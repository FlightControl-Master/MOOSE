--- **Functional** - Enhanced Warsaw Pact GCI Controller.
--
-- ## Main Features:
--
--    * Guide AI and human pilots in Warsaw Pact Style. GCI Kernel Functions.
--    * Advanced Tactics for Groups.
--    * Many additional events that the mission designer can hook into.
--
-- ===
--
-- ### Author: **Applevangelist**
--
-- ===
-- @module Functional.REDGCI_KERNEL
-- @image Func_RedGCI.png
-- @version 1.0.0


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- REDGCI_KERNEL class
-- @type REDGCI_KERNEL


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
-- @field REDGCI_KERNEL
REDGCI_KERNEL = {}
REDGCI_KERNEL.version = "1.0.0"

-- ─────────────────────────────────────────────────────────────
--  Konstanten (aus gci_types.h)
-- ─────────────────────────────────────────────────────────────

REDGCI_KERNEL.C = {
    RANGE_VECTOR_START  = 60000.0,
    RANGE_COMMIT        = 30000.0,
    RANGE_RADAR_FLOOR   = 20000.0,
    RANGE_VISUAL        =  5000.0,
    RANGE_MERGE         =  2000.0,
    WF_RANGE_MAX        = 25000.0,
    ALT_OFFSET_LOOKDOWN =    0.0,
    ASPECT_NOTCH_MIN    =   80.0,
    ASPECT_NOTCH_MAX    =  100.0,
    ASPECT_REAR_ATTACK  =  120.0,
    MAX_TTI             =  600.0,
    TICK_INTERVAL       =   15.0,
    FUEL_BINGO          =    0.25,
    DELAY_MIN           =    3.0,
    DELAY_MAX           =    8.0,
    DELAY_MERGE_MIN     =    2.0,
    DELAY_MERGE_MAX     =    4.0,
    TACTIC_PINCER       = 0,
    TACTIC_HIGH_LOW     = 1,
    TACTIC_STAGGER      = 2,
    TACTIC_TRAIL        = 3,
    TACTIC_GIRAFFE      = 4,  -- Irak/Iran-Doktrin: F1=Decoy normal, F2=Nap-of-Earth im Groundclutter
    PURSUIT_COLLISION   = 0,
    PURSUIT_LEAD        = 1,
    PURSUIT_PURE        = 2,
    PURSUIT_NO_SOLUTION = 3,
}

-- ─────────────────────────────────────────────────────────────
--  Hilfsfunktionen
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function REDGCI_KERNEL.vec2len(x, z)
    return math.sqrt(x*x + z*z)
end

function REDGCI_KERNEL.bearing(dx, dz)
    local b = math.deg(math.atan2(dx, dz))
    return b < 0.0 and b + 360.0 or b
end

function REDGCI_KERNEL.randDelay(lo, hi)
    return lo + UTILS.LCGRandom() * (hi - lo)
end

-- ─────────────────────────────────────────────────────────────
--  Aspect Angle  (0=Nose-on, 90=Beam, 180=Tail)
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.aspectAngle(target, observer)
    local dx    = observer.x - target.x
    local dz    = observer.z - target.z
    local range = REDGCI_KERNEL.vec2len(dx, dz)
    if range < 1.0 then return 0.0 end
    local nx  = dx / range
    local nz  = dz / range
    local spd = (target.speed or 1.0) + 1e-6
    local tvx = (target.vx or 0.0) / spd
    local tvz = (target.vz or 0.0) / spd
    local dot = REDGCI_KERNEL.clamp(tvx*nx + tvz*nz, -1.0, 1.0)
    return math.deg(math.acos(dot))
end

-- ─────────────────────────────────────────────────────────────
--  Closure Rate  (positiv = Annäherung)
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.closureRate(f, t)
    local dx    = t.x - f.x
    local dz    = t.z - f.z
    local range = REDGCI_KERNEL.vec2len(dx, dz)
    if range < 1.0 then return 0.0 end
    local nx  = dx / range
    local nz  = dz / range
    local dvx = (t.vx or 0.0) - (f.vx or 0.0)
    local dvz = (t.vz or 0.0) - (f.vz or 0.0)
    return -(dvx*nx + dvz*nz)
