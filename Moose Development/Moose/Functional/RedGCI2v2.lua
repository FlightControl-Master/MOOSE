--- **Functional** - Enhanced Warsaw Pact GCI 2v2 Controller.
--
-- ## Main Features:
--
--    * Guide AI and human pilots in Warsaw Pact Style in 2v2 tactics.
--    * Advanced Tactics for Groups.
--    * Many additional events that the mission designer can hook into.
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [GitHub](https://github.com/FlightControl-Master/MOOSE_MISSIONS/).
--
-- ===
--
-- ### Author: **Applevangelist**
--
-- ===
-- @module Functional.RedGCI2v2
-- @image Func_RedGCI.png

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- REDGCI2v2 class
-- @type REDGCI2v2
-- @field #string ClassName
-- @field #string version
-- @extends Core.Fsm#FSM

---
-- # RedGCI — Soviet GCI Doctrine & Player Guide
--
-- ## Philosophy: Централизованное управление (Centralized Control)
-- 
-- The fundamental difference between Soviet and NATO GCI is **who makes the tactical decision**.
-- 
-- In NATO doctrine, the GCI controller provides situational awareness — bearing, range, altitude, aspect — and the pilot decides how to prosecute the intercept. The pilot is an autonomous tactician. GCI is an advisor.
-- 
-- In Soviet doctrine, the GCI controller **directs**. The pilot executes. The controller selects the intercept geometry, assigns the heading, manages the radar, calls weapons free, and coordinates multi-ship tactics. The pilot's job is to fly the numbers and shoot when told. This is not a flaw — it is the system working as designed. Soviet fighter pilots were trained to be precise executors of GCI instructions, not independent tacticians. The ground radar network (PVO) was the brain; the aircraft was the weapon.
-- 
-- RedGCI models this philosophy faithfully.
-- 
-- ---
-- 
-- ## What to Expect as a Player
-- 
-- ### You will not be asked what you want to do.
-- 
-- There are no "recommend a vector" calls, no "at your discretion" callouts. The controller tells you your heading, your altitude, and your task. Your acknowledgement is assumed.
-- 
-- ### The controller manages your radar.
-- 
-- You do not decide when to turn your radar on. The GCI will tell you when to switch on (`локатор` / `Radar on`). Before that call, you fly cold and silent. This preserves your emissions discipline and prevents the target from getting an early RWR spike.
-- 
-- ### Weapons free is a controlled event.
-- 
-- You do not engage until the controller clears you (`цель разрешена` / `WEAPONS FREE`). The controller determines when geometry, range, and aspect are favorable. Shooting early breaks the coordinated intercept and may compromise your wingman's attack.
-- 
-- ### Radio calls are short and military.
-- 
-- Soviet GCI brevity is terse by design. Expect calls like:
-- 
-- - `"Сокол, курс 170, высота 4500."` — vector, altitude
-- - `"Сокол, цель, пара, истребитель. Локатор."` — picture call on commit: count, type, radar on
-- - `"Сокол, захват. Дальность 20. Цель разрешена."` — lock confirmed, range, weapons free
-- - `"Сокол, молодец. Домой."` — good kill, RTB
-- 
-- There are no "BOGEY DOPE" requests, no "BRAA" calls, no "DECLARE" queries. The controller has already done that work. You fly the vector.
-- 
-- ---
-- 
-- ## State Flow — What the GCI is Doing Behind the Scenes
-- 
-- RedGCI manages a state machine that progresses through six phases. Understanding these phases helps you anticipate what call is coming next.
-- 
-- ```
-- VECTOR → COMMIT → RADAR_CONTACT → VISUAL → MERGE → (SPLASH / ABORT / RTB)
-- ```
-- 
-- ### VECTOR
-- The controller has a track. You are being vectored onto an intercept geometry. Your radar is off. The controller is solving a collision course and updating your heading every tick. Altitude calls reflect the intercept geometry — you may be sent below the target (classic Soviet shoot-up doctrine for radar-limited types) or level/above (MiG-29/Su-27 lookdown geometry). Expect heading updates every 10–15 seconds.
-- 
-- **What you should do:** Fly the heading. Don't deviate. Don't turn your radar on yet. Speed is expected at 900kph TAS (depending on airframe)
-- 
-- ### COMMIT
-- Range has closed to approximately 30km. The controller calls the picture: count and type. Your radar comes on. You are now committed to the intercept — turning away is no longer the default option. The controller is building your radar geometry toward a lock.
-- 
-- **What you should do:** Activate your radar. Acquire the target. Do not fire yet.
-- 
-- ### RADAR_CONTACT
-- You have radar lock (or the AI has achieved it). The controller confirms lock and calls range. If geometry and range are favorable, weapons free follows immediately. If not — for example if aspect angle is unfavorable for a stern conversion — the controller holds fire and waits for better geometry.
-- 
-- **What you should do:** Maintain lock. Track the target. Wait for the weapons free call.
-- 
-- ### VISUAL
-- Range has closed to approximately 5km — visual conditions. Weapons free is automatic at this point. You are now in the merge envelope.
-- 
-- **What you should do:** Engage.
-- 
-- ### MERGE
-- Inside 2km. The GCI transitions to merge control: bearing to target, overshoot calls, separation instructions, reattack vectors. At this range the controller cannot see fine-grained geometry — merge calls are based on relative bearing and closure.
-- 
-- **What you should do:** Fight. Listen for overshoot, separation, and reattack calls.
-- 
-- ### SPLASH / ABORT / RTB
-- - `SPLASH` — kill confirmed, RTB
-- - `ABORT (THREAT)` — your RWR is spiked or a threat geometry has developed; break off immediately on the given heading
-- - `ABORT (BINGO)` — fuel state critical; break off and return
-- 
-- ---
-- 
-- ## Multi-Ship (2v2) Tactics (REDGCI2v2)
-- 
-- When two fighters are dispatched against a threat, the GCI selects a tactic automatically based on the tactical situation. The tactic is applied at COMMIT — until then, both fighters are vectored together toward the intercept midpoint.
-- 
--           | Tactic       | Description                                                                                                                                                    |   
--           |--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|   
--           | **PINCER**   | Classic bracket. F1 and F2 split left and right, attacking from opposite angles simultaneously. Forces the target to choose which threat to react to.          |   
--           | **HIGH-LOW** | Vertical split. One fighter attacks from below (radar up, clean sky background), one from above. Degrades the target's ability to acquire both simultaneously. |  
--           | **STAGGER**  | BVR timing offset. F1 fires first at long range, F2 follows 8–13km behind to engage a maneuvering or defending target.                                         |  
--           | **TRAIL**    | Close trail. F1 is the shooter, F2 is support — ready to engage if F1 overshoots or is defeated.                                                               |   
--           | **GIRAFFE**  | *(Historical — Iraq/Iran War, Mirage F1 vs F-14A)* F1 attacks at normal altitude, binding the AWG-9 radar. F2 flies nap-of-earth                               |    
--           |              |                         (300–600m AGL) using ground clutter to degrade radar detection, then pulls up and fires from close range.                              | 
-- 
-- During a tactic split, you may receive a heading that seems unusual — a large lateral offset or an unexpected altitude change. **Trust the vector.** The controller is positioning you for the tactic geometry. The merge point will bring you back onto the target.
-- 
-- ---
-- 
-- ## Dispatcher & CAP Flow (REDGCI_DISPATCHER)
-- 
-- When using the dispatcher layer, the full operational flow is:
-- 
-- ```
-- Spawn at homeplate
--     → Taxi and takeoff (template-controlled)   
--     → Transit to CAP zone   
--     → Orbit in assigned zone (radar cold, weapons safe)   
--         ↓ INTEL detects threat cluster   
--     → "Attention, radar contact. Pair, fighter, 45 kilometers." (all CAP fighters)   
--         ↓ Dispatcher assigns pair   
--     → "101 102, intercept. Pair, fighter." (dispatched pair)   
--     → VECTOR → COMMIT → RADAR_CONTACT → VISUAL → MERGE → SPLASH   
--         ↓ Engagement complete   
--     → AI: RTB waypoint → land → despawn → respawn after delay   
--     → Human: "101, mission complete. RTB, refuel and rearm."   
--         ↓ After RespawnDelay   
--     → New AI pair spawns into same CAP zone   
-- ```
-- 
-- Human players are dispatched first when available. If a human and AI are both in the CAP pool, the human is always assigned to the next intercept. AI fills gaps. The dispatcher does not send a single fighter if a pair is available — pairing is always preferred.
-- 
-- ---
-- 
-- ## Key Differences from NATO GCI at a Glance
-- 
--           |                    | Soviet (RedGCI)                      |  NATO                              |   
--           |--------------------|--------------------------------------|------------------------------------|   
--           | Tactical decision  | Controller                           | Pilot                              |   
--           | Radar management   | Controller-commanded                 | Pilot-initiated                    |  
--           | Weapons free       | Controller-called                    | Pilot-discretion (after WF)        |   
--           | Heading calls      | Prescriptive                         | Advisory                           |   
--           | Brevity style      | Terse, military, positional          | Standardized (BRAA, DECLARE, etc.) |   
--           | Multi-ship tactics | Centrally planned, applied at COMMIT | Mutually briefed, pilot-executed   |   
--           | Pilot autonomy     | Low (by design)                      | High                               |   
-- 
-- **The Soviet system is not inferior** — it is optimized for a different kind of pilot and a different operational context. Mass interception of large NATO strike packages over defended Soviet airspace demanded centralized, efficient, high-throughput GCI control. RedGCI brings that experience to DCS.
-- 
-- @field #REDGCI2v2
REDGCI2v2 = {}
REDGCI2v2.ClassName = "REDGCI2v2"
REDGCI2v2.version   = "1.0.0"

-- ─────────────────────────────────────────────────────────────
--  Tactic weights (sum must equal 100)
-- ─────────────────────────────────────────────────────────────

--- @type REDGCI2v2.TacticWeights
-- @field #string PINCER
-- @field #string HIGH_LOW
-- @field #string STAGGER
-- @field #string TRAIL
REDGCI2v2.TacticWeights = {
    ["PINCER"]  = 35,   -- split left/right, classic bracket
    ["HIGH_LOW"] = 25,  -- one high, one low
    ["STAGGER"]  = 20,  -- trail with BVR timing offset
    ["TRAIL"]    = 10,  -- tight trail, one shooter one support
    ["GIRAFFE"]  = 10,  -- Irak/Iran-Doktrin: F1 Decoy hoch, F2 NOE im Groundclutter
}

--- Tactic commit range — split geometry applied at this range
-- @field #number COMMIT_RANGE
REDGCI2v2.COMMIT_RANGE  = 30000   -- metres (mirrors GCI_RANGE_COMMIT)

--- Split lateral offset for PINCER (metres, randomised ±variation)
-- @field #number PINCER_OFFSET
REDGCI2v2.PINCER_OFFSET = 10000   -- 10 km

--- Altitude offsets for HIGH_LOW (metres relative to target)
-- @field #number HIGH_ALT_OFFSET
-- @field #number LOW_ALT_OFFSET
REDGCI2v2.HIGH_ALT_OFFSET =  3500
REDGCI2v2.LOW_ALT_OFFSET  =  -200

--- Trail/Stagger separation distances (metres)
-- @field #number TRAIL_SEP
-- @field #number STAGGER_SEP
REDGCI2v2.TRAIL_SEP   = 4000
REDGCI2v2.STAGGER_SEP = 13000

--- Formation lateral offset during VECTOR phase (metres)
-- @field #number FORMATION_OFFSET
REDGCI2v2.FORMATION_OFFSET = 2000

--- Split range for tactics VECTOR phase (metres)
-- @field #number SPLIT_RANGE
REDGCI2v2.SPLIT_RANGE = 60000  -- 60km pre-COMMIT split

--- How many ticks the tactic override point is held before reverting
-- to normal intercept guidance (default 7 ticks = 70s at 10s interval)
-- @field #number OVERRIDE_TICKS
REDGCI2v2.OVERRIDE_TICKS = 7

-- ─────────────────────────────────────────────────────────────
--  Constructor
-- ─────────────────────────────────────────────────────────────

--- Create a new REDGCI2v2 two-ship flight.
-- @param #REDGCI2v2 self
-- @param #string Fighter1Group  DCS group name — lead aircraft
-- @param #string Fighter2Group  DCS group name — wingman
-- @param #string Target1Group   DCS group name — primary target
-- @param #string Target2Group   DCS group name — secondary target (or nil for 2v1)
-- @param #string FlightCallsign Radio callsign prefix (e.g. "Сокол-1")
-- @param #number Coalition      coalition.side.RED or BLUE
-- @return #REDGCI2v2 self
function REDGCI2v2:New(Fighter1Group, Fighter2Group,
                        Target1Group,  Target2Group,
                        FlightCallsign, Coalition)
    local self = BASE:Inherit(self, FSM:New())  --#REDGCI2v2

    self.lid = string.format("REDGCI2v2 (%s) | ", FlightCallsign or "GCI2v2")

    -- ── Identity ──────────────────────────────────────────────
    self.Fighter1Group  = Fighter1Group  or "Fighter-1"
    self.Fighter2Group  = Fighter2Group  or "Fighter-2"
    self.Target1Group   = Target1Group   or "Target-1"
    self.Target2Group   = Target2Group   -- nil = 2v1 mode
    self.FlightCallsign = FlightCallsign or "Сокол-1"
    self.Coalition      = Coalition      or coalition.side.RED

    -- Callsigns for each aircraft (appended -1 / -2)
    
    local Unit1 = GROUP:FindByName(self.Fighter1Group):GetUnit(1)
    local Unit2 = GROUP:FindByName(self.Fighter2Group):GetUnit(1)
    
    local Callsign1 = (Unit1 and Unit1:IsAlive()) and Unit1:GetCallsign() or FlightCallsign .. "-1"
    local Callsign2 = (Unit2 and Unit2:IsAlive()) and Unit2:GetCallsign() or FlightCallsign .. "-2"
    
    self.Callsign1 = Callsign1
    self.Callsign2 = Callsign2

    -- ── Shared configuration defaults (mirrored to sub-instances) ──
    self.Locale           = "ru"
    self.TickInterval     = 10.0
    self.TxRepeatInterval = 30.0
    self.IsAIPlane        = true
    self.HomeBaseName     = nil
    self.AltOffset        = -700
    self.Debug            = false
    self._missilerangeflag = 2

    self.SRSPath    = nil
    self.SRSFreq    = 251
    self.SRSMod     = radio.modulation.AM
    self.SRSCulture = "ru-RU"
    self.SRSVoice   = MSRS.Voices.Google.Standard.ru_RU_Standard_D
    self.SRSPort    = 5002
    self.FreqOffset = 0.5

    -- ── Tactic state ──────────────────────────────────────────
    self._tactic          = nil    -- chosen at COMMIT
    self._variation       = 0.0   -- 0.0–1.0 random variation seed
    self._tactic_applied  = false  -- split WPs already pushed?
    self._assignment      = nil    -- { [1]=targetGroupName, [2]=targetGroupName }

    -- ── Sub-instances (created in onafterStart) ───────────────
    self._gci1 = nil  --#REDGCI
    self._gci2 = nil  --#REDGCI

    -- ── FSM ───────────────────────────────────────────────────
    self:SetStartState("Stopped")
    self:AddTransition("Stopped", "Start",  "Running")
    self:AddTransition("Running", "Status", "Running")
    self:AddTransition("Running", "Stop",   "Stopped")

    self:I(self.lid .. "v" .. REDGCI2v2.version .. " created.")
    return self
end

-- ─────────────────────────────────────────────────────────────
--  User API (mirrors REDGCI for convenience)
-- ─────────────────────────────────────────────────────────────

--- Set Locale
--@param #REDGCI2v2 self
--@param #string Locale Locale to be set. Known ones are "ru", "en" and "de".
function REDGCI2v2:SetLocale(Locale)
    self.Locale = Locale or "ru"
    return self
end

--- Set AI Mode
--@param #REDGCI2v2 self
--@param #boolean IsAI True for AI.
--@param #string HomeBaseName Name of the home plate.
function REDGCI2v2:SetAIMode(IsAI, HomeBaseName)
    self.IsAIPlane    = IsAI ~= false
    self.HomeBaseName = HomeBaseName
    return self
end

--- Set SRS
--@param #REDGCI2v2 self
--@param #string Path
--@param #number Frequency
--@param #number Modulation
--@param #string Culture
--@param #string Voice
--@param #string Port
--@param #string Speed
function REDGCI2v2:SetSRS(Path, Frequency, Modulation, Culture, Voice, Port, Speed)
    self.SRSPath    = Path
    self.SRSFreq    = Frequency  or self.SRSFreq
    self.SRSMod     = Modulation or self.SRSMod
    self.SRSCulture = Culture    or self.SRSCulture
    self.SRSVoice   = Voice      or self.SRSVoice
    self.SRSPort    = Port       or self.SRSPort
    self.SRSSpeed   = Speed      or 1
    self:I({F=self.SRSFreq,V=self.SRSVoice})
    return self
end

--- Set SRS Provider
--@param #REDGCI2v2 self
--@param #string Provider
function REDGCI2v2:SetSRSProvider(Provider)
    self.SRSProvider = Provider or MSRS.Provider.GOOGLE
    return self
end

--- Set SRS Voice Speaker for Hound/Piper
--@param #REDGCI2v2 self
--@param #number Speaker Speaker number, e.g. 11 for Speaker "318 (11)"
function REDGCI2v2:SetSRSPiperSpeaker(Speaker)
    self.SRSSpeaker = Speaker or 0
    return self
end

--- Configure the pilot one voice for radio acknowledgements.
-- The pilot uses the same frequency/modulation as the GCI controller but
-- a distinct voice so the two can be told apart on the radio.
-- Set PilotCallsign to nil (default) to disable pilot ACKs entirely.
-- @param #REDGCI2v2 self
-- @param #string  PilotCallsign  Pilot's callsign (e.g. "Сокол-1"), or nil to disable ACKs.
-- @param #string  Culture        BCP-47 culture string (default same as GCI)
-- @param #string  Voice          MSRS voice constant (default ru_RU_Standard_B)
-- @param #number  Speaker        (Optional) MSRS Speaker for Hound/Piper Voices, e.g. 11 for "318 (11)"
-- @return #REDGCI2v2 self
function REDGCI2v2:SetPilotOneSRS(PilotCallsign, Culture, Voice, Speaker)
    self.PilotOneCallsign   = PilotCallsign
    self.PilotOneSRSCulture = Culture or self.SRSCulture
    self.PilotOneSRSVoice   = Voice   or MSRS.Voices.Google.Standard.ru_RU_Standard_B
    self.PilotOneSRSSpeaker = Speaker
    return self
end

--- Configure the pilot two voice for radio acknowledgements.
-- The pilot uses the same frequency/modulation as the GCI controller but
-- a distinct voice so the two can be told apart on the radio.
-- Set PilotCallsign to nil (default) to disable pilot ACKs entirely.
-- @param #REDGCI2v2 self
-- @param #string  PilotCallsign  Pilot's callsign (e.g. "Сокол-1"), or nil to disable ACKs.
-- @param #string  Culture        BCP-47 culture string (default same as GCI)
-- @param #string  Voice          MSRS voice constant (default ru_RU_Standard_B)
-- @param #number  Speaker        (Optional) MSRS Speaker for Hound/Piper Voices, e.g. 11 for "318 (11)"
-- @return #REDGCI2v2 self
function REDGCI2v2:SetPilotTwoSRS(PilotCallsign, Culture, Voice, Speaker)
    self.PilotTwoCallsign   = PilotCallsign
    self.PilotTwoSRSCulture = Culture or self.SRSCulture
    self.PilotTwoSRSVoice   = Voice   or MSRS.Voices.Google.Standard.ru_RU_Standard_B
    self.PilotTwoSRSSpeaker = Speaker
    return self
end

--- Set Tick Interval
--@param #REDGCI2v2 self
--@param #number Seconds Default 10.0
function REDGCI2v2:SetTickInterval(Seconds)
    self.TickInterval = Seconds or 10.0
    return self
end

--- Set the AI weapons-free range threshold in metres.
-- Weapons free is declared when the C kernel wf flag is true OR (AI mode AND
-- state is RADAR_CONTACT AND range <= WFRange). Set to 0 to disable the
-- Lua-side override and rely solely on the C kernel.
-- @param #REDGCI2v2 self
-- @param #number Meters  Default 20000
-- @return #REDGCI2v2 self
function REDGCI2v2:SetWFRange(Meters)
    self.WFRange = Meters or 20000
    return self
end

--- Set minimum seconds between identical transmissions.
-- @param #REDGCI2v2 self
-- @param #number Seconds  Default 30.0
-- @return #REDGCI2v2 self
function REDGCI2v2:SetTxRepeatInterval(Seconds)
    self.TxRepeatInterval = Seconds or 30.0
    return self
end

--- Set Debug
--@param #REDGCI2v2 self
--@param #boolean 
function REDGCI2v2:SetDebug(OnOff)
    self.Debug = OnOff ~= false
    return self
end

--- Set AltOffset in meters. Negative for shoot-up, positive for shoot-down
--@param #REDGCI2v2 self
--@param #number Meters
function REDGCI2v2:SetAltOffset(Meters)
    self.AltOffset = Meters or -700
    return self
end

--- Override tactic selection weights.
-- @param #REDGCI2v2 self
-- @param #table Weights  { PINCER=N, HIGH_LOW=N, STAGGER=N, TRAIL=N } (sum = 100)
-- @return #REDGCI2v2 self
function REDGCI2v2:SetTacticWeights(Weights)
    self.TacticWeights = Weights
    return self
end

--- Set range on which AI will prefer to fire missiles.
-- MAX_RANGE = 0, NEZ_RANGE = 1, HALF_WAY_RMAX_NEZ = 2, TARGET_THREAT_EST = 3, RANDOM_RANGE = 4. Defaults to 2.
-- @param #REDGCI2v2 self
-- @param #number Flag The behavior to set. 
-- @return #REDGCI2v2 self
function REDGCI2v2:SetMissileFiringFlag(Flag)
  self._missilerangeflag = Flag or 2
  return self
end

-- ─────────────────────────────────────────────────────────────
--  Internal helpers
-- ─────────────────────────────────────────────────────────────

--- [Internal]
--@param #REDGCI2v2 self
--@param #string msg
function REDGCI2v2:_Log(msg)
    if self.Debug then
        env.info(self.lid .. msg)
    end
end

--- [Internal] Build a configured REDGCI sub-instance.
-- @param #REDGCI2v2 self
-- @param #string FighterGroup
-- @param #string TargetGroup
-- @param #string Callsign
-- @param #number FreqOffSet (Optional) Frequency offset for multiple groups.
-- @return #REDGCI instance (not started)
function REDGCI2v2:_MakeGCI(FighterGroup, TargetGroup, Callsign, FreqOffSet)
    local grp = GROUP:FindByName(FighterGroup)
    local IsAiPlane = true
    if grp and grp:GetPlayerName() ~= nil then IsAiPlane = false end
    FreqOffSet = FreqOffSet or 0
    local Frequency = self.SRSFreq + FreqOffSet
    local gci = REDGCI:New(FighterGroup, TargetGroup, Callsign, self.Coalition)
    gci:SetLocale(self.Locale)
    gci:SetAIMode(IsAiPlane, self.HomeBaseName)
    gci:SetSRS(self.SRSPath, Frequency, self.SRSMod, self.SRSCulture, self.SRSVoice, self.SRSPort, self.SRSSpeed)
    if self.SRSSpeaker then
      gci:SetSRSPiperSpeaker(self.SRSSpeaker)
    end
    if self.SRSProvider then
      gci:SetSRSProvider(self.SRSProvider)
    end
    if self.WFRange then
      gci:SetWFRange(self.WFRange)
    end
    gci:SetTickInterval(self.TickInterval)
    gci:SetTxRepeatInterval(self.TxRepeatInterval) 
    gci:SetAltOffset(self.AltOffset)
    gci:SetDebug(self.Debug)
    gci:SetMissileFiringFlag(self._missilerangeflag)
    return gci
end

--- [Internal] Range between two unit-data tables (horizontal).
-- @param #REDGCI2v2 self
-- @param #table A
-- @param #table B
-- @return #number metres
function REDGCI2v2:_Range(A, B)
    local dx = B.x - A.x
    local dz = B.z - A.z
    return math.sqrt(dx*dx + dz*dz)
end

--- [Internal] Weighted-random tactic selection.
-- @param #REDGCI2v2 self
-- @return #string tactic key
function REDGCI2v2:_PickTactic()
    local order  = { "PINCER", "HIGH_LOW", "STAGGER", "TRAIL", "GIRAFFE" }
    if self._Fixed_Tactic then return self._Fixed_Tactic end
    if UTILS.lcg == nil then
      UTILS.LCGRandomSeed(timer.getTime()*math.random())
    end
    --local roll  = UTILS.LCGRandomSeed(timer.getTime())
    local roll = math.floor(UTILS.LCGRandom()*100)
    local accum = 0
    for _,tactic in ipairs(order) do
      local weight = REDGCI2v2.TacticWeights[tactic] or 0
      accum = accum + weight
      self:T(self.lid.."_PickTactic "..string.format("Roll %d | Tactic %s | Weight %s | Chosen %s",roll,tactic,weight,tostring(roll <= accum)))
      if roll <= accum then
          return tactic
      end
    end
    return "PINCER"  -- fallback
end

--- [Internal] Target assignment — greedy minimum range 2×2.
-- Sets self._assignment = { [1]=groupName, [2]=groupName }
-- @param #REDGCI2v2 self
-- @param #table F1  fighter-1 unit data
-- @param #table F2  fighter-2 unit data
-- @param #table T1  target-1 unit data (or nil)
-- @param #table T2  target-2 unit data (or nil)
function REDGCI2v2:_AssignTargets(F1, F2, T1, T2)
    if not T2 then
        -- 2v1: both fighters on single target
        self._assignment = {
            [1] = self.Target1Group,
            [2] = self.Target1Group,
        }
        self:_Log("Assignment: 2v1 — both on " .. self.Target1Group)
        return
    end

    local d11 = self:_Range(F1, T1)
    local d22 = self:_Range(F2, T2)
    local d12 = self:_Range(F1, T2)
    local d21 = self:_Range(F2, T1)

    if d11 + d22 <= d12 + d21 then
        self._assignment = { [1] = self.Target1Group, [2] = self.Target2Group }
        self:_Log(string.format("Assignment: F1→T1 (%.0fm) F2→T2 (%.0fm)", d11, d22))
    else
        self._assignment = { [1] = self.Target2Group, [2] = self.Target1Group }
        self:_Log(string.format("Assignment: F1→T2 (%.0fm) F2→T1 (%.0fm)", d12, d21))
    end
end

--- [Internal] Target assignment — greedy minimum range 2×2.
-- Sets self._assignment = { [1]=groupName, [2]=groupName }
-- @param #REDGCI2v2 self
function REDGCI2v2:_SetDebugMenuTactics()
    --  { "PINCER", "HIGH_LOW", "STAGGER", "TRAIL", "GIRAFFE" }
   --local root = missionCommands.addSubMenuForCoalition(self.Coalition, "GCI")
   local root2 = missionCommands.addSubMenuForCoalition(self.Coalition, "GCI Tactic")
   missionCommands.addCommandForCoalition(self.Coalition, "PINCER", root2,
        function()
            self._Fixed_Tactic = "PINCER"
            self:_Log("Debug: PINCER Tactic")
        end)
      missionCommands.addCommandForCoalition(self.Coalition, "HIGH_LOW", root2,
        function()
            self._Fixed_Tactic = "HIGH_LOW"
            self:_Log("Debug: HIGH_LOW Tactic")
        end)
      missionCommands.addCommandForCoalition(self.Coalition, "TRAIL", root2,
        function()
            self._Fixed_Tactic = "TRAIL"
            self:_Log("Debug: TRAIL Tactic")
        end)
      missionCommands.addCommandForCoalition(self.Coalition, "STAGGER", root2,
        function()
            self._Fixed_Tactic = "STAGGER"
            self:_Log("Debug: STAGGER Tactic")
        end)
     missionCommands.addCommandForCoalition(self.Coalition, "GIRAFFE", root2,
        function()
            self._Fixed_Tactic = "GIRAFFE"
            self:_Log("Debug: GIRAFFE Tactic")
        end)
end

--- [Internal]Compute perpendicular vector (90° left of heading dx,dz), normalised.
-- @param #REDGCI2v2 self
-- @return #number px, #number pz
function REDGCI2v2._perp_left(dx, dz)
    local len = math.sqrt(dx*dx + dz*dz)
    if len < 1 then return 0, 0 end
    return -dz/len, dx/len
end

--- [Internal]Apply split tactic geometry and push waypoints to both fighters.
-- Called once at COMMIT transition.
-- @param #REDGCI2v2 self
-- @param #table  F1   fighter-1 unit data
-- @param #table  F2   fighter-2 unit data
-- @param #table  TgtMid  geometric midpoint of active targets
function REDGCI2v2:_ApplyTactic(F1, F2, TgtMid)
 
    -- Map Lua tactic name → C-kern TacticType int
    -- (must match TacticType enum in pursuit_solver.h)
    local TACTIC_INT = {
        PINCER   = 0,
        HIGH_LOW = 1,
        STAGGER  = 2,
        TRAIL    = 3,
        GIRAFFE  = 4,
    }
    local tactic_int = TACTIC_INT[self._tactic] or 0
 
    -- Call C-kernel geometry solver
    -- Returns 12 DCS-coordinate values (x=Nord, z=Ost, y=Höhe)
    local plan = REDGCI_KERNEL.computeSplitDCS(F1, F2, TgtMid, tactic_int, self._variation)
    local wp1x, wp1z, wp1y = plan.wp_f1.x, plan.wp_f1.z, plan.wp_f1.y
    local wp2x, wp2z, wp2y = plan.wp_f2.x, plan.wp_f2.z, plan.wp_f2.y
    local mp1x, mp1z, mp1y = plan.merge_f1.x, plan.merge_f1.z, plan.merge_f1.y
    local mp2x, mp2z, mp2y = plan.merge_f2.x, plan.merge_f2.z, plan.merge_f2.y
    local wp2_absolute = plan.wp_f2.absolute_alt or false
    -- altitudes
    local alt1 = self._gci1.AltOffset or 0
    local alt2 = wp2_absolute and 0 or (self._gci2.AltOffset or 0)
 
    self:T(self.lid .. string.format(
        "_ApplyTactic: %s var=%.2f | F1→(%.0f,%.0f,%.0fm) F2→(%.0f,%.0f,%.0fm)",
        self._tactic, self._variation,
        wp1x, wp1z, wp1y + alt1,
        wp2x, wp2z, wp2y + alt2))
 
    -- Set _wp_override on sub-instances.
    -- REDGCI:_ResolveTarget() checks this each tick and uses it instead
    -- of ip_x/ip_z/ip_y for OVERRIDE_TICKS ticks, then reverts.
    self._gci1._wp_override = {
        x     = wp1x,
        z     = wp1z,
        y     = wp1y + alt1,
        ticks = REDGCI2v2.OVERRIDE_TICKS,
        absolute_alt=false,
    }
    self._gci2._wp_override = {
        x     = wp2x,
        z     = wp2z,
        y     = wp2y + alt2,
        ticks = REDGCI2v2.OVERRIDE_TICKS,
        absolute_alt=wp2_absolute,
    }
 
    self._tactic_applied = true
 
    if self.Debug then
        trigger.action.outTextForCoalition(
            self.Coalition,
            string.format("[GCI2v2] %s | F1→(%.0f,%.0f,%.0fm) F2→(%.0f,%.0f,%.0fm)",
                self._tactic,
                wp1x, wp1z, wp1y + alt1,
                wp2x, wp2z, wp2y + alt2), 10)
    end
end

--- [Internal] Compute geometric midpoint of active targets.
-- @param #table T1  unit data or nil
-- @param #table T2  unit data or nil
-- @return #table { x, y, z }
function REDGCI2v2._tgt_midpoint(T1, T2)
    if T1 and T2 then
        return {
            x = (T1.x + T2.x) * 0.5,
            y = (T1.y + T2.y) * 0.5,
            z = (T1.z + T2.z) * 0.5,
        }
    elseif T1 then
        return { x=T1.x, y=T1.y, z=T1.z }
    elseif T2 then
        return { x=T2.x, y=T2.y, z=T2.z }
    end
end

--- [Internal] Formation VECTOR waypoint: both fighters get a shared intercept vector
-- with a lateral offset to maintain 2 km spacing.
-- @param #REDGCI2v2 self
-- @param #table F1  fighter-1 unit data
-- @param #table F2  fighter-2 unit data
-- @param #table TgtMid  target midpoint
function REDGCI2v2:_PushFormationVector(F1, F2, TgtMid)
    local dx = TgtMid.x - F1.x
    local dz = TgtMid.z - F1.z
    local px, pz = REDGCI2v2._perp_left(dx, dz)

    -- Apply formation offset to fighter-2 only (lead stays on centreline)
    local wp_y = TgtMid.y + self.AltOffset

    local cruise1 = math.max(F1.spd, 200)
    local cruise2 = math.max(F2.spd, 200)

    -- Rolling WP clamped to lookahead distance
    local wp1x, wp1z, wp1y = self._gci1:_ComputeRollingWaypoint(F1, TgtMid.x, TgtMid.z, wp_y)
    local wp2x, wp2z, wp2y = self._gci2:_ComputeRollingWaypoint(F2,
        TgtMid.x + px * REDGCI2v2.FORMATION_OFFSET,
        TgtMid.z + pz * REDGCI2v2.FORMATION_OFFSET,
        wp_y)

    self._gci1:_PushWaypoint(wp1x, wp1z, wp1y, cruise1)
    self._gci2:_PushWaypoint(wp2x, wp2z, wp2y, cruise2)
end

-- ─────────────────────────────────────────────────────────────
--  FSM handlers
-- ─────────────────────────────────────────────────────────────

--- [Internal] Start — build sub-instances and start them.
-- @param #REDGCI2v2 self
function REDGCI2v2:onafterStart(From, Event, To)
    self:T(self.lid .. "Starting...")

    -- Initial target assignment (may be reassigned later)
    self._assignment = {
        [1] = self.Target1Group,
        [2] = self.Target2Group or self.Target1Group,
    }

    -- Create and start the two REDGCI sub-instances.
    -- They manage their own FSM ticks; we drive formation/tactic logic here.
    self._gci1 = self:_MakeGCI(self.Fighter1Group, self._assignment[1], self.Callsign1) -- #REDGCI
    local FreqOffset = self.FreqOffset or 0.5
    --if self.IsAIPlane == true then FreqOffset = 0.5 end
    self._gci2 = self:_MakeGCI(self.Fighter2Group, self._assignment[2], self.Callsign2, FreqOffset)
    
    if self.PilotOneCallsign then
      self._gci1:SetPilotSRS(self.PilotOneCallsign, self.PilotOneSRSCulture, self.PilotOneSRSVoice, self.PilotOneSRSSpeaker)
    end
    
    if self.PilotTwoCallsign then
      self._gci2:SetPilotSRS(self.PilotTwoCallsign, self.PilotTwoSRSCulture, self.PilotTwoSRSVoice, self.PilotTwoSRSSpeaker)
    end
    
    self._gci1:Start()
    self._gci2:Start()

    self:T(self.lid .. "Sub-GCI started: " .. self.Callsign1 .. " / " .. self.Callsign2)
    
    -- Gemeinsame SRS Queue — verhindert dass beide Instanzen sich übersprechen
    --local shared_queue = MSRSQUEUE:New("REDGCI2v2_" .. self.FlightCallsign)
    --self._gci1._srs_queue = shared_queue
    --self._gci2._srs_queue = shared_queue
    --self:T(self.lid .. "Shared SRS queue injected.")
    
    -- WF Deconfliction Gate — Option C: Winkel-basiert
    local gci1 = self._gci1
    local gci2 = self._gci2
    local flight = self
    
    -- Lead: immer frei
    gci1._wf_gate = nil
    
    -- Wingman: WF nur wenn Winkel Lead-Schussvektor → Wingman > 30°
    gci2._wf_gate = function(gci)
        local F1 = gci1:_GetUnitData(gci1.FighterGroupName)
        local F2 = gci:_GetUnitData(gci.FighterGroupName)
        local T1 = gci1:_GetUnitData(gci1.TargetGroupName)
        if not F1 or not F2 or not T1 then return true end -- kein Daten = nicht blocken
    
        -- Vektor Lead → Ziel
        local ax = T1.x - F1.x
        local az = T1.z - F1.z
        local len_a = math.sqrt(ax*ax + az*az)
    
        -- Vektor Lead → Wingman
        local bx = F2.x - F1.x
        local bz = F2.z - F1.z
        local len_b = math.sqrt(bx*bx + bz*bz)
    
        if len_a < 1 or len_b < 1 then return true end
    
        -- Winkel zwischen beiden Vektoren
        local dot = (ax*bx + az*bz) / (len_a * len_b)
        dot = math.max(-1.0, math.min(1.0, dot))  -- clamp für acos
        local angle_deg = math.deg(math.acos(dot))
    
        local safe = angle_deg > 30.0
        if not safe then
            flight:I(flight.lid .. string.format(
                "WF Gate: Wingman zu nah am Schussvektor (%.1f°) — blocke WF", angle_deg))
        end
        return safe
    end
    
    if self.Debug then
      self:_SetDebugMenuTactics()
    end
    
    trigger.action.outTextForCoalition(
        self.Coalition,
        string.format("[GCI] Двухзвенный перехват. %s и %s готовы.",
            self.Callsign1, self.Callsign2), 5)

    self:__Status(-2)
end

--- [Internal] Main 2v2 coordination tick.
-- Runs in parallel with the two sub-instance ticks.
-- Handles: target reassignment, tactic selection, formation VECTOR, split at COMMIT.
-- @param #REDGCI2v2 self
--- Main 2v2 coordination tick.
-- Handles: target reassignment, tactic selection and split at COMMIT.
-- Does NOT push waypoints during VECTOR — sub-instances handle their own WPs.
-- @param #REDGCI2v2 self
--- Main 2v2 coordination tick.
-- Handles: target reassignment, tactic selection and pre-COMMIT split at SPLIT_RANGE.
-- Does NOT push waypoints during VECTOR — sub-instances handle their own WPs.
-- @param #REDGCI2v2 self
function REDGCI2v2:onafterStatus(From, Event, To)

    -- ── Get unit data ─────────────────────────────────────────
    local F1 = self._gci1:_GetUnitData(self.Fighter1Group)
    local F2 = self._gci2:_GetUnitData(self.Fighter2Group)

    -- Stop if both fighters gone
    if not F1 and not F2 then
        self:T(self.lid .. "Both fighters lost — stopping.")
        self:Stop()
        return
    end

    -- ── Target data ───────────────────────────────────────────
    local T1 = self._gci1:_GetUnitData(self._assignment[1])
    local T2 = self.Target2Group
               and self._gci2:_GetUnitData(self._assignment[2])
               or nil

    -- ── Target reassignment (only in true 2v2) ────────────────
    if self.Target2Group then
        local alive1 = T1 ~= nil
        local alive2 = T2 ~= nil

        if not alive1 and alive2 then
          if self._assignment[1] ~= self.Target2Group then
              self:T(self.lid .. "Target-1 destroyed — F1 → Target-2")
              self._assignment[1]        = self.Target2Group
              self._gci1.TargetGroupName = self.Target2Group
              -- Nur zurücksetzen wenn noch genug Range für sinnvollen Split
              local F1 = self._gci1:_GetUnitData(self.Fighter1Group)
              local T2 = self._gci2:_GetUnitData(self._assignment[2])
              if F1 and T2 and self:_Range(F1, T2) > REDGCI2v2.SPLIT_RANGE then
                  self._tactic_applied = false
              end
          end
        elseif alive1 and not alive2 then
          if self._assignment[2] ~= self.Target1Group then
              self:T(self.lid .. "Target-2 destroyed — F2 → Target-1")
              self._assignment[2]        = self.Target1Group
              self._gci2.TargetGroupName = self.Target1Group
              local F2 = self._gci2:_GetUnitData(self.Fighter2Group)
              local T1 = self._gci1:_GetUnitData(self._assignment[1])
              if F2 and T1 and self:_Range(F2, T1) > REDGCI2v2.SPLIT_RANGE then
                  self._tactic_applied = false
              end
          end
        elseif not alive1 and not alive2 then
            self:T(self.lid .. "All targets destroyed.")
            self:Stop()
            return
        end

        -- Re-fetch after possible reassignment
        T1 = self._gci1:_GetUnitData(self._assignment[1])
        T2 = self._gci2:_GetUnitData(self._assignment[2])
    end
    
    -- ── Picture call: count = alle lebenden Ziele ─────────────
    -- Jede REDGCI-Instanz hat keinen INTEL-Zugriff, also setzen wir
    -- den Count hier zentral: Summe aller lebenden Units in T1+T2.
    local total_count = 0
    for _, grpname in ipairs({ self.Target1Group, self.Target2Group }) do
        if grpname then
            local grp = GROUP:FindByName(grpname)
            if grp then total_count = total_count + grp:CountAliveUnits() end
        end
    end
    if total_count > 0 then
        self._gci1._target_count = total_count
        self._gci2._target_count = total_count
    end

    -- ── Target midpoint ───────────────────────────────────────
    local tgt_mid = REDGCI2v2._tgt_midpoint(T1, T2)

    -- ── Current states ────────────────────────────────────────
    local state1 = self._gci1._prev_state
    local state2 = self._gci2._prev_state

    -- ── Optimal assignment re-evaluation during VECTOR ────────
    if self.Target2Group and
       (state1 == "VECTOR" or state1 == nil) and
       (state2 == "VECTOR" or state2 == nil) then
        if F1 and F2 and T1 and T2 then
            self:_AssignTargets(F1, F2, T1, T2)
            self._gci1.TargetGroupName = self._assignment[1]
            self._gci2.TargetGroupName = self._assignment[2]
        end
    end

    -- ── Pre-COMMIT Split ──────────────────────────────────────
    -- Fires during VECTOR at SPLIT_RANGE (default 50km), giving fighters
    -- enough room to fly the split geometry before entering COMMIT.
    -- PINCER needs ~10km spread, STAGGER ~13km lag — 50km gives plenty of time.
    if (not self._tactic_applied) and F1 and F2 and tgt_mid then

        -- Use minimum range across both fighters to their targets
        local r1 = T1 and self:_Range(F1, T1) or math.huge
        local r2 = (T2 and self:_Range(F2, T2))
                   or (T1 and self:_Range(F2, T1))
                   or math.huge
        local min_range = math.min(r1, r2)

        if min_range <= REDGCI2v2.SPLIT_RANGE then
            self._tactic    = self:_PickTactic()
            --local roll  = UTILS.LCGRandomSeed(timer.getTime())
            self._variation = math.ceil(UTILS.LCGRandom()*100)

            self:T(self.lid .. string.format(
                "Split at %.0fm — tactic=%s variation=%.2f",
                min_range, self._tactic, self._variation))

            if self.Debug then
                trigger.action.outTextForCoalition(
                    self.Coalition,
                    string.format("[GCI2v2] Taktik: %s (%.0f km)",
                        self._tactic, min_range / 1000), 8)
            end

            self:_ApplyTactic(F1, F2, tgt_mid)
            -- _tactic_applied is set inside _ApplyTactic
        end
    end

    self:__Status(-self.TickInterval)
end

--- [Internal] Stop handler.
-- @param #REDGCI2v2 self
function REDGCI2v2:onafterStop(From, Event, To)
    self:T(self.lid .. "Stopped.")
end

-------------------------------------------------------------------------------
-- END of Class
-------------------------------------------------------------------------------