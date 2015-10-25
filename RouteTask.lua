--- A ROUTETASK orchestrates the travel to a specific zone defined within the ME.
-- @classmod ROUTETASK

--- Modeling a sequence of STAGEs to fly back to the home base specified by an Arrival Zone.
ROUTETASK = {
  ClassName = "ROUTETASK",
  GoalVerb = "Route",
}

--- Creates a new ROUTETASK.
-- @tparam table{sring,...}|string LandingZones Table of Zone Names where the target is located.
-- @tparam string TaskBriefing (optional) Defines a text describing the briefing of the task.
-- @treturn ROUTETASK
function ROUTETASK:New( LandingZones, TaskBriefing )
trace.f(self.ClassName, { LandingZones, TaskBriefing } )

  -- Child holds the inherited instance of the PICKUPTASK Class to the BASE class.
  local Child = BASE:Inherit( self, TASK:New() )

  local Valid = true
  
  Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    
  if  Valid then
    Child.Name = 'Route To Zone'
	if TaskBriefing then
		Child.TaskBriefing = TaskBriefing .. " Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the target objective."
	else
		Child.TaskBriefing = "Task: Fly to specified zone(s). Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the target objective."
	end
	if type( LandingZones ) == "table" then
		Child.LandingZones = LandingZones
	else
		Child.LandingZones = { LandingZones }
	end
    Child.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGEARRIVE:New(), STAGEDONE:New() }
	Child.SetStage( Child, 1 )
  end
  
  return Child
end

