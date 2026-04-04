--- **Functional** - Enhanced Warsaw Pact GCI Controller.
--
-- ## Main Features:
--
--    * Guide AI and human pilots in Warsaw Pact Style. GCI Dispatcher.
--    * Advanced Tactics for Groups.
--    * Many additional events that the mission designer can hook into.
--
-- ===
--
-- ### Author: **Applevangelist**
--
-- ===
-- @module Functional.REDGCI_DISPATCHER
-- @image Func_RedGCI.png


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- REDGCI_DISPATCHER class
-- @type REDGCI_DISPATCHER #REDGCI\_DISPATCHER
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
-- @field #REDGCI_DISPATCHER #REDGCI\_DISPATCHER
REDGCI_DISPATCHER = {
  ClassName = "REDGCI_DISPATCHER",
  version   = "2.0.0",
}

-- ─────────────────────────────────────────────────────────────
--  Constants
-- ─────────────────────────────────────────────────────────────

---
-- @field #number TICK_INTERVAL
-- @field #number UNITS_PER_PAIR
-- @field #number ORBIT_SPEED_KMPH
-- @field #number ORBIT_ALT_M
-- @field #number AI_PER_ZONE
-- @field #string STATE_CAP
-- @field #string STATE_ENGAGED
-- @field #string STATE_RTB
-- @field #string STATE_UNKNOWN
REDGCI_DISPATCHER.TICK_INTERVAL    = 30.0
REDGCI_DISPATCHER.UNITS_PER_PAIR   = 2
REDGCI_DISPATCHER.ORBIT_SPEED_KMPH = 600
REDGCI_DISPATCHER.ORBIT_ALT_M      = 4500
REDGCI_DISPATCHER.AI_PER_ZONE      = 2

REDGCI_DISPATCHER.STATE_CAP      = "CAP"
REDGCI_DISPATCHER.STATE_ENGAGED  = "ENGAGED"
REDGCI_DISPATCHER.STATE_RTB      = "RTB"
REDGCI_DISPATCHER.STATE_UNKNOWN  = "UNKNOWN"

-- ─────────────────────────────────────────────────────────────
--  Localized messages (token system, analogous to REDGCI)
-- ─────────────────────────────────────────────────────────────

--- @type REDGCI_DISPATCHER.Messages
REDGCI_DISPATCHER.Messages = {
    en = {
        RTB_CALL      = "{CALLSIGN}, mission complete. RTB, refuel and rearm.",
        INTEL_CONTACT = "Attention, radar contact. {COUNT}, {TYPE}, {RNG} kilometers.",
        DISPATCH_CALL = "{CALLSIGN}, intercept. {COUNT}, {TYPE}.",
    },
    de = {
        RTB_CALL      = "{CALLSIGN}, Einsatz beendet. Heimkurs, tanken, bewaffnen.",
        INTEL_CONTACT = "Achtung, Radar Kontakt. {COUNT}, {TYPE}, {RNG} Kilometer.",
        DISPATCH_CALL = "{CALLSIGN}, abfangen. {COUNT}, {TYPE}.",
    },
    ru = {
        RTB_CALL      = "{CALLSIGN}, задание выполнено. Домой, дозаправка, перевооружение.",
        INTEL_CONTACT = "Внимание, локатор обнаружил цель. {COUNT}, {TYPE}, дальность {RNG}.",
        DISPATCH_CALL = "{CALLSIGN}, на перехват. {COUNT}, {TYPE}.",
    },
}

-- ─────────────────────────────────────────────────────────────
--  Constructor
-- ─────────────────────────────────────────────────────────────

--- Create a new REDGCI_DISPATCHER instance.
-- @param #REDGCI_DISPATCHER self
-- @param #string TemplateName     Name of the late-activated template group (1 unit)
-- @param Core.Set#SET_ZONE ZoneSet SET_ZONE mit CAP-Holding-Zonen
-- @param Ops.Intel#INTEL Intel     Laufende INTEL-Instanz
-- @param #number Coalition         coalition.side.RED / BLUE
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:New(TemplateName, ZoneSet, Intel, Coalition)
    local self = BASE:Inherit(self, FSM:New())

    self.lid          = "REDGCI_DISPATCHER | "
    self.TemplateName = TemplateName
    self.ZoneSet      = ZoneSet
    self.Intel        = Intel
    self.Coalition    = Coalition or coalition.side.RED

    self.HomeBaseName  = nil
    self.HomeBase      = nil
    self.Locale        = "ru"
    self.Debug         = true
    self.AltOffset     = -700
    self.WFRange       = 20000
    self.OrbitAlt      = REDGCI_DISPATCHER.ORBIT_ALT_M
    self.OrbitSpeed    = REDGCI_DISPATCHER.ORBIT_SPEED_KMPH
    self.AiPerZone     = REDGCI_DISPATCHER.AI_PER_ZONE
    self.StartCallsign = 100

    self.SRSPath     = nil
    self.SRSFreq     = 251
    self.SRSMod      = radio.modulation.AM
    self.SRSCulture  = "ru-RU"
    self.SRSVoice    = MSRS.Voices.Google.Standard.ru_RU_Standard_D
    self.SRSPort     = 5002
    self.SRSSpeed    = 1
    self.SRSProvider = nil

    self.ClientSet    = nil

    -- Respawn after engagement
    self.RespawnEnabled = true
    self.RespawnDelay   = 300   -- Seconds after RTB before new AI are spawned (default 5 min)
    self.RespawnCount   = 2     -- Number of new AI per respawn

    self._pool        = {}
    self._engagements = {}
    self._known_clusters = {}   -- clusterKey -> true, tracks known vs. new clusters
    self._callsign_counter = self.StartCallsign
    self._msrs        = nil
    self._srs_queue   = nil
    self._gettext     = nil

    self:SetStartState("Stopped")
    self:AddTransition("Stopped", "Start",  "Running")
    self:AddTransition("Running", "Status", "Running")
    self:AddTransition("Running", "Stop",   "Stopped")

    self:I(self.lid .. "v" .. REDGCI_DISPATCHER.version .. " created.")
    return self
