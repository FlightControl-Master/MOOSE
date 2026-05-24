--- **TARS — Tactical Air Recon System**
--
-- Simulates photo-reconnaissance and visual-observation missions in DCS World.
-- Players fly designated recon aircraft or helicopters, activate the film from
-- the F10 radio menu, overfly enemy units within the sensor's flight envelope,
-- and return to an allied airbase or FARP to trigger a debrief.
-- Detected targets are published as coalition-only F10 map markers and optional
-- scoring credits are awarded.

---
-- @module Ops.TARS
-- @author FMD — Fredy
-- @author Applevangelist - Moose migration with documentation, helpers: Claude.AI
-- @image Ops_PlayerRecce.png

---
-- @type TARS_SESSION
-- @extends Core.Base#BASE
-- @field #boolean debug Enable debugging in TARS_SESSION.
-- @field #boolean debugunitsearch Enable Target Search Debug.
-- @field Wrapper.Unit#UNIT unit The MOOSE UNIT object for the recon aircraft.
-- @field #string lid Log-line prefix shown in Moose.log entries.
-- @field DCS#Vec3 vec3 World position snapshot taken at session creation.
-- @field #number coa Coalition side (1 = Red, 2 = Blue).
-- @field #string type DCS type name of the aircraft (key into `TARS.parameters`).
-- @field Wrapper.Group#GROUP group MOOSE GROUP the aircraft belongs to.
-- @field #number groupID Numeric group ID.
-- @field #string objectName DCS unit name — used as the registry key.
-- @field #string playerName Human-readable player name as shown in the scoreboard.
-- @field #number playerID Numeric DCS unit ID, used as F10-menu and message key.
-- @field #table ammo Ammo table snapshot from `unit:GetAmmo()`.
-- @field #number time Mission time (seconds) when the session was last refreshed.
-- @field #number category Group category at session creation.
-- @field #boolean capturing `true` while the capture loop is actively running.
-- @field #number duration Total expositions (shots) available per sortie.
-- @field #table targetList Targets detected this pass, not yet reported. `[unitName] = snap`.
-- @field #number captureCount Total unique targets captured this sortie.
-- @field #boolean loop `true` while the `TARS.CaptureLoop` timer is scheduled.
-- @field #boolean standby `true` when film is paused without ending the session.
-- @field #boolean filmExhausted `true` when `duration` reached zero.
-- @field #boolean sessionEnded `true` after STOP or film exhaustion; awaiting debrief.
-- @field #boolean wasCapturing `true` if capture was active at the moment of touchdown.
-- @field #boolean landingScheduled `true` once the debrief timer has been registered.
-- @field #number lastTakeoffTime Mission time of the last takeoff, used for debouncing.
-- @field #TARS Callback The TARS Callback object for menu functions etc.
-- @field #boolean PilotParameterHelper If true, there will be messages about the correct parameters to the UNIT.

---
-- ## Tracks all states for a single recon sortie.
--
-- One instance is created per player per flight when they take off from a
-- validated slot. It holds the remaining film, the list of targets captured
-- this pass, and all flags that drive the capture state-machine.
--
-- Instances are stored in `TARS.instances[unitName]` and are reset (not
-- destroyed) at the end of each successful debrief so the pilot can fly
-- another sortie in the same slot without rejoining.
--
-- @field #TARS_SESSION
TARS_SESSION = {}
TARS_SESSION.debug = false
TARS_SESSION.debugunitsearch = false

--- @type TARS
-- @extends Core.Base#BASE
-- @field #string version Semantic version string, e.g. `"v2.1.0"`.
-- @field #string lid Log-line prefix shown in Moose.log entries.
-- @field #string locale Active locale: `"en"` (default), `"de"`, `"fr"`.
-- @field #boolean mooseScoring Enable MOOSE SCORING backend.
-- @field #boolean debug Enable debugging in TARS.
-- @field #number valueScoring Points awarded per detected target (MOOSE path).
-- @field #number landingDelay Seconds after touchdown before landing is confirmed.
-- @field #number debriefDelay Seconds after confirmation before F10 marks appear.
-- @field #number landingDistance Max distance (m) from an allied base/FARP for a valid debrief.
-- @field #number _vAltMin Minimum AGL (m) for visual-recon helicopters.
-- @field #number _vRangeMin Detection radius (m) at `_vAltMin`.
-- @field #number _vAltOpti Optimal AGL (m) for visual-recon helicopters.
-- @field #number _vRangeOpti Detection radius (m) at `_vAltOpti`.
-- @field #number _vAltMax Maximum AGL (m) for visual-recon helicopters.
-- @field #number _vRangeMax Detection radius (m) at `_vAltMax`.
-- @field #boolean filmLimitEnabled Cap the number of detections per sortie.
-- @field #number filmLimitMax Maximum unique detections allowed per sortie.
-- @field #boolean detectUnits Master toggle for detecting DCS Unit objects.
-- @field #table units Sub-toggles `{ air, ground, ship }` for unit categories.
-- @field #boolean detectStatics Master toggle for detecting DCS Static objects.
-- @field #table statics Sub-config for static filtering (`farps`, `captureExceptions`, whitelist).
-- @field #table recoNameFilter `{ enabled=#boolean, keyword=#string }` — restricts TARS menus to matching group names.
-- @field #table targetNameFilter `{ enabled=#boolean, keywords=#table }` — per-coalition keyword lists for target filtering.
-- @field #table reconTypes Map of `[typeName] = true` for all recon-capable DCS type names.
-- @field #table parameters Map of `[typeName] = #TARS.PlatformParams` with per-platform sensor profiles.
-- @field #table allowedAmmo Map of `[weaponDisplayName] = true` for permitted loadout items.
-- @field #table instances Runtime map `[unitName] = #TARS_SESSION` of active sorties.
-- @field #table groundMenus Runtime map `[playerName] = #TARS.MenuData` of open F10 menus.
-- @field #table detectedTargets Lifetime map `[unitName] = #TARS.Snapshot` of all reported targets.
-- @field #table marks `{ blue = {}, red = {} }` — maps `[unitName] = markID`.
-- @field #number redMarkCount Next available mark ID for Red coalition marks.
-- @field #number blueMarkCount Next available mark ID for Blue coalition marks.
-- @field Functional.Scoring#SCORING scoring MOOSE SCORING instance (nil if mooseScoring is false).
-- @field #boolean PilotParameterHelper If true, there will be messages about the correct parameters to the UNIT.

