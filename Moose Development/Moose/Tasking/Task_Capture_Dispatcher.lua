--- **Tasking** - Creates and manages player TASK_ZONE_CAPTURE tasks.
-- 
-- The **TASK_CAPTURE_DISPATCHER** allows you to setup various tasks for let human
-- players capture zones in a co-operation effort. 
--  
-- The dispatcher will implement for you mechanisms to create capture zone tasks:
--  
--   * As setup by the mission designer.
--   * Dynamically capture zone tasks.
--   
-- 
--   
-- **Specific features:**
-- 
--   * Creates a task to capture zones and achieve mission goals.
--   * Orchestrate the task flow, so go from Planned to Assigned to Success, Failed or Cancelled.
--   * Co-operation tasking, so a player joins a group of players executing the same task.
-- 
-- 
-- **A complete task menu system to allow players to:**
--   
--   * Join the task, abort the task.
--   * Mark the location of the zones to capture on the map.
--   * Provide details of the zones.
--   * Route to the zones.
--   * Display the task briefing.
--   
--   
-- **A complete mission menu system to allow players to:**
--   
--   * Join a task, abort the task.
--   * Display task reports.
--   * Display mission statistics.
--   * Mark the task locations on the map.
--   * Provide details of the zones.
--   * Display the mission briefing.
--   * Provide status updates as retrieved from the command center.
--   * Automatically assign a random task as part of a mission.
--   * Manually assign a specific task as part of a mission.
--   
--   
--  **A settings system, using the settings menu:**
--  
--   * Tweak the duration of the display of messages.
--   * Switch between metric and imperial measurement system.
--   * Switch between coordinate formats used in messages: BR, BRA, LL DMS, LL DDM, MGRS.
--   * Various other options.
--   
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Tasking.Task_Capture_Dispatcher
-- @image MOOSE.JPG

