--- **Functional** - Manage and track client slots easily to add your own client-based menus and modules to.
-- 
-- The @{#CLIENTWATCH} class adds a simplified way to create scripts and menus for individual clients. Instead of creating large algorithms and juggling multiple event handlers, you can simply provide one or more prefixes to the class and use the callback functions on spawn, despawn, and any aircraft related events to script to your hearts content.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Find clients by prefixes or by providing a Wrapper.CLIENT object
--   * Trigger functions when the client spawns and despawns
--   * Create multiple client instances without overwriting event handlers between instances
--   * More reliable aircraft lost events for when DCS thinks the aircraft id dead but a dead event fails to trigger
--   * Easily manage clients spawned in dynamic slots
--
-- ====
-- 
-- ### Author: **Statua**
-- 
-- ### Contributions: **FlightControl**: Wrapper.CLIENT
-- 
-- ====
-- @module Functional.ClientWatch
-- @image clientwatch.jpg

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- CLIENTWATCH class
-- @type CLIENTWATCH
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Write Debug messages to DCS log file and send Debug messages to all players.
-- @field #string lid String for DCS log file.
-- @field #number FilterCoalition If not nil, will only activate for aircraft of the given coalition value.
-- @field #number FilterCategory If not nil, will only activate for aircraft of the given category value.
-- @extends Core.Fsm#FSM_CONTROLLABLE

--- Manage and track client slots easily to add your own client-based menus and modules to.
-- 
-- ## Creating a new instance
-- 
-- To start, you must first create a new instance of the client manager and provide it with either a Wrapper.Client#CLIENT object, a string prefix of the unit name, or a table of string prefixes for unit names. These are used to capture the client unit when it spawns and apply your scripted functions to it. Only fixed wing and rotary wing aircraft controlled by players can be used by this class.
-- **This will not work if the client aircraft is alive!**
-- 
-- ### Examples
--
--          -- Create an instance with a Wrapper.Client#CLIENT object
--          local heliClient = CLIENT:FindByName('Rotary1-1')
--          local clientInstance = CLIENTWATCH:New(heliClient)
--  
--          -- Create an instance with part of the unit name in the Mission Editor
--          local clientInstance = CLIENTWATCH:New("Rotary")
--  
--          -- Create an instance using prefixes for a few units as well as a FARP name for any dynamic spawns coming out of it
--          local clientInstance = CLIENTWATCH:New({"Rescue","UH-1H","FARP ALPHA"})
--
-- ## Applying functions and methods to client aircraft when they spawn
-- 
-- Once the instance is created, it will watch for birth events. If the unit name of the client aircraft matches the one provided in the instance, the callback method @{#CLIENTWATCH:OnAfterSpawn}() can be used to apply functions and methods to the client object.
--
-- In the OnAfterSpawn() callback method are four values. From, Event, To, and ClientObject. From,Event,To are standard FSM strings for the state changes. ClientObject is where the magic happens. This is a special object which you can use to access all the data of the client aircraft. The following entries in ClientObject are available for you to use:
--
--   * **ClientObject.Unit**: The Moose @{Wrapper.Unit#UNIT} of the client aircraft
--   * **ClientObject.Group**: The Moose @{Wrapper.Group#GRUP} of the client aircraft
--   * **ClientObject.Client**: The Moose @{Wrapper.Client#CLIENT} of the client aircraft
--   * **ClientObject.PlayerName**: A #string of the player controlling the aircraft
--   * **ClientObject.UnitName**: A #string of the client aircraft unit.
--   * **ClientObject.GroupName**: A #string of the client aircraft group.
-- 
-- ### Examples
--
--          -- Create an instance with a client unit prefix and send them a message when they spawn
--          local clientInstance = CLIENTWATCH:New("Rotary")
--          function clientInstance:OnAfterSpawn(From,Event,To,ClientObject,EventData)
--              MESSAGE:New("Welcome to your aircraft!",10):ToUnit(ClientObject.Unit)
--          end
--
-- ## Using event callbacks
-- 
-- In a normal setting, you can only use a callback function for a specific option in one location. If you have multiple scripts that rely on the same callback from the same object, this can get quite messy. With the ClientWatch module, these callbacks are isolated t the instances and therefore open the possibility to use many instances with the same callback doing different things. ClientWatch instances subscribe to all events that are applicable to player controlled aircraft and provides callbacks for each, forwarding the EventData in the callback function.
--
-- The following event callbacks can be used inside the OnAfterSpawn() callback:
--
--   * **:OnAfterDespawn(From,Event,To)**: Triggers whenever DCS no longer sees the aircraft as 'alive'. No event data is given in this callback as it is derived from other events
--   * **:OnAfterHit(From,Event,To,EventData)**: Triggers every time the aircraft takes damage or is struck by a weapon/explosion
--   * **:OnAfterKill(From,Event,To,EventData)**: Triggers after the aircraft kills something with its weapons
--   * **:OnAfterScore(From,Event,To,EventData)**: Triggers after accumulating score
--   * **:OnAfterShot(From,Event,To,EventData)**: Triggers after a single-shot weapon is released
--   * **:OnAfterShootingStart(From,Event,To,EventData)**: Triggers when an automatic weapon begins firing
--   * **:OnAfterShootingEnd(From,Event,To,EventData)**: Triggers when an automatic weapon stops firing
--   * **:OnAfterLand(From,Event,To,EventData)**: Triggers when an aircraft transitions from being airborne to on the ground
--   * **:OnAfterTakeoff(From,Event,To,EventData)**: Triggers when an aircraft transitions from being on the ground to airborne
--   * **:OnAfterRunwayTakeoff(From,Event,To,EventData)**: Triggers after lifting off from a runway
--   * **:OnAfterRunwayTouch(From,Event,To,EventData)**: Triggers when an aircraft's gear makes contact with a runway
--   * **:OnAfterRefueling(From,Event,To,EventData)**: Triggers when an aircraft begins taking on fuel
--   * **:OnAfterRefuelingStop(From,Event,To,EventData)**: Triggers when an aircraft stops taking on fuel
--   * **:OnAfterPlayerLeaveUnit(From,Event,To,EventData)**: Triggers when a player leaves an operational aircraft
--   * **:OnAfterCrash(From,Event,To,EventData)**: Triggers when an aircraft is destroyed (may fail to trigger if the aircraft is only partially destroyed)
--   * **:OnAfterDead(From,Event,To,EventData)**: Triggers when an aircraft is considered dead (may fail to trigger if the aircraft was partially destroyed first)
--   * **:OnAfterPilotDead(From,Event,To,EventData)**: Triggers when the pilot is killed (may fail to trigger if the aircraft was partially destroyed first)
--   * **:OnAfterUnitLost(From,Event,To,EventData)**: Triggers when an aircraft is lost for any reason (may fail to trigger if the aircraft was partially destroyed first)
--   * **:OnAfterEjection(From,Event,To,EventData)**: Triggers when a pilot ejects from an aircraft
--   * **:OnAfterHumanFailure(From,Event,To,EventData)**: Triggers when an aircraft or system is damaged from any source or action by the player
--   * **:OnAfterHumanAircraftRepairStart(From,Event,To,EventData)**: Triggers when an aircraft repair is started
--   * **:OnAfterHumanAircraftRepairFinish(From,Event,To,EventData)**: Triggers when an aircraft repair is completed
--   * **:OnAfterEngineStartup(From,Event,To,EventData)**: Triggers when the engine enters what DCS considers to be a started state. Parameters vary by aircraft
--   * **:OnAfterEngineShutdown(From,Event,To,EventData)**: Triggers when the engine enters what DCS considers to be a stopped state. Parameters vary by aircraft
--   * **:OnAfterWeaponAdd(From,Event,To,EventData)**: Triggers when an item is added to an aircraft's payload
--   * **:OnAfterWeaponDrop(From,Event,To,EventData)**: Triggers when an item is jettisoned or dropped from an aircraft (unconfirmed)
--   * **:OnAfterWeaponRearm(From,Event,To,EventData)**: Triggers when an item with internal supply is restored (unconfirmed)
-- 
-- ### Examples
--
--          -- Show a message to player when they take damage from a weapon
--          local clientInstance = CLIENTWATCH:New("Rotary")
--              function clientInstance:OnAfterSpawn(From,Event,To,ClientObject,EventData)
--              function ClientObject:OnAfterHit(From,Event,To,EventData)
--                 local typeShooter = EventData.IniTypeName
--                 local nameWeapon = EventData.weapon_name
--                 MESSAGE:New("A "..typeShooter.." hit you with a "..nameWeapon,20):ToUnit(ClientObject.Unit)
--              end
--          end
-- 
-- @field #CLIENTWATCH
CLIENTWATCH = {}
CLIENTWATCH.ClassName = "CLIENTWATCH"
CLIENTWATCH.Debug = false
CLIENTWATCH.DebugEventData = false
CLIENTWATCH.lid = nil

-- @type CLIENTWATCHTools
-- @field #table Unit Wrapper.UNIT of the cient object
-- @field #table Group Wrapper.GROUP of the cient object
-- @field #table Client Wrapper.CLIENT of the cient object
-- @field #string PlayerName Name of the player controlling the client object
-- @field #string UnitName Name of the unit that is the client object
-- @field #string GroupName Name of the group the client object belongs to
CLIENTWATCHTools = {}
  
--- CLIENTWATCH version
-- @field #string version
CLIENTWATCH.version="1.0.1"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new instance of CLIENTWATCH to add scripts to. Can be used multiple times with the same client/prefixes if you need it for multiple scripts.
-- @param #CLIENTWATCH self
-- @param #string Will watch for clients whos UNIT NAME or GROUP NAME matches part of the #string as a prefix.
-- @param #table Put strings in a table to use multiple prefixes for the above method.
-- @param Wrapper.Client#CLIENT Provide a Moose CLIENT object to apply to that specific aircraft slot (static slots only!)
-- @param #nil Leave blank to activate for ALL CLIENTS
-- @return #CLIENTWATCH self
function CLIENTWATCH:New(client)
    --Init FSM
    local self=BASE:Inherit(self, FSM:New())
    self:SetStartState( "Idle" )
    self:AddTransition( "*", "Spawn", "*" )

    self.FilterCoalition = nil
    self.FilterCategory = nil

    --- User function for OnAfter "Spawn" event.
  -- @function [parent=#CLIENTWATCH] OnAfterSpawn
  -- @param #CLIENTWATCH self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #table clientObject Custom object that handles events and stores Moose object data. See top documentation for more details.
  -- @param #table eventdata Data from EVENTS.Birth.

    --Set up spawn tracking
    if not client then
        if self.Debug then self:I({"New client instance created. ClientType = All clients"}) end
        self:HandleEvent(EVENTS.Birth)
        function self:OnEventBirth(eventdata)
            if (eventdata.IniCategory == 0 or eventdata.IniCategory == 1) and eventdata.IniPlayerName 
            and (not self.FilterCoalition or self.FilterCoalition == eventdata.IniCoalition) 
            and (not self.FilterCategory or self.FilterCategory == eventdata.IniCategory) then
                if self.Debug then 
                    self:I({"Client spawned in.",IniCategory = eventdata.IniCategory})
                end
                local clientWatchDebug = self.Debug
                local clientObject = CLIENTWATCHTools:_newClient(clientWatchDebug,eventdata)
                self:Spawn(clientObject,eventdata)
            end
        end
    elseif type(client) == "table" or type(client) == "string" then
        if type(client) == "table" then 

            --CLIENT TABLE
            if client.ClassName == "CLIENT" then
                if self.Debug then self:I({"New client instance created. ClientType = Wrapper.CLIENT",client}) end
                self.ClientName = client:GetName()
                self:HandleEvent(EVENTS.Birth)
                function self:OnEventBirth(eventdata)
                    if (eventdata.IniCategory == 0 or eventdata.IniCategory == 1) and eventdata.IniPlayerName 
                    and (not self.FilterCoalition or self.FilterCoalition == eventdata.IniCoalition) 
                    and (not self.FilterCategory or self.FilterCategory == eventdata.IniCategory) then
                        if self.ClientName == eventdata.IniUnitName then
                            if self.Debug then 
                                self:I({"Client spawned in.",IniCategory = eventdata.IniCategory})
                            end
                            local clientWatchDebug = self.Debug
                            local clientObject = CLIENTWATCHTools:_newClient(clientWatchDebug,eventdata)
                            self:Spawn(clientObject,eventdata)
                        end
                    end
                end

            --STRING TABLE
            else
                if self.Debug then self:I({"New client instance created. ClientType = Multiple Prefixes",client}) end
                local tableValid = true
                for _,entry in pairs(client) do
                    if type(entry) ~= "string" then
                        tableValid = false
                        self:E({"The base handler failed to start because at least one entry in param1's table is not a string!",InvalidEntry = entry})
                        return nil
                    end
                end
                if tableValid then
                    self:HandleEvent(EVENTS.Birth)
                    function self:OnEventBirth(eventdata)
                        for _,entry in pairs(client) do
                            if (eventdata.IniCategory == 0 or eventdata.IniCategory == 1) and eventdata.IniPlayerName 
                            and (not self.FilterCoalition or self.FilterCoalition == eventdata.IniCoalition) 
                            and (not self.FilterCategory or self.FilterCategory == eventdata.IniCategory) then
                                if string.match(eventdata.IniUnitName,entry) or string.match(eventdata.IniGroupName,entry) then
                                    if self.Debug then 
                                        self:I({"Client spawned in.",IniCategory = eventdata.IniCategory})
                                    end
                                    local clientWatchDebug = self.Debug
                                    local clientObject = CLIENTWATCHTools:_newClient(clientWatchDebug,eventdata)
                                    self:Spawn(clientObject,eventdata)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        else
            if self.Debug then self:I({"New client instance created. ClientType = Single Prefix",client}) end

            --SOLO STRING
            self:HandleEvent(EVENTS.Birth)
            function self:OnEventBirth(eventdata)
                if (eventdata.IniCategory == 0 or eventdata.IniCategory == 1) and eventdata.IniPlayerName 
                and (not self.FilterCoalition or self.FilterCoalition == eventdata.IniCoalition) 
                and (not self.FilterCategory or self.FilterCategory == eventdata.IniCategory) then
                    if string.match(eventdata.IniUnitName,client) or string.match(eventdata.IniGroupName,client) then
                        if self.Debug then 
                            self:I({"Client spawned in.",IniCategory = eventdata.IniCategory})
                        end
                        local clientWatchDebug = self.Debug
                        local clientObject = CLIENTWATCHTools:_newClient(clientWatchDebug,eventdata)
                        self:Spawn(clientObject,eventdata)
                    end
                end
            end
        end
    else
        self:E({"The base handler failed to start because param1 is not a CLIENT object or a prefix string!",param1 = client})
        return nil
    end

    return self
end


--- Filter out all clients not belonging to the provided coalition
-- @param #CLIENTWATCH self
-- @param #number Coalition number (1 = red, 2 = blue)
-- @param #string Coalition string ('red' or 'blue')
function CLIENTWATCH:FilterByCoalition(value)
    if value == 1 or value == "red" then
        self.FilterCoalition = 1
    else
        self.FilterCoalition = 2
    end
    return self
end


--- Filter out all clients that are not of the given category
-- @param #CLIENTWATCH self
-- @param #number Category number (0 = airplane, 1 = helicopter)
-- @param #string Category string ('airplane' or 'helicopter')
function CLIENTWATCH:FilterByCategory(value)
    if value == 1 or value == "helicopter" then
        self.FilterCategory = 1
    else
        self.FilterCategory = 0
    end
    return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Internal function for creating a new client on birth. Do not use!!!.
-- @param #CLIENTWATCHTools self
-- @param #EVENTS.Birth EventData
-- @return #CLIENTWATCHTools self
function CLIENTWATCHTools:_newClient(clientWatchDebug,eventdata)
    --Init FSM
    local self=BASE:Inherit(self, FSM:New())
    self:SetStartState( "Alive" )
    self:AddTransition( "Alive", "Despawn", "Dead" )

    self.Unit = eventdata.IniUnit
    self.Group = self.Unit:GetGroup()
    self.Client = self.Unit:GetClient()
    self.PlayerName = self.Unit:GetPlayerName()
    self.UnitName = self.Unit:GetName()
    self.GroupName = self.Group:GetName()

    --Event events
    self:AddTransition( "*", "Hit", "*" )
    self:AddTransition( "*", "Kill", "*" )
    self:AddTransition( "*", "Score", "*" )
    self:AddTransition( "*", "Shot", "*" )
    self:AddTransition( "*", "ShootingStart", "*" )
    self:AddTransition( "*", "ShootingEnd", "*" )
    self:AddTransition( "*", "Land", "*" )
    self:AddTransition( "*", "Takeoff", "*" )
    self:AddTransition( "*", "RunwayTakeoff", "*" )
    self:AddTransition( "*", "RunwayTouch", "*" )
    self:AddTransition( "*", "Refueling", "*" )
    self:AddTransition( "*", "RefuelingStop", "*" )
    self:AddTransition( "*", "PlayerLeaveUnit", "*" )
    self:AddTransition( "*", "Crash", "*" )
    self:AddTransition( "*", "Dead", "*" )
    self:AddTransition( "*", "PilotDead", "*" )
    self:AddTransition( "*", "UnitLost", "*" )
    self:AddTransition( "*", "Ejection", "*" )
    self:AddTransition( "*", "HumanFailure", "*" )
    self:AddTransition( "*", "HumanAircraftRepairFinish", "*" )
    self:AddTransition( "*", "HumanAircraftRepairStart", "*" )
    self:AddTransition( "*", "EngineShutdown", "*" )
    self:AddTransition( "*", "EngineStartup", "*" )
    self:AddTransition( "*", "WeaponAdd", "*" )
    self:AddTransition( "*", "WeaponDrop", "*" )
    self:AddTransition( "*", "WeaponRearm", "*" )

    --Event Handlers
    self:HandleEvent( EVENTS.Hit )
    self:HandleEvent( EVENTS.Kill )
    self:HandleEvent( EVENTS.Score )
    self:HandleEvent( EVENTS.Shot )
    self:HandleEvent( EVENTS.ShootingStart )
    self:HandleEvent( EVENTS.ShootingEnd )
    self:HandleEvent( EVENTS.Land )
    self:HandleEvent( EVENTS.Takeoff )
    self:HandleEvent( EVENTS.RunwayTakeoff )
    self:HandleEvent( EVENTS.RunwayTouch )
    self:HandleEvent( EVENTS.Refueling )
    self:HandleEvent( EVENTS.RefuelingStop )
    self:HandleEvent( EVENTS.PlayerLeaveUnit )
    self:HandleEvent( EVENTS.Crash )
    self:HandleEvent( EVENTS.Dead )
    self:HandleEvent( EVENTS.PilotDead )
    self:HandleEvent( EVENTS.UnitLost )
    self:HandleEvent( EVENTS.Ejection )
    self:HandleEvent( EVENTS.HumanFailure )
    self:HandleEvent( EVENTS.HumanAircraftRepairFinish )
    self:HandleEvent( EVENTS.HumanAircraftRepairStart )
    self:HandleEvent( EVENTS.EngineShutdown )
    self:HandleEvent( EVENTS.EngineStartup )
    self:HandleEvent( EVENTS.WeaponAdd )
    self:HandleEvent( EVENTS.WeaponDrop )
    self:HandleEvent( EVENTS.WeaponRearm )

    function self:OnEventHit(EventData)
        if EventData.TgtUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered hit event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Hit(EventData)
        end
    end

    function self:OnEventKill(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered kill event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Kill(EventData)
        end
    end

    function self:OnEventScore(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered score event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Score(EventData)
        end
    end

    function self:OnEventShot(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered shot event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Shot(EventData)
        end
    end

    function self:OnEventShootingStart(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered shooting start event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:ShootingStart(EventData)
        end
    end

    function self:OnEventShootingEnd(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered shooting end event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:ShootingEnd(EventData)
        end
    end

    function self:OnEventLand(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered land event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Land(EventData)
        end
    end

    function self:OnEventTakeoff(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered takeoff event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Takeoff(EventData)
        end
    end

    function self:OnEventRunwayTakeoff(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered runway takeoff event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:RunwayTakeoff(EventData)
        end
    end

    function self:OnEventRunwayTouch(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered runway touch event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:RunwayTouch(EventData)
        end
    end

    function self:OnEventRefueling(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered refueling event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Refueling(EventData)
        end
    end

    function self:OnEventRefuelingStop(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered refueling event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:RefuelingStop(EventData)
        end
    end

    function self:OnEventPlayerLeaveUnit(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered leave unit event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:PlayerLeaveUnit(EventData)
            self._deadRoutine()
        end
    end

    function self:OnEventCrash(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered crash event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Crash(EventData)
            self._deadRoutine()
        end
    end

    function self:OnEventDead(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered dead event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Dead(EventData)
            self._deadRoutine()
        end
    end

    function self:OnEventPilotDead(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered pilot dead event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:PilotDead(EventData)
            self._deadRoutine()
        end
    end

    function self:OnEventUnitLost(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered unit lost event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:UnitLost(EventData)
            self._deadRoutine()
        end
    end

    function self:OnEventEjection(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered ejection event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:Ejection(EventData)
            self._deadRoutine()
        end
    end

    function self:OnEventHumanFailure(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered human failure event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:HumanFailure(EventData)
            if not self.Unit:IsAlive() then
                self._deadRoutine()
            end
        end
    end

    function self:OnEventHumanAircraftRepairFinish(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered repair finished event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:HumanAircraftRepairFinish(EventData)
        end
    end

    function self:OnEventHumanAircraftRepairStart(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered repair start event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:HumanAircraftRepairStart(EventData)
        end
    end

    function self:OnEventEngineShutdown(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered engine shutdown event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:EngineShutdown(EventData)
        end
    end

    function self:OnEventEngineStartup(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered engine startup event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:EngineStartup(EventData)
        end
    end

    function self:OnEventWeaponAdd(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered weapon add event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:WeaponAdd(EventData)
        end
    end

    function self:OnEventWeaponDrop(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered weapon drop event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:WeaponDrop(EventData)
        end
    end

    function self:OnEventWeaponRearm(EventData)
        if EventData.IniUnitName == self.UnitName then
            if clientWatchDebug then
                self:I({"Client triggered weapon rearm event.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
                
            end
            self:WeaponRearm(EventData)
        end
    end


    --Fallback timer
    self.FallbackTimer = TIMER:New(function()
        if not self.Unit:IsAlive() then
            if clientWatchDebug then
                self:I({"Client is registered as dead without an event trigger. Running fallback dead routine.",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName})
            end
            self._deadRoutine()
        end
    end)
    self.FallbackTimer:Start(5,5)

    --Stop event handlers and trigger Despawn
    function self._deadRoutine()
        if clientWatchDebug then self:I({"Client dead routine triggered. Shutting down tracking...",Player = self.PlayerName,Group = self.GroupName,Unit = self.UnitName}) end
        self:UnHandleEvent( EVENTS.Hit )
        self:UnHandleEvent( EVENTS.Kill )
        self:UnHandleEvent( EVENTS.Score )
        self:UnHandleEvent( EVENTS.Shot )
        self:UnHandleEvent( EVENTS.ShootingStart )
        self:UnHandleEvent( EVENTS.ShootingEnd )
        self:UnHandleEvent( EVENTS.Land )
        self:UnHandleEvent( EVENTS.Takeoff )
        self:UnHandleEvent( EVENTS.RunwayTakeoff )
        self:UnHandleEvent( EVENTS.RunwayTouch )
        self:UnHandleEvent( EVENTS.Refueling )
        self:UnHandleEvent( EVENTS.RefuelingStop )
        self:UnHandleEvent( EVENTS.PlayerLeaveUnit )
        self:UnHandleEvent( EVENTS.Crash )
        self:UnHandleEvent( EVENTS.Dead )
        self:UnHandleEvent( EVENTS.PilotDead )
        self:UnHandleEvent( EVENTS.UnitLost )
        self:UnHandleEvent( EVENTS.Ejection )
        self:UnHandleEvent( EVENTS.HumanFailure )
        self:UnHandleEvent( EVENTS.HumanAircraftRepairFinish )
        self:UnHandleEvent( EVENTS.HumanAircraftRepairStart )
        self:UnHandleEvent( EVENTS.EngineShutdown )
        self:UnHandleEvent( EVENTS.EngineStartup )
        self:UnHandleEvent( EVENTS.WeaponAdd )
        self:UnHandleEvent( EVENTS.WeaponDrop )
        self:UnHandleEvent( EVENTS.WeaponRearm )
        self.FallbackTimer:Stop()
        self:Despawn()
    end
    
    self:I({"Detected client spawn and applied internal functions and events.", PlayerName = self.PlayerName, UnitName = self.UnitName, GroupName = self.GroupName})
    return self
end
