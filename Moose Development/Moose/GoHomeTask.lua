--- A GOHOMETASK orchestrates the travel back to the home base, which is a specific zone defined within the ME.
-- @module GOHOMETASK

--- The GOHOMETASK class
-- @type
GOHOMETASK = {
  ClassName = "GOHOMETASK",
}

--- Creates a new GOHOMETASK.
-- @param table{string,...}|string LandingZones Table of Landing Zone names where Home(s) are located.
-- @return GOHOMETASK
function GOHOMETASK:New( LandingZones )
  local self = BASE:Inherit( self, TASK:New() )
	self:F( { LandingZones } )
  local Valid = true
  
  Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    
  if  Valid then
    self.Name = 'Fly Home'
    self.TaskBriefing = "Task: Fly back to your home base. Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to your home base."
	if type( LandingZones ) == "table" then
		self.LandingZones = LandingZones
	else
		self.LandingZones = { LandingZones }
	end
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGEARRIVE:New(), STAGEDONE:New() }
		self.SetStage( self, 1 )
  end
  
  return self
end
