--- **Functional** - Enhanced Warsaw Pact GCI.
--
-- ## Main Features:
--
--    * Guide AI and human pilots in Warsaw Pact Style. Single flight engagements.
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
-- @module Functional.RedGCI
-- @image Func_RedGCI.png

---
-- # RedGCI — Soviet GCI Doctrine & Player Guide
--
-- ## Philosophy: Централизованное управление (Centralized Control)
-- 
-- The fundamental difference between Soviet and NATO GCI is **who makes the tactical decision**.
-- 
-- In NATO doctrine, the GCI controller provides situational awareness — bearing, range, altitude, aspect — and the pilot decides how to prosecute the intercept. The pilot is an autonomous tactician. 
-- GCI is an advisor.
-- 
-- In Soviet doctrine, the GCI controller **directs**. The pilot executes. The controller selects the intercept geometry, assigns the heading, manages the radar, calls weapons free, and coordinates 
-- multi-ship tactics. The pilot's job is to fly the numbers and shoot when told. This is not a flaw — it is the system working as designed. Soviet fighter pilots were trained to be precise executors 
-- of GCI instructions, not independent tacticians. The ground radar network (PVO) was the brain; the aircraft was the weapon.
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
-- You do not decide when to turn your radar on. The GCI will tell you when to switch on (`локатор` / `Radar on`). Before that call, you fly cold and silent. This preserves your emissions 
-- discipline and prevents the target from getting an early RWR spike.
-- 
-- ### Weapons free is a controlled event.
-- 
-- You do not engage until the controller clears you (`цель разрешена` / `WEAPONS FREE`). The controller determines when geometry, range, and aspect are favorable. Shooting early breaks the 
-- coordinated intercept and may compromise your wingman's attack.
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
-- The controller has a track. You are being vectored onto an intercept geometry. **Your radar is off**. The controller is solving a collision course and updating your heading every tick. 
-- Altitude calls reflect the intercept geometry — you may be sent below the target (classic Soviet shoot-up doctrine for radar-limited types) or level/above (MiG-29/Su-27 lookdown geometry). 
-- Expect heading updates every 10–15 seconds.
-- 
-- **What you should do:** Fly the heading. Don't deviate. **Don't turn your radar on yet**. Speed is expected at 900kph TAS (depending on airframe)
-- 
-- ### COMMIT
-- Range has closed to approximately 30km. The controller calls the picture: count and type. Your radar comes on. You are now committed to the intercept — turning away is no longer the 
-- default option. The controller is building your radar geometry toward a lock.
-- 
-- **What you should do:** Activate your radar. Acquire the target. Do not fire yet.
-- 
-- ### RADAR_CONTACT
-- You have radar lock (or the AI has achieved it). The controller confirms lock and calls range. If geometry and range are favorable, weapons free follows immediately. If not — for example 
-- if aspect angle is unfavorable for a stern conversion — the controller holds fire and waits for better geometry.
-- 
-- **What you should do:** Maintain lock. Track the target. Wait for the weapons free call.
-- 
-- ### VISUAL
-- Range has closed to approximately 5km — visual conditions. Weapons free is automatic at this point. You are now in the merge envelope.
-- 
-- **What you should do:** Engage.
-- 
-- ### MERGE
-- Inside 2km. The GCI transitions to merge control: bearing to target, overshoot calls, separation instructions, reattack vectors. At this range the controller cannot see fine-grained 
-- geometry — merge calls are based on relative bearing and closure.
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
-- When two fighters are dispatched against a threat, the GCI selects a tactic automatically based on the tactical situation. The tactic is applied at COMMIT — until then, both 
-- fighters are vectored together toward the intercept midpoint.
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
-- During a tactic split, you may receive a heading that seems unusual — a large lateral offset or an unexpected altitude change. **Trust the vector.** The controller is positioning you for 
-- the tactic geometry. The merge point will bring you back onto the target.
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
--     → "Attention, radar contact. Two, fighter, 45 kilometers." (all CAP fighters)   
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
-- Human players are dispatched first when available. If a human and AI are both in the CAP pool, the human is always assigned to the next intercept. AI fills gaps. The dispatcher does not 
-- send a single fighter if a pair is available — pairing is always preferred.
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
-- **The Soviet system is not inferior** — it is optimized for a different kind of pilot and a different operational context. Mass interception of large NATO strike packages over defended 
-- Soviet airspace demanded centralized, efficient, high-throughput GCI control. RedGCI brings that experience to DCS.
-- 
-- @field #REDGCI
REDGCI = {}

--- Class name
REDGCI.ClassName = "REDGCI"

--- Version
REDGCI.version = "2.0.0"

--- Waypoint lookahead: WP is clamped to this factor × speed × tick_interval (minimum 15 km)
-- @field #number WP_DISTANCE_FACTOR
REDGCI.WP_DISTANCE_FACTOR = 5.0

---
--@field #table RadioChannels
REDGCI.RadioChannels = {
  [1] = 125,
  [2] = 125.5,
  [3] = 126,
  [4] = 126.5,
  [5] = 127,
  [6] = 127.5,
  [7] = 128,
  [8] = 128.5,
  [9] = 129,
  [10] = 129.5,
}

-- ─────────────────────────────────────────────────────────────
--  Localized messages — embedded (gci_messages.lua no longer needed)
-- ─────────────────────────────────────────────────────────────

