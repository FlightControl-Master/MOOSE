--- **AI** - Models squadrons for airplanes and helicopters.
--
-- This is a class used in the @{AI_Air_Dispatcher} and derived dispatcher classes.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Air_Squadron
-- @image MOOSE.JPG



--- @type AI_AIR_SQUADRON
-- @extends Core.Base#BASE


--- Implements the core functions modeling squadrons for airplanes and helicopters.
-- 
-- ===
-- 
-- @field #AI_AIR_SQUADRON
AI_AIR_SQUADRON = {
  ClassName = "AI_AIR_SQUADRON",
}



--- Creates a new AI_AIR_SQUADRON object
-- @param #AI_AIR_SQUADRON self
-- @return #AI_AIR_SQUADRON
function AI_AIR_SQUADRON:New( SquadronName, AirbaseName, TemplatePrefixes, ResourceCount )

  self:I( { Air_Squadron = { SquadronName, AirbaseName, TemplatePrefixes, ResourceCount } } )

  local AI_Air_Squadron = BASE:New() -- #AI_AIR_SQUADRON
  
  AI_Air_Squadron.Name = SquadronName
  AI_Air_Squadron.Airbase = AIRBASE:FindByName( AirbaseName )
  AI_Air_Squadron.AirbaseName = AI_Air_Squadron.Airbase:GetName()
  if not AI_Air_Squadron.Airbase then
    error( "Cannot find airbase with name:" .. AirbaseName )
  end
  
  AI_Air_Squadron.Spawn = {}
  if type( TemplatePrefixes ) == "string" then
    local SpawnTemplate = TemplatePrefixes
    self.DefenderSpawns[SpawnTemplate] = self.DefenderSpawns[SpawnTemplate] or SPAWN:New( SpawnTemplate ) -- :InitCleanUp( 180 )
    AI_Air_Squadron.Spawn[1] = self.DefenderSpawns[SpawnTemplate]
  else
    for TemplateID, SpawnTemplate in pairs( TemplatePrefixes ) do
      self.DefenderSpawns[SpawnTemplate] = self.DefenderSpawns[SpawnTemplate] or SPAWN:New( SpawnTemplate ) -- :InitCleanUp( 180 )
      AI_Air_Squadron.Spawn[#AI_Air_Squadron.Spawn+1] = self.DefenderSpawns[SpawnTemplate]
    end
  end
  AI_Air_Squadron.ResourceCount = ResourceCount
  AI_Air_Squadron.TemplatePrefixes = TemplatePrefixes
  AI_Air_Squadron.Captured = false -- Not captured. This flag will be set to true, when the airbase where the squadron is located, is captured.

  self:SetSquadronLanguage( SquadronName, "EN" ) -- Squadrons speak English by default.

  return AI_Air_Squadron
end

--- Set the Name of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #string Name The Squadron Name.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetName( Name )

  self.Name = Name
  
  return self
end

--- Get the Name of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #string The Squadron Name.
function AI_AIR_SQUADRON:GetName()

  return self.Name
end

--- Set the ResourceCount of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number ResourceCount The Squadron ResourceCount.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetResourceCount( ResourceCount )

  self.ResourceCount = ResourceCount
  
  return self
end

--- Get the ResourceCount of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #number The Squadron ResourceCount.
function AI_AIR_SQUADRON:GetResourceCount()

  return self.ResourceCount
end

--- Add Resources to the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number Resources The Resources to be added.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:AddResources( Resources )

  self.ResourceCount = self.ResourceCount + Resources
  
  return self
end

--- Remove Resources to the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number Resources The Resources to be removed.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:RemoveResources( Resources )

  self.ResourceCount = self.ResourceCount - Resources
  
  return self
end
 
--- Set the Overhead of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number Overhead The Squadron Overhead.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetOverhead( Overhead )

  self.Overhead = Overhead
  
  return self
end

--- Get the Overhead of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #number The Squadron Overhead.
function AI_AIR_SQUADRON:GetOverhead()

  return self.Overhead
end

--- Set the Grouping of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number Grouping The Squadron Grouping.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetGrouping( Grouping )

  self.Grouping = Grouping
  
  return self
end

--- Get the Grouping of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #number The Squadron Grouping.
function AI_AIR_SQUADRON:GetGrouping()

  return self.Grouping
end

--- Set the FuelThreshold of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number FuelThreshold The Squadron FuelThreshold.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetFuelThreshold( FuelThreshold )

  self.FuelThreshold = FuelThreshold
  
  return self
end

--- Get the FuelThreshold of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #number The Squadron FuelThreshold.
function AI_AIR_SQUADRON:GetFuelThreshold()

  return self.FuelThreshold
end

--- Set the EngageProbability of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number EngageProbability The Squadron EngageProbability.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetEngageProbability( EngageProbability )

  self.EngageProbability = EngageProbability
  
  return self
end

--- Get the EngageProbability of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #number The Squadron EngageProbability.
function AI_AIR_SQUADRON:GetEngageProbability()

  return self.EngageProbability
end

--- Set the Takeoff of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number Takeoff The Squadron Takeoff.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetTakeoff( Takeoff )

  self.Takeoff = Takeoff
  
  return self
end

--- Get the Takeoff of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #number The Squadron Takeoff.
function AI_AIR_SQUADRON:GetTakeoff()

  return self.Takeoff
end

--- Set the Landing of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number Landing The Squadron Landing.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetLanding( Landing )

  self.Landing = Landing
  
  return self
end

--- Get the Landing of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #number The Squadron Landing.
function AI_AIR_SQUADRON:GetLanding()

  return self.Landing
end

--- Set the TankerName of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #string TankerName The Squadron Tanker Name.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetTankerName( TankerName )

  self.TankerName = TankerName
  
  return self
end

--- Get the Tanker Name of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @return #string The Squadron Tanker Name.
function AI_AIR_SQUADRON:GetTankerName()

  return self.TankerName
end


--- Set the Radio of the Squadron.
-- @param #AI_AIR_SQUADRON self
-- @param #number RadioFrequency The frequency of communication.
-- @param #number RadioModulation The modulation of communication.
-- @param #number RadioPower The power in Watts of communication.
-- @param #string Language The language of the radio speech.
-- @return #AI_AIR_SQUADRON The Squadron.
function AI_AIR_SQUADRON:SetRadio( RadioFrequency, RadioModulation, RadioPower, Language )

  self.RadioFrequency = RadioFrequency
  self.RadioModulation = RadioModulation or radio.modulation.AM 
  self.RadioPower = RadioPower or 100

  if self.RadioSpeech then
    self.RadioSpeech:Stop()
  end

  self.RadioSpeech = nil

  self.RadioSpeech = RADIOSPEECH:New( RadioFrequency, RadioModulation )
  self.RadioSpeech.power = RadioPower
  self.RadioSpeech:Start( 0.5 )

  self.RadioSpeech:SetLanguage( Language )
  
  return self
end