---
-- ## Simulates photo-reconnaissance and visual-observation missions in DCS World.
--
-- Players fly designated recon aircraft or helicopters, activate the film from
-- the F10 radio menu, overfly enemy units within the sensor's flight envelope,
-- and return to an allied airbase or FARP to trigger a debrief.
-- Detected targets are published as coalition-only F10 map markers and optional
-- scoring credits are awarded.
--
-- ## Quick-start
-- The system initialises automatically at the bottom of this file:
--
--          local locale = "de"           -- optional, default is "en"
--          TARS_Instance = TARS:New(locale)
--
-- Nothing else is required. Adjust the configuration fields at the top of the
-- file (`TARS.filmLimitMax`, `TARS.parameters`, `TARS.allowedAmmo`, …) to fit
-- your mission before loading.
--
-- ## Player workflow
-- 1. Spawn into a recon-capable slot and open the **F10 › Task TARS** radio menu.   
-- 2. Select **TARS validation** on the ground. The system checks your loadout and
--    reports the platform's altitude band, FOV, and available film. 
--    The validation item then disappears once approved. 
-- 3. Take off. **Start filming / STB & Resume / Stop filming** appear in the menu.   
-- 4. Select **TARS mode : Start filming** to begin recording.   
-- 5. Fly over enemy units within the sensor's altitude/attitude envelope.   
--    Each detected unit is confirmed in the HUD (`+1 Captured target`).   
-- 6. Use **TARS mode : STB & Resume** to pause (e.g. to refuel).   
--    Film resumes automatically on the next takeoff if the loadout is still valid.   
-- 7. Select **TARS mode : Stop filming** or let the film timer expire.   
-- 8. Land at an allied airbase or FARP within `TARS.landingDistance` metres.   
--    The film controls disappear. After `landingDelay + debriefDelay` seconds the
--    intel marks appear on the F10 map and scoring credits are awarded. 
--    After the debrief the **TARS validation** item reappears for the next sortie.   
--
-- ## Localization
-- 
-- All player-facing strings are defined in `TARS.Messages` using a table.
-- 
-- ## Platforms and Settings
-- 
-- Player **group name** filters
-- 
--          TARS.recoNameFilter = { enabled=false, keyword="Reco" } -- Only allow groups with this keyword in the name
-- 
-- ### Adding a new platform
-- 
-- Add an entry to `TARS.reconTypes` and a matching typename and profile to `TARS.parameters`:
--
--        TARS_Instance.reconTypes["F-16C_50"] = true
--        TARS_Instance.parameters["F-16C_50"] = {
--            minAlt=300, maxAlt=8000, maxRoll=10, maxPitch=15, -- Note altitude is AGL!
--            fov=35, duration=300, offset=math.rad(20), -- fov = field of view, duration = # max of photos, offset = camera angle in Radians
--            name="F-16C with RECCE pod"
--        }
--        
-- ### Optical System Parameters Demonstrator
-- 
-- The optical system is like a torchlight, the further away from the ground you are, the larger is the area covered. One underestimated effect is however, that on flat land,
-- because at angle, you actually cover an elliptic area. [You can checkout the effects of various parameters on this demonstrator](https://applevangelist.github.io/TARS_Optical/tars_optics.html).
-- 
-- ### Available Platforms are
-- 
--        TARS.reconTypes = {
--          ["MiG-21Bis"]=true, ["AJS37"]=true, ["Mirage-F1EE"]=true,
--          ["F-5E-3"]=true,    ["F-14A-135-GR"]=true, ["F-14B"]=true,
--          ["F-4E-45MC"]=true, ["P-51D"]=true, ["P-51D-30-NA"]=true,
--          ["SpitfireLFMkIX"]=true, ["FW-190A8"]=true, ["FW-190D9"]=true,
--          ["SA342M"]=true, ["SA342L"]=true, ["UH-1H"]=true, ["OH58D"]=true,
--          ["Mi-8MT"]=true, ["MH-6J"]=true,
--          ["OH-6A"]=true,}
-- 
-- ### Allowed weapon types on the platforms are - will be validated by the script
--  
--        TARS.allowedAmmo = {
--          ["AIM-9B"]=true,["AIM-9D"]=true,["AIM-9E"]=true,["AIM-9G"]=true,
--          ["AIM-9H"]=true,["AIM-9J"]=true,["AIM-9L"]=true,["AIM-9M"]=true,
--          ["AIM-9N"]=true,["AIM-9P"]=true,["AIM-9P3"]=true,["AIM-9P5"]=true,
--          ["AIM-9JULI"]=true,
--          ["R-3S"]=true,["R-13M"]=true,["R-13M1"]=true,["R-60"]=true,["R-60M"]=true,
--          ["R550 Magic II"]=true,
--          ["7_62x51"]=true,}
-- 
-- ### Film and detection settings
-- 
--        TARS.filmLimitEnabled = true
--        TARS.filmLimitMax     = 25        -- max 25 captured objects
--        TARS.detectUnits      = true      -- capture UNIT objects
--        TARS.detectStatics    = false     -- capture STATIC objects incl. of FARPs
-- 
-- ### Target UNIT Filters
--  
--        TARS.units = { air=false, ground=true, ship=true }
--
-- ### Target UNIT Name Filters
-- 
-- You always only detect UNITs of the other coalition. E.g. below - a RED unit would only detect BLUE units which have "Hawk" somewhere in the UNIT name.
-- Name keywords are tested independent of capitalization, it doesn't matter if it is Hawk, HAWK, or hAwK.
-- 
--        TARS.targetNameFilter = { enabled = true, keywords = { [coalition.side.BLUE] = { "Hawk" }, [coalition.side.RED]  = { "Scud" },},}    
--        
-- ### Target STATIC Filters
-- 
--        TARS.statics = {
--          farps=true,
--          captureExceptions=false, captureExceptionsList={}, -- these are mutually exclusive, either exceptions from the typename list captureExceptionsList **or**
--          captureUnique=false,     captureUniqueList={},}    -- unique (once only) typenames from the captureUniqueList!
-- 
-- 
-- ### Other Settings
-- 
--        TARS.debug           = false
--        TARS.mooseScoring    = true       -- if true use MOOSE scoring
--        TARS.valueScoring    = 100        -- points per detection
--        TARS.landingDelay    = 30         -- check valid landing after this many seconds
--        TARS.debriefDelay    = 60         -- show debriefing after this many seconds
--        TARS.landingDistance = 2500       -- land closer than this many meters to a friendly base for debrief
--        TARS.PilotParameterHelper = false -- show helper checks on pitch/roll/AGL parameters
-- 
-- ## SRS integration
-- All player messages route through `TARS:_MsgUnit()` and `TARS:_MsgCoalition()`.
-- To broadcast over SRS, init the SRS system with `TARS_Instance:SetSRS(...)`, provide the necessary parameters.
--
-- ## Scoring
-- Two scoring backends are supported:
--
-- * **MOOSE SCORING** — set `TARS_Instance.mooseScoring = true`. Requires a SCORING object
--   and awards `TARS_Instance.valueScoring` points per target.
--
-- * **DCSBot** — fallback when mooseScoring is false. Awards `ceil(count/4)` credits
--   via `dcsbot.addUserPoints()` if the DCSBot table is present.
--
-- ## Mission Scripting integration
-- 
-- Moose FSM Style callback functions are available for mission designers. Optionally overwrite with own function. Processed after landing on debriefing analysis:
-- 
--          function mytars:OnBeforeDataProcessing(Snapshot) -- provides a #TARS.Snapshot data table for a captured object, function must return true to call the OnAfterDataProcessing() function next.
-- 
--          function mytars:OnAfterDataProcessing(Snapshot) -- provides a #TARS.Snapshot data table for a captured object for use in your mission script.
-- 
-- @field #TARS
TARS = {}

--- Platform sensor/camera profile.
-- Stored in `TARS.parameters[typeName]`.
-- @type TARS.PlatformParams
-- @field #number minAlt Minimum AGL altitude (m) for valid detections.
-- @field #number maxAlt Maximum AGL altitude (m) for valid detections.
-- @field #number maxRoll Maximum bank angle (degrees) — camera must be level.
-- @field #number maxPitch Maximum pitch angle (degrees) — camera must be level.
-- @field #number fov Camera half-angle FOV (degrees). Not used for visual-recon helis.
-- @field #number duration Remaining expositions (shots) for this sortie.
-- @field #number offset Forward look-ahead (radians).
-- @field #string name Human-readable label in player messages.
-- @field #number minRange Detection radius (m) at `minAlt` — visual-recon helis only.
-- @field #number optimalAlt Optimal AGL (m) — triggers the dual-cone model.
-- @field #number optimalRange Detection radius (m) at `optimalAlt`.
-- @field #number maxRange Detection radius (m) at `maxAlt`.
-- @field #number overlap  Optional frame overlap 0–1 (default 0.5). Used by `_CalcInterval`.

--- F10 menu registration data.
-- Stored in `TARS.groundMenus[playerName]`.
-- @type TARS.MenuData
-- @field Core.Menu#MENU_GROUP menuHandle Root sub-menu. Call `:Remove()` to destroy.
-- @field Core.Menu#MENU_GROUP_COMMAND itemValidate "TARS validation" — present in GROUND_NEW; removed after validation.
-- @field Core.Menu#MENU_GROUP_COMMAND itemInfo "TARS capture config" — always present.
-- @field Core.Menu#MENU_GROUP_COMMAND itemStart "Start filming" — added on takeoff.
-- @field Core.Menu#MENU_GROUP_COMMAND itemStb "STB & Resume" — added on takeoff.
-- @field Core.Menu#MENU_GROUP_COMMAND itemStop "Stop filming" — added on takeoff.
-- @field #boolean approved `true` after successful ground validation.
-- @field #string unitName DCS unit name.
-- @field #number groupID Numeric group ID.
-- @field #string playerName Player display name.

--- Frozen target snapshot.
-- @type TARS.Snapshot #TARS.Snapshot
-- @field Wrapper.Unit#UNIT unit MOOSE UNIT wrapper or STATIC wrapper.
-- @field DCS#Object dcsObj Raw DCS object reference.
-- @field #number category `Object.Category.*` of the detected object.
-- @field #string type DCS type name.
-- @field #string name DCS unit name (registry key).
-- @field DCS#Vec3 point World position at detection time.
-- @field #number time Mission time of the snapshot.
-- @field #number groupID Group ID (units only).
-- @field #number groupCat Group category (units only).
-- @field #number coa Coalition side (units only).
-- @field #table ammo Ammo table at detection (units only).
-- @field #number life Health 0-100 at detection (units only).
-- @field #string playername Player name who captured the data.

-------------------------------------------------
-- TODO VERSION & LOCALE
-------------------------------------------------

--- @field #string version
TARS.version = "v2.3.2"

--- Active locale.
-- @field #string locale
TARS.locale = TARS.locale or "en"

-------------------------------------------------
-- TODO CONFIGURATION
-------------------------------------------------

TARS.debug           = false
TARS.mooseScoring    = true
TARS.valueScoring    = 100
TARS.landingDelay    = 30
TARS.debriefDelay    = 60
TARS.landingDistance = 2500
TARS.PilotParameterHelper = false -- If true, there will be messages about the correct parameters to the UNIT.

--- @field #number _vAltMin
TARS._vAltMin    = 100
--- @field #number _vRangeMin
TARS._vRangeMin  = TARS._vAltMin  * 20   -- 200 m
--- @field #number _vAltOpti
TARS._vAltOpti   = 500
--- @field #number _vRangeOpti
TARS._vRangeOpti = TARS._vAltOpti * 5    -- 2500 m
--- @field #number _vAltMax
TARS._vAltMax    = 1500
--- @field #number _vRangeMax
TARS._vRangeMax  = TARS._vAltMax  * 3    -- 4500 m

TARS.filmLimitEnabled = true
TARS.filmLimitMax     = 25
TARS.detectUnits      = true
TARS.detectStatics    = false

--- @field #table units
TARS.units = { air=false, ground=true, ship=true }

--- @field #table statics
TARS.statics = {
    farps=true,
    captureExceptions=false, captureExceptionsList={},
    captureUnique=false,     captureUniqueList={},
}

--- @field #table recoNameFilter
TARS.recoNameFilter = { enabled=false, keyword="Reco" }

--- @field #table targetNameFilter
TARS.targetNameFilter = {
    enabled  = true,
    keywords = {
        [coalition.side.BLUE] = { "USA" },
        [coalition.side.RED]  = { "USSR" },
    },
}

-------------------------------------------------
-- TODO RECON-CAPABLE PLATFORMS
-------------------------------------------------

--- @field #table reconTypes
TARS.reconTypes = {
    ["MiG-21Bis"]=true, ["AJS37"]=true, ["Mirage-F1EE"]=true,
    ["F-5E-3"]=true,    ["F-14A-135-GR"]=true, ["F-14B"]=true,
    ["F-4E-45MC"]=true, ["P-51D"]=true, ["P-51D-30-NA"]=true,
    ["SpitfireLFMkIX"]=true, ["FW-190A8"]=true, ["FW-190D9"]=true,
    ["SA342M"]=true, ["SA342L"]=true, ["UH-1H"]=true, ["OH58D"]=true,
    ["Mi-8MT"]=true, ["MH-6J"]=true,
    ["OH-6A"]=true,
}

-------------------------------------------------
-- TODO PER-PLATFORM PARAMETERS
-------------------------------------------------

--- @type #TARS.parameters
-- @field #table parameters
TARS.parameters = {}

TARS.parameters["F-4E-45MC"]     = { minAlt=100,  maxAlt=8000, maxRoll=10, maxPitch=15, fov=23,  duration=120, offset=math.rad(40), overlap=0.25, min_interval=3, name="RF-4E with KS-87 Forward Oblique Camera" }
TARS.parameters["MiG-21Bis"]     = { minAlt=500,  maxAlt=8000, maxRoll=10, maxPitch=15, fov=52,  duration=140, offset=math.rad(40), overlap=0.25, min_interval=3, name="MiG-21R with Day recce pod" }
TARS.parameters["AJS37"]         = { minAlt=15,   maxAlt=8000, maxRoll=10, maxPitch=15, fov=25,  duration=120, offset=math.rad(40), overlap=0.25, min_interval=3, name="SF 37" }
TARS.parameters["Mirage-F1EE"]   = { minAlt=1524, maxAlt=8000, maxRoll=10, maxPitch=15, fov=20,  duration=400, offset=math.rad(40), overlap=0.25, min_interval=3, name="Mirage-F1CR with Omera 33" }
TARS.parameters["F-5E-3"]        = { minAlt=762,  maxAlt=8000, maxRoll=15, maxPitch=15, fov=70,  duration=300, offset=math.rad(40), overlap=0.25, min_interval=3, name="F-5E Tigereye" }
TARS.parameters["F-14A-135-GR"]  = { minAlt=750,  maxAlt=8000, maxRoll=10, maxPitch=20, fov=14,  duration=400, offset=math.rad(45), overlap=0.25, min_interval=3, name="F-14A TARPS KS-87D" }
TARS.parameters["F-14B"]         = { minAlt=228,  maxAlt=8000, maxRoll=10, maxPitch=20, fov=85,  duration=400,  offset=math.rad(40), overlap=0.25, min_interval=3, name="F-14B TARPS KA-99A" }
TARS.parameters["TF-51D"]        = { minAlt=250,  maxAlt=2500, maxRoll=15, maxPitch=15, fov=60,  duration=400, offset=math.rad(10), overlap=0.5, min_interval=5, name="TF-51D Mustang RF-51D Photo Recon" }
TARS.parameters["P-51D"]         = { minAlt=250,  maxAlt=2500, maxRoll=15, maxPitch=15, fov=60,  duration=400, offset=math.rad(10), overlap=0.5, min_interval=5,name="P-51D Mustang F-6D Photo Recon" }
TARS.parameters["P-51D-30-NA"]   = { minAlt=250,  maxAlt=2500, maxRoll=15, maxPitch=15, fov=60,  duration=400, offset=math.rad(10), overlap=0.5, min_interval=5,name="P-51D-30 Mustang F-6D Photo Recon" }
TARS.parameters["SpitfireLFMkIX"]= { minAlt=150,  maxAlt=2500, maxRoll=15, maxPitch=15, fov=55,  duration=350, offset=math.rad(10), overlap=0.5, min_interval=5,name="Spitfire LF Mk IX PR Recon" }
TARS.parameters["FW-190A8"]      = { minAlt=200,  maxAlt=2500, maxRoll=15, maxPitch=15, fov=60,  duration=350, offset=math.rad(10), overlap=0.5, min_interval=5,name="FW-190 A-8 Tactical Recon" }
TARS.parameters["FW-190D9"]      = { minAlt=250,  maxAlt=2500, maxRoll=15, maxPitch=15, fov=60,  duration=350, offset=math.rad(10), overlap=0.5, min_interval=5,name="FW-190 D-9 Tactical Recon" }
TARS.parameters["SA342M"]        = { minAlt=20,   maxAlt=1000, maxRoll=35, maxPitch=25, fov=18,  duration=350, offset=math.rad(10), overlap=0.5, min_interval=5,name="SA342M EO/IR LIGHT RECO" }
TARS.parameters["SA342L"]        = { minAlt=20,   maxAlt=1000, maxRoll=35, maxPitch=25, fov=18,  duration=350, offset=math.rad(10), overlap=0.5, min_interval=5,name="SA342L EO/IR LIGHT RECO" }
TARS.parameters["OH58D"]         = { minAlt=30,   maxAlt=1200, maxRoll=35, maxPitch=25, fov=12,  duration=350, offset=math.rad(12), overlap=0.5, min_interval=5,name="OH-58D MMS EO/IR RECO" }
TARS.parameters["UH-1H"]  = { maxRoll=50, maxPitch=45, duration=900, offset=math.rad(6), name="UH-1H VISUAL/CREW RECO",          minAlt=TARS._vAltMin, minRange=TARS._vRangeMin, optimalAlt=TARS._vAltOpti, optimalRange=TARS._vRangeOpti, maxAlt=TARS._vAltMax, maxRange=TARS._vRangeMax }
TARS.parameters["Mi-8MT"] = { maxRoll=50, maxPitch=45, duration=900, offset=math.rad(6), name="Mi-8MT VISUAL/CREW RECO",         minAlt=TARS._vAltMin, minRange=TARS._vRangeMin, optimalAlt=TARS._vAltOpti, optimalRange=TARS._vRangeOpti, maxAlt=TARS._vAltMax, maxRange=TARS._vRangeMax }
TARS.parameters["MH-6J"]  = { maxRoll=50, maxPitch=45, duration=900, offset=math.rad(6), name="MH-6J VISUAL CLOSE RECO",         minAlt=TARS._vAltMin, minRange=TARS._vRangeMin, optimalAlt=TARS._vAltOpti, optimalRange=TARS._vRangeOpti, maxAlt=TARS._vAltMax, maxRange=TARS._vRangeMax }
TARS.parameters["OH-6A"]  = { maxRoll=50, maxPitch=45, duration=900, offset=math.rad(6), name="OH-6A Cayuse VISUAL CLOSE RECO",  minAlt=TARS._vAltMin, minRange=TARS._vRangeMin, optimalAlt=TARS._vAltOpti, optimalRange=TARS._vRangeOpti, maxAlt=TARS._vAltMax, maxRange=TARS._vRangeMax }

-------------------------------------------------
-- TODO ALLOWED WEAPONS WHITELIST
-------------------------------------------------

--- @field #table allowedAmmo
TARS.allowedAmmo = {
    ["AIM-9B"]=true,["AIM-9D"]=true,["AIM-9E"]=true,["AIM-9G"]=true,
    ["AIM-9H"]=true,["AIM-9J"]=true,["AIM-9L"]=true,["AIM-9M"]=true,
    ["AIM-9N"]=true,["AIM-9P"]=true,["AIM-9P3"]=true,["AIM-9P5"]=true,
    ["AIM-9JULI"]=true,
    ["R-3S"]=true,["R-13M"]=true,["R-13M1"]=true,["R-60"]=true,["R-60M"]=true,
    ["R550 Magic II"]=true,
    ["7_62x51"]=true,
}

-------------------------------------------------
-- TODO RUNTIME STATE
-------------------------------------------------

TARS.instances       = {}
TARS.groundMenus     = {}
TARS.detectedTargets = {}
TARS.marks           = { blue={}, red={} }
TARS.redMarkCount    = 150000
TARS.blueMarkCount   = 160000
TARS.scoring         = nil

-------------------------------------------------
-- LOCALE CONFIGURATION
-------------------------------------------------
 
--- Active locale used by `TARS:_T()`. Set before `TARS:New()`.
-- @field #string locale
TARS.locale = "en"
 
-------------------------------------------------
-- MESSAGE TABLE
-------------------------------------------------
 
--- Nested localization table: `TARS.Messages[locale][messageID] = string`.
-- @field #table Messages
TARS.Messages = {
 
    -- ==========================================================
    -- ENGLISH
    -- ==========================================================
    en = {
        -- Capture state
        TARS_FILM_START           = "[TARS] Capture activated. Expositions remaining: %d",
        TARS_FILM_EXHAUSTED       = "[TARS] Film exhausted. Return to base for debrief.",
        TARS_FILM_STOP            = "[TARS] Session capture ended. Return to base for debrief.",
        TARS_FILM_TIME_UP         = "[TARS] Film time exhausted. Return to base.",
        TARS_FILM_CAP_REACHED     = "[TARS] Maximum captures reached (%d). Return to base for debrief.",
        TARS_FILM_STB_MANUAL      = "[TARS] <>Manual<> Film manual STB.",
        TARS_FILM_RESUME_MANUAL   = "[TARS] <>Manual<> Film manual resume.",
        TARS_FILM_STB_LAND        = "[TARS] <>Landing<> Film auto STB.",
        TARS_FILM_RESUME_TO       = "[TARS] <>TakeOff<> Film auto resume. %d expositions",
        TARS_FILM_STB_LOCKED      = "[TARS] Film is STB — takeoff to resume.",
        TARS_FILM_ALREADY_ACTIVE  = "[TARS] Film already active.",
        TARS_FILM_NO_CAPTURE      = "[TARS] No active film.",
        TARS_FILM_NO_CAPTURE_STOP = "[TARS] No active film to stop.",
        TARS_CAPTURE_TICK         = "EXPOSITIONS REMAINING: %d",
        TARS_CAPTURE_HIT          = "[TARS] +1 Captured target (%d total)",
        TARS_CAPTURE_HIT_MAX      = "[TARS] +1 Captured target (%d total) / %d max",
 
        -- Session / debrief
        TARS_SESSION_ENDED        = "[TARS] Session ended. Return to base for debrief.",
        TARS_LAND_VALIDATED       = "[TARS] Landing validated, await your debriefing!",
        TARS_LAND_VALIDATED_TIME  = "[TARS] Targets shown in %d seconds.",
        TARS_NOT_AT_BASE          = "[TARS] Not on allied base or FARP. Return for debrief.",
        TARS_DEBRIEF_TARGETS      = "[TARS] %d targets captured. +%d points.",
        TARS_DEBRIEF_CREDITS      = "You received %d credits for reconnaissance.",
        TARS_DEBRIEF_COALITION    = "%s gathered intel on %d targets.",
        TARS_READY                = "[TARS] Ready for recon.",
 
        -- Validation
        TARS_VALID_OK_HDR         = "[TARS] Configuration is valid - Ready for takeoff",
        TARS_VALID_REFUSED_WPN    = "[TARS] Your configuration loadout is not ready. Check your weapons.",
        TARS_VALID_REFUSED_AMMO   = "Refused : ammo %s",
        TARS_VALID_AIRBORNE       = "[TARS] Validation only on ground.",
        TARS_VALID_RUNNING        = "[TARS] Validation already done — film is running.",
        TARS_VALID_GROUP_FILTER   = "[TARS] Task available for group name >%s< only.",
        TARS_VALIDATE_FIRST       = "[TARS] Validate first on ground.",
        TARS_NO_SESSION           = "[TARS] No session actived.",
        TARS_CONFIG_CHANGED       = "[TARS] Config changed — session ended.",
        TARS_LOADOUT_BAD          = "[TARS] Loadout not ready. Check your weapons.",
 
        -- Platform info labels
        TARS_PLATFORM_INFO        = "[TARS] Platform information",
        TARS_PLATFORM_LABEL       = "Platform",
        TARS_PLATFORM_ALT         = "Altitude",
        TARS_PLATFORM_FOV         = "FOV",
        TARS_PLATFORM_FILM        = "Film",
 
        -- F10 menu item labels
        TARS_MENU_ROOT            = "Task TARS",
        TARS_MENU_VALIDATE        = "TARS validation",
        TARS_MENU_INFO            = "TARS my capture config",
        TARS_MENU_START           = "TARS mode : Start filming",
        TARS_MENU_STB             = "TARS mode : Standby & Resume",
        TARS_MENU_STOP            = "TARS mode : Stop filming",
    },
 
    -- ==========================================================
    -- DEUTSCH
    -- ==========================================================
    de = {
        -- Aufnahmestatus
        TARS_FILM_START           = "[TARS] Aufnahme aktiviert. Verbleibende Aufnahmen: %d.",
        TARS_FILM_EXHAUSTED       = "[TARS] Film aufgebraucht. Kehren Sie zur Basis für das Briefing zurück.",
        TARS_FILM_STOP            = "[TARS] Aufnahmesitzung beendet. Kehren Sie zur Basis zurück.",
        TARS_FILM_TIME_UP         = "[TARS] Filmzeit abgelaufen. Kehren Sie zur Basis zurück.",
        TARS_FILM_CAP_REACHED     = "[TARS] Maximale Aufnahmen erreicht (%d). Kehren Sie zur Basis zurück.",
        TARS_FILM_STB_MANUAL      = "[TARS] <>Manuell<> Film manuell auf Standby.",
        TARS_FILM_RESUME_MANUAL   = "[TARS] <>Manuell<> Film manuell fortgesetzt.",
        TARS_FILM_STB_LAND        = "[TARS] <>Landung<> Film automatisch auf Standby.",
        TARS_FILM_RESUME_TO       = "[TARS] <>Takeoff<> Film fortgesetzt. %d Aufnahmen.",
        TARS_FILM_STB_LOCKED      = "[TARS] Film ist auf Standby — starten Sie, um fortzufahren.",
        TARS_FILM_ALREADY_ACTIVE  = "[TARS] Aufnahme bereits aktiv.",
        TARS_FILM_NO_CAPTURE      = "[TARS] Keine aktive Aufnahme.",
        TARS_FILM_NO_CAPTURE_STOP = "[TARS] Keine aktive Aufnahme zum Stoppen.",
        TARS_CAPTURE_TICK         = "Verbleibende Aufnahmen: %d.",
        TARS_CAPTURE_HIT          = "[TARS] +1 Ziel erfasst (%d gesamt)",
        TARS_CAPTURE_HIT_MAX      = "[TARS] +1 Ziel erfasst (%d gesamt) / %d max",
 
        -- Sitzung / Briefing
        TARS_SESSION_ENDED        = "[TARS] Sitzung beendet. Kehren Sie zur Basis für das Briefing zurück.",
        TARS_LAND_VALIDATED       = "[TARS] Landung erfolgreich, bitte warten Sie auf Ihr Debriefing!",
        TARS_LAND_VALIDATED_TIME  = "[TARS] Ziele werden in %d Sekunden angezeigt.",
        TARS_NOT_AT_BASE          = "[TARS] Nicht auf verbündeter Basis oder FARP. Kehren Sie zurück.",
        TARS_DEBRIEF_TARGETS      = "[TARS] %d Ziele erfasst. +%d Punkte.",
        TARS_DEBRIEF_CREDITS      = "Sie erhalten %d Credits für die Aufklärung.",
        TARS_DEBRIEF_COALITION    = "%s hat Informationen über %d Ziele gesammelt.",
        TARS_READY                = "[TARS] Bereit zur Aufklärung.",
 
        -- Validierung
        TARS_VALID_OK_HDR         = "[TARS] Konfiguration gültig - Bereit zum Start",
        TARS_VALID_REFUSED_WPN    = "[TARS] Ihre Konfiguration ist nicht bereit. Überprüfen Sie Ihre Waffen.",
        TARS_VALID_REFUSED_AMMO   = "Abgelehnt : Munition %s",
        TARS_VALID_AIRBORNE       = "[TARS] Validierung nur am Boden möglich.",
        TARS_VALID_RUNNING        = "[TARS] Validierung bereits erfolgt — Film läuft.",
        TARS_VALID_GROUP_FILTER   = "[TARS] Aufgabe nur für Gruppenname >%s< verfügbar.",
        TARS_VALIDATE_FIRST       = "[TARS] Zuerst am Boden validieren.",
        TARS_NO_SESSION           = "[TARS] Keine aktive Sitzung.",
        TARS_CONFIG_CHANGED       = "[TARS] Konfiguration geändert — Aufnahme beendet.",
        TARS_LOADOUT_BAD          = "[TARS] Ausrüstung nicht bereit. Überprüfen Sie Ihre Waffen.",
 
        -- Plattforminformationen
        TARS_PLATFORM_INFO        = "[TARS] Plattforminformationen",
        TARS_PLATFORM_LABEL       = "Plattform",
        TARS_PLATFORM_ALT         = "Höhe",
        TARS_PLATFORM_FOV         = "Sichtfeld",
        TARS_PLATFORM_FILM        = "Film",
 
        -- F10-Menüeinträge
        TARS_MENU_ROOT            = "Aufgabe TARS",
        TARS_MENU_VALIDATE        = "TARS Validierung",
        TARS_MENU_INFO            = "TARS meine Aufnahmekonfiguration",
        TARS_MENU_START           = "TARS Modus : Aufnahme starten",
        TARS_MENU_STB             = "TARS Modus : Standby & Fortsetzen",
        TARS_MENU_STOP            = "TARS Modus : Aufnahme stoppen",
    },
 
    -- ==========================================================
    -- FRANÇAIS
    -- ==========================================================
    fr = {
        -- État de capture
        TARS_FILM_START           = "[TARS] Capture activée. Expositions restantes : %d",
        TARS_FILM_EXHAUSTED       = "[TARS] Film épuisé. Retournez à la base pour le compte-rendu.",
        TARS_FILM_STOP            = "[TARS] Session de capture terminée. Retournez à la base.",
        TARS_FILM_TIME_UP         = "[TARS] Temps de film épuisé. Retournez à la base.",
        TARS_FILM_CAP_REACHED     = "[TARS] Nombre maximum de captures atteint (%d). Retournez à la base.",
        TARS_FILM_STB_MANUAL      = "[TARS] <>Manuel<> Film en STB manuel.",
        TARS_FILM_RESUME_MANUAL   = "[TARS] <>Manuel<> Reprise manuel du film.",
        TARS_FILM_STB_LAND        = "[TARS] <>Atterrissage<> Film en STB automatique.",
        TARS_FILM_RESUME_TO       = "[TARS] <>Décollage<> Film repris. %d expositions",
        TARS_FILM_STB_LOCKED      = "[TARS] Film en STB — décollez pour reprendre.",
        TARS_FILM_ALREADY_ACTIVE  = "[TARS] Film déjà activé.",
        TARS_FILM_NO_CAPTURE      = "[TARS] Aucun film activé.",
        TARS_FILM_NO_CAPTURE_STOP = "[TARS] Aucun film actif à stopper.",
        TARS_CAPTURE_TICK         = "[TARS] EXPOSITIONS RESTANTES : %d",
        TARS_CAPTURE_HIT          = "[TARS] +1 Cible capturée (%d au total)",
        TARS_CAPTURE_HIT_MAX      = "[TARS] +1 Cible capturée (%d au total) / %d max",
 
        -- Session / compte-rendu
        TARS_SESSION_ENDED        = "[TARS] Session terminée. Retournez à la base pour le debriefing.",
        TARS_LAND_VALIDATED       = "[TARS] Atterrissage validé, attendez votre debriefing !",
        TARS_LAND_VALIDATED_TIME  = "[TARS] Cibles affichées dans %d seconds.",
        TARS_NOT_AT_BASE          = "[TARS] Vous n'êtes pas sur une base ou FARP alliée. Retourné pour le debriefing.",
        TARS_DEBRIEF_TARGETS      = "[TARS] %d cibles capturées. +%d points.",
        TARS_DEBRIEF_CREDITS      = "Vous avez reçu %d crédits pour la reconnaissance.",
        TARS_DEBRIEF_COALITION    = "%s a recueilli des renseignements sur %d cibles.",
        TARS_READY                = "[TARS] Prêt pour la reconnaissance.",
 
        -- Validation
        TARS_VALID_OK_HDR         = "[TARS] Configuration valide - Prêt au décollage",
        TARS_VALID_REFUSED_WPN    = "[TARS] Votre configuration n'est pas prête. Vérifiez vos armes.",
        TARS_VALID_REFUSED_AMMO   = "Refusé : munition %s",
        TARS_VALID_AIRBORNE       = "[TARS] Validation uniquement au sol.",
        TARS_VALID_RUNNING        = "[TARS] Validation déjà effectuée — le film tourne.",
        TARS_VALID_GROUP_FILTER   = "[TARS] Tâche disponible pour le groupe >%s< uniquement.",
        TARS_VALIDATE_FIRST       = "[TARS] Validez d'abord au sol.",
        TARS_NO_SESSION           = "[TARS] Aucune session active.",
        TARS_CONFIG_CHANGED       = "[TARS] Configuration modifiée — session terminée.",
        TARS_LOADOUT_BAD          = "[TARS] Chargement pas prêt. Vérifiez vos armes.",
 
        -- Informations plateforme
        TARS_PLATFORM_INFO        = "[TARS] Informations sur la plateforme",
        TARS_PLATFORM_LABEL       = "Plateforme",
        TARS_PLATFORM_ALT         = "Altitude",
        TARS_PLATFORM_FOV         = "Champ de vision",
        TARS_PLATFORM_FILM        = "Film",
 
        -- Entrées menu F10
        TARS_MENU_ROOT            = "Mission TARS",
        TARS_MENU_VALIDATE        = "TARS validation",
        TARS_MENU_INFO            = "TARS ma config de capture",
        TARS_MENU_START           = "TARS mode : Démarrer le film",
        TARS_MENU_STB             = "TARS mode : Standby & Reprise",
        TARS_MENU_STOP            = "TARS mode : Arrêter le film",
    },
}


-------------------------------------------------
-- TODO STATIC HELPERS
-------------------------------------------------

--- [INTERNAL] Returns the aircraft's signed bank/roll angle in radians.
-- @param Wrapper.Unit#UNIT mooseUnit The recon aircraft.
-- @return #number Roll angle in radians.
function TARS.getRoll(mooseUnit)
    return mooseUnit:GetRoll() or 0
end

--- [INTERNAL] Returns the aircraft's pitch angle in radians.
-- @param Wrapper.Unit#UNIT mooseUnit The recon aircraft.
-- @return #number Pitch angle in radians.
function TARS.getPitch(mooseUnit)
    return mooseUnit:GetPitch() or 0
end

--- Maps a 0–100 health value to a human-readable damage status label.
-- @param #number life Health percentage (0–100), or nil.
-- @return #string Damage label.
function TARS.life2text(life)
    if     life == nil then return "Undefined"
    elseif life > 90   then return "No damage"
    elseif life > 70   then return "Slightly damage"
    elseif life > 40   then return "Damaged"
    elseif life > 20   then return "Major damage"
    elseif life > 0    then return "Destroyed"
    else                    return "Undefined"
    end
end

-------------------------------------------------
-- TODO TARS_SESSION — constructor + methods
-------------------------------------------------

--- [INTERNAL] Populates all shared fields from a MOOSE UNIT object.
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT unit The recon aircraft's MOOSE UNIT.
function TARS_SESSION:_SetSharedParams(unit)
    self:T(self.lid.."_SetSharedParams")
    self.unit       = unit
    self.vec3       = unit:GetVec3()
    self.coa        = unit:GetCoalition()
    self.type       = unit:GetTypeName()
    self.group      = unit:GetGroup()
    self.groupID    = unit:GetGroup():GetID()
    self.objectName = unit:GetName()
    self.playerName = unit:GetPlayerName()
    self.playerID   = unit:GetID()
    self.ammo       = unit:GetAmmo()
    self.time       = timer.getTime()
end

--- [INTERNAL] Refreshes aircraft references WITHOUT resetting sortie state.
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT unit The recon aircraft's MOOSE UNIT.
function TARS_SESSION:SetObjectParamsLight(unit)
    self:T2(self.lid.."SetObjectParamsLight")
    self:_SetSharedParams(unit)
end

--- [INTERNAL] Fully initialises (or resets) all sortie state.
-- After a debrief reset, re-adds the validation menu item (GROUND_NEW state).
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT unit The recon aircraft's MOOSE UNIT.
-- @return #TARS_SESSION self
function TARS_SESSION:SetObjectParams(unit)
    self:T(self.lid.."SetObjectParams")
    self:_SetSharedParams(unit)
    self.category         = unit:GetGroup():GetCategory()
    self.capturing        = false
    self.duration         = TARS.parameters[self.type].duration
    self.targetList       = {}
    self.captureCount     = 0
    self.loop             = false
    self.standby          = false
    self.filmExhausted    = false
    self.sessionEnded     = false
    self.wasCapturing     = false
    self.landingScheduled = false
    if self.playerName and TARS.groundMenus[self.playerName] and self.Callback then
        self.Callback:_MenuAddValidation(self.playerName)
    end
    return self
end

--- [INTERNAL] Creates a new TARS_SESSION for the given MOOSE UNIT.
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT unit The recon aircraft's MOOSE UNIT.
-- @param #TARS Callback The TARS singleton (for callbacks and config access).
-- @return #TARS_SESSION self The newly created session.
function TARS_SESSION:New(unit, Callback)
    local self = BASE:Inherit(self, BASE:New())
    self.lid      = string.format("TARS_SESSION %s | ", TARS.version)
    self.Callback = Callback
    self.PilotParameterHelper = Callback.PilotParameterHelper
    self:SetObjectParams(unit)
    self:T("TARS_SESSION created — unit=" .. tostring(self.objectName)
        .. " type=" .. tostring(self.type))
    return self
end

--- [INTERNAL] Merges a `FindTargets` result into this session's target list.
-- Notifies the player per new detection using the active locale.
-- @param #TARS_SESSION self
-- @param #table list Map of `[unitName] = Wrapper.Unit#UNIT` from `TARS_SESSION:FindTargets()`.
function TARS_SESSION:AddToTargetList(list)
    self:T(self.lid.."AddToTargetList")
    for k, v in pairs(list) do
        if self.targetList[k] == nil then
            self.targetList[k] = self:_FreezeUnit(v)
            self.captureCount  = (self.captureCount or 0) + 1
            local msg
            if TARS.filmLimitEnabled then
                msg = self.Callback:_Txt("TARS_CAPTURE_HIT_MAX",
                    self.captureCount, TARS.filmLimitMax)
            else
                msg = self.Callback:_Txt("TARS_CAPTURE_HIT", self.captureCount)
            end
            self.Callback:_MsgUnit(msg, 4, self.playerName)
        end
    end
end

--- [INTERNAL] Publishes all captured targets as F10 coalition marks.
-- @param #TARS_SESSION self
-- @return #number count Number of marks placed or updated this debrief.
function TARS_SESSION:ReturnReconTargets()
    self:T(self.lid.."ReturnReconTargets")
    local count = 0
    for k, v in next, self.targetList do
        if v.unit and v.unit:IsAlive() then
            local existing = self.Callback.detectedTargets[v.name]
            if not existing then
                count = count + 1
                self.Callback:OutMark(v, self.coa)
                self.Callback.detectedTargets[v.name] = v
                self:T("New target: " .. v.type .. "/" .. v.name)
            elseif existing.life ~= v.life then
                local markID = TARS.marks.blue[v.name] or TARS.marks.red[v.name]
                if markID then trigger.action.removeMark(markID) end
                count = count + 1
                self.Callback:OutMark(v, self.coa)
                self.Callback.detectedTargets[v.name] = v
                self:T("Updated " .. v.name .. " life "
                    .. tostring(existing.life) .. "→" .. tostring(v.life))
            end
        end
        self.targetList[k] = nil
    end
    return count
end

--- [INTERNAL] Starts the dynamic-interval capture loop.
-- The first tick fires after 2 seconds; subsequent ticks are spaced by
-- `_CalcInterval()` which adapts to the aircraft's current speed and altitude.
-- @param #TARS_SESSION self
function TARS_SESSION:CaptureData()
    self:T(self.lid.."CaptureData")
    if self.duration <= 0 then
        self.Callback:_MsgUnit(
            self.Callback:_Txt("TARS_FILM_EXHAUSTED"), 2, self.playerName)
        return
    end
    self.capturing = true
    self.loop      = true
    self.standby   = false
    self:T("FILM START — film=" .. self.duration .. "s")
    self.Callback:_MsgUnit(
        self.Callback:_Txt("TARS_FILM_START", self.duration), 5, self.playerName)
    timer.scheduleFunction(TARS_SESSION.CaptureLoop, self, timer.getTime() + 2)
end

--- [INTERNAL] Removes this session from the global registry.
-- @param #TARS_SESSION self
function TARS_SESSION:Delete()
    self:T(self.lid.."Delete")
    TARS.instances[self.objectName] = nil
end

--- [INTERNAL] Returns a unit's current health as a 0–100 percentage.
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT unit
-- @return #number Health 0–100, or nil.
function TARS_SESSION:_NormalizeLife(unit)
    if not unit or not unit:IsAlive() then return nil end
    local rlife = unit:GetLifeRelative() * 100
    if rlife == -1 then return nil end
    return rlife
end

--- [INTERNAL] Freezes a MOOSE object into a `TARS.Snapshot`.
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT _Object MOOSE UNIT or STATIC.
-- @return #TARS.Snapshot snap
function TARS_SESSION:_FreezeUnit(_Object)
    self:T(self.lid.."_FreezeUnit")
    local snap    = {}
    snap.unit     = _Object
    snap.dcsObj   = _Object:GetDCSObject()
    snap.category = _Object:GetCategory()
    snap.type     = _Object:GetTypeName()
    snap.name     = _Object:GetName()
    snap.point    = _Object:GetVec3()
    snap.time     = timer.getTime()
    if snap.category == Object.Category.UNIT and _Object then
        snap.groupID  = _Object:GetGroup():GetID()
        snap.groupCat = _Object:GetGroup():GetCategory()
        snap.coa      = _Object:GetCoalition()
        snap.ammo     = _Object:GetAmmo()
        snap.life     = self:_NormalizeLife(_Object)
    end
    snap.playername = self.playerName
    return snap
end

--- [INTERNAL] Calculates the 2-D ground point ahead of the aircraft.
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT unit
-- @param #TARS.PlatformParams params
-- @param #number center_shift shift value
-- @return #table `{ x, z, MSL, alt }` ahead of the aircraft.
function TARS_SESSION:_OffsetCalc(unit, params, center_shift)
    center_shift = center_shift or 0
    local pos  = unit:GetPosition()
    local vec3 = unit:GetVec3()
    local MSL  = land.getHeight({ x = vec3.x, y = vec3.z })
    local alt  = vec3.y - MSL
    local rad  = math.atan2(pos.x.x, pos.x.z)   -- ← unverändert
    local dist = (alt / math.tan(params.offset)) + center_shift
    return {
        x   = vec3.x + math.sin(rad) * dist,
        z   = vec3.z + math.cos(rad) * dist,
        MSL = MSL,
        alt = alt,
        rad = rad,   -- ← NEU: mitgeben für isInEllipse
    }
end

--- [INTERNAL] Validates a single DCS/MOOSE object against all active filters.
-- Returns true if the object should be added to the target list.
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT _Object MOOSE UNIT or STATIC.
-- @return #boolean
function TARS_SESSION:_ValidateObjectFound(_Object)
    self:T(self.lid.."_ValidateObjectFound " .. tostring(_Object:GetName()))

    if not (_Object and _Object:IsAlive()) then return false end
    if _Object:GetCoalition() == self.coa   then return false end

    if self.Callback.targetNameFilter.enabled then
        local keywords   = self.Callback.targetNameFilter.keywords[_Object:GetCoalition()]
        local targetName = string.lower(_Object:GetName() or "")
        local targetGroup
        local targetGroupName
        if _Object:IsInstanceOf("UNIT") then
          targetGroup = _Object:GetGroup()
          if targetGroup then targetGroupName = string.lower(targetGroup:GetName()) end
        end
        if type(keywords) == "string" then keywords = { keywords } end
        local matched = false
        for _, kw in pairs(keywords or {}) do
            if string.find(targetName, string.lower(kw)) then matched = true; break end
            -- noob catch
            if targetGroupName and string.find(targetName, string.lower(kw)) then matched = true; break end
        end
        if not matched then return false end
    end

    local typeName      = _Object:GetTypeName()
    local typeNameLower = string.lower(typeName)
    local objCat        = _Object:GetCategory()
    
    self:T(self.lid.."_ValidateObjectFound Name Filter Passed!")
     
    if objCat == Object.Category.UNIT then
        local desc    = _Object:GetDesc()
        local unitCat = desc and desc.category
        self:T(self.lid.."_ValidateObjectFound Name Category Check "..tostring(unitCat))
        if     unitCat == Unit.Category.AIRPLANE or unitCat == Unit.Category.HELICOPTER then
            return self.Callback.units.air
        elseif unitCat == Unit.Category.GROUND_UNIT then
            return self.Callback.units.ground
        elseif unitCat == Unit.Category.SHIP then 
            return self.Callback.units.ship
        end
    elseif objCat == Object.Category.STATIC or objCat == Object.Category.BASE then
        if self.Callback.statics.farps and string.find(typeNameLower, "farp") then
            return true
        end
        if self.Callback.statics.captureUnique then
            return self.Callback.statics.captureUniqueList[typeName] == true
        elseif self.Callback.statics.captureExceptions then
            for _, exName in pairs(self.Callback.statics.captureExceptionsList) do
                if string.find(typeNameLower, string.lower(exName)) then return true end
            end
        end
    end
    return false
end

--- [INTERNAL] Main capture tick. Scheduled dynamically via `timer.scheduleFunction`.
-- The interval between ticks is calculated from the aircraft's current speed
-- and camera footprint via `_CalcInterval()`, ensuring adequate frame overlap
-- regardless of whether the platform is a slow helicopter or a fast jet.
-- `duration` is decremented by the actual interval each tick.
-- @param #TARS_SESSION self The active session (timer data argument).
-- @return nil
function TARS_SESSION:CaptureLoop()
    if not self or not self.loop then return end

    -- Standby: keep the timer alive but don't capture or decrement film
    if self.capturing and self.standby then
        timer.scheduleFunction(TARS_SESSION.CaptureLoop, self, timer.getTime() + 10)
        return
    end

    if self.capturing and self.duration > 0 then
        -- Dynamic interval based on current speed and altitude
        local params   = self.Callback.parameters[self.type]
        local interval = self:_CalcInterval(self.unit, params)

        self.duration = self.duration - 1
        self.Callback:_MsgUnit(
            self.Callback:_Txt("TARS_CAPTURE_TICK", math.max(0, math.floor(self.duration))),
            math.min(interval, 9), self.playerName,true)

        self:AddToTargetList(self:FindTargets())

        if self.Callback.filmLimitEnabled
                and self.captureCount >= self.Callback.filmLimitMax then
            self.Callback:_MsgUnit(
                self.Callback:_Txt("TARS_FILM_CAP_REACHED", self.Callback.filmLimitMax),
                8, self.playerName)
            self.Callback:StopCapture(self)
            return
        end

        -- Debug: show interval when debugunitsearch is active
        if self.debugunitsearch then
            self:T(self.lid .. string.format(
                "CaptureLoop interval=%.1fs duration=%.0fs", interval, self.duration))
        end

        timer.scheduleFunction(TARS_SESSION.CaptureLoop, self, timer.getTime() + interval)
    end

    if self.duration <= 0 and self.loop then
        self.loop = false
        self.Callback:_MsgUnit(
            self.Callback:_Txt("TARS_FILM_TIME_UP"), 8, self.playerName)
        self.Callback:StopCapture(self)
    end
end

--- [INTERNAL] Two-segment linear interpolation for visual-recon helicopter range.
-- @param #TARS_SESSION self
-- @param #TARS.PlatformParams params
-- @param #number altitude AGL in metres.
-- @return #number radius Detection sphere radius in metres.
function TARS_SESSION:_CalcVisualRange(params, altitude)
    if altitude <= params.minAlt then
        return params.minRange
    elseif altitude <= params.optimalAlt then
        local t = (altitude - params.minAlt) / (params.optimalAlt - params.minAlt)
        return params.minRange + t * (params.optimalRange - params.minRange)
    elseif altitude <= params.maxAlt then
        local t = (altitude - params.optimalAlt) / (params.maxAlt - params.optimalAlt)
        return params.optimalRange + t * (params.maxRange - params.optimalRange)
    else
        return params.maxRange
    end
end

--- [INTERNAL] Calculates the capture interval in seconds based on current speed and altitude.
-- Uses the camera footprint width and the configured overlap to determine how long
-- the aircraft needs to travel before the next frame is needed.
-- Clamped between 5 and 120 seconds to prevent extreme values.
-- @param #TARS_SESSION self
-- @param Wrapper.Unit#UNIT unit The recon aircraft.
-- @param #TARS.PlatformParams params Platform parameter table.
-- @return #number interval Capture interval in seconds.
function TARS_SESSION:_CalcInterval(unit, params)
    -- Current AGL from last offset calculation (reuse if available, else recalc)
    local vec3 = unit:GetVec3()
    local alt  = vec3.y - land.getHeight({ x = vec3.x, y = vec3.z })
    alt = math.max(alt, 1)  -- guard against on-ground edge case

    -- Footprint half-width b (cross-track) at current altitude
    local elev     = params.offset
    local half_fov = math.rad(params.fov / 2)
    local d_ground = alt / math.tan(elev)
    local b        = d_ground * math.tan(half_fov)
    local diameter = 2 * b

    -- Current ground speed in m/s
    local vel   = unit:GetVelocityVec3()
    local speed = math.sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z)
    speed = math.max(speed, 10)  -- minimum 10 m/s to avoid division near zero

    -- Interval = footprint diameter × (1 - overlap) / speed
    local overlap  = params.overlap or 0.5
    local interval = (diameter * (1 - overlap)) / speed
  
    local min_interval = params.min_interval or 2
    return math.max(min_interval, math.min(120, interval))