end

-- ─────────────────────────────────────────────────────────────
--  User API
-- ─────────────────────────────────────────────────────────────

--- Set the home plate.
-- @param #REDGCI_DISPATCHER self
-- @param #string BaseName
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetHomeBase(BaseName)
    self.HomeBaseName = BaseName
    local ab = AIRBASE:FindByName(BaseName)
    if ab then self.HomeBase = ab
    else self:E(self.lid .. "SetHomeBase: '" .. tostring(BaseName) .. "' not found!") end
    return self
end

--- Set the client SET.
-- @param #REDGCI_DISPATCHER self
-- @param Core.Set#SET_CLIENT ClientSet
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetClientSet(ClientSet)
    self.ClientSet = ClientSet
    return self
end

--- Set orbit altitude and speed.
-- @param #REDGCI_DISPATCHER self
-- @param #number AltMSL    Altitude MSL in meters (default 4500)
-- @param #number SpeedKmph Speed in kph (km/h) (default 600)
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetOrbitParameters(AltMSL, SpeedKmph)
    self.OrbitAlt   = AltMSL    or REDGCI_DISPATCHER.ORBIT_ALT_M
    self.OrbitSpeed = SpeedKmph or REDGCI_DISPATCHER.ORBIT_SPEED_KMPH
    return self
end

--- Set number of AI spawned per CAP zone.
-- @param #REDGCI_DISPATCHER self
-- @param #number N  Default 2
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetAiPerZone(N)
    self.AiPerZone = N or 2
    return self
end

--- Set starting callsign number.
-- @param #REDGCI_DISPATCHER self
-- @param #number N  Default 100
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetStartCallsign(N)
    self.StartCallsign     = N or 100
    self._callsign_counter = self.StartCallsign
    return self
end

--- Set locale for radio messages.
-- @param #REDGCI_DISPATCHER self
-- @param #string Locale  "ru", "de", "en"
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetLocale(Locale)
    self.Locale = Locale or "ru"
    return self
end

--- Configure Dispatcher SRS.
-- @param #REDGCI_DISPATCHER self
-- @param #string Path (Optional) Defaults to "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
-- @param #number Frequency Single Frequency, e.g. 124
-- @param #number Modulation Modluation e.g. radio.modulation.AM
-- @param #string Culture (Optional) The cultrue string e.g. "en-EN"
-- @param #string Voice The voice name e.g. MSRS.Voices.Google.Wavenet.de_DE_Wavenet_G
-- @param #number Port (Optional) The SRS Server port, defaults to 5002.
-- @param #number Speed (Optional) Voice speed, defaults to 1.0 (100%)
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetSRS(Path, Frequency, Modulation, Culture, Voice, Port, Speed)
    self.SRSPath    = Path
    self.SRSFreq    = Frequency  or self.SRSFreq
    self.SRSMod     = Modulation or self.SRSMod
    self.SRSCulture = Culture    or self.SRSCulture
    self.SRSVoice   = Voice      or self.SRSVoice
    self.SRSPort    = Port       or self.SRSPort
    self.SRSSpeed   = Speed      or 1
    return self
end

--- Configure GCI SRS (the one that guides the pilots).
-- @param #REDGCI_DISPATCHER self
-- @param #number Frequency Single Frequency, e.g. 125
-- @param #string Voice The SRS Voice to be used.
-- @return #REDGCI_DISPATCHER self 
function REDGCI_DISPATCHER:SetSRSGCIDetails(StartFrequency,Voice)
  self:I({F=StartFrequency,V=Voice})
  self.SRSGCIFrequency = StartFrequency or 124
  self.SRSGCIVoice = Voice or self.SRSVoice or MSRS.Voices.Google.Wavenet.de_DE_Wavenet_B
  return self
end

--- Set SRS provider.
-- @param #REDGCI_DISPATCHER self
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetSRSProvider(Provider)
    self.SRSProvider = Provider
    return self
end

--- Set altitude offset for intercept geometry.
-- @param #REDGCI_DISPATCHER self
-- @param #number Meters  Default -700 (shoot up)
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetAltOffset(Meters)
    self.AltOffset = Meters or -700
    return self
end

--- Set weapons-free range.
-- @param #REDGCI_DISPATCHER self
-- @param #number Meters  Default 20000 (20 km)
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetWFRange(Meters)
    self.WFRange = Meters or 20000
    return self
end

--- Enable or disable automatic respawn after engagement.
-- New AI will be spawned into the same CAP zone after RespawnDelay seconds.
-- @param #REDGCI_DISPATCHER self
-- @param #boolean Enabled  Default true
-- @param #number  Delay    Seconds after RTB before respawn (default 300)
-- @param #number  Count    Number of AI to spawn (default 2)
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetRespawn(Enabled, Delay, Count)
    self.RespawnEnabled = Enabled ~= false
    self.RespawnDelay   = Delay or 300
    self.RespawnCount   = Count or 2
    return self
