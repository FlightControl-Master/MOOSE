"""P0-I3 host snapshot, source verification and archived-buffer replay.

Uses Python's standard library. Never starts or controls DCS. A prepared package
is a new immutable run; the user installs its single bootstrap in a mission copy.
"""
import argparse
from datetime import datetime, timezone
import hashlib
from io import BytesIO
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tempfile
import uuid
import zipfile

MIB = 1024 * 1024
CORE = "Moose Development/Moose/"
LOADER = "tests/support/local-pathfinding-loader.lua"
HELPERS = [LOADER, "tests/support/local-pathfinding-codec.lua",
           "tests/support/local-pathfinding-fixtures.lua",
           "tests/support/local-pathfinding-transcript.lua",
           "tests/support/local-pathfinding.lua",
           "tests/support/local-pathfinding-native.lua",
           "tests/support/local-pathfinding-dcs.lua"]
LIMITS = dict(MaxMemberBytes=4*MIB, MaxSourceBytes=32*MIB, MaxPackageBytes=64*MIB)
MISSION = re.compile(rb"(?:MISSION START|Mission started|Loaded mission|"
                     rb"SIMULATION.*(?:Start|start).*mission|"
                     rb"SIMULATION.*(?:Mission|mission).*(?:Start|start)|"
                     rb"load mission|Start mission)")


class EvidenceError(ValueError):
    def __init__(self, message, verdict="inconclusive"):
        super().__init__(message)
        self.verdict = verdict


def require(condition, message, verdict="inconclusive"):
    if not condition:
        raise EvidenceError(message, verdict)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def canonical(data):
    return json.dumps(data, ensure_ascii=False, allow_nan=False,
                      sort_keys=True, separators=(",", ":")).encode("utf-8")


def array(data):
    # The shared codec represents an empty Lua table as {}.
    if data == {}:
        return []
    require(isinstance(data, list), "expected dense array")
    return data


def confined(root, relative):
    require(isinstance(relative, str) and 0 < len(relative) <= 1024
            and "\\" not in relative and ":" not in relative and "\x00" not in relative,
            "invalid relative path")
    parts = relative.split("/")
    require(all(p not in ("", ".", "..") for p in parts), "path traversal")
    path = root.joinpath(*PurePosixPath(relative).parts)
    require(path.resolve().is_relative_to(root.resolve()), "path escapes run")
    return path


def read_bounded(path, maximum):
    with path.open("rb") as file:
        data = file.read(maximum + 1)
    require(len(data) <= maximum, f"size limit: {path.name}")
    return data


def decode(data):
    def duplicate_check(pairs):
        record = {}
        for key, value in pairs:
            require(key not in record, "duplicate JSON key")
            record[key] = value
        return record
    def invalid(value):
        raise EvidenceError("nonfinite JSON number: " + value)
    try:
        decoded = json.loads(data.decode("utf-8"), object_pairs_hook=duplicate_check,
                             parse_constant=invalid)
    except (RecursionError, UnicodeError, json.JSONDecodeError) as failure:
        raise EvidenceError("invalid JSON document: " + str(failure)[:256]) from failure
    pending, count = [(decoded, 1)], 0
    while pending:
        value, depth = pending.pop()
        count += 1
        require(depth <= 64 and count <= 32000000, "JSON depth/item limit")
        if isinstance(value, float):
            require(math.isfinite(value), "nonfinite JSON number")
        elif isinstance(value, dict):
            pending.extend((v, depth+1) for v in value.values())
        elif isinstance(value, list):
            pending.extend((v, depth+1) for v in value)
    return decoded


def source_check(data):
    require(not data.startswith((b"\xef\xbb\xbf", b"#!", b"\x1b")),
            "BOM/shebang/binary source unsupported")


