--- **Tasking** - This module contains the DETECTION_MANAGER class and derived classes.
-- 
-- ===
-- 
-- The @{#DETECTION_MANAGER} class defines the core functions to report detected objects to groups.
-- Reportings can be done in several manners, and it is up to the derived classes if DETECTION_MANAGER to model the reporting behaviour.
-- 
-- 1.1) DETECTION_MANAGER constructor:
-- -----------------------------------
--   * @{#DETECTION_MANAGER.New}(): Create a new DETECTION_MANAGER instance.
-- 
-- 1.2) DETECTION_MANAGER reporting:
-- ---------------------------------
-- Derived DETECTION_MANAGER classes will reports detected units using the method @{#DETECTION_MANAGER.ReportDetected}(). This method implements polymorphic behaviour.
-- 
-- The time interval in seconds of the reporting can be changed using the methods @{#DETECTION_MANAGER.SetRefreshTimeInterval}(). 
-- To control how long a reporting message is displayed, use @{#DETECTION_MANAGER.SetReportDisplayTime}().
-- Derived classes need to implement the method @{#DETECTION_MANAGER.GetReportDisplayTime}() to use the correct display time for displayed messages during a report.
-- 
-- Reporting can be started and stopped using the methods @{#DETECTION_MANAGER.StartReporting}() and @{#DETECTION_MANAGER.StopReporting}() respectively.
-- If an ad-hoc report is requested, use the method @{#DETECTION_MANAGER#ReportNow}().
-- 
-- The default reporting interval is every 60 seconds. The reporting messages are displayed 15 seconds.
-- 
-- ===
-- 
-- 2) @{#DETECTION_REPORTING} class, extends @{#DETECTION_MANAGER}
-- ===
-- The @{#DETECTION_REPORTING} class implements detected units reporting. Reporting can be controlled using the reporting methods available in the @{Tasking.DetectionManager#DETECTION_MANAGER} class.
-- 
-- 2.1) DETECTION_REPORTING constructor:
-- -------------------------------
-- The @{#DETECTION_REPORTING.New}() method creates a new DETECTION_REPORTING instance.
--    
--    
-- ===
-- 
-- ### Contributions: Mechanist, Prof_Hilactic, FlightControl - Concept & Testing
-- ### Author: FlightControl - Framework Design &  Programming
-- 
-- @module Tasking.DetectionManager
-- @image Task_Detection_Manager.JPG

do -- DETECTION MANAGER
  
  --- @type DETECTION_MANAGER
  -- @field Core.Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Functional.Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @extends Core.Fsm#FSM

  --- DETECTION_MANAGER class.
  -- @field #DETECTION_MANAGER
  DETECTION_MANAGER = {
    ClassName = "DETECTION_MANAGER",
    SetGroup = nil,
    Detection = nil,
  }
  
  --- FAC constructor.
  -- @param #DETECTION_MANAGER self
  -- @param Core.Set#SET_GROUP SetGroup
  -- @param Functional.Detection#DETECTION_BASE Detection
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:New( SetGroup, Detection )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM:New() ) -- #DETECTION_MANAGER
    
    self.SetGroup = SetGroup
    self.Detection = Detection
    
    self:SetStartState( "Stopped" )
    self:AddTransition( "Stopped", "Start", "Started" )
    
    --- Start Handler OnBefore for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] OnBeforeStart
    -- @param #DETECTION_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Start Handler OnAfter for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] OnAfterStart
    -- @param #DETECTION_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Start Trigger for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] Start
    -- @param #DETECTION_MANAGER self
    
    --- Start Asynchronous Trigger for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] __Start
    -- @param #DETECTION_MANAGER self
    -- @param #number Delay
    
    
    
    self:AddTransition( "Started", "Stop", "Stopped" )
    
    --- Stop Handler OnBefore for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] OnBeforeStop
    -- @param #DETECTION_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Stop Handler OnAfter for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] OnAfterStop
    -- @param #DETECTION_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Stop Trigger for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] Stop
    -- @param #DETECTION_MANAGER self
    
    --- Stop Asynchronous Trigger for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] __Stop
    -- @param #DETECTION_MANAGER self
    -- @param #number Delay

    self:AddTransition( "Started", "Success", "Started" )
    
    --- Success Handler OnAfter for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] OnAfterSuccess
    -- @param #DETECTION_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Tasking.Task#TASK Task
    
    
    self:AddTransition( "Started", "Failed", "Started" )
    
    --- Failed Handler OnAfter for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] OnAfterFailed
    -- @param #DETECTION_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Tasking.Task#TASK Task
    
    
    self:AddTransition( "Started", "Aborted", "Started" )
    
    --- Aborted Handler OnAfter for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] OnAfterAborted
    -- @param #DETECTION_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Tasking.Task#TASK Task
    
    self:AddTransition( "Started", "Cancelled", "Started" )
    
    --- Cancelled Handler OnAfter for DETECTION_MANAGER
    -- @function [parent=#DETECTION_MANAGER] OnAfterCancelled
    -- @param #DETECTION_MANAGER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Tasking.Task#TASK Task
    

    self:AddTransition( "Started", "Report", "Started" )
    
    self:SetRefreshTimeInterval( 30 )
    self:SetReportDisplayTime( 25 )
  
    Detection:__Start( 3 )

    return self
  end
  
  function DETECTION_MANAGER:onafterStart( From, Event, To )
    self:Report()
  end
  
  function DETECTION_MANAGER:onafterReport( From, Event, To )

    self:__Report( -self._RefreshTimeInterval )
    
    self:ProcessDetected( self.Detection )
  end
  
  --- Set the reporting time interval.
  -- @param #DETECTION_MANAGER self
  -- @param #number RefreshTimeInterval The interval in seconds when a report needs to be done.
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:SetRefreshTimeInterval( RefreshTimeInterval )
    self:F2()
  
    self._RefreshTimeInterval = RefreshTimeInterval
  end
  
  
  --- Set the reporting message display time.
  -- @param #DETECTION_MANAGER self
  -- @param #number ReportDisplayTime The display time in seconds when a report needs to be done.
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:SetReportDisplayTime( ReportDisplayTime )
    self:F2()
  
    self._ReportDisplayTime = ReportDisplayTime
  end
  
  --- Get the reporting message display time.
  -- @param #DETECTION_MANAGER self
  -- @return #number ReportDisplayTime The display time in seconds when a report needs to be done.
  function DETECTION_MANAGER:GetReportDisplayTime()
    self:F2()
  
    return self._ReportDisplayTime
  end
  
  --- Reports the detected items to the @{Core.Set#SET_GROUP}.
  -- @param #DETECTION_MANAGER self
  -- @param Functional.Detection#DETECTION_BASE Detection
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:ProcessDetected( Detection )
  	self:E()
  
  end

end


do -- DETECTION_REPORTING

  --- DETECTION_REPORTING class.
  -- @type DETECTION_REPORTING
  -- @field Core.Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Functional.Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @extends #DETECTION_MANAGER
  DETECTION_REPORTING = {
    ClassName = "DETECTION_REPORTING",
  }
  
  
  --- DETECTION_REPORTING constructor.
  -- @param #DETECTION_REPORTING self
  -- @param Core.Set#SET_GROUP SetGroup
  -- @param Functional.Detection#DETECTION_AREAS Detection
  -- @return #DETECTION_REPORTING self
  function DETECTION_REPORTING:New( SetGroup, Detection )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #DETECTION_REPORTING
    
    self:Schedule( 1, 30 )
    return self
  end
  
  --- Creates a string of the detected items in a @{Detection}.
  -- @param #DETECTION_MANAGER self
  -- @param Core.Set#SET_UNIT DetectedSet The detected Set created by the @{Functional.Detection#DETECTION_BASE} object.
  -- @return #DETECTION_MANAGER self
  function DETECTION_REPORTING:GetDetectedItemsText( DetectedSet )
    self:F2()
  
    local MT = {} -- Message Text
    local UnitTypes = {}
  
    for DetectedUnitID, DetectedUnitData in pairs( DetectedSet:GetSet() ) do
      local DetectedUnit = DetectedUnitData -- Wrapper.Unit#UNIT
      if DetectedUnit:IsAlive() then
        local UnitType = DetectedUnit:GetTypeName()
    
        if not UnitTypes[UnitType] then
          UnitTypes[UnitType] = 1
        else
          UnitTypes[UnitType] = UnitTypes[UnitType] + 1
        end
      end
    end
  
    for UnitTypeID, UnitType in pairs( UnitTypes ) do
      MT[#MT+1] = UnitType .. " of " .. UnitTypeID
    end
  
    return table.concat( MT, ", " )
  end
  
  
  
  --- Reports the detected items to the @{Core.Set#SET_GROUP}.
  -- @param #DETECTION_REPORTING self
  -- @param Wrapper.Group#GROUP Group The @{Wrapper.Group} object to where the report needs to go.
  -- @param Functional.Detection#DETECTION_AREAS Detection The detection created by the @{Functional.Detection#DETECTION_BASE} object.
  -- @return #boolean Return true if you want the reporting to continue... false will cancel the reporting loop.
  function DETECTION_REPORTING:ProcessDetected( Group, Detection )
    self:F2( Group )
  
    local DetectedMsg = {}
    for DetectedAreaID, DetectedAreaData in pairs( Detection:GetDetectedAreas() ) do
      local DetectedArea = DetectedAreaData -- Functional.Detection#DETECTION_AREAS.DetectedArea
      DetectedMsg[#DetectedMsg+1] = " - Group #" .. DetectedAreaID .. ": " .. self:GetDetectedItemsText( DetectedArea.Set )
    end  
    local FACGroup = Detection:GetDetectionGroups()
    FACGroup:MessageToGroup( "Reporting detected target groups:\n" .. table.concat( DetectedMsg, "\n" ), self:GetReportDisplayTime(), Group  )
  
    return true
  end

end

