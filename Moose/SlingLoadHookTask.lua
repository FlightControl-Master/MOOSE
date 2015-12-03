--- A SLINGLOADHOOKTASK will orchestrate the sling-load hook activity to slingload a CARGO from a specific landing zone(s).
-- @classmod SLINGLOADHOOKTASK

Include.File("Task")

SLINGLOADHOOKTASK = {
  ClassName = "SLINGLOADHOOKTASK",
  GoalVerb = "Hook and Sling Cargo"
}

--- Creates a new SLINGLOADHOOKTASK.
-- @tparam table{string,...}|string LandingZones Table or name of the zone(s) where Cargo is to be loaded.
-- @tparam table{string,...)|string CargoPrefixes is the name or prefix of the name of the Cargo objects defined within the DCS ME.
-- @treturn SLINGLOADHOOKTASK
function SLINGLOADHOOKTASK:New( LandingZones, CargoPrefixes )
trace.f(self.ClassName)

    local self = BASE:Inherit( self, TASK:New() )

	self.Name = 'Hook and Sling Cargo'
	self.TaskBriefing = "Task: Hook"
	
	if type( LandingZones ) == "table" then
		self.LandingZones = LandingZones
	else
		self.LandingZones = { LandingZones }
	end

	if type( CargoPrefixes ) == "table" then
		self.CargoPrefixes = CargoPrefixes
	else
		self.CargoPrefixes = { CargoPrefixes }
	end

	self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGE_SLINGLOAD_HOOK:New(), STAGEDONE:New() }
	self:SetStage( 1 )
  
	return self
end
