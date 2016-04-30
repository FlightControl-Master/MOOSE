--- A ROUTETASK orchestrates the travel to a specific zone defined within the ME.
-- @module ROUTETASK

--- The ROUTETASK class
-- @type
ROUTETASK = {
  ClassName = "ROUTETASK",
  GoalVerb = "Route",
}

--- Creates a new ROUTETASK.
-- @param table{sring,...}|string LandingZones Table of Zone Names where the target is located.
-- @param string TaskBriefing (optional) Defines a text describing the briefing of the task.
-- @return ROUTETASK
function ROUTETASK:New( LandingZones, TaskBriefing )
  local self = BASE:Inherit( self, TASK:New() )
	self:F( { LandingZones, TaskBriefing } )

  local Valid = true
  
  Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    
  if  Valid then
    self.Name = 'Route To Zone'
	if TaskBriefing then
		self.TaskBriefing = TaskBriefing .. " Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the target objective."
	else
		self.TaskBriefing = "Task: Fly to specified zone(s). Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the target objective."
	end
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

