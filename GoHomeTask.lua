--- A GOHOMETASK orchestrates the travel back to the home base, which is a specific zone defined within the ME.
-- @classmod GOHOMETASK

Include.File("Task")

GOHOMETASK = {
  ClassName = "GOHOMETASK",
}

--- Creates a new GOHOMETASK.
-- @tparam table{string,...}|string LandingZones Table of Landing Zone names where Home(s) are located.
-- @treturn GOHOMETASK
function GOHOMETASK:New( LandingZones )
trace.f(self.ClassName)

  -- Child holds the inherited instance of the PICKUPTASK Class to the BASE class.
  local Child = BASE:Inherit( self, TASK:New() )

  local Valid = true
  
  Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    
  if  Valid then
    Child.Name = 'Fly Home'
    Child.TaskBriefing = "Task: Fly back to your home base. Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to your home base."
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