def lua_literal(value):
    if isinstance(value, str):
        # Decimal byte escapes preserve Unicode, quotes and CRLF in Lua 5.1.
        return '"' + "".join("\\%03d" % b for b in value.encode("utf-8")) + '"'
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, list):
        return "{" + ",".join(lua_literal(v) for v in value) + "}"
    if isinstance(value, dict):
        return "{" + ",".join("[" + lua_literal(k) + "]=" + lua_literal(v)
                              for k, v in sorted(value.items())) + "}"
    raise EvidenceError("unsupported bootstrap value")


BOOTSTRAP = r'''-- Generated P0-I3 trusted entry. Use only in the isolated mission copy.
local reference = @REFERENCE@
local root = @ROOT@
assert(io and type(io.open) == "function" and os and type(os.rename) == "function"
  and type(loadstring) == "function", "P0 bootstrap: file/compiler capability unavailable")
assert(__Moose == nil and ASTAR == nil, "P0 bootstrap: MOOSE already loaded")
local member
for _, candidate in ipairs(reference.Members) do
  if candidate.LogicalPath == "tests/support/local-pathfinding-loader.lua" then
    member = candidate
  end
end
assert(member, "P0 bootstrap: missing loader reference")
local function closed(file)
  local ok, reason = file:close()
  assert(ok, reason)
end
local file = assert(io.open(root .. "/" .. member.PreparedPath, "rb"))
local ok, bytes = pcall(function()
  local data, reason = file:read(reference.Limits.MaxMemberBytes + 1)
  assert(data ~= nil or reason == nil, reason)
  return data or ""
end)
local closeOK, closeFailure = pcall(closed, file)
if not ok then error(bytes, 0) end
assert(closeOK, closeFailure)
assert(#bytes == member.Bytes, "P0 bootstrap: loader size mismatch")
assert(bytes:sub(1, 3) ~= "\239\187\191" and bytes:sub(1, 2) ~= "#!"
  and bytes:sub(1, 1) ~= "\27", "P0 bootstrap: unsupported source")
for _, suffix in ipairs({"", ".partial"}) do
  local existing = io.open(root .. "/" .. member.LoadedPath .. suffix, "rb")
  if existing then
    closed(existing)
    error("P0 bootstrap: this run has already been used; prepare a fresh run")
  end
end
local output = assert(io.open(root .. "/" .. member.LoadedPath .. ".partial", "wb"))
local written, failure = pcall(function() assert(output:write(bytes)) end)
local outputClosed, outputFailure = pcall(closed, output)
if not written then error(failure, 0) end
assert(outputClosed, outputFailure)
assert(os.rename(root .. "/" .. member.LoadedPath .. ".partial", root .. "/" .. member.LoadedPath))
-- Archive and compile this same buffer; never reread the executable source.
local Loader = assert(loadstring(bytes, "@" .. member.LogicalPath))()
local context = Loader.New(reference, {Root = root})
context:AdoptLoader(member.LogicalPath, bytes)
local loaded = context:Bootstrap()
loaded.Runner.Start(context)
'''