end

-- ─────────────────────────────────────────────────────────────
--  _solveCollision (intern, GCI-Koordinaten)
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL._solveCollision(f, t)
    local C   = REDGCI_KERNEL.C
    local dx  = t.x - f.x
    local dz  = t.z - f.z
    local vtx = t.vx or 0.0
    local vtz = t.vz or 0.0
    local vf  = f.speed or 1.0
    local a   = vtx*vtx + vtz*vtz - vf*vf
    local b   = 2.0 * (dx*vtx + dz*vtz)
    local c   = dx*dx + dz*dz
    local sol_t = -1.0
    if math.abs(a) < 1.0 then
        if math.abs(b) > 0.01 then
            sol_t = -c / b
        else
            return false
        end
    else
        local disc = b*b - 4.0*a*c
        if disc < 0.0 then return false end
        local sq = math.sqrt(disc)
        local t1 = (-b - sq) / (2.0 * a)
        local t2 = (-b + sq) / (2.0 * a)
        if     t1 > 0.0 and t2 > 0.0 then sol_t = math.min(t1, t2)
        elseif t1 > 0.0               then sol_t = t1
        elseif t2 > 0.0               then sol_t = t2
        else return false
        end
    end
    if sol_t < 0.0 or sol_t > C.MAX_TTI then return false end
    local ip = {
        x = t.x + vtx * sol_t,
        z = t.z + vtz * sol_t,
        y = math.max(t.y + C.ALT_OFFSET_LOOKDOWN, 300.0),
    }
    local hdg = REDGCI_KERNEL.bearing(ip.x - f.x, ip.z - f.z)
    return true, hdg, sol_t, ip
end

-- ─────────────────────────────────────────────────────────────
--  _solveLead (intern, GCI-Koordinaten)
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL._solveLead(f, t)
    local C     = REDGCI_KERNEL.C
    local dx    = t.x - f.x
    local dz    = t.z - f.z
    local range = REDGCI_KERNEL.vec2len(dx, dz)
    if range < 1.0 then return 0.0, 0.0 end
    local base_bearing = REDGCI_KERNEL.bearing(dx, dz)
    local aspect_rad   = math.rad(REDGCI_KERNEL.aspectAngle(t, f))
    local speed_ratio  = (t.speed or 1.0) / ((f.speed or 1.0) + 1e-6)
    local sin_lead     = REDGCI_KERNEL.clamp(speed_ratio * math.sin(aspect_rad), -1.0, 1.0)
    local lead_deg     = math.deg(math.asin(sin_lead))
    local hdg
    if math.abs(lead_deg) < 45.0 then
        hdg = (base_bearing + lead_deg + 360.0) % 360.0
    else
        hdg = base_bearing
    end
    local closing = REDGCI_KERNEL.closureRate(f, t)
    if closing < 50.0 then closing = 50.0 end
    local tti = math.min(range / closing, C.MAX_TTI)
    return hdg, tti
end

