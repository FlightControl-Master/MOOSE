--- A SLINGLOADUNHOOKTASK will orchestrate the sling-load unhook activity to (sling)load a CARGO and deploy it in a specific landing zone(s).
-- @classmod SLINGLOADUNHOOKTASK

Include.File("Task")

SLINGLOADUNHOOKTASK = {
  ClassName = "SLINGLOADUNHOOKTASK",
  GoalVerb = "Sling and UnHook Cargo"
}

--- Creates a new SLINGLOADUNHOOKTASK.
-- @tparam table{string,...}|string LandingZones Table or name of the zone(s) where Cargo is to be loaded.
-- @tparam table{string,...}|string CargoPrefixes is the name or prefix of the name of the Cargo objects defined within the DCS ME.
function SLINGLOADUNHOOKTASK:New( LandingZones, CargoPrefixes )
trace.f(self.ClassName)

    local self = BASE:Inherit( self, TASK:New() )

	self.Name = 'Sling and Unhook Cargo'
	self.TaskBriefing = "Task: UnHook"
	
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

	self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGE_SLINGLOAD_UNHOOK:New(), STAGEDONE:New() }
	self:SetStage( 1 )
  
	return self
end
