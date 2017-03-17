--- This test demonstrates the use(s) of the SwitchWayPoint method of the GROUP class.

local HeliGroup = GROUP:FindByName( "Helicopter" )

local AttackGroup = GROUP:FindByName( "AttackGroup" )

local AttackUnits = AttackGroup:GetUnits()

local Tasks = {}

for i = 1, #AttackUnits do

  local AttackUnit = AttackGroup:GetUnit( i )
  Tasks[#Tasks+1] = HeliGroup:TaskAttackUnit( AttackUnit )
end

Tasks[#Tasks+1] = HeliGroup:TaskFunction( 1, 7, "_Resume", { "''" } )

--- @param Wrapper.Group#GROUP HeliGroup
function _Resume( HeliGroup )
  env.info( '_Resume' )

  HeliGroup:MessageToAll( "Resuming",10,"Info")
end

HeliGroup:PushTask( 
  HeliGroup:TaskCombo(
  Tasks
  ), 30 
)