def prepare(repo, parent, saved_games=None):
    repo, parent = Path(repo).resolve(), Path(parent).resolve()
    modules = read_bounded(repo / CORE / "Modules.lua", 4*MIB)
    include_pattern = rb"__Moose\.Include\s*\(\s*MOOSE_DEVELOPMENT_FOLDER\s*\.\.\s*['\"](/Moose/[^'\"]+)['\"]\s*\)"
    includes = [CORE + match.decode("utf-8")[len("/Moose/"):]
                for match in re.findall(include_pattern, modules)]
    require(len(includes) > 0 and len(set(includes)) == len(includes), "invalid module list")
    active = [line for line in modules.splitlines()
              if line.strip() and not line.lstrip().startswith(b"--")]
    require(len(active) == len(includes), "unsupported dynamic module declaration")
    sources = [(CORE + "Modules.lua", modules, True)]
    sources += [(p, read_bounded(confined(repo, p), 4*MIB), True) for p in includes]
    sources += [(p, read_bounded(confined(repo, p), 4*MIB), True) for p in HELPERS]
    external = {}
    if saved_games is not None:
        settings = Path(saved_games).resolve() / "Config/serverSettings.lua"
        if settings.exists():
            logical = "external/serverSettings.lua"
            sources.append((logical, read_bounded(settings, 4*MIB), False))
            external[settings.as_posix()] = logical
    require(0 < len(sources) <= 256, "source member limit")
    require(sum(len(data) for _, data, _ in sources) <= 32*MIB, "source total limit")
    for _, data, _ in sources:
        source_check(data)
    run_id, token = str(uuid.uuid4()), str(uuid.uuid4())
    root = parent / run_id
    root.mkdir(parents=True, exist_ok=False)
    for folder in ("prepared", "loaded", "tapes"):
        (root / folder).mkdir()
    members = []
    for index, (path, data, required) in enumerate(sources, 1):
        member = dict(Index=index, LogicalPath=path, Bytes=len(data), SHA256=digest(data),
                      PreparedPath=f"prepared/{index:03d}.lua", LoadedPath=f"loaded/{index:03d}.lua",
                      Required=required)
        members.append(member)
        (root / member["PreparedPath"]).write_bytes(data)
    tested = [{"Path": m["LogicalPath"], "SHA256": m["SHA256"]} for m in members
              if m["LogicalPath"] in (CORE + "Core/" + n + ".lua"
                                      for n in ("Vector", "Pathline", "Grid", "Astar"))]
    reference = dict(SchemaVersion=1, RunId=run_id, BuildToken=token, Members=members,
                     IncludeOrder=includes, ExternalPaths=external, TestedSources=tested,
                     Limits=LIMITS.copy(), PreparedBytes=0,
                     PreparedUTC=datetime.now(timezone.utc).isoformat(),
                     GitContext={"Status": "unavailable"})
    try:
        git = ["git", "-c", "safe.directory="+repo.as_posix(), "-C", str(repo)]
        head = subprocess.run(git+["rev-parse", "HEAD"], capture_output=True, text=True, timeout=10)
        dirty = subprocess.run(git+["status", "--short"], capture_output=True, text=True, timeout=10)
        if head.returncode == dirty.returncode == 0:
            require(len(dirty.stdout.encode()) <= 65536, "Git context limit")
            reference["GitContext"] = dict(Status="observed", Revision=head.stdout.strip(),
                                          Dirty=bool(dirty.stdout), Files=dirty.stdout.splitlines())
    except (OSError, subprocess.SubprocessError):
        pass  # Optional context; source hashes remain mandatory.
    # Fixed point includes the reference and bootstrap sizes in the package cap.
    prepared_size = sum(m["Bytes"] for m in members)
    for _ in range(10):
        embedded = lua_literal(reference)
        bootstrap = BOOTSTRAP.replace("@REFERENCE@", embedded).replace(
            "@ROOT@", lua_literal(root.as_posix())).encode("utf-8")
        host_reference = dict(reference, BootstrapSHA256=digest(bootstrap))
        reference_bytes = canonical(host_reference)
        total = prepared_size + len(bootstrap) + len(reference_bytes)
        if reference["PreparedBytes"] == total:
            break
        reference["PreparedBytes"] = total
    else:
        raise EvidenceError("bootstrap accounting did not converge")
    require(total < 64*MIB and len(bootstrap) < 4*MIB, "prepared package limit")
    (root / "reference.json").write_bytes(reference_bytes)
    (root / "bootstrap.lua").write_bytes(bootstrap)
    return root