end

--- [INTERNAL] Checks a point is inside of an elipse
-- @return #boolean IsInElipse
function TARS_SESSION.isInEllipse(ox, oz, cx, cz, a, b, heading_rad)
    -- heading_rad ist jetzt direkt in Radians (aus offset.rad)
    local dx    = ox - cx
    local dz    = oz - cz
    local cos_h = math.cos(heading_rad)   -- ← kein math.rad() mehr
    local sin_h = math.sin(heading_rad)
    local lx    =  dx * sin_h + dz * cos_h
    local ly    = -dx * cos_h + dz * sin_h
    return (lx/a)^2 + (ly/b)^2 <= 1
end

--- [INTERNAL] earches for targets in a sphere ahead of the aircraft.
-- @param #TARS_SESSION self
-- @return #table `[unitName] = Wrapper.Unit#UNIT`
--- [INTERNAL] Searches for targets in an elliptical footprint ahead of the aircraft.
-- @param #TARS_SESSION self
-- @return #table `[unitName] = Wrapper.Unit#UNIT`
function TARS_SESSION:FindTargets()
    local unit   = self.unit
    local params = self.Callback.parameters[self.type]

    -- Attitude check
    local roll   = math.abs(TARS.getRoll(unit))
    local pitch  = math.abs(TARS.getPitch(unit))
    local isFlat = roll < params.maxRoll and pitch < params.maxPitch

    -- Ellipsen-Geometrie berechnen
    local elev     = params.offset                  -- Radians, Blickwinkel nach vorne
    local half_fov = math.rad(params.fov / 2)

    local center_shift = 0
    local a, b

    -- Offset berechnen (gibt jetzt MSL und alt mit zurück)
    local offset_data = self:_OffsetCalc(unit, params, 0)  -- erst ohne shift
    local alt         = offset_data.alt
    local MSL         = offset_data.MSL

    -- Querachse b
    local d_ground = alt / math.tan(elev)
    b = d_ground * math.tan(half_fov)

    -- Längsachse a + center_shift, nur wenn geometrisch gültig
    if (elev - half_fov) > math.rad(2) then
        local d_near   = alt / math.tan(elev + half_fov)
        local d_far    = alt / math.tan(elev - half_fov)
        a              = (d_far - d_near) / 2
        center_shift   = (d_far + d_near) / 2 - d_ground
    else
        a            = b   -- Fallback: Kreis
        center_shift = 0
        self:T(self.lid .. "FindTargets: elev-fov margin too small, fallback to circle")
    end

    -- Offset-Punkt mit korrektem center_shift
    local offset = self:_OffsetCalc(unit, params, center_shift)

    -- Nach: local offset = self:_OffsetCalc(unit, params, center_shift)
    local unit_pos = unit:GetVec3()
    local hdg = unit:GetHeading()
    -- Erwarteter Offset-Punkt: Flugzeug + (d_ground+shift) in Flugrichtung
    local expected_x = unit_pos.x + math.sin(math.rad(hdg)) * (d_ground + center_shift)
    local expected_z = unit_pos.z + math.cos(math.rad(hdg)) * (d_ground + center_shift)
    self:T(string.format(
        "OFFSET DRIFT: _OffsetCalc=(%.0f,%.0f)  expected=(%.0f,%.0f)  drift=(Δx=%.0f,Δz=%.0f)",
        offset.x, offset.z,
        expected_x, expected_z,
        offset.x - expected_x,
        offset.z - expected_z))
    
    -- Koordinate aktualisieren
    local coordinate = self.coordinate
        or COORDINATE:New(offset.x, offset.MSL, offset.z)
    coordinate = coordinate:UpdateFromVec3({ x = offset.x, y = offset.MSL, z = offset.z })
    self.coordinate = coordinate

    -- Scan-Radius = längere Halbachse, deckt die Ellipse vollständig ab
    local scan_radius = math.max(a, b)

    -- Heading für Ellipsen-Rotation
    local heading = unit:GetHeading()

    -- Debug-Visualisierung
    if self.debugunitsearch then
        local searchzone = self.searchzone  -- Core.Zone#ZONE_BASE
            or ZONE_RADIUS:New("TARS Debug", coordinate:GetVec2(), scan_radius)

        if searchzone.DrawID then searchzone:UndrawZone() end
        searchzone:UpdateFromVec2(coordinate:GetVec2(), scan_radius)           
        searchzone:DrawZone(-1, {0, 0, 1}, 1, {0, 1, 0}, .2, 2, true)
        self.searchzone = searchzone
        self:ScheduleOnce(30, ZONE_BASE.UndrawZone, searchzone)
    end
    
    if self.PilotParameterHelper == true then
        self:T({ Roll = roll, Pitch = pitch, AGL = alt, a = a, b = b, shift = center_shift })

        if roll > params.maxRoll then
            MESSAGE:New(string.format("Roll - NOK out of parameters (%d°)!", roll), 9, "PARAM"):ToUnit(unit)
        elseif pitch > params.maxPitch then
            MESSAGE:New(string.format("Pitch - NOK out of parameters (%d°)!", pitch), 9, "PARAM"):ToUnit(unit)
        elseif alt < params.minAlt or alt > params.maxAlt then
            MESSAGE:New(string.format("AGL - NOK too high or too low (%dm)!", alt), 9, "PARAM"):ToUnit(unit)
        else
            MESSAGE:New(string.format("Params OK | a=%.0fm b=%.0fm shift=%.0fm", a, b, center_shift), 9, "PARAM"):ToUnit(unit)
        end
    end

    -- Scan
    local ScannedUnits   = self.Callback.detectUnits   and coordinate:ScanUnits(scan_radius)   or nil
    local ScannedStatics = self.Callback.detectStatics and coordinate:ScanStatics(scan_radius) or nil

    -- Ziele filtern
    local targetList = {}
    if alt > params.minAlt and alt < params.maxAlt and isFlat then
    
        for _, u in pairs(ScannedUnits and ScannedUnits.Set or {}) do
            if self:_ValidateObjectFound(u) then
                local uv = u:GetVec3()
                local dx = uv.x - offset.x
                local dz = uv.z - offset.z
                local cos_h = math.cos(offset.rad)   -- ← offset.rad statt math.rad(heading)
                local sin_h = math.sin(offset.rad)
                local lx =  dx * sin_h + dz * cos_h
                local ly = -dx * cos_h + dz * sin_h
                local ellipse_val = (lx/a)^2 + (ly/b)^2
                self:T(string.format(
                    "ELLIPSE CHECK '%s': dx=%.0f dz=%.0f lx=%.0f ly=%.0f val=%.2f %s",
                    u:GetName(), dx, dz, lx, ly, ellipse_val,
                    ellipse_val <= 1 and "HIT ✓" or "MISS (außerhalb)"))
                if ellipse_val <= 1 then   -- ← direkt val nutzen, kein zweiter isInEllipse-Call
                    targetList[u:GetName()] = u
                end
            end
        end
    
        for _, s in pairs(ScannedStatics and ScannedStatics.Set or {}) do
            if self:_ValidateObjectFound(s) then
                local sv = s:GetVec3()
                if TARS_SESSION.isInEllipse(sv.x, sv.z, offset.x, offset.z, a, b, offset.rad) then
                    targetList[s:GetName()] = s
                end
            end
        end
    
    end

    -- Debug SET_UNIT (nur wenn debug flag gesetzt)
    if self.debug == true then
        self:T(self.lid .. "FindTargets Debug SET_UNIT created")
        local debugunitset = SET_UNIT:New():FilterCategories("ground"):FilterCoalitions("red"):FilterOnce()
        for _, u in pairs(debugunitset and debugunitset.Set or {}) do
            if self:_ValidateObjectFound(u) then
                targetList[u:GetName()] = u
            end
        end
    end

    return targetList
