---
title: Local pathfinding isolated DCS capture test
parent: Developer
nav_exclude: true
---

# Local pathfinding isolated DCS capture test

Status: P0-I3 approved and implemented on 2026-10-11, including the isolated
test loader, native adapter/writer, host source verifier and archived Core
replay. Offline regressions pass under Lua 5.1.5. The native DCS smoke run and
its loaded-source/replay acceptance remain pending; no simulator result is
claimed by the offline tests.

See the [P0 contract and implemented tooling](local-pathfinding-test-contract.md)
and [rebuild plan](rolling-pathfinding-plan.md). The subsequently implemented
[R1b production preparation](navy-route-preparation-api.md) is outside this
identity-only smoke; measured vessel policy and NAVYGROUP LOCAL control remain
later steps.

## 1. Purpose and evidence boundaries

Record actual DCS terrain calls made by ASTAR, GRID, VECTOR and PATHLINE,
replay them without live terrain access, and bind both runs to the bytes of
the sources that executed. The first smoke test has three small cases;
the complete Qeshm route follows only after this capture/replay gate passes.

Report these independently:

| Evidence | Required conclusion |
| --- | --- |
| Native capture | Ordered stages, arguments, return arity/data and public actions were captured completely within limits |
| Loaded-source verification | The archived buffers that were compiled/executed match the prepared reference manifest; relevant runtime bindings remained current |
| Exact replay | Every recorded terrain call was consumed with the same scope, function and exact arguments, with no live fallback |
| Semantic parity | Copied raw candidates and route-check reports match under P0's documented identity/timing exclusions |
| Terrain assertions | Open-water and land-crossing expectations hold; the shallow segment's measured result is reproducible |

A complete capture may record a blocked route or a native exception. That
does not itself pass the smoke test. Query parity does not certify turning
clearance, vessel motion or ship safety. Identity preparation continues to
report `Selected=false`, `ExecutionValidated=false` and
`maneuver_not_implemented`.

## 2. Verified starting points and proposed isolation

Source inspection on 2026-10-11 established:

- `Moose_Dynamic_Loader.lua` uses `base.loadfile(IncludeFile)` and logs a
  filename. It records neither the compiled buffer nor its digest. It loads
  `Modules.lua`, which controls the individual module order.
- `Moose_Create.lua` generates the dynamic/static includes from `Modules.lua`.
  Its commit marker and the legacy `Moose.files` list do not prove loaded bytes.
- The saved `Astar_Qeshem.miz` contains an embedded dynamic `Moose.lua`,
  theatre `PersianGulf`, and trigger definitions for `Astar.lua`,
  `Astar_Tests.lua` and `Astar_Develop.lua`. The first two mission scripts have
  additional trigger conditions; do not assume that they can never execute.
- `Astar_Develop.lua` currently selects `testcase=2`. Its common prelude draws
  zones and enables tracing before entering a testcase.
- The installed `Scripts/Moose` junction currently resolves to this checkout.
  The inspected `MissionScripting.lua` has sanitization calls for `io`,
  `os` and `lfs` commented out. Those disk observations are not proof of
  capabilities or includes in a running mission.

Use a separate mission copy with the existing zones and **one dedicated test
entry**, `Astar_P0Capture.lua`. Disable the ordinary MOOSE
include and all three existing Astar script triggers in that copy. The test
entry loads MOOSE once through the test-only loader, then starts the runner.
Do not add another branch after the drawing/tracing prelude or reload classes
in an already running mission.

The mission has no scripted vessel movement. A Harbor Tug is optional and is
not used to supply input or receive commands. The initial pose is configured
at the resolved route start, with configured heading/speeds; it is never
labelled a measurement. No NAVYGROUP object, controller command, drawing,
profiler or other test suite is started by the runner. Normal MOOSE bootstrap
services may exist, but the runner creates only its own bounded timer chain.

## 3. Preparation and actual loaded-source proof

### Host preparation

Create a fresh task-specific temporary run directory and unique `RunId` plus
`BuildToken`. Copy raw source bytes into a prepared snapshot outside the
checkout. Freeze the entire source set named by `Modules.lua`, the module
list itself, test loader/runner and portable P0 helpers. Include any additional
executed helper dependencies. An undeclared nested file load is a setup error.
Use logical paths for identity and explicit host paths only for locating files.