def bind_mission(root, mission):
    """Archive the final mission's embedded entry identity, without controlling DCS."""
    root, mission = Path(root).resolve(), Path(mission).resolve()
    reference = decode(read_bounded(root/"reference.json", 4*MIB))
    raw = read_bounded(mission, 64*MIB)
    require(not (root/"mission-definition.json").exists(), "mission definition already bound")
    with zipfile.ZipFile(BytesIO(raw)) as archive:
        candidates = [i for i in archive.infolist()
                      if i.filename.lower().endswith(".lua") and i.file_size <= 4*MIB]
        require(len(candidates) <= 256 and sum(i.file_size for i in candidates) <= 32*MIB,
                "mission resource limit")
        matched = []
        for info in candidates:
            data = archive.read(info)
            if digest(data) == reference["BootstrapSHA256"]:
                matched.append(info.filename)
        require(len(matched) == 1, "mission must contain exactly one matching embedded P0 entry")
    record = dict(SchemaVersion=1, RunId=reference["RunId"], BuildToken=reference["BuildToken"],
                  ConfiguredPath=str(mission), Bytes=len(raw), SHA256=digest(raw),
                  EntryResource=matched[0], EntrySHA256=reference["BootstrapSHA256"],
                  Status="configured_file_context", RuntimeIdentity="mission_log_markers")
    (root/"mission-definition.json").write_bytes(canonical(record))
    return record


def identity(data, reference, name):
    require(isinstance(data, dict) and data.get("SchemaVersion") == 1, name + ": schema")
    require(data.get("RunId") == reference["RunId"] and data.get("BuildToken") == reference["BuildToken"],
            name + ": run/token mismatch", "failed")


def correlation(raw, reference):
    require(raw.endswith(b"\n"), "unfinished log line")
    lines = raw.splitlines()
    require(lines and MISSION.search(lines[0]), "log must begin at a mission-start marker")
    prefix = ("[P0 DCS CAPTURE] " + reference["RunId"] + " " + reference["BuildToken"] + " ").encode()
    begin, loaded, ends, final = [], [], [], []
    for index, line in enumerate(lines):
        if index and MISSION.search(line):
            raise EvidenceError("another mission start in log range")
        if prefix in line:
            marker = line.split(prefix, 1)[1]
            if marker == b"BEGIN schema=1":
                begin.append(index)
            elif marker.startswith(b"LOAD COMPLETE schema=1"):
                loaded.append(index)
            elif marker.startswith(b"END case="):
                ends.append((index, marker[len(b"END case="):]))
            elif marker == b"CAPTURE COMPLETE source=pending_host_verification":
                final.append(index)
    require(len(begin) == len(loaded) == len(final) == 1, "missing/duplicate mission capture markers")
    require([name for _, name in ends] == [b"open-request", b"shallow-probe", b"coast-probe"],
            "missing/duplicate case markers")
    require(loaded[0] < begin[0] < ends[0][0] < ends[1][0] < ends[2][0] < final[0],
            "capture marker order")
    return dict(Status="matched", MissionStart=lines[0].decode("utf-8", "replace")[:512],
                RunId=reference["RunId"], BuildToken=reference["BuildToken"])


def collect(root, log, start, maximum=8*MIB):
    """Copy original complete bytes from a user-selected mission start offset."""
    require(isinstance(start, int) and start >= 0 and 0 < maximum <= 8*MIB, "invalid log snapshot limits")
    with Path(log).open("rb") as file:
        before = os.fstat(file.fileno())
        require(start < before.st_size, "mission start offset beyond log")
        file.seek(start)
        data = file.read(min(maximum + 1, before.st_size - start))
        after = os.fstat(file.fileno())
    require(after.st_size >= before.st_size and before.st_ino == after.st_ino,
            "log truncated/rotated during read")
    require(len(data) <= maximum, "log snapshot limit")
    data = data[:data.rfind(b"\n") + 1]
    reference = decode(read_bounded(root / "reference.json", 4*MIB))
    correlation(data, reference)
    require(not (root / "dcs.raw.log").exists(), "refusing to overwrite log evidence")
    (root / "dcs.raw.log").write_bytes(data)
    (root / "log-checkpoint.json").write_bytes(canonical(dict(
        SchemaVersion=1, RunId=reference["RunId"], BuildToken=reference["BuildToken"],
        Path=str(Path(log).resolve()), FileIdentity=[before.st_dev, before.st_ino],
        MissionStartByte=start, ReadByte=start+len(data), ObservedSize=before.st_size,
        RawSHA256=digest(data), CompleteLines=True, ReportedFindings=[])))


