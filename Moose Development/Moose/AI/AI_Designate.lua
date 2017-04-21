--- **AI (Release 2.1)** -- Management of target designation.
--
-- --![Banner Image](..\Presentations\DESIGNATE\Dia1.JPG)
--
-- ===
--
-- @module AI_Designate


do -- AI_DESIGNATE

  --- @type AI_DESIGNATE
  -- @extends Core.Fsm#FSM_PROCESS

  --- # AI_DESIGNATE class, extends @{Fsm#FSM}
  -- 
  -- AI_DESIGNATE is orchestrating the designation of potential targets executed by a Recce group, 
  -- and communicates these to a dedicated attacking group of players, 
  -- so that following a dynamically generated menu system, 
  -- each detected set of potential targets can be lased or smoked...
  -- 
  -- The Recce group is detecting as part of the DETECTION_ class continuously targets.
  -- Once targets have been detected, they will be reported. The AI_DESIGNATE object will fire the **Detect** event in this case!
  -- As part of the reporting, the following happens:
  -- 
  --   * A message is sent to each GROUP of the Attack SET_GROUP, containing the threat level and the target composition.
  --   * A menu is created and updated for each GROUP of the Attack SET_GROUP, containing the the treat level and the target composition.
  -- 
  -- One of the players in one of the Attack GROUPs, can then select a Target Set by selecting one of the menu options.
  -- Each menu option has two modes: 
  -- 
  --   * If the Target Set is not being designated, then the Designate menu for the target Set will provide options to Lase or Smoke the targets.
  --   * If the Target Set is being designated, then the Designate menu will provide an option to cancel the designation.
  -- 
  -- In this way, the AI can assist players to designate ground targets for a coordinated attack!
  -- 
  -- Have FUN!
  -- 
  -- ## 1. AI_DESIGNATE constructor
  --   
  --   * @{#AI_DESIGNATE.New}(): Creates a new AI_DESIGNATE object.
  -- 
  -- ## 2. AI_DESIGNATE is a FSM
  -- 
  -- ![Process](µ)
  -- 
  -- ### 2.1 AI_DESIGNATE States
  -- 
  --   * **Designating** ( Group ): The process is not started yet.
  -- 
  -- ### 2.2 AI_DESIGNATE Events
  -- 
  --   * **@{#AI_DESIGNATE.Detect}**: Detect targets.
  --   * **@{#AI_DESIGNATE.LaseOn}**: Lase the targets with the specified Index.
  --   * **@{#AI_DESIGNATE.LaseOff}**: Stop lasing the targets with the specified Index.
  --   * **@{#AI_DESIGNATE.Smoke}**: Smoke the targets with the specified Index.
  --   * **@{#AI_DESIGNATE.Status}**: Report designation status.
  -- 
  -- ## 3. Set laser codes
  -- 
  -- An array of laser codes can be provided, that will be used by the AI_DESIGNATE when lasing.
  -- The laser code is communicated by the Recce when it is lasing a larget.
  -- Note that the default laser code is 1113.
  -- Working known laser codes are: 1113,1462,1483,1537,1362,1214,1131,1182,1644,1614,1515,1411,1621,1138,1542,1678,1573,1314,1643,1257,1467,1375,1341,1275,1237
  -- 
  -- Use the method @{#AI_DESIGNATE.SetLaserCodes}() to set the possible laser codes to be selected from.
  -- One laser code can be given or an sequence of laser codes through an table...
  -- 
  --     AIDesignate:SetLaserCodes( 1214 )
  --     
  -- The above sets one laser code with the value 1214.
  -- 
  --     AIDesignate:SetLaserCodes( { 1214, 1131, 1614, 1138 } )
  --     
  -- The above sets a collection of possible laser codes that can be assigned. **Note the { } notation!**
  -- 
  -- 
  -- 
  -- @field #AI_DESIGNATE
  -- 
  AI_DESIGNATE = {
    ClassName = "AI_DESIGNATE",
  }

  --- AI_DESIGNATE Constructor. This class is an abstract class and should not be instantiated.
  -- @param #AI_DESIGNATE self
  -- @param Functional.Detection#DETECTION_BASE Detection
  -- @param Core.Set#SET_GROUP GroupSet The set of groups to designate for.
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:New( Detection, GroupSet )
  
    local self = BASE:Inherit( self, FSM:New() ) -- #AI_DESIGNATE
    self:F( { Detection } )
  
    self:SetStartState( "Designating" )
    self:AddTransition( "*", "Detect", "*" )
    
    --- Detect Handler OnBefore for AI_DESIGNATE
    -- @function [parent=#AI_DESIGNATE] OnBeforeDetect
    -- @param #AI_DESIGNATE self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Detect Handler OnAfter for AI_DESIGNATE
    -- @function [parent=#AI_DESIGNATE] OnAfterDetect
    -- @param #AI_DESIGNATE self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Detect Trigger for AI_DESIGNATE
    -- @function [parent=#AI_DESIGNATE] Detect
    -- @param #AI_DESIGNATE self
    
    --- Detect Asynchronous Trigger for AI_DESIGNATE
    -- @function [parent=#AI_DESIGNATE] __Detect
    -- @param #AI_DESIGNATE self
    -- @param #number Delay

    self:AddTransition( "*", "LaseOn", "Lasing" )
    
    --- LaseOn Handler OnBefore for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] OnBeforeLaseOn
    -- @param #AI_DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOn Handler OnAfter for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] OnAfterLaseOn
    -- @param #AI_DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOn Trigger for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] LaseOn
    -- @param #AI_DESIGNATE  self
    
    --- LaseOn Asynchronous Trigger for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] __LaseOn
    -- @param #AI_DESIGNATE  self
    -- @param #number Delay
    
    self:AddTransition( "Lasing", "Lasing", "Lasing" )
    
    
    self:AddTransition( "*", "LaseOff", "Designate" )
    
    --- LaseOff Handler OnBefore for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] OnBeforeLaseOff
    -- @param #AI_DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOff Handler OnAfter for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] OnAfterLaseOff
    -- @param #AI_DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOff Trigger for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] LaseOff
    -- @param #AI_DESIGNATE  self
    
    --- LaseOff Asynchronous Trigger for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] __LaseOff
    -- @param #AI_DESIGNATE  self
    -- @param #number Delay
    
    
    
    self:AddTransition( "*", "Smoke", "*" )
    
    --- Smoke Handler OnBefore for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] OnBeforeSmoke
    -- @param #AI_DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Smoke Handler OnAfter for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] OnAfterSmoke
    -- @param #AI_DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Smoke Trigger for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] Smoke
    -- @param #AI_DESIGNATE  self
    
    --- Smoke Asynchronous Trigger for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] __Smoke
    -- @param #AI_DESIGNATE  self
    -- @param #number Delay
    
    
    
    self:AddTransition( "*", "Status", "*" )
    
    --- Status Handler OnBefore for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] OnBeforeStatus
    -- @param #AI_DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Status Handler OnAfter for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] OnAfterStatus
    -- @param #AI_DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Status Trigger for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] Status
    -- @param #AI_DESIGNATE  self
    
    --- Status Asynchronous Trigger for AI_DESIGNATE 
    -- @function [parent=#AI_DESIGNATE ] __Status
    -- @param #AI_DESIGNATE  self
    -- @param #number Delay
    
    self.Detection = Detection
    self.GroupSet = GroupSet
    self.RecceSet = Detection:GetDetectionSetGroup()
    self.Spots = {}
    
    self:SetLaserCodes( 1688 )
    
    self.LaserCodesUsed = {}
    
    
    self.Detection:__Start( 2 )

    
    return self
  end
  

  --- Set an array of possible laser codes.
  -- Each new lase will select a code from this table.
  -- @param #AI_DESIGNATE self
  -- @param #list<#number> LaserCodes
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:SetLaserCodes( LaserCodes )

    self.LaserCodes = ( type( LaserCodes ) == "table" ) and LaserCodes or { LaserCodes }
    self:E(self.LaserCodes)
    
    self.LaserCodesUsed = {}

    return self
  end
  

  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterDetect()
    
    self:__Detect( -60 )
    
    self:SendStatus()
    self:SetDesignateMenu()      
  
    return self
  end

  --- Sends the status to the Attack Groups.
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:SendStatus()

    local DetectedReport = REPORT:New( "Targets ready to be designated:" )
    local DetectedItems = self.Detection:GetDetectedItems()
    
    for Index, DetectedItemData in pairs( DetectedItems ) do
      
      local Report = self.Detection:DetectedItemReportSummary( Index )
      DetectedReport:Add(" - " .. Report)
    end
    
    local RecceLeader = self.RecceSet:GetFirst() -- Wrapper.Group#GROUP

    self.GroupSet:ForEachGroup(
    
      --- @param Wrapper.Group#GROUP GroupReport
      function( AttackGroup )
        RecceLeader:MessageToGroup( DetectedReport:Text( "\n" ), 15, AttackGroup )
      end
    )
    
    return self
  end

  --- Sets the Designate Menu.
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:SetDesignateMenu()

    self.GroupSet:ForEachGroup(
    
      --- @param Wrapper.Group#GROUP GroupReport
      function( AttackGroup )
        local DesignateMenu = AttackGroup:GetState( AttackGroup, "DesignateMenu" ) -- Core.Menu#MENU_GROUP
        if DesignateMenu then
          DesignateMenu:Remove()
          DesignateMenu = nil
          self:E("Remove Menu")
        end
        DesignateMenu = MENU_GROUP:New( AttackGroup, "Designate Targets" )
        self:E(DesignateMenu)
        AttackGroup:SetState( AttackGroup, "DesignateMenu", DesignateMenu )
        
      
        local DetectedItems = self.Detection:GetDetectedItems()
        
        for Index, DetectedItemData in pairs( DetectedItems ) do
          
          local Report = self.Detection:DetectedItemReportSummary( Index )
          
          local DetectedMenu = MENU_GROUP:New(
            AttackGroup, 
            Report,
            DesignateMenu
          )
          
          MENU_GROUP_COMMAND:New(
            AttackGroup, 
            "Lase target 60 secs",
            DetectedMenu,
            self.MenuLaseOn,
            self,
            AttackGroup,
            Index,
            60
          )
          MENU_GROUP_COMMAND:New(
            AttackGroup, 
            "Lase target 120 secs",
            DetectedMenu,
            self.MenuLaseOn,
            self,
            AttackGroup,
            Index,
            120
          )
          MENU_GROUP_COMMAND:New(
            AttackGroup, 
            "Switch laser Off",
            DetectedMenu,
            self.MenuLaseOff,
            self,
            AttackGroup,
            Index
          )
           
          MENU_GROUP_COMMAND:New(
            AttackGroup, 
            "Smoke",
            DetectedMenu,
            self.MenuSmoke,
            self,
            AttackGroup,
            Index
          )
           
           
        end
      end
    )
    
    return self
  end
  
  --- 
  -- @param #AI_DESIGNATE self
  function AI_DESIGNATE:MenuSmoke( AttackGroup, Index )

    self:E("Designate through Smoke")

    self:__Smoke( 1, AttackGroup, Index )    
  end

  --- 
  -- @param #AI_DESIGNATE self
  function AI_DESIGNATE:MenuLaseOn( AttackGroup, Index, Duration )

    self:E("Designate through Lase")

    self:__LaseOn( 1, AttackGroup, Index, Duration ) 
  end

  --- 
  -- @param #AI_DESIGNATE self
  function AI_DESIGNATE:MenuLaseOff( AttackGroup, Index, Duration )

    self:E("Lasing off")

    self:__LaseOff( 1, AttackGroup, Index ) 
  end

  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterLaseOn( From, Event, To, AttackGroup, Index, Duration )
  
    self:__Lasing( -5, AttackGroup, Index, Duration )
  
  end
  

  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterLasing( From, Event, To, AttackGroup, Index, Duration )
  
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )

    local Targets = false

    TargetSetUnit:ForEachUnit(
      --- @param Wrapper.Unit#UNIT SmokeUnit
      function( TargetUnit )
        self:E("In procedure")
        --if math.random( 1, ( 100 * TargetSetUnit:Count() ) / 100 ) <= 100 then
        if TargetUnit:IsAlive() then
          local Spot = self.Spots[TargetUnit]
          if (not Spot) or ( Spot and Spot:IsLasing() == false ) then
            local NearestRecceGroup = self.RecceSet:FindNearestGroupFromPointVec2( TargetUnit:GetPointVec2() )
            if NearestRecceGroup then
              for UnitID, UnitData in pairs( NearestRecceGroup:GetUnits() or {} ) do
                local RecceUnit = UnitData -- Wrapper.Unit#UNIT
                Targets = true
                if RecceUnit:IsLasing() == false then
                  local LaserCode = self.LaserCodes[math.random(1, #self.LaserCodes)]
                  local Spot = RecceUnit:LaseUnit( TargetUnit, LaserCode, Duration )
                  self.Spots[TargetUnit] = Spot
                  RecceUnit:MessageToGroup( "Lasing " .. TargetUnit:GetTypeName() .. " for " .. Duration .. " seconds. Laser Code: " .. Spot.LaserCode, 15, AttackGroup )
                  break
                end
              end
            end
          else
            local RecceUnit = Spot.Recce
            RecceUnit:MessageToGroup( "Lasing " .. TargetUnit:GetTypeName() .. " for " .. Duration .. " seconds. Laser Code: " .. Spot.LaserCode, 15, AttackGroup )
          end
        else
          self.Spots[TargetUnit] = nil
        end
        --end
      end
    )

    if Targets == true then
      self:__Lasing( -30, AttackGroup, Index, Duration )
    else
      self:__LaseOff( -0.2, AttackGroup, Index  )
    end    

    self:SetDesignateMenu()

  end
    
  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterLaseOff( From, Event, To, AttackGroup, Index )
  
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
    
    local Spots = self.Spots
    
    for SpotID, SpotData in pairs( Spots ) do
      local Spot = SpotData -- Core.Spot#SPOT
      Spot.Recce:MessageToGroup( "Stopped lasing " .. Spot.Target:GetTypeName() .. ".", 15, AttackGroup )
      Spot:LaseOff()
    end
    
    Spots = nil
    self.Spots = {}

    self:SetDesignateMenu()
  end


  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterSmoke( From, Event, To, AttackGroup, Index )
  

    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
  
    TargetSetUnit:ForEachUnit(
      --- @param Wrapper.Unit#UNIT SmokeUnit
      function( SmokeUnit )
        self:E("In procedure")
        --if math.random( 1, ( 100 * TargetSetUnit:Count() ) / 100 ) <= 100 then
          SCHEDULER:New( self,
            function()
              if SmokeUnit:IsAlive() then
                SmokeUnit:Smoke( SMOKECOLOR.Red, 150 )
              end
            end, {}, math.random( 10, 60 ) 
          )
        --end
      end
    )
    

  end

end