--- @type REDGCI.Messages
-- @field #string en
-- @field #string de
-- @field #string ru
REDGCI.Messages = {

    -- ── ENGLISH ──────────────────────────────────────────────
    en = {
        -- GCI → Pilot
        VECTOR              = "{CALLSIGN}, vector {HDG}, {ALT}.",
        VECTOR_WITH_TTI     = "{CALLSIGN}, vector {HDG}, {ALT}. Target in {TTI_M}.",
        COMMIT_FIRST        = "{CALLSIGN}, target, {COUNT}, {TYPE}. Radar on.",
        COMMIT_NO_LOCK      = "{CALLSIGN}, correction: bearing {ASPECT}, {RNG} kilometers. No lock?",
        COMMIT_NUDGE        = "{CALLSIGN}, {DIR_LR} ten degrees.",
        RADAR_LOCK_WF       = "{CALLSIGN}, lock confirmed. {RNG} kilometers. WEAPONS FREE.",
        RADAR_LOCK_HOLD     = "{CALLSIGN}, lock confirmed. {RNG} kilometers. Hold fire.",
        RADAR_WF_NOW        = "{CALLSIGN}, WEAPONS FREE.",
        VISUAL_CONFIRM      = "{CALLSIGN}, visual confirmed. WEAPONS FREE.",
        NOTCH_ENTRY         = "{CALLSIGN}, target maneuvering. Standby.",
        NOTCH_UPDATE        = "{CALLSIGN}, target {DIR_RL}, {RNG} kilometers.",
        ABORT_BINGO         = "{CALLSIGN}, BINGO. Break off. Course {HDG}.",
        ABORT_THREAT        = "{CALLSIGN}, THREAT. Break off. Course {HDG}.",
        MERGE_ENTRY         = "{CALLSIGN}, contact {DIR_RL}, {ASPECT} degrees. FIGHT.",
        MERGE_OVERSHOOT     = "{CALLSIGN}, overshoot. Break {DIR_LR}.",
        MERGE_SEPARATION    = "{CALLSIGN}, separate. Climb and reset.",
        MERGE_REATTACK      = "{CALLSIGN}, reattack. Target {DIR_RL}.",
        MERGE_LOST          = "{CALLSIGN}, blind. Heading {HDG}.",
        MERGE_SPLASH        = "{CALLSIGN}, good kill. RTB.",
        RADAR_ON            = "{CALLSIGN}, radar on.",
        WEAPONS_FREE        = "{CALLSIGN}, WEAPONS FREE.",
        RADIO_SWITCH_CHANNEL = "{CALLSIGN}, switch to channel {CHNL} for GCI.",
        -- Pilot → GCI acknowledgements
        ACK_VECTOR          = "Copy, {HDG}.",
        ACK_COMMIT          = "Copy.",
        ACK_WEAPONS_FREE    = "Copy. Engaging.",
        ACK_ABORT           = "Copy. Breaking off.",
        ACK_SPLASH          = "Splash. RTB.",
    },

    -- ── GERMAN ───────────────────────────────────────────────
    de = {
        -- GCI → Pilot
        VECTOR              = "{CALLSIGN}, Kurs {HDG}, {ALT}.",
        VECTOR_WITH_TTI     = "{CALLSIGN}, Kurs {HDG}, {ALT}. Ziel in {TTI_M}.",
        COMMIT_FIRST        = "{CALLSIGN}, Ziel, {COUNT}, {TYPE}. Radar an.",
        COMMIT_NO_LOCK      = "{CALLSIGN}, Korrektur: Peilung {ASPECT}, {RNG} Kilometer. Kein Lock?",
        COMMIT_NUDGE        = "{CALLSIGN}, {DIR_LR} zehn Grad.",
        RADAR_LOCK_WF       = "{CALLSIGN}, Lock bestätigt. {RNG} Kilometer. Feuer frei.",
        RADAR_LOCK_HOLD     = "{CALLSIGN}, Lock bestätigt. {RNG} Kilometer. Warten.",
        RADAR_WF_NOW        = "{CALLSIGN}, Feuer frei.",
        VISUAL_CONFIRM      = "{CALLSIGN}, Sichtkontakt. Feuer frei.",
        NOTCH_ENTRY         = "{CALLSIGN}, Ziel manövriert. Warten.",
        NOTCH_UPDATE        = "{CALLSIGN}, Ziel {DIR_RL}, {RNG} Kilometer.",
        ABORT_BINGO         = "{CALLSIGN}, BINGO. Abbruch. Kurs {HDG}.",
        ABORT_THREAT        = "{CALLSIGN}, GEFAHR. Abbruch. Kurs {HDG}.",
        MERGE_ENTRY         = "{CALLSIGN}, Kontakt {DIR_RL}, {ASPECT} Grad. Angriff.",
        MERGE_OVERSHOOT     = "{CALLSIGN}, Überschuss. {DIR_LR} ausbrechen.",
        MERGE_SEPARATION    = "{CALLSIGN}, trennen. Steigen und neu ansetzen.",
        MERGE_REATTACK      = "{CALLSIGN}, neu angreifen. Ziel {DIR_RL}.",
        MERGE_LOST          = "{CALLSIGN}, BLIND. Kurs {HDG}.",
        MERGE_SPLASH        = "{CALLSIGN}, Treffer. Heimkurs.",
        RADAR_ON            = "{CALLSIGN}, Radar an.",
        WEAPONS_FREE        = "{CALLSIGN}, Feuer frei.",
        RADIO_SWITCH_CHANNEL = "{CALLSIGN}, umschalten auf Kanal {CHNL} für Anweisungen.",
        -- Pilot → GCI acknowledgements
        ACK_VECTOR          = "Verstanden, Kurs {HDG}.",
        ACK_COMMIT          = "Verstanden.",
        ACK_WEAPONS_FREE    = "Verstanden. Greife an.",
        ACK_ABORT           = "Verstanden. Abbruch.",
        ACK_SPLASH          = "Treffer. Heimkurs.",
    },

    -- ── RUSSIAN ───────────────────────────────────────────────
    ru = {
        -- GCI → Pilot
        VECTOR              = "{CALLSIGN}, курс {HDG}, высота {ALT}.",
        VECTOR_WITH_TTI     = "{CALLSIGN}, курс {HDG}, высота {ALT}. До цели {TTI_M} минут.",
        COMMIT_FIRST        = "{CALLSIGN}, цель, {COUNT}, {TYPE}. Локатор.",
        COMMIT_NO_LOCK      = "{CALLSIGN}, поправка: азимут {ASPECT}, дальность {RNG}. Захват?",
        COMMIT_NUDGE        = "{CALLSIGN}, довернись {DIR_LR}.",
        RADAR_LOCK_WF       = "{CALLSIGN}, захват. Дальность {RNG}. Цель разрешена.",
        RADAR_LOCK_HOLD     = "{CALLSIGN}, захват. Дальность {RNG}. Жди.",
        RADAR_WF_NOW        = "{CALLSIGN}, цель разрешена.",
        VISUAL_CONFIRM      = "{CALLSIGN}, визуальный. Цель разрешена.",
        NOTCH_ENTRY         = "{CALLSIGN}, цель маневрирует. Жди.",
        NOTCH_UPDATE        = "{CALLSIGN}, цель {DIR_RL}, дальность {RNG}.",
        ABORT_BINGO         = "{CALLSIGN}, топливо. Прекрати. Курс {HDG}.",
        ABORT_THREAT        = "{CALLSIGN}, угроза. Прекрати. Курс {HDG}.",
        MERGE_ENTRY         = "{CALLSIGN}, контакт {DIR_RL}, {ASPECT} градусов. Бой.",
        MERGE_OVERSHOOT     = "{CALLSIGN}, перелёт. Разворот {DIR_LR}.",
        MERGE_SEPARATION    = "{CALLSIGN}, выход. Высота, повтори.",
        MERGE_REATTACK      = "{CALLSIGN}, повтори. Цель {DIR_RL}.",
        MERGE_LOST          = "{CALLSIGN}, потеря. Курс {HDG}.",
        MERGE_SPLASH        = "{CALLSIGN}, молодец. Домой.",
        RADAR_ON            = "{CALLSIGN}, локатор.",
        WEAPONS_FREE        = "{CALLSIGN}, цель разрешена.",
        RADIO_SWITCH_CHANNEL = "{CALLSIGN}, переключись на канал {CHNL} для указаний.",
        -- Pilot → GCI acknowledgements (kurz und militärisch)
        ACK_VECTOR          = "Понял, курс {HDG}.",
        ACK_COMMIT          = "Понял.",
        ACK_WEAPONS_FREE    = "Понял. Атакую.",
        ACK_ABORT           = "Понял. Прекращаю.",
        ACK_SPLASH          = "Цель поражена. Домой.",
    },
}

--- @type REDGCI.DirTokens
-- @field #string en
-- @field #string de
-- @field #string ru
REDGCI.DirTokens = {
    en = { left="left",   right="right",  ahead="ahead",   behind="behind", low="low",   high="high"  },
    de = { left="links",  right="rechts", ahead="voraus",  behind="hinten", low="tief",  high="hoch"  },
    ru = { left="влево",  right="вправо", ahead="впереди", behind="сзади",  low="ниже",  high="выше"  },
}

--- ─────────────────────────────────────────────────────────────
--  Picture tokens — COUNT and TYPE
--  COUNT: 1=single, 2=pair, 3-4=group, 5+=big group
--  TYPE:  RCS-based fighter/bomber/machines (machines = unknown/medium)
-- ─────────────────────────────────────────────────────────────

--- @type REDGCI.CountTokens
-- @field #string en
-- @field #string de
-- @field #string ru
REDGCI.CountTokens = {
    en = { single="single",       pair="two",    group="group",       biggroup="big group"     },
    de = { single="einzel",       pair="zwei",   group="Gruppe",      biggroup="große Gruppe"  },
    ru = { single="одиночная",    pair="пара",   group="группа",      biggroup="большая группа"},
}

--- @type REDGCI.TypeTokens
-- @field #string en
-- @field #string de
-- @field #string ru
REDGCI.TypeTokens = {
    en = { fighter="fighter",     bomber="bomber",              machines="machines"          },
    de = { fighter="Jäger",       bomber="Bomber",              machines="Maschinen"         },
    ru = { fighter="истребитель", bomber="бомбардировщик",      machines="машины"            },
}

---
-- @field #number RCS_FIGHTER_MAX
-- @field #number RCS_BOMBER_MIN
-- RCS thresholds für automatische Typ-Erkennung aus INTEL
REDGCI.RCS_FIGHTER_MAX = 6.0    -- < 6 m² → Jäger
REDGCI.RCS_BOMBER_MIN  = 20.0   -- > 20 m² → Bomber
                                 -- dazwischen → Maschinen (unbekannt)

-- ─────────────────────────────────────────────────────────────
--  Constructor
-- ─────────────────────────────────────────────────────────────

--- Create a new REDGCI instance.
-- @param #REDGCI self
-- @param #string FighterGroupName  DCS group name of the interceptor(s)
-- @param #string TargetGroupName   DCS group name of the target(s)
-- @param #string Callsign          Radio callsign string (e.g. "Сокол-1")
-- @param #number Coalition         coalition.side.RED or coalition.side.BLUE
-- @return #REDGCI self
function REDGCI:New(FighterGroupName, TargetGroupName, Callsign, Coalition)
    local self = BASE:Inherit(self, FSM:New())  --#REDGCI

    -- Log prefix
    self.lid = string.format("REDGCI (%s) | ", Callsign or "GCI")

    -- ── Core identity ─────────────────────────────────────────
    self.FighterGroupName = FighterGroupName or "Mig-29A"
    self.TargetGroupName  = TargetGroupName  or "Target"
    self.Callsign         = Callsign         or "Сокол 1"
    self.Coalition        = Coalition        or coalition.side.RED

    -- ── Defaults ─────────────────────────────────────────────
    self.Locale           = "ru"
    self.TickInterval     = 10.0
    self.TxRepeatInterval = 30.0
    self.SubtitleTime     = 8
    self.IsAIPlane        = true
    self.HomeBaseName     = nil
    self.HomeBase         = nil    -- Vec2 {x,y}
    self.Debug                = false
    self.WFRange              = 20000  -- metres: AI weapons-free range (C kernel wf=false workaround)
    self.AltOffset            = -700   -- metres relative to target altitude for intercept waypoint.
    self.ContactLostTimeout   = 3      -- ticks without contact before declaring target gone
    self._contact_lost_ticks  = 0     -- internal counter
                                   -- Negative = below target (Shootup geometry, classic Soviet doctrine
                                   -- for radar-limited types like MiG-21/early MiG-23).
                                   -- Zero or positive = Lookdown/Shoot-Down geometry (MiG-29, Su-27).
                                   -- Use SetAltOffset() to override.
    self._target_count        = 1
    self._target_type         = "FIGHTER"

    -- ── SRS defaults (GCI controller voice) ──────────────────
    self.SRSPath          = nil
    self.SRSFreq          = 251
    self.SRSMod           = radio.modulation.AM
    self.SRSCulture       = "ru-RU"
    self.SRSVoice         = MSRS.Voices.Google.Standard.ru_RU_Standard_D
    self.SRSPort          = 5002

    -- ── Pilot SRS defaults (separate voice for acknowledgements) ──
    self.PilotCallsign    = nil   -- if nil, no pilot ACKs are transmitted
    self.PilotSRSCulture  = "ru-RU"
    self.PilotSRSVoice    = MSRS.Voices.Google.Standard.ru_RU_Standard_B
    self._pilot_msrs      = nil
    self._pilot_queue     = nil

    -- ── Internal state (per instance) ─────────────────────────
    self._pilot_flags = { radar=false, visual=false, threat=false }
    self._prev_state  = nil
    self._prev_wf     = false
    self._prev_radar  = false
    self._last_tx     = { text="", time=0 }
    self._msrs        = nil
    self._srs_queue   = nil
    self._gettext     = nil
    self._wp_override = nil   -- { x, z, y, ticks } set by REDGCI2v2 for tactic geometry
    self._missilerangeflag = 2  -- 1, HALF_WAY_RMAX_NEZ = 2, TARGET_THREAT_EST = 3, RANDOM_RANGE = 4. Defaults to 2.
    
    -- FSM state tracking for REDGCI_KERNEL (no C DLL needed)
    self._ticks_in_state    = 0
    self._merge_phase       = "ENTRY"
    self._merge_phase_prev  = "ENTRY"
    self._merge_ticks       = 0
    self._merge_pass_count  = 0

    -- ── FSM transitions ───────────────────────────────────────
    self:SetStartState("Stopped")
    self:AddTransition("Stopped", "Start",  "Running")
    self:AddTransition("Running", "Status", "Running")
    self:AddTransition("Running", "Stop",   "Stopped")

    self:I(self.lid .. "v" .. REDGCI.version .. " created. Fighter=" ..
           self.FighterGroupName .. " Target=" .. self.TargetGroupName)

    return self