do -- TASK_CAPTURE_DISPATCHER

  --- TASK_CAPTURE_DISPATCHER class.
  -- @type TASK_CAPTURE_DISPATCHER
  -- @extends Tasking.Task_Manager#TASK_MANAGER
  -- @field TASK_CAPTURE_DISPATCHER.ZONE ZONE

  --- @type TASK_CAPTURE_DISPATCHER.CSAR
  -- @field Wrapper.Unit#UNIT PilotUnit
  -- @field Tasking.Task#TASK Task
  

  --- Implements the dynamic dispatching of capture zone tasks.
  -- 
  -- The **TASK_CAPTURE_DISPATCHER** allows you to setup various tasks for let human
  -- players capture zones in a co-operation effort. 
  --  
  -- Let's explore **step by step** how to setup the task capture zone dispatcher.
  -- 
  -- # 1. Setup a mission environment.
  -- 
  -- It is easy, as it works just like any other task setup, so setup a command center and a mission.
  -- 
  -- ## 1.1. Create a command center.
  -- 
  -- First you need to create a command center using the @{Tasking.CommandCenter#COMMANDCENTER.New}() constructor.
  -- The command assumes that you´ve setup a group in the mission editor with the name HQ.
  -- This group will act as the command center object.
  -- It is a good practice to mark this group as invisible and invulnerable.
  -- 
  --     local CommandCenter = COMMANDCENTER
  --        :New( GROUP:FindByName( "HQ" ), "HQ" ) -- Create the CommandCenter.
  --     
  -- ## 1.2. Create a mission.
  -- 
  -- Tasks work in a **mission**, which groups these tasks to achieve a joint **mission goal**. A command center can **govern multiple missions**.
  -- 
  -- Create a new mission, using the @{Tasking.Mission#MISSION.New}() constructor.
  -- 
  --     -- Declare the Mission for the Command Center.
  --     local Mission = MISSION
  --       :New( CommandCenter, 
  --             "Overlord", 
  --             "High", 
  --             "Capture the blue zones.", 
  --             coalition.side.RED 
  --           ) 
  -- 
  -- 
  -- # 2. Dispatch a **capture zone** task.
  -- 
  -- So, now that we have a command center and a mission, we now create the capture zone task.
  -- We create the capture zone task using the @{#TASK_CAPTURE_DISPATCHER.AddCaptureZoneTask}() constructor.
  -- 
  -- ## 2.1. Create the capture zones.
  -- 
  -- Because a capture zone task will not generate the capture zones, you'll need to create them first.
  -- 
  --     
  --     -- We define here a capture zone; of the type ZONE_CAPTURE_COALITION.
  --     -- The zone to be captured has the name Alpha, and was defined in the mission editor as a trigger zone.
  --     CaptureZone = ZONE:New( "Alpha" )
  --     CaptureZoneCoalitionApha = ZONE_CAPTURE_COALITION:New( CaptureZone, coalition.side.RED )
  -- 
  -- ## 2.2. Create a set of player groups.
  --    
  -- What is also needed, is to have a set of @{Core.Group}s defined that contains the clients of the players.
  -- 
  --     -- Allocate the player slots, which must be aircraft (airplanes or helicopters), that can be manned by players.
  --     -- We use the method FilterPrefixes to filter those player groups that have client slots, as defined in the mission editor.
  --     -- In this example, we filter the groups where the name starts with "Blue Player", which captures the blue player slots.
  --     local PlayerGroupSet = SET_GROUP:New():FilterPrefixes( "Blue Player" ):FilterStart()
  -- 
  -- ## 2.3. Setup the capture zone task.
  -- 
  -- First, we need to create a TASK_CAPTURE_DISPATCHER object.
  -- 
  --     TaskCaptureZoneDispatcher = TASK_CAPTURE_DISPATCHER:New( Mission, PilotGroupSet )
  -- 
  -- So, the variable `TaskCaptureZoneDispatcher` will contain the object of class TASK_CAPTURE_DISPATCHER, 
  -- which will allow you to dispatch capture zone tasks:
  --  
  --   * for mission `Mission`, as was defined in section 1.2.
  --   * for the group set `PilotGroupSet`, as was defined in section 2.2.
  -- 
  -- Now that we have `TaskDispatcher` object, we can now **create the TaskCaptureZone**, using the @{#TASK_CAPTURE_DISPATCHER.AddCaptureZoneTask}() method!
  -- 
  --     local TaskCaptureZone = TaskCaptureZoneDispatcher:AddCaptureZoneTask( 
  --       "Capture zone Alpha", 
  --       CaptureZoneCoalitionAlpha, 
  --       "Fly to zone Alpha and eliminate all enemy forces to capture it." )
  -- 
  -- As a result of this code, the `TaskCaptureZone` (returned) variable will contain an object of @{#TASK_CAPTURE_ZONE}!
  -- We pass to the method the title of the task, and the `CaptureZoneCoalitionAlpha`, which is the zone to be captured, as defined in section 2.1!
  -- This returned `TaskCaptureZone` object can now be used to setup additional task configurations, or to control this specific task with special events.
  -- 
  -- And you're done! As you can see, it is a small bit of work, but the reward is great.
  -- And, because all this is done using program interfaces, you can easily build a mission to capture zones yourself!
  -- Based on various events happening within your mission, you can use the above methods to create new capture zones, 
  -- and setup a new capture zone task and assign it to a group of players, while your mission is running!
  -- 
  --     
  -- 
  -- @field #TASK_CAPTURE_DISPATCHER
  TASK_CAPTURE_DISPATCHER = {
    ClassName = "TASK_CAPTURE_DISPATCHER",
    Mission = nil,
    Tasks = {},
    Zones = {},
    ZoneCount = 0,
  }


  
  TASK_CAPTURE_DISPATCHER.AI_A2G_Dispatcher = nil -- AI.AI_A2G_Dispatcher#AI_A2G_DISPATCHER
  
  --- TASK_CAPTURE_DISPATCHER constructor.
  -- @param #TASK_CAPTURE_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission The mission for which the task dispatching is done.
  -- @param Core.Set#SET_GROUP SetGroup The set of groups that can join the tasks within the mission.
  -- @return #TASK_CAPTURE_DISPATCHER self
  function TASK_CAPTURE_DISPATCHER:New( Mission, SetGroup )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, TASK_MANAGER:New( SetGroup ) ) -- #TASK_CAPTURE_DISPATCHER
    
    self.Mission = Mission
    self.FlashNewTask = false
    
    self:AddTransition( "Started", "Assign", "Started" )
    self:AddTransition( "Started", "ZoneCaptured", "Started" )
    
    self:__StartTasks( 5 )
    
    return self
  end


  --- Link a task capture dispatcher from the other coalition to understand its plan for defenses.
  -- This is used for the tactical overview, so the players also know the zones attacked by the other coalition!
  -- @param #TASK_CAPTURE_DISPATCHER self
  -- @param #TASK_CAPTURE_DISPATCHER DefenseTaskCaptureDispatcher
  function TASK_CAPTURE_DISPATCHER:SetDefenseTaskCaptureDispatcher( DefenseTaskCaptureDispatcher )
  
    self.DefenseTaskCaptureDispatcher = DefenseTaskCaptureDispatcher
  end


  --- Get the linked task capture dispatcher from the other coalition to understand its plan for defenses.
  -- This is used for the tactical overview, so the players also know the zones attacked by the other coalition!
  -- @param #TASK_CAPTURE_DISPATCHER self
  -- @return #TASK_CAPTURE_DISPATCHER
  function TASK_CAPTURE_DISPATCHER:GetDefenseTaskCaptureDispatcher()
  
    return self.DefenseTaskCaptureDispatcher
  end


  --- Link an AI A2G dispatcher from the other coalition to understand its plan for defenses.
  -- This is used for the tactical overview, so the players also know the zones attacked by the other AI A2G dispatcher!
  -- @param #TASK_CAPTURE_DISPATCHER self
  -- @param AI.AI_A2G_Dispatcher#AI_A2G_DISPATCHER DefenseAIA2GDispatcher
  function TASK_CAPTURE_DISPATCHER:SetDefenseAIA2GDispatcher( DefenseAIA2GDispatcher )
  
    self.DefenseAIA2GDispatcher = DefenseAIA2GDispatcher
  end


  --- Get the linked AI A2G dispatcher from the other coalition to understand its plan for defenses.
  -- This is used for the tactical overview, so the players also know the zones attacked by the AI A2G dispatcher!
  -- @param #TASK_CAPTURE_DISPATCHER self
  -- @return AI.AI_A2G_Dispatcher#AI_A2G_DISPATCHER
  function TASK_CAPTURE_DISPATCHER:GetDefenseAIA2GDispatcher()
  
    return self.DefenseAIA2GDispatcher
  end


  --- Add a capture zone task.
  -- @param #TASK_CAPTURE_DISPATCHER self
  -- @param #string TaskPrefix (optional) The prefix of the capture zone task. 
  -- If no TaskPrefix is given, then "Capture" will be used as the TaskPrefix. 
  -- The TaskPrefix will be appended with a . + a number of 3 digits, if the TaskPrefix already exists in the task collection.
  -- @param Functional.CaptureZoneCoalition#ZONE_CAPTURE_COALITION CaptureZone The zone of the coalition to be captured as the task goal.
  -- @param #string Briefing The briefing of the task to be shown to the player.
  -- @return Tasking.Task_Capture_Zone#TASK_CAPTURE_ZONE
  -- @usage
  -- 
  --  
  function TASK_CAPTURE_DISPATCHER:AddCaptureZoneTask( TaskPrefix, CaptureZone, Briefing )

    local TaskName = TaskPrefix or "Capture"
    if self.Zones[TaskName] then
      self.ZoneCount = self.ZoneCount + 1
      TaskName = string.format( "%s.%03d", TaskName, self.ZoneCount )
    end
    
    self.Zones[TaskName] = {} 
    self.Zones[TaskName].CaptureZone = CaptureZone
    self.Zones[TaskName].Briefing = Briefing
    self.Zones[TaskName].Task = nil
    self.Zones[TaskName].TaskPrefix = TaskPrefix
    
    self:ManageTasks()
    
    return self.Zones[TaskName] and self.Zones[TaskName].Task
  end


  --- Link an AI_A2G_DISPATCHER to the TASK_CAPTURE_DISPATCHER.
  -- @param #TASK_CAPTURE_DISPATCHER self
  -- @param AI.AI_A2G_Dispatcher#AI_A2G_DISPATCHER AI_A2G_Dispatcher The AI Dispatcher to be linked to the tasking. 
  -- @return Tasking.Task_Capture_Zone#TASK_CAPTURE_ZONE
  function TASK_CAPTURE_DISPATCHER:Link_AI_A2G_Dispatcher( AI_A2G_Dispatcher )

    self.AI_A2G_Dispatcher = AI_A2G_Dispatcher -- AI.AI_A2G_Dispatcher#AI_A2G_DISPATCHER
    AI_A2G_Dispatcher.Detection:LockDetectedItems()

    return self
  end


  --- Assigns tasks to the @{Core.Set#SET_GROUP}.
  -- @param #TASK_CAPTURE_DISPATCHER self
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function TASK_CAPTURE_DISPATCHER:ManageTasks()
    self:F()
  
    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local Mission = self.Mission
    
    if Mission:IsIDLE() or Mission:IsENGAGED() then
    
      local TaskReport = REPORT:New()
      
      -- Checking the task queue for the dispatcher, and removing any obsolete task!
      for TaskIndex, TaskData in pairs( self.Tasks ) do
        local Task = TaskData -- Tasking.Task#TASK
        if Task:IsStatePlanned() then
        -- Here we need to check if the pilot is still existing.
--            Task = self:RemoveTask( TaskIndex )
        end
        
      end

      -- Now that all obsolete tasks are removed, loop through the Zone tasks.
      for TaskName, CaptureZone in pairs( self.Zones ) do
        
        if not CaptureZone.Task then
          -- New Transport Task
          CaptureZone.Task = TASK_CAPTURE_ZONE:New( Mission, self.SetGroup, TaskName, CaptureZone.CaptureZone, CaptureZone.Briefing )
          CaptureZone.Task.TaskPrefix = CaptureZone.TaskPrefix -- We keep the TaskPrefix for further reference!
          Mission:AddTask( CaptureZone.Task )
          TaskReport:Add( TaskName )
          
          -- Link the Task Dispatcher to the capture zone task, because it is used on the UpdateTaskInfo.
          CaptureZone.Task:SetDispatcher( self )
          CaptureZone.Task:UpdateTaskInfo()

          function CaptureZone.Task.OnEnterAssigned( Task, From, Event, To )
            if self.AI_A2G_Dispatcher then
              self.AI_A2G_Dispatcher:Unlock( Task.TaskZoneName ) -- This will unlock the zone to be defended by AI.
            end        
            CaptureZone.Task:UpdateTaskInfo()
            CaptureZone.Task.ZoneGoal.Attacked = true
          end
          
          function CaptureZone.Task.OnEnterSuccess( Task, From, Event, To )
            --self:Success( Task )
            if self.AI_A2G_Dispatcher then
              self.AI_A2G_Dispatcher:Lock( Task.TaskZoneName ) -- This will lock the zone from being defended by AI.
            end
            CaptureZone.Task:UpdateTaskInfo()
            CaptureZone.Task.ZoneGoal.Attacked = false
          end

          function CaptureZone.Task.OnEnterCancelled( Task, From, Event, To )
            self:Cancelled( Task )
            if self.AI_A2G_Dispatcher then
              self.AI_A2G_Dispatcher:Lock( Task.TaskZoneName ) -- This will lock the zone from being defended by AI.
            end
            CaptureZone.Task:UpdateTaskInfo()
            CaptureZone.Task.ZoneGoal.Attacked = false
          end
            
          function CaptureZone.Task.OnEnterFailed( Task, From, Event, To )
            self:Failed( Task )
            if self.AI_A2G_Dispatcher then
              self.AI_A2G_Dispatcher:Lock( Task.TaskZoneName ) -- This will lock the zone from being defended by AI.
            end
            CaptureZone.Task:UpdateTaskInfo()
            CaptureZone.Task.ZoneGoal.Attacked = false
          end

          function CaptureZone.Task.OnEnterAborted( Task, From, Event, To )
            self:Aborted( Task )
            if self.AI_A2G_Dispatcher then
              self.AI_A2G_Dispatcher:Lock( Task.TaskZoneName ) -- This will lock the zone from being defended by AI.
            end
            CaptureZone.Task:UpdateTaskInfo()
            CaptureZone.Task.ZoneGoal.Attacked = false
          end

          -- Now broadcast the onafterCargoPickedUp event to the Task Cargo Dispatcher.
          function CaptureZone.Task.OnAfterCaptured( Task, From, Event, To, TaskUnit )
            self:Captured( Task, Task.TaskPrefix, TaskUnit )
            if self.AI_A2G_Dispatcher then
              self.AI_A2G_Dispatcher:Lock( Task.TaskZoneName ) -- This will lock the zone from being defended by AI.
            end
            CaptureZone.Task:UpdateTaskInfo()
            CaptureZone.Task.ZoneGoal.Attacked = false
          end

        end
        
      end
      
      
      -- TODO set menus using the HQ coordinator
      Mission:GetCommandCenter():SetMenu()

      local TaskText = TaskReport:Text(", ")
      
      for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
        if ( not Mission:IsGroupAssigned(TaskGroup) ) and TaskText ~= "" and ( not self.FlashNewTask ) then
          Mission:GetCommandCenter():MessageToGroup( string.format( "%s has tasks %s. Subscribe to a task using the radio menu.", Mission:GetShortText(), TaskText ), TaskGroup )
        end
      end
      
    end
    
    return true
  end

end
