--- This module contains the DETECTION_MANAGER class and derived classes.
-- 
-- ===
-- 
-- 1) @{DetectionManager#DETECTION_MANAGER} class, extends @{Fsm#FSM}
-- ====================================================================
-- The @{DetectionManager#DETECTION_MANAGER} class defines the core functions to report detected objects to groups.
-- Reportings can be done in several manners, and it is up to the derived classes if DETECTION_MANAGER to model the reporting behaviour.
-- 
-- 1.1) DETECTION_MANAGER constructor:
-- -----------------------------------
--   * @{DetectionManager#DETECTION_MANAGER.New}(): Create a new DETECTION_MANAGER instance.
-- 
-- 1.2) DETECTION_MANAGER reporting:
-- ---------------------------------
-- Derived DETECTION_MANAGER classes will reports detected units using the method @{DetectionManager#DETECTION_MANAGER.ReportDetected}(). This method implements polymorphic behaviour.
-- 
-- The time interval in seconds of the reporting can be changed using the methods @{DetectionManager#DETECTION_MANAGER.SetReportInterval}(). 
-- To control how long a reporting message is displayed, use @{DetectionManager#DETECTION_MANAGER.SetReportDisplayTime}().
-- Derived classes need to implement the method @{DetectionManager#DETECTION_MANAGER.GetReportDisplayTime}() to use the correct display time for displayed messages during a report.
-- 
-- Reporting can be started and stopped using the methods @{DetectionManager#DETECTION_MANAGER.StartReporting}() and @{DetectionManager#DETECTION_MANAGER.StopReporting}() respectively.
-- If an ad-hoc report is requested, use the method @{DetectionManager#DETECTION_MANAGER#ReportNow}().
-- 
-- The default reporting interval is every 60 seconds. The reporting messages are displayed 15 seconds.
-- 
-- ===
-- 
-- 2) @{DetectionManager#DETECTION_REPORTING} class, extends @{DetectionManager#DETECTION_MANAGER}
-- =========================================================================================
-- The @{DetectionManager#DETECTION_REPORTING} class implements detected units reporting. Reporting can be controlled using the reporting methods available in the @{DetectionManager#DETECTION_MANAGER} class.
-- 
-- 2.1) DETECTION_REPORTING constructor:
-- -------------------------------
-- The @{DetectionManager#DETECTION_REPORTING.New}() method creates a new DETECTION_REPORTING instance.
--    
--    
-- ===
-- 
-- ### Contributions: Mechanist, Prof_Hilactic, FlightControl - Concept & Testing
-- ### Author: FlightControl - Framework Design &  Programming
-- 
-- @module DetectionManager

do -- DETECTION MANAGER
  
  --- DETECTION_MANAGER class.
  -- @type DETECTION_MANAGER
  -- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Functional.Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @extends Core.Fsm#FSM
  DETECTION_MANAGER = {
    ClassName = "DETECTION_MANAGER",
    SetGroup = nil,
    Detection = nil,
  }
  
  --- FAC constructor.
  -- @param #DETECTION_MANAGER self
  -- @param Set#SET_GROUP SetGroup
  -- @param Functional.Detection#DETECTION_BASE Detection
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:New( SetGroup, Detection )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM:New() ) -- #DETECTION_MANAGER
    
    self.SetGroup = SetGroup
    self.Detection = Detection
    
    self:SetStartState( "Stopped" )
    self:AddTransition( "Stopped", "Start", "Started" )
    self:AddTransition( "Started", "Stop", "Stopped" )
    self:AddTransition( "Started", "Report", "Started" )
    
    self:SetReportInterval( 30 )
    self:SetReportDisplayTime( 25 )
  
    Detection:__Start( 1 )

    return self
  end
  
  function DETECTION_MANAGER:onafterStart( From, Event, To )
    self:Report()
  end
  
  function DETECTION_MANAGER:onafterReport( From, Event, To )

    self:E( "onafterReport" )

    self:__Report( -self._ReportInterval )
    
    self:ProcessDetected( self.Detection )
  end
  
  --- Set the reporting time interval.
  -- @param #DETECTION_MANAGER self
  -- @param #number ReportInterval The interval in seconds when a report needs to be done.
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:SetReportInterval( ReportInterval )
    self:F2()
  
    self._ReportInterval = ReportInterval
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
  
  --- Reports the detected items to the @{Set#SET_GROUP}.
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
  -- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Functional.Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @extends #DETECTION_MANAGER
  DETECTION_REPORTING = {
    ClassName = "DETECTION_REPORTING",
  }
  
  
  --- DETECTION_REPORTING constructor.
  -- @param #DETECTION_REPORTING self
  -- @param Set#SET_GROUP SetGroup
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
  -- @param Set#SET_UNIT DetectedSet The detected Set created by the @{Detection#DETECTION_BASE} object.
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
  
  
  
  --- Reports the detected items to the @{Set#SET_GROUP}.
  -- @param #DETECTION_REPORTING self
  -- @param Wrapper.Group#GROUP Group The @{Group} object to where the report needs to go.
  -- @param Functional.Detection#DETECTION_AREAS Detection The detection created by the @{Detection#DETECTION_BASE} object.
  -- @return #boolean Return true if you want the reporting to continue... false will cancel the reporting loop.
  function DETECTION_REPORTING:ProcessDetected( Group, Detection )
    self:F2( Group )
  
    self:E( Group )
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

