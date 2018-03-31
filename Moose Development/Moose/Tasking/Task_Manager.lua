--- This module contains the TASK_MANAGER class and derived classes.
-- 
-- ===
-- 
-- 1) @{Task_Manager#TASK_MANAGER} class, extends @{Fsm#FSM}
-- ===
-- The @{Task_Manager#TASK_MANAGER} class defines the core functions to report tasks to groups.
-- Reportings can be done in several manners, and it is up to the derived classes if TASK_MANAGER to model the reporting behaviour.
-- 
-- 1.1) TASK_MANAGER constructor:
-- -----------------------------------
--   * @{Task_Manager#TASK_MANAGER.New}(): Create a new TASK_MANAGER instance.
-- 
-- 1.2) TASK_MANAGER reporting:
-- ---------------------------------
-- Derived TASK_MANAGER classes will manage tasks using the method @{Task_Manager#TASK_MANAGER.ManageTasks}(). This method implements polymorphic behaviour.
-- 
-- The time interval in seconds of the task management can be changed using the methods @{Task_Manager#TASK_MANAGER.SetRefreshTimeInterval}(). 
-- To control how long a reporting message is displayed, use @{Task_Manager#TASK_MANAGER.SetReportDisplayTime}().
-- Derived classes need to implement the method @{Task_Manager#TASK_MANAGER.GetReportDisplayTime}() to use the correct display time for displayed messages during a report.
-- 
-- Task management can be started and stopped using the methods @{Task_Manager#TASK_MANAGER.StartTasks}() and @{Task_Manager#TASK_MANAGER.StopTasks}() respectively.
-- If an ad-hoc report is requested, use the method @{Task_Manager#TASK_MANAGER#ManageTasks}().
-- 
-- The default task management interval is every 60 seconds.
-- 
-- ===
-- 
-- ### Contributions: Mechanist, Prof_Hilactic, FlightControl - Concept & Testing
-- ### Author: FlightControl - Framework Design &  Programming
-- 
-- @module Task_Manager

do -- TASK_MANAGER
  
  --- TASK_MANAGER class.
  -- @type TASK_MANAGER
  -- @field Set#SET_GROUP SetGroup The set of group objects containing players for which tasks are managed.
  -- @extends Core.Fsm#FSM
  TASK_MANAGER = {
    ClassName = "TASK_MANAGER",
    SetGroup = nil,
  }
  
  --- TASK\_MANAGER constructor.
  -- @param #TASK_MANAGER self
  -- @param Set#SET_GROUP SetGroup The set of group objects containing players for which tasks are managed.
  -- @return #TASK_MANAGER self
  function TASK_MANAGER:New( SetGroup )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM:New() ) -- #TASK_MANAGER
    
    self.SetGroup = SetGroup
    
    self:SetStartState( "Stopped" )
    self:AddTransition( "Stopped", "StartTasks", "Started" )
    
    --- StartTasks Handler OnBefore for TASK_MANAGER
    -- @function [parent=#TASK_MANAGER] OnBeforeStartTasks
    -- @param #TASK_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- StartTasks Handler OnAfter for TASK_MANAGER
    -- @function [parent=#TASK_MANAGER] OnAfterStartTasks
    -- @param #TASK_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- StartTasks Trigger for TASK_MANAGER
    -- @function [parent=#TASK_MANAGER] StartTasks
    -- @param #TASK_MANAGER self
    
    --- StartTasks Asynchronous Trigger for TASK_MANAGER
    -- @function [parent=#TASK_MANAGER] __StartTasks
    -- @param #TASK_MANAGER self
    -- @param #number Delay
    
    
    
    self:AddTransition( "Started", "StopTasks", "Stopped" )
    
    --- StopTasks Handler OnBefore for TASK_MANAGER
    -- @function [parent=#TASK_MANAGER] OnBeforeStopTasks
    -- @param #TASK_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- StopTasks Handler OnAfter for TASK_MANAGER
    -- @function [parent=#TASK_MANAGER] OnAfterStopTasks
    -- @param #TASK_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- StopTasks Trigger for TASK_MANAGER
    -- @function [parent=#TASK_MANAGER] StopTasks
    -- @param #TASK_MANAGER self
    
    --- StopTasks Asynchronous Trigger for TASK_MANAGER
    -- @function [parent=#TASK_MANAGER] __StopTasks
    -- @param #TASK_MANAGER self
    -- @param #number Delay
    

    self:AddTransition( "Started", "Manage", "Started" )

    self:SetRefreshTimeInterval( 30 )
  
    return self
  end
  
  function TASK_MANAGER:onafterStartTasks( From, Event, To )
    self:Manage()
  end
  
  function TASK_MANAGER:onafterManage( From, Event, To )

    self:__Manage( -self._RefreshTimeInterval )

    self:ManageTasks()
  end
  
  --- Set the refresh time interval in seconds when a new task management action needs to be done.
  -- @param #TASK_MANAGER self
  -- @param #number RefreshTimeInterval The refresh time interval in seconds when a new task management action needs to be done.
  -- @return #TASK_MANAGER self
  function TASK_MANAGER:SetRefreshTimeInterval( RefreshTimeInterval )
    self:F2()
  
    self._RefreshTimeInterval = RefreshTimeInterval
  end
  
  
  --- Manages the tasks for the @{Set#SET_GROUP}.
  -- @param #TASK_MANAGER self
  -- @return #TASK_MANAGER self
  function TASK_MANAGER:ManageTasks()
    self:E()
  
  end

end