end

-- ─────────────────────────────────────────────────────────────
--  User API — configuration (all return self for chaining)
-- ─────────────────────────────────────────────────────────────

--- Set the locale for radio messages.
-- @param #REDGCI self
-- @param #string Locale  "en", "de", or "ru" (default "ru")
-- @return #REDGCI self
function REDGCI:SetLocale(Locale)
    self.Locale = Locale or "ru"
    return self
end

--- Enable or disable AI waypoint and radar management.
-- @param #REDGCI self
-- @param #boolean IsAI           true = push waypoints + control radar
-- @param #string  HomeBaseName   AIRBASE name for RTB (e.g. AIRBASE.Caucasus.Nalchik)
-- @return #REDGCI self
function REDGCI:SetAIMode(IsAI, HomeBaseName)
    self.IsAIPlane = IsAI ~= false
    if HomeBaseName then
        self.HomeBaseName = HomeBaseName
        local ab = AIRBASE:FindByName(HomeBaseName)
        if ab then
            self.HomeBase = ab:GetVec2()
        else
            self:E(self.lid .. "SetAIMode: AIRBASE '" .. tostring(HomeBaseName) .. "' not found!")
        end
    end
    return self
end

--- Configure SRS radio output.
-- @param #REDGCI self
-- @param #string  Path       Path to SRS (or nil to use MSRS default)
-- @param #number  Frequency  MHz, e.g. 251
-- @param #number  Modulation radio.modulation.AM or FM (default AM)
-- @param #string  Culture    BCP-47 culture string, e.g. "ru-RU"
-- @param #string  Voice      MSRS voice constant
-- @param #number  Port       SRS port (default 5002)
-- @param #number  Speed      Speach speed, default 1.
-- @return #REDGCI self
function REDGCI:SetSRS(Path, Frequency, Modulation, Culture, Voice, Port, Speed)
    self.SRSPath    = Path
    self.SRSFreq    = Frequency  or self.SRSFreq
    self.SRSMod     = Modulation or self.SRSMod
    self.SRSCulture = Culture    or self.SRSCulture
    self.SRSVoice   = Voice      or self.SRSVoice
    self.SRSPort    = Port       or self.SRSPort
    self.SRSSpeed   = Speed      or 1
    self:T({F=Frequency,V=Voice})
    return self
end

--- Enable SRS autotranslation, do not forget to set voices according to language! Requires HOUND as SRS backend!
-- @param #REDGCI self
-- @param #string languagecode Language to translate to, defaults to "fr". Takes [ISO 639-1](https://en.wikipedia.org/wiki/ISO_639-1) language codes.
-- @param #string provider (optional) Translation provider, defaults to `MSRS.Provider.GOOGLE`
-- @return #REDGCI2v2 self
function REDGCI:EnableSRSAutoTranslate(languagecode,provider)
  self.translateEnabled = true
  self.translateLanguage = languagecode or "fr"
  self.translateProvider = provider or MSRS.Provider.GOOGLE
  return self
end

--- Configure available channel numbers and frequencies for pilots.
-- @param #REDGCI self
-- @param #table RadioTable Table of available channel numbers and their frequencies, indexed by channel number
-- @return #REDGCI self
-- @usage
--  Use as follows, e.g.
--          local RadioTable = {  
--            [1] = 125,
--            [2] = 125.5,
--            [3] = 126,
--            [4] = 126.5,
--            [5] = 127,
--            [6] = 127.5,
--            [7] = 128,
--            [8] = 128.5,
--            [9] = 129,
--            [10] = 129.5,
--               }
--            dispatch:SetRadioChannelList(RadioTable)
function REDGCI:SetRadioChannelList(RadioTable)
  self.RadioChannels = RadioTable
  return self
end

--- Set SRS Provider
--@param #REDGCI self
--@param #string Provider
function REDGCI:SetSRSProvider(Provider)
  self:T(self.lid.."SetSRSProvider "..tostring(Provider))
  self.SRSProvider = Provider or MSRS.Provider.GOOGLE
  return self
end

--- Set SRS Voice Speaker for Hound/Piper
--@param #REDGCI self
--@param #number Speaker Speaker number, e.g. 11 for Speaker "318 (11)"
function REDGCI:SetSRSPiperSpeaker(Speaker)
  self:T(self.lid.."SetSRSPiperSpeaker "..tostring(Speaker))
  self.SRSSpeaker = Speaker
  return self
end

--- Configure the pilot voice for radio acknowledgements.
-- The pilot uses the same frequency/modulation as the GCI controller but
-- a distinct voice so the two can be told apart on the radio.
-- Set PilotCallsign to nil (default) to disable pilot ACKs entirely.
-- @param #REDGCI self
-- @param #string  PilotCallsign  Pilot's callsign (e.g. "Сокол-1"), or nil to disable ACKs.
-- @param #string  Culture        BCP-47 culture string (default same as GCI)
-- @param #string  Voice          MSRS voice constant (default ru_RU_Standard_B)
-- @param #number  Speaker        (Optional) MSRS Speaker for Hound/Piper Voices, e.g. 11 for "318 (11)"
-- @return #REDGCI self
function REDGCI:SetPilotSRS(PilotCallsign, Culture, Voice, Speaker)
  self:T({CS=PilotCallsign,CU=Culture,VO=Voice,SP=Speaker})
  self.PilotCallsign   = PilotCallsign
  self.PilotSRSCulture = Culture or self.SRSCulture
  self.PilotSRSVoice   = Voice   or MSRS.Voices.Google.Standard.ru_RU_Standard_B
  self.PilotSRSSpeaker = Speaker
  return self
end



--- Set the target count manually (used when no INTEL source is attached).
-- Overridden automatically when INTEL is active.
-- @param #REDGCI self
-- @param #number Count  Number of targets (1=single, 2=pair, 3-4=group, 5+=big group)
-- @return #REDGCI self
function REDGCI:SetTargetCount(Count)
    self._target_count = Count or 1
    return self
end

--- Set the target type manually (used when no INTEL source is attached).
-- @param #REDGCI self
-- @param #string Type  "FIGHTER", "BOMBER", or "MACHINES" (default)
-- @return #REDGCI self
function REDGCI:SetTargetType(Type)
    self._target_type = Type or "MACHINES"
    return self
end

--- Set the GCI tick interval in seconds.
-- @param #REDGCI self
-- @param #number Seconds  Default 10.0
-- @return #REDGCI self
function REDGCI:SetTickInterval(Seconds)
    self.TickInterval = Seconds or 10.0
    return self
end

--- Set minimum seconds between identical transmissions.
-- @param #REDGCI self
-- @param #number Seconds  Default 30.0
-- @return #REDGCI self
function REDGCI:SetTxRepeatInterval(Seconds)
    self.TxRepeatInterval = Seconds or 30.0
    return self
end

--- Set the AI weapons-free range threshold in metres.
-- Weapons free is declared when the C kernel wf flag is true OR (AI mode AND
-- state is RADAR_CONTACT AND range <= WFRange). Set to 0 to disable the
-- Lua-side override and rely solely on the C kernel.
-- @param #REDGCI self
-- @param #number Meters  Default 20000
-- @return #REDGCI self
function REDGCI:SetWFRange(Meters)
    self.WFRange = Meters or 20000
    return self
end

--- Enable or disable debug logging.
-- @param #REDGCI self
-- @param #boolean OnOff  true = verbose logging
-- @return #REDGCI self
function REDGCI:SetDebug(OnOff)
    self.Debug = OnOff ~= false
    return self