Normal bootstrap also executes `Globals.lua`, which may load
`Config/serverSettings.lua` when available. Inspect these actual bootstrap
dependencies during preparation; any Lua configuration that will execute must
be a declared frozen member too. Identify pre-existing native libraries such
as `lfs` separately as external dependencies, not verified Lua source members.
Never claim that archiving the four tested Core files captures the whole
bootstrap environment.

Compute SHA-256 and byte length on each raw file and write the reference
manifest. Record include order, loader identity, helper order, Git revision
and dirty-tree context. Those Git fields remain context, not proof. Snapshot
preparation must fail if its declared files cannot be read or exceed limits.
Later checkout edits require a newly prepared snapshot and mission restart.

After saving the isolated copy, `bind-mission` identifies its exact embedded
test-entry resource by digest and stores its mission-file hash. It does not
modify the mission or infer that other triggers are disabled. The prepared
entry bytes are already archived as `bootstrap.lua`.
The mission identity retains the configured file/hash separately from
runtime-observed theatre and mission-start markers. A filename on disk alone
does not establish which mission is running.

### Test-only loader

The bootstrap is an explicit, inspected entry in the isolated mission copy.
It passes one binary-read loader buffer both to `loadstring` and to that
loader's evidence collector. The collector then owns every subsequent include:

1. Resolve an allowed logical member of the prepared snapshot. Read it once
   in binary mode with a bounded read; keep that exact string.
2. Archive that buffer, byte for byte, under an assigned artifact member.
   Check write/close results before allowing execution.
3. Compile **the same string** with `loadstring(buffer, chunkName)`. Record
   compile success, then entry and successful return in increasing load order.
4. Execute `Modules.lua` through this path. Its `__Moose.Include` calls resolve
   to the prepared members and use the same procedure. Repeated identical
   include requests are recorded as deduplicated; unexpected reloads fail.
5. Load runner/helpers through the same collector. Test-helper imports use
   an explicit dependency loader rather than ordinary working-directory
   `dofile`. No `Fixtures.Install()` is executed in DCS.

During this synchronous bootstrap only, owned `loadfile`/`dofile` adapters
route nested Lua loads through the declared snapshot as well. Restore the
original functions before yielding. The runtime runner uses its explicit
helper loader; an unexpected later dependency load stops the test rather
than falling through to mutable disk files.

There is no second `loadfile(path)` after reading or hashing: that would allow
a different file to execute. Do not translate CRLF, strip a BOM or re-encode
Unicode before archiving/hashing. For this first loader, BOM/shebang inputs
are rejected explicitly during preparation rather than silently transformed;
unsupported compilation fails and retains evidence.

The small bootstrap and DCS executable are the trust boundary. This is a
reproducibility proof under the inspected test loader, not an attestation
against malicious mission code or a compromised simulator. Record bootstrap
provenance separately; do not describe a later reread of its path as proof of
its executed bytes.

Once bootstrap loading finishes, snapshot the actual class tables and function
bindings used by the runner, including relevant BASE, UTILS, COORDINATE,
ASTAR, GRID, VECTOR and PATHLINE dependencies. Check their identities before
each owned work slice and at completion. Create tested instances only after
this checkpoint. Unexpected table/method replacement, another include, or an
untracked loader invalidates the proof and stops the test; do not repair the
running environment by reloading it.

### Host verification after capture

The host independently hashes every archived executed buffer and compares it
with the prepared manifest, matching logical identity, byte length, load order
and execution records. All required modules/helpers must have returned from
loading successfully. Correlate `RunId`/`BuildToken` across the reference
manifest, native loader completion, test BEGIN, final artifact and current
mission-start log range. Verify that the archived bootstrap entry matches the
prepared mission resource. A missing member, mismatched digest, incomplete load
chain or uncorrelated marker prevents `loaded_verified`.

Native markers say `source=pending_host_verification`. Only the host verifier
can produce `SourceProof.Status="loaded_verified"`. It identifies precisely
which logical members are verified, plus the separately trusted bootstrap.
Path equality, junction checks, timestamps, commit strings and a caller-supplied
`SourceVerified=true` are insufficient.

## 4. Runtime capability and environment gate

Before terrain work, require the actual native functions
`land.getSurfaceType`, `land.getSurfaceHeightWithSeabed` and `land.profile`,
resolved WATER/SHALLOW_WATER enums, the loaded R1a APIs and the required binary
reader/writer/compiler capabilities. Create/write/read/close a small owned
probe file in the run directory and remove only that file. Never change
`MissionScripting.lua` or simulator settings to make the test work.

