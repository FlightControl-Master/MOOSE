--- @module Process_Smoke

do -- PROCESS_SMOKE_TARGETS

  --- PROCESS_SMOKE_TARGETS class
  -- @type PROCESS_SMOKE_TARGETS
  -- @field Task#TASK_BASE Task
  -- @field Unit#UNIT ProcessUnit
  -- @field Set#SET_UNIT TargetSetUnit
  -- @field Zone#ZONE_BASE TargetZone
  -- @extends Task2#TASK2
  PROCESS_SMOKE_TARGETS = { 
    ClassName = "PROCESS_SMOKE_TARGETS",
  }
  
  
  --- Creates a new task assignment state machine. The process will request from the menu if it accepts the task, if not, the unit is removed from the simulator.
  -- @param #PROCESS_SMOKE_TARGETS self
  -- @param Task#TASK Task
  -- @param Unit#UNIT Unit
  -- @return #PROCESS_SMOKE_TARGETS self
  function PROCESS_SMOKE_TARGETS:New( Task, ProcessUnit, TargetSetUnit, TargetZone )
  
    local FSMT = {
      initial = 'None',
      events = {
        { name = 'Start',  from = 'None',  to = 'AwaitSmoke' },
        { name = 'Next',  from = 'AwaitSmoke',  to = 'Smoking' },
        { name = 'Next',  from = 'Smoking',  to = 'AwaitSmoke' },
        { name = 'Fail',  from = 'Smoking',  to = 'Failed' },
        { name = 'Fail',  from = 'AwaitSmoke',  to = 'Failed' },
        { name = 'Fail',  from = 'None',  to = 'Failed' },
      },
      callbacks = {
        onStart = self.OnStart,
        onNext = self.OnNext,
        onSmoking = self.OnSmoking,
      },
      endstates = {
      },
    }

    -- Inherits from BASE
    local self = BASE:Inherit( self, PROCESS:New( FSMT, ProcessUnit, "SMOKE_TARGETS" ) ) -- #PROCESS_SMOKE_TARGETS
    
    self.TargetSetUnit = TargetSetUnit
    self.TargetZone = TargetZone
    
    
    return self
  end
  
  --- StateMachine callback function
  -- @param #PROCESS_SMOKE_TARGETS self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_SMOKE_TARGETS:OnStart( ProcessUnit, Event, From, To )
    self:E( { Event, From, To, ProcessUnit.UnitName} )
  
    self:E("Set smoke menu")
  
    local ProcessGroup = ProcessUnit:GetGroup()
    --local MissionMenu = self.Task.Mission:GetMissionMenu( ProcessGroup )
     
    local function MenuSmoke( MenuParam )
      self:E( MenuParam )
      local self = MenuParam.self
      local SmokeColor = MenuParam.SmokeColor
      self.SmokeColor = SmokeColor
      self:__Next( 1 )
    end
     
    --self.Menu = MENU_GROUP:New( ProcessGroup, "Target acquisition", MissionMenu )
    --self.MenuSmokeBlue   = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop blue smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.Blue } )
    --self.MenuSmokeGreen  = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop green smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.Green } )
    --self.MenuSmokeOrange = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop Orange smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.Orange } )
    --self.MenuSmokeRed    = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop Red smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.Red } )
    --self.MenuSmokeWhite  = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop White smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.White } )
  end
  
  --- StateMachine callback function
  -- @param #PROCESS_SMOKE_TARGETS self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_SMOKE_TARGETS:OnSmoking( ProcessUnit, Event, From, To )
    self:E( { Event, From, To, ProcessUnit.UnitName} )
    
    self.TargetSetUnit:ForEachUnit(
      --- @param Unit#UNIT SmokeUnit
      function( SmokeUnit )
        if math.random( 1, ( 100 * self.TargetSetUnit:Count() ) / 4 ) <= 100 then
          SCHEDULER:New( self,
            function()
              if SmokeUnit:IsAlive() then
                SmokeUnit:Smoke( self.SmokeColor, 150 )
              end
            end, {}, math.random( 10, 60 ) 
          )
        end
      end
    )
    
  end
  
end