end

-------------------------------------------------
-- TODO TARS — private helpers
-------------------------------------------------

--- [INTERNAL] Returns the active TARS_SESSION for a unit name, or nil.
-- @param #TARS self
-- @param #string unitName
-- @return #TARS_SESSION or nil
function TARS:GetInstance(unitName)
    local inst = self.instances[unitName]
    if inst and inst.unit and inst.unit:IsAlive() then return inst end
    self.instances[unitName] = nil
    return nil
end

--- [INTERNAL] Resolves a localized string by message ID.
-- Lookup order: `TARS.Messages[locale][id]` → `TARS.Messages["en"][id]` → raw id.
-- Passes extra arguments through `string.format` when provided.
-- @param #TARS self
-- @param #string id Message ID (key in `TARS.Messages[locale]`).
-- @param ... Optional `string.format` arguments.
-- @return #string Resolved, formatted string.
function TARS:_Txt(id, ...)
    local locale = self.locale or "en"
    local text   = (TARS.Messages[locale]   and TARS.Messages[locale][id])
                or (TARS.Messages["en"]     and TARS.Messages["en"][id])
    if not text then
        BASE:E("TARS:_T — unknown locale key '" .. tostring(id) .. "'")
        return tostring(id)
    end
    if select("#", ...) > 0 then
        local ok, result = pcall(string.format, text, ...)
        return ok and result or text
    end
    return text