Record `_VERSION`, native `env.mission.theatre`, runtime mission time and,
where directly available, DCS build and terrain revision. Host-observed build
metadata has a separate origin/reference. Unavailable build/revision fields
remain `unknown`; do not invent a mission API for them. Full input/response
tapes can still support exact replay with unknown terrain revision.

Resolve the six existing endpoint zones once:

`ASTAR Start 1`, `ASTAR Goal 1`, `PATHLINE Shallow Start`,
`PATHLINE Shallow Goal`, `PATHLINE Coast Start`, `PATHLINE Coast Goal`.

Use each zone's `GetVec2()` once and copy horizontal x/y into Vec3 x/z, with
configured altitude `y=0`. In particular, `ZONE_RADIUS:GetVec3()` queries
`land.getHeight`, so it is not the input resolver for this test. Freeze these
copied centers before search, schedule or terrain scope. Store exact binary64
coordinates, names and per-field provenance. Reject missing zones, nonfinite
positions and coincident required endpoints with `setup_required`. Input
resolution asks no terrain for altitude and cannot add hidden search queries.

## 5. First native test matrix and effective settings

| Case | Native operations | Expected result |
| --- | --- | --- |
| `open-request` | One cold local request to a goal 500 m from ASTAR Start 1 towards ASTAR Goal 1; virtually follow its copied points; prepare the same raw snapshot at the frozen start pose | Exact virtual goal reached; connection and dense checks clear; maneuver/execution remain unverified |
| `shallow-probe` | The frozen Shallow Start/Goal reference segment; independent fresh ASTAR connection check and PATHLINE dense corridor job | No assumed clear/blocked result. Both actual results, failure location and missing-data evidence must replay identically |
| `coast-probe` | The frozen Coast Start/Goal reference segment; independent fresh connection and dense corridor jobs | The land crossing is rejected by each check; native reasons/locations are retained independently |

The probe segments are `configured_reference_segment` inputs, not purported
ASTAR candidates. Execute their two stages independently even when connection
rejects the segment, so the dense native profile path is exercised. Keep that
probe behavior separate from normal preparation, which may stop after a
failed earlier stage. Each probe uses its own start pose and cold evaluator.

Name the search variant `native-smoke-compact-weight1`. Retain T2's hexagonal
400 m spacing, 3000 candidate-cell cap, water/shallow-water filter, hard depth
3.5 m, full corridor 50 m, preferred depth 15 m and weight 1. Override only the
window to Ahead 1200 m / full Width 800 m / Behind 400 m for the short request.
Keep learning/progress rules from the common P0 baseline. Persist all resolved
parameters and native enum values; this does not validate the full T2 window
or weight-10 behavior.

Dense settings remain common P0: longitudinal spacing 25 m, lateral spacing
10 m, maximum section length 1000 m, 65 offsets, 4096 profile records per query
and 4097 direct positions per section. Preserve native zero-based/sparse
profile structure in the tape; do not normalize it into a successful profile.

For the first run use these explicitly resolved limits:

| Limit | Initial test value |
| --- | --- |
| Search slice / request | 32 work items; at most 4000 slices and 200000 admitted items per request; at most 2 requests |
| Validation slice / total per probe or preparation | 64 work units, 8 point checks, 1 profile query; 200000 total work units, 50000 point checks, 4096 profile queries; 10000 slices shared across its stages |
| Scheduling | One owned callback chain, interval 0.1 simulation seconds; whole test at most 1200 elapsed simulation seconds |
| Each transcript | 20000 calls and 200000 profile records per stage, 8 MiB canonical bytes including headers/first-issue reserve |
| Raw loaded sources | At most 256 members, 4 MiB per member and 32 MiB total |
| Other serialized results / complete package | 4 MiB result/metadata allowance; 64 MiB package including sources and all tapes |

Apply a package cap as well as individual tape caps; independent sessions do
not each inherit an additional whole-package allowance. Limits do not bound
Lua heap or native profile allocation/frame duration. Returned profile size
can only be checked after its atomic native call. A limit prevents a success
claim and does not silently increase itself or retry in a new window.