end

--- Set the altitude offset applied to intercept waypoints relative to the target altitude.
-- Models the preferred attack geometry of the fighter type:
--
--   Negative offset (below target) = classic Soviet Shootup doctrine.
--     The fighter is vectored below the target so its radar looks up
--     against a clean sky background, avoiding ground clutter.
--     Appropriate for MiG-21, early MiG-23 (limited or no LDSD capability).
--     Typical value: -700 m (default).
--
--   Zero or positive offset (at or above target) = Lookdown/Shoot-Down.
--     The fighter has a modern pulse-Doppler radar capable of suppressing
--     ground clutter and shooting downward.
--     Appropriate for MiG-29 (N019), Su-27 (N001), MiG-31 (Zaslon).
--     Typical value: 0 (level) to +300 m (slight high perch).
--
-- The offset is only applied during VECTOR and COMMIT states.
-- In RADAR_CONTACT and beyond, exact geometry is driven by the C kernel.
-- @param #REDGCI self
-- @param #number Meters  Altitude offset in metres (default -700).
-- @return #REDGCI self
function REDGCI:SetAltOffset(Meters)
    self.AltOffset = Meters or -700
    return self
end

--- Set how many consecutive ticks without a target contact are tolerated
-- before the GCI declares the intercept over.
--
-- During a contact gap the GCI transmits NOTCH_ENTRY on the first missing
-- tick and then stays silent, holding the last known vector, until either
-- the contact is re-acquired (counter resets) or the timeout is reached
-- (MERGE_SPLASH + Stop).
--
-- One tick = TickInterval seconds (default 10 s), so the default of 3 ticks
-- means ~30 s of tolerance — enough to cover a typical notch manoeuvre or
-- brief Doppler blind spot without falsely declaring a kill.
-- @param #REDGCI self
-- @param #number Ticks  Number of ticks (default 3).
-- @return #REDGCI self
function REDGCI:SetContactLostTimeout(Ticks)
    self.ContactLostTimeout = Ticks or 3
    return self
end

--- Signal that the pilot has achieved radar lock.
-- Equivalent to pressing "Radar Lock" in the F10 menu.
-- @param #REDGCI self
-- @param #boolean OnOff
-- @return #REDGCI self
function REDGCI:SetPilotRadarLock(OnOff)
    self._pilot_flags.radar = OnOff ~= false
    return self
end

--- Signal that the pilot has visual contact.
-- @param #REDGCI self
-- @param #boolean OnOff
-- @return #REDGCI self
function REDGCI:SetPilotVisual(OnOff)
    self._pilot_flags.visual = OnOff ~= false
    return self
end

--- Set range on which AI will prefer to fire missiles.
-- MAX_RANGE = 0, NEZ_RANGE = 1, HALF_WAY_RMAX_NEZ = 2, TARGET_THREAT_EST = 3, RANDOM_RANGE = 4. Defaults to 2.
-- @param #REDGCI self
-- @param #number Flag The behavior to set. 
-- @return #REDGCI self
function REDGCI:SetMissileFiringFlag(Flag)
  self._missilerangeflag = Flag or 2
  return self
end

--- Signal that the pilot's RWR is active (threat warning).
-- @param #REDGCI self
-- @param #boolean OnOff
-- @return #REDGCI self
function REDGCI:SetPilotThreat(OnOff)
    self._pilot_flags.threat = OnOff ~= false
    return self
end

--- Reset FSM state and pilot flags (e.g. after a splash or new intercept).
-- @param #REDGCI self
-- @return #REDGCI self
function REDGCI:Reset()
    self._pilot_flags        = { radar=false, visual=false, threat=false }
    self._prev_state         = nil
    self._prev_wf            = false
    self._prev_radar         = false
    self._last_tx            = { text="", time=0 }
    self._contact_lost_ticks = 0
    self._wp_override = nil   -- { x, z, y, ticks } set by REDGCI2v2 for tactic geometry
    RedGCI.reset(self.Callsign)
    self:_SetRadar(false)
    self:_SetWeaponsFree(false)
    self:T(self.lid .. "Reset.")
    return self
end

-- ─────────────────────────────────────────────────────────────
--  Internal helpers
-- ─────────────────────────────────────────────────────────────

--- [INTERNAL]
--- @param #REDGCI self
function REDGCI:_Log(msg)
    if self.Debug then
        env.info(self.lid .. msg)
    end
end

--- [INTERNAL] Initialize TEXTANDSOUND localization from embedded Messages table.
-- @param #REDGCI self
function REDGCI:_InitLocalization()
    self._gettext = TEXTANDSOUND:New("REDGCI_" .. self.Callsign, "en")
    for locale, entries in pairs(REDGCI.Messages) do
        local loc = string.lower(tostring(locale))
        for id, text in pairs(entries) do
            self._gettext:AddEntry(loc, tostring(id), text)
        end
    end
end

--- [INTERNAL] Initialize MSRS + queue.
-- @param #REDGCI self
function REDGCI:_InitSRS()
    -- GCI controller voice
    self._msrs = MSRS:New(self.SRSPath, self.SRSFreq, self.SRSMod)
    self._msrs:SetPort(self.SRSPort)
    self._msrs:SetLabel("GCI")
    self._msrs:SetCulture(self.SRSCulture)
    self._msrs:SetVoice(self.SRSVoice)
    self._msrs:SetCoalition(self.Coalition)
    if self.SRSProvider then
      self._msrs:SetProvider(self.SRSProvider)
    end
    if self.SRSSpeaker then
      self._msrs:SetSpeakerPiper(self.SRSSpeaker)
    end
    if self.translateEnabled == true then 
      self._msrs:SetAutoTranslate(self.translateProvider,self.translateLanguage)
    end
    self._srs_queue = MSRSQUEUE:New("REDGCI_" .. self.Callsign) -- Sound.MSRS#MSRSQUEUE

    -- Pilot voice (only when a pilot callsign has been configured)
    if self.PilotCallsign then
        self._pilot_msrs = MSRS:New(self.SRSPath, self.SRSFreq, self.SRSMod)
        self._pilot_msrs:SetPort(self.SRSPort)
        self._pilot_msrs:SetLabel("PILOT")
        self._pilot_msrs:SetCulture(self.PilotSRSCulture)
        self._pilot_msrs:SetVoice(self.PilotSRSVoice)
        self._pilot_msrs:SetCoalition(self.Coalition)
        if self.SRSProvider then
            self._pilot_msrs:SetProvider(self.SRSProvider)
        end
        if self.SRSSpeaker then
            self._pilot_msrs:SetSpeakerPiper(self.PilotSRSSpeaker)
        end
        if self.translateEnabled == true then 
            self._pilot_msrs:SetAutoTranslate(self.translateProvider,self.translateLanguage)
        end
        self._pilot_queue = self._srs_queue
        self:_Log("Pilot SRS ready: " .. self.PilotCallsign)
    end
end

--- [INTERNAL] Get live unit data from a DCS group (returns first alive unit).
-- @param #REDGCI self
-- @param #string GroupName
-- @return #table  { x, y, z, spd, vx, vy, vz, hdg, fuel } or nil
function REDGCI:_GetUnitData(GroupName)
  if not GroupName then return end
    local grp = Group.getByName(GroupName)
    if not grp then return nil end
    for _, u in ipairs(grp:getUnits()) do
        if u and u:isExist() and u:isActive() then
            local pos3 = u:getPosition()
            local p    = pos3.p
            local fwd  = pos3.x
            local v    = u:getVelocity()
            return {
                x    = p.x,
                y    = p.y,
                z    = p.z,
                spd  = math.sqrt(v.x*v.x + v.z*v.z),
                vx   = v.x,
                vy   = v.y,
                vz   = v.z,
                hdg  = math.deg(math.atan2(fwd.z, fwd.x)) % 360,
                fuel = u:getFuel(),
            }
        end
    end
    return nil
end