end

--- [INTERNAL] Sends a localized MESSAGE to a single unit by player name.
-- @param #TARS self
-- @param #string text Resolved message text.
-- @param #number seconds Display duration in seconds.
-- @param #string playerName Player display name.
-- @param #boolean Silent Do not send via SRS if this is true.
function TARS:_MsgUnit(text, seconds, playerName, Silent)
    local unit = CLIENT:FindByPlayerName(playerName)
    if unit then
        MESSAGE:New(text, seconds, "TARS"):ToUnit(unit)
    end
    if self.debug == true then
      MESSAGE:New(text, seconds, "TARS"):ToAll()
    end
    if unit and self.SRS and (not Silent) then
        local srsText = string.gsub(text, "^%[TARS%] ?", playerName .. ", ")
        srsText = string.gsub(srsText, "[<>]", "")
        MESSAGE:New(srsText, seconds, "TARS"):ToSRS()
    end
end

--- [INTERNAL] Sends a localized MESSAGE to an entire coalition.
-- @param #TARS self
-- @param #string text Resolved message text.
-- @param #number seconds Display duration in seconds.
-- @param #number coa Coalition side (1 = Red, 2 = Blue).
function TARS:_MsgCoalition(text, seconds, coa)
    MESSAGE:New(text, seconds, "TARS"):ToCoalition(coa)