def _verify(root, require_log=True):
    """Read/check once, returning verified buffers for an isolated replay copy."""
    root = Path(root).resolve()
    buffers = {}
    def read(path, maximum=4*MIB):
        data = read_bounded(confined(root, path), maximum)
        buffers[path] = data
        return data
    reference = decode(read("reference.json"))
    require(reference.get("SchemaVersion") == 1 and reference.get("Limits") == LIMITS, "reference schema/limits")
    require(re.fullmatch(r"[0-9a-f-]{36}", reference.get("RunId", "")) is not None
            and re.fullmatch(r"[0-9a-f-]{36}", reference.get("BuildToken", "")) is not None, "reference identity")
    require(digest(read("bootstrap.lua")) == reference.get("BootstrapSHA256"), "bootstrap digest mismatch", "failed")
    completion = decode(read("completion.json"))
    identity(completion, reference, "completion")
    require(completion.get("Complete") is True and completion.get("State") == "complete", "incomplete capture")
    require(completion.get("BindingsStable") is True and completion.get("Cleanup", {}).get("Restored") is True
            and not completion["Cleanup"].get("Errors"), "binding/cleanup failure", "failed")
    entries, paths = {}, set()
    members = array(reference.get("Members"))
    require(0 < len(members) <= 256, "source count")
    for index, member in enumerate(members, 1):
        require(member.get("Index") == index and member.get("LogicalPath") not in entries, "duplicate/source order")
        for key in ("LogicalPath", "PreparedPath", "LoadedPath"):
            confined(root, member.get(key))
        require(member["PreparedPath"] not in paths and member["LoadedPath"] not in paths
                and member["PreparedPath"] != member["LoadedPath"], "duplicate source path")
        paths.update((member["PreparedPath"], member["LoadedPath"]))
        require(type(member.get("Bytes")) is int and 0 <= member["Bytes"] <= 4*MIB
                and re.fullmatch("[0-9a-f]{64}", member.get("SHA256", "")), "source size/digest")
        prepared = read(member["PreparedPath"])
        source_check(prepared)
        require(len(prepared) == member["Bytes"] and digest(prepared) == member["SHA256"],
                "prepared digest mismatch: " + member["LogicalPath"], "failed")
        entries[member["LogicalPath"]] = member
    require(sum(m["Bytes"] for m in members) <= 32*MIB, "source total limit")
    events = decode(read("load-events.json"))
    identity(events, reference, "load-events")
    require(events.get("BootstrapComplete") is True, "bootstrap incomplete")
    stages, returned, stack = {}, [], []
    event_list = array(events.get("Events"))
    require(0 < len(event_list) <= 2048, "load event limit")
    for number, event in enumerate(event_list, 1):
        path, kind = event.get("LogicalPath"), event.get("Kind")
        member = entries.get(path)
        require(member and event.get("Sequence") == number and event.get("Index") == member["Index"]
                and event.get("Bytes") == member["Bytes"], "undeclared/duplicate load event")
        current = stages.get(path)
        if kind == "deduplicated":
            require(current == "returned", "deduplicated before completion")
            continue
        expected = {None: "archived", "archived": "compiled", "compiled": "entered", "entered": "returned"}
        require(expected.get(current) == kind, "invalid load transition")
        if kind == "entered":
            stack.append(path)
        elif kind == "returned":
            require(stack and stack.pop() == path, "load execution order")
            returned.append(path)
        stages[path] = kind
    require(not stack, "unfinished chunk execution")
    require(all(stages.get(p) == "returned" for p, m in entries.items() if m["Required"]), "missing loaded member")
    observed_includes = [p for p in returned if p.startswith(CORE) and p != CORE+"Modules.lua"]
    require(observed_includes == reference.get("IncludeOrder"), "module include order mismatch", "failed")
    proof_members = []
    for path in sorted(stages):
        require(stages[path] == "returned", "failed chunk execution")
        member = entries[path]
        actual = read(member["LoadedPath"])
        source_check(actual)
        require(len(actual) == member["Bytes"] and digest(actual) == member["SHA256"],
                "loaded digest mismatch: " + path, "failed")
        proof_members.append(dict(Path=path, Bytes=len(actual), SHA256=digest(actual)))
    artifact_paths = set()
    for member in array(completion.get("Members")):
        path = member.get("Path")
        require(isinstance(path, str) and path not in artifact_paths
                and (path in ("inputs.json", "actions.json", "results.json", "load-events.json")
                     or re.fullmatch(r"tapes/[123]-(SearchTape|PreparationTape|ProbeTape)\.json", path)),
                "invalid/duplicate artifact member")
        artifact_paths.add(path)
        data = read(path, 8*MIB if path.startswith("tapes/") else 4*MIB)
        require(len(data) == member.get("Bytes"), "artifact length mismatch", "failed")
    require(artifact_paths == {"inputs.json", "actions.json", "results.json", "load-events.json",
                             "tapes/1-SearchTape.json", "tapes/1-PreparationTape.json",
                             "tapes/2-ProbeTape.json", "tapes/3-ProbeTape.json"}, "missing artifact member")
    for name in ("inputs.json", "actions.json", "results.json"):
        identity(decode(buffers[name]), reference, name)
    inputs, results = decode(buffers["inputs.json"]), decode(buffers["results.json"])
    cases = array(inputs.get("Cases"))
    require(len(cases) == 3 and [c.get("CaseId") for c in cases]
            == ["open-request", "shallow-probe", "coast-probe"], "case matrix mismatch")
    require(len(array(results.get("Cases"))) == 3, "result case count")
    for index, item in enumerate(results["Cases"]):
        require(item.get("Case") == cases[index], "frozen case/result mismatch", "failed")
        for key in ("SearchTape", "PreparationTape", "ProbeTape"):
            if key in item:
                require(item[key] == {"Path": f"tapes/{index+1}-{key}.json"}, "tape consumer/path mismatch")
    for path in sorted(artifact_paths):
        if path.startswith("tapes/"):
            tape = decode(buffers[path])
            require(tape.get("SchemaVersion") == 1 and tape.get("Complete") is True
                    and "Issue" not in tape, "incomplete terrain tape")
            require(tape.get("Manifest", {}).get("SourceVerification") == "unverified"
                    and tape["Manifest"].get("SourceManifest") == reference.get("TestedSources"),
                    "tape source manifest mismatch", "failed")
    total = sum(len(v) for v in buffers.values()) + len(read("capability.txt", 1024))
    require(total <= 64*MIB, "package total limit")
    require(not any(root.rglob("*.partial")), "unfinished artifact write")
    mission = {"Status": "pending"}
    mission_definition = {"Status": "unbound"}
    if (root/"mission-definition.json").exists():
        mission_definition = decode(read("mission-definition.json"))
        identity(mission_definition, reference, "mission-definition")
        require(mission_definition.get("EntrySHA256") == reference["BootstrapSHA256"],
                "mission entry mismatch", "failed")
    if (root / "dcs.raw.log").exists():
        raw = read("dcs.raw.log", 8*MIB)
        checkpoint = decode(read("log-checkpoint.json"))
        identity(checkpoint, reference, "log-checkpoint")
        require(checkpoint.get("RawSHA256") == digest(raw)
                and checkpoint.get("ReadByte", 0)-checkpoint.get("MissionStartByte", 0) == len(raw)
                and checkpoint.get("CompleteLines") is True, "raw log/checkpoint mismatch", "failed")
        mission = correlation(raw, reference)
    elif require_log:
        raise EvidenceError("mission correlation pending; collect the announced mission's raw log range")
    proof = dict(SchemaVersion=1, RunId=reference["RunId"], BuildToken=reference["BuildToken"],
                 Status="loaded_verified" if mission["Status"] == "matched" else "buffers_verified",
                 Members=proof_members, Mission=mission, MissionDefinition=mission_definition,
                 ArtifactDigests=[dict(Path=p, Bytes=len(b), SHA256=digest(b))
                                  for p, b in sorted(buffers.items())],
                 Substitutions=["BASE", "UTILS", "COORDINATE", "DCS controller/drawing/timer guards"],
                 TrustBoundary="prepared bootstrap, DCS executable and host tool",
                 NativePhysicsValidated=False)
    return proof, buffers