-- ─────────────────────────────────────────────────────────────
--  computeIntercept (GCI-Koordinaten intern)
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.computeIntercept(fighter, target)
    local C  = REDGCI_KERNEL.C
    local dx = target.x - fighter.x
    local dz = target.z - fighter.z
    local sol = {
        heading_deg        = 0.0,
        time_to_intercept  = C.MAX_TTI,
        intercept_point    = { x=target.x, z=target.z, y=target.y },
        target_alt         = target.y,
        solution_found     = false,
        aspect_angle       = REDGCI_KERNEL.aspectAngle(target, fighter),
        range              = REDGCI_KERNEL.vec2len(dx, dz),
        mode               = C.PURSUIT_NO_SOLUTION,
        weapons_free       = false,
    }
    local closure         = REDGCI_KERNEL.closureRate(fighter, target)
    local projected_range = sol.range - closure * C.TICK_INTERVAL
    sol.weapons_free = (sol.range < C.WF_RANGE_MAX) or
                       (closure > 0.0 and projected_range < C.WF_RANGE_MAX)
    local ok, hdg, tti, ip = REDGCI_KERNEL._solveCollision(fighter, target)
    if ok then
        sol.heading_deg       = hdg
        sol.time_to_intercept = tti
        sol.intercept_point   = ip
        sol.solution_found    = true
        sol.mode              = C.PURSUIT_COLLISION
        return sol
    end
    local lhdg, ltti = REDGCI_KERNEL._solveLead(fighter, target)
    sol.heading_deg       = lhdg
    sol.time_to_intercept = ltti
    sol.solution_found    = true
    sol.mode              = C.PURSUIT_LEAD
    sol.intercept_point   = {
        x = target.x + (target.vx or 0.0) * ltti,
        z = target.z + (target.vz or 0.0) * ltti,
        y = math.max(target.y + C.ALT_OFFSET_LOOKDOWN, 300.0),
    }
    return sol
end

-- ─────────────────────────────────────────────────────────────
--  computeInterceptDCS  (DCS-Koordinaten Ein/Aus)
--  Flat-Rückgabe kompatibel mit alter C-API
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.computeInterceptDCS(f, t)
    local f_gci = { x=f.z, z=f.x, y=f.y, vx=f.vz, vz=f.vx, vy=f.vy, speed=f.spd }
    local t_gci = { x=t.z, z=t.x, y=t.y, vx=t.vz, vz=t.vx, vy=t.vy, speed=t.spd }
    local sol   = REDGCI_KERNEL.computeIntercept(f_gci, t_gci)
    -- GCI→DCS: ip.z(Nord)→DCS.x, ip.x(Ost)→DCS.z
    return sol.heading_deg,
           sol.time_to_intercept,
           sol.mode,
           sol.weapons_free,
           sol.range,
           sol.aspect_angle,
           sol.intercept_point.z,
           sol.intercept_point.x,
           sol.intercept_point.y,
           sol.target_alt
end