Use count-driven work for capture/replay. ASTAR still receives a valid positive
`MaxSeconds` argument, but its work scope exposes no `os.clock`. Preserve the
other `os` functions and restore the original table before yielding. PATHLINE
receives work/call limits without a CPU deadline. Record this policy explicitly:
class CPU fields are unavailable, not zero measurements. Independently use a
saved native clock, if available, to measure inclusive runner-slice CPU and the
worst slice. That includes capture overhead and is not ASTAR self time.
Simulation time/acceleration and host wall time are separate observations.
Do not sum overlapping timings or derive CPU cost from simulation duration.

## 6. Terrain binding, scheduling and cleanup

Reuse P0-I2's canonical codec/session format and first-issue rules. The native
binding is a test-only environment adapter, not an extension of production
terrain APIs. Capture forwards the original argument/return values; replay
returns detached recorded data and never invokes the original functions.

Install an owned `land` proxy only while executing a synchronous public
operation: setup/start, one search slice, one connection evaluation, one dense
slice or cancellation. Constructor/configuration calls that access terrain
must also have a scope; none may bypass recording. Keep `SurfaceType` values
unchanged, save original native function references, and reject an unsupported
terrain access as an explicit gap. Geometry-only work must have zero terrain
calls. Drawing and environment preflight do not occur inside these scopes.

Restore `land` and the scoped clock before callback return, logging/file
serialization, scheduling another callback or rethrowing an error. There is
no proxy installed between ticks and no coroutine yield with a proxy active.
Nested or foreign proxy ownership is a setup/ownership error. Cleanup checks
current ownership; it never overwrites a foreign replacement to hide a conflict.

Persist the session across slices, with exact stage/consumer/request/candidate
identity. Record explicit public actions and slice boundaries in an ordered
action journal. Two consumers have separate sessions/cursors. Cached results
remain results; replay must not add terrain queries for a cache hit.

Each callback verifies its run token and current task before work. Completion,
limit, cancellation or exception stops that chain, cancels current owned
ASTAR/PATHLINE jobs and closes its scopes. No automatic restart, second chain,
larger limits or movement follows. A late callback is inert. Failure while
persisting evidence leaves the artifact incomplete.

A narrow protected-call boundary exists only to restore owned bindings and
retain the original exception. It rethrows that same error after best-effort
bounded evidence finalization; cleanup failures are secondary. Nonstring
exceptions remain original errors and non-replayable gaps. No terrain result
or successful stage is fabricated.

## 7. Artifacts and exact offline replay

Suggested local output parent:
`C:/Users/frank/AppData/Local/Temp/moose-astar-grid-check/p0-native/`.
Each unique run has:

- `reference.json` and `prepared/`: host-prepared manifest and raw snapshot.
- `loaded/` and `load-events.json`: the actual archived compiled buffers and
  ordered load/binding evidence.
- `inputs.json`, `actions.json`, `results.json` and separate search/connection/
  depth tapes identified by case and consumer.
- `completion.json` written last, containing member lengths/identities and
  completeness, plus a separate host-created `verification.json`.
- The relevant mission log range as original bytes in `dcs.raw.log` and a
  host read/checkpoint record; no decoded-line substitute.

Member paths are assigned by the adapter, confined to the run directory.
Write owned partial files, close/check them, then finalize; the final marker
is never created before mandatory files are complete. File existence alone
is not completeness. The native writer cannot set host-verification status.
Raw log storage is host-owned with its own bounded snapshot policy; it is
not a terrain tape or a mission writer.

The host admits only complete, bounded, schema-valid artifacts with matching
run identity. Load the **archived tested Core buffers**, not the checkout's
current files, into a fresh Lua 5.1 replay process with controlled external
fixtures. Archive/identify those fixture definitions too. BASE/coordinate
stubs remain declared substitutions; proof of tested Core source identity
does not mean the complete native MOOSE environment was reproduced.

Replay search and preparation from the frozen inputs, action journal and
their own tapes. Replay probes with their declared independent stages.
Do not reconstruct missing actions from screenshots or result endpoints.
Use P0's semantic comparison and keep native IDs separate from logical
request/window identities. Never remap consumer scopes to conceal a mismatch.
The first differing scope/function/argument/report field is reported with
bounded expected/actual evidence; missing records or incomplete captures
produce `inconclusive`, with no nearest-sample/live fallback.

