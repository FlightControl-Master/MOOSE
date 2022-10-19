--- **Tasking** - Controls the information of a Task.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Tasking.TaskInfo
-- @image MOOSE.JPG

--- @type TASKINFO
-- @extends Core.Base#BASE

--- 
-- # TASKINFO class, extends @{Core.Base#BASE}
-- 
-- ## The TASKINFO class implements the methods to contain information and display information of a task. 
-- 
-- @field #TASKINFO
TASKINFO = {
  ClassName = "TASKINFO",
}

--- @type TASKINFO.Detail #string A string that flags to document which level of detail needs to be shown in the report.
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

  local self = BASE:Inherit( self, BASE:New() ) -- Core.Base#BASE
  
  self.Task = Task
  self.VolatileInfo = SET_BASE:New()
  self.PersistentInfo = SET_BASE:New()
  
  self.Info = self.VolatileInfo
  
  return self
end


--- Add taskinfo. 
-- @param #TASKINFO self
-- @param #string Key The info key.
-- @param Data The data of the info.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddInfo( Key, Data, Order, Detail, Keep, ShowKey, Type )
  self.VolatileInfo:Add( Key, { Data = Data, Order = Order, Detail = Detail, ShowKey = ShowKey, Type = Type } )
  if Keep == true then
    self.PersistentInfo:Add( Key, { Data = Data, Order = Order, Detail = Detail, ShowKey = ShowKey, Type = Type } )
  end
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
  local Object = self.Info:Get( Key )
  return Object and Object.Data
end


--- Add Text. 
-- @param #TASKINFO self
-- @param #string Key The key.
-- @param #string Text The text.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddText( Key, Text, Order, Detail, Keep )
  self:AddInfo( Key, Text, Order, Detail, Keep )
  return self
end


--- Add the task name. 
-- @param #TASKINFO self
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddTaskName( Order, Detail, Keep )
  self:AddInfo( "TaskName", self.Task:GetName(), Order, Detail, Keep )
  return self
end




--- Add a Coordinate. 
-- @param #TASKINFO self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddCoordinate( Coordinate, Order, Detail, Keep, ShowKey, Name )
  self:AddInfo( Name or "Coordinate", Coordinate, Order, Detail, Keep, ShowKey, "Coordinate" )
  return self
end


--- Get the Coordinate. 
-- @param #TASKINFO self
-- @return Core.Point#COORDINATE Coordinate
function TASKINFO:GetCoordinate( Name )
  return self:GetData( Name or "Coordinate" )
end



--- Add Coordinates. 
-- @param #TASKINFO self
-- @param #list<Core.Point#COORDINATE> Coordinates
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddCoordinates( Coordinates, Order, Detail, Keep )
  self:AddInfo( "Coordinates", Coordinates, Order, Detail, Keep )
  return self
end



--- Add Threat. 
-- @param #TASKINFO self
-- @param #string ThreatText The text of the Threat.
-- @param #string ThreatLevel The level of the Threat.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddThreat( ThreatText, ThreatLevel, Order, Detail, Keep )
  self:AddInfo( "Threat", " [" .. string.rep(  "■", ThreatLevel ) .. string.rep(  "□", 10 - ThreatLevel ) .. "]:" .. ThreatText, Order, Detail, Keep )
  return self
end


--- Get Threat. 
-- @param #TASKINFO self
-- @return #string The threat
function TASKINFO:GetThreat()
  self:GetInfo( "Threat" )
  return self
end



--- Add the Target count. 
-- @param #TASKINFO self
-- @param #number TargetCount The amount of targets.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddTargetCount( TargetCount, Order, Detail, Keep )
  self:AddInfo( "Counting", string.format( "%d", TargetCount ), Order, Detail, Keep )
  return self
end

--- Add the Targets. 
-- @param #TASKINFO self
-- @param #number TargetCount The amount of targets.
-- @param #string TargetTypes The text containing the target types.
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddTargets( TargetCount, TargetTypes, Order, Detail, Keep )
  self:AddInfo( "Targets", string.format( "%d of %s", TargetCount, TargetTypes ), Order, Detail, Keep )
  return self
end

--- Get Targets. 
-- @param #TASKINFO self
-- @return #string The targets
function TASKINFO:GetTargets()
  self:GetInfo( "Targets" )
  return self
end




--- Add the QFE at a Coordinate. 
-- @param #TASKINFO self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddQFEAtCoordinate( Coordinate, Order, Detail, Keep )
  self:AddInfo( "QFE", Coordinate, Order, Detail, Keep )
  return self