-- ─────────────────────────────────────────────────────────────
--  computeSplit (GCI-Koordinaten intern)
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.computeSplit(f1, f2, tgt, tactic, variation)
    local C   = REDGCI_KERNEL.C
    variation = REDGCI_KERNEL.clamp(variation or 0.5, 0.0, 1.0)
    tactic    = tactic or C.TACTIC_PINCER
    local mid_x = (f1.x + f2.x) * 0.5
    local mid_z = (f1.z + f2.z) * 0.5
    local dx  = tgt.x - mid_x
    local dz  = tgt.z - mid_z
    local rng = REDGCI_KERNEL.vec2len(dx, dz)
    if rng < 1.0 then rng = 1.0 end
    local ax = dx / rng
    local az = dz / rng
    local px = -az
    local pz =  ax

    local plan = {
        tactic   = tactic,
        wp_f1    = { x=0, z=0, y=0 },
        wp_f2    = { x=0, z=0, y=0 },
        merge_f1 = { x=0, z=0, y=0 },
        merge_f2 = { x=0, z=0, y=0 },
    }

    local function clamp_alt(pt)
        if pt.y < 300.0 then pt.y = 300.0 end
    end
    
    local function clamp_alt_noe(pt)
      if pt.y < 150.0 then pt.y = 150.0 end
    end
    
    -- GIRAFFE F2 fliegt NOE — separater clamp mit niedrigerer Mindesthöhe
    local function clamp_alt_noe(pt)
        if pt.y < 150.0 then pt.y = 150.0 end
    end

    if tactic == C.TACTIC_PINCER then
        local spread    = 12000.0 + variation * 5000.0
        local approach  = rng * 0.45
        local merge_off = spread * 0.30
        plan.wp_f1    = { x=mid_x+ax*approach+px*spread,  z=mid_z+az*approach+pz*spread,  y=tgt.y }
        plan.wp_f2    = { x=mid_x+ax*approach-px*spread,  z=mid_z+az*approach-pz*spread,  y=tgt.y }
        plan.merge_f1 = { x=tgt.x-ax*3000+px*merge_off,   z=tgt.z-az*3000+pz*merge_off,   y=tgt.y }
        plan.merge_f2 = { x=tgt.x-ax*3000-px*merge_off,   z=tgt.z-az*3000-pz*merge_off,   y=tgt.y }

    elseif tactic == C.TACTIC_HIGH_LOW then
        local vert     = 3000.0 + variation * 1500.0
        local approach = rng * 0.50
        local side_off = 2000.0
        plan.wp_f1    = { x=mid_x+ax*approach+px*side_off, z=mid_z+az*approach+pz*side_off, y=tgt.y-500.0 }
        plan.wp_f2    = { x=mid_x+ax*approach-px*side_off, z=mid_z+az*approach-pz*side_off, y=tgt.y+vert  }
        plan.merge_f1 = { x=tgt.x-ax*3000+px*side_off,     z=tgt.z-az*3000+pz*side_off,     y=plan.wp_f1.y }
        plan.merge_f2 = { x=tgt.x-ax*3000-px*side_off,     z=tgt.z-az*3000-pz*side_off,     y=plan.wp_f2.y }

    elseif tactic == C.TACTIC_STAGGER then
        local lag       = 8000.0 + variation * 3000.0
        local lead_dist = rng * 0.85
        plan.wp_f1    = { x=mid_x+ax*lead_dist,            z=mid_z+az*lead_dist,            y=tgt.y }
        plan.wp_f2    = { x=mid_x+ax*(lead_dist-lag),      z=mid_z+az*(lead_dist-lag),      y=tgt.y }
        plan.merge_f1 = { x=plan.wp_f1.x, z=plan.wp_f1.z, y=plan.wp_f1.y }
        plan.merge_f2 = { x=plan.wp_f2.x, z=plan.wp_f2.z, y=plan.wp_f2.y }

    elseif tactic == C.TACTIC_TRAIL then
        local lag       = 3000.0 + variation * 2000.0
        local lead_dist = rng * 0.85
        local side_off  = 500.0
        plan.wp_f1    = { x=mid_x+ax*lead_dist,                    z=mid_z+az*lead_dist,                    y=tgt.y }
        plan.wp_f2    = { x=mid_x+ax*(lead_dist-lag)+px*side_off,  z=mid_z+az*(lead_dist-lag)+pz*side_off,  y=tgt.y }
        plan.merge_f1 = { x=plan.wp_f1.x, z=plan.wp_f1.z, y=plan.wp_f1.y }
        plan.merge_f2 = { x=plan.wp_f2.x, z=plan.wp_f2.z, y=plan.wp_f2.y }
    
        elseif tactic == C.TACTIC_GIRAFFE then
        -- ── GIRAFFE: Irak/Iran-Doktrin (Mirage F1 vs F-14A) ──────────────
        --
        --  F1 = Decoy:  normale Höhe, direkter Anflug, bindet AWG-9 Radar.
        --               Zieht Phoenixe auf sich — gibt F2 Zeit für Pull-up.
        --
        --  F2 = Killer: Nap-of-Earth (~300-600m AGL/MSL) weit seitlich versetzt.
        --               Nutzt Groundclutter um AWG-9 Look-Down zu degradieren.
        --               Nähert sich bis 10km vor Ziel, dann Pull-up und Schuss.
        --               Seitlicher Versatz ~8-12km damit F2 nicht im Radarsektor
        --               des AWG-9 liegt während F1 den Lock hält.
        --
        --  Historisch: Iran-Irak Krieg 1982-88. Irakische Mirage F1EQ nutzten
        --  dieses Profil gegen F-14A/AIM-54 Phoenix — der AWG-9 hatte trotz
        --  Look-Down-Fähigkeit bei sehr tiefen Zielen über unebenen Terrain
        --  (Zagros-Berge, Khuzestan-Ebene) erhöhte Clutter-Probleme.
        --
        --  Höhen: neutral (0.0) — Lua addiert AltOffset + terrain-awareness.
        --  Mindesthöhe 300m MSL wird am Ende geclampt.
 
        local noe_alt   = 300.0 + variation * 300.0    -- 300-600m MSL (Nap-of-Earth)
        local side_off  = 8000.0 + variation * 4000.0  -- 8-12km seitlich (aus AWG-9 Sektor)
        local approach  = rng * 0.60                    -- F1 direkter Anflug, 60% des Weges
        local noe_dist  = rng * 0.75                    -- F2 nähert sich weiter ran vor Pull-up
     
        plan.wp_f1    = { x=mid_x+ax*approach+px*2000, z=mid_z+az*approach+pz*2000, y=tgt.y }
        plan.merge_f1 = { x=tgt.x-ax*5000+px*2000,     z=tgt.z-az*5000+pz*2000,     y=tgt.y }
        plan.wp_f2    = { x=mid_x+ax*noe_dist-px*side_off, z=mid_z+az*noe_dist-pz*side_off, y=noe_alt, absolute_alt=true }
        plan.merge_f2 = { x=tgt.x-ax*10000-px*side_off*0.3, z=tgt.z-az*10000-pz*side_off*0.3, y=tgt.y }
    
    else
        plan.wp_f1    = { x=tgt.x, z=tgt.z, y=tgt.y }
        plan.wp_f2    = { x=tgt.x, z=tgt.z, y=tgt.y }
        plan.merge_f1 = { x=tgt.x, z=tgt.z, y=tgt.y }
        plan.merge_f2 = { x=tgt.x, z=tgt.z, y=tgt.y }
    end

    clamp_alt(plan.wp_f1)
    if tactic == C.TACTIC_GIRAFFE then
        clamp_alt_noe(plan.wp_f2)
    else
        clamp_alt(plan.wp_f2)
    end
    clamp_alt(plan.merge_f1)
    clamp_alt(plan.merge_f2)
    return plan