end

--- Enable debug logging.
-- @param #REDGCI_DISPATCHER self
-- @param #boolean OnOff
-- @return #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:SetDebug(OnOff)
    self.Debug = OnOff ~= false
    return self
end

-- ─────────────────────────────────────────────────────────────
--  Internal helpers
-- ─────────────────────────────────────────────────────────────

--- [INTERNAL]
-- @param #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:_Log(msg)
    if self.Debug then env.info(self.lid .. msg) end
end

--- [INTERNAL] Initialize TEXTANDSOUND localization.
-- @param #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:_InitLocalization()
    self._gettext = TEXTANDSOUND:New("REDGCI_DISPATCHER", "en")
    for locale, entries in pairs(REDGCI_DISPATCHER.Messages) do
        local loc = string.lower(tostring(locale))
        for id, text in pairs(entries) do
            self._gettext:AddEntry(loc, tostring(id), text)
        end
    end
end

--- [INTERNAL] Fill {PLACEHOLDER} tokens in a template string.
-- @param #REDGCI_DISPATCHER self
-- @param #string Template
-- @param #table Vars
-- @return #string
function REDGCI_DISPATCHER:_FillTemplate(Template, Vars)
  self:I({T=Template,V=Vars})
    return (string.gsub(Template, "{([%w_]+)}", function(key)
        return tostring(Vars[key] or "")
    end))
end

--- [INTERNAL] Dispatch a radio transmission via SRS queue.
-- @param #REDGCI_DISPATCHER self
-- @param #string Key      Message key from Messages table
-- @param #table  Vars     Token variables
-- @param #string GroupName For subtitle targeting (optional)
function REDGCI_DISPATCHER:_Transmit(Key, Vars, GroupName)
    if not self._gettext or not self._msrs or not self._srs_queue then return end

    local template = self._gettext:GetEntry(Key, self.Locale)
    if not template then
        self:_Log("_Transmit: no template for key=" .. tostring(Key))
        return
    end

    local text    = self:_FillTemplate(template, Vars or {})
    local srstext = string.gsub(text, "%.", ";")
    local grp     = GroupName and GROUP:FindByName(GroupName) or nil

    self._srs_queue:NewTransmission( --text,duration,msrs,tstart,interval,subgroups,subtitle,subduration,frequency,modulation,gender,culture,voice,volume,label,coordinate,speed,speaker,priority)
        srstext, nil, self._msrs, 3.0, 2,
        grp and { grp } or nil,
        text, 8,
        nil, nil, nil, nil, nil, nil, "DISPATCH",
        nil, nil, nil,75)

    self:_Log("[TX/" .. Key .. "] " .. text)
end

--- [INTERNAL] Next callsign number.
-- @param #REDGCI_DISPATCHER self
-- @return #number
function REDGCI_DISPATCHER:_NextCallsign()
    local cs = self._callsign_counter
    self._callsign_counter = self._callsign_counter + 1
    return cs
end

--- [INTERNAL] Localized tactic name for radio.
-- @param #REDGCI_DISPATCHER self
-- @param #string Tactic  "PINCER","HIGH_LOW","STAGGER","TRAIL","GIRAFFE"
-- @return #string
function REDGCI_DISPATCHER:_TacticToken(Tactic)
    local tokens = {
        en = { PINCER="pincer", HIGH_LOW="high-low", STAGGER="stagger",
               TRAIL="trail",   GIRAFFE="giraffe" },
        de = { PINCER="Zange",  HIGH_LOW="hoch-tief", STAGGER="gestaffelt",
               TRAIL="Kette",   GIRAFFE="Giraffe" },
        ru = { PINCER="клещи",  HIGH_LOW="верх-низ",  STAGGER="уступ",
               TRAIL="цепочка", GIRAFFE="жираф" },
    }
    local t = tokens[self.Locale] or tokens["en"]
    return t[Tactic] or string.lower(Tactic or "?")
end