end

--- [INTERNAL] Awards credits via DCSBot (if loaded).
-- @param #TARS self
-- @param #string name Player display name.
-- @param #number points Credits to award.
-- @return #boolean `true` if credited.
function TARS:_AddUserPoints(name, points)
    if dcsbot and dcsbot.addUserPoints then
        dcsbot.addUserPoints(name, points)
        self:T(self.lid .. "AddUserPoints +" .. tostring(points) .. " for " .. tostring(name))
        return true
    end
    return false
end

--- [INTERNAL] Resolves the MOOSE UNIT for a player from the groundMenus registry.
-- @param #TARS self
-- @param #string playerName
-- @return Wrapper.Unit#UNIT unit or nil.
function TARS:_GetUnitFromPlayerName(playerName)
    local data = TARS.groundMenus[playerName]
    if not data or not data.unitName then return nil end
    return UNIT:FindByName(data.unitName)
end


-------------------------------------------------
-- F10 MENU CALLBACKS
-------------------------------------------------

--- [INTERNAL] F10 callback: ground validation.
-- @param #TARS self
-- @param #string playerName
function TARS:_CbValidate(playerName)
    local u = self:_GetUnitFromPlayerName(playerName)
    if u then self:CheckTask(u) end
end

--- [INTERNAL] F10 callback: show platform info.
-- @param #TARS self
-- @param #string playerName
function TARS:_CbInfo(playerName)
    local u = self:_GetUnitFromPlayerName(playerName)
    if not u then return end
    local inst = self:GetInstance(u:GetName())
    if inst then self:ShowPlatformInfo(inst)
    else self:_MsgUnit(self:_Txt("TARS_NO_SESSION"), 4, playerName) end
end

--- [INTERNAL] F10 callback: start capture.
-- @param #TARS self
-- @param #string playerName
function TARS:_CbStart(playerName)
    local u = self:_GetUnitFromPlayerName(playerName)
    if not u then return end
    local inst = self:GetInstance(u:GetName())
    if inst then self:Control(inst)
    else self:_MsgUnit(self:_Txt("TARS_VALIDATE_FIRST"), 5, playerName) end
end

--- [INTERNAL] F10 callback: toggle STB.
-- @param #TARS self
-- @param #string playerName
function TARS:_CbStb(playerName)
    local u = self:_GetUnitFromPlayerName(playerName)
    if not u then return end
    local inst = self:GetInstance(u:GetName())
    if inst then self:StandbyCapture(inst)
    else self:_MsgUnit(self:_Txt("TARS_FILM_NO_CAPTURE"), 4, playerName) end
end

--- [INTERNAL] F10 callback: stop capture.
-- @param #TARS self
-- @param #string playerName
function TARS:_CbStop(playerName)
    local u = self:_GetUnitFromPlayerName(playerName)
    if not u then return end
    local inst = self:GetInstance(u:GetName())
    if inst then self:StopCapture(inst)
    else self:_MsgUnit(self:_Txt("TARS_FILM_NO_CAPTURE"), 4, playerName) end
end

-------------------------------------------------
-- TODO PUBLIC METHODS
-------------------------------------------------

--- [INTERNAL] Creates and registers a new TARS_SESSION.
-- @param #TARS self
-- @param Wrapper.Unit#UNIT unit
-- @return #TARS_SESSION
function TARS:CreateInstance(unit)
    self:T(self.lid.."CreateInstance")
    local inst = TARS_SESSION:New(unit, self)
    self.instances[inst.objectName] = inst
    return inst
end

--- [INTERNAL] Validates the aircraft loadout.
-- @param #TARS self
-- @param Wrapper.Unit#UNIT unit
-- @return #boolean reconOk
-- @return #string refusedWeapon or nil
function TARS:CheckIfRecon(unit)
    if not unit then return false end
    local typeName = unit:GetTypeName()
    if not TARS.reconTypes[typeName] then return false end

    if TARS.recoNameFilter.enabled then
        local grp  = unit:GetGroup()
        local name = (grp and grp:GetName()) or unit:GetName() or ""
        if not string.find(string.lower(name), string.lower(TARS.recoNameFilter.keyword)) then
            return false
        end
    end

    if not TARS.parameters[typeName] then return false end

    local ammo = unit:GetAmmo()
    if type(ammo) ~= "table" then return true end

    for _, w in ipairs(ammo) do
        if w and w.desc then
            local name = w.desc.displayName or w.desc.typeName or w.desc.name
            if name and not TARS.allowedAmmo[name] then
                return false, name
            end
        end
    end
    return true
end

--- [INTERNAL] Validates loadout on the ground and sets the approved flag.
-- @param #TARS self
-- @param Wrapper.Unit#UNIT unit
function TARS:CheckTask(unit)
    if not unit or not unit:IsAlive() then return end
    local typeName = unit:GetTypeName()
    local params   = self.parameters[typeName]

    if unit:InAir(false) then
        local inst = self:GetInstance(unit:GetName())
        local msg  = (inst and inst.capturing)
            and self:_Txt("TARS_VALID_RUNNING")
            or  self:_Txt("TARS_VALID_AIRBORNE")
        self:_MsgUnit(msg, 5, unit:GetPlayerName() or unit:GetName())
        return
    end

    if self.recoNameFilter.enabled then
        local grp       = unit:GetGroup()
        local groupName = grp and grp:GetName() or ""
        if not string.find(string.lower(groupName), string.lower(self.recoNameFilter.keyword)) then
            self:_MsgUnit(
                self:_Txt("TARS_VALID_GROUP_FILTER", self.recoNameFilter.keyword),
                10, unit:GetPlayerName() or unit:GetName(),true)
            return
        end
    end

    local playerName             = unit:GetPlayerName() or unit:GetName()
    local reconOk, refusedWeapon = self:CheckIfRecon(unit)

    TARS.groundMenus[playerName]            = TARS.groundMenus[playerName] or {}
    TARS.groundMenus[playerName].approved   = reconOk
    TARS.groundMenus[playerName].playerName = playerName

    if reconOk then
        self:T("VALIDATE OK — " .. unit:GetName() .. " / " .. tostring(playerName))
        self:_MenuRemoveValidation(playerName)
        -- Build the platform info block using localized labels
        local msg = self:_Txt("TARS_VALID_OK_HDR")
        self:_MsgUnit(msg, 15, playerName)
        local msg = ""
            .. self:_Txt("TARS_PLATFORM_LABEL") .. " : " .. params.name .. "\n"
            .. self:_Txt("TARS_PLATFORM_ALT")   .. " : " .. params.minAlt .. "m - " .. params.maxAlt .. "m AGL\n"
            .. self:_Txt("TARS_PLATFORM_FOV")   .. " : " .. tostring(params.fov or "-") .. "\xc2\xb0\n"
            .. self:_Txt("TARS_PLATFORM_FILM")  .. " : " .. params.duration .. " expositions"
        self:_MsgUnit(msg, 15, playerName,true)
    else
        self:T("VALIDATE REFUSED — " .. unit:GetName() .. " ammo=" .. tostring(refusedWeapon))
        local msg = self:_Txt("TARS_VALID_REFUSED_WPN")
        if refusedWeapon then
            msg = msg .. "\n" .. self:_Txt("TARS_VALID_REFUSED_AMMO", refusedWeapon)
        end
        self:_MsgUnit(msg, 10, playerName,true)
    end
end

--- [INTERNAL] Arms the capture session.
-- @param #TARS self
-- @param #TARS_SESSION instance
function TARS:Control(instance)
    if not instance then return end
    if instance.sessionEnded then
        self:_MsgUnit(self:_Txt("TARS_SESSION_ENDED"), 5, instance.playerName)
        return
    end
    if instance.capturing then
        self:_MsgUnit(self:_Txt("TARS_FILM_ALREADY_ACTIVE"), 4, instance.playerName)
        return
    end
    instance:CaptureData()
end