end

-- ─────────────────────────────────────────────────────────────
--  computeSplitDCS  (DCS-Koordinaten Ein/Aus)
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.computeSplitDCS(f1, f2, tgt, tactic, variation)
    local function dcs2gci(u)
        return { x=u.z, z=u.x, y=u.y, vx=u.vz or 0, vz=u.vx or 0, speed=u.spd or 0 }
    end
    local function gci2dcs(pt)
        return { x=pt.z, z=pt.x, y=pt.y, absolute_alt=pt.absolute_alt }
    end
    local tgt_gci = { x=tgt.z, z=tgt.x, y=tgt.y }
    local plan    = REDGCI_KERNEL.computeSplit(
        dcs2gci(f1), dcs2gci(f2), tgt_gci, tactic, variation)
    plan.wp_f1    = gci2dcs(plan.wp_f1)
    plan.wp_f2    = gci2dcs(plan.wp_f2)
    plan.merge_f1 = gci2dcs(plan.merge_f1)
    plan.merge_f2 = gci2dcs(plan.merge_f2)
    return plan
end

-- ─────────────────────────────────────────────────────────────
--  buildTransmission  (Port von gci_build_transmission)
--
--  ctx/prev Felder: state, prev_state, ticks_in_state, range,
--    aspect_angle, closure_rate, altitude_delta, fuel_fraction
--  sol Felder: heading_deg, time_to_intercept, target_alt,
--    range, aspect_angle, weapons_free
--  Rückgabe: { token_str, delay_sec, weapons_free, silence }
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.buildTransmission(ctx, prev, sol)
    local C  = REDGCI_KERNEL.C
    local tx = {
        token_str    = "",
        delay_sec    = REDGCI_KERNEL.clamp(
            REDGCI_KERNEL.randDelay(C.DELAY_MIN, C.DELAY_MAX), 3.0, 8.0),
        weapons_free = sol.weapons_free,
        silence      = false,
        priority     = 50,
    }

    local hdg_i    = math.floor((sol.heading_deg   or 0) + 0.5)
    local alt_i    = math.floor((sol.target_alt    or 0) / 100.0 + 0.5) * 100
    local rng_km   = math.floor((ctx.range         or 0) / 1000.0 + 0.5)
    local aspect_i = math.floor((ctx.aspect_angle  or 0) + 0.5)
    local delay    = tx.delay_sec
    local state      = ctx.state          or "VECTOR"
    local prev_state = prev.state         or "VECTOR"
    local ticks      = ctx.ticks_in_state or 0

    local function emit(fmt, ...)
        tx.token_str = string.format(fmt, ...)
    end

    if state == "VECTOR" then
        if prev_state ~= "VECTOR" then
            local tti_m = math.floor((sol.time_to_intercept or 0) / 60.0)
            local tti_s = math.floor(sol.time_to_intercept or 0) % 60
            if tti_m > 0 then
                emit("VECTOR_WITH_TTI|hdg=%d|alt=%d|rng=%d|tti_m=%d|tti_s=%d|delay=%.1f",
                    hdg_i, alt_i, rng_km, tti_m, tti_s, delay)
            else
                emit("VECTOR|hdg=%d|alt=%d|rng=%d|delay=%.1f",
                    hdg_i, alt_i, rng_km, delay)
            end
        else
            local hdg_delta = math.abs((sol.heading_deg or 0) - (ctx.aspect_angle or 0))
            if hdg_delta < 5.0 and ticks > 3 then
                tx.silence = true
            else
                emit("VECTOR|hdg=%d|alt=%d|rng=%d|delay=%.1f",
                    hdg_i, alt_i, rng_km, delay)
            end
        end

    elseif state == "COMMIT" then
        if prev_state ~= "COMMIT" then
            tx.priority = 100
            emit("COMMIT_FIRST|hdg=%d|alt=%d|rng=%d|aspect=%d|delay=%.1f",
                hdg_i, alt_i, rng_km, aspect_i, delay)
        elseif ticks == 6 then
            emit("COMMIT_NO_LOCK|hdg=%d|rng=%d|aspect=%d|delay=%.1f",
                hdg_i, rng_km, aspect_i, delay)
        elseif ticks > 8 then
            emit("COMMIT_NUDGE|hdg=%d|aspect=%d|delay=%.1f",
                hdg_i, aspect_i, delay)
        else
            tx.silence = true
        end

    elseif state == "RADAR_CONTACT" then
        if prev_state ~= "RADAR_CONTACT" then
            if sol.weapons_free then
                tx.priority = 100
                emit("RADAR_LOCK_WF|rng=%d|delay=%.1f", rng_km, delay)
                tx.weapons_free = true
            else
                emit("RADAR_LOCK_HOLD|rng=%d|delay=%.1f", rng_km, delay)
            end
        elseif not sol.weapons_free
            and (ctx.range or 0)        < C.WF_RANGE_MAX
            and (ctx.aspect_angle or 0) > C.ASPECT_REAR_ATTACK
            and prev_state              == "RADAR_CONTACT" then
            emit("RADAR_WF_NOW|rng=%d|delay=%.1f", rng_km, delay)
            tx.priority = 100
            tx.weapons_free = true
        else
            tx.silence = true
        end

    elseif state == "VISUAL" then
        if prev_state ~= "VISUAL" then
            emit("VISUAL_CONFIRM|rng=%d|delay=%.1f", rng_km, delay)
            tx.weapons_free = true
        else
            tx.silence = true
        end

    elseif state == "NOTCH" then
        if prev_state ~= "NOTCH" then
            emit("NOTCH_ENTRY|delay=1.5")
        elseif ticks % 8 == 0 then
            emit("NOTCH_UPDATE|rng=%d|aspect=%d|delay=%.1f",
                rng_km, aspect_i, delay)
        else
            tx.silence = true
        end

    elseif state == "ABORT" then
        tx.delay_sec = 1.5
        if (ctx.fuel_fraction or 1.0) < C.FUEL_BINGO then
            emit("ABORT_BINGO|hdg=%d|delay=1.5", hdg_i)
        else
            emit("ABORT_THREAT|hdg=%d|delay=1.5", hdg_i)
        end

    else
        tx.silence = true
    end

    return tx