def verify(root, require_log=True):
    try:
        return _verify(root, require_log)
    except (KeyError, TypeError, AttributeError, IndexError) as failure:
        raise EvidenceError("invalid artifact schema: " + str(failure)[:256]) from failure


def run_replay(proof, buffers, lua):
    # Private copies come from the very buffers checked above, not another read.
    with tempfile.TemporaryDirectory(prefix="moose-p0-replay-") as temporary:
        target = Path(temporary)
        for path, data in buffers.items():
            file = confined(target, path)
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(data)
        script = Path(__file__).with_name("p0-native-replay.lua")
        runner_bytes = read_bounded(script, 4*MIB)
        (target / "replay.lua").write_bytes(runner_bytes)
        completed = subprocess.run([str(lua), str(target/"replay.lua"), str(target)],
                                   cwd=target, capture_output=True, text=True, timeout=120)
        result_path = target / "replay-result.json"
        require(result_path.exists(), "replay aborted: " + (completed.stderr+completed.stdout)[-1024:])
        result = decode(read_bounded(result_path, 4*MIB))
        result["SourceProof"] = proof
        result["HostReplayRunnerSHA256"] = digest(runner_bytes)
        require(completed.returncode == 0 or result.get("Verdict") != "passed", "replay process failed")
    return result


