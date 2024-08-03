--- **Functional** - Improve the autonomous behaviour of ground AI.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Mechanized Infantry Tactics
--   * Move and attack
--   * etc
--
-- ===
-- 
-- ## Missions:
--
-- ## [MOOSE - ALL Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS)
-- 
-- === 
-- 
-- Short description
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg)
-- 
-- ===
-- 
-- ### Author: **Statua**
-- 
-- ### Contributions: FlightControl
-- 
-- ===
-- 
-- @module Functional.Tactics
-- @image Tactics.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- TACTICS class
-- @type TACTICS
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Write Debug messages to DCS log file and send Debug messages to all players.
-- @field #string lid String for DCS log file.
-- @extends Core.Fsm#FSM
-- 

--- Improve the autonomous behaviour of ground AI.
-- 
-- ## Title
-- 
-- Body
-- 
-- ### Subtitle
-- 
-- Sub body
--  
-- ![Process](..\Presentations\TACTICS\image.png)
-- 
-- Talking about this function/method @{#TACTICS.OnAfterTroopsDropped}()
-- 
-- # Examples
-- 
-- ## Mechanized Infantry
-- This example shows how to set up a basic mechanized infantry group which will respond to enemy contact by dispersing, deploying troops, and using the troops to fight back.
-- 
-- ![Process](..\Presentations\TACTICS\Tactics_Example_01.png)
-- 
-- 
-- # Customization and Fine Tuning
-- The following user functions can be used to change the default values
-- 
-- * @{#TACTICS.DefaultTroopAttackDist}() can be used to set the default maximum distance troops will move to attack a target after disembarking
-- 
-- 
-- @field #TACTICS
TACTICS = {}
TACTICS_UTILS = {}
TACTICS.ClassName = "TACTICS"
TACTICS.Debug = false
TACTICS.lid = nil
TACTICS_UTILS.GroupsRed = {}
TACTICS_UTILS.GroupsBlue = {}
TACTICS_UTILS.SetGroups = nil
TACTICS_UTILS.SetActive = false
  
--- TACTICS version.
-- @field #number version
TACTICS.version="0.1.0"

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--TODO list
--Check timer cutoffs in deadResponse
--Check nil for dead groups in all timers
--Check stuck in movement loop timers

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[Event Callbacks]]
--UnitLost(EventData)
--GroupDead(EventData)

--StartTravel(StartPoint, EndPoint)
--Redirect(CurrentPoint, EndPoint)
--EndTravel(ActualPoint, Endpoint)

--StartEngaging(WasHit, UnitName, WeaponName, EventData)
--EngageToIdle
--EngageToTravel
--EngageToRearming
--EngageToWinchester

--IsWinchester
--StartRearming
--RearmedToIdle
--RearmedToTravel

--StartAttacking
--AttackToIdle
--AttackToTravel

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new object to handle Tactics for a given Wrapper.Group#GROUP object.
-- @param #TACTICS self
-- @param Wrapper.Group#GROUP group The GROUP object for which tactics should be applied.
-- @return #TACTICS self
function TACTICS:New(group)

    ----------[INITIALIZATION]----------
    TACTICS_UTILS.SetGroups = SET_GROUP:new()
    --Start Set
    if not TACTICS_UTILS.SetActive then
        TACTICS_UTILS.SetActive = true
        TACTICS_UTILS.SetGroups:FilterStart()
    end

    --Inherit from MOOSE
    local self=BASE:Inherit(self, FSM:New()) -- #TACTICS


    --Validate Wrapper.GROUP
    if group:GetCoordinate() ~=nil then
        self.lid=string.format("TACTICS %s | ", tostring(group:GetName()))
        self:T("TACTICS version "..TACTICS.version..": Starting tactics handler for "..group:GetName())
    else
        self:E("TACTICS: Requested group does not exist! (Has to be a MOOSE group that is also alive)")
        return nil
    end


    --Warn on non-ground group
    if group:IsGround() == false then
        self:E("TACTICS: WARNING! "..group:GetName().." is not a ground group. Tactics are designed for ground units only and may result in errors or strange behaviour with this group.")
    end


    --Establish FSM Capabilities
    self:SetStartState( "Stopped" )
    self:AddTransition( "Stopped", "Start", "Idle" )
    self:AddTransition( "*", "Stop", "Stopped" )
    self:AddTransition( "*", "GroupDead", "Dead" )
    self:AddTransition( "*", "UnitLost", "*" )
    self:AddTransition( "*", "Winchester", "*" )
    self:AddTransition( "*", "FullyRearmed", "*" )
    self:AddTransition( "*", "TargetSpotted", "*" )
    self:AddTransition( "*", "AttackManeuver", "*" )
    self:AddTransition( "*", "TroopsDropped", "*" )
    self:AddTransition( "*", "TroopsReturned", "*" )
    self:AddTransition( "*", "TroopsExtracted", "*" )
    self:AddTransition ("*", "SupportRequested", "*")
    self:AddTransition ("*", "Supporting", "*")
    self:AddTransition ("*", "Abandoned", "*")
    self:AddTransition ("*", "CrewRecovered", "*")



    -- (Travel)
    self:AddTransition( "Idle", "StartTravel", "Travelling" )
    self:AddTransition( "Travelling", "Redirect", "Travelling" )
    self:AddTransition( "Travelling", "EndTravel", "Idle" )

    -- (Engage)
    self:AddTransition( {"Idle", "Travelling","Attacking","Rearming"}, "StartEngaging", "Engaging" )
    self:AddTransition( "Engaging", "EngageToIdle", "Idle" )
    self:AddTransition( "Engaging", "EngageToTravel", "Travelling" )
    
    -- (Rearming)
    self:AddTransition( "*", "RequestRearming", "Rearming" )
    self:AddTransition( "Rearming", "RearmedToIdle", "Idle" )
    self:AddTransition( "Rearming", "RearmedToTravel", "Travelling" )
    
    -- (Attacking)
    self:AddTransition( {"Idle","Travelling"}, "StartAttack", "Attacking" )
    self:AddTransition( "Attacking", "AttackToIdle", "Idle" )
    self:AddTransition( "Attacking", "AttackToTravel", "Travelling" )
    self:AddTransition( {"Idle","Travelling"}, "StartHold", "Holding" )
    self:AddTransition( "Holding", "HoldToIdle", "Idle" )
    self:AddTransition( "Holding", "HoldToTravel", "Travelling" )
    self:AddTransition( {"Idle","Travelling"}, "StartAvoid", "Avoiding" )
    self:AddTransition( "Avoiding", "AvoidToIdle", "Idle" )
    self:AddTransition( "Avoiding", "AvoidToTravel", "Travelling" )

    -- (Retreating)
    self:AddTransition( "*", "StartRetreat", "Retreating" )
    self:AddTransition( "Retreating", "EndRetreat", "Idle" )


    --Initialize Group Data
    self.TickRate = 1
    self.Group = group --The Wrapper.Group#GROUP object of the group.
    self.Groupname = group:GetName() --The DCS GroupName of the Wrapper.Group#GROUP object
    self.groupCoalition = self.Group:GetCoalition()
    self.enemyCoalition = coalition.side.RED
    self.groupCoalitionString = "blue"
    self.enemyCoalitionString = "red"
    if self.groupCoalition == coalition.side.RED then 
        self.enemyCoalition = coalition.side.BLUE 
        self.groupCoalitionString = "red"
        self.enemyCoalitionString = "blue"
    end
    self.MessageOutput = false
    self.MessageDuration = 10
    self.MessageSound = "squelch2.ogg"
    self.MessageCallsign = "ANONYMOUS"
    self.Sleeping = false


    --(Group Units)
    self.UnitTable = self.Group:GetUnits() --A table containing all of the Wrapper.Unit#UNIT objects in the group with nested data.
    for i = 1, #self.UnitTable do
        self.UnitTable[i].UnitName = self.UnitTable[i]:GetName() --Name of the Wrapper.Unit#UNIT object
        self.UnitTable[i].TroopTransport = false --Is the unit a troop transport?
        self.UnitTable[i].TroopsBoarded = false --Are any troops on board?
        self.UnitTable[i].TroopGroup = nil --The Wrapper.Group#GROUP object of deployed troops when dropped
        self.UnitTable[i].TroopsAlive = nil --Number of troops alive from the original template
    end

    --(Ammunition/Rearming)
    self.groupAmmo = {}
    self.LowAmmoPercent = 0.25
    self.FullAmmoPercent = 0.95
    self.IsWinchester = false
    self.IsRearming = false
    self.RearmTemplate = nil
    self.RearmSpawnCoord = nil
    self.AllowRearming = false
    self.DespawnRearmingGroup = false
    self.AllowRearmRespawn = true
    self.RearmGroup = nil
    self.RearmGroupBase = nil
    self.RearmGroupRTB = true
    self.RearmGroupUseRoads = true
    self.RearmGroupSpeed = 60
    self.RearmGroupFormation = "Cone"
    self.RearmDrawing = false
    self.DrawDataR = {}

    --(Troop Transport)
    self.TroopTransport = false --Set to true to enable troop transport. Additional options required
    self.TransportUnitPrefix = nil --Provide a #string to identify specific units that will carry troops. Leave as nil to enable troop transport for all units of the group
    self.TroopTemplate = nil --A late activated Wrapper.Group#GROUP object to use as the template for troop deployment
    self.TroopAttackDist = 1000 --How far troops deployed will move to attack the closest enemy (also affects when an attacking group stops to deploy troops)
    self.TroopDismountDistMin = 100 -- If engaging beyond of TroopAttackDist, how far will troops move away from the carriers when disembarking (min random value)
    self.TroopDismountDistMax = 300 -- If engaging beyond of TroopAttackDist, how far will troops move away from the carriers when disembarking (max random value)
    self.TroopFormation = "Diamond" -- Formation the troops will move in when attacking
    self.TroopMoveSpeed = 24
    self.TroopsAttacking = false
    self.DeployedTroops = {}
    self.AttackingTroops = {}
    self.ExtractTimeLimit = 300

    --(Travel)
    self.Destination = nil --The last provided destination in the TravelTo call.
    self.DestinationRate = 30 --How often in seconds to check up on the traveling group and see if its at its destination or is stuck
    self.DestinationRadius = 100 --How close the group needs to be to its destination to consider it as arrived
    self.FixStuck = true --Allow the group to make short movements in different directions if they've stopped before reaching their destination without switching states
    self.UnstuckDist = 100 --How far to place a waypoint for the group to try and get it unstuck
    self.MaxUnstuckAttempts = 10 --How many attempts to make to get unstuck before it stops trying. Returns state to Idle if DestroyStuck is false
    self.DestroyStuck = false --Set to true to remove the group from the game if MaxUnstuckAttempts has been reached.
    self.StuckHeadingIncrements = 60
    self.InclineLimit = 35

    self.travelToStored = nil
    self.stuckPosit = nil
    self.lastStuckHeading = nil
    self.countStuck = 0

    --(Detection)
    self.UseDetection = true
    self.DetectionRate = 30
    self.TacticalROE = "Attack" --Options = "Attack", "Avoid", "Hold", "Ignore"
    self.UseLOS = true
    self.UseDetectionChance = true
    self.MaxDetection = 6000
    self.FullDetection = 500
    self.FilterDetectionZones = nil
    self.FilterEnemyType = nil --Options = "Helicopter", "Airplane", "Ground Unit", "Ship", "Train"
    self.ManageAlarmState = true
    self.DefaultAlarmState = "Auto"
    self.ClosestEnemy = nil
    self.DrawEnemySpots = true
    self.EnemySpotStale = 120
    self.markSpot = nil
    self.markSpotTimer = nil
    self.zoneDetection = ZONE_RADIUS:New("DetZone_"..self.Groupname, self.Group:GetVec2(), self.MaxDetection, true)

    --(Attack)
    self.CombatDistance = 2000
    self.AttackFarUsesRoads = false
    self.AttackPositionDist = 200
    self.attackLastCoord = nil
    self.AttackSpeed = 20
    self.AttackSpeedFar = 60
    self.AttackFormationFar = "Diamond"
    self.AttackFormation = "Rank"
    self.AttackTimeout = 300
    self.LastTargetThreshold = 25

    self.HoldingTime = 120
    self.HoldDistance = 4000

    self.AvoidDistance = 2000
    self.AvoidAzimuthMax = 30
    self.AvoidUseRoads = false
    self.AvoidSpeed = 60
    self.AvoidFormation = 'Cone'
    self.avoidDest = nil
    self.AvoidRate = 30

    --(Engagement)
    self.ReactToHits = true
    self.ReactAfterShooting = true
    self.EvadeDistance = 25
    self.EngageCooldown = 120
    self.DisperseOnShoot = true
    self.DisperseOnHit = true
    self.DrawDataE = {}
    self.EngageDrawing = false
    self.EngageDrawingFresh = 120
    self.EngageDrawingStale = 300

    --(Retreating)
    self.RetreatAfterLosses = nil
    self.RetreatZone = nil
    self.RetreatSpeed = 60
    self.RetreatOnRoads = true
    self.RetreatFormation = "Diamond"
    self.DespawnAfterRetreat = false
    self.retreatDestination = nil

    --(SUPPORT REQUEST)
    self.AllowSupportRequests = true
    self.SupportRadius = 4000
    self.SupportGroupLimit = 3
    self.RespondToSupport = true
    self.SupportLevel = 3 --1 = On Spotted, 2 = On Engage, 3 = On Hit, 4 = On Unit Loss
    self.supportTable = {}
    self.SupportCooldown = 300

    --(ABANDON VEHICLE)
    self.AbandonEnabled = false
    self.CrewTemplate = nil
    self.AbandonHealth = 0.5
    self.AbandonDistance = 1000
    self.AllowSelfRecover = true
    self.RecoveryVehicle = nil
    self.RecoverySpawnZone = nil
    self.RecoveryUseRoads = true
    self.RecoverySpeed = 60
    self.RecoveryFormation = "Diamond"
    self.SmokeAbandoned = false
    self.StaticSmokeTimeout = 300

    --Event Handling
    self.Group:HandleEvent(EVENTS.Hit)
    self.Group:HandleEvent(EVENTS.ShootingStart)
    self.Group:HandleEvent(EVENTS.Shot)
    self.Group:HandleEvent(EVENTS.Dead)

    local function handleContact(type, EventData)
        if not self.Sleeping then
            if not self:Is("Retreating") then
                if type == "Hit" then
                    if self.ReactToHits then 
                        if not self:Is("Engaging") then self:_InitEngagement(true,EventData) end
                        self.TimeEngageActive = true
                        self.TimeEngageStamp = timer.getAbsTime()
                        if self.SupportLevel <= 3 and not self.TimeSupportActive and self.AllowSupportRequests then
                            self:RequestSupport(EventData.IniUnit)
                        end
                    end
                end
                if type == "Shooting" then
                    if self.ReactAfterShooting then 
                        if not self:Is("Engaging") then self:_InitEngagement(false,EventData) end
                        self.TimeEngageActive = true
                        self.TimeEngageStamp = timer.getAbsTime()
                        if self.SupportLevel <= 2 and not self.TimeSupportActive and self.AllowSupportRequests then
                            self:RequestSupport(EventData.TgtUnit)
                        end
                    end
                end
                if type == "Shot" then
                    if self.ReactAfterShooting then 
                        if not self:Is("Engaging") then self:_InitEngagement(false,EventData) end
                        self.TimeEngageActive = true
                        self.TimeEngageStamp = timer.getAbsTime()
                        if self.SupportLevel <= 2 and not self.TimeSupportActive and self.AllowSupportRequests then
                            self:RequestSupport(EventData.TgtUnit)
                        end
                    end
                end
            end
        end
        if type == "Dead" then
            self:_DeadResponse(EventData)
        end
    end

    function self.Group:OnEventHit(EventData)
        handleContact("Hit", EventData)
    end

    function self.Group:OnEventShot(EventData)
        handleContact("Shot", EventData)
    end

    function self.Group:OnEventShootingStart(EventData)
        handleContact("Shooting", EventData)
    end

    function self.Group:OnEventDead(EventData)
        handleContact("Dead", EventData)
    end
    


    --Build group ammunition table if able
    for i = 1, #self.UnitTable do
        local tableAmmo = self.UnitTable[i]:GetAmmo()
        if tableAmmo then
            for a = 1, #tableAmmo do
                self:T( self.UnitTable[i].UnitName .. " has " .. tableAmmo[a]["count"] .. " " .. tableAmmo[a]["desc"]["typeName"])
            end
            table.insert(self.groupAmmo, tableAmmo)
        else
            self:T( self.UnitTable[i].UnitName .. " does not use ammunition.")
            table.insert(self.groupAmmo, nil)
        end
    end

    --Set Group Initialization
    -- TIMER:New(function()
    --     self.setEnemy = SET_UNIT:New():FilterCoalitions(self.enemyCoalitionString):FilterActive()
    --     if self.FilterEnemyType then self.setEnemy:FilterCategories(self.FilterEnemyType) end
    --     if self.FilterDetectionZones then self.setEnemy:FilterZones(self.FilterDetectionZones) end
    --     self.setEnemy:FilterStart()
    -- end):Start(1)



    
    ----------[TIMER BASED FUNCTIONS]----------


    --Master Time Tracking
    local initialTime = timer.getAbsTime()
    self.TimeTravelActive = false
    self.TimeTravelStamp = initialTime
    self.TimeDetectionActive = false
    self.TimeDetectionStamp = initialTime
    self.TimeRearmActive = false
    self.TimeRearmStamp = initialTime
    self.TimeRetreatActive = false
    self.TimeRetreatStamp = initialTime
    self.TimeAvoidActive = false
    self.TimeAvoidStamp = initialTime

    self.TimeEngageActive = false
    self.TimeEngageStamp = initialTime
    self.TimeHoldActive = false
    self.TimeHoldStamp = initialTime
    self.TimeAttackActive = false
    self.TimeAttackStamp = initialTime
    self.TimeSupportActive = false
    self.TimeSupportStamp = initialTime


    --Master Timer
    self.MasterTime = TIMER:New(function()
        local timeNow = timer.getAbsTime()

        ----{LOOPS}----
        --Travel Tracker
        if self.TimeTravelActive then
            if timeNow >= self.TimeTravelStamp + self.DestinationRate then
                self.TimeTravelStamp = timer.getAbsTime()
                self:_TravelCheck()
            end
        end

        --Detection
        if self.TimeDetectionActive then
            if timeNow >= self.TimeDetectionStamp + self.DetectionRate then
                self.TimeDetectionStamp = timer.getAbsTime()
                self:_DetectionCycle()
            end
        end
        
        --Avoid
        if self.TimeAvoidActive then
            if timeNow >= self.TimeAvoidStamp + self.AvoidRate then
                self.TimeAvoidStamp = timer.getAbsTime()
                self:_AvoidTimer()
            end
        end

        --Rearmed
        if self.TimeRearmActive then
            if timeNow >= self.TimeRearmStamp + 60 then
                self.TimeRearmStamp = timer.getAbsTime()
                self:_RearmCheckTimer()
            end
        end

        --Retreat
        if self.TimeRetreatActive then
            if timeNow >= self.TimeRetreatStamp + 60 then
                self.TimeRetreatStamp = timer.getAbsTime()
                self:_RetreatTimer()
            end
        end


        ----{COOLDOWNS}----
        --Engagement
        if self.TimeEngageActive then
            if timeNow >= self.TimeEngageStamp + self.EngageCooldown then
                self.TimeEngageActive = false
                self:_EngageCooldown()
            end
        end
        
        --Hold
        if self.TimeHoldActive then
            if timeNow >= self.TimeHoldStamp + self.HoldingTime then
                self.TimeHoldActive = false
                self:_HoldTimer()
            end
        end
        
        --Attack
        if self.TimeAttackActive then
            if timeNow >= self.TimeAttackStamp + self.AttackTimeout then
                self.TimeAttackActive = false
                self:_AttackTimer()
            end
        end
        
        --Support
        if self.TimeSupportActive then
            if timeNow >= self.TimeSupportStamp + self.SupportCooldown then
                self.TimeSupportActive = false
            end
        end
    end)


    ----------[USER FUNCTIONS]----------



    


    --Constructor related stuff
    if self.groupCoalition == coalition.side.RED then
        table.insert(TACTICS_UTILS.GroupsRed, self)
    else
        table.insert(TACTICS_UTILS.GroupsBlue, self)
    end     

    self:__Start(1)
    return self
end




--------[INTERNAL FSM CALLBACKS]---------

--- [Internal] FSM Function onafterStart
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterStart(From,Event,To)
    self:T({From, Event, To})
    self.MasterTime:Start(self.TickRate,self.TickRate)
    if self.UseDetection == true then self.TimeDetectionActive = true end
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is now active and available for tasking.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
    return self
end

--- [Internal] FSM Function onafterStop
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterStop(From,Event,To)
    self:T({From, Event, To})
    self.MasterTime:Stop()
    return self
end

--- [Internal] FSM Function onafterStartTravel
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterStartTravel(From,Event,To,CoordGroup,CoordDest)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is initiating travel to our assigned destination.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterRedirect
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterRedirect(From,Event,To,CoordGroup,CoordDest)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." received. Redirecting to the new destination.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterEndTravel
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterEndTravel(From,Event,To,GroupCoord,DestCoord)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." has arrived at our destination. Ready for tasking.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterStartAvoid
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterStartAvoid(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is avoiding the target.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterAvoidToTravel
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterAvoidToTravel(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer avoiding the target. Resuming travel to destination.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterAvoidToIdle
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterAvoidToIdle(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer avoiding the target. Ready for tasking.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterEngageToTravel
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterEngageToTravel(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer engaged with the enemy. Resuming travel to destination.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterEngageToIdle
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterEngageToIdle(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer engaged with the enemy. Ready for tasking.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterHoldToTravel
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterHoldToTravel(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer holding from the enemy contact. Resuming travel to destination.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterHoldToIdle
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterHoldToIdle(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer holding from the enemy contact. Ready for tasking.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterStartAttack
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterStartAttack(From,Event,To,_enemy,distance,hdgEnemy)
    if self.MessageOutput then
        local tgtType = "enemy target"
        if _enemy:GetClassName() and not _enemy:GetClassName() == "COORDINATE" then tgtType = _enemy:GetTypeName() end
        MESSAGE:New(self.MessageCallsign.." is moving to attack a "..tostring(tgtType).." at "..math.floor(hdgEnemy).." for "..math.floor(distance).."m.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterAttackToTravel
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterAttackToTravel(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer attacking the enemy. Resuming travel to destination.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterAttackToIdle
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterAttackToIdle(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer attacking the enemy. Ready for tasking.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterStartEngaging
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterStartEngaging(From,Event,To,WasHit,UnitName,WeaponName,EventData)
    if self.MessageOutput then
        if WasHit then 
            if EventData.IniTypeName then
                MESSAGE:New(self.MessageCallsign.." is engaged with and receiving fire from a "..tostring(EventData.IniTypeName).."!",self.MessageDuration):ToCoalition(self.groupCoalition)
            else
                MESSAGE:New(self.MessageCallsign.." is engaged with and receiving fire from the enemy!",self.MessageDuration):ToCoalition(self.groupCoalition)
            end
        else        
            if EventData.TgtTypeName then
                MESSAGE:New(self.MessageCallsign.." is engaged with and attacking a "..tostring(EventData.TgtTypeName).."!",self.MessageDuration):ToCoalition(self.groupCoalition)
            else
                MESSAGE:New(self.MessageCallsign.." is engaged with and attacking the enemy!",self.MessageDuration):ToCoalition(self.groupCoalition)
            end
        end
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterRetreat
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterRetreat(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." has taken significant losses and is retreating!",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterEndRetreat
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterEndRetreat(From,Event,To,CoordGroup,CoordRetreat)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is no longer retreating.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterGroupDead
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterGroupDead(From,Event,To,EventData)
    if self.MessageOutput and EventData then
        MESSAGE:New(self.MessageCallsign.." is KIA!",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterWinchester
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterWinchester(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is winchester!",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterRequestRearming
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterRequestRearming(From,Event,To,GroupRearm)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." requesting rearming.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterFullyRearmed
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterFullyRearmed(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." is fully rearmed.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterTroopsDropped
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterTroopsDropped(From,Event,To,TargetCoord,IsAttacking)
    if self.MessageOutput then
        local attackMessage = " to attack a target"
        if not IsAttacking then attackMessage = "" end
        MESSAGE:New(self.MessageCallsign.."'s infantry are now disembarked"..attackMessage..".",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterTroopsReturned
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterTroopsReturned(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." has embarked all of our troops.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterTroopsExtracted
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterTroopsExtracted(From,Event,To)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." has extracted troops.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterSupportRequested
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterSupportRequested(From,Event,To,CoordTarget,UnitTarget)
    if self.MessageOutput then
        local addMessage = ""
        if UnitTarget then addMessage = " Our target is a "..tostring(UnitTarget:GetTypeName()).."." end
        MESSAGE:New(self.MessageCallsign.." requesting support!"..addMessage,self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterSupporting
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterSupporting(From,Event,To,Group,CoordTarget,Callsign)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." will provide support for "..tostring(Callsign)..".",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterAbandoned
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterAbandoned(From,Event,To,UnitCoord,UnitName,UnitType)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." has abandoned a "..UnitType.." due to excessive damage.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end

--- [Internal] FSM Function onafterCrewRecovered
-- @param #TACTICS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TACTICS self
function TACTICS:onafterCrewRecovered(From,Event,To,RecoveryUnit,RecoveryName)
    if self.MessageOutput then
        MESSAGE:New(self.MessageCallsign.." the abandoning crew has been recovered by another vehicle.",self.MessageDuration):ToCoalition(self.groupCoalition)
        USERSOUND:New(self.MessageSound):ToCoalition(self.groupCoalition)
    end
end




--------[TIMER METHODS]---------

---LOOP: Travel Tracker
--- [Internal] Travek Chek
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_TravelCheck()
    if self:Is("Travelling") then
        self:T2("TACTICS: "..self.Groupname.." travel check timer.")
        local coordGroup = self.Group:GetAverageCoordinate()
        if not coordGroup then coordGroup = self.Group:GetCoordinate() end
        if not coordGroup then 
            if not self:Is("Dead") then
                self:_DeadResponse()
            end
        elseif self.Destination then
            local distGroup = coordGroup:Get3DDistance(self.Destination)
            local speedGroup = self.Group:GetVelocityKMH()

            --Arrived at destination
            if distGroup <= self.DestinationRadius then
                self.Group:RouteStop()
                self:T("TACTICS: "..self.Groupname.." arrived at their destination.")
                self.TimeTravelActive = false
                self.travelToStored = nil
                self:EndTravel(self.Group:GetAverageCoordinate(), self.Destination)
                self.Destination = nil
            elseif speedGroup < 1 and self.FixStuck or self.countStuck > 0 then -- Attempt to get unstuck if it's stopped before arriving at the destination.
                self.countStuck = self.countStuck + 1
                self:T("TACTICS: "..self.Groupname.." is stopped when it should be moving. Check #"..self.countStuck)
                if self.countStuck == 1 then -- Initial unstuck check
                    self.stuckPosit = self.Group:GetAverageCoordinate()
                elseif self.countStuck > 1 and self.countStuck < self.MaxUnstuckAttempts then
                    local distStuck = coordGroup:Get3DDistance(self.stuckPosit)
                    if distStuck <= self.UnstuckDist/4 then -- Attempt to get unstuck
                        if self.lastStuckHeading == nil then 
                            self.lastStuckHeading = (self.stuckPosit:HeadingTo(self.Destination) + self.StuckHeadingIncrements) % 360
                        else
                            self.lastStuckHeading = (self.lastStuckHeading + self.StuckHeadingIncrements) % 360
                        end
                        local unstuckDest = coordGroup:Translate(self.UnstuckDist,self.lastStuckHeading,false,false)
                        self.Group:RouteGroundTo(unstuckDest, 10, 'Cone', 1)
                        self:T("TACTICS: "..self.Groupname.." is attempting to get unstuck by driving "..self.UnstuckDist .."m toward heading "..self.lastStuckHeading)
                    else -- Group has moved enough to resume the route
                        self:T("TACTICS: "..self.Groupname.." has gotten unstuck. Resuming on the path...")
                        self.countStuck = 0
                        self.stuckPosit = nil
                        self.TimeTravelActive = false
                        self:_InitiateTravel()
                    end
                elseif self.countStuck >= self.MaxUnstuckAttempts then -- Max stuck attempts exceeded
                    if self.DestroyStuck then --EITHER Destroy the group
                        self:E("TACTICS: "..self.Groupname.." has been stuck for too long and was removed from the game...")
                        self.Group:Destroy()
                        self:_DeadResponse(false)
                    else --OR Return the group to Idle
                        self:E("TACTICS: "..self.Groupname.." has been stuck for too long and was returned to the idle state...")
                        self.Group:RouteStop()
                        self.TimeTravelActive = false
                        self.travelToStored = nil
                        self:EndTravel(self.Group:GetAverageCoordinate(), self.Destination)
                        self.Destination = nil
                    end
                end
            else
                self.countStuck = 0
                self.stuckPosit = nil
            end           
        else
            self:E("TACTCS ERROR: "..self.Groupname.." attempted to compare distance to travel destination but 'self.Destination' is a nil value!")    
        end
    else
        self.TimeTravelActive = false
        self.stuckPosit = nil
        self.lastStuckHeading = nil
        self.countStuck = 0
    end
    return self
end


--- [Internal] Detection Cycle
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_DetectionCycle()
    if not self:Is("Engaging") then
        self:T2("TACTICS: ---- Detection Cycle ---- - [GRP: "..self.Groupname.."]")
        local coordGroup = self.Group:GetAverageCoordinate()
        if not coordGroup then coordGroup = self.Group:GetCoordinate() end
        if not coordGroup then 
            if not self:Is("Dead") then
                self:_DeadResponse()
            end
        end
        if coordGroup then
            --Try to detect an enemy.
            local distClosestEnemy = 9999999
            local newSpot = false
            local hdgClosestEnemy = 0
            self.zoneDetection:SetVec2(coordGroup:GetVec2())
            
            TACTICS_UTILS.SetGroups:ForEachGroupAnyInZone(self.zoneDetection, function(_setgroup)
                local coordEnemy = _setgroup:GetCoordinate()
                local validUnit = true
                if not coordEnemy then
                    validUnit = false
                elseif _setgroup:GetCoalition() == self.groupCoalition then
                    validUnit = false
                elseif self.FilterEnemyType and not _setgroup:GetCategoryName() == self.FilterEnemyType then
                    validUnit = false
                elseif self.FilterDetectionZones and type(self.FilterDetectionZones) == "table" then
                    local inZone = false
                    for i = 1, #self.FilterDetectionZones do
                        if _setgroup:IsAnyInZone(self.FilterDetectionZones[i]) then
                            inZone = true
                            break
                        end
                    end
                    validUnit = inZone
                end

                if validUnit then
                    local tableEnemyUnits = _setgroup:GetUnits()
                    for i = 1,#tableEnemyUnits do
                        local _enemy = tableEnemyUnits[i]
                        if _enemy:IsInZone(self.zoneDetection) then
                            local speedEnemy = _enemy:GetVelocityKMH()
                            local distEnemy = coordGroup:Get3DDistance(coordEnemy)
                            self:T2("TACTICS: Checking "..tostring(_enemy:GetName()).." at a range of "..tostring(distEnemy).."m / "..tostring(self.MaxDetection).."m")
                            if distEnemy < self.MaxDetection then
                                local checkLOS = true
                                if self.UseLOS then checkLOS = coordGroup:IsLOS(coordEnemy) end
                                self:T2("TACTICS: "..tostring(_enemy:GetName()).." is LOS = "..tostring(checkLOS))
                                if distEnemy < self.FullDetection and distEnemy < distClosestEnemy then
                                    self:T2("TACTICS: "..tostring(_enemy:GetName()).." is the closest target and is within Full Detection range ("..tostring(self.FullDetection).."m)")
                                    distClosestEnemy = distEnemy 
                                    hdgClosestEnemy = coordGroup:HeadingTo(coordEnemy)
                                    self.ClosestEnemy = _enemy
                                    newSpot = true
                                elseif checkLOS then
                                    local distVarChance = 2
                                    if self.UseDetectionChance then distVarChance = (self.MaxDetection - distEnemy)/self.MaxDetection end
                                    local checkChance = math.random(1,100)
                                    if self.FilterEnemyType == "ground" then
                                        if speedEnemy > 5 and speedEnemy < 60 then checkChance = checkChance / 2 end
                                    end
                                    if self.FilterEnemyType == "helicopter" and self.UseDetectionChance or self.FilterEnemyType == "airplane" and self.UseDetectionChance then
                                        local altVarChance = 0.05
                                        local altHelo = _enemy:GetAltitude()
                                        local altGroup = _grp:GetAltitude()
                                        local altDiff = altHelo - altGroup
                                        local degHelo = 0
                                        if altDiff > 0 then
                                            local angHelo = math.asin(altDiff/distEnemy)
                                            degHelo = math.deg(angHelo)
                                            if degHelo > 15 then altVarChance = 1.0 elseif degHelo > 5 then altVarChance = (degHelo/15) end         
                                        end
                                        distVarChance = distVarChance + altVarChance
                                    end

                                    self:T2("TACTICS: Detection roll: Is "..tostring(checkChance).." <= "..tostring((distVarChance/2)*100).."?")
                                    if checkChance <= (distVarChance/2)*100 and distEnemy < distClosestEnemy then 
                                        self:T2("TACTICS: "..tostring(_enemy:GetName()).." was detected by "..self.Groupname.." and is the closest target")
                                        distClosestEnemy = distEnemy
                                        hdgClosestEnemy = coordGroup:HeadingTo(coordEnemy)
                                        self.ClosestEnemy = _enemy
                                        newSpot = true
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if newSpot then
                self:_SpotTarget(self.ClosestEnemy,distClosestEnemy)
                self:TargetSpotted(self.ClosestEnemy,distClosestEnemy,hdgClosestEnemy)
                if self.DrawEnemySpots then
                    self:_ContactMark(self.ClosestEnemy:GetCoordinate(),2)
                end
            end
        end
    end
    return self
end

--- [Internal] Avoid Timer Function
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_AvoidTimer()
    self:T("TACTICS: >> AVOID TIMER << - [GRP: "..self.Groupname.."]")
    if not self.Group:GetCoordinate() then
        if not self:Is("Dead") then
            self:_DeadResponse()
        end
    else
        if self:Is("Engaging") then
            self.TimeAvoidActive = false
        else
            local coordGroup = self.Group:GetAverageCoordinate()
            if not coordGroup then coordGroup = self.Group:GetCoordinate() end
            local distGroup = coordGroup:Get3DDistance(self.avoidDest)
            if distGroup <= self.DestinationRadius then
                self:I("TACTICS: "..self.Groupname.." is no longer avoiding the threat.")
                if self.ManageAlarmState then
                    if self.DefaultAlarmState == "Auto" then 
                        self.Group:OptionAlarmStateAuto()
                    elseif self.DefaultAlarmState == "Red" then 
                        self.Group:OptionAlarmStateRed()
                    elseif self.DefaultAlarmState == "Green" then 
                        self.Group:OptionAlarmStateGreen()
                    end
                end
                if self.travelToStored then
                    self:AvoidToTravel()
                    self:_InitiateTravel()
                else
                    self.Group:RouteStop()
                    self:AvoidToIdle()
                end
                self.TimeAvoidActive = false
            end
        end
    end
    return self
end

--- [Internal] Rearm check timer
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_RearmCheckTimer()
    self:T("TACTICS: >> REARM CHECK TIMER << - [GRP: "..self.Groupname.."]")
    if not self.Group:GetCoordinate() then
        if not self:Is("Dead") then
            self:_DeadResponse()
        end
    else
        --Finish up if full
        local isWinchester, isFull = self:CheckAmmo()
        if isFull or self:Is("Retreating") then
            if not self:Is("Retreating") then 
                self:I("TACTICS: "..self.Groupname.." is fully rearmed.") 
            else 
                self:I("TACTICS: "..self.Groupname.." interrupted rearming to retreat.") 
            end
            self.TimeRearmActive = false
            self.IsWinchester = false
            self.IsRearming = false
            self:FullyRearmed()
            self:_RTBRearmGroup()
            if self.DrawDataR.DrawText then 
                trigger.action.removeMark(self.DrawDataR.DrawText)
                self.DrawDataR.DrawText = nil
            end
            if self.DrawDataR.DrawPoly then 
                trigger.action.removeMark(self.DrawDataR.DrawPoly)
                self.DrawDataR.DrawPoly = nil
            end

            --Return to activity
            if self.Destination and not self:Is("Retreating") then
                self:RearmedToTravel()
                self:_InitiateTravel()
            elseif not self:Is("Retreating") then
                self:RearmedToIdle()
            end          
        end

        --Dispatch another group if lost
        if not self:Is("Retreating") then
            if not self.RearmGroup and not self.RearmGroupBase then
                self:T("TACTICS: "..self.Groupname.." does not have a rearm group or base. ")
            elseif not self.RearmGroup:GetCoordinate() and self.AllowRearmRespawn then
                self:_CallForRearm(true)
            elseif not self.RearmGroup:GetCoordinate() and not self.AllowRearmRespawn then
                self:I("TACTICS: "..self.Groupname.." can no longer be rearmed.")
                self.TimeRearmActive = false
                self.IsWinchester = false
                self.IsRearming = false
                self.AllowRearming = false

                --Return to activity
                if self.Destination then
                    self:RearmedToTravel()
                    self:_InitiateTravel()
                else
                    self:RearmedToIdle()
                end      
            end
        end
    end
    return self
end

--- [Internal] Retreat check timer
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_RetreatTimer()
    self:T("TACTICS: >> RETREAT CHECK TIMER << - [GRP: "..self.Groupname.."]")
    if not self.Group:GetCoordinate() then
        if not self:Is("Dead") then
            self:_DeadResponse()
        end
    elseif self:Is("Retreating") then
        local unitsRemain, selfRecover = self:CheckUnitLife()
        if unitsRemain > 0 then
            local coordGroup = self.Group:GetAverageCoordinate()
            if not coordGroup then coordGroup = self.Group:GetCoordinate() end
            local distGroup = coordGroup:Get3DDistance(self.retreatDestination)
            local speedGroup = self.Group:GetVelocityKMH()

            --Arrived at destination
            if distGroup <= self.DestinationRadius then
                self.Group:RouteStop()
                self:T("TACTICS: "..self.Groupname.." arrived at their destination.")
                self.RetreatTimer:Stop()
                self.travelToStored = nil
                self:EndRetreat(self.Group:GetAverageCoordinate(), self.retreatDestination)
                self.retreatDestination = nil
                if self.DespawnAfterRetreat then
                    self.Group:Destroy()
                    self:_DeadResponse(false)
                else
                    if self.UseDetection == true then
                        self.TimeDetectionActive = true
                        self.TimeDetectionStamp = timer.getAbsTime() 
                    end
                end
            elseif speedGroup < 1 and self.FixStuck or self.countStuck > 0 then -- Attempt to get unstuck if it's stopped before arriving at the destination.
                self.countStuck = self.countStuck + 1
                self:T("TACTICS: "..self.Groupname.." is stopped when it should be moving. Check #"..self.countStuck)
                if self.countStuck == 1 then -- Initial unstuck check
                    self.stuckPosit = self.Group:GetAverageCoordinate()
                elseif self.countStuck > 1 and self.countStuck < self.MaxUnstuckAttempts then
                    local distStuck = coordGroup:Get3DDistance(self.stuckPosit)
                    if distStuck <= self.UnstuckDist/4 then -- Attempt to get unstuck
                        if self.lastStuckHeading == nil then 
                            self.lastStuckHeading = (self.stuckPosit:HeadingTo(self.retreatDestination) + self.StuckHeadingIncrements) % 360
                        else
                            self.lastStuckHeading = (self.lastStuckHeading + self.StuckHeadingIncrements) % 360
                        end
                        local unstuckDest = coordGroup:Translate(self.UnstuckDist,self.lastStuckHeading,false,false)
                        self.Group:RouteGroundTo(unstuckDest, 10, 'Cone', 1)
                        self:T("TACTICS: "..self.Groupname.." is attempting to get unstuck by driving "..self.UnstuckDist .."m toward heading "..self.lastStuckHeading)
                    else -- Group has moved enough to resume the route
                        self:T("TACTICS: "..self.Groupname.." has gotten unstuck. Resuming on the path...")
                        self.countStuck = 0
                        self.stuckPosit = nil
                        if not self.TroopsAttacking then
                            if self.RetreatOnRoads then
                                self.Group:RouteGroundOnRoad(self.retreatDestination, self.RetreatSpeed, 1, self.RetreatFormation)
                            else
                                self.Group:RouteGroundTo(self.retreatDestination, self.a, self.RetreatFormation, 1)
                            end
                        end
                    end
                elseif self.countStuck >= self.MaxUnstuckAttempts then -- Max stuck attempts exceeded
                    if self.DestroyStuck then --EITHER Destroy the group
                        self:E("TACTICS: "..self.Groupname.." has been stuck for too long and was removed from the game...")
                        self:EndRetreat(self.Group:GetAverageCoordinate(), self.retreatDestination)
                        self.Group:Destroy()
                        self:_DeadResponse(false)
                    else --OR Return the group to Idle
                        self:E("TACTICS: "..self.Groupname.." has been stuck for too long and was returned to the idle state...")
                        self.Group:RouteStop()
                        self.RetreatTimer:Stop()
                        self.travelToStored = nil
                        self:EndRetreat(self.Group:GetAverageCoordinate(), self.retreatDestination)
                        self.retreatDestination = nil
                        if self.DespawnAfterRetreat then
                            self.Group:Destroy()
                            self:_DeadResponse(false)
                        else
                            if self.UseDetection == true then
                                self.TimeDetectionActive = true
                                self.TimeDetectionStamp = timer.getAbsTime() 
                            end
                        end
                    end
                end
            else
                self.countStuck = 0
                self.stuckPosit = nil
            end
        end
    else
        self.TimeTravelActive = false
        self.stuckPosit = nil
        self.lastStuckHeading = nil
        self.countStuck = 0
    end
    return self
end

--- [Internal] Cooldown engagement
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_EngageCooldown()
    self:T("TACTICS: >> ENGAGE COOLDOWN TIMER << - [GRP: "..self.Groupname.."]")
    if not self.Group:GetCoordinate() then
        if not self:Is("Dead") then
            self:_DeadResponse()
        end
    else
        local unitsRemain, selfRecover = self:CheckUnitLife()
        if unitsRemain > 0 then
            local isWinchester, isFull = self:CheckAmmo()
            if isWinchester and self.AllowRearming then
                self:_CallForRearm()
                if self.TroopsAttacking then self:_ReturnTroops() end
            elseif not selfRecover then
                if self.TroopsAttacking then
                    self:_ReturnTroops()
                elseif self.Destination then
                    self:EngageToTravel()
                    self:_InitiateTravel()
                else
                    self:EngageToIdle()
                end
            end
        end
    end
    if self.DrawDataE.DrawText then 
        trigger.action.removeMark(self.DrawDataE.DrawText)
        self.DrawDataE.DrawText = nil
    end
    if self.DrawDataE.DrawPoly then 
        trigger.action.removeMark(self.DrawDataE.DrawPoly)
        self.DrawDataE.DrawPoly = nil
    end
    return self
end

--- [Internal Hold timer
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_HoldTimer()
    self:T("TACTICS: >> HOLD POSITION TIMER << - [GRP: "..self.Groupname.."]")
    if not self.Group:GetCoordinate() then
        if not self:Is("Dead") then
            self:_DeadResponse()
        end
    else
        if not self:Is("Engaging") then
            self:I("TACTICS: "..self.Groupname.." is no longer holding after spotting a threat.")
            if self.ManageAlarmState then
                if self.DefaultAlarmState == "Auto" then 
                    self.Group:OptionAlarmStateAuto()
                elseif self.DefaultAlarmState == "Red" then 
                    self.Group:OptionAlarmStateRed()
                elseif self.DefaultAlarmState == "Green" then 
                    self.Group:OptionAlarmStateGreen()
                end
            end
            if self.TroopsAttacking then
                self:_ReturnTroops()
            elseif self.Destination then
                self:HoldToTravel()
                self:_InitiateTravel()
            else
                self:HoldToIdle()
            end
        end
    end
    return self
end

--- [Internal Attacktimer
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_AttackTimer()
    self:T("TACTICS: >> ATTACK TIMER << - [GRP: "..self.Groupname.."]")
    self.attackLastCoord = nil
    if not self.Group:GetCoordinate() then
        if not self:Is("Dead") then
            self:_DeadResponse()
        end
    else
        if self:Is("Attacking") then
            self:I("TACTICS: "..self.Groupname.." does not see their target anymore and will stop attacking.")
            if self:Is("Attacking") then
                if self.TroopsAttacking then
                    self:_ReturnTroops()
                elseif self.Destination then
                    self:AttackToTravel()
                    self:_InitiateTravel()
                else
                    self.Group:RouteStop()
                    self:AttackToIdle()
                end
            end
            if self.ManageAlarmState then
                if self.DefaultAlarmState == "Auto" then 
                    self.Group:OptionAlarmStateAuto()
                elseif self.DefaultAlarmState == "Red" then 
                    self.Group:OptionAlarmStateRed()
                elseif self.DefaultAlarmState == "Green" then 
                    self.Group:OptionAlarmStateGreen()
                end
            end
        end
    end
    return self
end

--- [Internal EXTERNAL TIMER: Despawn Rearm Group
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_RearmingGroupDespawn()
    self.RearmingGroupDespawnTimer = TIMER:New(function()
        self:T({"TACTICS: >> REARM GROUP DESPAWN TIMER <<",GroupName = self.Groupname})
        if self.RearmGroup and self.RearmGroup:GetCoordinate() then
            self:I("TACTICS: checking if "..self.RearmGroup:GetName().." can despawn.")
            local speedGroup = self.RearmGroup:GetVelocityKMH()
            if speedGroup < 1 then
                self:I("TACTICS: removing "..self.RearmGroup:GetName().." from the simulation")
                self.RearmGroup:Destroy()
                self.RearmingGroupDespawnTimer:Stop()
                self.RearmingGroupDespawnTimer = nil
            end
        else
            self.RearmingGroupDespawnTimer:Stop()
            self.RearmingGroupDespawnTimer = nil
        end
    end)
    self.RearmingGroupDespawnTimer:Start(60,60)
    return self
end




--------[INTERNAL METHODS]---------

--- [Internal Initiate Travel
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_InitiateTravel()
    if self.Destination then
        self:T({"TACTICS TRAVEL INITIATED:", Groupname = self.Groupname, UseRoads = self.travelToStored.UseRoads, ToCoordinate = self.travelToStored.ToCoordinate, Speed = self.travelToStored.Speed, Formation = self.travelToStored.Formation, DelaySeconds = self.travelToStored.DelaySeconds, WaypointFunction = self.travelToStored.WaypointFunction, WaypointFunctionArguments = self.travelToStored.WaypointFunctionArguments, CurrentState = self:GetState()})
        if self.travelToStored.UseRoads then
            self.Group:RouteGroundOnRoad(self.travelToStored.ToCoordinate, self.travelToStored.Speed, self.travelToStored.DelaySeconds, self.travelToStored.Formation, self.travelToStored.WaypointFunction, self.travelToStored.WaypointFunctionArguments)
        else
            self.Group:RouteGroundTo(self.travelToStored.ToCoordinate, self.travelToStored.Speed, self.travelToStored.Formation, self.travelToStored.DelaySeconds, self.travelToStored.WaypointFunction, self.travelToStored.WaypointFunctionArguments)
        end
        if self:Is("Idle") then 
            self:StartTravel(self.Group:GetAverageCoordinate(), self.Destination)
        elseif self:Is("Travelling") then 
            self:Redirect(self.Group:GetAverageCoordinate(), self.Destination) 
        end
        self.TimeTravelActive = true
        self.TimeTravelStamp = timer.getAbsTime()
    else
        self:E("TACTICS ERROR: "..self.Groupname.." attempted to travel somewhere but doesn't have a destination!")
    end
    return self
end

--- [Internal Initiate Engagements
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_InitEngagement(WasHit,EventData)
    self:T({"TACTICS: "..self.Groupname.." started engaging something.",WasHit,EventData})
    local UnitName = EventData.IniDCSUnitName
    if not WasHit then UnitName = EventData.TgtDCSUnitName end
    local WeaponName = EventData.WeaponName
    local coordGroup = self.Group:GetAverageCoordinate()
    if not coordGroup then coordGroup = self.Group:GetCoordinate() end
    if coordGroup then
        local unitEnemy = UNIT:FindByName(UnitName)
        local coordEnemy = nil
        if unitEnemy then coordEnemy = unitEnemy:GetCoordinate() end
        local targetCoord = coordEnemy
        if not targetCoord then targetCoord = coordGroup end

        --Deploy troops if able
        if not self.TroopsAttacking and self.TroopTransport then
            self:DropTroops(targetCoord,true)
        end
        
        --Disperse if able
        if self.DisperseOnShoot and not WasHit or self.DisperseOnHit and WasHit then
            self:T("TACTICS: "..self.Groupname.." will attempt to disperse.")
            local headingGroup = self.Group:GetHeading()
            if headingGroup then
                local roadside = math.random(2)
                if roadside == 1 then headingGroup = headingGroup + 45 else headingGroup = headingGroup - 45 end
                if headingGroup < 1 then headingGroup = headingGroup + 360 elseif headingGroup > 359 then headingGroup = headingGroup - 360 end
                local coordEvade = coordGroup:Translate(headingGroup, self.EvadeDistance, false, false)
                if not coordEvade:IsInFlatArea(25, self.InclineLimit) or coordEvade:IsSurfaceTypeWater() or coordEvade:IsSurfaceTypeShallowWater()  then
                    if roadside == 2 then headingGroup = headingGroup + 45 else headingGroup = headingGroup - 45 end
                    if headingGroup < 1 then headingGroup = headingGroup + 360 elseif headingGroup > 359 then headingGroup = headingGroup - 360 end
                    coordEvade:Translate(headingGroup, self.EvadeDistance, false, true)
                end
                if coordEvade:IsInFlatArea(25, self.InclineLimit) and not coordEvade:IsSurfaceTypeWater() and not coordEvade:IsSurfaceTypeShallowWater() then
                    self:T({"TACTICS: "..self.Groupname.." is dispersing.",headingGroup,self.EvadeDistance})
                    self.Group:RouteGroundTo(coordEvade, 20, 'Cone', 1)
                    TIMER:New(function()
                        if not self:Is("Retreating") then self.Group:RouteStop() end
                    end):Start(15)
                else                  
                    self:T("TACTICS: "..self.Groupname.." could not disperse due to unsuitable terrain.")
                    self.Group:RouteStop()
                end
            end
        elseif self.Is("Traveling") then
            self.Group:RouteStop()
        end

        --Interrupt rearming if required
        if self.IsWinchester then
            self.IsWinchester = false
            if self.IsRearming then
                self.IsRearming = false
                self.TimeRearmActive = false
                if self.RearmGroup and self.RearmGroup:GetCoordinate() then
                    self:_RTBRearmGroup()
                end
                if self.DrawDataR.DrawText then 
                    trigger.action.removeMark(self.DrawDataR.DrawText)
                    self.DrawDataR.DrawText = nil
                end
                if self.DrawDataR.DrawPoly then 
                    trigger.action.removeMark(self.DrawDataR.DrawPoly)
                    self.DrawDataR.DrawPoly = nil
                end
            end
        end

        --Draw on map if able
        if self.EngageDrawing then
            if self.DrawDataE.DrawText then 
                trigger.action.removeMark(self.DrawDataE.DrawText)
            end
            if self.DrawDataE.DrawPoly then 
                trigger.action.removeMark(self.DrawDataE.DrawPoly)
            end

            self.DrawDataE.DrawText = coordGroup:TextToAll(self.DrawDataE.Text,self.DrawDataE.Coalition,self.DrawDataE.Color1,self.DrawDataE.Alpha1,self.DrawDataE.Color2,self.DrawDataE.Alpha2,self.DrawDataE.Font,false) 
            self.DrawDataE.DrawPoly = coordGroup:CircleToAll(self.DrawDataE.Radius,self.DrawDataE.Coalition,self.DrawDataE.Color1,self.DrawDataE.Alpha1,self.DrawDataE.Color2,self.DrawDataE.Alpha2/2,self.DrawDataE.Linetype,false)

            if self.DrawDataE.MarkEnemy then
                local tempType = 0
                if not coordEnemy then tempType = 1 end
                self:_ContactMark(targetCoord,tempType)
            end
        end
    
        self:StartEngaging(WasHit, UnitName, WeaponName, EventData)
    end
    return self
end

--- [Internal Dead unit response
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_DeadResponse(EventData)
    if not self:Is("Dead") then
        if EventData then 
            self:UnitLost(EventData)
            self:T("TACTICS: "..self.Groupname.." lost a unit.") 
            if self.SupportLevel <= 4 and not self.TimeSupportActive and self.Group:GetCoordinate() and self.AllowSupportRequests then
                self:RequestSupport()
            end
        end
        if self.Group:GetUnits() == nil or #self.Group:GetUnits() <= 0 then
            self:I("TACTICS: "..self.Groupname.." has died or was removed from the sim.")
            if self.MasterTime and self.MasterTime:IsRunning() then self.MasterTime:Stop() end
            
            --Garbage Day
            self.MasterTime = nil
            self.UnitTable = nil
            -- self.setEnemy:FilterStop()
            -- self.setEnemy = nil
            
            if self.DrawDataR.DrawText then 
                trigger.action.removeMark(self.DrawDataR.DrawText)
                self.DrawDataR.DrawText = nil
            end
            if self.DrawDataR.DrawPoly then 
                trigger.action.removeMark(self.DrawDataR.DrawPoly)
                self.DrawDataR.DrawPoly = nil
            end
            if self.DrawDataE.DrawText then 
                trigger.action.removeMark(self.DrawDataE.DrawText)
                self.DrawDataE.DrawText = nil
            end
            if self.DrawDataE.DrawPoly then 
                trigger.action.removeMark(self.DrawDataE.DrawPoly)
                self.DrawDataE.DrawPoly = nil
            end

            self:GroupDead(EventData)
        elseif self.RetreatAfterLosses and #self.Group:GetUnits() <= (#self.UnitTable * self.RetreatAfterLosses) and not self:Is("Retreating") then
            self:Retreat()
        end
    end
    return self
end

--- [Internal Ammo check
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:CheckAmmo()
    self:T("TACTICS: Ammo check called for "..self.Groupname)
    local checkUnits = self.Group:GetUnits()
    local ammoLow = false
    local ammoFull = true
    for u = 1, #checkUnits do
        for z = 1, #self.UnitTable do
            if checkUnits[u]:GetName() == self.UnitTable[z].UnitName then
                self:T("TACTICS: Checking "..self.UnitTable[z].UnitName)
                local currentAmmo = checkUnits[u]:GetAmmo()
                if self.groupAmmo[z] and #self.groupAmmo[z] > 0 then
                    for i = 1, #self.groupAmmo[z] do
                        local ammoCount = 0
                        if currentAmmo and #currentAmmo > 0 then
                            for v = 1, #currentAmmo do
                                if currentAmmo[v]["desc"]["typeName"] == self.groupAmmo[z][i]["desc"]["typeName"] then
                                    ammoCount = currentAmmo[v]["count"]
                                    self:T( "TACTICS: "..self.groupAmmo[z][i]["desc"]["typeName"].." = "..currentAmmo[v]["count"].."/"..self.groupAmmo[z][i]["count"])
                                end
                            end
                        else
                            ammoLow = true
                        end
                        if ammoCount < (self.groupAmmo[z][i]["count"] * self.LowAmmoPercent) then
                            ammoLow = true
                        end
                        if ammoCount < (self.groupAmmo[z][i]["count"] * self.FullAmmoPercent) or ammoLow then
                            ammoFull = false
                        end
                    end
                else
                    self:T(self.UnitTable[z].UnitName.." does not use ammo.")
                end
            end
        end
    end
    return ammoLow, ammoFull
end

--- [Internal Call for rearm
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_CallForRearm(respawnCall)
    if respawnCall then 
        self:I("TACTICS: "..self.Groupname.." requesting respawn of rearm group.")
    else 
        self:I("TACTICS: "..self.Groupname.." is winchester.") 
    end

    self.IsWinchester = true

    --Manage rearming if able
    if self.AllowRearming and not self:Is("Retreating") then
        if self.RearmingGroupDespawnTimer and self.RearmingGroupDespawnTimer:IsRunning() then 
            self.RearmingGroupDespawnTimer:Stop() 
            self.RearmingGroupDespawnTimer = nil
        end
        --Dispatch ammo truck if available
        local coordGroup = self.Group:GetAverageCoordinate()
        if self.RearmGroup and self.RearmGroup:GetCoordinate() then
            self:I("TACTICS: Dispatching "..self.RearmGroup:GetName().." to rearm "..self.Groupname)
            if self.RearmGroupUseRoads then
                self.RearmGroup:RouteGroundOnRoad(coordGroup, self.RearmGroupSpeed, 1, self.RearmGroupFormation)
            else 
                self.RearmGroup:RouteGroundTo(coordGroup, self.RearmGroupSpeed, self.RearmGroupFormation, 1) 
            end
        elseif self.RearmTemplate and self.RearmSpawnCoord then
            --Spawn new if able and no truck is available
            local spawnIndex = math.random(9999)
            local rearmSpawn = SPAWN:NewWithAlias(self.RearmTemplate, self.RearmTemplate..spawnIndex)
            rearmSpawn:OnSpawnGroup(function(_grp)
                self.RearmGroup = _grp
                if self.RearmGroupUseRoads then
                    _grp:RouteGroundOnRoad(coordGroup, self.RearmGroupSpeed, 1, self.RearmGroupFormation)
                else 
                    _grp:RouteGroundTo(coordGroup, self.RearmGroupSpeed, self.RearmGroupFormation, 1) 
                end
                self:I("TACTICS: Spawned and dispatched ".._grp:GetName().." to rearm "..self.Groupname)
            end)
            rearmSpawn:SpawnFromCoordinate(self.RearmSpawnCoord)
        else
            self:I("TACTICS: "..self.Groupname.." does not have a rearming group assigned to it. They can mark but will remain stationary until rearmed.")
        end

        --Draw on map if able
        if self.RearmDrawing then
            if self.DrawDataR.DrawText then 
                trigger.action.removeMark(self.DrawDataR.DrawText)
            end
            if self.DrawDataR.DrawPoly then 
                trigger.action.removeMark(self.DrawDataR.DrawPoly)
            end

            self.DrawDataR.DrawText = coordGroup:TextToAll(self.DrawDataR.Text,self.DrawDataR.Coalition,self.DrawDataR.Color1,self.DrawDataR.Alpha1,self.DrawDataR.Color2,self.DrawDataR.Alpha2,self.DrawDataR.Font,false) 
            self.DrawDataR.DrawPoly = coordGroup:CircleToAll(self.DrawDataR.Radius,self.DrawDataR.Coalition,self.DrawDataR.Color1,self.DrawDataR.Alpha1,self.DrawDataR.Color2,self.DrawDataR.Alpha2/2,self.DrawDataR.Linetype,false)
        end

        --Group units up if spread out
        local unitList = self.Group:GetUnits()
        for i = 1,#unitList do
            local coordUnit = unitList[i]:GetCoordinate()
            if coordUnit:Get3DDistance(coordGroup) >= 300 then
                self.Group:RouteGroundTo(coordGroup)
                break
            end
        end

        self.IsRearming = true
        self:RequestRearming(self.RearmGroup)
        self.TimeRearmActive = true
        self.TimeRearmStamp = timer.getAbsTime()
    end
    self:Winchester()
    return self
end

--- [Internal RTB Rearm Group
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_RTBRearmGroup()
    if self.RearmGroup and self.RearmGroup:GetCoordinate() and self.RearmGroupBase and self.RearmGroupRTB then
        self:I("TACTICS: Sending "..self.RearmGroup:GetName().." back to base.")
        if self.RearmGroupUseRoads then 
            self.RearmGroup:RouteGroundOnRoad(self.RearmGroupBase, self.RearmGroupSpeed, 1, self.RearmGroupFormation)
        else 
            self.RearmGroup:RouteGroundTo(self.RearmGroupBase, self.RearmGroupSpeed, self.RearmGroupFormation, 1) 
        end
        if self.DespawnRearmingGroup and not self.RearmingGroupDespawnTimer then
            self:_RearmingGroupDespawn()
        end
    end
    return self
end

--- [Internal] Spot target
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_SpotTarget(_enemy,distance)
    self:T("TACTICS: "..self.Groupname.." detected "..tostring(_enemy:GetName()).." at a range of "..distance.."m. Current Tactical ROE: "..self.TacticalROE)
    if self.ManageAlarmState then self.Group:OptionAlarmStateRed() end
    --Attack
    if self.TacticalROE == "Attack" then
        self:AttackTarget(_enemy,distance)
    
    --Hold
    elseif self.TacticalROE == "Hold" then
        if distance <= self.HoldDistance then
            if self:Is("Travelling") or self:Is("Idle") then
                self.Group:RouteStop()
                self:StartHold()
            end
            --Deploy troops if able
            if not self.TroopsAttacking and self.TroopTransport and _enemy:GetCoordinate() then
                self:DropTroops(_enemy:GetCoordinate(),true)
            end
            self.TimeHoldActive = true
            self.TimeHoldStamp = timer.getAbsTime()
        end

    --Avoid
    elseif self.TacticalROE == "Avoid" then
        if distance <= self.AvoidDistance then
            self:AvoidTarget(_enemy,distance)
        end
    
    --Ignore
    else
        if self.ManageAlarmState then
            TIMER:New(function()
                if self.DefaultAlarmState == "Auto" then 
                    self.Group:OptionAlarmStateAuto()
                elseif self.DefaultAlarmState == "Red" then 
                    self.Group:OptionAlarmStateRed()
                elseif self.DefaultAlarmState == "Green" then 
                    self.Group:OptionAlarmStateGreen()
                end
            end):Start(self.DetectionRate-1)
        end
    end
    
    if self.SupportLevel <= 1 and not self.TimeSupportActive and self.AllowSupportRequests then
        self:RequestSupport(_enemy:GetCoordinate())
    end
    return self
end

--- [Internal Attack a target
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:AttackTarget(_enemy,distance)
    local coordGroup = self.Group:GetAverageCoordinate()
    local coordEnemy = nil
    local hdgEnemy = 0
    local className = _enemy:GetClassName()
    if className == "COORDINATE" then
        self:T("TACTICS: "..self.Groupname.." is attacking a provided coordinate "..distance.."m away.")
        coordEnemy = _enemy
    elseif not className then 
        self:E("TACTICS ERROR: The provided enemy is not a valid Core.COORDINATE or Wrapper.POSITIONABLE object.")
    else        
        self:T("TACTICS: "..self.Groupname.." is attacking "..tostring(_enemy:GetName()).." "..distance.."m away.")
        coordEnemy = _enemy:GetCoordinate()
    end

    if coordEnemy and coordGroup then
        hdgEnemy = coordGroup:HeadingTo(coordEnemy)
        local coordTargetDest = nil
        local skipNewDest = false
        if self.attackLastCoord and self.attackLastCoord:Get3DDistance(coordEnemy) <= self.LastTargetThreshold then 
            skipNewDest = true 
            local tempDist = self.attackLastCoord:Get3DDistance(coordEnemy)
            self:T("TACTICS: "..self.Groupname.."'s target is only "..tempDist.."m away from where it was last. Threshold set to "..self.LastTargetThreshold)
        end

        --Get attack move-to position
        if distance > 25 then
            local hdgTgt = coordGroup:HeadingTo(coordEnemy)
            coordTargetDest = coordEnemy:Translate(-self.AttackPositionDist,hdgTgt,false,false)          
            if distance < self.AttackPositionDist+20 then 
                coordTargetDest = coordEnemy:Translate(-(distance/2),hdgTgt,false,false) 
                skipNewDest = false
            end
            local booIsFlat = false
            local checkFlat = 0
            if not skipNewDest then
                while not booIsFlat and checkFlat < 10 do
                    checkFlat = checkFlat + 1
                    if coordTargetDest:IsInFlatArea(25, self.InclineLimit) and not coordTargetDest:IsSurfaceTypeWater() and not coordTargetDest:IsSurfaceTypeShallowWater() then
                        if distance < self.CombatDistance then
                            self.Group:RouteGroundTo(coordTargetDest, self.AttackSpeed, self.AttackFormation, 1)
                        else
                            if self.AttackFarUsesRoads then self.Group:RouteGroundOnRoad(coordTargetDest, self.AttackSpeedFar, 1, self.AttackFormationFar)
                            else self.Group:RouteGroundTo(coordTargetDest, self.AttackSpeedFar, self.AttackFormationFar, 1) end
                        end
                        booIsFlat = true
                        checkFlat = 10
                    else
                        coordTargetDest:Translate(25,(hdgTgt+90) % 360 ,false,true)
                    end
                end
                if not booIsFlat then
                    coordTargetDest = coordEnemy:Translate(-self.AttackPositionDist,hdgTgt,false,false)
                    if distance < self.AttackPositionDist+20 then coordTargetDest = coordEnemy:Translate(-(distance/2),hdgTgt,false,false) end
                    if distance < self.CombatDistance then
                        self.Group:RouteGroundTo(coordTargetDest, self.AttackSpeed, self.AttackFormation, 1)
                    else
                        if self.AttackFarUsesRoads then self.Group:RouteGroundOnRoad(coordTargetDest, self.AttackSpeedFar, 1, self.AttackFormationFar)
                        else self.Group:RouteGroundTo(coordTargetDest, self.AttackSpeedFar, self.AttackFormationFar, 1) end
                    end
                end
            end
        else
            --Move both groups toward a convergence point
            if className == "GROUP" or className == "UNIT" then
                self:T("TACTICS: "..self.Groupname.." and "..tostring(_enemy:GetName()).." are too close without engaging (>25m). Attempting to move both groups.")
                local coordTargetDest = coordEnemy:Translate(25,90,false,false) 
                if not coordTargetDest:IsInFlatArea(25, self.InclineLimit) or coordTargetDest:IsSurfaceTypeWater() or coordTargetDest:IsSurfaceTypeShallowWater() then
                    coordTargetDest = coordEnemy:Translate(25,-90 ,false,false)
                end
                if not coordTargetDest:IsInFlatArea(25, self.InclineLimit) or coordTargetDest:IsSurfaceTypeWater() or coordTargetDest:IsSurfaceTypeShallowWater() then
                    coordTargetDest = coordEnemy:Translate(25,0 ,false,false)
                end
                if not coordTargetDest:IsInFlatArea(25, self.InclineLimit) or coordTargetDest:IsSurfaceTypeWater() or coordTargetDest:IsSurfaceTypeShallowWater() then
                    coordTargetDest = coordEnemy:Translate(25,180 ,false,false)
                end
                self.Group:RouteGroundTo(coordTargetDest, self.AttackSpeed, self.AttackFormation, 1)
                _enemy:RouteGroundTo(coordTargetDest, self.AttackSpeed, self.AttackFormation, 1)
            end
        end
        
        --Deploy Troops If Able
        if not self.TroopsAttacking and self.TroopTransport and distance <= self.TroopAttackDist then
            self:T("TACTICS: "..self.Groupname.." is deploying troops to attack "..tostring(_enemy:GetName()))
            self.Group:RouteStop()
            self:DropTroops(coordEnemy,true)
            TIMER:New(function()
                self.Group:RouteResume()
            end):Start(5)
        end

        self.attackLastCoord = coordEnemy
        self.TimeAttackActive = true
        self.TimeAttackStamp = timer.getAbsTime()
        self:AttackManeuver(_enemy,distance,hdgEnemy)
        if not self:Is("Attacking") then self:StartAttack(_enemy,distance,hdgEnemy) end
    end
    return self
end

--- [Internal Avoid target
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:AvoidTarget(_enemy,distance)
    local coordGroup = self.Group:GetAverageCoordinate()
    local coordEnemy = nil
    local className = _enemy:GetClassName()
    if className == "COORDINATE" then
        self:T("TACTICS: "..self.Groupname.." is avoiding a provided coordinate "..distance.."m away.")
        coordEnemy = _enemy
    elseif not className then 
        self:E("TACTICS ERROR: The provided enemy is not a valid Core.COORDINATE or Wrapper.POSITIONABLE object.")
    else        
        self:T("TACTICS: "..self.Groupname.." is avoiding "..tostring(_enemy:GetName()).." "..distance.."m away.")
        coordEnemy = _enemy:GetCoordinate()
    end
    local isAvoiding = false

    if coordGroup and coordEnemy then
        self:T("TACTICS: "..self.Groupname.." will try to avoid "..tostring(_enemy:GetName()))
        for i = 1,100 do
            local hdgAvoid = coordEnemy:HeadingTo(coordGroup)
            if self.AvoidAzimuthMax then 
                hdgAvoid = ((hdgAvoid - self.AvoidAzimuthMax) + (math.random(self.AvoidAzimuthMax*2))) % 360
                if hdgAvoid < 1 then hdgAvoid = hdgAvoid + 360 end
            end
            local avoidPoint = coordGroup:Translate(self.AvoidDistance, hdgAvoid, false, false)
            if avoidPoint:IsInFlatArea(25, self.InclineLimit) and not avoidPoint:IsSurfaceTypeWater() and not avoidPoint:IsSurfaceTypeShallowWater() then
                isAvoiding = true
                if self.AvoidUseRoads then
                    self.Group:RouteGroundOnRoad(avoidPoint, self.AvoidSpeed, 1, self.AvoidFormation)
                    self.avoidDest = avoidPoint
                    self.TimeAvoidActive = true
                    self.TimeAvoidStamp = timer.getAbsTime()
                else
                    self.Group:RouteGroundTo(avoidPoint, self.AvoidSpeed, self.AvoidFormation, 1)
                    self.avoidDest = avoidPoint
                    self.TimeAvoidActive = true
                    self.TimeAvoidStamp = timer.getAbsTime()
                end
                if self:Is("Travelling") or self:Is("Idle") then self:StartAvoid() end
                break
            end
        end
    end
    if not isAvoiding then
        self:E("TACTICS ERROR: "..self.Groupname.." tried to avoid ".._enemy:GetName().." but could not find a destination with suitable terrain after 100 attempts.")
    end
end

--- [Internal Drop troops
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:DropTroops(_targetCoord,_attacking,_limit)
    self:T("TACTICS: "..self.Groupname.." called dropTroops. Attacking = "..tostring(_attacking))
    local coordGroup = self.Group:GetCoordinate()
    local hdgGroup = self.Group:GetHeading()

    --Check if enemy is close enough to attack
    local distTarget = _targetCoord:Get3DDistance(coordGroup)
    local hdgTarget = nil
    local coordAttack = nil

    if distTarget <= self.TroopAttackDist and _attacking then
        self:T("TACTICS: "..self.Groupname.." dropped troops are in range and will attack the target.")
        hdgTarget = coordGroup:HeadingTo(_targetCoord)
        coordAttack = coordGroup:Translate(distTarget-20,hdgTarget,false,false)
    elseif _attacking then
        self:T("TACTICS: "..self.Groupname.." dropped troops are too far from the target and will disperse instead.")
    else
        coordAttack = _targetCoord
    end
    
    --Get spawn parameters
    local intSpawnIndex = math.random(1,9999)
    local nameDroppedTroops = self.TroopTemplate.."_"..self.Groupname..intSpawnIndex
    local troopsOffset = math.random(self.TroopDismountDistMin,self.TroopDismountDistMax)
    local directionX = math.random(1,100)
    if directionX > 50 then
    troopsOffset = -troopsOffset
    end
    
    --Set up troop spawn
    local spawnDropTroops = SPAWN:NewWithAlias(self.TroopTemplate, nameDroppedTroops):InitGroupHeading(hdgGroup)
    spawnDropTroops:OnSpawnGroup(function(_troops)
        local coordMoveTo = nil
        if coordAttack then coordMoveTo = coordAttack:GetCoordinate() end
        if coordMoveTo and _attacking then
            local headingFlank = 0
            local checkFlank = math.random(0,2)
            if checkFlank == 0 then headingFlank = hdgTarget-90 elseif checkFlank == 2 then headingFlank = hdgTarget+90 end
            if headingFlank < 0 then headingFlank = headingFlank+360 elseif headingFlank > 360 then headingFlank = headingFlank-360 end
            if checkFlank ~= 1 then
                coordMoveTo:Translate(100,headingFlank,false,true)
                coordMoveTo:Translate(40,hdgTarget,false,true)
            end
        elseif _attacking then
            coordMoveTo = _troops:GetUnit(1):GetOffsetCoordinate(0,0,troopsOffset)
        elseif not _attacking then 
            coordMoveTo = _targetCoord
        end
        _troops:RouteGroundTo(coordMoveTo,self.TroopMoveSpeed,self.TroopFormation)
        if _attacking then
            table.insert(self.AttackingTroops,_troops)
            self.TroopsAttacking = true
        else
            table.insert(self.DeployedTroops,_troops)
        end
        self:T("TACTICS: "..self.Groupname.." deployed ".._troops:GetName())
    end)
    
    --Timer to drop troops
    local timerDropTroops = TIMER:New(function()
        coordGroup = self.Group:GetCoordinate()
        local unitTable = self.Group:GetUnits()
        local dropAmount = #unitTable
        if _limit then dropAmount = _limit end
        for i = 1, dropAmount do
            local coordDrop = unitTable[i]:GetOffsetCoordinate(-10,0,0)
            spawnDropTroops:SpawnFromCoordinate(coordDrop)
        end   
        self:TroopsDropped(_targetCoord,_attacking) 
    end)
    timerDropTroops:Start(5)
    return self
end

--- [Internal Return troops
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_ReturnTroops()
    self:I("TACTICS: "..self.Groupname.." attempting to recover deployed troops.")
    self.Group:RouteStop()

    local homeCoord = self.Group:GetAverageCoordinate()       
    if not homeCoord then homeCoord = self.Group:GetCoordinate() end
    local countTroops = 0

    --Function to see if all troops have boarded
    local function checkAllReturned()
        if not self:Is("Dead") then
            self:T("TACTICS: "..self.Groupname.."'s troops remaining to be extracted = "..tostring(countTroops))
            if countTroops == 0 then
                self.AttackingTroops = {}
                self.TroopsAttacking = false
                self:I("TACTICS: "..self.Groupname.." picked up all deployed troops and will resume tasking.")
                local isWinchester, isFull = self:CheckAmmo()
                if isWinchester and self.AllowRearming and not self.IsRearming then
                    self:_CallForRearm()
                end
                if self:Is("Retreating") then
                    if self.RetreatOnRoads then
                        self.Group:RouteGroundOnRoad(self.retreatDestination, self.RetreatSpeed, 1, self.RetreatFormation)
                        self.TimeRetreatActive = true
                        self.TimeRetreatStamp = timer.getAbsTime()
                    else
                        self.Group:RouteGroundTo(self.retreatDestination, self.a, self.RetreatFormation, 1)
                        self.TimeRetreatActive = true
                        self.TimeRetreatStamp = timer.getAbsTime()
                    end
                elseif not self.IsRearming then
                    if self.Destination then
                        if self:Is("Engaging") then self:EngageToTravel() 
                        elseif self:Is("Attacking") then self:AttackToTravel()
                        elseif self:Is("Holding") then self:HoldToTravel()
                        elseif self:Is("Idle") then self:StartTravel() end
                        self:_InitiateTravel()
                    else
                        if self:Is("Engaging") then self:EngageToIdle()
                        elseif self:Is("Holding") then self:HoldToIdle()
                        elseif self:Is("Attacking") then  self:AttackToIdle()end
                    end
                end
                self:TroopsReturned()
            end
        end
    end

    --Send troops back to group position
    if #self.AttackingTroops == 0 then
        self:I("TACTICS: All of "..self.Groupname.."'s troops are KIA!")
        checkAllReturned()
    else
        for i = #self.AttackingTroops,1,-1 do
            local troopGroup = self.AttackingTroops[i]
            if troopGroup:GetCoordinate() then
                self:T("TACTICS: "..self.Groupname.." is recovering "..troopGroup:GetName())
                local despawn = {}
                troopGroup:RouteGroundTo(homeCoord,self.TroopMoveSpeed,self.TroopFormation)

                --Check to despawn troops
                local timerLimit = math.ceil(self.ExtractTimeLimit/20)
                despawn.Timer = TIMER:New(function()
                    timerLimit = timerLimit - 1
                    self:T("TACTICS: "..troopGroup:GetName().." recovery limit check = "..timerLimit.."/"..math.ceil(self.ExtractTimeLimit/20))
                    local checkCoord = troopGroup:GetCoordinate()
                    local checkHome = self.Group:GetCoordinate()
                    if checkCoord and checkHome then
                        local distHome = checkCoord:Get3DDistance(homeCoord)
                        if distHome <= 25 then
                            despawn.Timer:Stop()
                            troopGroup:Destroy()
                            countTroops = countTroops - 1
                            checkAllReturned()
                        end
                    else
                        despawn.Timer:Stop()
                        countTroops = countTroops - 1
                        checkAllReturned()
                    end
                    if despawn.Timer:IsRunning() and timerLimit <= 0 then
                        despawn.Timer:Stop()
                        troopGroup:Destroy()
                        countTroops = countTroops - 1
                        checkAllReturned()
                    end
                end)
                despawn.Timer:Start(20,20)
            else
                table.remove(self.AttackingTroops,i)
            end
        countTroops = #self.AttackingTroops
        end
    end

    --Backup in the event of a failure
    TIMER:New(function()
        if countTroops > 0 then
            for i = 1, #self.AttackingTroops do
                self.AttackingTroops[i]:Destroy()
            end
            countTroops = 0
            checkAllReturned()
        end
    end):Start(self.ExtractTimeLimit+5)
    return self
end

--- [Internal Exctract Troops
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:ExtractTroops()
    if not self:Is("Retreating") then
        self:I("TACTICS: "..self.Groupname.." attempting to extract troops from the field.")
        self.Group:RouteStop()

        local homeCoord = self.Group:GetAverageCoordinate()   
        if not homeCoord then homeCoord = self.Group:GetCoordinate() end
        local countTroops = 0

        --Function to see if all troops have boarded
        local function checkAllReturned()
            self:T("TACTICS: "..self.Groupname.."'s troops remaining to be extracted = "..tostring(countTroops))
            if countTroops == 0 then
                self.DeployedTroops = {}
                self:I("TACTICS: "..self.Groupname.." picked up all deployed troops and will resume tasking.")
                if self:Is("Retreating") then
                    if self.RetreatOnRoads then
                        self.Group:RouteGroundOnRoad(self.retreatDestination, self.RetreatSpeed, 1, self.RetreatFormation)
                        self.TimeRetreatActive = true
                        self.TimeRetreatStamp = timer.getAbsTime()
                    else
                        self.Group:RouteGroundTo(self.retreatDestination, self.a, self.RetreatFormation, 1)
                        self.TimeRetreatActive = true
                        self.TimeRetreatStamp = timer.getAbsTime()
                    end
                elseif not self.IsRearming then
                    if self.Destination then
                        if self:Is("Engaging") then self:EngageToTravel() 
                        elseif self:Is("Attacking") then self:AttackToTravel()
                        elseif self:Is("Idle") then self:StartTravel() end
                        self:_InitiateTravel()
                    else
                        if self:Is("Engaging") then self:EngageToIdle() 
                        elseif self:Is("Attacking") then  self:AttackToIdle()end
                    end
                end
                self:TroopsExtracted()
            end
        end

        --Send troops back to group position
        if #self.DeployedTroops == 0 then
            self:I("TACTICS: All of "..self.Groupname.."'s deployed troops are KIA!")
            checkAllReturned()
        else
            for i = #self.DeployedTroops,1,-1 do
                local troopGroup = self.DeployedTroops[i]
                if troopGroup:GetCoordinate() then
                    local despawn = {}
                    troopGroup:RouteGroundTo(homeCoord,self.TroopMoveSpeed,self.TroopFormation)

                    --Check to despawn troops
                    local timerLimit = math.ceil(self.ExtractTimeLimit/20)
                    despawn.Timer = TIMER:New(function()
                        timerLimit = timerLimit - 1
                        local checkCoord = troopGroup:GetCoordinate()
                        local checkHome = self.Group:GetCoordinate()
                        if checkCoord and checkHome then
                            local distHome = checkCoord:Get3DDistance(homeCoord)
                            if distHome <= 25 then
                                despawn.Timer:Stop()
                                troopGroup:Destroy()
                                countTroops = countTroops - 1
                                checkAllReturned()
                            end
                        else
                            despawn.Timer:Stop()
                            countTroops = countTroops - 1
                            checkAllReturned()
                        end
                        if despawn.Timer:IsRunning() and timerLimit <= 0 then
                            despawn.Timer:Stop()
                            troopGroup:Destroy()
                            countTroops = countTroops - 1
                            checkAllReturned()
                        end
                    end)
                    despawn.Timer:Start(20,20)
                else
                    table.remove(self.DeployedTroops,i)
                end
            countTroops = #self.DeployedTroops
            end
        end

        --Backup in the event of a failure
        TIMER:New(function()
            if countTroops > 0 then
                for i = 1, #self.DeployedTroops do
                    self.DeployedTroops[i]:Destroy()
                end
                countTroops = 0
                checkAllReturned()
            end
        end):Start(self.ExtractTimeLimit+5)
        return self
    else
        self:E("TACTICS ERROR: "..self.Groupname.." cannot extract troops while retreating.")
    end
end

--- [Internal Contact marks
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:_ContactMark(_coord,_type)

    --Get coordinates for the correct shape
    local coordQuad1 = _coord:Translate(200,359,false,false)
    local coordQuad2 = _coord:Translate(200,1,false,false)
    local coordQuad3 = _coord:Translate(200,120,false,false)
    local coordQuad4 = _coord:Translate(200,240,false,false)
    if _type == 1 then
        coordQuad1 = _coord:Translate(200,179,false,false)
        coordQuad2 = _coord:Translate(200,181,false,false)
        coordQuad3 = _coord:Translate(200,300,false,false)
        coordQuad4 = _coord:Translate(200,60,false,false)
    end
    if _type == 2 then
        coordQuad1 = _coord:Translate(200,0,false,false)
        coordQuad2 = _coord:Translate(200,90,false,false)
        coordQuad3 = _coord:Translate(200,180,false,false)
        coordQuad4 = _coord:Translate(200,270,false,false)
    end

    --Get coalition params
    local coalitionNum = 2
    local coalitionColorA = {1,0,0}
    local coalitionColorB = {0.5,0,0}
    if self.groupCoalition == coalition.side.RED then
        coalitionColorA = {0,0,1}
        coalitionColorB = {0,0,0.5}
        coalitionNum = 1
    end

    --Get timeout values
    local timeoutFresh = self.EngageDrawingFresh
    local timeoutStale = self.EngageDrawingStale
    if _type == 2 then
        timeoutFresh = self.DetectionRate-1
        timeoutStale = self.EnemySpotStale
    end
    
    --Draw marker
    if self.markSpot then trigger.action.removeMark(self.markSpot) end
    self.markSpot = coordQuad1:QuadToAll(coordQuad2, coordQuad3, coordQuad4, coalitionNum,coalitionColorA,1,coalitionColorA,0.15,1,true)
    if self.markSpotTimer and self.markSpotTimer:IsRunning() then
        self.markSpotTimer:Stop()
        self.markSpotTimer = nil
    end
    self.markSpotTimer = TIMER:New(function() 
        trigger.action.removeMark(self.markSpot) 
        self.markSpot = coordQuad1:QuadToAll(coordQuad2, coordQuad3, coordQuad4, coalitionNum,coalitionColorB,1,coalitionColorB,0.15,3,true)
        self.markSpotTimer = nil
        self.markSpotTimer = TIMER:New(function() 
            trigger.action.removeMark(self.markSpot) 
            self.markSpot = nil
            self.markSpotTimer = nil
        end):Start(timeoutStale)
    end):Start(timeoutFresh)
    return self
end

--- [Internal Request Support
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:RequestSupport(target)
    local targetName = "nil target"
    local coordGroup = self.Group:GetCoordinate()
    local coordTarget = coordGroup
    local unitTarget = nil
    if target and target:GetClassName() == "COORDINATE" then
        coordTarget = target
    elseif target and target:GetClassName() == "UNIT" then
        coordTarget = target:GetCoordinate()
        unitTarget = target
        targetName = target:GetName()
    end
    self:T({"TACTICS: "..self.Groupname.." requested support.","Target = "..tostring(targetName)})
    if coordGroup then
        self:T2("TACTICS: "..self.Groupname.." will search for nearby friendlies.")
        local countGroups = 0
        local friendlyTable = TACTICS_UTILS.GroupsRed
        if self.groupCoalition == coalition.side.BLUE then friendlyTable = TACTICS_UTILS.GroupsBlue end
        for i = 1,#friendlyTable do
            self:T2("TACTICS: Group table index "..i.." for coalition "..tostring(self.groupCoalition))
            local coordFriendly = friendlyTable[i].Group:GetCoordinate()
            if coordFriendly then
                self:T({"TACTICS: "..self.Groupname.." is checking if "..friendlyTable[i].Groupname.." can provide support.",RespondToSupport = friendlyTable[i].RespondToSupport, State = friendlyTable[i]:GetState()})
                if friendlyTable[i].Groupname ~= self.Groupname and friendlyTable[i].RespondToSupport then
                    if friendlyTable[i]:Is("Idle") or friendlyTable[i]:Is("Travelling") then
                        local distFriendly = coordFriendly:Get3DDistance(coordGroup)
                        self:T("TACTICS: "..friendlyTable[i].Groupname.." is "..distFriendly.."m / "..self.SupportRadius.."m from "..self.Groupname)
                        if distFriendly <= self.SupportRadius then
                            local distTarget = coordFriendly:Get3DDistance(coordTarget)
                            friendlyTable[i]:AttackTarget(coordTarget,distTarget)
                            table.insert(self.supportTable,friendlyTable[i])
                            countGroups = countGroups + 1
                            self:I("TACTICS: "..friendlyTable[i].Groupname.." is moving to support "..self.Groupname)
                            friendlyTable[i]:Supporting(self.Group,coordTarget,self.MessageCallsign)
                            if self.SupportGroupLimit and countGroups >= self.SupportGroupLimit then
                                self:I("TACTICS: "..self.Groupname.." reached the support group limit: "..self.SupportGroupLimit)
                                break
                            end
                        end
                    end
                end
            end
        end
        self.TimeSupportActive = true
        self.TimeSupportStamp = timer.getAbsTime()
        self:SupportRequested(coordTarget,unitTarget)
    end
    return self
end

--- [Internal Check Unit Health
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:CheckUnitLife()
    local unitsRemain = 0
    local willRecover = false
    local unitList = self.Group:GetUnits()
    if unitList and #unitList > 0 then
        self:T({"TACTICS: Checking health of all units in "..self.Groupname})
        for i = 1,#unitList do
            unitsRemain = unitsRemain + 1
            local unitLife = unitList[i]:GetLifeRelative()
            self:T({"TACTICS: "..unitList[i]:GetName(),"RelativeLife = "..unitLife.."/"..self.AbandonHealth,GroupUnitCount = unitsRemain})
            if unitLife < self.AbandonHealth then
                unitsRemain = unitsRemain - 1
                if self.AllowSelfRecover then willRecover = true end                 
                self:T({"TACTICS: "..unitList[i]:GetName().." is below the life threshold. Crew will abandon vehicle.",GroupUnitCount = unitsRemain,SelfRecover = willRecover})
                if self:Is("Retreating") then 
                    self.Group:RouteStop()
                    TIMER:New(function()
                        self:AbandonVehicle(unitList[i])
                    end):Start(5)
                else
                    self:AbandonVehicle(unitList[i])
                end
            end
        end
    end
    return unitsRemain,willRecover
end

--- [Internal Abandon vehicle
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:AbandonVehicle(Unit)
    local coordUnit = Unit:GetCoordinate()
    local headingUnit = Unit:GetHeading()
    local healthUnit = Unit:GetLife()
    local nameUnit = Unit:GetName()
    local countryUnit = Unit:GetCountry()
    local typeUnit = Unit:GetTypeName()
    local crewPosition = coordUnit:Translate(5,(headingUnit + 90)%360,false,false)
    Unit:Destroy()
    self:T({"TACTICS: "..nameUnit.." is being abandoned."})
    self:_DeadResponse(false)

    --Crew spawning logic
    local spawnCrew = SPAWN:NewWithAlias(self.CrewTemplate,"Crew_"..nameUnit)
    spawnCrew:OnSpawnGroup(function(_grp)
        self:T({"TACTICS: ".._grp:GetName().." spawned. Checking next step.", CanRecover = self.AllowSelfRecover})
        local canRecover = false
        local crewName = _grp:GetName()

        --Check if group can self recover
        if self.Group:GetCoordinate() and self.AllowSelfRecover then
            local groupUnits = self.Group:GetUnits()
            local closestDist = 99999999
            local closestCoord = nil
            local closestUnit = nil
            local closestUnitName = "invalid"
            for i = 1,#groupUnits do
                local coordNearby = groupUnits[i]:GetCoordinate()
                local distNearby = coordNearby:Get3DDistance(crewPosition)
                if distNearby < closestDist then
                    closestDist = distNearby
                    closestCoord = coordNearby
                    closestUnit = groupUnits[i]
                    canRecover = true
                end
            end
            if canRecover then
                self:T({"TACTICS: "..crewName.." will move to "..closestUnitName.." for recovery."})
                _grp:RouteGroundTo(closestCoord,20,"Diamond",1)
                local tbl = {}
                tbl.recoverTime = TIMER:New(function()
                    local coordGrp = _grp:GetCoordinate()
                    local coordRecoverUnit = closestUnit:GetCoordinate()
                    if coordGrp and coordRecoverUnit then 
                        local distGrp = coordGrp:Get3DDistance(closestCoord)
                        self:T2({"TACTICS: "..crewName.." is "..distGrp.."/25m from "..closestUnitName})
                        if distGrp <= 25 then
                            self:T({"TACTICS: "..crewName.." is within 25m of "..closestUnitName.." and will board the vehicle.",Distance = distGrp})
                            _grp:Destroy()
                            self:CrewRecovered(closestUnit,nameUnit)
                            tbl.recoverTime:Stop()
                            if self.TroopsAttacking then
                                self:_ReturnTroops()
                            elseif self.Destination and not self:Is("Retreating") then
                                self:EngageToTravel()
                                self:_InitiateTravel()
                            elseif self:Is("Retreating") then
                                self.Group:RouteResume()
                            else
                                self:EngageToIdle()
                            end
                        end
                    else
                        self:T({"TACTICS: "..crewName.." was destroyed."})
                        tbl.recoverTime:Stop()
                        if self.TroopsAttacking then
                            self:_ReturnTroops()
                        elseif self.Destination and not self:Is("Retreating") then
                            self:EngageToTravel()
                            self:_InitiateTravel()
                        elseif self:Is("Retreating") then
                            self.Group:RouteResume()
                        else
                            self:EngageToIdle()
                        end
                    end
                end)
                tbl.recoverTime:Start(20,20)
            end
            return self
        end

        --Run away and dispatch recovery vehicle if avail
        if not canRecover then
            local hdgEscape = math.random(90,270)
            if self:Is("Retreating") then hdgEscape = math.random(270,450) end
            hdgEscape = (hdgEscape + headingUnit)%360
            self:T({"TACTICS: "..crewName.." will run "..self.AbandonDistance.."m away at a heading of "..hdgEscape})
            local coordEscape = coordUnit:Translate(hdgEscape,self.AbandonDistance)
            _grp:RouteGroundTo(coordEscape,20,"Diamond",1)
            if self.RecoveryVehicle and self.RecoverySpawnZone then
                self:T({"TACTICS: "..crewName.." will request a recovery vehicle pickup from their destination."})
                local spawnRecovery = SPAWN:NewWithAlias(self.RecoveryVehicle,"Recovery_"..nameUnit)
                spawnRecovery:OnSpawnGroup(function(_veh)
                    local nameRecovery = _veh:GetName()
                    local isRTB = false
                    if self.RecoveryUseRoads then 
                        _veh:RouteGroundOnRoad(coordEscape, self.RecoverySpeed, 1, self.RecoveryFormation)
                    else
                        _veh:RouteGroundTo(coordEscape,self.RecoverySpeed,self.RecoveryFormation,1)
                    end
                    local tbl = {}
                    tbl.recoverTimer = TIMER:New(function()
                        local coordVeh = _veh:GetCoordinate()
                        local coordGrp = _grp:GetCoordinate()
                        if coordVeh then
                            if not isRTB then
                                if coordGrp then
                                    local distRecover = coordVeh:Get3DDistance(coordGrp)
                                    self:T2({"TACTICS: "..nameRecovery.." is "..distRecover.."/25m from "..crewName})
                                    if distRecover < 25 then
                                        self:T({"TACTICS: "..crewName.." is within 25m of "..nameRecovery.." and will board the vehicle.",Distance = distRecover})
                                        _grp:Destroy()
                                        self:CrewRecovered(_veh,nameUnit)
                                        isRTB = true
                                        if self.RecoveryUseRoads then 
                                            _veh:RouteGroundOnRoad(self.RecoverySpawnZone:GetCoordinate(), self.RecoverySpeed, 1, self.RecoveryFormation)
                                        else
                                            _veh:RouteGroundTo(self.RecoverySpawnZone:GetCoordinate(),self.RecoverySpeed,self.RecoveryFormation,1)
                                        end
                                    end
                                else
                                    self:T({"TACTICS: "..crewName.." was destroyed. "..nameRecovery.." is RTB."})
                                    isRTB = true
                                    if self.RecoveryUseRoads then 
                                        _veh:RouteGroundOnRoad(self.RecoverySpawnZone:GetCoordinate(), self.RecoverySpeed, 1, self.RecoveryFormation)
                                    else
                                        _veh:RouteGroundTo(self.RecoverySpawnZone:GetCoordinate(),self.RecoverySpeed,self.RecoveryFormation,1)
                                    end
                                end
                            else
                                if _veh:IsAnyInZone(self.RecoverySpawnZone) then
                                    self:T({"TACTICS: "..nameRecovery.." returned to base and will despawn."})
                                    _veh:Destroy()
                                    tbl.recoverTimer:Stop()
                                end
                            end
                        else
                            tbl.recoverTimer:Stop()
                        end
                    end)
                    tbl.recoverTimer:Start(10,10)
                    self:T({"TACTICS: "..nameRecovery.." spawned and is moving to recover "..crewName,UseRoads = self.RecoveryUseRoads,Speed = self.RecoverySpeed,Formation = self.RecoveryFormation})
                end)
                spawnRecovery:SpawnInZone(self.RecoverySpawnZone,true)                   
            end
        end
    end)
    spawnCrew:SpawnFromCoordinate(crewPosition)

    --New static spawn
    self:T({"TACTICS: Replacing "..nameUnit.." with a static object."})
    local vec2Unit = coordUnit:GetVec2()
    local staticInfo = {
        ["heading"] = headingUnit * (math.pi*2) / 360,
        ["Country"] = countryUnit,
        ["y"] = vec2Unit.y, 
        ["x"] = vec2Unit.x, 
        ["name"] = nameUnit.."_Abandoned",
        ["category"] = "Ground Identifiable",
        ["type"] = typeUnit,
        ["dead"] = false,
        --["livery_id"] = SaveStatics[k]["livery_id"]
    }
    coalition.addStaticObject(countryUnit, staticInfo)
    if self.SmokeAbandoned then 
        coordUnit:BigSmokeSmall(0.01) 
        TIMER:New(function()
            coordUnit:StopBigSmokeAndFire()
        end):Start(self.StaticSmokeTimeout)
    end
    self:Abandoned(coordUnit,nameUnit,typeUnit)
end


--------[USER METHODS]---------

--- [User] Find a group by name
-- @param #TACTICS self
-- @param #string Groupname Name to find
-- @return Wrapper.Group#GROUP Group found
function TACTICS:FindByName(Groupname)
    for i = 1,#TACTICS_UTILS.GroupsRed do
        if TACTICS_UTILS.GroupsRed[i].Groupname == Groupname then
            return TACTICS_UTILS.GroupsRed[i]
        end
    end
    for i = 1,#TACTICS_UTILS.GroupsBlue do
        if TACTICS_UTILS.GroupsBlue[i].Groupname == Groupname then
            return TACTICS_UTILS.GroupsBlue[i]
        end
    end
    BASE:E("TACTICS ERROR: Could not find a group named "..Groupname.." with Tactics capabilities enabled.")
    return nil
end

--- [User] Get Group Name
-- @param #TACTICS self
-- @return #string Name Name of the group
function TACTICS:GetName()
    return self.Groupname
end


--- [User] Travel To: Assigns a destination for the group to make its way to
-- @param #TACTICS self
-- @param #boolean UseRoads Set to true to use road connections
-- @param Core.Point#COORDINATE ToCoordinate Coordinate to go to
-- @param #number Speed Speed to set on the group
-- @param #string Formation Formation to be used
-- @param #number DelaySeconds Delay in seconds
-- @param #function WaypointFunction Function to execute at a waypoint
-- @param #table WaypointFunctionArguments Arguments to be passed to the prior function
-- @return #TACTICS self
function TACTICS:TravelTo(UseRoads, ToCoordinate, Speed, Formation, DelaySeconds, WaypointFunction, WaypointFunctionArguments)
    if not self:Is("Dead") then
        self.Destination = ToCoordinate
        self.travelToStored = {UseRoads = UseRoads, ToCoordinate = ToCoordinate, Speed = Speed, Formation = Formation, DelaySeconds = DelaySeconds, WaypointFunction = WaypointFunction, WaypointFunctionArguments = WaypointFunctionArguments}
        if self:Is("Idle") or self:Is("Travelling") then
            self:_InitiateTravel()
        end
    end
    return self
end


--- [User] Stop Travel
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:StopTravel()
    if not self:Is("Dead") then
        if self:Is("Travelling") then
            self.Group:RouteStop()
            self:T("TACTICS: "..self.Groupname.." was forced to stop travelling.")
            self:EndTravel(self.Group:GetAverageCoordinate(), self.Destination)
            self.TimeTravelActive = false
            self.Destination = nil
            self.travelToStored = nil
        else
            self.Destination = nil
            self.travelToStored = nil
            self:T("TACTICS: Removing travel to from "..self.Groupname.."'s queue.")
        end
    end
    return self
end

--- [User] Set tactical ROE
-- @param #TACTICS self
-- @param #string rtype Type or ROE, can be "Ignore" or  "Attack" or "Hold" or "Avoid" 
-- @return #TACTICS self
function TACTICS:SetTacticalROE(rtype)
    if rtype == "Ignore" or rtype == "Attack" or rtype == "Hold" or rtype == "Avoid" then
        self.TacticalROE = rtype
    else
        self:E("TACTICS ERROR: "..tostring(rtype).." is not a valid TacticalROE! Please enter one of the following: 'Attack' | 'Hold' | 'Avoid' | 'Ignore'")
    end
    return self
end

--- [User] Enable/Disable Detection
-- @param #TACTICS self
-- @param #boolean OnOff
-- @param Core.Zone#ZONE FilterZone
-- @param #string FilterType
-- @return #TACTICS self
function TACTICS:DetectionEnabled(OnOff,FilterZone,FilterType)
    if OnOff == true then
        self.UseDetection = true
        self.TimeDetectionActive = true
    else
        self.UseDetection = false
        self.TimeDetectionActive = false
    end
    if FilterZone then self.FilterDetectionZones = FilterZone end
    if FilterType then self.FilterEnemyType = FilterType end
    return self
end

--- [User] Enable/Disable Rearming
-- @param #TACTICS self
-- @param #boolean OnOff
-- @param #number LowPercent
-- @param #string FullPercent
-- @param #boolean RearmGroup
-- @param Core.Point#COORDINATE BaseCoord
-- @param #boolean AllowRTB
-- @param #string SpawnTemplate
-- @param Core.Point#COORDINATE SpawnCoord
-- @param #boolean UseRoads
-- @param #number Speed
-- @param #string Formation
-- @return #TACTICS self
function TACTICS:EnableRearming(OnOff,LowPercent,FullPercent,RearmGroup,BaseCoord,AllowRTB,SpawnTemplate,SpawnCoord,UseRoads,Speed,Formation)
    self.AllowRearming = OnOff
    self.LowAmmoPercent = LowPercent or 0.25
    self.FullAmmoPercent = FullPercent or 0.95
    self.RearmGroup = GroupAlive
    self.RearmTemplate = SpawnTemplate
    self.RearmSpawnCoord = SpawnCoord or BaseCoord
    self.DespawnRearmingGroup = false
    self.RearmGroupBase = BaseCoord
    self.RearmGroupRTB = AllowRTB or false
    self.RearmGroupUseRoads = UseRoads or false
    self.RearmGroupSpeed = Speed or 60
    self.RearmGroupFormation = Formation or "Diamond"
    return self
end

--- [User] Enable Troop Transport
-- @param #TACTICS self
-- @param #string template
-- @param #number attackdist
-- @param #number attackreturn
-- @param string unitprefix
-- @return #TACTICS self
function TACTICS:EnableTroopTransport(template,attackdist,attackreturn,unitprefix)
    self.TroopTransport = true
    self.TroopTemplate = template
    if attackdist then self.TroopAttackDist = attackdist end
    if attackreturn then self.TroopReturnTime = attackreturn end
    if unitprefix then self.TransportUnitPrefix = unitprefix end
    return self
end

--- [User] Enable drawing rearming requests
-- @param #TACTICS self
-- @param #string Text
-- @param #number FontSize
-- @param #number Radius
-- @param #table BorderTextColor
-- @param #number BorderTextAlpha
-- @param #table FillColor
-- @param #number FillAlpha
-- @param #number LineType
-- @return #TACTICS self
function TACTICS:EnableRearmDrawings(Text,FontSize,Radius,BorderTextColor,BorderTextAlpha,FillColor,FillAlpha,LineType)
    self.RearmDrawing = true
    self.DrawDataR.DrawText = nil
    self.DrawDataR.DrawPoly = nil
    self.DrawDataR.Text = Text
    self.DrawDataR.Font = FontSize
    self.DrawDataR.Radius = Radius
    self.DrawDataR.Color1 = BorderTextColor
    self.DrawDataR.Color2 = FillColor
    self.DrawDataR.Alpha1 = BorderTextAlpha
    self.DrawDataR.Alpha2 = FillAlpha
    self.DrawDataR.Linetype = LineType
    self.DrawDataR.Coalition = 2
    if self.groupCoalition == coalition.side.RED then self.DrawDataR.Coalition = 1 end
    return self
end

--- [User] Enable drawing rgroups that are engaged with enemy forces
-- @param #TACTICS self
-- @param #string Text
-- @param #number FontSize
-- @param #number Radius
-- @param #table BorderTextColor
-- @param #number BorderTextAlpha
-- @param #table FillColor
-- @param #number FillAlpha
-- @param #number LineType
-- @param #boolean MarkEnemy
-- @param #number MarkFreshTime 
-- @param #number MarkStaleTime
-- @return #TACTICS self
function TACTICS:EnableEngageDrawings(Text,FontSize,Radius,BorderTextColor,BorderTextAlpha,FillColor,FillAlpha,LineType,MarkEnemy,MarkFreshTime,MarkStaleTime)
    self.EngageDrawing = true
    self.DrawDataE.DrawText = nil
    self.DrawDataE.DrawPoly = nil
    self.DrawDataE.Text = Text
    self.DrawDataE.Font = FontSize
    self.DrawDataE.Radius = Radius
    self.DrawDataE.Color1 = BorderTextColor
    self.DrawDataE.Color2 = FillColor
    self.DrawDataE.Alpha1 = BorderTextAlpha
    self.DrawDataE.Alpha2 = FillAlpha
    self.DrawDataE.Linetype = LineType
    if MarkEnemy then self.DrawDataE.MarkEnemy = MarkEnemy end
    if MarkFreshTime then self.EngageDrawingFresh = MarkFreshTime end
    if MarkStaleTime then self.EngageDrawingStale = MarkStaleTime end
    self.DrawDataE.Coalition = 2
    if self.groupCoalition == coalition.side.RED then self.DrawDataE.Coalition = 1 end
    return self
end

--- [User] Enable drawing rgroups that are engaged with enemy forces
-- @param #TACTICS self
-- @param #number StaleTimeout
-- @return #TACTICS self
function TACTICS:EnableSpotDrawings(StaleTimeout)
    self.DrawEnemySpots = true
    if StaleTimeout then self.EnemySpotStale = StaleTimeout end
    return self
end

--- [User] Retreat to the retreat zone
-- @param #TACTICS self
-- @param Core.Point#COORDINATE Destination
-- @param #boolean Despawn
-- @param #number Speed
-- @param #string Formation
-- @param #boolean UseRoads
-- @return #TACTICS self
function TACTICS:Retreat(Destination,Despawn,Speed,Formation,UseRoads)
    if not self:Is("Retreating") then
        if not Destination and self.RetreatZone then 
            self:I("RETREAT: "..self.Groupname.." will attempt to retreat to the defined retreat zone.")
            Destination = self.RetreatZone:GetRandomCoordinate() 
            if not Speed then Speed = self.RetreatSpeed else self.RetreatSpeed = Speed end
            if not Formation then Formation = self.RetreatFormation else self.RetreatFormation = Formation end
            if not UseRoads then UseRoads = false end
            if not Despawn then Despawn = false end
            self.retreatDestination = Destination
            self.TimeTravelActive = false
            self.TimeEngageActive = false
            self.TimeHoldActive = false
            self.TimeAvoidActive = false
            self.TimeAttackActive = false
            self.TimeDetectionActive = false

            if self.DrawDataR.DrawText then 
                trigger.action.removeMark(self.DrawDataR.DrawText)
                self.DrawDataR.DrawText = nil
            end
            if self.DrawDataR.DrawPoly then 
                trigger.action.removeMark(self.DrawDataR.DrawPoly)
                self.DrawDataR.DrawPoly = nil
            end
            if self.DrawDataE.DrawText then 
                trigger.action.removeMark(self.DrawDataE.DrawText)
                self.DrawDataE.DrawText = nil
            end
            if self.DrawDataE.DrawPoly then 
                trigger.action.removeMark(self.DrawDataE.DrawPoly)
                self.DrawDataE.DrawPoly = nil
            end

            if not self.TroopsAttacking then
                if self.RetreatOnRoads then
                    self.Group:RouteGroundOnRoad(self.retreatDestination, self.RetreatSpeed, 1, self.RetreatFormation)
                    self.TimeRetreatActive = true
                    self.TimeRetreatStamp = timer.getAbsTime()
                else
                    self.Group:RouteGroundTo(self.retreatDestination, self.a, self.RetreatFormation, 1)
                    self.TimeRetreatActive = true
                    self.TimeRetreatStamp = timer.getAbsTime()
                end
            else
                self:_ReturnTroops()
            end
            self:StartRetreat(self.retreatDestination)               
        else
            self:E("TACICS ERROR: "..self.Groupname.." attempted to retreat but no retreat zone was declared and no destination was provided.")
        end
    end
    return self
end

--- [User] Enable retreating
-- @param #TACTICS self
-- @param Core.Zone#ZONE RetreatZone
-- @param #number LossPercentage
-- @param #boolean DespawnAfterRetreat
-- @param #number RetreatSpeed
-- @param #string RetreatFormation
-- @param #boolean UseRoads
-- @return #TACTICS self
function TACTICS:EnableRetreating(RetreatZone,LossPercentage,DespawnAfterRetreat,RetreatSpeed,RetreatFormation,UseRoads)
    if RetreatZone then 
        self.RetreatZone = RetreatZone 
    else
        self:E("TACTICS WARNING: No retreat zone declared when retreating was enabled for "..self.Groupname..". Retreating can only be conducted if executed manually.")
    end
    if LossPercentage then self.RetreatAfterLosses = LossPercentage end
    if RetreatSpeed then self.RetreatSpeed = RetreatSpeed end
    if RetreatFormation then self.RetreatFormation = RetreatFormation end
    if UseRoads or UseRoads == false then self.RetreatOnRoads = UseRoads end
    if DespawnAfterRetreat or DespawnAfterRetreat == false then self.DespawnAfterRetreat = DespawnAfterRetreat end
    self:T({"TACTCS: Retreating enabled for "..self.Groupname,RetreatZone = RetreatZone,LossPercentage = LossPercentage,RetreatSpeed = RetreatSpeed,RetreatFormation = RetreatFormation,UseRoads = UseRoads,DespawnAfterRetreat = DespawnAfterRetreat})
    return self
end

--- [User] Enable Abandoning
-- @param #TACTICS self
-- @param #string CrewTemplate
-- @param #boolean AllowSelfRecover
-- @param #string RecoveryVehicle
-- @param Core.Zone#ZONE RecoverySpawnZone
-- @param #boolean SmokeAbandoned
-- @param #number AbandonHealth
-- @param #number AbandonDistance
-- @param #boolean RecoveryUseRoads
-- @param #number RecoverySpeed
-- @param #string RecoveryFormation
-- @return #TACTICS self
function TACTICS:EnableAbandon(CrewTemplate,AllowSelfRecover,RecoveryVehicle,RecoverySpawnZone,SmokeAbandoned,AbandonHealth,AbandonDistance,RecoveryUseRoads,RecoverySpeed,RecoveryFormation)
    if CrewTemplate then
        self.AbandonEnabled = true
        self.CrewTemplate = CrewTemplate
        if AllowSelfRecover then self.AllowSelfRecover = AllowSelfRecover end
        if RecoveryVehicle then self.RecoveryVehicle = RecoveryVehicle end
        if RecoverySpawnZone then self.RecoverySpawnZone = RecoverySpawnZone end
        if SmokeAbandoned then self.SmokeAbandoned = true else self.SmokeAbandoned = false end
        if AbandonHealth then self.AbandonHealth = AbandonHealth end
        if AbandonDistance then self.AbandonDistance = AbandonDistance end
        if RecoveryUseRoads then self.RecoveryUseRoads = true else self.RecoveryUseRoads = false end
        if RecoverySpeed then self.RecoverySpeed = RecoverySpeed end
        if RecoveryFormation then self.RecoveryFormation = RecoveryFormation end
    else
        self:E("TACTICS ERROR: A crew template is required for vehicle abandoning!")
    end
    return self
end

--- [User] Set Detection Range
-- @param #TACTICS self
-- @param #number val
-- @return #TACTICS self
function TACTICS:SetDetectionMax(val)
    self.zoneDetection:SetRadius(val)
    self.MaxDetection = val
    return self
end

--- [User] Enable Message Output
-- @param #TACTICS self
-- @param #boolean OnOff
-- @param #string Callsign
-- @param #string sound
-- @param #number duration
-- @return #TACTICS self
function TACTICS:EnableMessageOutput(OnOff,Callsign,Sound,Duration)
    self.MessageOutput = OnOff or true
    if Callsign then self.MessageCallsign = Callsign end
    if Sound then self.MessageSound = Sound end
    if Duration then self.MessageDuration = Duration end
    return self
end

--- [User] Enable Support Requests
-- @param #TACTICS self
-- @param #boolean OnOff
-- @param #number Radius
-- @param #number GroupLimit
-- @return #TACTICS self
function TACTICS:EnableSupportRequest(OnOff,Radius,GroupLimit)
    self.AllowSupportRequests = OnOff or true
    if Radius then self.SupportRadius = Radius end
    if GroupLimit then self.SupportGroupLimit = GroupLimit end
    return self
end

--- [User] Enable Support Response
-- @param #TACTICS self
-- @param #boolean OnOff
-- @return #TACTICS self
function TACTICS:EnableSupportRespond(OnOff)
    self.RespondToSupport = OnOff or true
    return self
end

--- [User] Pause timers, halt group, and disable AI
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:Sleep()
    if not self.Sleeping then
        if self.MasterTime then
            self.MasterTime:Stop()
            self.Group:RouteStop()
            self.Group:SetAIOff()
            self.Sleeping = true
        else
            self.E("Failed attempt to sleep "..self.Groupname.." as it is no longer active!")
        end
    end
    return self
end

--- [User] Resume timers after 5 seconds and enable AI immediately
-- @param #TACTICS self
-- @return #TACTICS self
function TACTICS:Wake()
    if self.Sleeping then
        if self.MasterTime then
            self.MasterTime:Start(5,self.TickRate)
            self.Group:SetAIOn()
            self.Sleeping = false
        else
            self.E("Failed attempt to wake "..self.Groupname.." as it is no longer active!")
        end
    end
    return self
end