--- [INTERNAL] Send transmission to all CAP fighters in pool.
-- @param #REDGCI_DISPATCHER self
-- @param #string Key    Message key
-- @param #table  Vars   Token variables
function REDGCI_DISPATCHER:_TransmitToAllCAP(Key, Vars)
    if not self._gettext or not self._msrs or not self._srs_queue then return end

    local template = self._gettext:GetEntry(Key, self.Locale)
    if not template then
        self:_Log("_TransmitToAllCAP: no template for key=" .. tostring(Key))
        return
    end

    local text    = self:_FillTemplate(template, Vars or {})
    local srstext = string.gsub(text, "%.", ";")
    self:I("[TX_ALL/ SRS Text: "..srstext)
    -- Collect all CAP groups for subtitle
    local subgroups = {}
    for _, entry in pairs(self._pool) do
        local grp = GROUP:FindByName(entry.groupName)
        if grp and grp:IsAlive() then
            subgroups[#subgroups + 1] = grp
        end
    end

    self._srs_queue:NewTransmission(
        srstext, nil, self._msrs, 2.0, 2,
        #subgroups > 0 and subgroups or nil,
        text, 8,
        nil, nil, nil, nil, nil, nil, "DISPATCH",
        nil, nil, nil,100)

    self:_Log("[TX_ALL/" .. Key .. "] " .. text)
end

--- [INTERNAL] Get callsign string from group.
-- Reads part after '#' in group name, e.g. "TEMPLATE#101" → "101".
-- Falls back to GetCustomCallSign(), then last part of group name.
-- @param #REDGCI_DISPATCHER self
-- @param Wrapper.Group#GROUP Grp
-- @return #string
function REDGCI_DISPATCHER:_GetCallsign(Grp)
    if not Grp then return "GCI" end
    local name = Grp:GetName() or "GCI"
    local after_hash = string.match(name, "#(%d+)")
    if after_hash then return after_hash end
    local cs = Grp:GetCustomCallSign(true, true)
    if cs and cs ~= "" then return cs end
    return string.match(name, "([^%-]+)$") or name
end

--- [INTERNAL] Check if group has a human pilot.
-- @param #REDGCI_DISPATCHER self
-- @param Wrapper.Group#GROUP Grp
-- @return #boolean
function REDGCI_DISPATCHER:_IsHuman(Grp)
    if not Grp then return false end
    if self.ClientSet then
        local found = false
        self.ClientSet:ForEachClient(function(client)
            if client and client:GetGroup() and
               client:GetGroup():GetName() == Grp:GetName() then
                found = true
            end
        end)
        if found then return true end
    end
    for _, unit in pairs(Grp:GetUnits() or {}) do
        if unit and unit:IsAlive() and unit:GetPlayerName() then return true end
    end
    return false
end

--- [INTERNAL] Initialize SRS.
-- @param #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:_InitSRS()
    self._msrs = MSRS:New(self.SRSPath, 121.5, self.SRSMod)
    self._msrs:SetPort(self.SRSPort)
    self._msrs:SetLabel("DISPATCH")
    self._msrs:SetCulture(self.SRSCulture)
    self._msrs:SetVoice(self.SRSVoice)
    self._msrs:SetCoalition(self.Coalition)
    if self.SRSProvider then self._msrs:SetProvider(self.SRSProvider) end
    self._srs_queue = MSRSQUEUE:New("REDGCI_DISPATCHER")
end

--- [INTERNAL] Spawn AI group and assign orbit.
-- Uses SPAWN:NewWithAlias() so group name contains callsign.
-- Template controls parking, hot/cold, heading.
-- OnSpawnGroup callback ensures group is alive before orbit assignment.
-- @param #REDGCI_DISPATCHER self
-- @param Core.Zone#ZONE Zone
-- @return Wrapper.Group#GROUP or nil
function REDGCI_DISPATCHER:_SpawnAI(Zone)
    local cs    = self:_NextCallsign()
    local alias = self.TemplateName .. "#" .. cs

    local spawner = SPAWN:NewWithAlias(self.TemplateName, alias)
    spawner:InitCallSignRed(cs)

    spawner:OnSpawnGroup(function(grp)
        self:I(self.lid .. "Gespawnt: " .. grp:GetName() ..
               " CS=" .. cs .. " -> orbit in " .. Zone:GetName())
        self:_RegisterFighter(grp, Zone, false)
        self:_AssignOrbit(grp, Zone)
    end)

    local grp = spawner:Spawn()
    return grp
end

--- [INTERNAL] Toggle radar emission on the fighter group.
-- @param #REDGCI self
-- @param #boolean On
-- @param #number Delay
function REDGCI_DISPATCHER:_SetRadar(Grp,On,Delay)
    --if not self.IsAIPlane then return end
    if Delay then
      self:ScheduleOnce(Delay,REDGCI_DISPATCHER._SetRadar,self,Grp,On)
      return
    end
    local grp = Grp
    if not grp then return end
    if On == true then
      grp:SetOptionRadarUsingForContinousSearch()
      grp:OptionECM_DetectedLockByRadar()
      grp:SetOptionJettisonEmptyTanks(true)
    else
      grp:SetOptionRadarUsingNever()
      grp:OptionECM_Never()
    end
    self:_Log("Radar " .. (On and "ON" or "OFF"))
end

--- [INTERNAL] Toggle weapons free on the fighter group.
-- @param #REDGCI self
-- @param #boolean On
-- @param #number Delay Delay in seconds
function REDGCI_DISPATCHER:_SetWeaponsFree(Grp,On,Delay)
    --if not self.IsAIPlane then return end
    if Delay then
      self:ScheduleOnce(Delay,REDGCI_DISPATCHER._SetWeaponsFree,self,Grp,On)
      return
    end
    local grp = Grp
    if not grp then return end
    if On == true then
      grp:OptionROEWeaponFree()
      grp:OptionAlarmStateRed()
      grp:OptionAAAttackRange(self._missilerangeflag)
      grp:OptionECM_DetectedLockByRadar()
      grp:SetOptionJettisonEmptyTanks(true)
    else
      grp:OptionROEHoldFire()
      grp:OptionAlarmStateAuto()
      grp:OptionAAAttackRange(3)
      grp:OptionECM_Never()
    end
    self:_Log("Weapons " .. (On and "ON" or "OFF"))
end

--- [INTERNAL] Assign orbit task in CAP zone.
-- WaypointAir expects speed in kph or km/h; TaskOrbit expects mps or m/s.
-- Altitude variation prevents all groups flying at exact same level.
-- @param #REDGCI_DISPATCHER self
-- @param Wrapper.Group#GROUP Grp
-- @param Core.Zone#ZONE Zone
function REDGCI_DISPATCHER:_AssignOrbit(Grp, Zone)
    if not Grp or not Grp:IsAlive() then return end
    
    
    if Grp:GetPlayerName() == nil then
      -- Ensure radar and weapons are cold in CAP
      self:_SetRadar(Grp, false, 1)
      self:_SetWeaponsFree(Grp, false, 1)
    end

    local center    = Zone:GetCoordinate()
    local variation = UTILS.Round((UTILS.LCGRandom() * 1000),-2)
    local alt       = self.OrbitAlt + variation
    local spd_mps   = UTILS.KmphToMps(self.OrbitSpeed)
    local spd_tas   = UTILS.IasToTas(self.OrbitSpeed, alt)

    self:I(self.lid .. "Orbit variation: " .. variation)

    -- TaskOrbit requires speed in m/s
    local task = Grp:TaskOrbit(center, alt, spd_mps)

    -- WaypointAir requires speed in km/h
    local wp0 = Grp:GetCoordinate():WaypointAir(
        COORDINATE.WaypointAltType.BARO,
        COORDINATE.WaypointType.TurningPoint,
        COORDINATE.WaypointAction.FlyoverPoint,
        self.OrbitSpeed, false, nil, {}, "TRANSIT")

    local wp2c = COORDINATE:New(center.x, alt, center.z)

    -- Intermediate waypoint for clean climb profile (km/h)
    local wp1 = Grp:GetCoordinate():GetIntermediateCoordinate(wp2c, 0.5)
        :SetAltitude(1000)
        :WaypointAir(
            COORDINATE.WaypointAltType.BARO,
            COORDINATE.WaypointType.TurningPoint,
            COORDINATE.WaypointAction.FlyoverPoint,
            spd_tas, true, nil, {}, "TRANSIT")

    -- Orbit waypoint (km/h TAS)
    local wp2 = wp2c:WaypointAir(
        COORDINATE.WaypointAltType.BARO,
        COORDINATE.WaypointType.TurningPoint,
        COORDINATE.WaypointAction.FlyoverPoint,
        spd_tas, true, nil, { task }, "CAP_ORBIT")

    Grp:Route({ wp0, wp1, wp2 }, 2)

    self:_Log(Grp:GetName() .. " -> orbit " .. Zone:GetName() ..
              string.format(" %.0fm %.0fkph TAS", alt, spd_tas))
end

--- [INTERNAL] Register fighter in pool.
-- @param #REDGCI_DISPATCHER self
-- @param Wrapper.Group#GROUP Grp
-- @param Core.Zone#ZONE Zone
-- @param #boolean IsHuman
function REDGCI_DISPATCHER:_RegisterFighter(Grp, Zone, IsHuman)
    local name = Grp:GetName()
    self._pool[name] = {
        groupName  = name,
        group      = Grp,
        zone       = Zone,
        isHuman    = IsHuman or false,
        state      = REDGCI_DISPATCHER.STATE_CAP,
        pairedWith = nil,
        engagement = nil,
        callsign   = self:_GetCallsign(Grp),
    }
    self:I(self.lid .. "Pool+: " .. name ..
           " CS=" .. self._pool[name].callsign ..
           (IsHuman and " [HUMAN]" or " [AI]"))
end

--- [INTERNAL] Refresh human pool from ClientSet.
-- @param #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:_RefreshHumanPool()
    if not self.ClientSet then return end

    self.ClientSet:ForEachClient(function(client)
        if not client then return end
        local grp = client:GetGroup()
        if not grp or not grp:IsAlive() then return end
        local name = grp:GetName()

        if self._pool[name] then
            self._pool[name].isHuman = true
            if self._pool[name].state ~= REDGCI_DISPATCHER.STATE_ENGAGED and
               self._pool[name].state ~= REDGCI_DISPATCHER.STATE_RTB then
                local in_zone = false
                if self.ZoneSet then
                    self.ZoneSet:ForEachZone(function(zone)
                        if grp:IsPartlyOrFullyInZone(zone) then
                            in_zone = true
                            self._pool[name].zone = zone
                        end
                    end)
                end
                self._pool[name].state = in_zone and
                    REDGCI_DISPATCHER.STATE_CAP or REDGCI_DISPATCHER.STATE_UNKNOWN
            end
            return
        end

        -- New human — find closest CAP zone within 50km
        local closest_zone, closest_dist = nil, math.huge
        if self.ZoneSet then
            self.ZoneSet:ForEachZone(function(zone)
                local d = grp:GetCoordinate():Get2DDistance(zone:GetCoordinate())
                if d < closest_dist then
                    closest_dist = d
                    closest_zone = zone
                end
            end)
        end

        if closest_zone and closest_dist < 50000 then
            self:_RegisterFighter(grp, closest_zone, true)
        end
    end)
end

--- [INTERNAL] Return available fighters sorted by priority.
-- Humans first, then by distance to cluster centroid.
-- Safe iteration — collects dead groups separately before removing.
-- @param #REDGCI_DISPATCHER self
-- @param #table Centroid  DCS coordinates {x, z}
-- @return #table
function REDGCI_DISPATCHER:_AvailableFighters(Centroid)
    local available = {}
    local to_remove = {}

    for _, entry in pairs(self._pool) do
        if entry.state == REDGCI_DISPATCHER.STATE_CAP then
            local grp = GROUP:FindByName(entry.groupName)
            if grp and grp:IsAlive() then
                if Centroid then
                    local c = grp:GetCoordinate()
                    entry._dist = c and c:Get2DDistance(Centroid) or math.huge
                else
                    entry._dist = math.huge
                end
                available[#available + 1] = entry
            else
                to_remove[#to_remove + 1] = entry.groupName
            end
        end
    end

    -- Safe removal after iteration
    for _, name in ipairs(to_remove) do
        self:_Log("Pool-: " .. name .. " dead (AvailableFighters)")
        self._pool[name] = nil
    end

    table.sort(available, function(a, b)
        if a.isHuman ~= b.isHuman then return a.isHuman end
        return (a._dist or math.huge) < (b._dist or math.huge)
    end)

    return available
end

--- [INTERNAL] Stable cluster key.
-- @param #REDGCI_DISPATCHER self
-- @param #table Cluster
-- @return #string
function REDGCI_DISPATCHER:_ClusterKey(Cluster)
    local c  = Cluster.coordinate or {}
    local cz = c.z or c.y or 0
    return string.format("C_%.0f_%.0f", (c.x or 0)/1000, cz/1000)
end

--- [INTERNAL] Count alive units in cluster.
-- @param #REDGCI_DISPATCHER self
-- @param #table Cluster
-- @return #number
function REDGCI_DISPATCHER:_ClusterSize(Cluster)
    local n = 0
    for _, contact in pairs(Cluster.Contacts or {}) do
        local grp = GROUP:FindByName(contact.groupname)
        if grp and grp:IsAlive() then n = n + grp:CountAliveUnits() end
    end
    return n
end

--- [INTERNAL] Derive localized count and type tokens for a cluster.
-- Reuses REDGCI CountTokens/TypeTokens tables.
-- @param #REDGCI_DISPATCHER self
-- @param #table Cluster
-- @return #string count_str, #string type_str, #number rng_km
function REDGCI_DISPATCHER:_ClusterPicture(Cluster)
    local size = self:_ClusterSize(Cluster)

    -- Count token (reuse REDGCI table if available)
    local count_str
    if REDGCI and REDGCI.CountTokens then
        local t = REDGCI.CountTokens[self.Locale] or REDGCI.CountTokens["en"]
        if     size == 1 then count_str = t.single
        elseif size == 2 then count_str = t.pair
        elseif size <= 4 then count_str = t.group
        else                  count_str = t.biggroup
        end
    else
        count_str = tostring(size)
    end

    -- Type token from RCS (reuse REDGCI table if available)
    local type_str = "FIGHTER"
    local rcs_sum, rcs_n = 0.0, 0
    for _, contact in pairs(Cluster.Contacts or {}) do
        if contact.rcs then
            rcs_sum = rcs_sum + contact.rcs
            rcs_n   = rcs_n + 1
        end
    end

    if REDGCI and REDGCI.TypeTokens and rcs_n > 0 then
        local t   = REDGCI.TypeTokens[self.Locale] or REDGCI.TypeTokens["en"]
        local avg = rcs_sum / rcs_n
        if     avg < (REDGCI.RCS_FIGHTER_MAX or 6.0)  then type_str = t.fighter
        elseif avg > (REDGCI.RCS_BOMBER_MIN  or 20.0) then type_str = t.bomber
        else                                                type_str = t.machines
        end
    end

    -- Range to centroid from nearest CAP fighter
    -- Range to centroid from nearest CAP fighter
    local rng_km = 0
    local centroid = Cluster.coordinate
    if centroid then
        local min_dist = math.huge
        for _, entry in pairs(self._pool) do
            local grp = GROUP:FindByName(entry.groupName)
            if grp and grp:IsAlive() then
                local c = grp:GetCoordinate()
                if c then
                    local d = c:Get2DDistance(centroid)
                    if d < min_dist then min_dist = d end
                end
            end
        end
        if min_dist < math.huge then
            rng_km = math.floor(min_dist / 1000 + 0.5)
        end
    end

    return count_str, type_str, rng_km
end

--- [INTERNAL] Get up to 2 target group names from cluster (closest to centroid).
-- @param #REDGCI_DISPATCHER self
-- @param #table Cluster
-- @return #string T1name, #string T2name
function REDGCI_DISPATCHER:_ClusterTargets(Cluster)
    local c  = Cluster.coordinate or { x=0, z=0, y=0 }
    local cz = c.z or c.y or 0
    local groups = {}
    for _, contact in pairs(Cluster.Contacts or {}) do
        local grp = GROUP:FindByName(contact.groupname)
        if grp and grp:IsAlive() then
            local coord = grp:GetCoordinate()
            local dx = (coord and coord.x or 0) - c.x
            local dz = (coord and coord.z or 0) - cz
            groups[#groups + 1] = { name=contact.groupname, dist=math.sqrt(dx*dx+dz*dz) }
        end
    end
    table.sort(groups, function(a, b) return a.dist < b.dist end)
    return groups[1] and groups[1].name or nil,
           groups[2] and groups[2].name or nil
end

--- [INTERNAL] Dispatch one pair against a cluster.
-- @param #REDGCI_DISPATCHER self
-- @param #table F1entry
-- @param #table F2entry  (may be nil for solo)
-- @param #table Cluster
-- @param #string ClusterKey
function REDGCI_DISPATCHER:_DispatchPair(F1entry, F2entry, Cluster, ClusterKey)
    local t1, t2 = self:_ClusterTargets(Cluster)
    if not t1 then
        self:_Log("Dispatch: keine Ziele in " .. ClusterKey)
        return
    end

    local f1  = F1entry.groupName
    local f2  = F2entry and F2entry.groupName or nil
    local cs1 = F1entry.callsign
    local cs2 = F2entry and F2entry.callsign or cs1

    self:I(self.lid .. string.format(
        "DISPATCH %s(%s)+%s(%s) -> %s/%s [%s]",
        f1, cs1, f2 or "-", cs2, t1, t2 or "-", ClusterKey))

    F1entry.state      = REDGCI_DISPATCHER.STATE_ENGAGED
    F1entry.pairedWith = f2
    F1entry.engagement = ClusterKey
    if F2entry then
        F2entry.state      = REDGCI_DISPATCHER.STATE_ENGAGED
        F2entry.pairedWith = f1
        F2entry.engagement = ClusterKey
    end

    local gci2v2 = REDGCI2v2:New(-- Functional.RedGCI2v2#REDGCI2v2
        f1, f2 or f1, t1, t2 or t1, cs1, cs2, self.Coalition)

    gci2v2:SetLocale(self.Locale)
    gci2v2:SetAIMode(true, self.HomeBaseName)
    gci2v2:SetSRS(self.SRSPath, self.SRSGCIFrequency, self.SRSMod,
                  self.SRSCulture, self.SRSGCIVoice, self.SRSPort, self.SRSSpeed)
    if self.SRSProvider then gci2v2:SetSRSProvider(self.SRSProvider) end
    gci2v2:SetAltOffset(self.AltOffset)
    gci2v2:SetWFRange(self.WFRange)
    gci2v2:SetDebug(self.Debug)
    gci2v2.Coalition = self.Coalition

    -- Stop-Hook: release fighters back to pool
    local dr   = self
    local orig = gci2v2.onafterStop
    gci2v2.onafterStop = function(s, F, E, T)
        if orig then orig(s, F, E, T) end
        dr:_OnEngagementEnd(ClusterKey, F1entry, F2entry)
    end

    gci2v2:Start()

    -- Dispatch-Meldung: Picture an Piloten.
    -- Tactic is not known yet at dispatch time (REDGCI2v2 picks it at COMMIT).
    -- We send Count/Type now; the tactic call comes from the GCI itself.
    local count_str, type_str, _ = self:_ClusterPicture(Cluster)
    local cs_text = cs1 .. (f2 and (", " .. cs2) or "")
    self:_Transmit("DISPATCH_CALL", {
        CALLSIGN = cs_text,
        COUNT    = count_str,
        TYPE     = type_str,
    }, f1)

    -- Picture call: cluster size
    local sz = self:_ClusterSize(Cluster)
    if gci2v2._gci1 then gci2v2._gci1._target_count = sz end
    if gci2v2._gci2 then gci2v2._gci2._target_count = sz end

    self._engagements[ClusterKey] = {
        gci2v2     = gci2v2,
        f1Name     = f1,
        f2Name     = f2,
        clusterKey = ClusterKey,
        startTime  = timer.getTime(),
    }
end

--- [INTERNAL] Called when engagement ends (REDGCI2v2 Stop fires).
-- AI → RTB waypoint then removed from pool.
-- Human → RTB radio call, re-enters pool after 5 min.
-- @param #REDGCI_DISPATCHER self
-- @param #string ClusterKey
-- @param #table F1entry
-- @param #table F2entry
function REDGCI_DISPATCHER:_OnEngagementEnd(ClusterKey, F1entry, F2entry)
    self:I(self.lid .. "Engagement end: " .. ClusterKey)
    self._engagements[ClusterKey] = nil

    local entries = F2entry and { F1entry, F2entry } or { F1entry }
    for _, entry in ipairs(entries) do
        entry.pairedWith = nil
        entry.engagement = nil

        if entry.isHuman then
            entry.state = REDGCI_DISPATCHER.STATE_RTB
            self:_Transmit("RTB_CALL",
                { CALLSIGN = entry.callsign or entry.groupName },
                entry.groupName)
            local name = entry.groupName
            self:ScheduleOnce(300, function()
                if self._pool[name] then
                    self._pool[name].state = REDGCI_DISPATCHER.STATE_UNKNOWN
                    self:I(self.lid .. name .. " [HUMAN] released")
                end
            end)
        else
            entry.state = REDGCI_DISPATCHER.STATE_RTB
            self:_RTBAircraft(entry.groupName)
            local name = entry.groupName
            self:ScheduleOnce(600, function()
                self._pool[name] = nil
                self:I(self.lid .. name .. " [AI] removed from pool")
            end)
            -- Respawn: spawn new AI into same zone after delay
            if self.RespawnEnabled and entry.zone then
                local zone = entry.zone
                self:ScheduleOnce(self.RespawnDelay, function()
                    self:I(self.lid .. "Respawn: " .. self.RespawnCount ..
                           "× AI → " .. zone:GetName())
                    for i = 1, self.RespawnCount do
                        self:_SpawnAI(zone)
                    end
                end)
            end
        end
    end
end

--- [INTERNAL] Push RTB waypoint for AI group.
-- WaypointAir expects speed in km/h.
-- @param #REDGCI_DISPATCHER self
-- @param #string GroupName
function REDGCI_DISPATCHER:_RTBAircraft(GroupName)
    if not self.HomeBase then return end
    local grp = GROUP:FindByName(GroupName)
    if not grp or not grp:IsAlive() then return end

    local spd_kmh = math.max(self.OrbitSpeed, 400)  -- km/h for WaypointAir
    local c0      = grp:GetCoordinate()
    local c1      = self.HomeBase:GetCoordinate()

    grp:Route({
        c0:WaypointAir(COORDINATE.WaypointAltType.BARO,
            COORDINATE.WaypointType.TurningPoint,
            COORDINATE.WaypointAction.FlyoverPoint,
            spd_kmh, true, nil, {}, "RTB"),
        c1:WaypointAir(COORDINATE.WaypointAltType.BARO,
            COORDINATE.WaypointType.Land,
            COORDINATE.WaypointAction.Landing,
            spd_kmh, true, self.HomeBase, {}, "LAND"),
    }, 3)

    self:I(self.lid .. GroupName .. " [AI] RTB -> " .. self.HomeBaseName)
end

-- ─────────────────────────────────────────────────────────────
--  FSM handlers
-- ─────────────────────────────────────────────────────────────

--- [INTERNAL] Start handler.
-- @param #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:onafterStart(From, Event, To)
    self:I(self.lid .. "Start v" .. REDGCI_DISPATCHER.version)

    if not self.Intel    then self:E(self.lid .. "ERROR: no INTEL set!")    return end
    if not self.ZoneSet  then self:E(self.lid .. "ERROR: no ZoneSet!")  return end
    if not self.HomeBase then self:E(self.lid .. "ERROR: no HomeBase set!") return end

    self:_InitSRS()
    self:_InitLocalization()

    self.ZoneSet:ForEachZone(function(zone)
        self:I(self.lid .. "Zone: " .. zone:GetName() ..
               " -> spawning " .. self.AiPerZone .. "x AI")
        for i = 1, self.AiPerZone do
            self:_SpawnAI(zone)
        end
    end)

    self:__Status(-REDGCI_DISPATCHER.TICK_INTERVAL)
end

--- [INTERNAL] Main dispatch tick.
-- @param #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:onafterStatus(From, Event, To)

    self:_RefreshHumanPool()

    -- Safe removal of dead AI: collect first, then delete
    local to_remove = {}
    for name, entry in pairs(self._pool) do
        if not entry.isHuman then
            local grp = GROUP:FindByName(name)
            if (not grp or not grp:IsAlive()) and
               entry.state ~= REDGCI_DISPATCHER.STATE_RTB then
                to_remove[#to_remove + 1] = name
            end
        end
    end
    for _, name in ipairs(to_remove) do
        self:_Log("Pool-: " .. name .. " dead")
        self._pool[name] = nil
    end

    local clusters = self.Intel:GetClusterTable()
    if not clusters then
        self:__Status(-REDGCI_DISPATCHER.TICK_INTERVAL)
        return
    end

    -- Clean up known clusters that have disappeared
    for key in pairs(self._known_clusters) do
        local still_alive = false
        for _, cluster in pairs(clusters) do
            if self:_ClusterKey(cluster) == key and
               self:_ClusterSize(cluster) > 0 then
                still_alive = true
                break
            end
        end
        if not still_alive then
            self._known_clusters[key] = nil
            self:_Log("Cluster " .. key .. " gone - removed from known_clusters")
        end
    end

    for _, cluster in pairs(clusters) do
        local key  = self:_ClusterKey(cluster)
        local size = self:_ClusterSize(cluster)

        if size > 0 then
            -- New cluster? -> send INTEL contact to all CAP fighters
            if not self._known_clusters[key] then
                self._known_clusters[key] = true
                local count_str, type_str, rng_km = self:_ClusterPicture(cluster)
                self:_TransmitToAllCAP("INTEL_CONTACT", {
                    COUNT = count_str,
                    TYPE  = type_str,
                    RNG   = rng_km,
                })
                self:I(self.lid .. "Neuer Cluster " .. key ..
                       " → INTEL_CONTACT gesendet")
            end
            local active = 0
            for ek in pairs(self._engagements) do
                if string.find(ek, key, 1, true) then active = active + 1 end
            end

            local needed  = math.ceil(size / REDGCI_DISPATCHER.UNITS_PER_PAIR)
            local to_send = math.max(0, needed - active)

            if to_send > 0 then
                local centroid  = cluster.coordinate
                local available = self:_AvailableFighters(centroid)

                self:I(self.lid .. string.format(
                    "Cluster %s size=%d need=%d pairs avail=%d fighter",
                    key, size, needed, #available))

                if #available > 0 then
                    local idx, dispatched = 1, 0
                    while dispatched < to_send and idx + 1 <= #available do
                        self:_DispatchPair(
                            available[idx], available[idx+1],
                            cluster, key .. "_P" .. (active + dispatched + 1))
                        idx        = idx + 2
                        dispatched = dispatched + 1
                    end

                    if dispatched == 0 and #available >= 1 and size <= 1 then
                        self:_DispatchPair(available[1], nil, cluster,
                            key .. "_P" .. (active + 1))
                    end
                end
            end
        end
    end

    self:__Status(-REDGCI_DISPATCHER.TICK_INTERVAL)
end

--- [INTERNAL] Stop handler.
-- @param #REDGCI_DISPATCHER self
function REDGCI_DISPATCHER:onafterStop(From, Event, To)
    self:I(self.lid .. "Stopped.")
end

-------------------------------------------------------------------------------
-- END of Class
-------------------------------------------------------------------------------