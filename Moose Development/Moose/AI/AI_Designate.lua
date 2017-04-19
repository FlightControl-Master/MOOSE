--- **AI (Release 2.1)** -- Management of target designation.
--
-- --![Banner Image](..\Presentations\AI_DESIGNATE\CARGO.JPG)
--
-- ===
--
-- @module AI_Designate


do -- AI_DESIGNATE

  --- @type AI_DESIGNATE
  -- @extends Core.Fsm#FSM_PROCESS

  ---
  -- 
  -- @field #AI_DESIGNATE AI_DESIGNATE
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
    self:AddTransition( "*", "LaseOn", "*" )
    self:AddTransition( "*", "LaseOff", "*" )
    self:AddTransition( "*", "Smoke", "*" )
    self:AddTransition( "*", "Status", "*" )
  
    self.Detection = Detection
    self.GroupSet = GroupSet
    self.RecceSet = Detection:GetDetectionSetGroup()
    self.Spots = {}
    
    self.Detection:__Start( 2 )

    
    return self
  end

  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterDetect()
    
    self:__Detect( -60 )
    
    self.GroupSet:ForEachGroup(
    
      --- @param Wrapper.Group#GROUP GroupReport
      function( GroupReport )
      
        self:E(GroupReport:GetName())
      
        local DesignateMenu = GroupReport:GetState( GroupReport, "DesignateMenu" ) -- Core.Menu#MENU_GROUP
        if DesignateMenu then
          DesignateMenu:Remove()
          DesignateMenu = nil
          self:E("Remove Menu")
        end
        DesignateMenu = MENU_GROUP:New( GroupReport, "Designate Targets" )
        self:E(DesignateMenu)
        GroupReport:SetState( GroupReport, "DesignateMenu", DesignateMenu )
        
      
        local DetectedItems = self.Detection:GetDetectedItems()
        
        for Index, DetectedItemData in pairs( DetectedItems ) do
          
          local DetectedReport = self.Detection:DetectedItemReportSummary( Index )
          
          GroupReport:MessageToAll( DetectedReport, 15, "Detected" )
          
          local DetectedMenu = MENU_GROUP:New(
            GroupReport, 
            DetectedReport,
            DesignateMenu
          )
          
          if self.Spots[Index] then
          
            MENU_GROUP_COMMAND:New(
              GroupReport, 
              "Switch laser Off",
              DetectedMenu,
              self.MenuLaseOff,
              self,
              Index
            )
          else
            MENU_GROUP_COMMAND:New(
              GroupReport, 
              "Lase target 60 secs",
              DetectedMenu,
              self.MenuLaseOn,
              self,
              Index,
              60
            )
            MENU_GROUP_COMMAND:New(
              GroupReport, 
              "Lase target 120 secs",
              DetectedMenu,
              self.MenuLaseOn,
              self,
              Index,
              120
            )
          end
           
          MENU_GROUP_COMMAND:New(
            GroupReport, 
            "Smoke",
            DetectedMenu,
            self.MenuSmoke,
            self,
            Index
          )
           
           
        end
      end
    )
  
    return self
  end
  
  --- 
  -- @param #AI_DESIGNATE self
  function AI_DESIGNATE:MenuSmoke( Index )

    self:E("Designate through Smoke")

    self:__Smoke( 1, Index )    
  end

  --- 
  -- @param #AI_DESIGNATE self
  function AI_DESIGNATE:MenuLaseOn( Index, Duration )

    self:E("Designate through Lase")

    self:__LaseOn( 1, Index, Duration ) 
  end

  --- 
  -- @param #AI_DESIGNATE self
  function AI_DESIGNATE:MenuLaseOff( Index, Duration )

    self:E("Lasing off")

    self:__LaseOff( 1, Index ) 
  end

  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterLaseOn( From, Event, To, Index, Duration )
  
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
  
    TargetSetUnit:ForEachUnit(
      --- @param Wrapper.Unit#UNIT SmokeUnit
      function( SmokeUnit )
        self:E("In procedure")
        --if math.random( 1, ( 100 * TargetSetUnit:Count() ) / 100 ) <= 100 then
        if SmokeUnit:IsAlive() then
          local NearestRecceGroup = self.RecceSet:FindNearestGroupFromPointVec2(SmokeUnit:GetPointVec2())
          local NearestRecceUnit = NearestRecceGroup:GetUnit(1)
          self:E( { NearestRecceUnit = NearestRecceUnit  } )
          self.Spots[Index] = NearestRecceUnit:LaseUnitOn( SmokeUnit, nil, Duration )
        end
        --end
      end
    )
  end

  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterLaseOff( From, Event, To, Index )
  
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
    
    self.Spots[Index]:LaseOff()
    self.Spots[Index] = nil

  end


  --- 
  -- @param #AI_DESIGNATE self
  -- @return #AI_DESIGNATE
  function AI_DESIGNATE:onafterSmoke( From, Event, To, Index )
  

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