--- [INTERNAL] Ends the capture session; marks it as awaiting debrief.
-- @param #TARS self
-- @param #TARS_SESSION instance
function TARS:StopCapture(instance)
    if not instance then return end
    if not instance.capturing then
        self:_MsgUnit(self:_Txt("TARS_FILM_NO_CAPTURE_STOP"), 4, instance.playerName)
        return
    end
    instance.capturing     = false
    instance.standby       = false
    instance.loop          = false
    instance.sessionEnded  = true
    instance.filmExhausted = (instance.duration <= 0)
    instance:I("FILM STOP — captures=" .. instance.captureCount
        .. " filmLeft=" .. instance.duration .. "s")
    self:_MsgUnit(
        instance.filmExhausted
            and self:_Txt("TARS_FILM_EXHAUSTED")
            or  self:_Txt("TARS_FILM_STOP"),
        8, instance.playerName)
end

--- [INTERNAL] Toggles film standby on/off.
-- @param #TARS self
-- @param #TARS_SESSION instance
function TARS:StandbyCapture(instance)
    if not instance then return end
    if not instance.capturing then
        self:_MsgUnit(self:_Txt("TARS_FILM_NO_CAPTURE"), 4, instance.playerName)
        return
    end
    if instance.standby and instance.wasCapturing then
        self:_MsgUnit(self:_Txt("TARS_FILM_STB_LOCKED"), 4, instance.playerName)
        return
    end
    instance.standby = not instance.standby
    instance:I("FILM " .. (instance.standby and "STB" or "RESUME"))
    self:_MsgUnit(
        instance.standby
            and self:_Txt("TARS_FILM_STB_MANUAL")
            or  self:_Txt("TARS_FILM_RESUME_MANUAL"),
        5, instance.playerName)
end

--- [INTERNAL] Sends platform capabilities as a HUD message.
-- All labels are resolved through the active locale.
-- @param #TARS self
-- @param #TARS_SESSION instance
function TARS:ShowPlatformInfo(instance)
    if not instance or not instance.unit or not instance.unit:IsAlive() then return end
    local params = TARS.parameters[instance.type]
    if not params then return end
    local msg = self:_Txt("TARS_PLATFORM_INFO") .. "\n"
        .. self:_Txt("TARS_PLATFORM_LABEL") .. " : " .. params.name .. "\n"
        .. self:_Txt("TARS_PLATFORM_ALT")   .. " : " .. params.minAlt .. "m - " .. params.maxAlt .. "m AGL\n"
        .. self:_Txt("TARS_PLATFORM_FOV")   .. " : " .. tostring(params.fov or "-") .. "\xc2\xb0\n"
        .. self:_Txt("TARS_PLATFORM_FILM")  .. " : " .. instance.duration .. " / " .. params.duration .. " expositions"
    self:_MsgUnit(msg, 15, instance.playerName, true)
end

--- [INTERNAL] Places a coalition F10 map marker for a detected target snapshot.
-- @param #TARS self
-- @param #TARS.Snapshot snap
-- @param #number coa Coalition side.
-- @return #number counter Mark ID used.
function TARS:OutMark(snap, coa)
    if not snap then return end
    local c        = COORDINATE:NewFromVec3(snap.point)
    local lat, lon = c:GetLLDDM()
    local hPa      = UTILS.Round(c:GetPressure(), 2)
    local inHg     = UTILS.Round(hPa * 0.02953, 2)
    local text     = string.format(
        "%.4f, %.4f | %.2f hPa / %.2f inHg\nTYPE: %s  STATUS: %s",
        lat, lon, hPa, inHg, snap.type, TARS.life2text(snap.life))

    local markTable = (coa == 1) and self.marks.red  or self.marks.blue
    local counter   = (coa == 1) and self.redMarkCount or self.blueMarkCount

    trigger.action.markToCoalition(counter, text, snap.point, coa, true)
    markTable[snap.name] = counter

    if coa == 1 then self.redMarkCount  = self.redMarkCount  + 1
    else             self.blueMarkCount = self.blueMarkCount + 1 end
    
    local out = true
    if self.OnBeforeDataProcessing then out = self:OnBeforeDataProcessing(snap) end
    if out == true and self.OnAfterDataProcessing then self:OnAfterDataProcessing(snap) end
    
    return counter
end

--- [INTERNAL] Debrief: publishes marks and awards points after a valid landing.
-- @param #TARS self
-- @param #TARS_SESSION instance
function TARS:ProcessLanding(instance)
    if not instance or not instance.unit or not instance.unit:IsAlive() then return end
    local unit = instance.unit
    if unit:InAir(false) or not instance.sessionEnded then return end

    instance.wasCapturing     = false
    instance.landingScheduled = false

    if not self:IsNearAlliedBase(unit) then
        self:_MsgUnit(self:_Txt("TARS_NOT_AT_BASE"), 10, instance.playerName)
        return
    end

    local count = instance:ReturnReconTargets()
    instance:I("DEBRIEF — targets=" .. count .. " player=" .. tostring(instance.playerName))

    if TARS.mooseScoring and count > 0 and TARS.scoring then
        local pts       = count * TARS.valueScoring
        local mooseUnit = UNIT:FindByName(instance.objectName)
        if mooseUnit and mooseUnit:IsAlive() then
            TARS.scoring:_AddPlayerFromUnit(mooseUnit)
            TARS.scoring:AddGoalScore(mooseUnit,
                string.format("RECCE_%s_T%d", instance.objectName, math.floor(timer.getTime())),
                string.format("[TARS] %d target(s) captured +%d pts", count, pts), pts)
            self:_MsgUnit(self:_Txt("TARS_DEBRIEF_TARGETS", count, pts), 8, instance.playerName, true)
        end
    else
        local pts = math.ceil(count / 4)
        self:_AddUserPoints(instance.playerName, pts)
        self:_MsgUnit(self:_Txt("TARS_DEBRIEF_CREDITS", pts), 8, instance.playerName)
    end

    self:_MsgCoalition(
        self:_Txt("TARS_DEBRIEF_COALITION", unit:GetPlayerName(), count),
        8, instance.coa)

    instance:I("SESSION RESET")
    instance:SetObjectParams(unit)
end

--- [INTERNAL] Removes F10 marks for units that no longer exist.
-- @param #TARS self
-- @param #boolean _
-- @param #number time
-- @return #number time + 120
function TARS:RemoveUnusedMarks(_, time)
    local function sweep(markTable)
        for unitName, markID in next, markTable do
            local u = UNIT:FindByName(unitName)
            if not u or not u:IsAlive() then
                trigger.action.removeMark(markID)
                markTable[unitName]            = nil
                self.detectedTargets[unitName] = nil
            end
        end
    end
    sweep(self.marks.blue)
    sweep(self.marks.red)
    return time + 120
end

--- [INTERNAL] Returns true if the unit is within landingDistance of any allied base/FARP.
-- @param #TARS self
-- @param Wrapper.Unit#UNIT unit
-- @return #boolean
function TARS:IsNearAlliedBase(unit)
    if self.debug then return true end
    local pos            = unit:GetCoordinate()
    local _, distance    = pos:GetClosestAirbase(nil, unit:GetCoalition())
    return distance < TARS.landingDistance
end

-------------------------------------------------
-- TODO DYNAMIC MENU HELPERS
--
-- State machine:
--   GROUND_NEW   [validate + info]
--        │ CheckTask() OK  → _MenuRemoveValidation
--        ▼
--   GROUND_APPROVED  [info only]
--        │ _OnEventTakeOff → _MenuAddFilmControls
--        ▼
--   AIRBORNE  [info + start + stb + stop]
--        │ _OnEventLand (sessionEnded) → _MenuRemoveFilmControls
--        ▼
--   LANDED_DEBRIEF  [info only]
--        │ SetObjectParams after debrief → _MenuAddValidation
--        ▼
--   GROUND_NEW (reset)  [validate + info]
-------------------------------------------------

--- [INTERNAL] Adds the "TARS validation" menu item using the active locale label.
-- @param #TARS self
-- @param #string playerName
function TARS:_MenuAddValidation(playerName)
    local d = TARS.groundMenus[playerName]
    if not d or not d.menuHandle or d.itemValidate then return end
    local grp      = d.group
    local label    = self:_Txt("TARS_MENU_VALIDATE")
    d.itemValidate = MENU_GROUP_COMMAND:New(grp, label, d.menuHandle,
        TARS._CbValidate, self, playerName)
    d.itemValidate.MenuTag = 1
    d.menuHandle:RefreshAndOrderByTag()
    self:T(self.lid .. "MENU +validate — " .. tostring(playerName))
end

--- [INTERNAL] Removes the "TARS validation" menu item.
-- @param #TARS self
-- @param #string playerName
function TARS:_MenuRemoveValidation(playerName)
    local d = TARS.groundMenus[playerName]
    if not d or not d.itemValidate then return end
    d.itemValidate:Remove()
    d.itemValidate = nil
    d.menuHandle:RefreshAndOrderByTag()
    self:T(self.lid .. "MENU -validate — " .. tostring(playerName))
end

--- [INTERNAL] Adds the three film-control items using the active locale labels.
-- @param #TARS self
-- @param #string playerName
function TARS:_MenuAddFilmControls(playerName)
    local d = TARS.groundMenus[playerName]
    if not d or not d.menuHandle or d.itemStart then return end
    local grp   = d.group
    d.itemStart = MENU_GROUP_COMMAND:New(grp, self:_Txt("TARS_MENU_START"),
        d.menuHandle, TARS._CbStart, self, playerName)
    d.itemStart.MenuTag = 2
    d.itemStb   = MENU_GROUP_COMMAND:New(grp, self:_Txt("TARS_MENU_STB"),
        d.menuHandle, TARS._CbStb, self, playerName)
    d.itemStb.MenuTag = 3
    d.itemStop  = MENU_GROUP_COMMAND:New(grp, self:_Txt("TARS_MENU_STOP"),
        d.menuHandle, TARS._CbStop, self, playerName)
    d.itemStop.MenuTag = 4
    d.menuHandle:RefreshAndOrderByTag()
    self:T(self.lid .. "MENU +film controls — " .. tostring(playerName))
end

--- [INTERNAL] Removes the three film-control items.
-- @param #TARS self
-- @param #string playerName
function TARS:_MenuRemoveFilmControls(playerName)
    local d = TARS.groundMenus[playerName]
    if not d then return end
    if d.itemStart then d.itemStart:Remove(); d.itemStart = nil end
    if d.itemStb   then d.itemStb:Remove();   d.itemStb   = nil end
    if d.itemStop  then d.itemStop:Remove();  d.itemStop  = nil end
    if d.menuHandle then d.menuHandle:RefreshAndOrderByTag() end
    self:T(self.lid .. "MENU -film controls — " .. tostring(playerName))
end

--- [INTERNAL] Creates the Task TARS F10 sub-menu and its initial items.
-- Initial state (GROUND_NEW): "TARS validation" + "TARS capture config".
-- @param #TARS self
-- @param Wrapper.Unit#UNIT unit
-- @param #string playerName
function TARS:AddBaseMenu(unit, playerName)
    self:T(self.lid .. "AddBaseMenu — " .. unit:GetName()
        .. " / " .. tostring(playerName))

    local typeName = unit:GetTypeName()
    if not TARS.reconTypes[typeName] then return end

    local grp = unit:GetGroup()
    if not grp then return end

    if TARS.recoNameFilter.enabled then
        local groupName = grp:GetName() or ""
        if not string.find(string.lower(groupName),
                string.lower(TARS.recoNameFilter.keyword)) then
            return
        end
    end

    local groupID  = grp:GetID()
    local unitName = unit:GetName()
    local existing = TARS.groundMenus[playerName]

    if existing and existing.menuHandle then
        if existing.groupID ~= groupID then
            self:T(self.lid .. "AddBaseMenu — group changed, rebuilding")
            existing.menuHandle:Remove()
            TARS.groundMenus[playerName] = nil
        else
            if existing.unitName ~= unitName then
                existing.unitName = unitName
                existing.approved = false
                self:_MenuAddValidation(playerName)
                self:_MenuRemoveFilmControls(playerName)
            end
            return
        end
    end

    local displayName = unit:GetPlayerName() or tostring(playerName)
    -- Menu root label uses locale
    local subMenu     = MENU_GROUP:New(grp, self:_Txt("TARS_MENU_ROOT") .. " - " .. displayName)
    subMenu.MenuTag = -1
    local itemInfo    = MENU_GROUP_COMMAND:New(grp, self:_Txt("TARS_MENU_INFO"),
        subMenu, TARS._CbInfo, self, playerName)
    itemInfo.MenuTag  = 0

    TARS.groundMenus[playerName] = {
        menuHandle   = subMenu,
        itemValidate = nil,
        itemInfo     = itemInfo,
        itemStart    = nil,
        itemStb      = nil,
        itemStop     = nil,
        approved     = false,
        unitName     = unitName,
        groupID      = groupID,
        playerName   = displayName,
        group        = grp,
    }

    self:_MenuAddValidation(playerName)

    self:T(self.lid .. "MENU created — " .. tostring(playerName)
        .. " group=" .. grp:GetName())
