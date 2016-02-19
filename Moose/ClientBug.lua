--- Bug Client Activation Multiplayer Classes
-- @classmod CLIENTBUG

Include.File( "Routines" )
Include.File( "Base" )


CLIENTBUG = {
	ClassName = "CLIENTBUG",
}

function CLIENTBUG:New( )
trace.f( self.ClassName )

	-- Arrange meta tables
	local self = BASE:Inherit( self, BASE:New() )
	
	self.ActiveClients = {}
	
	self.ClientBugWorkaround = routines.scheduleFunction( self._ClientBugWorkaround, { self }, timer.getTime() + 1, 0.1 )

	return self
end

function CLIENTBUG:_ClientBugWorkaround()

	-- Get the units of the players
	local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }

	for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
		trace.i( self.ClassName, CoalitionData )
	
		for UnitId, UnitData in pairs( CoalitionData ) do
			trace.i( self.ClassName, UnitData )
			
			if UnitData and UnitData:isExist() then
			
				local UnitSkill = _Database.Units[UnitData:getName()].Template.skill
				trace.i( self.ClassName, "UnitSkill = " .. UnitSkill )
				
				if UnitSkill == "Client" then
					
					-- Generate birth event
					self:CreateEventBirth( 0, UnitData, UnitData:getName(), 0, 0 )
				end
			end
		end
	end

end