def replay(root, lua):
    proof, buffers = verify(root)
    require(proof["Status"] == "loaded_verified", "source admission missing")
    result = run_replay(proof, buffers, lua)
    (Path(root) / "verification.json").write_bytes(canonical(proof))
    (Path(root) / "replay-report.json").write_bytes(canonical(result))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    build = commands.add_parser("prepare")
    build.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent)
    build.add_argument("--out", type=Path, required=True)
    build.add_argument("--saved-games", type=Path)
    build.add_argument("--entry", type=Path, help="create a new mission entry copy; never overwrite it")
    bind = commands.add_parser("bind-mission")
    bind.add_argument("--run", type=Path, required=True)
    bind.add_argument("--mission", type=Path, required=True)
    copy = commands.add_parser("collect")
    copy.add_argument("--run", type=Path, required=True)
    copy.add_argument("--log", type=Path, required=True)
    copy.add_argument("--mission-start-byte", type=int, required=True)
    check = commands.add_parser("verify")
    check.add_argument("--run", type=Path, required=True)
    check.add_argument("--buffers-only", action="store_true")
    again = commands.add_parser("replay")
    again.add_argument("--run", type=Path, required=True)
    again.add_argument("--lua", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            root = prepare(args.repo, args.out, args.saved_games)
            if args.entry is not None:
                with args.entry.open("xb") as file:
                    file.write((root/"bootstrap.lua").read_bytes())
            print(root / "bootstrap.lua")
        elif args.command == "bind-mission":
            record = bind_mission(args.run, args.mission)
            print(record["EntryResource"])
        elif args.command == "collect":
            collect(args.run, args.log, args.mission_start_byte)
            print("Raw mission bytes saved.")
        elif args.command == "verify":
            proof, _ = verify(args.run, require_log=not args.buffers_only)
            (args.run / "verification.json").write_bytes(canonical(proof))
            print(proof["Status"])
        else:
            result = replay(args.run, args.lua)
            print(result["Verdict"])
            return 0 if result["Verdict"] == "passed" else 1
    except (EvidenceError, OSError, ValueError, zipfile.BadZipFile, subprocess.SubprocessError) as failure:
        print(json.dumps(dict(Verdict=getattr(failure, "verdict", "inconclusive"),
                              Reason=str(failure)[:1024])), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