P0-I3 adds a test-only environment/operation boundary to the shared driver.
The analytic binding remains its default; DCS explicitly supplies the native
adapter. Lua 5.1 work yields outside all protected calls and owned bindings.
Each native work operation and public action uses the same shared driver.
`Fixtures.Install()` is used only in offline regression/replay processes.
Native results have `ReplayCapability="native_capture"`; replay attempts use
`recorded_exact`. Existing tapes keep `SourceVerification="unverified"`.
An independently verified `SourceProof` remains beside those unchanged tapes.
No public MOOSE API or `Modules.lua` entry was changed.

The full source/load manifest belongs to this envelope. Individual existing
P0-I2 tape manifests retain their bounded tested-source references (at most
32 entries); they do not embed all bootstrap modules or a claimed verification
result. The envelope binds each tape and action/input/result member by exact
content digest, and the host checks that binding before comparison.

## 8. Markers and acceptance

Use `[P0 DCS CAPTURE]` with schema revision, `RunId` and `BuildToken`.
Log only BEGIN, load-complete reference, one END per case and final capture
completion/first error. Keep lines bounded; store payloads in files. Native
completion is `CAPTURE COMPLETE; source=pending_host_verification`, not a
source-verified replay PASS.

The host reports `PASS: isolated capture and verified core replay` only when
all three cases have complete evidence, source proof passes, all query tapes
and semantic results replay exactly, both coast checks reject land, open
search/route checks pass and cleanup/isolation checks pass. The shallow result
is stated with its actual clear/blocked/missing-data evidence. Unknown build
metadata is disclosed; it is not substituted with a guessed value.

Classify assertion/query/report mismatches as `failed`; missing source proof,
capture gaps, missing capabilities or incomplete files as `inconclusive`.
Keep native reasons and driver reasons separate. Neither status advances to
R1b or requests a longer route automatically.

The user starts the prepared isolated mission and announces that it is running.
Only then inspect `dcs.log` directly, identify that mission start and BEGIN,
save read position/run identity/event counts/reported findings, and account for
rotation, truncation and incomplete final lines. No recurring monitor is
created. Missing log growth is neither failure nor mission end.

## 9. Implementation order and required regressions

The approved **P0-I3 implementation** contains:

1. Test-only host snapshot builder, bounded byte-preserving loader, load/binding
   evidence and host source verifier. Validate generated test artifacts in a
   fresh temporary directory; leave normal include templates unchanged.
2. Shared P0 environment/operation boundary, native terrain binding, owned
   scheduling/writer and archived-source offline replay.
3. Dedicated native smoke entry and the three-case reports, plus explicit
   instructions for the isolated mission copy and trigger order.

Lua 5.1 regressions must exercise real production methods with controlled
external dependencies and expose each original failure:

- Changing a path after its one binary read does not change the executed
  buffer; altered loaded bytes, stale tokens, missing/duplicate members,
  failed chunk execution and later class-method replacement prevent proof.
- Exact byte preservation for CRLF/non-ASCII source, declared BOM/shebang
  rejection, source/package limits, failed/partial writes and missing
  capabilities; no path traversal or overwrite of another run.
- Scope ownership/restoration on success, setup failure, terrain exception,
  cap, cancellation, conflicting ownership and a late callback; no binding
  remains between scheduled ticks or native query during replay.
- Zero-based/sparse/malformed profiles, trailing nil, missing depth and the
  first mismatch/gap survive a native-shaped capture/serialize/replay cycle.
- Copied action/pose/raw-report ownership, separate consumer/probe stages,
  current-buffer fixture loading and rejection of substituted checkout code.
- Count-driven CPU policy, one timer chain, final-operation completion at a
  cap and zero controller/route/drawing calls in the test driver.

Keep both existing P0 suites passing in separate Lua 5.1 processes; run
affected production suites if refactoring exposes a dependency. Compile new
Lua files and review final diff/whitespace. Stubbed tests precede the first
DCS run and cannot replace it.

Implemented test-only files:

| File | Responsibility |
| --- | --- |
| `tests/p0-native.py` | Fresh bounded raw snapshot; unique run/build tokens; Git context; binary mission-entry binding; raw log collection; independent digest/load-order/identity checks; private verified-buffer replay copy |
| `tests/support/local-pathfinding-loader.lua` | Archive-before-compile loading, exact return arity, declared nested loads, checked writes, runtime binding/run checkpoints |
| `tests/support/local-pathfinding-native.lua` | Native terrain/clock ownership, exact action journal, cooperative jobs, one timer chain, independent probe stages and semantic comparison |
| `tests/support/local-pathfinding-dcs.lua` | Isolated three-case entry, frozen zone inputs, bounded artifacts, error tapes and final completion marker |
| `tests/p0-native-replay.lua` | Fresh Lua 5.1 process; archived helpers/Core; declared external stubs; exact query/action replay and semantic/assertion reports |