end

--- [INTERNAL] Removes the TARS F10 menu for a player.
-- @param #TARS self
-- @param #string playerName
function TARS:RemoveGroundMenu(playerName)
    local data = TARS.groundMenus[playerName]
    if not data or not data.menuHandle then return end
    data.menuHandle:Remove()
    self:T(self.lid .. "MENU removed — " .. tostring(playerName))
    TARS.groundMenus[playerName] = nil
end

-------------------------------------------------
-- TODO EVENT HANDLERS
-------------------------------------------------

--- [INTERNAL] Handles unit birth.
-- @param #TARS self
-- @param Core.Event#EVENTDATA EventData
function TARS:_OnEventBirth(EventData)
    self:T(self.lid .. "OnEventBirth")
    local unit = EventData.IniUnit
    if not unit then return end
    local instance = self:GetInstance(unit:GetName())
    if instance then instance:Delete() end
    local playerName = EventData.IniPlayerName --unit:GetPlayerName()
    if not playerName then return end
    local pName = playerName
    timer.scheduleFunction(function()
        if unit:IsAlive() then
            pcall(function() self:AddBaseMenu(unit, pName) end)
        end
    end, nil, timer.getTime() + 1)
end

--- [INTERNAL] Handles engine startup (fallback for pre-loaded slots).
-- @param #TARS self
-- @param Core.Event#EVENTDATA EventData
function TARS:_OnEventEngineStartup(EventData)
    if EventData.IniPlayerName == nil then return end
    local unit = EventData.IniUnit
    if not unit or not unit:GetPlayerName() then return end
    local pName = unit:GetPlayerName()
    timer.scheduleFunction(function()
        if unit:IsAlive() then
            pcall(function() self:AddBaseMenu(unit, pName) end)
        end
    end, nil, timer.getTime() + 1)
end

--- [INTERNAL] Handles unit death.
-- @param #TARS self
-- @param Core.Event#EVENTDATA EventData
function TARS:_OnEventDead(EventData)
    local unit = EventData.IniUnit
    if not unit then return end
    local name       = unit:GetName()
    local playerName = EventData.IniPlayerName --unit:GetPlayerName() or unit:GetName()
    if TARS.groundMenus[playerName] then self:RemoveGroundMenu(playerName) end
    if self.detectedTargets[name] then
        local markID = self.marks.blue[name] or self.marks.red[name]
        if markID then trigger.action.removeMark(markID) end
        self.marks.blue[name]       = nil
        self.marks.red[name]        = nil
        self.detectedTargets[name]  = nil
    end
end

--- [INTERNAL] Handles player leaving a slot.
-- @param #TARS self
-- @param Core.Event#EVENTDATA EventData
function TARS:_OnEventPlayerLeaveUnit(EventData)
    local unit = EventData.IniUnit
    if not unit then return end
    local playerName = EventData.IniPlayerName --unit:GetPlayerName() or unit:GetName()
    if TARS.groundMenus[playerName] then self:RemoveGroundMenu(playerName) end
end

--- [INTERNAL] Handles takeoff events (TakeOff + RunwayTakeOff share this handler).
-- Branch 1: capture active → validate config, auto-resume film.
-- Branch 2: film inactive → check approval, create session, add film menus.
-- @param #TARS self
-- @param Core.Event#EVENTDATA EventData
function TARS:_OnEventTakeOff(EventData)
    self:T(self.lid.."_OnEventTakeOff")
    if EventData.IniPlayerName == nil then return end
    local unit     = EventData.IniUnit
    if not unit then return end
    local instance = self:GetInstance(unit:GetName())
    local now      = timer.getTime()
    
    -- Branch 1: auto-resume after ground STB
    if instance and instance.capturing then
        if instance.lastTakeoffTime and (now - instance.lastTakeoffTime) < 5 then return end
        if not instance.wasCapturing then return end
        instance.lastTakeoffTime = now

        local reconOk, refused = self:CheckIfRecon(unit)
        if not reconOk then
            self:StopCapture(instance)
            instance.wasCapturing = false
            local msg = self:_Txt("TARS_CONFIG_CHANGED")
            if refused then
                msg = msg .. "\n" .. self:_Txt("TARS_VALID_REFUSED_AMMO", refused)
            end
            self:_MsgUnit(msg, 10, instance.playerName)
            return
        end
        instance:SetObjectParamsLight(unit)
        instance.wasCapturing = false
        instance.standby      = false
        instance:I("FILM AUTO-RESUME — filmLeft=" .. instance.duration .. "s")
        local inst = instance
        timer.scheduleFunction(function()
            if inst.unit:IsAlive() then
                self:_MsgUnit(
                    self:_Txt("TARS_FILM_RESUME_TO", inst.duration), 5, inst.playerName)
            end
        end, nil, now + 2)
        return
    end

    -- Branch 2: normal takeoff
    if instance and instance.lastTakeoffTime and (now - instance.lastTakeoffTime) < 5 then
        return
    end
    local playerName = EventData.IniPlayerName --unit:GetPlayerName() or unit:GetName()
    if playerName == nil then return end
    local groundData = TARS.groundMenus[playerName]
    if not (groundData and groundData.approved) then return end

    local reconOk, refused = self:CheckIfRecon(unit)
    if not reconOk then
        local msg = self:_Txt("TARS_LOADOUT_BAD")
        if refused then
            msg = msg .. "\n" .. self:_Txt("TARS_VALID_REFUSED_AMMO", refused)
        end
        if TARS.groundMenus[playerName] then
            TARS.groundMenus[playerName].approved = false
        end
        self:_MsgUnit(msg, 10, playerName)
        return
    end

    if not instance then
        instance = self:CreateInstance(unit)
    else
        instance:SetObjectParams(unit)
    end
    instance.lastTakeoffTime = now

    -- AIRBORNE: add film control items
    self:_MenuAddFilmControls(playerName)

    local inst = instance
    timer.scheduleFunction(function()
        if inst.unit:IsAlive() then
            self:_MsgUnit(self:_Txt("TARS_READY"), 8, inst.playerName)
        end
    end, nil, now + 5)
end

--- [INTERNAL] Handles landing events (Land + RunwayTouch share this handler).
-- Branch 1: capture active → auto standby.
-- Branch 2: session ended → schedule debrief, remove film menus.
-- @param #TARS self
-- @param Core.Event#EVENTDATA EventData
function TARS:_OnEventLand(EventData)
    self:T(self.lid.."_OnEventLand")
    local unit     = EventData.IniUnit
    if not unit then return end
    local instance = self:GetInstance(unit:GetName())

    -- Branch 1: auto standby
    if instance and instance.capturing then
        if instance.wasCapturing then return end
        instance.standby      = true
        instance.wasCapturing = true
        instance:I("FILM AUTO-STB — landing")
        self:_MsgUnit(self:_Txt("TARS_FILM_STB_LAND"), 5, instance.playerName)
        return
    end

    -- Branch 2: session ended → schedule debrief
    if not (instance and instance.sessionEnded) then return end
    if instance.landingScheduled                then return end
    if not TARS.reconTypes[unit:GetTypeName()]  then return end

    if not self:IsNearAlliedBase(unit) then
        self:_MsgUnit(self:_Txt("TARS_NOT_AT_BASE"), 10, instance.playerName)
        return
    end

    instance.landingScheduled = true
    local landTime = timer.getTime()
    local inst     = instance
  local msgTime = TARS.debriefDelay*0.98

    -- LANDED_DEBRIEF: remove film controls
    self:_MenuRemoveFilmControls(instance.playerName)

    timer.scheduleFunction(function()
        if inst.unit:IsAlive() and not inst.unit:InAir(false) then
            self:_MsgUnit(self:_Txt("TARS_LAND_VALIDATED"),10,instance.playerName)
            self:_MsgUnit(
                self:_Txt("TARS_LAND_VALIDATED_TIME", TARS.debriefDelay),
                msgTime, inst.playerName)
            inst:I("Landing validated — debrief in " .. TARS.debriefDelay .. "s")
        end
    end, nil, landTime + TARS.landingDelay)

    timer.scheduleFunction(function()
        self:ProcessLanding(inst)
    end, nil, landTime + TARS.landingDelay + TARS.debriefDelay)
end

-------------------------------------------------
-- TODO CONSTRUCTOR
-------------------------------------------------

--- Creates the TARS singleton and wires up all event handlers.
-- @param #TARS self
-- @param #string locale (optional) Set locale for text output, defaults to "en". "fr" and "de" available out-of-the-box.
-- @return #TARS self
function TARS:New(locale)
    local self = BASE:Inherit(self, BASE:New())
    self.lid = "TARS " .. TARS.version .. " | "

    if TARS.mooseScoring then
        TARS.scoring = SCORING:New("TARS Scoring")
    end

    self:HandleEvent(EVENTS.Birth,           self._OnEventBirth)
    self:HandleEvent(EVENTS.EngineStartup,   self._OnEventEngineStartup)
    self:HandleEvent(EVENTS.Dead,            self._OnEventDead)
    self:HandleEvent(EVENTS.PlayerLeaveUnit, self._OnEventPlayerLeaveUnit)
    self:HandleEvent(EVENTS.Takeoff,         self._OnEventTakeOff)
    self:HandleEvent(EVENTS.RunwayTakeoff,   self._OnEventTakeOff)
    self:HandleEvent(EVENTS.Land,            self._OnEventLand)
    self:HandleEvent(EVENTS.RunwayTouch,     self._OnEventLand)

    timer.scheduleFunction(
        function(_, t) return self:RemoveUnusedMarks(nil, t) end,
        nil, timer.getTime() + 20)
        
    self.locale = locale or self.locale
    self:I(self.lid .. "initialised. Locale: " .. tostring(self.locale))
    return self
end

--- Configure SRS radio output.
-- @param #TARS self
-- @param #string  Path       (Optional) Path to SRS (or nil to use MSRS default)
-- @param #number  Frequency  MHz, e.g. 251
-- @param #number  Modulation radio.modulation.AM or FM (default AM)
-- @param #string  Culture    (Optional) BCP-47 culture string, e.g. "ru-RU"
-- @param #string  Gender     (Optional) "male" or "female". Usually not used when using a specific voice.
-- @param #string  Voice      MSRS voice constant; do not forget to adjust voice to your locale!
-- @param #number  Coalition  MSRS Coalition, e.g. coalition.side.BLUE.
-- @param #number  Port       (Optional) SRS port (default 5002)
-- @param #number  Speed      (Optional) Speech speed (or nil to use MSRS default)
-- @param #string  Provider   (Optional) Provider, e.g. MSRS.Provider.GOOGLE (or nil to use MSRS default)
-- @param #string  Backend    (Optional) Backend, e.g. MSRS.Backend.HOUND (or nil to use MSRS default)
-- @param #number  Speaker    (Optional, HOUND/PIPER only!) Speaker number, e.g. 11 for Speaker "318 (11)"
-- @return #TARS self
function TARS:SetSRS(Path,Frequency,Modulation,Culture,Gender,Voice,Coalition,Port,Speed,Provider,Backend,Speaker)
  self:T(self.lid.."SetSRS")
  MESSAGE.SetMSRS(Path,Port,nil,Frequency,Modulation,Gender,Culture,Voice,Coalition,nil,"TARS",nil,Backend,Provider,Speaker)
  if Speed then
    _MESSAGESRS.MSRS.speed = Speed
  end
  self.SRS = true
  return self
end


--- Set SRS Voice Speaker for Hound/Piper
--@param #TARS self
--@param #number Speaker Speaker number, e.g. 11 for Speaker "318 (11)"
--@return #TARS self
function TARS:SetSRSPiperSpeaker(Speaker)
  self:T(self.lid.."SetSRSPiperSpeaker "..tostring(Speaker))
  self.SRSSpeaker = Speaker
  return self
end

--- Moose FSM Style callback function for mission designers. Optionally overwrite with own function. Processed after landing on debriefing analysis. Use for pre-processing.
-- @param #TARS self
-- @param #TARS.Snapshot TargetSnap Table of data of a **single** found object in the last session.
-- @return #boolean returnvalue If false, then `TARS:OnAfterDataProcessing` will NOT be called.
function TARS:OnBeforeDataProcessing(TargetSnap)
  return true
end

--- Moose FSM Style callback function for mission designers. Optionally overwrite with own function. Processed after landing on debriefing analysis.
-- @param #TARS self
-- @param #TARS.Snapshot TargetSnap Table of data of a **single** found object in the last session.
-- @return #TARS self
function TARS:OnAfterDataProcessing(TargetSnap)
  return self
end