--- [INTERNAL] Parse a pipe-separated token string from the C kernel.
-- Input:  "VECTOR|hdg=165|alt=4500|tti_m=8|wf=false"
-- Output: { key="VECTOR", hdg=165, alt=4500, tti_m=8, wf=false }
-- @param #REDGCI self
function REDGCI:_ParseTokens(TokenStr)
  self:T("_ParseTokens "..TokenStr)
    if not TokenStr or TokenStr == "" then return nil end
    local parts = {}
    for part in string.gmatch(TokenStr, "[^|]+") do
        parts[#parts + 1] = part
    end
    local result = { key = parts[1] }
    for i = 2, #parts do
        local k, v = string.match(parts[i], "^([%w_]+)=(.+)$")
        if k and v then
            if     v == "true"  then result[k] = true
            elseif v == "false" then result[k] = false
            elseif tonumber(v)  then result[k] = tonumber(v)
            else                     result[k] = v
            end
        end
    end
    UTILS.PrintTableToLog(result)
    return result
end

--- [INTERNAL] Fill {PLACEHOLDER} tokens in a template string.
-- @param #REDGCI self
function REDGCI:_FillTemplate(Template, Vars)
    return (string.gsub(Template, "{([%w_]+)}", function(key)
        return tostring(Vars[key] or "")
    end))
end

--- [INTERNAL] Resolve COUNT token to localized word.
-- @param #REDGCI self
-- @param #number Count
-- @return #string
function REDGCI:_CountToken(Count)
    local t   = REDGCI.CountTokens[self.Locale] or REDGCI.CountTokens["en"]
    local n   = Count or 1
    if     n == 1 then return t.single
    elseif n == 2 then return t.pair
    elseif n <= 4 then return t.group
    else               return t.biggroup
    end
end

--- [INTERNAL] Resolve TYPE token to localized word.
-- @param #REDGCI self
-- @param #string TypeKey  "FIGHTER", "BOMBER", "MACHINES"
-- @return #string
function REDGCI:_TypeToken(TypeKey)
    local t = REDGCI.TypeTokens[self.Locale] or REDGCI.TypeTokens["en"]
    local k = string.lower(TypeKey or "machines")
    return t[k] or t.machines
end

--- [INTERNAL] Derive count and type from INTEL contact.
-- Updates self._target_count and self._target_type.
-- @param #REDGCI self
function REDGCI:_UpdatePictureFromIntel()
    if not self.Intel or not self.Intel:Is("Running") then return end
    local contacts = self.Intel:GetContactTable()
    if not contacts then return end

    local count   = 0
    local rcs_sum = 0.0
    local rcs_n   = 0

    for _, contact in pairs(contacts) do
        if contact.ctype == INTEL.Ctype.AIRCRAFT then
            if not (self.IntelTargetFilter and
                    not string.find(contact.groupname or "", self.IntelTargetFilter, 1, true)) then
                -- Anzahl Units in der Kontaktgruppe
                local grp = GROUP:FindByName(contact.groupname)
                if grp then
                    count = count + grp:CountAliveUnits()
                else
                    count = count + 1
                end
                -- RCS aus contact wenn verfügbar
                if contact.rcs then
                    rcs_sum = rcs_sum + contact.rcs
                    rcs_n   = rcs_n + 1
                end
            end
        end
    end

    if count > 0 then
        self._target_count = count
    end

    -- Type aus durchschnittlichem RCS
    if rcs_n > 0 then
        local avg_rcs = rcs_sum / rcs_n
        if     avg_rcs < REDGCI.RCS_FIGHTER_MAX then self._target_type = "FIGHTER"
        elseif avg_rcs > REDGCI.RCS_BOMBER_MIN  then self._target_type = "BOMBER"
        else                                          self._target_type = "MACHINES"
        end
    end
end

--- [INTERNAL] Resolve a direction key to a localized word.
-- @param #REDGCI self
-- @param #string Key   "left", "right", "ahead", "behind", "low", "high"
-- @return #string
function REDGCI:_DirToken(Key)
    local t = REDGCI.DirTokens[self.Locale] or REDGCI.DirTokens["en"]
    return t[Key] or Key
end

--- [INTERNAL] Derive "left"/"right" turn instruction from aspect angle.
-- @param #REDGCI self
function REDGCI:_DeriveDirLR(AspectAngle)
    return (AspectAngle > 5.0) and "right" or "left"
end

--- [INTERNAL] Derive target position relative to fighter ("ahead"/"behind"/"left"/"right").
-- @param #REDGCI self
-- @param #table Fighter  unit data
-- @param #table Target   unit data
-- @return #string
function REDGCI:_DeriveDirRL(Fighter, Target)
    local dx     = Target.x - Fighter.x
    local dz     = Target.z - Fighter.z
    local f_hdg  = math.atan2(Fighter.vx, Fighter.vz)
    local to_tgt = math.atan2(dx, dz)
    local rel    = math.deg(to_tgt - f_hdg) % 360
    if     rel < 45  or rel > 315 then return "ahead"
    elseif rel < 135              then return "right"
    elseif rel < 225              then return "behind"
    else                               return "left"
    end
end

--- [INTERNAL] Build and dispatch a radio transmission.
-- @param #REDGCI self
-- @param #string TokenStr   Pipe-separated token string from C kernel
-- @param #string DirLR      "left"/"right" for manoeuvre cues
-- @param #string DirRL      "ahead"/"behind"/"left"/"right" for target position
-- @param #number Priority
function REDGCI:_Transmit(TokenStr, DirLR, DirRL, Priority)
    local tok = self:_ParseTokens(TokenStr)
    if not tok then
        self:_Log("_Transmit: empty token string")
        return
    end

    -- Look up template
    local template = self._gettext:GetEntry(tok.key, self.Locale)
    if not template then
        self:_Log("_Transmit: no template for key=" .. tostring(tok.key) ..
                  " locale=" .. self.Locale)
        return
    end
    
    tok.aspect = tok.aspect or tok.brg  -- Merge nutzt brg statt aspect
    
    -- Build variable table
    local vars = {
        CALLSIGN = string.gsub(self.Callsign, "-", " "),
        HDG      = tok.hdg    and string.format("%03d", tok.hdg)          or "",
        ALT      = tok.alt    and tostring(math.floor(tok.alt))           or "",
        RNG      = tok.rng    and tostring(math.floor(tok.rng))           or "",
        TTI_M    = tok.tti_m  and tostring(tok.tti_m)                     or "",
        TTI_S    = tok.tti_s  and tostring(tok.tti_s)                     or "",
        ASPECT   = tok.aspect and string.format("%03d", tok.aspect)       or "",
        DIR_LR   = self:_DirToken(DirLR or "right"),
        DIR_RL   = self:_DirToken(DirRL or "ahead"),
        BRG    = tok.brg    and string.format("%03d", tok.brg)    or "",
        COUNT    = self:_CountToken(self._target_count),
        TYPE     = self:_TypeToken(self._target_type),
        CHNL     = tok.channel or 1,
    }

    local text = self:_FillTemplate(template, vars)

    -- Throttle: same text repeated within TxRepeatInterval → suppress
    local now = timer.getTime()
    if text == self._last_tx.text and
       (now - self._last_tx.time) < self.TxRepeatInterval then
        self:_Log("[SRS/THROTTLED/" .. tok.key .. "] " .. text)
        return
    end
    self._last_tx.text = text
    self._last_tx.time = now

    self:_Log(string.format("[SRS/%s/%s] %s", self.Locale, tok.key, text))
    
    local srstext = string.gsub(text,"%.",";")
      
    if self._srs_queue and self._msrs then
        local delay = tok.delay or 3.0
        --MSRSQUEUE:NewTransmission(text, duration, msrs, tstart, interval, subgroups, subtitle, subduration, frequency, modulation, gender, culture, voice, volume, label,coordinate,speed,speaker,priority)
        self._srs_queue:NewTransmission(
            srstext,          -- message text
            nil,              -- duration (auto)
            self._msrs,       -- MSRS instance
            delay,            -- start delay
            2,                -- interval
            {GROUP:FindByName(RedGCI.FIGHTER_GROUP)},            -- Subgroups (Subtitle)
            text,             -- subtitle
            self.SubtitleTime,-- subtitle duration
            nil, nil,         -- channel/mod (from msrs)
            nil, nil, nil,    -- gender/culture/voice (from msrs)
            nil,              -- volume
            "GCI",            -- label
            nil,              -- coordinate
            self.SRSSpeed,    -- speed
            nil,               -- speaker
            Priority          -- priority
        )
    else
        -- Fallback: on-screen text
        trigger.action.outText(text, self.SubtitleTime, false)
    end
    
    if self.Debug then
      trigger.action.outText(text, self.SubtitleTime, false)
    end
end

--- [INTERNAL] Dispatch a pilot acknowledgement transmission.
-- Uses the pilot's MSRS voice on the same frequency as GCI.
-- The ACK key is looked up in the Messages table under the pilot locale;
-- vars are filled identically to _Transmit so {HDG} etc. work.
-- The ACK fires after a short realistic reaction delay (GCI_delay + ~2s).
-- No-op when PilotCallsign is nil or pilot SRS is not initialised.
-- @param #REDGCI self
-- @param #string AckKey   Message key, e.g. "ACK_VECTOR"
-- @param #table  Vars     Variable table (same format as _Transmit vars)
-- @param #number GciDelay Delay of the preceding GCI transmission (seconds)
function REDGCI:_TransmitPilot(AckKey, Vars, GciDelay)
    if not self.IsAIPlane then return end
    if not self.PilotCallsign then return end
    if not self._pilot_queue or not self._pilot_msrs then return end

    local template = self._gettext:GetEntry(AckKey, self.Locale)
    if not template then
        self:_Log("_TransmitPilot: no template for key=" .. AckKey)
        return
    end

    -- Inject pilot callsign into vars
    --local v = Vars or {}
    --v.CALLSIGN = self.PilotCallsign

    --local text = self:_FillTemplate(template, v)
    local text = self.PilotCallsign
    -- Pilot speaks ~2-3 s after GCI finishes (GCI delay + estimated GCI speech + reaction)
    local pilot_delay = (GciDelay or 3.0)

    self:_Log(string.format("[PILOT/%s/%s] %s", self.Locale, AckKey, text))
    --(text, duration, msrs, tstart, interval, subgroups, subtitle, subduration, frequency, modulation, gender, culture, voice, volume, label,coordinate,speed,speaker)
    self._pilot_queue:NewTransmission(
        text,
        nil, -- duration
        self._pilot_msrs, --msrs
        pilot_delay, --tstrat
        1, --interval
        nil, --{GROUP:FindByName(self.FighterGroupName)}, --subgroups
        nil, --text, subtitle
        nil, --self.SubtitleTime, subduration
        nil, nil, --frequency, modulation, 
        nil, nil, self.PilotSRSVoice, --gender, culture, voice
        nil, --volume
        text -- label
    )

    if self.Debug then
        trigger.action.outText("[PILOT] " .. text, self.SubtitleTime, false)
    end
end

--- [INTERNAL] Push a waypoint
-- @param #REDGCI self
-- @param #number wx       DCS x coord (North)
-- @param #number wz       DCS z coord (East)
-- @param #number wy       altitude MSL metres
-- @param #number SpeedMps airspeed in m/s
-- @param #boolean LandHome  true = set waypoint type to LAND at HomeBase
function REDGCI:_PushWaypoint(wx, wz, wy, SpeedMps, LandHome)
    if not self.IsAIPlane then return end

    local grp = GROUP:FindByName(self.FighterGroupName)
    if not grp then return end

    -- Terrain floor + 300 m minimum clearance
    local terrain_floor = land.getHeight({ x=wx, y=wz }) + 300
    local safe_alt      = math.max(wy, terrain_floor)
    local kmph          = UTILS.MpsToKmph(SpeedMps)
    local speed_tas = UTILS.IasToTas(kmph,math.max(wy, safe_alt))
    
    local tsk = grp:TaskAerobatics()
    tsk = grp:TaskAerobaticsStraightFlight(tsk,1,math.max(wy, safe_alt),speed_tas,UseSmoke,StartImmediately,10)
    
    local startpoint = grp:GetCoordinate()
    local wp0 = startpoint:WaypointAir(
        COORDINATE.WaypointAltType.BARO,
        COORDINATE.WaypointType.TurningPoint,
        COORDINATE.WaypointAction.FlyoverPoint,
        speed_tas, true, nil, {}, "VECTOR")

    local endpoint = COORDINATE:New(wx, safe_alt, wz)
    local wp1
    if LandHome then
      grp:SetOptionLandingOverheadBreak()
      grp:SetOptionLandingForcePair()
        local ab = self.HomeBaseName and AIRBASE:FindByName(self.HomeBaseName) or nil
        wp1 = endpoint:WaypointAir(
            COORDINATE.WaypointAltType.BARO,
            COORDINATE.WaypointType.Land,
            COORDINATE.WaypointAction.Landing,
            speed_tas, true, ab, {}, "HOME")
    else
        wp1 = endpoint:WaypointAir(
            COORDINATE.WaypointAltType.BARO,
            COORDINATE.WaypointType.TurningPoint,
            COORDINATE.WaypointAction.FlyoverPoint,
            speed_tas, true, nil, tsk, "VECTOR")
    end

    grp:Route({ wp0, wp1 }, 2)
    self:_Log(string.format("WP → x=%.0f z=%.0f alt=%.0fm spd=%.0f kph TAS=%.0f kph",
                            wx, wz, safe_alt, kmph, speed_tas))
end

--- [INTERNAL] Resolve intercept target point, honouring any active tactic override.
-- When REDGCI2v2 has set _wp_override, that point is used instead of the
-- C-kernel intercept point for N ticks, then reverts to normal guidance.
-- @param #REDGCI self
-- @param #number ip_x  Normal intercept x (DCS North, AltOffset already applied)
-- @param #number ip_z  Normal intercept z (DCS East)
-- @param #number ip_y  Normal intercept altitude
-- @return #number tx, tz, ty
function REDGCI:_ResolveTarget(ip_x, ip_z, ip_y)
    local ov = self._wp_override
    if ov and ov.ticks > 0 then
        ov.ticks = ov.ticks - 1
        self:_Log(string.format(
            "Override active (%d ticks left) → x=%.0f z=%.0f y=%.0f",
            ov.ticks + 1, ov.x, ov.z, ov.y))
        if ov.ticks == 0 then
            self._wp_override = nil
            self:_Log("Override expired — resuming normal intercept")
        end
        return ov.x, ov.z, ov.y, ov.absolute_alt
    end
    return ip_x, ip_z, ip_y, false
end

--- [INTERNAL] Clamp an intercept point to max_dist from the fighter.
-- Prevents the AI from overshooting on a distant waypoint.
-- @param #REDGCI self
-- @param #table  Fighter  unit data
-- @param #number ip_x     intercept x (DCS North)
-- @param #number ip_z     intercept z (DCS East)
-- @param #number ip_y     intercept altitude
-- @return #number, #number, #number  clamped wx, wz, wy
function REDGCI:_ComputeRollingWaypoint(Fighter, ip_x, ip_z, ip_y)
    local dx   = ip_x - Fighter.x
    local dz   = ip_z - Fighter.z
    local dist = math.sqrt(dx*dx + dz*dz)

    local max_dist = math.max(
        Fighter.spd * self.TickInterval * REDGCI.WP_DISTANCE_FACTOR,
        15000)  -- minimum 15 km lookahead

    if dist <= max_dist or dist < 1 then
        return ip_x, ip_z, ip_y
    end

    local nx = dx / dist
    local nz = dz / dist
    return Fighter.x + nx * max_dist,
           Fighter.z + nz * max_dist,
           ip_y
end

--- [INTERNAL] Toggle radar emission on the fighter group.
-- @param #REDGCI self
-- @param #boolean On
-- @param #number Delay
function REDGCI:_SetRadar(On,Delay)
    if not self.IsAIPlane then return end
    if Delay then
      self:ScheduleOnce(Delay,REDGCI._SetRadar,self,On)
      return
    end
    local grp = GROUP:FindByName(self.FighterGroupName)
    if not grp then return end
    if On == true then
      grp:SetOptionRadarUsingForContinousSearch()
      --grp:OptionROEWeaponFree()
      --grp:OptionAlarmStateRed()
      --grp:OptionAAAttackRange(1)
      grp:OptionECM_DetectedLockByRadar()
      grp:SetOptionJettisonEmptyTanks(true)
    else
      grp:SetOptionRadarUsingNever()
      --grp:OptionROEHoldFire()
      --grp:OptionAlarmStateAuto()
      --grp:OptionAAAttackRange(3)
      grp:OptionECM_Never()
    end
    self:_Log("Radar " .. (On and "ON" or "OFF"))
end

--- [INTERNAL] Toggle weapons free on the fighter group.
-- @param #REDGCI self
-- @param #boolean On
-- @param #number Delay Delay in seconds
function REDGCI:_SetWeaponsFree(On,Delay)
    if not self.IsAIPlane then return end
    if Delay then
      self:ScheduleOnce(Delay,REDGCI._SetWeaponsFree,self,On)
      return
    end
    -- Externer Gate-Check — REDGCI2v2 kann das überschreiben
    if On and self._wf_gate and not self._wf_gate(self) then
        self:_Log("WF geblockt — Gate nicht offen")
        return
    end
    local grp = GROUP:FindByName(self.FighterGroupName)
    if not grp then return end
    if On == true then
      --grp:SetOptionRadarUsingForContinousSearch()
      grp:OptionROEWeaponFree()
      grp:OptionAlarmStateRed()
      grp:OptionAAAttackRange(self._missilerangeflag)
      grp:OptionECM_DetectedLockByRadar()
      grp:SetOptionJettisonEmptyTanks(true)
    else
      --grp:SetOptionRadarUsingNever()
      grp:OptionROEHoldFire()
      grp:OptionAlarmStateAuto()
      grp:OptionAAAttackRange(3)
      grp:OptionECM_Never()
    end
    self:_Log("Weapons " .. (On and "ON" or "OFF"))
end

--- [INTERNAL] Register F10 coalition menu entries.
-- @param #REDGCI self
function REDGCI:_SetupF10Menu()
    local root = missionCommands.addSubMenuForCoalition(self.Coalition, "GCI")

    missionCommands.addCommandForCoalition(self.Coalition, "Radar Lock", root,
        function()
            self._pilot_flags.radar  = true
            self._pilot_flags.visual = false
            self:_Log("Pilot: Radar Lock")
        end)

    missionCommands.addCommandForCoalition(self.Coalition, "Visual Contact", root,
        function()
            self._pilot_flags.visual = true
            self:_Log("Pilot: Visual Contact")
        end)

    missionCommands.addCommandForCoalition(self.Coalition, "Threat (RWR)", root,
        function()
            self._pilot_flags.threat = true
            self:_Log("Pilot: Threat")
        end)

    missionCommands.addCommandForCoalition(self.Coalition, "Splash / Kill", root,
        function()
            self:_Transmit("MERGE_SPLASH|delay=1.5", nil, nil)
            self:Reset()
            self:_Log("Splash — Reset")
        end)

    missionCommands.addCommandForCoalition(self.Coalition, "Reset GCI", root,
        function()
            self:Reset()
            self:_Log("GCI Reset via F10 menu")
        end)
    
    --[[
    missionCommands.addCommandForCoalition(self.Coalition, "Toggle AI Mode", root,
        function()
            self.IsAIPlane = not self.IsAIPlane
            local status = self.IsAIPlane and "ON" or "OFF"
            trigger.action.outTextForCoalition(
                self.Coalition, "[GCI] AI mode " .. status, 3)
            self:_Log("AI mode: " .. status)
        end)
   --]]
end

---
-- ══════════════════════════════════════════════════════════════════
--  Part 2 — REDGCI Intel source integration
--
--  When an INTEL source is attached, REDGCI derives the intercept target
--  from the INTEL contact table instead of polling a fixed group name.
--  Selection criterion: highest threat-level aircraft contact.
--  Tie-break: closest to the fighter.
--
--  The INTEL contact's position/velocity are used directly, so the GCI
--  works even after the real unit is lost from DCS sensor view (INTEL
--  keeps a prediction window of up to 10 min for aircraft).
-- ══════════════════════════════════════════════════════════════════

--- Attach an INTEL object as the target source for this GCI instance.
-- When set, REDGCI picks the highest-threat aircraft contact from INTEL
-- on every tick instead of polling a fixed target group name.
-- The GCI continues to work with INTEL's predicted positions during
-- contact gaps (up to INTEL's configured forget window).
-- @param #REDGCI self
-- @param Ops.Intel#INTEL Intel INTEL instance (must be Started/Running).
-- @param #string Filter (optional) Only consider contacts whose group name
--                contains this substring (case-sensitive).
-- @return #REDGCI self
function REDGCI:SetIntelSource(Intel, Filter)
    self.Intel             = Intel
    self.IntelTargetFilter = Filter
    self:T(self.lid .. "Intel source set: " ..
           (Intel and Intel.alias or "nil") ..
           (Filter and (" filter='" .. Filter .. "'") or ""))
    return self
end

--- [INTERNAL] Derive intercept target data from the attached INTEL.
-- Returns a unit-data table identical in structure to _GetUnitData(),
-- or nil when no suitable contact is available.
-- @param #REDGCI self
-- @param #table FighterData  Fighter unit data (for proximity tie-break).
-- @return #table or nil
function REDGCI:_GetTargetFromIntel(FighterData)
    if not self.Intel or not self.Intel:Is("Running") then return nil end

    local contacts = self.Intel:GetContactTable()
    if not contacts then return nil end

    local best      = nil
    local bestScore = -math.huge

    for _, contact in pairs(contacts) do --#INTEL.Contact

        -- Aircraft contacts only
        if contact.ctype == INTEL.Ctype.AIRCRAFT then

        -- Optional name filter
        if self.IntelTargetFilter and
           not string.find(contact.groupname, self.IntelTargetFilter, 1, true) then
           -- goto continue
        end

        if not contact.position then end --goto continue end

        local pos = contact.position
        local dx  = pos.x - FighterData.x
        local dz  = pos.z - FighterData.z
        local rng = math.sqrt(dx * dx + dz * dz)

        -- Score: threat level primary; range as tie-break (closer = higher)
        local score = (contact.threatlevel or 0) * 100000 - rng

        if score > bestScore then
            bestScore = score
            best = contact
        end
      end
    end

    if not best then return nil end

    local pos = best.position
    local vel = best.velocity or { x = 0, y = 0, z = 0 }
    local alt = best.altitude or (pos and pos.y) or 0

    return {
        x    = pos.x,
        y    = alt,
        z    = pos.z,
        spd  = best.speed or 0,
        vx   = vel.x or 0,
        vy   = vel.y or 0,
        vz   = vel.z or 0,
        hdg  = best.heading or 0,
        fuel = 1.0,  -- not available from INTEL
    }
end

-- ─────────────────────────────────────────────────────────────
--  FSM handlers
-- ─────────────────────────────────────────────────────────────

 
-- ─────────────────────────────────────────────────────────────
--  FSM state machine (pure Lua, replaces RedGCI.fsmUpdate)
-- ─────────────────────────────────────────────────────────────
 
--- [INTERNAL] Compute next FSM state from range/aspect/pilot flags.
-- Mirrors gci_fsm_transition() from intercept_fsm.c.
-- @param #REDGCI self
-- @param #string  current   Current state string
-- @param #number  range     Distance to target (m)
-- @param #number  aspect    Aspect angle (deg)
-- @param #boolean has_radar Pilot has radar lock
-- @param #boolean has_visual Pilot has visual
-- @param #boolean threat    RWR threat
-- @param #number  fuel      Fuel fraction 0-1
-- @return #string  next state
function REDGCI:_FsmTransition(current, range, aspect, has_radar, has_visual, threat, fuel)
    local C = REDGCI_KERNEL.C
 
    -- Abort always wins
    if (fuel or 1.0) < C.FUEL_BINGO then return "ABORT" end
    if threat and range > C.RANGE_VISUAL  then return "ABORT" end
 
    if current == "VECTOR" then
        if range <= C.RANGE_COMMIT                              then return "COMMIT" end
        if aspect > C.ASPECT_NOTCH_MIN and
           aspect < C.ASPECT_NOTCH_MAX                         then return "NOTCH"  end
        return "VECTOR"
 
    elseif current == "COMMIT" then
        if has_radar                                            then return "RADAR_CONTACT" end
        if range <= C.RANGE_VISUAL and not has_radar           then return "VISUAL" end
        return "COMMIT"
 
    elseif current == "RADAR_CONTACT" then
        if not has_radar                                        then return "COMMIT" end
        if has_visual or range <= C.RANGE_VISUAL               then return "VISUAL" end
        return "RADAR_CONTACT"
 
    elseif current == "VISUAL" then
        if range <= C.RANGE_MERGE                              then return "MERGE"  end
        return "VISUAL"
 
    elseif current == "NOTCH" then
        if aspect < C.ASPECT_NOTCH_MIN or
           aspect > C.ASPECT_NOTCH_MAX                         then return "VECTOR" end
        return "NOTCH"
 
    else
        -- MERGE / ABORT / RTB are terminal — handled elsewhere
        return current
    end
end

--- [INTERNAL] Called when Start event fires (Stopped → Running).
-- Initializes localization, SRS, context, F10 menu, and schedules first tick.
-- @param #REDGCI self
function REDGCI:onafterStart(From, Event, To)
    self:T(self.lid .. "Starting...")

    self:_InitLocalization()
    self:_InitSRS()
    self:_SetRadar(false)
    self:_SetWeaponsFree(false)
    
    RedGCI.getCtxId(self.Callsign)
    if self.Debug == true and self.Callsign == "101" then
      self:_SetupF10Menu()
    end

    local mode_str = self.IsAIPlane and " [AI]" or " [Human]"
    trigger.action.outTextForCoalition(
        self.Coalition,
        "[GCI] Системы готовы. Жду цель." .. mode_str, 5)

    self:T(self.lid .. "Ready. Fighter='" .. self.FighterGroupName ..
           "' Target='" .. self.TargetGroupName ..
           "' Mode=" .. (self.IsAIPlane and "AI" or "Human"))
    
    local function GetChannel(Freq)
      for key,val in pairs(self.RadioChannels) do
        if tonumber(val)==tonumber(Freq) then
          return key
        end
      end
      return 1
    end
    
    local channel = 1
    if self.RadioChannels then channel = GetChannel(self.SRSFreq) end
    
    self:_Transmit("RADIO_SWITCH_CHANNEL|channel="..channel,nil,nil,100)
    
    -- Schedule first tick after short delay
    self:__Status(-2)
end

--- [INTERNAL] Main tick — called every TickInterval seconds while Running.
-- @param #REDGCI self
function REDGCI:onafterStatus(From, Event, To)
    local f = self:_GetUnitData(self.FighterGroupName)
    local t = self.Intel and self:_GetTargetFromIntel(f)
           or self:_GetUnitData(self.TargetGroupName)

    if not f then
        self:T(self.lid .. "Fighter '" .. self.FighterGroupName .. "' not found — stopping.")
        self:Stop()
        return
    end

    if not t then
        self._contact_lost_ticks = self._contact_lost_ticks + 1
        self:T(self.lid .. "Contact lost — tick " .. self._contact_lost_ticks ..
               "/" .. self.ContactLostTimeout)

        if self._contact_lost_ticks == 1 then
            -- First missing tick: tell pilot to stand by, keep last heading
            self:_Transmit("NOTCH_ENTRY|delay=1.5", nil, nil)
        elseif self._contact_lost_ticks >= self.ContactLostTimeout then
            -- Timeout expired: target is genuinely gone (destroyed or escaped)
            self:T(self.lid .. "Contact timeout — declaring target gone.")
            if self._prev_radar then
                self:_SetRadar(false)
            end
            self:_Transmit("MERGE_SPLASH|delay=1.5", nil, nil)
            if self.IsAIPlane and self.HomeBase then
                self:_PushWaypoint(
                    self.HomeBase.x, self.HomeBase.y,
                    1000, f.spd * 0.8, true)
            end
            self:Stop()
            return
        end
        -- Ticks 2…(timeout-1): stay silent, hold course
        self:__Status(-self.TickInterval)
        return
    end

    -- Contact (re-)acquired — reset counter
    self._contact_lost_ticks = 0
    
    -- Picture call aktualisieren (INTEL → count/type, sonst manuell gesetzt)
    self:_UpdatePictureFromIntel()
    
    -- ── 1. Intercept geometry (C kernel) ──────────────────────
    local hdg, tti, mode, wf, range, aspect, ip_x, ip_z, ip_y = REDGCI_KERNEL.computeInterceptDCS(f, t)
        --RedGCI.computeIntercept(f, t)
    --UTILS.PrintTableToLog({hdg, tti, mode, wf, range, aspect, ip_x, ip_z, ip_y},indent,noprint,maxDepth,seen)    

    if self.Debug then
        env.info(string.format(
            self.lid .. "hdg=%d tti=%d mode=%s wf=%s range=%d aspect=%d ip_x=%d ip_z=%d ip_y=%d",
            hdg, tti, mode, tostring(wf), range, aspect, ip_x, ip_z, ip_y))
    end

    if mode == "NONE" then
        self:_Log("No intercept solution (fighter too slow?)")
        self:__Status(-self.TickInterval)
        return
    end

    -- ── 2. Closure rate ───────────────────────────────────────
    local dx   = t.x - f.x
    local dz   = t.z - f.z
    local dist = math.sqrt(dx*dx + dz*dz)
    local closure = 0
    if dist > 1 then
        closure = -((t.vx - f.vx) * dx/dist + (t.vz - f.vz) * dz/dist)
    end

    -- ── 3. AI radar lock at COMMIT range ─────────────────────
    local ai_radar_lock = self.IsAIPlane and (range < 30000)

    -- ── 4. FSM update (C kernel) ──────────────────────────────
    local current_state = self._prev_state or "VECTOR"
    local state = self:_FsmTransition(
        current_state, range, aspect,
        self._pilot_flags.radar or ai_radar_lock,
        self._pilot_flags.visual,
        self._pilot_flags.threat,
        f.fuel)
 
    -- Track ticks_in_state
    if state ~= current_state then
        self._ticks_in_state = 0
    else
        self._ticks_in_state = self._ticks_in_state + 1
    end

    -- ── 5. State-transition side effects ─────────────────────
    if state ~= self._prev_state then
        self:T(self.lid .. "State: " .. (self._prev_state or "START") .. " → " .. state)

        if state == "COMMIT" then
            self:_Transmit("RADAR_ON|delay=1.5", nil, nil,75)
            self:_TransmitPilot("ACK_COMMIT", {}, 1.5)
        elseif state == "ABORT" or state == "RTB" then
            self:_SetRadar(false)
            self._prev_radar = false
            if self.HomeBase then
                self:_PushWaypoint(
                    self.HomeBase.x, self.HomeBase.y,
                    1000, f.spd * 0.8, true)
            end
            -- Pilot ACK for abort includes RTB heading
            local rtb_hdg = ""
            if self.HomeBase then
                local dx_h = self.HomeBase.x - f.x
                local dz_h = self.HomeBase.y - f.z
                rtb_hdg = string.format("%03d", math.floor(math.deg(math.atan2(dz_h, dx_h)) % 360))
            end
            self:_TransmitPilot("ACK_ABORT", { HDG = rtb_hdg }, 3.0)
        end
    end

    -- ── 6. Waypoint + radar per state (every tick) ────────────
    if state == "VECTOR" then
        self:_SetRadar(false)
        local cruise_spd    = math.max(f.spd, 200)
        local tx, tz, ty, abs_alt = self:_ResolveTarget(ip_x, ip_z, ip_y + self.AltOffset)
        local final_ty = abs_alt and ty or (ty + self.AltOffset)
        local wx, wz, wy    = self:_ComputeRollingWaypoint(f, tx, tz, final_ty)
        self:_PushWaypoint(wx, wz, wy, cruise_spd)

    elseif state == "COMMIT" or state == "RADAR_CONTACT" then
        if self._prev_radar == false then
           self:_SetRadar(true,2)
           self:_SetWeaponsFree(true,2)
           self._prev_radar = true        
        end
        local tx, tz, ty, abs_alt = self:_ResolveTarget(ip_x, ip_z, ip_y + self.AltOffset)
        local final_ty = abs_alt and ty or (ty + self.AltOffset)
        local wx, wz, wy = self:_ComputeRollingWaypoint(f, tx, tz, final_ty)
        self:_PushWaypoint(wx, wz, wy, f.spd)

    elseif state == "NOTCH" then
        if self._prev_radar == true then
           self:_SetRadar(false)
           self._prev_radar = false       
        end
    end
 
    -- ── 7. Merge phase (Lua kernel) ───────────────────────────
    if state == "MERGE" then
        local f_hdg   = math.atan2(f.vx, f.vz)
        local to_tgt  = math.atan2(t.x - f.x, t.z - f.z)
        local rel_brg = math.deg(to_tgt - f_hdg) % 360
 
        -- Build merge context
        local merge_ctx = {
            phase             = self._merge_phase,
            ticks_in_phase    = self._merge_ticks,
            range             = range,
            bearing_to_target = rel_brg,
            closure_rate      = closure,
            altitude_delta    = t.y - f.y,
            pass_count        = self._merge_pass_count,
            radar_lost        = false,
        }
        local merge_prev = { phase = self._merge_phase_prev }
 
        -- Transition
        local new_phase = REDGCI_KERNEL.mergeTransition(merge_ctx, merge_prev)
        if new_phase ~= merge_ctx.phase then
            self._merge_phase_prev = merge_ctx.phase
            self._merge_phase      = new_phase
            self._merge_ticks      = 0
            if new_phase == "SEPARATION" then
                self._merge_pass_count = self._merge_pass_count + 1
            end
        else
            self._merge_ticks = self._merge_ticks + 1
        end
        merge_ctx.phase          = self._merge_phase
        merge_ctx.ticks_in_phase = self._merge_ticks
 
        local tx_merge = REDGCI_KERNEL.buildMergeTransmission(merge_ctx, merge_prev)
 
        if not tx_merge.silence then
            local dir_lr = self:_DeriveDirLR(aspect)
            local dir_rl = self:_DeriveDirRL(f, t)
            self:_Transmit(tx_merge.token_str, dir_lr, dir_rl,tx_merge.priority)
        end
 
        self:_Log(string.format("[MERGE] range=%.0fm → %s",
            range, tx_merge.silence and "SILENCE" or tx_merge.token_str))
 
        self._prev_state = state
 
        if not self._prev_radar or not self._prev_wf then
            self:_SetRadar(true, 2)
            self:_SetWeaponsFree(true, 2)
            self._prev_radar = true
            self._prev_wf    = true
        end
 
        self:__Status(-self.TickInterval)
        return
    end

    -- ── 8. Build and send transmission ────────────────────────
    -- Effective WF: C kernel flag OR Lua-side override when AI has lock inside WEZ.
    -- (C kernel currently always returns wf=false; remove override once fixed.)
    local effective_wf = wf or (
        self.IsAIPlane           and
        self.WFRange > 0         and
        state == "RADAR_CONTACT" and
        range <= self.WFRange)
 
    -- ctx/prev for buildTransmission
    local ctx = {
        state          = state,
        range          = range,
        aspect_angle   = aspect,
        closure_rate   = closure,
        ticks_in_state = self._ticks_in_state,
        fuel_fraction  = f.fuel,
    }
    local prev_ctx = { state = self._prev_state or "VECTOR" }
 
    -- sol: VECTOR reports ip_y (intercept geometry), others report t.y (real target alt)
    local report_alt
    if state == "VECTOR" then
        local ov = self._wp_override
        if ov and ov.ticks > 0 then
            report_alt = ov.y   -- taktische Override-Höhe direkt
        else
            report_alt = ip_y + self.AltOffset
        end
    else
        report_alt = t.y
    end
    local sol = {
        heading_deg       = hdg,
        time_to_intercept = tti,
        target_alt        = report_alt,
        range             = range,
        aspect_angle      = aspect,
        weapons_free      = effective_wf,
    }
 
    local tx = REDGCI_KERNEL.buildTransmission(ctx, prev_ctx, sol)
 
    if not tx.silence then
        local dir_lr = self:_DeriveDirLR(aspect)
        local dir_rl = self:_DeriveDirRL(f, t)
        self:_Transmit(tx.token_str, dir_lr, dir_rl,tx.priority)
    end
 
    -- Weapons free edge: fire once on first transition
    if tx.weapons_free and not self._prev_wf then
        if not self._prev_radar == true then
            self:_Transmit("RADAR_ON|delay=1.5", nil, nil)
        end
        self:_Transmit("WEAPONS_FREE|delay=1.5", nil, nil,75)
        self:_TransmitPilot("ACK_WEAPONS_FREE", {}, 1.0,100)
        self:_SetRadar(true, 2)
        self:_SetWeaponsFree(true, 2)
        self._prev_radar = true
        self._prev_wf    = true
    end
    self._prev_wf = tx.weapons_free or false
 
    self:_Log(string.format(
        "[%s] HDG:%d TTI:%ds MODE:%d WF:%s RANGE:%.0fm ASPECT:%.1f° → %s",
        state, math.floor(hdg), math.floor(tti or 0), mode,
        tostring(tx.weapons_free), range, aspect,
        tx.silence and "SILENCE" or tostring(tx.token_str)))
 
    self._prev_state = state
    self:__Status(-self.TickInterval)
end

--- [INTERNAL] Called when Stop event fires.
-- @param #REDGCI self
function REDGCI:onafterStop(From, Event, To)
    self:T(self.lid .. "Stopped.")
end

-------------------------------------------------------------------------------
-- END of Class
-------------------------------------------------------------------------------