Regression validation: 52 P0-I1, 45 P0-I2, 15 loader and 28 native-shaped cases
pass in separate Lua 5.1.5 processes (140 total), plus 22 Python host cases.
The host integration case runs actual archived Core buffers through capture,
serialization and replay. Its terrain, mission markers and load evidence are
explicit fixtures; its source status stays `buffers_verified`, never a native
simulator result. No native physics, terrain or controller validation is claimed.

## 10. Running the isolated smoke test

Run preparation from the repository root. This local example uses the
installed Python runtime; it is not production configuration:

```powershell
$python = 'C:\Program Files\Python313\python.exe'
& $python tests/p0-native.py prepare `
  --out "$env:TEMP/moose-astar-grid-check/p0-native" `
  --saved-games 'C:/Users/frank/Saved Games/DCS.testing' `
  --entry 'D:/DCS/Scripts/My_Missions/_Ops/NavalGroup/Astar/Astar_P0Capture.lua'
```

`--entry` creates a new byte-identical entry copy and refuses to overwrite an
existing file. For later runs, omit this option and select the printed fresh
`bootstrap.lua` directly, or review/copy it into the owned mission entry.
Every attempt needs a fresh run directory; reusing a published run fails.

1. Save a separate copy of `Astar_Qeshem.miz` with the six zones listed above.
2. Disable the ordinary MOOSE include and the three existing Astar script
   triggers. Add one **MISSION START / DO SCRIPT FILE** trigger for the fresh
   entry. Do not enable `Astar_Develop.lua` alongside it.
3. Save the copy. Bind its actual embedded entry and mission hash:

```powershell
$run = '<fresh run directory printed by prepare>'
& $python tests/p0-native.py bind-mission --run $run --mission '<saved isolated copy.miz>'
```

The bind command checks exact embedded entry bytes. Mission hash is configured
file context; the runtime identity comes separately from log markers.
After a new preparation, reselect the new resource in the trigger and restart
the mission. Editing the checkout alone does not update a frozen run.

The user starts the mission and announces that it is running. Then inspect the
log directly and identify that mission's start byte. The host command preserves
original complete bytes and records file identity/read position; it refuses a
rotated/truncated range, another mission, a stale run or duplicate BEGIN:

```powershell
& $python tests/p0-native.py collect --run $run `
  --log 'C:/Users/frank/Saved Games/DCS.testing/Logs/dcs.log' `
  --mission-start-byte <observed byte offset>
& $python tests/p0-native.py verify --run $run
& $python tests/p0-native.py replay --run $run `
  --lua 'D:/Programs/lua-5.1.5_Win64_bin/lua5.1.exe'
```

No recurring observation is created. `verify --buffers-only` is available for
offline diagnostics and reports `buffers_verified`; it cannot admit the native
acceptance replay without mission correlation. The host executes private copies
of the same buffers it checked, so a second checkout read cannot substitute a
different Core version.

Expected log order: `LOAD COMPLETE`, `BEGIN`, three `END case=...` markers,
then `CAPTURE COMPLETE source=pending_host_verification`. There are no F10
drawings or ship commands. Missing IO/rename/compiler capabilities fail before
terrain work; no sanitization setting is edited. Limits, ownership conflicts,
exceptions or partial writes prevent a success claim. Unpublished error scopes
are retained as `tapes/failure-*.json` where persistence capabilities permit.

Acceptance is the combination of `verification.json` with
`Status="loaded_verified"` and `replay-report.json` with `Verdict="passed"`,
all query checks/semantic comparison/terrain assertions passed and cleanup
restored. DCS build/terrain revision and native wall/acceleration measurements
remain unavailable unless independently observed. Inclusive runner CPU and
elapsed simulation seconds are reported separately.

Next agreed handoff: request approval for this isolated DCS smoke test and
wait for the mission-start notification. R1b production preparation was later
approved independently; this smoke does not exercise it or start vessel movement.
Refresh the frozen snapshot before testing later production changes.
