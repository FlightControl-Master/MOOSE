--- **Tasking** - The TASK_Protect models tasks for players to protect or capture specific zones.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: MillerTime
-- 
-- ====
--   
-- @module Task_Protect

do -- TASK_PROTECT

  --- The TASK_PROTECT class
  -- @type TASK_PROTECT
  -- @field Functional.Protect#PROTECT Protect
  -- @extends Tasking.Task#TASK

  --- # TASK_PROTECT class, extends @{Task#TASK}
  -- 
  -- The TASK_PROTECT class defines the task to protect or capture a protection zone. 
  -- The TASK_PROTECT is implemented using a @{Fsm#FSM_TASK}, and has the following statuses:
  -- 
  --   * **None**: Start of the process
  --   * **Planned**: The A2G task is planned.
  --   * **Assigned**: The A2G task is assigned to a @{Group#GROUP}.
  --   * **Success**: The A2G task is successfully completed.
  --   * **Failed**: The A2G task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- ## Set the scoring of achievements in an A2G attack.
  -- 
  -- Scoring or penalties can be given in the following circumstances:
  -- 
  --   * @{#TASK_PROTECT.SetScoreOnDestroy}(): Set a score when a target in scope of the A2G attack, has been destroyed.
  --   * @{#TASK_PROTECT.SetScoreOnSuccess}(): Set a score when all the targets in scope of the A2G attack, have been destroyed.
  --   * @{#TASK_PROTECT.SetPenaltyOnFailed}(): Set a penalty when the A2G attack has failed.
  -- 
  -- @field #TASK_PROTECT
  TASK_PROTECT = {
    ClassName = "TASK_PROTECT",
  }
  
  --- Instantiates a new TASK_PROTECT.
  -- @param #TASK_PROTECT self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Functional.Protect#PROTECT Protect
  -- @return #TASK_PROTECT self
  function TASK_PROTECT:New( Mission, SetGroup, TaskName, Protect, TaskType, TaskBriefing )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, TaskType, TaskBriefing ) ) -- #TASK_PROTECT
    self:F()
  
    self.Protect = Protect
    self.TaskType = TaskType
    
    local Fsm = self:GetUnitProcess()
    

    Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "ProtectZone", Rejected = "Reject" }  )
    
    Fsm:AddTransition( "Assigned", "ProtectZone", "Protecting" )
    Fsm:AddProcess   ( "Protecting", "Protect", "Protecting", {} )
    Fsm:AddTransition( "Protecting", "RouteToTarget", "Protecting" )
    Fsm:AddProcess( "Protecting", "RouteToTargetZone", ACT_ROUTE_ZONE:New(), {} )
    
    --Fsm:AddTransition( "Accounted", "DestroyedAll", "Accounted" )
    --Fsm:AddTransition( "Accounted", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    
    self:SetTargetZone( self.Protect:GetProtectZone() )
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_PROTECT Task
    function Fsm:onafterProtectZone( TaskUnit, Task )
      self:E( { self } )
      self:__Protect( 0.1 )
      self:__RouteToTarget( 0.1 )
    end
    
    --- Protect Loop
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_PROTECT Task
    function Fsm:onafterProtect( TaskUnit, Task )
      self:E( { self } )
      self:__Protect( 15 )
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2G#TASK_PROTECT Task
    function Fsm:onafterRouteToTarget( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      if Task:GetTargetZone( TaskUnit ) then
        self:__RouteToTargetZone( 0.1 )
      end
    end
    
    return self
 
  end

  --- @param #TASK_PROTECT self
  -- @param Functional.Protect#PROTECT Protect The Protect Engine.
  function TASK_PROTECT:SetProtect( Protect )
  
    self.Protect = Protect -- Functional.Protect#PROTECT
  end
   

  
  --- @param #TASK_PROTECT self
  function TASK_PROTECT:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.Protect:GetProtectZoneName() .. " )"
  end

  
  --- @param #TASK_PROTECT self
  -- @param Core.Zone#ZONE_BASE TargetZone The Zone object where the Target is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_PROTECT:SetTargetZone( TargetZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteProtectZone = ProcessUnit:GetProcess( "Protecting", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteProtectZone:SetZone( TargetZone )
  end
   

  --- @param #TASK_PROTECT self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the Target is located on the map.
  function TASK_PROTECT:GetTargetZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteProtectZone = ProcessUnit:GetProcess( "Protecting", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteProtectZone:GetZone()
  end

  function TASK_PROTECT:SetGoalTotal()
  
    self.GoalTotal = 1
  end

  function TASK_PROTECT:GetGoalTotal()
  
    return self.GoalTotal
  end

end 


do -- TASK_CAPTURE_ZONE

  --- The TASK_CAPTURE_ZONE class
  -- @type TASK_CAPTURE_ZONE
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task_Protect#TASK_PROTECT

  --- # TASK_CAPTURE_ZONE class, extends @{Task_A2G#TASK_PROTECT}
  -- 
  -- The TASK_CAPTURE_ZONE class defines an Suppression or Extermination of Air Defenses task for a human player to be executed.
  -- These tasks are important to be executed as they will help to achieve air superiority at the vicinity.
  -- 
  -- The TASK_CAPTURE_ZONE is used by the @{Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create SEAD tasks 
  -- based on detected enemy ground targets.
  -- 
  -- @field #TASK_CAPTURE_ZONE
  TASK_CAPTURE_ZONE = {
    ClassName = "TASK_CAPTURE_ZONE",
  }
  
  --- Instantiates a new TASK_CAPTURE_ZONE.
  -- @param #TASK_CAPTURE_ZONE self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Functional.Protect#PROTECT Protect
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_CAPTURE_ZONE self
  function TASK_CAPTURE_ZONE:New( Mission, SetGroup, TaskName, Protect, TaskBriefing)
    local self = BASE:Inherit( self, TASK_PROTECT:New( Mission, SetGroup, TaskName, Protect, "CAPTURE", TaskBriefing ) ) -- #TASK_CAPTURE_ZONE
    self:F()
    
    Mission:AddTask( self )
    
    self:SetBriefing( 
      TaskBriefing or 
      "Capture zone " .. self.Protect:GetProtectZoneName() .. "."
    )

    return self
  end 

  --- Instantiates a new TASK_CAPTURE_ZONE.
  -- @param #TASK_CAPTURE_ZONE self
  function TASK_CAPTURE_ZONE:UpdateTaskInfo() 


    local ZoneCoordinate = self.Protect:GetProtectZone():GetCoordinate() 
    self:SetInfo( "Coordinates", ZoneCoordinate, 0 )

  end
    
  function TASK_CAPTURE_ZONE:ReportOrder( ReportGroup ) 
    local Coordinate = self:GetInfo( "Coordinates" )
    --local Coordinate = self.TaskInfo.Coordinates.TaskInfoText
    local Distance = ReportGroup:GetCoordinate():Get2DDistance( Coordinate )
    
    return Distance
  end
  
  
  --- @param #TASK_CAPTURE_ZONE self
  function TASK_CAPTURE_ZONE:onafterGoal( TaskUnit, From, Event, To )
    
    if self.Protect:IsState( "Captured" ) then
      self:Success()
    end
    
    self:__Goal( -10 )
  end

  --- Set a score when a target in scope of the A2G attack, has been destroyed .
  -- @param #TASK_CAPTURE_ZONE self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points to be granted when task process has been achieved.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CAPTURE_ZONE
  function TASK_CAPTURE_ZONE:SetScoreOnProgress( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    --ProcessUnit:AddScoreProcess( "Protecting", "Protect", "Captured", "Player " .. PlayerName .. " has SEADed a target.", Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2G attack, have been destroyed.
  -- @param #TASK_CAPTURE_ZONE self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CAPTURE_ZONE
  function TASK_CAPTURE_ZONE:SetScoreOnSuccess( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", "The zone has been captured!", Score )
    
    return self
  end

  --- Set a penalty when the A2G attack has failed.
  -- @param #TASK_CAPTURE_ZONE self
  -- @param #string PlayerName The name of the player.
  -- @param #number Penalty The penalty in points, must be a negative value!
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CAPTURE_ZONE
  function TASK_CAPTURE_ZONE:SetScoreOnFail( PlayerName, Penalty, TaskUnit )
    self:F( { PlayerName, Penalty, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", "The zone has been lost!", Penalty )
    
    return self
  end


end

