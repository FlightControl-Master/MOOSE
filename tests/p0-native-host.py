"""P0-I3 host regressions; all mission/load evidence here is fabricated fixture data."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location("p0_native", Path(__file__).with_name("p0-native.py"))
host = importlib.util.module_from_spec(spec)
spec.loader.exec_module(host)


def events(reference):
    result = []
    def event(member, kind):
        result.append(dict(Sequence=len(result)+1, Kind=kind, LogicalPath=member["LogicalPath"],
                           Index=member["Index"], Bytes=member["Bytes"]))
    def complete(member):
        for kind in ("archived", "compiled", "entered", "returned"):
            event(member, kind)
    members = {m["LogicalPath"]: m for m in reference["Members"]}
    complete(members[host.LOADER])
    modules = members[host.CORE+"Modules.lua"]
    for kind in ("archived", "compiled", "entered"):
        event(modules, kind)
    for path in reference["IncludeOrder"]:
        complete(members[path])
    event(modules, "returned")
    for path in host.HELPERS[1:]:
        complete(members[path])
    return result


def loaded_fixture(root):
    reference = host.decode((root/"reference.json").read_bytes())
    for member in reference["Members"]:
        shutil.copyfile(root/member["PreparedPath"], root/member["LoadedPath"])
    return reference, events(reference)


def fake_package(repo, parent):
    root = host.prepare(repo, parent)
    reference, recorded = loaded_fixture(root)
    headers = dict(SchemaVersion=1, RunId=reference["RunId"], BuildToken=reference["BuildToken"])
    cases = [dict(CaseId=name) for name in ("open-request", "shallow-probe", "coast-probe")]
    results = [dict(Case=c) for c in cases]
    data = {
        "inputs.json": dict(headers, Cases=cases),
        "actions.json": dict(headers, Actions=[]),
        "load-events.json": dict(headers, Events=recorded, BootstrapComplete=True),
    }
    for index, keys in enumerate((("SearchTape", "PreparationTape"), ("ProbeTape",), ("ProbeTape",)), 1):
        for key in keys:
            path = f"tapes/{index}-{key}.json"
            results[index-1][key] = dict(Path=path)
            data[path] = dict(SchemaVersion=1, Complete=True, Tapes=[],
                              Manifest=dict(SourceVerification="unverified",
                                            SourceManifest=reference["TestedSources"]))
    data["results.json"] = dict(headers, Cases=results)
    published = []
    for path, value in data.items():
        encoded = host.canonical(value)
        (root/path).write_bytes(encoded)
        published.append(dict(Path=path, Bytes=len(encoded)))
    (root/"capability.txt").write_bytes(b"fixture only")
    (root/"completion.json").write_bytes(host.canonical(dict(
        headers, Complete=True, State="complete", BindingsStable=True,
        Cleanup=dict(Restored=True, Errors=[]), Members=published)))
    return root


class HostTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="moose-p0-host-unit-")
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.repo = self.base/"repo"
        self.repo.mkdir()
        includes = ["Core/"+name+".lua" for name in ("Vector", "Pathline", "Grid", "Astar")]
        module = self.repo/host.CORE/"Modules.lua"
        module.parent.mkdir(parents=True)
        module.write_bytes(b"\r\n".join(("__Moose.Include(MOOSE_DEVELOPMENT_FOLDER..'/Moose/"+p+"')").encode()
                                       for p in includes))
        for path in [host.CORE+p for p in includes] + host.HELPERS:
            file = self.repo/path
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes("-- Grüße\r\nreturn 1\r\n".encode())
        self.root = fake_package(self.repo, self.base/"runs")

    def mutate_json(self, path, callback):
        file = self.root/path
        value = host.decode(file.read_bytes())
        callback(value)
        encoded = host.canonical(value)
        file.write_bytes(encoded)
        if path != "completion.json":
            completion = host.decode((self.root/"completion.json").read_bytes())
            for member in completion["Members"]:
                if member["Path"] == path:
                    member["Bytes"] = len(encoded)
            (self.root/"completion.json").write_bytes(host.canonical(completion))

    def test_complete_buffers_have_no_native_mission_claim(self):
        proof, _ = host.verify(self.root, require_log=False)
        self.assertEqual(proof["Status"], "buffers_verified")
        self.assertFalse(proof["NativePhysicsValidated"])
        with self.assertRaisesRegex(host.EvidenceError, "mission correlation"):
            host.verify(self.root)

    def test_exact_crlf_and_unicode_bytes(self):
        reference = host.decode((self.root/"reference.json").read_bytes())
        member = reference["Members"][1]
        self.assertIn("Grüße".encode(), (self.root/member["LoadedPath"]).read_bytes())
        self.assertIn(b"\r\n", (self.root/member["LoadedPath"]).read_bytes())
        proof, _ = host.verify(self.root, False)
        self.assertEqual(proof["Members"][0]["SHA256"], host.digest((self.repo/host.CORE/"Core/Astar.lua").read_bytes()))

    def test_modified_loaded_bytes(self):
        reference = host.decode((self.root/"reference.json").read_bytes())
        (self.root/reference["Members"][1]["LoadedPath"]).write_bytes(b"return 2")
        with self.assertRaisesRegex(host.EvidenceError, "loaded digest"):
            host.verify(self.root, False)

    def test_changed_prepared_buffer(self):
        reference = host.decode((self.root/"reference.json").read_bytes())
        (self.root/reference["Members"][1]["PreparedPath"]).write_bytes(b"return 2")
        with self.assertRaisesRegex(host.EvidenceError, "prepared digest"):
            host.verify(self.root, False)

    def test_changed_bootstrap(self):
        with (self.root/"bootstrap.lua").open("ab") as file:
            file.write(b"\n-- replacement")
        with self.assertRaisesRegex(host.EvidenceError, "bootstrap digest"):
            host.verify(self.root, False)

    def test_stale_token(self):
        self.mutate_json("completion.json", lambda v: v.update(BuildToken="stale"))
        with self.assertRaisesRegex(host.EvidenceError, "run/token"):
            host.verify(self.root, False)

    def test_failed_cleanup(self):
        self.mutate_json("completion.json", lambda v: v.update(Cleanup=dict(Restored=False, Errors=[])))
        with self.assertRaisesRegex(host.EvidenceError, "cleanup"):
            host.verify(self.root, False)

    def test_unfinished_capture(self):
        self.mutate_json("completion.json", lambda v: v.update(Complete=False))
        with self.assertRaisesRegex(host.EvidenceError, "incomplete"):
            host.verify(self.root, False)

    def test_missing_chunk_return(self):
        self.mutate_json("load-events.json", lambda v: v["Events"].pop())
        with self.assertRaisesRegex(host.EvidenceError, "unfinished chunk"):
            host.verify(self.root, False)

    def test_duplicate_load_event(self):
        def change(value):
            value["Events"].append(dict(value["Events"][-1], Sequence=len(value["Events"])+1))
        self.mutate_json("load-events.json", change)
        with self.assertRaisesRegex(host.EvidenceError, "transition"):
            host.verify(self.root, False)

    def test_duplicate_member(self):
        self.mutate_json("completion.json", lambda v: v["Members"].append(v["Members"][0]))
        with self.assertRaisesRegex(host.EvidenceError, "duplicate artifact"):
            host.verify(self.root, False)

    def test_missing_artifact(self):
        self.mutate_json("completion.json", lambda v: v["Members"].pop())
        with self.assertRaisesRegex(host.EvidenceError, "missing artifact"):
            host.verify(self.root, False)

    def test_tape_cannot_claim_verification(self):
        self.mutate_json("tapes/1-SearchTape.json", lambda v: v["Manifest"].update(SourceVerification="verified"))
        with self.assertRaisesRegex(host.EvidenceError, "tape source manifest"):
            host.verify(self.root, False)

    def test_first_path_and_size_failure(self):
        with self.assertRaisesRegex(host.EvidenceError, "traversal"):
            host.confined(self.root, "../another-run/source.lua")
        with self.assertRaisesRegex(host.EvidenceError, "size limit"):
            host.read_bounded(self.root/"bootstrap.lua", 1)
        with self.assertRaisesRegex(host.EvidenceError, "duplicate JSON"):
            host.decode(b'{"a":1,"a":2}')

    def test_nonfinite_json_and_unsupported_source(self):
        with self.assertRaisesRegex(host.EvidenceError, "nonfinite"):
            host.decode(b'{"x":NaN}')
        for prefix in (b"\xef\xbb\xbf", b"#!", b"\x1b"):
            with self.assertRaisesRegex(host.EvidenceError, "unsupported"):
                host.source_check(prefix+b"return 1")

    def raw_log(self):
        reference = host.decode((self.root/"reference.json").read_bytes())
        prefix = f'[P0 DCS CAPTURE] {reference["RunId"]} {reference["BuildToken"]} '
        return ("DCS INFO SIMULATION: MISSION START fixture\r\n" + "\r\n".join(
            prefix+m for m in ("LOAD COMPLETE schema=1 source=pending_host_verification", "BEGIN schema=1",
                              "END case=open-request", "END case=shallow-probe", "END case=coast-probe",
                              "CAPTURE COMPLETE source=pending_host_verification")) + "\r\n").encode()

    def test_log_snapshot_preserves_original_bytes_and_excludes_incomplete_line(self):
        raw = self.raw_log()
        file = self.base/"fixture.log"
        file.write_bytes(b"earlier run\r\n" + raw + b"unfinished")
        host.collect(self.root, file, len(b"earlier run\r\n"))
        self.assertEqual((self.root/"dcs.raw.log").read_bytes(), raw)
        proof, _ = host.verify(self.root)
        self.assertEqual(proof["Mission"]["Status"], "matched")  # fabricated fixture only
        with self.assertRaisesRegex(host.EvidenceError, "overwrite"):
            host.collect(self.root, file, len(b"earlier run\r\n"))

    def test_log_rotation_wrong_run_duplicate_begin_and_later_mission_reject(self):
        reference = host.decode((self.root/"reference.json").read_bytes())
        raw = self.raw_log()
        for bad in (raw.replace(reference["RunId"].encode(), b"old-run"),
                    raw + b"MISSION START another\r\n",
                    raw.replace(b"BEGIN schema=1", b"BEGIN schema=1\r\n" +
                                f'[P0 DCS CAPTURE] {reference["RunId"]} {reference["BuildToken"]} BEGIN schema=1'.encode())):
            with self.assertRaises(host.EvidenceError):
                host.correlation(bad, reference)
        with self.assertRaisesRegex(host.EvidenceError, "unfinished"):
            host.correlation(raw[:-1], reference)

    def test_prepare_is_fresh_and_bounds_external_mapping(self):
        saved = self.base/"saved"
        (saved/"Config").mkdir(parents=True)
        (saved/"Config/serverSettings.lua").write_bytes(b"cfg={name='fixture'}")
        second = host.prepare(self.repo, self.base/"runs", saved)
        self.assertNotEqual(second, self.root)
        reference = host.decode((second/"reference.json").read_bytes())
        self.assertEqual(reference["ExternalPaths"][(saved/"Config/serverSettings.lua").as_posix()],
                         "external/serverSettings.lua")
        self.assertEqual(reference["PreparedBytes"],
                         sum(p.stat().st_size for p in second.rglob("*") if p.is_file()))

    def test_final_mission_entry_is_bound_by_raw_resource_digest(self):
        mission = self.base/"fixture.miz"
        bootstrap = (self.root/"bootstrap.lua").read_bytes()
        with zipfile.ZipFile(mission, "w") as archive:
            archive.writestr("l10n/DEFAULT/Astar_P0Capture.lua", bootstrap)
            archive.writestr("mission", "mission = {theatre='PersianGulf'}")
        record = host.bind_mission(self.root, mission)
        self.assertEqual(record["SHA256"], host.digest(mission.read_bytes()))
        proof, _ = host.verify(self.root, False)
        self.assertEqual(proof["MissionDefinition"]["Status"], "configured_file_context")
        with self.assertRaisesRegex(host.EvidenceError, "already bound"):
            host.bind_mission(self.root, mission)

    def test_wrong_embedded_mission_entry_is_not_accepted(self):
        mission = self.base/"fixture.miz"
        with zipfile.ZipFile(mission, "w") as archive:
            archive.writestr("l10n/DEFAULT/Astar_P0Capture.lua", b"-- stale entry")
        with self.assertRaisesRegex(host.EvidenceError, "matching embedded"):
            host.bind_mission(self.root, mission)

    def test_invalid_schema_depth_and_unfinished_file_are_gaps(self):
        with self.assertRaisesRegex(host.EvidenceError, "depth"):
            host.decode(b"["*65+b"0"+b"]"*65)
        with self.assertRaisesRegex(host.EvidenceError, "nonfinite"):
            host.decode(b'{"x":1e400}')
        (self.root/"result.partial").write_bytes(b"unfinished")
        with self.assertRaisesRegex(host.EvidenceError, "unfinished artifact"):
            host.verify(self.root, False)


class ArchivedCoreReplay(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("P0_LUA51"), "set P0_LUA51 to enable archived Core integration")
    def test_actual_archived_core_capture_serialization_and_replay(self):
        repo = Path(__file__).resolve().parent.parent
        with tempfile.TemporaryDirectory(prefix="moose-p0-core-unit-") as temporary:
            root = host.prepare(repo, Path(temporary))
            reference, recorded = loaded_fixture(root)
            (root/"fixture-load-events.json").write_bytes(host.canonical(recorded))
            codec = next(m["LoadedPath"] for m in reference["Members"]
                         if m["LogicalPath"] == "tests/support/local-pathfinding-codec.lua")
            completed = subprocess.run([os.environ["P0_LUA51"],
                                        str(repo/"tests/support/local-pathfinding-native-fixture.lua"),
                                        str(root), codec], cwd=repo, capture_output=True, text=True, timeout=60)
            self.assertEqual(completed.returncode, 0, completed.stdout+completed.stderr)
            # No fabricated DCS log is admitted. The proof explicitly stays offline.
            proof, buffers = host.verify(root, require_log=False)
            report = host.run_replay(proof, buffers, Path(os.environ["P0_LUA51"]))
            self.assertEqual(report["Verdict"], "passed", json.dumps(report)[:3000])
            self.assertEqual(report["SourceProof"]["Status"], "buffers_verified")
            self.assertTrue(all(q["Verdict"] == "passed" for q in report["QueryChecks"]))
            self.assertEqual(report["Assertions"]["Verdict"], "passed")


if __name__ == "__main__":
    unittest.main()