end

--- Add the Temperature at a Coordinate. 
-- @param #TASKINFO self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddTemperatureAtCoordinate( Coordinate, Order, Detail, Keep )
  self:AddInfo( "Temperature", Coordinate, Order, Detail, Keep )
  return self
end

--- Add the Wind at a Coordinate. 
-- @param #TASKINFO self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddWindAtCoordinate( Coordinate, Order, Detail, Keep )
  self:AddInfo( "Wind", Coordinate, Order, Detail, Keep )
  return self
end

--- Add Cargo. 
-- @param #TASKINFO self
-- @param Core.Cargo#CARGO Cargo
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddCargo( Cargo, Order, Detail, Keep )
  self:AddInfo( "Cargo", Cargo, Order, Detail, Keep )
  return self
end


--- Add Cargo set. 
-- @param #TASKINFO self
-- @param Core.Set#SET_CARGO SetCargo
-- @param #number Order The display order, which is a number from 0 to 100.
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param #boolean Keep (optional) If true, this would indicate that the planned taskinfo would be persistent when the task is completed, so that the original planned task info is used at the completed reports.
-- @return #TASKINFO self
function TASKINFO:AddCargoSet( SetCargo, Order, Detail, Keep )

  local CargoReport = REPORT:New()
  CargoReport:Add( "" )
  SetCargo:ForEachCargo(
    --- @param Cargo.Cargo#CARGO Cargo
    function( Cargo )
      CargoReport:Add( string.format( ' - %s (%s) %s - status %s ', Cargo:GetName(), Cargo:GetType(), Cargo:GetTransportationMethod(), Cargo:GetCurrentState() ) )
    end
  )

  self:AddInfo( "Cargo", CargoReport:Text(), Order, Detail, Keep )
  

  return self
end



--- Create the taskinfo Report
-- @param #TASKINFO self
-- @param Core.Report#REPORT Report
-- @param #TASKINFO.Detail Detail The detail Level.
-- @param Wrapper.Group#GROUP ReportGroup
-- @param Tasking.Task#TASK Task
-- @return #TASKINFO self
function TASKINFO:Report( Report, Detail, ReportGroup, Task )

  local Line = 0
  local LineReport = REPORT:New()

  if not self.Task:IsStatePlanned() and not self.Task:IsStateAssigned() then
    self.Info = self.PersistentInfo
  end

  for Key, Data in UTILS.spairs( self.Info.Set, function( t, a, b ) return t[a].Order < t[b].Order end ) do

    if Data.Detail:find( Detail ) then
      local Text = ""
      local ShowKey = ( Data.ShowKey == nil or Data.ShowKey == true )
      if     Key == "TaskName" then
        Key = nil
        Text = Data.Data
      elseif Data.Type and Data.Type == "Coordinate" then
        local Coordinate = Data.Data -- Core.Point#COORDINATE
        Text = Coordinate:ToString( ReportGroup:GetUnit(1), nil, Task )
      elseif Key == "Threat" then
        local DataText = Data.Data -- #string
        Text = DataText
      elseif Key == "Counting" then
        local DataText = Data.Data -- #string
        Text = DataText
      elseif Key == "Targets" then
        local DataText = Data.Data -- #string
        Text = DataText
      elseif Key == "QFE" then
        local Coordinate = Data.Data -- Core.Point#COORDINATE
        Text = Coordinate:ToStringPressure( ReportGroup:GetUnit(1), nil, Task )
      elseif Key == "Temperature" then
        local Coordinate = Data.Data -- Core.Point#COORDINATE
        Text = Coordinate:ToStringTemperature( ReportGroup:GetUnit(1), nil, Task )
      elseif Key == "Wind" then
        local Coordinate = Data.Data -- Core.Point#COORDINATE
        Text = Coordinate:ToStringWind( ReportGroup:GetUnit(1), nil, Task )
      elseif Key == "Cargo" then
        local DataText = Data.Data -- #string
        Text = DataText
      elseif Key == "Friendlies" then
        local DataText = Data.Data -- #string
        Text = DataText
      elseif Key == "Players" then
        local DataText = Data.Data -- #string
        Text = DataText
      else
        local DataText = Data.Data -- #string
        if type(DataText) == "string" then --Issue #1388 - don't just assume this is a string
          Text = DataText
        end
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

      if Text ~= "" then
        LineReport:Add( ( ( Key and ShowKey == true ) and ( Key .. ": " ) or "" ) .. Text )
      end

    end
  end
  
  Report:AddIndent( LineReport:Text( ", " ) )
end