end

-- ─────────────────────────────────────────────────────────────
--  mergeTransition  (Port von gci_merge_transition)
--
--  ctx Felder: phase, ticks_in_phase, range, bearing_to_target,
--    closure_rate, altitude_delta, pass_count, radar_lost
--  Rückgabe: phase string
--    "ENTRY"|"OVERSHOOT"|"SEPARATION"|"REATTACK"|"LOST"|"SPLASH"
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.mergeTransition(ctx, prev)
    if ctx.radar_lost then return "LOST" end
    if (ctx.closure_rate or 0) < -30.0 and (ctx.range or 0) > 3000.0 then
        return "SEPARATION"
    end
    local brg = ctx.bearing_to_target or 0
    if brg > 100.0 and brg < 260.0 and (ctx.range or 0) < 5000.0 then
        return "OVERSHOOT"
    end
    if ctx.phase == "SEPARATION" and (ctx.pass_count or 0) < 3 then
        return "REATTACK"
    end
    return ctx.phase
end

-- ─────────────────────────────────────────────────────────────
--  buildMergeTransmission  (Port von gci_build_merge_transmission)
-- ─────────────────────────────────────────────────────────────

function REDGCI_KERNEL.buildMergeTransmission(ctx, prev)
    local C  = REDGCI_KERNEL.C
    local tx = {
        token_str    = "",
        delay_sec    = REDGCI_KERNEL.clamp(
            REDGCI_KERNEL.randDelay(C.DELAY_MERGE_MIN, C.DELAY_MERGE_MAX), 2.0, 5.0),
        weapons_free = false,
        silence      = false,
        priority     = 50,
    }

    local brg        = math.floor((ctx.bearing_to_target or 0) + 0.5)
    local rng_km     = math.floor((ctx.range or 0) / 1000.0 + 0.5)
    local delay      = tx.delay_sec
    local phase      = ctx.phase          or "ENTRY"
    local prev_phase = prev.phase         or "ENTRY"
    local ticks      = ctx.ticks_in_phase or 0

    local dir_rl  = ((ctx.bearing_to_target or 0) < 180.0) and "right" or "left"
    local alt_d   = ctx.altitude_delta or 0
    local alt_rel = ""
    if     alt_d >  400.0 then alt_rel = "low"
    elseif alt_d < -400.0 then alt_rel = "high"
    end

    local function emit(fmt, ...)
        tx.token_str = string.format(fmt, ...)
    end

    if phase == "ENTRY" then
        tx.priority = 100
        emit("MERGE_ENTRY|brg=%d|dir_rl=%s|delay=%.1f", brg, dir_rl, delay)

    elseif phase == "OVERSHOOT" then
        emit("MERGE_OVERSHOOT|brg=%d|dir_rl=%s|alt_rel=%s|delay=%.1f",
            brg, dir_rl, alt_rel, delay)

    elseif phase == "SEPARATION" then
        if (ctx.pass_count or 0) < 3 then
            emit("MERGE_REATTACK|brg=%d|rng=%d|delay=%.1f", brg, rng_km, delay)
        else
            emit("ABORT_THREAT|hdg=%d|delay=%.1f", brg, delay)
        end

    elseif phase == "REATTACK" then
        if prev_phase ~= "REATTACK" or ticks % 3 == 0 then
            emit("MERGE_REATTACK|brg=%d|rng=%d|delay=%.1f", brg, rng_km, delay)
        else
            tx.silence = true
        end

    elseif phase == "LOST" then
        if prev_phase ~= "LOST" or ticks == 4 then
            emit("MERGE_LOST|brg=%d|rng=%d|delay=%.1f", brg, rng_km, delay)
        else
            tx.silence = true
        end

    elseif phase == "SPLASH" then
        tx.delay_sec = 1.5
        tx.priority = 100
        emit("MERGE_SPLASH|delay=1.5")

    else
        tx.silence = true
    end

    return tx
end

-------------------------------------------------------------------------------
-- END of Class
-------------------------------------------------------------------------------
