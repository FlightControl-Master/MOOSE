--- **Functional** - Suppress fire of ground units when they get hit.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Hold fire of attacked units when being fired upon.
--   * Retreat to a user defined zone.
--   * Fall back on hits.
--   * Take cover on hits.
--   * Gaussian distribution of suppression time.
--
-- ===
-- 
-- ## Missions:
--
-- ## [MOOSE - ALL Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS)
-- 
-- === 
-- 
-- When ground units get hit by (suppressive) enemy fire, they will not be able to shoot back for a certain amount of time.
-- 
-- The implementation is based on an idea and script by MBot. See the [DCS forum threat](https://forums.eagle.ru/showthread.php?t=107635) for details.
-- 
-- In addition to suppressing the fire, conditions can be specified, which let the group retreat to a defined zone, move away from the attacker
-- or hide at a nearby scenery object.
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: [FlightControl](https://forums.eagle.ru/member.php?u=89536)
-- 
-- ===
-- 
-- @module Functional.Suppression
-- @image Suppression.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- SUPPRESSION class
-- @type SUPPRESSION
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Write Debug messages to DCS log file and send Debug messages to all players.
-- @field #string lid String for DCS log file.
-- @field #boolean flare Flare units when they get hit or die.
-- @field #boolean smoke Smoke places to which the group retreats, falls back or hides.
-- @field #list DCSdesc Table containing all DCS descriptors of the group.
-- @field #string Type Type of the group.
-- @field #number SpeedMax Maximum speed of group in km/h.
-- @field #boolean IsInfantry True if group has attribute Infantry.
-- @field Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the FSM. Must be a ground group.
-- @field #number Tsuppress_ave Average time in seconds a group gets suppressed. Actual value is sampled randomly from a Gaussian distribution.
-- @field #number Tsuppress_min Minimum time in seconds the group gets suppressed.
-- @field #number Tsuppress_max Maximum time in seconds the group gets suppressed.
-- @field #number TsuppressionOver Time at which the suppression will be over.
-- @field #number IniGroupStrength Number of units in a group at start.
-- @field #number Nhit Number of times the group was hit.
-- @field #string Formation Formation which will be used when falling back, taking cover or retreating. Default "Vee".
-- @field #number Speed Speed the unit will use when falling back, taking cover or retreating. Default 999.
-- @field #boolean MenuON If true creates a entry in the F10 menu.
-- @field #boolean FallbackON If true, group can fall back, i.e. move away from the attacking unit.
-- @field #number FallbackWait Time in seconds the unit will wait at the fall back point before it resumes its mission.
-- @field #number FallbackDist Distance in meters the unit will fall back.
-- @field #number FallbackHeading Heading in degrees to which the group should fall back. Default is directly away from the attacking unit.
-- @field #boolean TakecoverON If true, group can hide at a nearby scenery object.
-- @field #number TakecoverWait Time in seconds the group will hide before it will resume its mission.
-- @field #number TakecoverRange Range in which the group will search for scenery objects to hide at.
-- @field Core.Point#COORDINATE hideout Coordinate/place where the group will try to take cover.
-- @field #number PminFlee Minimum probability in percent that a group will flee (fall back or take cover) at each hit event. Default is 10 %.
-- @field #number PmaxFlee Maximum probability in percent that a group will flee (fall back or take cover) at each hit event. Default is 90 %.
-- @field Core.Zone#ZONE RetreatZone Zone to which a group retreats.
-- @field #number RetreatDamage Damage in percent at which the group will be ordered to retreat.
-- @field #number RetreatWait Time in seconds the group will wait in the retreat zone before it resumes its mission. Default two hours. 
-- @field #string CurrentAlarmState Alam state the group is currently in.
-- @field #string CurrentROE ROE the group currently has.
-- @field #string DefaultAlarmState Alarm state the group will go to when it is changed back from another state. Default is "Auto".
-- @field #string DefaultROE ROE the group will get once suppression is over. Default is "Free".
-- @field #boolean eventmoose If true, events are handled by MOOSE. If false, events are handled directly by DCS eventhandler. Default true.
-- @field Core.Zone#ZONE BattleZone 
-- @field #boolean AutoEngage
-- @extends Core.Fsm#FSM_CONTROLLABLE
-- 

--- Mimic suppressive enemy fire and let groups flee or retreat.
-- 
-- ## Suppression Process
-- 
-- ![Process](..\Presentations\SUPPRESSION\Suppression_Process.png)
-- 
-- The suppression process can be described as follows.
-- 
-- ### CombatReady
-- 
-- A group starts in the state **CombatReady**. In this state the group is ready to fight. The ROE is set to either "Weapon Free" or "Return Fire".
-- The alarm state is set to either "Auto" or "Red".
-- 
-- ### Event Hit
-- The most important event in this scenario is the **Hit** event. This is an event of the FSM and triggered by the DCS event hit.
-- 
-- ### Suppressed
-- After the **Hit** event the group changes its state to **Suppressed**. Technically, the ROE of the group is changed to "Weapon Hold".
-- The suppression of the group will last a certain amount of time. It is randomized an will vary each time the group is hit.
-- The expected suppression time is set to 15 seconds by default. But the actual value is sampled from a Gaussian distribution.
--  
-- ![Process](..\Presentations\SUPPRESSION\Suppression_Gaussian.png)
-- 
-- The graph shows the distribution of suppression times if a group would be hit 100,000 times. As can be seen, on most hits the group gets
-- suppressed for around 15 seconds. Other values are also possible but they become less likely the further away from the "expected" suppression time they are.
-- Minimal and maximal suppression times can also be specified. By default these are set to 5 and 25 seconds, respectively. This can also be seen in the graph
-- because the tails of the Gaussian distribution are cut off at these values.
-- 
-- ### Event Recovered
-- After the suppression time is over, the event **Recovered** is initiated and the group becomes **CombatReady** again.
-- The ROE of the group will be set to "Weapon Free".
-- 
-- Of course, it can also happen that a group is hit again while it is still suppressed. In that case a new random suppression time is calculated.
-- If the new suppression time is longer than the remaining suppression of the previous hit, then the group recovers when the suppression time of the last
-- hit has passed.
-- If the new suppression time is shorter than the remaining suppression, the group will recover after the longer time of the first suppression has passed.
-- 
-- For example:
-- 
-- * A group gets hit the first time and is suppressed for - let's say - 15 seconds.
-- * After 10 seconds, i.e. when 5 seconds of the old suppression are left, the group gets hit a again.
-- * A new suppression time is calculated which can be smaller or larger than the remaining 5 seconds.
-- * If the new suppression time is smaller, e.g. three seconds, than five seconds, the group will recover after the 5 remaining seconds of the first suppression have passed.
-- * If the new suppression time is longer than last suppression time, e.g. 10 seconds, then the group will recover after the 10 seconds of the new hit have passed.
-- 
-- Generally speaking, the suppression times are not just added on top of each other. Because this could easily lead to the situation that a group 
-- never becomes CombatReady again before it gets destroyed.
-- 
-- The mission designer can capture the event **Recovered** by the function @{#SUPPRESSION.OnAfterRecovered}().
-- 
-- ## Flee Events and States
-- Apart from being suppressed the groups can also flee from the enemy under certain conditions.
-- 
-- ### Event Retreat
-- The first option is a retreat. This can be enabled by setting a retreat zone, i.e. a trigger zone defined in the mission editor.
-- 
-- If the group takes a certain amount of damage, the event **Retreat** will be called and the group will start to move to the retreat zone.
-- The group will be in the state **Retreating**, which means that its ROE is set to "Weapon Hold" and the alarm state is set to "Green".
-- Setting the alarm state to green is necessary to enable the group to move under fire.
-- 
-- When the group has reached the retreat zone, the event **Retreated** is triggered and the state will change to **Retreated** (note that both the event and
-- the state of the same name in this case). ROE and alarm state are
-- set to "Return Fire" and "Auto", respectively. The group will stay in the retreat zone and not actively participate in the combat any more.
-- 
-- If no option retreat zone has been specified, the option retreat is not available.
-- 
-- The mission designer can capture the events **Retreat** and **Retreated** by the functions @{#SUPPRESSION.OnAfterRetreat}() and @{#SUPPRESSION.OnAfterRetreated}().
-- 
-- ### Fallback
-- 
-- If a group is attacked by another ground group, it has the option to fall back, i.e. move away from the enemy. The probability of the event **FallBack** to
-- happen depends on the damage of the group that was hit. The more a group gets damaged, the more likely **FallBack** event becomes.
-- 
-- If the group enters the state **FallingBack** it will move 100 meters in the opposite direction of the attacking unit. ROE and alarmstate are set to "Weapon Hold"
-- and "Green", respectively.
-- 
-- At the fallback point the group will wait for 60 seconds before it resumes its normal mission.
-- 
-- The mission designer can capture the event **FallBack** by the function @{#SUPPRESSION.OnAfterFallBack}().
-- 
-- ### TakeCover
-- 
-- If a group is hit by either another ground or air unit, it has the option to "take cover" or "hide". This means that the group will move to a random
-- scenery object in it vicinity.
-- 
-- Analogously to the fall back case, the probability of a **TakeCover** event to occur, depends on the damage of the group. The more a group is damaged, the more
-- likely it becomes that a group takes cover.
-- 
-- When a **TakeCover** event occurs an area with a radius of 300 meters around the hit group is searched for an arbitrary scenery object.
-- If at least one scenery object is found, the group will move there. One it has reached its "hideout", it will wait there for two minutes before it resumes its
-- normal mission.
-- 
-- If more than one scenery object is found, the group will move to a random one.
-- If no scenery object is near the group the **TakeCover** event is rejected and the group will not move.
-- 
-- The mission designer can capture the event **TakeCover** by the function @{#SUPPRESSION.OnAfterTakeCover}().
-- 
-- ### Choice of FallBack or TakeCover if both are enabled?
-- 
-- If both **FallBack** and **TakeCover** events are enabled by the functions @{#SUPPRESSION.Fallback}() and @{#SUPPRESSION.Takecover}() the algorithm does the following:
-- 
-- * If the attacking unit is a ground unit, then the **FallBack** event is executed.
-- * Otherwise, i.e. if the attacker is *not* a ground unit, then the **TakeCover** event is triggered.
-- 
-- ### FightBack
-- 
-- When a group leaves the states **TakingCover** or **FallingBack** the event **FightBack** is triggered. This changes the ROE and the alarm state back to their default values.
-- 
-- The mission designer can capture the event **FightBack** by the function @{#SUPPRESSION.OnAfterFightBack}()
-- 
-- # Examples
-- 
-- ## Simple Suppression
-- This example shows the basic steps to use suppressive fire for a group.
-- 
-- ![Process](..\Presentations\SUPPRESSION\Suppression_Example_01.png)
-- 
-- 
-- # Customization and Fine Tuning
-- The following user functions can be used to change the default values
-- 
-- * @{#SUPPRESSION.SetSuppressionTime}() can be used to set the time a goup gets suppressed.
-- * @{#SUPPRESSION.SetRetreatZone}() sets the retreat zone and enables the possiblity for the group to retreat.
-- * @{#SUPPRESSION.SetFallbackDistance}() sets a value how far the unit moves away from the attacker after the fallback event.
-- * @{#SUPPRESSION.SetFallbackWait}() sets the time after which the group resumes its mission after a FallBack event.
-- * @{#SUPPRESSION.SetTakecoverWait}() sets the time after which the group resumes its mission after a TakeCover event.
-- * @{#SUPPRESSION.SetTakecoverRange}() sets the radius in which hideouts are searched.
-- * @{#SUPPRESSION.SetTakecoverPlace}() explicitly sets the place where the group will run at a TakeCover event.
-- * @{#SUPPRESSION.SetMinimumFleeProbability}() sets the minimum probability that a group flees (FallBack or TakeCover) after a hit. Note taht the probability increases with damage.
-- * @{#SUPPRESSION.SetMaximumFleeProbability}() sets the maximum probability that a group flees (FallBack or TakeCover) after a hit. Default is 90%.
-- * @{#SUPPRESSION.SetRetreatDamage}() sets the damage a group/unit can take before it is ordered to retreat.
-- * @{#SUPPRESSION.SetRetreatWait}() sets the time a group waits in the retreat zone after a retreat.
-- * @{#SUPPRESSION.SetDefaultAlarmState}() sets the alarm state a group gets after it becomes CombatReady again.
-- * @{#SUPPRESSION.SetDefaultROE}() set the rules of engagement a group gets after it becomes CombatReady again.
-- * @{#SUPPRESSION.FlareOn}() is mainly for debugging. A flare is fired when a unit is hit, gets suppressed, recovers, dies.
-- * @{#SUPPRESSION.SmokeOn}() is mainly for debugging. Puts smoke on retreat zone, hideouts etc.
-- * @{#SUPPRESSION.MenuON}() is mainly for debugging. Activates a radio menu item where certain functions like retreat etc. can be triggered manually.
-- 
-- 
-- @field #SUPPRESSION
SUPPRESSION={
  ClassName         = "SUPPRESSION",
  Debug             = false,
  lid               = nil,
  flare             = false,
  smoke             = false,
  DCSdesc           = nil,
  Type              = nil,
  IsInfantry        = nil,
  SpeedMax          = nil,
  Tsuppress_ave     = 15,
  Tsuppress_min     = 5,
  Tsuppress_max     = 25,
  TsuppressOver     = nil,
  IniGroupStrength  = nil,
  Nhit              = 0,
  Formation         = "Off road",
  Speed             = 4,
  MenuON            = false,
  FallbackON        = false,
  FallbackWait      = 60,
  FallbackDist      = 100,
  FallbackHeading   = nil,
  TakecoverON       = false,
  TakecoverWait     = 120,
  TakecoverRange    = 300,
  hideout           = nil,
  PminFlee          = 10,
  PmaxFlee          = 90,
  RetreatZone       = nil,
  RetreatDamage     = nil,
  RetreatWait       = 7200,
  CurrentAlarmState = "unknown",
  CurrentROE        = "unknown",
  DefaultAlarmState = "Auto",
  DefaultROE        = "Weapon Free",
  eventmoose        = true,
}

--- Enumerator of possible rules of engagement.
-- @type SUPPRESSION.ROE
-- @field #string Hold Hold fire.
-- @field #string Free Weapon fire.
-- @field #string Return Return fire.
SUPPRESSION.ROE={
  Hold="Weapon Hold",
  Free="Weapon Free",
  Return="Return Fire",  
}

--- Enumerator of possible alarm states.
-- @type SUPPRESSION.AlarmState
-- @field #string Auto Automatic.
-- @field #string Green Green.
-- @field #string Red Red.
SUPPRESSION.AlarmState={
  Auto="Auto",
  Green="Green",
  Red="Red",
}

--- Main F10 menu for suppresion, i.e. F10/Suppression.
-- @field #string MenuF10
SUPPRESSION.MenuF10=nil

--- PSEUDOATC version.
-- @field #number version
SUPPRESSION.version="0.9.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--TODO list
--DONE: Figure out who was shooting and move away from him.
--DONE: Move behind a scenery building if there is one nearby.
--DONE: Retreat to a given zone or point.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new AI_suppression object.
-- @param #SUPPRESSION self
-- @param Wrapper.Group#GROUP group The GROUP object for which suppression should be applied.
-- @return #SUPPRESSION SUPPRESSION object or *nil* if group does not exist or is not a ground group.
function SUPPRESSION:New(group)

  -- Inherits from FSM_CONTROLLABLE
  local self=BASE:Inherit(self, FSM_CONTROLLABLE:New()) -- #SUPPRESSION
  
  -- Check that group is present.
  if group then
    self.lid=string.format("SUPPRESSION %s | ", tostring(group:GetName()))
    self:T(self.lid..string.format("SUPPRESSION version %s. Activating suppressive fire for group %s", SUPPRESSION.version, group:GetName()))
  else
    self:E(self.lid.."SUPPRESSION | Requested group does not exist! (Has to be a MOOSE group.)")
    return nil
  end
  
  -- Check that we actually have a GROUND group.
  if group:IsGround()==false then
    self:E(self.lid..string.format("SUPPRESSION fire group %s has to be a GROUND group!", group:GetName()))
    return nil
  end  
  
  -- Set the controllable for the FSM.
  self:SetControllable(group)
  
  -- Get DCS descriptors of group.
  self.DCSdesc=group:GetDCSDesc(1)
  
  -- Get max speed the group can do and convert to km/h.
  self.SpeedMax=group:GetSpeedMax()
  
  -- Set speed to maximum.
  self.Speed=self.SpeedMax
  
  -- Is this infantry or not.
  self.IsInfantry=group:GetUnit(1):HasAttribute("Infantry")
  
  -- Type of group.
  self.Type=group:GetTypeName()
  
  -- Initial group strength.
  self.IniGroupStrength=#group:GetUnits()
  
  -- Set ROE and Alarm State.
  self:SetDefaultROE("Free")
  self:SetDefaultAlarmState("Auto")
  
  -- Transitions 
  self:AddTransition("*",           "Start",     "CombatReady")
  self:AddTransition("*",           "Status",    "*")
  self:AddTransition("CombatReady", "Hit",       "Suppressed")
  self:AddTransition("Suppressed",  "Hit",       "Suppressed") 
  self:AddTransition("Suppressed",  "Recovered", "CombatReady")
  self:AddTransition("Suppressed",  "TakeCover", "TakingCover")
  self:AddTransition("Suppressed",  "FallBack",  "FallingBack")
  self:AddTransition("*",           "Retreat",   "Retreating")
  self:AddTransition("TakingCover", "FightBack", "CombatReady")
  self:AddTransition("FallingBack", "FightBack", "CombatReady")
  self:AddTransition("Retreating",  "Retreated", "Retreated")
  self:AddTransition("*",           "OutOfAmmo", "*")
  self:AddTransition("*",           "Dead",      "*")
  self:AddTransition("*",           "Stop",      "Stopped")
  
  self:AddTransition("TakingCover", "Hit",       "TakingCover")
  self:AddTransition("FallingBack", "Hit",       "FallingBack")


  --- Trigger "Status" event.
  -- @function [parent=#SUPPRESSION] Status
  -- @param #SUPPRESSION self

  --- Trigger "Status" event after a delay.
  -- @function [parent=#SUPPRESSION] __Status
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds.

  --- User function for OnAfter "Status" event.
  -- @function [parent=#SUPPRESSION] OnAfterStatus
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Trigger "Hit" event.
  -- @function [parent=#SUPPRESSION] Hit
  -- @param #SUPPRESSION self
  -- @param Wrapper.Unit#UNIT Unit Unit that was hit.
  -- @param Wrapper.Unit#UNIT AttackUnit Unit that attacked.

  --- Trigger "Hit" event after a delay.
  -- @function [parent=#SUPPRESSION] __Hit
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds. 
  -- @param Wrapper.Unit#UNIT Unit Unit that was hit.
  -- @param Wrapper.Unit#UNIT AttackUnit Unit that attacked.

  --- User function for OnBefore "Hit" event.
  -- @function [parent=#SUPPRESSION] OnBeforeHit
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#UNIT Unit Unit that was hit.
  -- @param Wrapper.Unit#UNIT AttackUnit Unit that attacked.
  -- @return #boolean

  --- User function for OnAfter "Hit" event.
  -- @function [parent=#SUPPRESSION] OnAfterHit
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#UNIT Unit Unit that was hit.
  -- @param Wrapper.Unit#UNIT AttackUnit Unit that attacked.

  
  --- Trigger "Recovered" event.
  -- @function [parent=#SUPPRESSION] Recovered
  -- @param #SUPPRESSION self

  --- Trigger "Recovered" event after a delay.
  -- @function [parent=#SUPPRESSION] Recovered
  -- @param #number Delay Delay in seconds. 
  -- @param #SUPPRESSION self

  --- User function for OnBefore "Recovered" event.
  -- @function [parent=#SUPPRESSION] OnBeforeRecovered
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @return #boolean  

  --- User function for OnAfter "Recovered" event.
  -- @function [parent=#SUPPRESSION] OnAfterRecovered
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Trigger "TakeCover" event.
  -- @function [parent=#SUPPRESSION] TakeCover
  -- @param #SUPPRESSION self
  -- @param Core.Point#COORDINATE Hideout Place where the group will hide.

  --- Trigger "TakeCover" event after a delay.
  -- @function [parent=#SUPPRESSION] __TakeCover
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds. 
  -- @param Core.Point#COORDINATE Hideout Place where the group will hide.

  --- User function for OnBefore "TakeCover" event.
  -- @function [parent=#SUPPRESSION] OnBeforeTakeCover
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Point#COORDINATE Hideout Place where the group will hide.
  -- @return #boolean

  --- User function for OnAfter "TakeCover" event.
  -- @function [parent=#SUPPRESSION] OnAfterTakeCover
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Point#COORDINATE Hideout Place where the group will hide.


  --- Trigger "FallBack" event.
  -- @function [parent=#SUPPRESSION] FallBack
  -- @param #SUPPRESSION self
  -- @param Wrapper.Unit#UNIT AttackUnit Attacking unit. We will move away from this.

  --- Trigger "FallBack" event after a delay.
  -- @function [parent=#SUPPRESSION] __FallBack
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds. 
  -- @param Wrapper.Unit#UNIT AttackUnit Attacking unit. We will move away from this.

  --- User function for OnBefore "FallBack" event.
  -- @function [parent=#SUPPRESSION] OnBeforeFallBack
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#UNIT AttackUnit Attacking unit. We will move away from this.
  -- @return #boolean

  --- User function for OnAfter "FallBack" event.
  -- @function [parent=#SUPPRESSION] OnAfterFallBack
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#UNIT AttackUnit Attacking unit. We will move away from this.


  --- Trigger "Retreat" event.
  -- @function [parent=#SUPPRESSION] Retreat
  -- @param #SUPPRESSION self

  --- Trigger "Retreat" event after a delay.
  -- @function [parent=#SUPPRESSION] __Retreat
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds. 

  --- User function for OnBefore "Retreat" event.
  -- @function [parent=#SUPPRESSION] OnBeforeRetreat
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @return #boolean
  
  --- User function for OnAfter "Retreat" event.
  -- @function [parent=#SUPPRESSION] OnAfterRetreat
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Trigger "Retreated" event.
  -- @function [parent=#SUPPRESSION] Retreated
  -- @param #SUPPRESSION self

  --- Trigger "Retreated" event after a delay.
  -- @function [parent=#SUPPRESSION] __Retreated
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds. 

  --- User function for OnBefore "Retreated" event.
  -- @function [parent=#SUPPRESSION] OnBeforeRetreated
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @return #boolean
  
  --- User function for OnAfter "Retreated" event.
  -- @function [parent=#SUPPRESSION] OnAfterRetreated
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Trigger "FightBack" event.
  -- @function [parent=#SUPPRESSION] FightBack
  -- @param #SUPPRESSION self

  --- Trigger "FightBack" event after a delay.
  -- @function [parent=#SUPPRESSION] __FightBack
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds. 

  --- User function for OnBefore "FlightBack" event.
  -- @function [parent=#SUPPRESSION] OnBeforeFightBack
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @return #boolean
  
  --- User function for OnAfter "FlightBack" event.
  -- @function [parent=#SUPPRESSION] OnAfterFightBack
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Trigger "OutOfAmmo" event.
  -- @function [parent=#SUPPRESSION] OutOfAmmo
  -- @param #SUPPRESSION self

  --- Trigger "OutOfAmmo" event after a delay.
  -- @function [parent=#SUPPRESSION] __OutOfAmmo
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds. 

  --- User function for OnAfter "OutOfAmmo" event.
  -- @function [parent=#SUPPRESSION] OnAfterOutOfAmmo
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Trigger "Dead" event.
  -- @function [parent=#SUPPRESSION] Dead
  -- @param #SUPPRESSION self

  --- Trigger "Dead" event after a delay.
  -- @function [parent=#SUPPRESSION] __Dead
  -- @param #SUPPRESSION self
  -- @param #number Delay Delay in seconds. 

  --- User function for OnAfter "Dead" event.
  -- @function [parent=#SUPPRESSION] OnAfterDead
  -- @param #SUPPRESSION self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set average, minimum and maximum time a unit is suppressed each time it gets hit.
-- @param #SUPPRESSION self
-- @param #number Tave Average time [seconds] a group will be suppressed. Default is 15 seconds.
-- @param #number Tmin (Optional) Minimum time [seconds] a group will be suppressed. Default is 5 seconds.
-- @param #number Tmax (Optional) Maximum time a group will be suppressed. Default is 25 seconds.
function SUPPRESSION:SetSuppressionTime(Tave, Tmin, Tmax)
  self:F({Tave=Tave, Tmin=Tmin, Tmax=Tmax})

  -- Minimum suppression time is input or default but at least 1 second.
  self.Tsuppress_min=Tmin or self.Tsuppress_min
  self.Tsuppress_min=math.max(self.Tsuppress_min, 1)
  
  -- Maximum suppression time is input or dault but at least Tmin.
  self.Tsuppress_max=Tmax or self.Tsuppress_max
  self.Tsuppress_max=math.max(self.Tsuppress_max, self.Tsuppress_min)
  
  -- Expected suppression time is input or default but at leat Tmin and at most Tmax.
  self.Tsuppress_ave=Tave or self.Tsuppress_ave
  self.Tsuppress_ave=math.max(self.Tsuppress_min)
  self.Tsuppress_ave=math.min(self.Tsuppress_max)
  
  self:T(self.lid..string.format("Set ave suppression time to %d seconds.", self.Tsuppress_ave))
  self:T(self.lid..string.format("Set min suppression time to %d seconds.", self.Tsuppress_min))
  self:T(self.lid..string.format("Set max suppression time to %d seconds.", self.Tsuppress_max))
end

--- Set the zone to which a group retreats after being damaged too much.
-- @param #SUPPRESSION self
-- @param Core.Zone#ZONE zone MOOSE zone object.
function SUPPRESSION:SetRetreatZone(zone)
  self:F({zone=zone})
  self.RetreatZone=zone
end

--- Turn Debug mode on. Enables messages and more output to DCS log file.
-- @param #SUPPRESSION self
function SUPPRESSION:DebugOn()
  self:F()
  self.Debug=true
end

--- Flare units when they are hit, die or recover from suppression.
-- @param #SUPPRESSION self
function SUPPRESSION:FlareOn()
  self:F()
  self.flare=true
end

--- Smoke positions where units fall back to, hide or retreat.
-- @param #SUPPRESSION self
function SUPPRESSION:SmokeOn()
  self:F()
  self.smoke=true
end

--- Set the formation a group uses for fall back, hide or retreat.
-- @param #SUPPRESSION self
-- @param #string formation Formation of the group. Default "Vee".
function SUPPRESSION:SetFormation(formation)
  self:F(formation)
  self.Formation=formation or "Vee"
end

--- Set speed a group moves at for fall back, hide or retreat.
-- @param #SUPPRESSION self
-- @param #number speed Speed in km/h of group. Default max speed the group can do.
function SUPPRESSION:SetSpeed(speed)
  self:F(speed)
  self.Speed=speed or self.SpeedMax
  self.Speed=math.min(self.Speed, self.SpeedMax)
end

--- Enable fall back if a group is hit.
-- @param #SUPPRESSION self
-- @param #boolean switch Enable=true or disable=false fall back of group.
function SUPPRESSION:Fallback(switch)
  self:F(switch)
  if switch==nil then
    switch=true
  end
  self.FallbackON=switch
end

--- Set distance a group will fall back when it gets hit.
-- @param #SUPPRESSION self
-- @param #number distance Distance in meters.
function SUPPRESSION:SetFallbackDistance(distance)
  self:F(distance)
  self.FallbackDist=distance
end

--- Set time a group waits at its fall back position before it resumes its normal mission.
-- @param #SUPPRESSION self
-- @param #number time Time in seconds.
function SUPPRESSION:SetFallbackWait(time)
  self:F(time)
  self.FallbackWait=time
end

--- Enable take cover option if a unit is hit.
-- @param #SUPPRESSION self
-- @param #boolean switch Enable=true or disable=false fall back of group.
function SUPPRESSION:Takecover(switch)
  self:F(switch)
  if switch==nil then
    switch=true
  end
  self.TakecoverON=switch
end

--- Set time a group waits at its hideout position before it resumes its normal mission.
-- @param #SUPPRESSION self
-- @param #number time Time in seconds.
function SUPPRESSION:SetTakecoverWait(time)
  self:F(time)
  self.TakecoverWait=time
end

--- Set distance a group searches for hideout places.
-- @param #SUPPRESSION self
-- @param #number range Search range in meters.
function SUPPRESSION:SetTakecoverRange(range)
  self:F(range)
  self.TakecoverRange=range
end

--- Set hideout place explicitly.
-- @param #SUPPRESSION self
-- @param Core.Point#COORDINATE Hideout Place where the group will hide after the TakeCover event.
function SUPPRESSION:SetTakecoverPlace(Hideout)
  self.hideout=Hideout
end

--- Set minimum probability that a group flees (falls back or takes cover) after a hit event. Default is 10%.
-- @param #SUPPRESSION self
-- @param #number probability Probability in percent.
function SUPPRESSION:SetMinimumFleeProbability(probability)
  self:F(probability)
  self.PminFlee=probability or 10
end

--- Set maximum probability that a group flees (falls back or takes cover) after a hit event. Default is 90%.
-- @param #SUPPRESSION self
-- @param #number probability Probability in percent.
function SUPPRESSION:SetMaximumFleeProbability(probability)
  self:F(probability)
  self.PmaxFlee=probability or 90
end

--- Set damage threshold before a group is ordered to retreat if a retreat zone was defined.
-- If the group consists of only a singe unit, this referrs to the life of the unit.
-- If the group consists of more than one unit, this referrs to the group strength relative to its initial strength.
-- @param #SUPPRESSION self
-- @param #number damage Damage in percent. If group gets damaged above this value, the group will retreat. Default 50 %.
function SUPPRESSION:SetRetreatDamage(damage)
  self:F(damage)
  self.RetreatDamage=damage or 50
end

--- Set time a group waits in the retreat zone before it resumes its mission. Default is two hours.
-- @param #SUPPRESSION self
-- @param #number time Time in seconds. Default 7200 seconds = 2 hours.
function SUPPRESSION:SetRetreatWait(time)
  self:F(time)
  self.RetreatWait=time or 7200
end

--- Set alarm state a group will get after it returns from a fall back or take cover.
-- @param #SUPPRESSION self
-- @param #string alarmstate Alarm state. Possible "Auto", "Green", "Red". Default is "Auto".
function SUPPRESSION:SetDefaultAlarmState(alarmstate)
  self:F(alarmstate)
  if alarmstate:lower()=="auto" then
    self.DefaultAlarmState=SUPPRESSION.AlarmState.Auto
  elseif alarmstate:lower()=="green" then
    self.DefaultAlarmState=SUPPRESSION.AlarmState.Green
  elseif alarmstate:lower()=="red" then
    self.DefaultAlarmState=SUPPRESSION.AlarmState.Red
  else
    self.DefaultAlarmState=SUPPRESSION.AlarmState.Auto
  end
end

--- Set Rules of Engagement (ROE) a group will get when it recovers from suppression.
-- @param #SUPPRESSION self
-- @param #string roe ROE after suppression. Possible "Free", "Hold" or "Return". Default "Free".
function SUPPRESSION:SetDefaultROE(roe)
  self:F(roe)
  if roe:lower()=="free" then
    self.DefaultROE=SUPPRESSION.ROE.Free
  elseif roe:lower()=="hold" then
    self.DefaultROE=SUPPRESSION.ROE.Hold
  elseif roe:lower()=="return" then
    self.DefaultROE=SUPPRESSION.ROE.Return
  else
    self.DefaultROE=SUPPRESSION.ROE.Free
  end
end

--- Create an F10 menu entry for the suppressed group. The menu is mainly for Debugging purposes.
-- @param #SUPPRESSION self
-- @param #boolean switch Enable=true or disable=false menu group. Default is true.
function SUPPRESSION:MenuOn(switch)
  self:F(switch)
  if switch==nil then
    switch=true
  end
  self.MenuON=switch
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create F10 main menu, i.e. F10/Suppression. The menu is mainly for Debugging purposes.
-- @param #SUPPRESSION self
function SUPPRESSION:_CreateMenuGroup()
  local SubMenuName=self.Controllable:GetName()
  local MenuGroup=MENU_MISSION:New(SubMenuName, SUPPRESSION.MenuF10)
  MENU_MISSION_COMMAND:New("Fallback!", MenuGroup, self.OrderFallBack, self)
  MENU_MISSION_COMMAND:New("Take Cover!", MenuGroup, self.OrderTakeCover, self)
  MENU_MISSION_COMMAND:New("Retreat!", MenuGroup, self.OrderRetreat, self)
  MENU_MISSION_COMMAND:New("Report Status", MenuGroup, self.Status, self, true)
end

--- Order group to fall back between 100 and 150 meters in a random direction.
-- @param #SUPPRESSION self
function SUPPRESSION:OrderFallBack()
  local group=self.Controllable --Wrapper.Controllable#CONTROLLABLE
  local vicinity=group:GetCoordinate():GetRandomVec2InRadius(150, 100)
  local coord=COORDINATE:NewFromVec2(vicinity)
  self:FallBack(self.Controllable)
end

--- Order group to take cover at a nearby scenery object.
-- @param #SUPPRESSION self
function SUPPRESSION:OrderTakeCover()
  -- Search place to hide or take specified one.
  local Hideout=self.hideout
  if self.hideout==nil then
    Hideout=self:_SearchHideout()
  end      
  -- Trigger TakeCover event.
  self:TakeCover(Hideout)
end

--- Order group to retreat to a pre-defined zone.
-- @param #SUPPRESSION self
function SUPPRESSION:OrderRetreat()
  self:Retreat()
end

--- Status of group. Current ROE, alarm state, life.
-- @param #SUPPRESSION self
-- @param #boolean message Send message to all players.
function SUPPRESSION:StatusReport(message)

  local group=self.Controllable --Wrapper.Group#GROUP

  local nunits=group:CountAliveUnits()
  local roe=self.CurrentROE
  local state=self.CurrentAlarmState
  local life_min, life_max, life_ave, life_ave0, groupstrength=self:_GetLife()
  local ammotot=group:GetAmmunition()
  local detectedG=group:GetDetectedGroupSet():CountAlive()
  local detectedU=group:GetDetectedUnitSet():Count()
  
  local text=string.format("State %s, Units=%d/%d, ROE=%s, AlarmState=%s, Hits=%d, Life(min/max/ave/ave0)=%d/%d/%d/%d, Total Ammo=%d, Detected=%d/%d", 
  self:GetState(), nunits, self.IniGroupStrength, self.CurrentROE, self.CurrentAlarmState, self.Nhit, life_min, life_max, life_ave, life_ave0, ammotot, detectedG, detectedU)
  
  MESSAGE:New(text, 10):ToAllIf(message or self.Debug)
  self:I(self.lid..text)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Start" event. Initialized ROE and alarm state. Starts the event handler.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterStart(Controllable, From, Event, To)
  self:_EventFromTo("onafterStart", Event, From, To)
  
  local text=string.format("Started SUPPRESSION for group %s.", Controllable:GetName())
  self:I(self.lid..text)
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
  
  local rzone="not defined"
  if self.RetreatZone then
    rzone=self.RetreatZone:GetName()
  end
  
  -- Set retreat damage value if it was not set by user input.
  if self.RetreatDamage==nil then
    if self.RetreatZone then
      if self.IniGroupStrength==1 then
        self.RetreatDamage=60.0  -- 40% of life is left.
      elseif self.IniGroupStrength==2 then
        self.RetreatDamage=50.0  -- 50% of group left, i.e. 1 of 2. We already order a retreat, because if for a group 2 two a zone is defined it would not be used at all.
      else
        self.RetreatDamage=66.5  -- 34% of the group is left, e.g. 1 of 3,4 or 5, 2 of 6,7 or 8, 3 of 9,10 or 11, 4/12, 4/13, 4/14, 5/15, ... 
      end
    else
      self.RetreatDamage=100   -- If no retreat then this should be set to 100%.
    end
  end
  
  -- Create main F10 menu if it is not there yet.
  if self.MenuON then 
    if not SUPPRESSION.MenuF10 then
      SUPPRESSION.MenuF10 = MENU_MISSION:New("Suppression")
    end
    self:_CreateMenuGroup()
  end
    
  -- Set the current ROE and alam state.
  self:_SetAlarmState(self.DefaultAlarmState)
  self:_SetROE(self.DefaultROE)
  
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Suppressed group   = %s\n", Controllable:GetName())
  text=text..string.format("Type               = %s\n", self.Type)
  text=text..string.format("IsInfantry         = %s\n", tostring(self.IsInfantry))  
  text=text..string.format("Group strength     = %d\n", self.IniGroupStrength)
  text=text..string.format("Average time       = %5.1f seconds\n", self.Tsuppress_ave)
  text=text..string.format("Minimum time       = %5.1f seconds\n", self.Tsuppress_min)
  text=text..string.format("Maximum time       = %5.1f seconds\n", self.Tsuppress_max)
  text=text..string.format("Default ROE        = %s\n", self.DefaultROE)
  text=text..string.format("Default AlarmState = %s\n", self.DefaultAlarmState)
  text=text..string.format("Fall back ON       = %s\n", tostring(self.FallbackON))
  text=text..string.format("Fall back distance = %5.1f m\n", self.FallbackDist)
  text=text..string.format("Fall back wait     = %5.1f seconds\n", self.FallbackWait)
  text=text..string.format("Fall back heading  = %s degrees\n", tostring(self.FallbackHeading))
  text=text..string.format("Take cover ON      = %s\n", tostring(self.TakecoverON))
  text=text..string.format("Take cover search  = %5.1f m\n", self.TakecoverRange)
  text=text..string.format("Take cover wait    = %5.1f seconds\n", self.TakecoverWait)  
  text=text..string.format("Min flee probability = %5.1f\n", self.PminFlee)  
  text=text..string.format("Max flee probability = %5.1f\n", self.PmaxFlee)
  text=text..string.format("Retreat zone       = %s\n", rzone)
  text=text..string.format("Retreat damage     = %5.1f %%\n", self.RetreatDamage)
  text=text..string.format("Retreat wait       = %5.1f seconds\n", self.RetreatWait)
  text=text..string.format("Speed              = %5.1f km/h\n", self.Speed)
  text=text..string.format("Speed max          = %5.1f km/h\n", self.SpeedMax)
  text=text..string.format("Formation          = %s\n", self.Formation)
  text=text..string.format("******************************************************\n")
  self:T(self.lid..text)
    
  -- Add event handler.
  if self.eventmoose then
    self:HandleEvent(EVENTS.Hit,  self._OnEventHit)
    self:HandleEvent(EVENTS.Dead, self._OnEventDead)
  else
    world.addEventHandler(self)
  end
  
  self:__Status(-1)
end

--- After "Status" event.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterStatus(Controllable, From, Event, To)

  -- Suppressed group.  
  local group=self.Controllable --Wrapper.Group#GROUP
  
  -- Check if group object exists.
  if group then
  
    -- Number of alive units.
    local nunits=group:CountAliveUnits()
    
    -- Check if there are units.
    if nunits>0 then
      
      -- Retreat if completely out of ammo and retreat zone defined. 
      local nammo=group:GetAmmunition()
      if nammo==0 then
        self:OutOfAmmo()
      end

      -- Status report.
      self:StatusReport(false)
    
      -- Call status again if not "Stopped".
      if self:GetState()~="Stopped" then
        self:__Status(-30)
      end
      
    else
      -- Stop FSM as there are no units left.
      self:Stop()
    end
    
  else
    -- Stop FSM as there group object does not exist.
    self:Stop()
  end
  
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Hit" event.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit Unit that was hit.
-- @param Wrapper.Unit#UNIT AttackUnit Unit that attacked.
function SUPPRESSION:onafterHit(Controllable, From, Event, To, Unit, AttackUnit)
  self:_EventFromTo("onafterHit", Event, From, To)
    
  -- Suppress unit.
  if From=="CombatReady" or From=="Suppressed" then
    self:_Suppress()
  end
  
  -- Get life of group in %.
  local life_min, life_max, life_ave, life_ave0, groupstrength=self:_GetLife()
  
  -- Damage in %. If group consists only of one unit, we take its life value.
  local Damage=100-life_ave0
  
  -- Condition for retreat.
  local RetreatCondition = Damage >= self.RetreatDamage-0.01 and self.RetreatZone
    
  -- Probability that a unit flees. The probability increases linearly with the damage of the group/unit.
  -- If Damage=0             ==> P=Pmin
  -- if Damage=RetreatDamage ==> P=Pmax
  -- If no retreat zone has been specified, RetreatDamage is 100.
  local Pflee=(self.PmaxFlee-self.PminFlee)/self.RetreatDamage * math.min(Damage, self.RetreatDamage) + self.PminFlee
  
  -- Evaluate flee condition.
  local P=math.random(0,100)
  local FleeCondition =  P < Pflee
  
  local text
  text=string.format("\nGroup %s: Life min=%5.1f, max=%5.1f, ave=%5.1f, ave0=%5.1f group=%5.1f\n", Controllable:GetName(), life_min, life_max, life_ave, life_ave0, groupstrength)
  text=string.format("Group %s: Damage = %8.4f (%8.4f retreat threshold).\n", Controllable:GetName(), Damage, self.RetreatDamage)
  text=string.format("Group %s: P_Flee = %5.1f %5.1f=P_rand (P_Flee > Prand ==> Flee)\n", Controllable:GetName(), Pflee, P)
  self:T(self.lid..text)
  
  -- Group is obviously destroyed.
  if Damage >= 99.9 then
    return
  end
  
  if RetreatCondition then
  
    -- Trigger Retreat event.
    self:Retreat()
    
  elseif FleeCondition then
  
    if self.FallbackON and AttackUnit:IsGround() then
    
      -- Trigger FallBack event.
      self:FallBack(AttackUnit)
      
    elseif self.TakecoverON then
    
      -- Search place to hide or take specified one.
      local Hideout=self.hideout
      if self.hideout==nil then
        Hideout=self:_SearchHideout()
      end
      
      -- Trigger TakeCover event.
      self:TakeCover(Hideout)
    end
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Recovered" event. Check if suppression time is over.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean
function SUPPRESSION:onbeforeRecovered(Controllable, From, Event, To)
  self:_EventFromTo("onbeforeRecovered", Event, From, To)
  
  -- Current time.
  local Tnow=timer.getTime()
  
  -- Debug info
  self:T(self.lid..string.format("onbeforeRecovered: Time now: %d  - Time over: %d", Tnow, self.TsuppressionOver))
  
  -- Recovery is only possible if enough time since the last hit has passed.
  if Tnow >= self.TsuppressionOver then
    return true
  else
    return false
  end
  
end

--- After "Recovered" event. Group has recovered and its ROE is set back to the "normal" unsuppressed state. Optionally the group is flared green.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterRecovered(Controllable, From, Event, To)
  self:_EventFromTo("onafterRecovered", Event, From, To)
  
  if Controllable and Controllable:IsAlive() then
  
    -- Debug message.
    local text=string.format("Group %s has recovered!", Controllable:GetName())
    MESSAGE:New(text, 10):ToAllIf(self.Debug)
    self:T(self.lid..text)
    
    -- Set ROE back to default.
    self:_SetROE()
    
    -- Flare unit green.
    if self.flare or self.Debug then
      Controllable:FlareGreen()
    end
    
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "FightBack" event. ROE and Alarm state are set back to default.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterFightBack(Controllable, From, Event, To)
  self:_EventFromTo("onafterFightBack", Event, From, To)
  
  -- Set ROE and alarm state back to default.
  self:_SetROE()
  self:_SetAlarmState()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "FallBack" event. We check that group is not already falling back.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT AttackUnit Attacking unit. We will move away from this.
-- @return #boolean
function SUPPRESSION:onbeforeFallBack(Controllable, From, Event, To, AttackUnit)
  self:_EventFromTo("onbeforeFallBack", Event, From, To)
  
  --TODO: Add retreat? Only allowd transition is Suppressed-->Fallback. So in principle no need.
  if From == "FallingBack" then
    return false
  else
    return true
  end
end

--- After "FallBack" event. We get the heading away from the attacker and route the group a certain distance in that direction.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT AttackUnit Attacking unit. We will move away from this.
function SUPPRESSION:onafterFallBack(Controllable, From, Event, To, AttackUnit)
  self:_EventFromTo("onafterFallback", Event, From, To)
  
  -- Debug info
  self:T(self.lid..string.format("Group %s is falling back after %d hits.", Controllable:GetName(), self.Nhit))
  
  -- Coordinate of the attacker and attacked unit.
  local ACoord=AttackUnit:GetCoordinate()
  local DCoord=Controllable:GetCoordinate()
  
  -- Heading from attacker to attacked unit.
  local heading=self:_Heading(ACoord, DCoord)
  
  -- Overwrite heading with user specified heading.
  if self.FallbackHeading then
    heading=self.FallbackHeading
  end
  
  -- Create a coordinate ~ 100 m in opposite direction of the attacking unit.
  local Coord=DCoord:Translate(self.FallbackDist, heading)
  
  -- Place marker
  if self.Debug then
    local MarkerID=Coord:MarkToAll("Fall back position for group "..Controllable:GetName())
  end
  
  -- Smoke the coordinate.
  if self.smoke or self.Debug then
    Coord:SmokeBlue()
  end
  
  -- Set ROE to weapon hold.
  self:_SetROE(SUPPRESSION.ROE.Hold)
  
  -- Set alarm state to GREEN and let the unit run away.
  self:_SetAlarmState(SUPPRESSION.AlarmState.Green)

  -- Make the group run away.
  self:_Run(Coord, self.Speed, self.Formation, self.FallbackWait)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "TakeCover" event. Search an area around the group for possible scenery objects where the group can hide.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Hideout Place where the group will hide.
-- @return #boolean
function SUPPRESSION:onbeforeTakeCover(Controllable, From, Event, To, Hideout)
  self:_EventFromTo("onbeforeTakeCover", Event, From, To)
  
  --TODO: Need to test this!
  if From=="TakingCover" then
    return false
  end
  
  -- Block transition if no hideout place is given.
  if Hideout ~= nil then
    return true
  else
    return false
  end

end

--- After "TakeCover" event. Group will run to a nearby scenery object and "hide" there for a certain time.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Hideout Place where the group will hide.
function SUPPRESSION:onafterTakeCover(Controllable, From, Event, To, Hideout)
  self:_EventFromTo("onafterTakeCover", Event, From, To)
     
  if self.Debug then
    local MarkerID=Hideout:MarkToAll(string.format("Hideout for group %s", Controllable:GetName()))
  end
  
  -- Smoke place of hideout.
  if self.smoke or self.Debug then
    Hideout:SmokeBlue()
  end
  
  -- Set ROE to weapon hold.
  self:_SetROE(SUPPRESSION.ROE.Hold)
  
  -- Set the ALARM STATE to GREEN. Then the unit will move even if it is under fire.
  self:_SetAlarmState(SUPPRESSION.AlarmState.Green)
  
  -- Make the group run away.
  self:_Run(Hideout, self.Speed, self.Formation, self.TakecoverWait)
    
end

--- After "OutOfAmmo" event. Triggered when group is completely out of ammo.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterOutOfAmmo(Controllable, From, Event, To)
  self:_EventFromTo("onafterOutOfAmmo", Event, From, To)

  -- Info to log.
  self:I(self.lid..string.format("Out of ammo!"))
    
  -- Order retreat if retreat zone was specified.
  if self.RetreatZone then
    self:Retreat()
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Retreat" event. We check that the group is not already retreating.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean True if transition is allowed, False if transition is forbidden.
function SUPPRESSION:onbeforeRetreat(Controllable, From, Event, To)
  self:_EventFromTo("onbeforeRetreat", Event, From, To)
  
  if From=="Retreating" then
    local text=string.format("Group %s is already retreating.", tostring(Controllable:GetName()))
    self:T2(self.lid..text)
    return false
  else
    return true
  end
  
end

--- After "Retreat" event. Find a random point in the retreat zone and route the group there.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterRetreat(Controllable, From, Event, To)
  self:_EventFromTo("onafterRetreat", Event, From, To)
  
  -- Route the group to a zone.
  local text=string.format("Group %s is retreating! Alarm state green.", Controllable:GetName())
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
  self:T(self.lid..text)
  
  -- Get a random point in the retreat zone.
  local ZoneCoord=self.RetreatZone:GetRandomCoordinate() -- Core.Point#COORDINATE
  local ZoneVec2=ZoneCoord:GetVec2()

  -- Debug smoke zone and point.
  if self.smoke or self.Debug then
    ZoneCoord:SmokeBlue()
  end
  if self.Debug then
    self.RetreatZone:SmokeZone(SMOKECOLOR.Red, 12)
  end
  
  -- Set ROE to weapon hold.
  self:_SetROE(SUPPRESSION.ROE.Hold)
  
  -- Set the ALARM STATE to GREEN. Then the unit will move even if it is under fire.
  self:_SetAlarmState(SUPPRESSION.AlarmState.Green)
  
  -- Make unit run to retreat zone and wait there for ~two hours.
  self:_Run(ZoneCoord, self.Speed, self.Formation, self.RetreatWait)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Retreateded" event. Check that the group is really in the retreat zone.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onbeforeRetreated(Controllable, From, Event, To)
  self:_EventFromTo("onbeforeRetreated", Event, From, To)
  
  -- Check that the group is inside the zone.
  local inzone=self.RetreatZone:IsVec3InZone(Controllable:GetVec3())
  
  return inzone
end

--- After "Retreateded" event. Group has reached the retreat zone. Set ROE to return fire and alarm state to auto.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterRetreated(Controllable, From, Event, To)
  self:_EventFromTo("onafterRetreated", Event, From, To)
  
  -- Set ROE to weapon return fire.
  self:_SetROE(SUPPRESSION.ROE.Return)
  
  -- Set the ALARM STATE to GREEN. Then the unit will move even if it is under fire.
  self:_SetAlarmState(SUPPRESSION.AlarmState.Auto)
  
  -- TODO: Add hold task? Move from _Run()
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Dead" event, when a unit has died. When all units of a group are dead, FSM is stopped and eventhandler removed.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterDead(Controllable, From, Event, To)
  self:_EventFromTo("onafterDead", Event, From, To)
  
  local group=self.Controllable --Wrapper.Group#GROUP
  
  if group then
  
    -- Number of units left in the group.
    local nunits=group:CountAliveUnits()
        
    local text=string.format("Group %s: One of our units just died! %d units left.", self.Controllable:GetName(), nunits)
    MESSAGE:New(text, 10):ToAllIf(self.Debug)
    self:T(self.lid..text)
        
    -- Go to stop state.
    if nunits==0 then
      self:Stop()
    end
    
  else
    self:Stop()
  end
  
end

--- After "Stop" event.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SUPPRESSION:onafterStop(Controllable, From, Event, To)
  self:_EventFromTo("onafterStop", Event, From, To)
      
  local text=string.format("Stopping SUPPRESSION for group %s", self.Controllable:GetName())
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
  self:I(self.lid..text)
      
  -- Clear all pending schedules
  self.CallScheduler:Clear()
  
  if self.mooseevents then
    self:UnHandleEvent(EVENTS.Dead)
    self:UnHandleEvent(EVENTS.Hit)
  else
    world.removeEventHandler(self)
  end
  
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Event Handler
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event handler for suppressed groups.
--@param #SUPPRESSION self
function SUPPRESSION:onEvent(Event)
  --self:E(event)
  
  if Event == nil or Event.initiator == nil or Unit.getByName(Event.initiator:getName()) == nil then
    return true
  end
    
  local EventData={}
  if Event.initiator then
    EventData.IniDCSUnit   = Event.initiator
    EventData.IniUnitName  = Event.initiator:getName()
    EventData.IniDCSGroup  = Event.initiator:getGroup()
    EventData.IniGroupName = Event.initiator:getGroup():getName()
    EventData.IniGroup     = GROUP:FindByName(EventData.IniGroupName)
    EventData.IniUnit      = UNIT:FindByName(EventData.IniUnitName)
  end

  if Event.target then
    EventData.TgtDCSUnit   = Event.target
    EventData.TgtUnitName  = Event.target:getName()
    EventData.TgtDCSGroup  = Event.target:getGroup()
    EventData.TgtGroupName = Event.target:getGroup():getName()
    EventData.TgtGroup     = GROUP:FindByName(EventData.TgtGroupName)
    EventData.TgtUnit      = UNIT:FindByName(EventData.TgtUnitName)
  end  
  
  
  -- Event HIT
  if Event.id == world.event.S_EVENT_HIT then
    self:_OnEventHit(EventData)
  end

  -- Event DEAD
  if Event.id == world.event.S_EVENT_DEAD then
    self:_OnEventDead(EventData)
  end
  
end

--- Event handler for Dead event of suppressed groups.
-- @param #SUPPRESSION self
-- @param Core.Event#EVENTDATA EventData
function SUPPRESSION:_OnEventHit(EventData)
  self:F(EventData)

  local GroupNameSelf=self.Controllable:GetName()
  local GroupNameTgt=EventData.TgtGroupName
  local TgtUnit=EventData.TgtUnit
  local tgt=EventData.TgtDCSUnit
  local IniUnit=EventData.IniUnit

  -- Check that correct group was hit.
  if GroupNameTgt == GroupNameSelf then
  
    self:T(self.lid..string.format("Hit event at t = %5.1f", timer.getTime()))
  
    -- Flare unit that was hit.
    if self.flare or self.Debug then
      TgtUnit:FlareRed()
    end
    
    -- Increase Hit counter.
    self.Nhit=self.Nhit+1

    -- Info on hit times.
    self:T(self.lid..string.format("Group %s has just been hit %d times.", self.Controllable:GetName(), self.Nhit))
    
    --self:Status()
    local life=tgt:getLife()/(tgt:getLife0()+1)*100
    self:T2(self.lid..string.format("Target unit life = %5.1f", life))
  
    -- FSM Hit event.
    self:__Hit(3, TgtUnit, IniUnit)
  end

end

--- Event handler for Dead event of suppressed groups.
-- @param #SUPPRESSION self
-- @param Core.Event#EVENTDATA EventData
function SUPPRESSION:_OnEventDead(EventData)

  local GroupNameSelf=self.Controllable:GetName()
  local GroupNameIni=EventData.IniGroupName

  -- Check for correct group.
  if  GroupNameIni==GroupNameSelf then
    
    -- Dead Unit.
    local IniUnit=EventData.IniUnit --Wrapper.Unit#UNIT
    local IniUnitName=EventData.IniUnitName
    
    if EventData.IniUnit then
      self:T2(self.lid..string.format("Group %s: Dead MOOSE unit DOES exist! Unit name %s.", GroupNameIni, IniUnitName))
    else
      self:T2(self.lid..string.format("Group %s: Dead MOOSE unit DOES NOT not exist! Unit name %s.", GroupNameIni, IniUnitName))
    end
    
    if EventData.IniDCSUnit then
      self:T2(self.lid..string.format("Group %s: Dead DCS unit DOES exist! Unit name %s.", GroupNameIni, IniUnitName))
    else
      self:T2(self.lid..string.format("Group %s: Dead DCS unit DOES NOT exist! Unit name %s.", GroupNameIni, IniUnitName))
    end
    
    -- Flare unit that died.
    if IniUnit and (self.flare or self.Debug) then
      IniUnit:FlareWhite()
      self:T(self.lid..string.format("Flare Dead MOOSE unit."))
    end
    
    -- Flare unit that died.
    if EventData.IniDCSUnit and (self.flare or self.Debug) then
      local p=EventData.IniDCSUnit:getPosition().p
      trigger.action.signalFlare(p, trigger.flareColor.Yellow , 0)
      self:T(self.lid..string.format("Flare Dead DCS unit."))
    end
       
    -- Get status.
    self:Status()
    
    -- FSM Dead event.
    self:__Dead(0.1)
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Suppress fire of a unit by setting its ROE to "Weapon Hold".
-- @param #SUPPRESSION self
function SUPPRESSION:_Suppress()

  -- Current time.
  local Tnow=timer.getTime()
  
  -- Controllable
  local Controllable=self.Controllable --Wrapper.Controllable#CONTROLLABLE
  
  -- Group will hold their weapons.
  self:_SetROE(SUPPRESSION.ROE.Hold)
  
  -- Get randomized time the unit is suppressed.
  local sigma=(self.Tsuppress_max-self.Tsuppress_min)/4
  local Tsuppress=self:_Random_Gaussian(self.Tsuppress_ave,sigma,self.Tsuppress_min, self.Tsuppress_max)
  
  -- Time at which the suppression is over.
  local renew=true
  if self.TsuppressionOver ~= nil then
    if Tsuppress+Tnow > self.TsuppressionOver then
      self.TsuppressionOver=Tnow+Tsuppress
    else
      renew=false
    end
  else
    self.TsuppressionOver=Tnow+Tsuppress
  end
  
  -- Recovery event will be called in Tsuppress seconds.
  if renew then
    self:__Recovered(self.TsuppressionOver-Tnow)
  end
  
  -- Debug message.
  local text=string.format("Group %s is suppressed for %d seconds. Suppression ends at %d:%02d.", Controllable:GetName(), Tsuppress, self.TsuppressionOver/60, self.TsuppressionOver%60)
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
  self:T(self.lid..text)

end


--- Make group run/drive to a certain point. We put in several intermediate waypoints because sometimes the group stops before it arrived at the desired point.
--@param #SUPPRESSION self
--@param Core.Point#COORDINATE fin Coordinate where we want to go.
--@param #number speed Speed of group. Default is 20.
--@param #string formation Formation of group. Default is "Vee".
--@param #number wait Time the group will wait/hold at final waypoint. Default is 30 seconds.
function SUPPRESSION:_Run(fin, speed, formation, wait)

  speed=speed or 20
  formation=formation or "Off road"
  wait=wait or 30

  local group=self.Controllable -- Wrapper.Controllable#CONTROLLABLE
  
  if group and group:IsAlive() then
  
    -- Clear all tasks.
    group:ClearTasks()
    
    -- Current coordinates of group.
    local ini=group:GetCoordinate()
    
    -- Distance between current and final point. 
    local dist=ini:Get2DDistance(fin)
    
    -- Heading from ini to fin.
    local heading=self:_Heading(ini, fin)
    
    -- Number of waypoints.
    local nx
    if dist <= 50 then
      nx=2
    elseif dist <= 100 then
      nx=3
    elseif dist <= 500 then
      nx=4
    else
      nx=5
    end
    
    -- Number of intermediate waypoints.
    local dx=dist/(nx-1)
      
    -- Waypoint and task arrays.
    local wp={}
    local tasks={}
    
    -- First waypoint is the current position of the group.
    wp[1]=ini:WaypointGround(speed, formation)
    tasks[1]=group:TaskFunction("SUPPRESSION._Passing_Waypoint", self, 1, false)
  
    if self.Debug then  
      local MarkerID=ini:MarkToAll(string.format("Waypoing %d of group %s (initial)", #wp, self.Controllable:GetName()))
    end
    
    self:T2(self.lid..string.format("Number of waypoints %d", nx))
    for i=1,nx-2 do
    
      local x=dx*i
      local coord=ini:Translate(x, heading)
      
      wp[#wp+1]=coord:WaypointGround(speed, formation)
      tasks[#tasks+1]=group:TaskFunction("SUPPRESSION._Passing_Waypoint", self, #wp, false)
      
      self:T2(self.lid..string.format("%d x = %4.1f", i, x))
      if self.Debug then
        local MarkerID=coord:MarkToAll(string.format("Waypoing %d of group %s", #wp, self.Controllable:GetName()))
      end
      
    end
    self:T2(self.lid..string.format("Total distance: %4.1f", dist))
    
    -- Final waypoint.
    wp[#wp+1]=fin:WaypointGround(speed, formation)
    if self.Debug then
      local MarkerID=fin:MarkToAll(string.format("Waypoing %d of group %s (final)", #wp, self.Controllable:GetName()))
    end
    
      -- Task to hold.
    local ConditionWait=group:TaskCondition(nil, nil, nil, nil, wait, nil)
    local TaskHold = group:TaskHold()
    
    -- Task combo to make group hold at final waypoint.
    local TaskComboFin = {}
    TaskComboFin[#TaskComboFin+1] = group:TaskFunction("SUPPRESSION._Passing_Waypoint", self, #wp, true)
    TaskComboFin[#TaskComboFin+1] = group:TaskControlled(TaskHold, ConditionWait)
  
    -- Add final task.  
    tasks[#tasks+1]=group:TaskCombo(TaskComboFin)
  
    -- Original waypoints of the group.
    local Waypoints = group:GetTemplateRoutePoints()
    
    -- New points are added to the default route.
    for i,p in ipairs(wp) do
      table.insert(Waypoints, i, wp[i])
    end
    
    -- Set task for all waypoints.
    for i,wp in ipairs(Waypoints) do
      group:SetTaskWaypoint(Waypoints[i], tasks[i])
    end
    
    -- Submit task and route group along waypoints.
    group:Route(Waypoints)
    
  else
    self:E(self.lid..string.format("ERROR: Group is not alive!"))
  end

end

--- Function called when group is passing a waypoint. At the last waypoint we set the group back to CombatReady.
--@param Wrapper.Group#GROUP group Group which is passing a waypoint.
--@param #SUPPRESSION Fsm The suppression object.
--@param #number i Waypoint number that has been reached.
--@param #boolean final True if it is the final waypoint. Start Fightback.
function SUPPRESSION._Passing_Waypoint(group, Fsm, i, final)

  -- Debug message.
  local text=string.format("Group %s passing waypoint %d (final=%s)", group:GetName(), i, tostring(final))
  MESSAGE:New(text,10):ToAllIf(Fsm.Debug)
  if Fsm.Debug then
    env.info(self.lid..text)
  end

  if final then
    if Fsm:is("Retreating") then
      -- Retreated-->Retreated.
      Fsm:Retreated()
    else
    -- FightBack-->Combatready: Change alarm state back to default.  
      Fsm:FightBack()
    end
  end
end


--- Search a place to hide. This is any scenery object in the vicinity.
--@param #SUPPRESSION self
--@return Core.Point#COORDINATE Coordinate of the hideout place.
--@return nil If no scenery object is within search radius.
function SUPPRESSION:_SearchHideout()
  -- We search objects in a zone with radius ~300 m around the group.
  local Zone = ZONE_GROUP:New("Zone_Hiding", self.Controllable, self.TakecoverRange)
  local gpos = self.Controllable:GetCoordinate()

  -- Scan for Scenery objects to run/drive to.
  Zone:Scan(Object.Category.SCENERY)
  
  -- Array with all possible hideouts, i.e. scenery objects in the vicinity of the group.
  local hideouts={}

  for SceneryTypeName, SceneryData in pairs(Zone:GetScannedScenery()) do
    for SceneryName, SceneryObject in pairs(SceneryData) do
    
      local SceneryObject = SceneryObject -- Wrapper.Scenery#SCENERY
      
      -- Position of the scenery object.
      local spos=SceneryObject:GetCoordinate()
      
      -- Distance from group to hideout.
      local distance= spos:Get2DDistance(gpos)
      
      if self.Debug then
        -- Place markers on every possible scenery object.
        local MarkerID=SceneryObject:GetCoordinate():MarkToAll(string.format("%s scenery object %s", self.Controllable:GetName(),SceneryObject:GetTypeName()))
        local text=string.format("%s scenery: %s, Coord %s", self.Controllable:GetName(), SceneryObject:GetTypeName(), SceneryObject:GetCoordinate():ToStringLLDMS())
        self:T2(self.lid..text)
      end
      
      -- Add to table.
      table.insert(hideouts, {object=SceneryObject, distance=distance})      
    end
  end
  
  -- Get random hideout place.
  local Hideout=nil
  if #hideouts>0 then
  
    -- Debug info.
    self:T(self.lid.."Number of hideouts "..#hideouts)
    
    -- Sort results table wrt number of hits.
    local _sort = function(a,b) return a.distance < b.distance end
    table.sort(hideouts,_sort)
    
    -- Pick a random location.
    --Hideout=hideouts[math.random(#hideouts)].object
    
    -- Pick closest location.
    Hideout=hideouts[1].object:GetCoordinate()
    
  else
    self:E(self.lid.."No hideouts found!")
  end
  
  return Hideout

end

--- Get (relative) life in percent of a group. Function returns the value of the units with the smallest and largest life. Also the average value of all groups is returned.
-- @param #SUPPRESSION self
-- @return #number Smallest life value of all units.
-- @return #number Largest life value of all units.
-- @return #number Average life value of all alife groups
-- @return #number Average life value of all groups including already dead ones.
-- @return #number Relative group strength.
function SUPPRESSION:_GetLife()

  local group=self.Controllable --Wrapper.Group#GROUP
  
  if group and group:IsAlive() then
  
    local units=group:GetUnits()
  
    local life_min=nil
    local life_max=nil
    local life_ave=0
    local life_ave0=0
    local n=0
    
    local groupstrength=#units/self.IniGroupStrength*100
    
    self.T2(self.lid..string.format("Group %s _GetLife nunits = %d", self.Controllable:GetName(), #units))
    
    for _,unit in pairs(units) do
    
      local unit=unit -- Wrapper.Unit#UNIT
      if unit and unit:IsAlive() then
        n=n+1
        local life=unit:GetLife()/(unit:GetLife0()+1)*100
        if life_min==nil or life < life_min then
          life_min=life
        end
        if life_max== nil or life > life_max then
          life_max=life
        end
        life_ave=life_ave+life
        if self.Debug then
          local text=string.format("n=%02d: Life = %3.1f, Life0 = %3.1f, min=%3.1f, max=%3.1f, ave=%3.1f, group=%3.1f", n, unit:GetLife(), unit:GetLife0(), life_min, life_max, life_ave/n,groupstrength)
          self:T2(self.lid..text)
        end
      end
      
    end
    
    -- If the counter did not increase (can happen!) return 0
    if n==0 then
      return 0,0,0,0,0
    end
    
    -- Average life relative to initial group strength including the dead ones.
    life_ave0=life_ave/self.IniGroupStrength
    
    -- Average life of all alive units.
    life_ave=life_ave/n    
    
    return life_min, life_max, life_ave, life_ave0, groupstrength
  else
    return 0, 0, 0, 0, 0
  end
end


--- Heading from point a to point b in degrees.
--@param #SUPPRESSION self
--@param Core.Point#COORDINATE a Coordinate.
--@param Core.Point#COORDINATE b Coordinate.
--@return #number angle Angle from a to b in degrees.
function SUPPRESSION:_Heading(a, b)
  local dx = b.x-a.x
  local dy = b.z-a.z
  local angle = math.deg(math.atan2(dy,dx))
  if angle < 0 then
    angle = 360 + angle
  end
  return angle
end

--- Generate Gaussian pseudo-random numbers.
-- @param #SUPPRESSION self
-- @param #number x0 Expectation value of distribution.
-- @param #number sigma (Optional) Standard deviation. Default 10.
-- @param #number xmin (Optional) Lower cut-off value.
-- @param #number xmax (Optional) Upper cut-off value.
-- @return #number Gaussian random number.
function SUPPRESSION:_Random_Gaussian(x0, sigma, xmin, xmax)

  -- Standard deviation. Default 5 if not given.
  sigma=sigma or 5
    
  local r
  local gotit=false
  local i=0
  while not gotit do
  
    -- Uniform numbers in [0,1). We need two.
    local x1=math.random()
    local x2=math.random()
  
    -- Transform to Gaussian exp(-(x-x0)²/(2*sigma²).
    r = math.sqrt(-2*sigma*sigma * math.log(x1)) * math.cos(2*math.pi * x2) + x0
    
    i=i+1
    if (r>=xmin and r<=xmax) or i>100 then
      gotit=true
    end
  end
  
  return r

end

--- Sets the ROE for the group and updates the current ROE variable.
-- @param #SUPPRESSION self
-- @param #string roe ROE the group will get. Possible "Free", "Hold", "Return". Default is self.DefaultROE.
function SUPPRESSION:_SetROE(roe)
  local group=self.Controllable --Wrapper.Controllable#CONTROLLABLE
  
  -- If no argument is given, we take the default ROE.
  roe=roe or self.DefaultROE
  
  -- Update the current ROE.
  self.CurrentROE=roe
  
  -- Set the ROE.
  if roe==SUPPRESSION.ROE.Free then
    group:OptionROEOpenFire()
  elseif roe==SUPPRESSION.ROE.Hold then
    group:OptionROEHoldFire()
  elseif roe==SUPPRESSION.ROE.Return then
    group:OptionROEReturnFire()
  else
    self:E(self.lid.."Unknown ROE requested: "..tostring(roe))
    group:OptionROEOpenFire()
    self.CurrentROE=SUPPRESSION.ROE.Free
  end
  
  local text=string.format("Group %s now has ROE %s.", self.Controllable:GetName(), self.CurrentROE)
  self:T(self.lid..text)
end

--- Sets the alarm state of the group and updates the current alarm state variable.
-- @param #SUPPRESSION self
-- @param #string state Alarm state the group will get. Possible "Auto", "Green", "Red". Default is self.DefaultAlarmState.
function SUPPRESSION:_SetAlarmState(state)
  local group=self.Controllable --Wrapper.Controllable#CONTROLLABLE
  
  -- Input or back to default alarm state.
  state=state or self.DefaultAlarmState
  
  -- Update the current alam state of the group.
  self.CurrentAlarmState=state
  
  -- Set the alarm state.
  if state==SUPPRESSION.AlarmState.Auto then
    group:OptionAlarmStateAuto()
  elseif state==SUPPRESSION.AlarmState.Green then
    group:OptionAlarmStateGreen()
  elseif state==SUPPRESSION.AlarmState.Red then
    group:OptionAlarmStateRed()
  else
    self:E(self.lid.."Unknown alarm state requested: "..tostring(state))
    group:OptionAlarmStateAuto()
    self.CurrentAlarmState=SUPPRESSION.AlarmState.Auto
  end
  
  local text=string.format("Group %s now has Alarm State %s.", self.Controllable:GetName(), self.CurrentAlarmState)
  self:T(self.lid..text)
end

--- Print event-from-to string to DCS log file. 
-- @param #SUPPRESSION self
-- @param #string BA Before/after info.
-- @param #string Event Event.
-- @param #string From From state.
-- @param #string To To state.
function SUPPRESSION:_EventFromTo(BA, Event, From, To)
  local text=string.format("\n%s: %s EVENT %s: %s --> %s", BA, self.Controllable:GetName(), Event, From, To)
  self:T2(self.lid..text)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

