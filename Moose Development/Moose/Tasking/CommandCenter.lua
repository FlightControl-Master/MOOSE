--- **Tasking** -- A command center governs multiple missions, and takes care of the reporting and communications.
-- 
-- **Features:**
-- 
--   * Govern multiple missions.
--   * Communicate to coalitions, groups.
--   * Assign tasks.
--   * Manage the menus.
--   * Manage reference zones.
-- 
-- ===
--  
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Tasking.CommandCenter
-- @image Task_Command_Center.JPG


--- The COMMANDCENTER class
-- @type COMMANDCENTER
-- @field Wrapper.Group#GROUP HQ
-- @field DCS#coalition CommandCenterCoalition
-- @list<Tasking.Mission#MISSION> Missions
-- @extends Core.Base#BASE


--- Governs multiple missions, the tasking and the reporting.
--  
-- Command centers govern missions, communicates the task assignments between human players of the coalition, and manages the menu flow.
-- It can assign a random task to a player when requested.
-- The commandcenter provides the facilitites to communicate between human players online, executing a task.
--  
-- ## 1. Create a command center object.
--
--   * @{#COMMANDCENTER.New}(): Creates a new COMMANDCENTER object.
-- 
-- ## 2. Command center mission management.
-- 
-- Command centers manage missions. These can be added, removed and provides means to retrieve missions.
-- These methods are heavily used by the task dispatcher classes.
-- 
--   * @{#COMMANDCENTER.AddMission}(): Adds a mission to the commandcenter control.
--   * @{#COMMANDCENTER.RemoveMission}(): Removes a mission to the commandcenter control.
--   * @{#COMMANDCENTER.GetMissions}(): Retrieves the missions table controlled by the commandcenter.
-- 
-- ## 3. Communication management between players. 
-- 
-- Command center provide means of communication between players. 
-- Because a command center is a central object governing multiple missions,  
-- there are several levels at which communication needs to be done.
-- Within MOOSE, communication is facilitated using the message system within the DCS simulator.
-- 
-- Messages can be sent between players at various levels:
-- 
--   - On a global level, to all players.
--   - On a coalition level, only to the players belonging to the same coalition.
--   - On a group level, to the players belonging to the same group.
--   
-- Messages can be sent to **all players** by the command center using the method @{Tasking.CommandCenter#COMMANDCENTER.MessageToAll}().
-- 
-- To send messages to **the coalition of the command center**, there are two methods available:
--  
--   - Use the method @{Tasking.CommandCenter#COMMANDCENTER.MessageToCoalition}() to send a specific message to the coalition, with a given message display duration.
--   - You can send a specific type of message using the method @{Tasking.CommandCenter#COMMANDCENTER.MessageTypeToCoalition}().
--     This will send a message of a specific type to the coalition, and as a result its display duration will be flexible according the message display time selection by the human player.
--     
-- To send messages **to the group** of human players, there are also two methods available:
-- 
--   - Use the method @{Tasking.CommandCenter#COMMANDCENTER.MessageToGroup}() to send a specific message to a group, with a given message display duration.
--   - You can send a specific type of message using the method @{Tasking.CommandCenter#COMMANDCENTER.MessageTypeToGroup}().
--     This will send a message of a specific type to the group, and as a result its display duration will be flexible according the message display time selection by the human player .
--     
-- Messages are considered to be sometimes disturbing for human players, therefore, the settings menu provides the means to activate or deactivate messages.
-- For more information on the message types and display timings that can be selected and configured using the menu, refer to the @{Core.Settings} menu description.
--     
-- ## 4. Command center detailed methods.
-- 
-- Various methods are added to manage command centers.
-- 
-- ### 4.1. Naming and description.
-- 
-- There are 3 methods that can be used to retrieve the description of a command center:
-- 
--   - Use the method @{Tasking.CommandCenter#COMMANDCENTER.GetName}() to retrieve the name of the command center. 
--     This is the name given as part of the @{Tasking.CommandCenter#COMMANDCENTER.New}() constructor.
--     The returned name using this method, is not to be used for message communication.
-- 
-- A textual description can be retrieved that provides the command center name to be used within message communication:
-- 
--   - @{Tasking.CommandCenter#COMMANDCENTER.GetShortText}() returns the command center name as `CC [CommandCenterName]`.
--   - @{Tasking.CommandCenter#COMMANDCENTER.GetText}() returns the command center name as `Command Center [CommandCenterName]`.
-- 
-- ### 4.2. The coalition of the command center.
-- 
-- The method @{Tasking.CommandCenter#COMMANDCENTER.GetCoalition}() returns the coalition of the command center.
-- The return value is an enumeration of the type @{DCS#coalition.side}, which contains the RED, BLUE and NEUTRAL coalition. 
-- 
-- ### 4.3. The command center is a real object.
-- 
-- The command center must be represented by a live object within the DCS simulator. As a result, the command center   
-- can be a @{Wrapper.Unit}, a @{Wrapper.Group}, an @{Wrapper.Airbase} or a @{Wrapper.Static} object.
-- 
-- Using the method @{Tasking.CommandCenter#COMMANDCENTER.GetPositionable}() you retrieve the polymorphic positionable object representing
-- the command center, but just be aware that you should be able to use the representable object derivation methods.
-- 
-- ### 5. Command center reports.
-- 
-- Because a command center giverns multiple missions, there are several reports available that are generated by command centers.
-- These reports are generated using the following methods:
-- 
--   - @{Tasking.CommandCenter#COMMANDCENTER.ReportSummary}(): Creates a summary report of all missions governed by the command center.
--   - @{Tasking.CommandCenter#COMMANDCENTER.ReportDetails}(): Creates a detailed report of all missions governed by the command center.
--   - @{Tasking.CommandCenter#COMMANDCENTER.ReportMissionPlayers}(): Creates a report listing the players active at the missions governed by the command center.
--   
-- ## 6. Reference Zones.
-- 
-- Command Centers may be aware of certain Reference Zones within the battleground. These Reference Zones can refer to
-- known areas, recognizable buildings or sites, or any other point of interest.
-- Command Centers will use these Reference Zones to help pilots with defining coordinates in terms of navigation
-- during the WWII era.
-- The Reference Zones are related to the WWII mode that the Command Center will operate in.
-- Use the method @{#COMMANDCENTER.SetModeWWII}() to set the mode of communication to the WWII mode.
-- 
-- In WWII mode, the Command Center will receive detected targets, and will select for each target the closest
-- nearby Reference Zone. This allows pilots to navigate easier through the battle field readying for combat.
-- 
-- The Reference Zones need to be set by the Mission Designer in the Mission Editor.
-- Reference Zones are set by normal trigger zones. One can color the zones in a specific color, 
-- and the radius of the zones doesn't matter, only the point is important. Place the center of these Reference Zones at
-- specific scenery objects or points of interest (like cities, rivers, hills, crossing etc).
-- The trigger zones indicating a Reference Zone need to follow a specific syntax.
-- The name of each trigger zone expressing a Reference Zone need to start with a classification name of the object,
-- followed by a #, followed by a symbolic name of the Reference Zone.
-- A few examples:
-- 
--   * A church at Tskinvali would be indicated as: *Church#Tskinvali*
--   * A train station near Kobuleti would be indicated as: *Station#Kobuleti*
--   
-- The COMMANDCENTER class contains a method to indicate which trigger zones need to be used as Reference Zones.
-- This is done by using the method @{#COMMANDCENTER.SetReferenceZones}().
-- For the moment, only one Reference Zone class can be specified, but in the future, more classes will become possible.
-- 
-- ## 7. Tasks.
-- 
-- ### 7.1. Automatically assign tasks.
-- 
-- One of the most important roles of the command center is the management of tasks.
-- The command center can assign automatically tasks to the players using the @{Tasking.CommandCenter#COMMANDCENTER.SetAutoAssignTasks}() method.
-- When this method is used with a parameter true; the command center will scan at regular intervals which players in a slot are not having a task assigned.
-- For those players; the tasking is enabled to assign automatically a task.
-- An Assign Menu will be accessible for the player under the command center menu, to configure the automatic tasking to switched on or off.
-- 
-- ### 7.2. Automatically accept assigned tasks.
-- 
-- When a task is assigned; the mission designer can decide if players are immediately assigned to the task; or they can accept/reject the assigned task.
-- Use the method @{Tasking.CommandCenter#COMMANDCENTER.SetAutoAcceptTasks}() to configure this behaviour.
-- If the tasks are not automatically accepted; the player will receive a message that he needs to access the command center menu and
-- choose from 2 added menu options either to accept or reject the assigned task within 30 seconds.
-- If the task is not accepted within 30 seconds; the task will be cancelled and a new task will be assigned.
-- 
-- 
-- @field #COMMANDCENTER
COMMANDCENTER = {
  ClassName = "COMMANDCENTER",
  CommandCenterName = "",
  CommandCenterCoalition = nil,
  CommandCenterPositionable = nil,
  Name = "",
  ReferencePoints = {},
  ReferenceNames = {},
  CommunicationMode = "80",
}


--- @type COMMANDCENTER.AutoAssignMethods
COMMANDCENTER.AutoAssignMethods = {
  ["Random"] = 1,
  ["Distance"] = 2,
  ["Priority"] = 3,
  }

--- The constructor takes an IDENTIFIABLE as the HQ command center.
-- @param #COMMANDCENTER self
-- @param Wrapper.Positionable#POSITIONABLE CommandCenterPositionable
-- @param #string CommandCenterName
-- @return #COMMANDCENTER
function COMMANDCENTER:New( CommandCenterPositionable, CommandCenterName )

  local self = BASE:Inherit( self, BASE:New() ) -- #COMMANDCENTER

  self.CommandCenterPositionable = CommandCenterPositionable  
  self.CommandCenterName = CommandCenterName or CommandCenterPositionable:GetName()
  self.CommandCenterCoalition = CommandCenterPositionable:GetCoalition()
  
	self.Missions = {}

  self:SetAutoAssignTasks( false )
  self:SetAutoAcceptTasks( true )
  self:SetAutoAssignMethod( COMMANDCENTER.AutoAssignMethods.Distance )
  self:SetFlashStatus( false )
  
  self:HandleEvent( EVENTS.Birth,
    --- @param #COMMANDCENTER self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      if EventData.IniObjectCategory == 1 then
        local EventGroup = GROUP:Find( EventData.IniDCSGroup )
        --self:E( { CommandCenter = self:GetName(), EventGroup = EventGroup:GetName(), HasGroup = self:HasGroup( EventGroup ), EventData = EventData } )
        if EventGroup and EventGroup:IsAlive() and self:HasGroup( EventGroup ) then
          local CommandCenterMenu = MENU_GROUP:New( EventGroup, self:GetText() )
          local MenuReporting = MENU_GROUP:New( EventGroup, "Missions Reports", CommandCenterMenu )
          local MenuMissionsSummary = MENU_GROUP_COMMAND:New( EventGroup, "Missions Status Report", MenuReporting, self.ReportSummary, self, EventGroup )
          local MenuMissionsDetails = MENU_GROUP_COMMAND:New( EventGroup, "Missions Players Report", MenuReporting, self.ReportMissionsPlayers, self, EventGroup )
          self:ReportSummary( EventGroup )
          local PlayerUnit = EventData.IniUnit
          for MissionID, Mission in pairs( self:GetMissions() ) do
            local Mission = Mission -- Tasking.Mission#MISSION
            local PlayerGroup = EventData.IniGroup -- The GROUP object should be filled!
            Mission:JoinUnit( PlayerUnit, PlayerGroup )
          end
          self:SetMenu()
        end
      end
      
    end
    )
  
--  -- When a player enters a client or a unit, the CommandCenter will check for each Mission and each Task in the Mission if the player has things to do.
--  -- For these elements, it will=
--  -- - Set the correct menu.
--  -- - Assign the PlayerUnit to the Task if required.
--  -- - Send a message to the other players in the group that this player has joined.
--  self:HandleEvent( EVENTS.PlayerEnterUnit,
--    --- @param #COMMANDCENTER self
--    -- @param Core.Event#EVENTDATA EventData
--    function( self, EventData )
--      local PlayerUnit = EventData.IniUnit
--      for MissionID, Mission in pairs( self:GetMissions() ) do
--        local Mission = Mission -- Tasking.Mission#MISSION
--        local PlayerGroup = EventData.IniGroup -- The GROUP object should be filled!
--        Mission:JoinUnit( PlayerUnit, PlayerGroup )
--      end
--      self:SetMenu()
--    end
--  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:HandleEvent( EVENTS.MissionEnd,
    --- @param #TASK self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        local Mission = Mission -- Tasking.Mission#MISSION
        Mission:Stop()
      end
    end
  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:HandleEvent( EVENTS.PlayerLeaveUnit,
    --- @param #TASK self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        local Mission = Mission -- Tasking.Mission#MISSION
        if Mission:IsENGAGED() then
          Mission:AbortUnit( PlayerUnit )
        end
      end
    end
  )

  -- Handle when a player crashes ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:HandleEvent( EVENTS.Crash,
    --- @param #TASK self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        local Mission = Mission -- Tasking.Mission#MISSION
        if Mission:IsENGAGED() then
          Mission:CrashUnit( PlayerUnit )
        end
      end
    end
  )
  
  self:SetMenu()
  
  _SETTINGS:SetSystemMenu( CommandCenterPositionable )
  
  self:SetCommandMenu()
	
	return self
end

--- Gets the name of the HQ command center.
-- @param #COMMANDCENTER self
-- @return #string
function COMMANDCENTER:GetName()

  return self.CommandCenterName
end

--- Gets the text string of the HQ command center.
-- @param #COMMANDCENTER self
-- @return #string
function COMMANDCENTER:GetText()

  return "Command Center [" .. self.CommandCenterName .. "]"
end

--- Gets the short text string of the HQ command center.
-- @param #COMMANDCENTER self
-- @return #string
function COMMANDCENTER:GetShortText()

  return "CC [" .. self.CommandCenterName .. "]"
end


--- Gets the coalition of the command center.
-- @param #COMMANDCENTER self
-- @return DCScoalition#coalition
function COMMANDCENTER:GetCoalition()

  return self.CommandCenterCoalition
end


--- Gets the POSITIONABLE of the HQ command center.
-- @param #COMMANDCENTER self
-- @return Wrapper.Positionable#POSITIONABLE
function COMMANDCENTER:GetPositionable()
  return self.CommandCenterPositionable
end

--- Get the Missions governed by the HQ command center.
-- @param #COMMANDCENTER self
-- @return #list<Tasking.Mission#MISSION>
function COMMANDCENTER:GetMissions()

  return self.Missions or {}
end

--- Add a MISSION to be governed by the HQ command center.
-- @param #COMMANDCENTER self
-- @param Tasking.Mission#MISSION Mission
-- @return Tasking.Mission#MISSION
function COMMANDCENTER:AddMission( Mission )

  self.Missions[Mission] = Mission

  return Mission
end

--- Removes a MISSION to be governed by the HQ command center.
-- The given Mission is not nilified.
-- @param #COMMANDCENTER self
-- @param Tasking.Mission#MISSION Mission
-- @return Tasking.Mission#MISSION
function COMMANDCENTER:RemoveMission( Mission )

  self.Missions[Mission] = nil

  return Mission
end

--- Set special Reference Zones known by the Command Center to guide airborne pilots during WWII.
-- 
-- These Reference Zones are normal trigger zones, with a special naming.
-- The Reference Zones need to be set by the Mission Designer in the Mission Editor.
-- Reference Zones are set by normal trigger zones. One can color the zones in a specific color, 
-- and the radius of the zones doesn't matter, only the center of the zone is important. Place the center of these Reference Zones at
-- specific scenery objects or points of interest (like cities, rivers, hills, crossing etc).
-- The trigger zones indicating a Reference Zone need to follow a specific syntax.
-- The name of each trigger zone expressing a Reference Zone need to start with a classification name of the object,
-- followed by a #, followed by a symbolic name of the Reference Zone.
-- A few examples:
-- 
--   * A church at Tskinvali would be indicated as: *Church#Tskinvali*
--   * A train station near Kobuleti would be indicated as: *Station#Kobuleti*
-- 
-- Taking the above example, this is how this method would be used:
-- 
--     CC:SetReferenceZones( "Church" )
--     CC:SetReferenceZones( "Station" )
-- 
-- 
-- @param #COMMANDCENTER self
-- @param #string ReferenceZonePrefix The name before the #-mark indicating the class of the Reference Zones.
-- @return #COMMANDCENTER
function COMMANDCENTER:SetReferenceZones( ReferenceZonePrefix )
  local MatchPattern = "(.*)#(.*)"
  self:F( { MatchPattern = MatchPattern } )
  for ReferenceZoneName in pairs( _DATABASE.ZONENAMES ) do
    local ZoneName, ReferenceName = string.match( ReferenceZoneName, MatchPattern )
    self:F( { ZoneName = ZoneName, ReferenceName = ReferenceName } )
    if ZoneName and ReferenceName and ZoneName == ReferenceZonePrefix then
      self.ReferencePoints[ReferenceZoneName] = ZONE:New( ReferenceZoneName )
      self.ReferenceNames[ReferenceZoneName] = ReferenceName
    end
  end
  return self
end

--- Set the commandcenter operations in WWII mode
-- This will disable LL, MGRS, BRA, BULLS navigatin messages sent by the Command Center, 
-- and will be replaced by a navigation using Reference Zones.
-- It will also disable the settings at the settings menu for these.
-- @param #COMMANDCENTER self
-- @return #COMMANDCENTER
function COMMANDCENTER:SetModeWWII()
  self.CommunicationMode = "WWII"
  return self
end


--- Returns if the commandcenter operations is in WWII mode
-- @param #COMMANDCENTER self
-- @return #boolean true if in WWII mode.
function COMMANDCENTER:IsModeWWII()
  return self.CommunicationMode == "WWII"
end




--- Sets the menu structure of the Missions governed by the HQ command center.
-- @param #COMMANDCENTER self
function COMMANDCENTER:SetMenu()
  self:F2()

  local MenuTime = timer.getTime()
  for MissionID, Mission in pairs( self:GetMissions() or {} ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Mission:SetMenu( MenuTime )
  end

  for MissionID, Mission in pairs( self:GetMissions() or {} ) do
    Mission = Mission -- Tasking.Mission#MISSION
    Mission:RemoveMenu( MenuTime )
  end
  
end

--- Gets the commandcenter menu structure governed by the HQ command center.
-- @param #COMMANDCENTER self
-- @param Wrapper.Group#Group TaskGroup Task Group.
-- @return Core.Menu#MENU_COALITION
function COMMANDCENTER:GetMenu( TaskGroup )

  local MenuTime = timer.getTime()

  self.CommandCenterMenus = self.CommandCenterMenus or {}
  local CommandCenterMenu
  
  local CommandCenterText = self:GetText()
  CommandCenterMenu = MENU_GROUP:New( TaskGroup, CommandCenterText ):SetTime(MenuTime)
  self.CommandCenterMenus[TaskGroup] = CommandCenterMenu

  if self.AutoAssignTasks == false then
    local AssignTaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, "Assign Task", CommandCenterMenu, self.AssignTask, self, TaskGroup ):SetTime(MenuTime):SetTag("AutoTask")
  end
  CommandCenterMenu:Remove( MenuTime, "AutoTask" )
    
  return self.CommandCenterMenus[TaskGroup]
end


--- Assigns a random task to a TaskGroup.
-- @param #COMMANDCENTER self
-- @return #COMMANDCENTER
function COMMANDCENTER:AssignTask( TaskGroup )

  local Tasks = {}
  local AssignPriority = 99999999
  local AutoAssignMethod = self.AutoAssignMethod

  for MissionID, Mission in pairs( self:GetMissions() ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    local MissionTasks = Mission:GetGroupTasks( TaskGroup )
    for MissionTaskName, MissionTask in pairs( MissionTasks or {} ) do
      local MissionTask = MissionTask -- Tasking.Task#TASK
      if MissionTask:IsStatePlanned() or MissionTask:IsStateReplanned() or MissionTask:IsStateAssigned() then
        local TaskPriority = MissionTask:GetAutoAssignPriority( self.AutoAssignMethod, self, TaskGroup )
        if TaskPriority < AssignPriority then
          AssignPriority = TaskPriority
          Tasks = {}
        end
        if TaskPriority == AssignPriority then
          Tasks[#Tasks+1] = MissionTask
        end
      end
    end
  end
  
  local Task = Tasks[ math.random( 1, #Tasks ) ] -- Tasking.Task#TASK
  
  if Task then

    self:I( "Assigning task " .. Task:GetName() .. " using auto assign method " .. self.AutoAssignMethod .. " to " .. TaskGroup:GetName() .. " with task priority " .. AssignPriority )
    
    if not self.AutoAcceptTasks == true then
      Task:SetAutoAssignMethod( ACT_ASSIGN_MENU_ACCEPT:New( Task.TaskBriefing ) )
    end
    
    Task:AssignToGroup( TaskGroup )
    
  end

end


--- Sets the menu of the command center.
-- This command is called within the :New() method.
-- @param #COMMANDCENTER self
function COMMANDCENTER:SetCommandMenu()

  local MenuTime = timer.getTime()
  
  if self.CommandCenterPositionable and self.CommandCenterPositionable:IsInstanceOf(GROUP) then
    local CommandCenterText = self:GetText()
    local CommandCenterMenu = MENU_GROUP:New( self.CommandCenterPositionable, CommandCenterText ):SetTime(MenuTime)
  
    if self.AutoAssignTasks == false then
      local AutoAssignTaskMenu = MENU_GROUP_COMMAND:New( self.CommandCenterPositionable, "Assign Task On", CommandCenterMenu, self.SetAutoAssignTasks, self, true ):SetTime(MenuTime):SetTag("AutoTask")
    else
      local AutoAssignTaskMenu = MENU_GROUP_COMMAND:New( self.CommandCenterPositionable, "Assign Task Off", CommandCenterMenu, self.SetAutoAssignTasks, self, false ):SetTime(MenuTime):SetTag("AutoTask")
    end
    CommandCenterMenu:Remove( MenuTime, "AutoTask" )
  end

end



--- Automatically assigns tasks to all TaskGroups.
-- One of the most important roles of the command center is the management of tasks.
-- When this method is used with a parameter true; the command center will scan at regular intervals which players in a slot are not having a task assigned.
-- For those players; the tasking is enabled to assign automatically a task.
-- An Assign Menu will be accessible for the player under the command center menu, to configure the automatic tasking to switched on or off.
-- @param #COMMANDCENTER self
-- @param #boolean AutoAssign true for ON and false or nil for OFF.
function COMMANDCENTER:SetAutoAssignTasks( AutoAssign )

  self.AutoAssignTasks = AutoAssign or false
  
  if self.AutoAssignTasks == true then
    self:ScheduleRepeat( 10, 30, 0, nil, self.AssignTasks, self )
  else
    self:ScheduleStop( self.AssignTasks )
  end
  
end

--- Automatically accept tasks for all TaskGroups.
-- When a task is assigned; the mission designer can decide if players are immediately assigned to the task; or they can accept/reject the assigned task.
-- If the tasks are not automatically accepted; the player will receive a message that he needs to access the command center menu and
-- choose from 2 added menu options either to accept or reject the assigned task within 30 seconds.
-- If the task is not accepted within 30 seconds; the task will be cancelled and a new task will be assigned.
-- @param #COMMANDCENTER self
-- @param #boolean AutoAccept true for ON and false or nil for OFF.
function COMMANDCENTER:SetAutoAcceptTasks( AutoAccept )

  self.AutoAcceptTasks = AutoAccept or false
  
end


--- Define the method to be used to assign automatically a task from the available tasks in the mission.
-- There are 3 types of methods that can be applied for the moment:
-- 
--   1. Random - assigns a random task in the mission to the player.
--   2. Distance - assigns a task based on a distance evaluation from the player. The closest are to be assigned first.
--   3. Priority - assigns a task based on the priority as defined by the mission designer, using the SetTaskPriority parameter.
--   
-- The different task classes implement the logic to determine the priority of automatic task assignment to a player, depending on one of the above methods.
-- The method @{Tasking.Task#TASK.GetAutoAssignPriority} calculate the priority of the tasks to be assigned. 
-- @param #COMMANDCENTER self
-- @param #COMMANDCENTER.AutoAssignMethods AutoAssignMethod A selection of an assign method from the COMMANDCENTER.AutoAssignMethods enumeration.
function COMMANDCENTER:SetAutoAssignMethod( AutoAssignMethod )

  self.AutoAssignMethod = AutoAssignMethod or COMMANDCENTER.AutoAssignMethods.Random
  
end

--- Automatically assigns tasks to all TaskGroups.
-- @param #COMMANDCENTER self
function COMMANDCENTER:AssignTasks()

  local GroupSet = self:AddGroups()

  for GroupID, TaskGroup in pairs( GroupSet:GetSet() ) do
    local TaskGroup = TaskGroup -- Wrapper.Group#GROUP
    
    if TaskGroup:IsAlive() then
      self:GetMenu( TaskGroup )
      
      if self:IsGroupAssigned( TaskGroup ) then
      else
        -- Only groups with planes or helicopters will receive automatic tasks.
        -- TODO Workaround DCS-BUG-3 - https://github.com/FlightControl-Master/MOOSE/issues/696
        if TaskGroup:IsAir() then
          self:AssignTask( TaskGroup )
        end
      end
    end
  end

end


--- Get all the Groups active within the command center.
-- @param #COMMANDCENTER self
-- @return Core.Set#SET_GROUP The set of groups active within the command center.
function COMMANDCENTER:AddGroups()

  local GroupSet = SET_GROUP:New()
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    GroupSet = Mission:AddGroups( GroupSet )
  end
  
  return GroupSet
end


--- Checks of the TaskGroup has a Task.
-- @param #COMMANDCENTER self
-- @return #boolean When true, the TaskGroup has a Task, otherwise the returned value will be false.
function COMMANDCENTER:IsGroupAssigned( TaskGroup )

  local Assigned = false
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    if Mission:IsGroupAssigned( TaskGroup ) then
      Assigned = true
      break
    end
  end
  
  return Assigned
end


--- Checks of the command center has the given MissionGroup.
-- @param #COMMANDCENTER self
-- @param Wrapper.Group#GROUP MissionGroup The group active within one of the missions governed by the command center.
-- @return #boolean
function COMMANDCENTER:HasGroup( MissionGroup )

  local Has = false
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    if Mission:HasGroup( MissionGroup ) then
      Has = true
      break
    end      
  end
  
  return Has
end

--- Let the command center send a Message to all players.
-- @param #COMMANDCENTER self
-- @param #string Message The message text.
function COMMANDCENTER:MessageToAll( Message )

    self:GetPositionable():MessageToAll( Message, 20, self:GetName() )

end

--- Let the command center send a message to the MessageGroup.
-- @param #COMMANDCENTER self
-- @param #string Message The message text.
-- @param Wrapper.Group#GROUP MessageGroup The group to receive the message.
function COMMANDCENTER:MessageToGroup( Message, MessageGroup )

  self:GetPositionable():MessageToGroup( Message, 15, MessageGroup, self:GetShortText() )

end

--- Let the command center send a message to the MessageGroup.
-- @param #COMMANDCENTER self
-- @param #string Message The message text.
-- @param Wrapper.Group#GROUP MessageGroup The group to receive the message.
-- @param Core.Message#MESSAGE.MessageType MessageType The type of the message, resulting in automatic time duration and prefix of the message.
function COMMANDCENTER:MessageTypeToGroup( Message, MessageGroup, MessageType )

  self:GetPositionable():MessageTypeToGroup( Message, MessageType, MessageGroup, self:GetShortText() )

end

--- Let the command center send a message to the coalition of the command center.
-- @param #COMMANDCENTER self
-- @param #string Message The message text.
function COMMANDCENTER:MessageToCoalition( Message )

  local CCCoalition = self:GetPositionable():GetCoalition()
    --TODO: Fix coalition bug!
    
    self:GetPositionable():MessageToCoalition( Message, 15, CCCoalition, self:GetShortText() )

end


--- Let the command center send a message of a specified type to the coalition of the command center.
-- @param #COMMANDCENTER self
-- @param #string Message The message text.
-- @param Core.Message#MESSAGE.MessageType MessageType The type of the message, resulting in automatic time duration and prefix of the message.
function COMMANDCENTER:MessageTypeToCoalition( Message, MessageType )

  local CCCoalition = self:GetPositionable():GetCoalition()
    --TODO: Fix coalition bug!
    
    self:GetPositionable():MessageTypeToCoalition( Message, MessageType, CCCoalition, self:GetShortText() )

end


--- Let the command center send a report of the status of all missions to a group.
-- Each Mission is listed, with an indication how many Tasks are still to be completed.
-- @param #COMMANDCENTER self
-- @param Wrapper.Group#GROUP ReportGroup The group to receive the report.
function COMMANDCENTER:ReportSummary( ReportGroup )
  self:F( ReportGroup )

  local Report = REPORT:New()

  -- List the name of the mission.
  local Name = self:GetName()
  Report:Add( string.format( '%s - Report Summary Missions', Name ) )
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Report:Add( " - " .. Mission:ReportSummary( ReportGroup ) )
  end
  
  self:MessageToGroup( Report:Text(), ReportGroup )
end

--- Let the command center send a report of the players of all missions to a group.
-- Each Mission is listed, with an indication how many Tasks are still to be completed.
-- @param #COMMANDCENTER self
-- @param Wrapper.Group#GROUP ReportGroup The group to receive the report.
function COMMANDCENTER:ReportMissionsPlayers( ReportGroup )
  self:F( ReportGroup )

  local Report = REPORT:New()
  
  Report:Add( "Players active in all missions." )

  for MissionID, MissionData in pairs( self.Missions ) do
    local Mission = MissionData -- Tasking.Mission#MISSION
    Report:Add( " - " .. Mission:ReportPlayersPerTask(ReportGroup) )
  end
  
  self:MessageToGroup( Report:Text(), ReportGroup )
end

--- Let the command center send a report of the status of a task to a group.
-- Report the details of a Mission, listing the Mission, and all the Task details.
-- @param #COMMANDCENTER self
-- @param Wrapper.Group#GROUP ReportGroup The group to receive the report.
-- @param Tasking.Task#TASK Task The task to be reported.
function COMMANDCENTER:ReportDetails( ReportGroup, Task )
  self:F( ReportGroup )

  local Report = REPORT:New()
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Report:Add( " - " .. Mission:ReportDetails() )
  end
  
  self:MessageToGroup( Report:Text(), ReportGroup )
end


--- Let the command center flash a report of the status of the subscribed task to a group.
-- @param #COMMANDCENTER self
function COMMANDCENTER:SetFlashStatus( Flash )
  self:F()

  self.FlashStatus = Flash or true

end
