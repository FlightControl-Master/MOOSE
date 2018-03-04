--- **Tasking** -- Controls the information of a Task.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
-- 
-- @module TaskInfo

--- @type TASKINFO
-- @extends Core.Set#SET_BASE

--- 
-- # TASKINFO class, extends @{Set#SET}
-- 
-- ## The TASKINFO class implements the methods to contain information and display information of a task. 
-- 
-- @field #TASKINFO
TASKINFO = {
  ClassName = "TASKINFO",
}

--- @type #TASKINFO.Detail #string A string that flags to document which level of detail needs to be shown in the report.
-- 
--   - "M" for Markings on the Map (F10).
--   - "S" for Summary Reports.
--   - "O" for Overview Reports.
--   - "D" for Detailed Reports.
TASKINFO.Detail = ""

--- Instantiates a new TASKINFO. 
-- @param #TASKINFO self
-- @param Tasking.Task#TASK Task The task owning the information.
-- @return #TASKINFO self
function TASKINFO:New( Task )

  local self = BASE:Inherit( self, SET_BASE:New() ) -- Core.Set#SET
  
  self.Task = Task
  
  return self
end


--- Add taskinfo. 
-- @param #TASKINFO self
-- @param #string The info key.
-- @param Data The data of the info.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddInfo( Key, Data, Order, Detail )
  self:Add( Key, { Data = Data, Order = Order, Detail = Detail } )
  return self
end


--- Get taskinfo. 
-- @param #TASKINFO self
-- @param #string The info key.
-- @return Data The data of the info.
-- @return #number Order The display order, which is a number from 0 to 100.
-- @return #TASKINFO.Detail Detail The detail Level.
function TASKINFO:GetInfo( Key )
  local Object = self:Get( Key )
  return Object.Data, Object.Order, Object.Detail
end


--- Get data. 
-- @param #TASKINFO self
-- @param #string The info key.
-- @return Data The data of the info.
function TASKINFO:GetData( Key )
  local Object = self:Get( Key )
  return Object.Data
end


--- Add Text. 
-- @param #TASKINFO self
-- @param #string Key The key.
-- @param #string Text The text.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddText( Key, Text, Order, Detail )
  self:AddInfo( Key, Text, Order, Detail )
  return self
end


--- Add the task name. 
-- @param #TASKINFO self
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddTaskName( Order, Detail )
  self:AddInfo( "TaskName", self.Task:GetName(), Order, Detail )
  return self
end




--- Add a Coordinate. 
-- @param #TASKINFO self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddCoordinate( Coordinate, Order, Detail )
  self:AddInfo( "Coordinate", Coordinate, Order, Detail )
  return self
end


--- Add Threat. 
-- @param #TASKINFO self
-- @param #string ThreatText The text of the Threat.
-- @param #string ThreatLevel The level of the Threat.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddThreat( ThreatText, ThreatLevel, Order, Detail )
  self:AddInfo( "Threat", ThreatText .. " [" .. string.rep(  "■", ThreatLevel ) .. string.rep(  "□", 10 - ThreatLevel ) .. "]", Order, Detail )
  return self
end


--- Add the Target count. 
-- @param #TASKINFO self
-- @param #number TargetCount The amount of targets.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddTargetCount( TargetCount, Order, Detail )
  self:AddInfo( "Counting", string.format( "%d", TargetCount ), Order, Detail )
  return self
end

--- Add the Targets. 
-- @param #TASKINFO self
-- @param #number TargetCount The amount of targets.
-- @param #string TargetTypes The text containing the target types.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddTargets( TargetCount, TargetTypes, Order, Detail )
  self:AddInfo( "Targets", string.format( "%d of %s", TargetCount, TargetTypes ), Order, Detail )
  return self
end

--- Add the QFE at a Coordinate. 
-- @param #TASKINFO self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddQFEAtCoordinate( Coordinate, Order, Detail )
  self:AddInfo( "QFE", Coordinate, Order, Detail )
  return self
end

--- Add the Temperature at a Coordinate. 
-- @param #TASKINFO self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddTemperatureAtCoordinate( Coordinate, Order, Detail )
  self:AddInfo( "Temperature", Coordinate, Order, Detail )
  return self
end

--- Add the Wind at a Coordinate. 
-- @param #TASKINFO self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @return #TASKINFO self
function TASKINFO:AddWindAtCoordinate( Coordinate, Order, Detail )
  self:AddInfo( "Wind", Coordinate, Order, Detail )
  return self
end


--- Create the taskinfo Report
-- @param #TASKINFO self
-- @param Core.Report#REPORT Report
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param Wrapper.Group#GROUP ReportGroup
-- @return #TASKINFO self
function TASKINFO:Report( Report, Detail, ReportGroup )

  local Line = 0
  local LineReport = REPORT:New()

  for Key, Data in UTILS.spairs( self.Set, function( t, a, b ) return t[a].Order < t[b].Order end ) do

    self:E( { Key = Key, Detail = Detail, Data = Data } )
    
    if Data.Detail:find( Detail ) then
      local Text = ""
      if Key == "TaskName" then
        Key = nil
        Text = Data.Data
      end
      if Key == "Coordinate" then
        local Coordinate = Data.Data -- Core.Point#COORDINATE
        Text = Coordinate:ToString( ReportGroup:GetUnit(1), nil, self )
      end
      if Key == "Threat" then
        local DataText = Data.Data -- #string
        Text = DataText
      end
      if Key == "Counting" then
        local DataText = Data.Data -- #string
        Text = DataText
      end
      if Key == "Targets" then
        local DataText = Data.Data -- #string
        Text = DataText
      end
      if Key == "QFE" then
        local Coordinate = Data.Data -- Core.Point#COORDINATE
        Text = Coordinate:ToStringPressure( ReportGroup:GetUnit(1), nil, self )
      end
      if Key == "Temperature" then
        local Coordinate = Data.Data -- Core.Point#COORDINATE
        Text = Coordinate:ToStringTemperature( ReportGroup:GetUnit(1), nil, self )
      end
      if Key == "Wind" then
        local Coordinate = Data.Data -- Core.Point#COORDINATE
        Text = Coordinate:ToStringWind( ReportGroup:GetUnit(1), nil, self )
      end

      if Line < math.floor( Data.Order / 10 ) then
        if Line == 0 then
          Report:AddIndent( LineReport:Text( ", " ), "-" )
        else
          Report:AddIndent( LineReport:Text( ", " ) )
        end
        LineReport = REPORT:New()
        Line = math.floor( Data.Order / 10 )
      end

      LineReport:Add( ( Key and ( Key .. ":" ) or "" ) .. Text )
    end
  end
  Report:AddIndent( LineReport:Text( ", " ) )

end
