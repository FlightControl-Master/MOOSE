--- **Functional** -- Management of target **Designation**.
--
-- --![Banner Image](..\Presentations\DESIGNATE\Dia1.JPG)
--
-- ===
--
-- DESIGNATE is orchestrating the designation of potential targets executed by a Recce group, 
-- and communicates these to a dedicated attacking group of players, 
-- so that following a dynamically generated menu system, 
-- each detected set of potential targets can be lased or smoked...
-- 
-- Targets can be:
-- 
--   * **Lased** for a period of time.
--   * **Smoked**. Artillery or airplanes with Illuminatino ordonance need to be present. (WIP, but early demo ready.)
--   * **Illuminated** through an illumination bomb. Artillery or airplanes with Illuminatino ordonance need to be present. (WIP, but early demo ready.
-- 
-- ===
-- 
-- # **AUTHORS and CONTRIBUTIONS**
-- 
-- ### Contributions: 
-- 
--   * [**Ciribob**](https://forums.eagle.ru/member.php?u=112175): Showing the way how to lase targets + how laser codes work!!! Explained the autolase script.
--   * [**EasyEB**](https://forums.eagle.ru/member.php?u=112055): Ideas and Beta Testing
--   * [**Wingthor**](https://forums.eagle.ru/member.php?u=123698): Beta Testing
--   
-- 
-- ### Authors: 
-- 
--   * **FlightControl**: Design & Programming
-- 
-- @module Designate


do -- DESIGNATE

  --- @type DESIGNATE
  -- @extends Core.Fsm#FSM_PROCESS

  --- # DESIGNATE class, extends @{Fsm#FSM}
  -- 
  -- DESIGNATE is orchestrating the designation of potential targets executed by a Recce group, 
  -- and communicates these to a dedicated attacking group of players, 
  -- so that following a dynamically generated menu system, 
  -- each detected set of potential targets can be lased or smoked...
  -- 
  -- Targets can be:
  -- 
  --   * **Lased** for a period of time.
  --   * **Smoked**. Artillery or airplanes with Illuminatino ordonance need to be present. (WIP, but early demo ready.)
  --   * **Illuminated** through an illumination bomb. Artillery or airplanes with Illuminatino ordonance need to be present. (WIP, but early demo ready.
  -- 
  -- The following terminology is being used throughout this document:
  -- 
  --   * The **DesignateObject** is the object of the DESIGNATE class, which is this class explained in the document.
  --   * The **DetectionObject** is the object of a DETECTION_ class (DETECTION_TYPES, DETECTION_AREAS, DETECTION_UNITS), which is executing the detection and grouping of Targets into _DetectionItems_.
  --   * **DetectionItems** is the list of detected target groupings by the _DetectionObject_. Each _DetectionItem_ contains a _TargetSet_.
  --   * **DetectionItem** is one element of the _DetectionItems_ list, and contains a _TargetSet_.
  --   * The **TargetSet** is a SET_UNITS collection of _Targets_, that have been detected by the _DetectionObject_.
  --   * A **Target** is a detected UNIT object by the _DetectionObject_.
  --   * A **Threat Level** is a number from 0 to 10 that is calculated based on the threat of the Target in an Air to Ground battle scenario.
  --   * The **RecceSet** is a SET_GROUP collection that contains the **RecceGroups**.
  --   * A **RecceGroup** is a GROUP object containing the **Recces**.
  --   * A **Recce** is a UNIT object executing the reconnaissance as part the _DetectionObject_. A Recce can be of any UNIT type.
  --   * An **AttackGroup** is a GROUP object that contain _Players_.
  --   * A **Player** is an active CLIENT object containing a human player.
  --   * A **Designate Menu** is the menu that is dynamically created during the designation process for each _AttackGroup_.
  -- 
  -- The RecceSet is continuously detecting for potential Targets, executing its task as part of the DetectionObject.
  -- Once Targets have been detected, the DesignateObject will trigger the **Detect Event**.
  -- 
  -- As part of the Detect Event, the DetectionItems list is used by the DesignateObject to provide the Players with:
  -- 
  --   * The RecceGroups are reporting to each AttackGroup, sending **Messages** containing the Threat Level and the TargetSet composition.
  --   * **Menu options** are created and updated for each AttackGroup, containing the Threat Level and the TargetSet composition.
  -- 
  -- A Player can then select an action from the Designate Menu. 
  -- 
  -- **Note that each selected action will be executed for a TargetSet, thus the Target grouping done by the DetectionObject.**
  -- 
  -- Each **Menu Option** in the Designate Menu has two modes: 
  -- 
  --   1. If the TargetSet **is not being designated**, then the **Designate Menu** option for the target Set will provide options to **Lase** or **Smoke** the targets.
  --   2. If the Target Set **is being designated**, then the **Designate Menu** option will provide an option to stop or cancel the designation.
  -- 
  -- While designating, the RecceGroups will report any change in TargetSet composition or Target presence.
  -- 
  -- The following logic is executed when a TargetSet is selected to be *lased* from the Designation Menu:
  -- 
  --   * The RecceSet is searched for any Recce that is within *designation distance* from a Target in the TargetSet that is currently not being designated.
  --   * If there is a Recce found that is currently no designating a target, and is within designation distance from the Target, then that Target will be designated.
  --   * During designation, any Recce that does not have Line of Sight (LOS) and is not within disignation distance from the Target, will stop designating the Target, and a report is given.
  --   * When a Recce is designating a Target, and that Target is destroyed, then the Recce will stop designating the Target, and will report the event.
  --   * When a Recce is designating a Target, and that Recce is destroyed, then the Recce will be removed from the RecceSet and designation will stop without reporting.
  --   * When all RecceGroups are destroyed from the RecceSet, then the DesignationObject will stop functioning, and nothing will be reported.
  --   
  -- In this way, the DesignationObject assists players to designate ground targets for a coordinated attack!
  -- 
  -- Have FUN!
  -- 
  -- ## 1. DESIGNATE constructor
  --   
  --   * @{#DESIGNATE.New}(): Creates a new DESIGNATE object.
  -- 
  -- ## 2. DESIGNATE is a FSM
  -- 
  -- ![Process](..\Presentations\DESIGNATE\Dia2.JPG)
  -- 
  -- ### 2.1 DESIGNATE States
  -- 
  --   * **Designating** ( Group ): The process is not started yet.
  -- 
  -- ### 2.2 DESIGNATE Events
  -- 
  --   * **@{#DESIGNATE.Detect}**: Detect targets.
  --   * **@{#DESIGNATE.LaseOn}**: Lase the targets with the specified Index.
  --   * **@{#DESIGNATE.LaseOff}**: Stop lasing the targets with the specified Index.
  --   * **@{#DESIGNATE.Smoke}**: Smoke the targets with the specified Index.
  --   * **@{#DESIGNATE.Status}**: Report designation status.
  -- 
  -- ## 3. Laser codes
  -- 
  -- ### 3.1 Set possible laser codes
  -- 
  -- An array of laser codes can be provided, that will be used by the DESIGNATE when lasing.
  -- The laser code is communicated by the Recce when it is lasing a larget.
  -- Note that the default laser code is 1113.
  -- Working known laser codes are: 1113,1462,1483,1537,1362,1214,1131,1182,1644,1614,1515,1411,1621,1138,1542,1678,1573,1314,1643,1257,1467,1375,1341,1275,1237
  -- 
  -- Use the method @{#DESIGNATE.SetLaserCodes}() to set the possible laser codes to be selected from.
  -- One laser code can be given or an sequence of laser codes through an table...
  -- 
  --     Designate:SetLaserCodes( 1214 )
  --     
  -- The above sets one laser code with the value 1214.
  -- 
  --     Designate:SetLaserCodes( { 1214, 1131, 1614, 1138 } )
  --     
  -- The above sets a collection of possible laser codes that can be assigned. **Note the { } notation!**
  -- 
  -- ### 3.2 Auto generate laser codes
  -- 
  -- Use the method @{#DESIGNATE.GenerateLaserCodes}() to generate all possible laser codes. Logic implemented and advised by Ciribob!
  -- 
  -- ## 4. Autolase to automatically lase detected targets.
  -- 
  -- DetectionItems can be auto lased once detected by Recces. As such, there is almost no action required from the Players using the Designate Menu.
  -- The **auto lase** function can be activated through the Designation Menu.
  -- Use the method @{#DESIGNATE.SetAutoLase}() to activate or deactivate the auto lase function programmatically.
  -- Note that autolase will automatically activate lasing for ALL DetectedItems. Individual items can be switched-off if required using the Designation Menu.
  -- 
  --     Designate:SetAutoLase( true )
  -- 
  -- Activate the auto lasing.
  -- 
  -- ## 5. Target prioritization on threat level
  -- 
  -- Targets can be detected of different types in one DetectionItem. Depending on the type of the Target, a different threat level applies in an Air to Ground combat context.
  -- SAMs are of a higher threat than normal tanks. So, if the Target type was recognized, the Recces will select those targets that form the biggest threat first,
  -- and will continue this until the remaining vehicles with the lowest threat have been reached.
  -- 
  -- This threat level prioritization can be activated using the method @{#DESIGNATE.SetThreatLevelPrioritization}().
  -- If not activated, Targets will be selected in a random order, but most like those first which are the closest to the Recce marking the Target.
  -- 
  --     Designate:SetThreatLevelPrioritization( true )
  --     
  -- The example will activate the threat level prioritization for this the Designate object. Threats will be marked based on the threat level of the Target.
  -- 
  -- ## 6. Status Report
  -- 
  -- A status report is available that displays the current Targets detected, grouped per DetectionItem, and a list of which Targets are currently being marked.
  -- 
  --   * The status report can be shown by selecting "Status" -> "Report Status" from the Designation menu .
  --   * The status report can be automatically flashed by selecting "Status" -> "Flash Status On".
  --   * The automatic flashing of the status report can be deactivated by selecting "Status" -> "Flash Status Off".
  --   * The flashing of the status menu is disabled by default.
  --   * The method @{#DESIGNATE.FlashStatusMenu}() can be used to enable or disable to flashing of the status menu.
  --   
  --     Designate:FlashStatusMenu( true )
  --     
  -- The example will activate the flashing of the status menu for this Designate object.
  -- 
  -- @field #DESIGNATE
  -- 
  DESIGNATE = {
    ClassName = "DESIGNATE",
  }

  --- DESIGNATE Constructor. This class is an abstract class and should not be instantiated.
  -- @param #DESIGNATE self
  -- @param Tasking.CommandCenter#COMMANDCENTER CC
  -- @param Functional.Detection#DETECTION_BASE Detection
  -- @param Core.Set#SET_GROUP AttackSet The Attack collection of GROUP objects to designate and report for.
  -- @return #DESIGNATE
  function DESIGNATE:New( CC, Detection, AttackSet )
  
    local self = BASE:Inherit( self, FSM:New() ) -- #DESIGNATE
    self:F( { Detection } )
  
    self:SetStartState( "Designating" )
    
    self:AddTransition( "*", "Detect", "*" )
    --- Detect Handler OnBefore for DESIGNATE
    -- @function [parent=#DESIGNATE] OnBeforeDetect
    -- @param #DESIGNATE self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Detect Handler OnAfter for DESIGNATE
    -- @function [parent=#DESIGNATE] OnAfterDetect
    -- @param #DESIGNATE self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Detect Trigger for DESIGNATE
    -- @function [parent=#DESIGNATE] Detect
    -- @param #DESIGNATE self
    
    --- Detect Asynchronous Trigger for DESIGNATE
    -- @function [parent=#DESIGNATE] __Detect
    -- @param #DESIGNATE self
    -- @param #number Delay
    
    self:AddTransition( "*", "LaseOn", "Lasing" )
    --- LaseOn Handler OnBefore for DESIGNATE 
    -- @function [parent=#DESIGNATE ] OnBeforeLaseOn
    -- @param #DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOn Handler OnAfter for DESIGNATE 
    -- @function [parent=#DESIGNATE ] OnAfterLaseOn
    -- @param #DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOn Trigger for DESIGNATE 
    -- @function [parent=#DESIGNATE ] LaseOn
    -- @param #DESIGNATE  self
    
    --- LaseOn Asynchronous Trigger for DESIGNATE 
    -- @function [parent=#DESIGNATE ] __LaseOn
    -- @param #DESIGNATE  self
    -- @param #number Delay
    
    self:AddTransition( "Lasing", "Lasing", "Lasing" )
    
    self:AddTransition( "*", "LaseOff", "Designate" )
    --- LaseOff Handler OnBefore for DESIGNATE 
    -- @function [parent=#DESIGNATE ] OnBeforeLaseOff
    -- @param #DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOff Handler OnAfter for DESIGNATE 
    -- @function [parent=#DESIGNATE ] OnAfterLaseOff
    -- @param #DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOff Trigger for DESIGNATE 
    -- @function [parent=#DESIGNATE ] LaseOff
    -- @param #DESIGNATE  self
    
    --- LaseOff Asynchronous Trigger for DESIGNATE 
    -- @function [parent=#DESIGNATE ] __LaseOff
    -- @param #DESIGNATE  self
    -- @param #number Delay
    
    self:AddTransition( "*", "Smoke", "*" )
    --- Smoke Handler OnBefore for DESIGNATE 
    -- @function [parent=#DESIGNATE ] OnBeforeSmoke
    -- @param #DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Smoke Handler OnAfter for DESIGNATE 
    -- @function [parent=#DESIGNATE ] OnAfterSmoke
    -- @param #DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Smoke Trigger for DESIGNATE 
    -- @function [parent=#DESIGNATE ] Smoke
    -- @param #DESIGNATE  self
    
    --- Smoke Asynchronous Trigger for DESIGNATE 
    -- @function [parent=#DESIGNATE ] __Smoke
    -- @param #DESIGNATE  self
    -- @param #number Delay
    
    self:AddTransition( "*", "Illuminate", "*" )
    --- Illuminate Handler OnBefore for DESIGNATE
    -- @function [parent=#DESIGNATE] OnBeforeIlluminate
    -- @param #DESIGNATE self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Illuminate Handler OnAfter for DESIGNATE
    -- @function [parent=#DESIGNATE] OnAfterIlluminate
    -- @param #DESIGNATE self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Illuminate Trigger for DESIGNATE
    -- @function [parent=#DESIGNATE] Illuminate
    -- @param #DESIGNATE self
    
    --- Illuminate Asynchronous Trigger for DESIGNATE
    -- @function [parent=#DESIGNATE] __Illuminate
    -- @param #DESIGNATE self
    -- @param #number Delay

    self:AddTransition( "*", "Done", "*" )
    
    self:AddTransition( "*", "Status", "*" )
    --- Status Handler OnBefore for DESIGNATE 
    -- @function [parent=#DESIGNATE ] OnBeforeStatus
    -- @param #DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Status Handler OnAfter for DESIGNATE 
    -- @function [parent=#DESIGNATE ] OnAfterStatus
    -- @param #DESIGNATE  self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Status Trigger for DESIGNATE 
    -- @function [parent=#DESIGNATE ] Status
    -- @param #DESIGNATE  self
    
    --- Status Asynchronous Trigger for DESIGNATE 
    -- @function [parent=#DESIGNATE ] __Status
    -- @param #DESIGNATE  self
    -- @param #number Delay
    
    self.CC = CC
    self.Detection = Detection
    self.AttackSet = AttackSet
    self.RecceSet = Detection:GetDetectionSetGroup()
    self.Recces = {}
    self.Designating = {}
    
    self.LaseDuration = 60
    
    self:SetFlashStatusMenu( false )
    self:SetDesignateMenu()
    
    self:SetLaserCodes( 1688 ) -- set self.LaserCodes
    self:SetAutoLase( false ) -- set self.Autolase
    
    self:SetThreatLevelPrioritization( false ) -- self.ThreatLevelPrioritization, default is threat level priorization off
    
    self.LaserCodesUsed = {}
    
    
    self.Detection:__Start( 2 )
    
    return self
  end

  --- Set the flashing of the status menu.
  -- @param #DESIGNATE self
  -- @param #boolean FlashMenu true: the status menu will be flashed every detection run; false: no flashing of the menu.
  -- @return #DESIGNATE
  function DESIGNATE:SetFlashStatusMenu( FlashMenu ) --R2.1

    self.FlashStatusMenu = {}

    self.AttackSet:ForEachGroup(
    
      --- @param Wrapper.Group#GROUP GroupReport
      function( AttackGroup )
        self.FlashStatusMenu[AttackGroup] = FlashMenu
      end
    )

    return self
  end


  --- Set an array of possible laser codes.
  -- Each new lase will select a code from this table.
  -- @param #DESIGNATE self
  -- @param #list<#number> LaserCodes
  -- @return #DESIGNATE
  function DESIGNATE:SetLaserCodes( LaserCodes ) --R2.1

    self.LaserCodes = ( type( LaserCodes ) == "table" ) and LaserCodes or { LaserCodes }
    self:E(self.LaserCodes)
    
    self.LaserCodesUsed = {}

    return self
  end
  
  --- Generate an array of possible laser codes.
  -- Each new lase will select a code from this table.
  -- The entered value can range from 1111 - 1788,
  -- -- but the first digit of the series must be a 1 or 2
  -- -- and the last three digits must be between 1 and 8.
  --  The range used to be bugged so its not 1 - 8 but 0 - 7.
  -- function below will use the range 1-7 just in case
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:GenerateLaserCodes() --R2.1

    self.LaserCodes = {}
    
    local function containsDigit(_number, _numberToFind)

      local _thisNumber = _number
      local _thisDigit = 0
  
      while _thisNumber ~= 0 do
        _thisDigit = _thisNumber % 10
        _thisNumber = math.floor(_thisNumber / 10)
        if _thisDigit == _numberToFind then
          return true
        end
      end
  
      return false
    end

    -- generate list of laser codes
    local _code = 1111
    local _count = 1
    while _code < 1777 and _count < 30 do
      while true do
        _code = _code + 1
        if not containsDigit(_code, 8)
       and not containsDigit(_code, 9)
       and not containsDigit(_code, 0) then
          self:T(_code)            
          table.insert( self.LaserCodes, _code )
          break
        end
      end
      _count = _count + 1
    end

    self.LaserCodesUsed = {}

    return self
  end
  
  
  
  --- Set auto lase.
  -- Auto lase will start lasing targets immediately when these are in range.
  -- @param #DESIGNATE self
  -- @param #boolean AutoLase
  -- @return #DESIGNATE
  function DESIGNATE:SetAutoLase( AutoLase ) --R2.1

    self.AutoLase = AutoLase
    
    local AutoLaseOnOff = ( AutoLase == true ) and "On" or "Off"

    local CC = self.CC:GetPositionable()
    
    if CC then
      CC:MessageToSetGroup( "Auto Lase " .. AutoLaseOnOff .. ".", 15, self.AttackSet )
    end

    self:ActivateAutoLase()
    self:SetDesignateMenu()      

    return self
  end

  --- Set priorization of Targets based on the **Threat Level of the Target** in an Air to Ground context.
  -- @param #DESIGNATE self
  -- @param #boolean Prioritize
  -- @return #DESIGNATE
  function DESIGNATE:SetThreatLevelPrioritization( Prioritize ) --R2.1

    self.ThreatLevelPrioritization = Prioritize
    
    return self
  end
  
  

  --- 
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterDetect()
    
    self:__Detect( -60 )
    
    self:ActivateAutoLase()
    self:SendStatus()
    self:SetDesignateMenu()      
  
    return self
  end

  --- Sends the status to the Attack Groups.
  -- @param #DESIGNATE self
  -- @param Wrapper.Group#GROUP AttackGroup
  -- @param #number Duration The time in seconds the report should be visible.
  -- @return #DESIGNATE
  function DESIGNATE:SendStatus( MenuAttackGroup, Duration )

    Duration = Duration or 10
    
    self.AttackSet:ForEachGroup(
    
      --- @param Wrapper.Group#GROUP GroupReport
      function( AttackGroup )
      
        if self.FlashStatusMenu[AttackGroup] or ( MenuAttackGroup and ( AttackGroup:GetName() == MenuAttackGroup:GetName() ) ) then

          local DetectedReport = REPORT:New( "Targets designated:\n" )
          local DetectedItems = self.Detection:GetDetectedItems()
          
          for Index, DetectedItemData in pairs( DetectedItems ) do
            
            local Report = self.Detection:DetectedItemReportSummary( Index, AttackGroup )
            DetectedReport:Add(" - " .. Report)
          end
          
          local CC = self.CC:GetPositionable()
      
          CC:MessageToGroup( DetectedReport:Text( "\n" ), Duration, AttackGroup )
          
          local DesignationReport = REPORT:New( "Targets marked:\n" )
      
          self.RecceSet:ForEachGroup(
            function( RecceGroup )
              local RecceUnits = RecceGroup:GetUnits()
              for UnitID, RecceData in pairs( RecceUnits ) do
                local Recce = RecceData -- Wrapper.Unit#UNIT
                if Recce:IsLasing() then
                  DesignationReport:Add( " - " .. Recce:GetMessageText( "Marking " .. Recce:GetSpot().Target:GetTypeName() .. " with laser " .. Recce:GetSpot().LaserCode .. "." ) )
                end
              end
            end
          )
      
          CC:MessageToGroup( DesignationReport:Text(), Duration, AttackGroup )
        end
      end
    )
    
    return self
  end

  --- Coordinates the Auto Lase.
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:ActivateAutoLase()

    self.AttackSet:Flush()

    self.AttackSet:ForEachGroup(
    
      --- @param Wrapper.Group#GROUP GroupReport
      function( AttackGroup )

        local DetectedItems = self.Detection:GetDetectedItems()
        
        for Index, DetectedItemData in pairs( DetectedItems ) do
          if self.AutoLase then
            if not self.Designating[Index] then
              self:LaseOn( Index, self.LaseDuration ) 
            end
          end
        end
      end
    )
    
    return self
  end

  --- Sets the Designate Menu.
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:SetDesignateMenu()

    self.AttackSet:Flush()

    self.AttackSet:ForEachGroup(
    
      --- @param Wrapper.Group#GROUP GroupReport
      function( AttackGroup )
        local DesignateMenu = AttackGroup:GetState( AttackGroup, "DesignateMenu" ) -- Core.Menu#MENU_GROUP
        if DesignateMenu then
          DesignateMenu:Remove()
          DesignateMenu = nil
          self:E("Remove Menu")
        end
        DesignateMenu = MENU_GROUP:New( AttackGroup, "Designate" )
        self:E(DesignateMenu)
        AttackGroup:SetState( AttackGroup, "DesignateMenu", DesignateMenu )
        
        -- Set Menu option for auto lase

        if self.AutoLase then        
          MENU_GROUP_COMMAND:New( AttackGroup, "Auto Lase Off", DesignateMenu, self.MenuAutoLase, self, false )
        else
          MENU_GROUP_COMMAND:New( AttackGroup, "Auto Lase On", DesignateMenu, self.MenuAutoLase, self, true )
        end        

        local StatusMenu = MENU_GROUP:New( AttackGroup, "Status", DesignateMenu )
        MENU_GROUP_COMMAND:New( AttackGroup, "Report Status 15s", StatusMenu, self.MenuStatus, self, AttackGroup, 15 )
        MENU_GROUP_COMMAND:New( AttackGroup, "Report Status 30s", StatusMenu, self.MenuStatus, self, AttackGroup, 30 )
        MENU_GROUP_COMMAND:New( AttackGroup, "Report Status 60s", StatusMenu, self.MenuStatus, self, AttackGroup, 60 )
        
        if self.FlashStatusMenu[AttackGroup] then
          MENU_GROUP_COMMAND:New( AttackGroup, "Flash Status Report Off", StatusMenu, self.MenuFlashStatus, self, AttackGroup, false )
        else
           MENU_GROUP_COMMAND:New( AttackGroup, "Flash Status Report On", StatusMenu, self.MenuFlashStatus, self, AttackGroup, true )
        end        
      
        local DetectedItems = self.Detection:GetDetectedItems()
        
        for Index, DetectedItemData in pairs( DetectedItems ) do
          
          local Report = self.Detection:DetectedItemMenu( Index, AttackGroup )
          
          if not self.Designating[Index] then
            local DetectedMenu = MENU_GROUP:New( AttackGroup, Report, DesignateMenu )
            MENU_GROUP_COMMAND:New( AttackGroup, "Lase target 60 secs", DetectedMenu, self.MenuLaseOn, self, Index, 60 )
            MENU_GROUP_COMMAND:New( AttackGroup, "Lase target 120 secs", DetectedMenu, self.MenuLaseOn, self, Index, 120 )
            MENU_GROUP_COMMAND:New( AttackGroup, "Smoke red", DetectedMenu, self.MenuSmoke, self, Index, SMOKECOLOR.Red )
            MENU_GROUP_COMMAND:New( AttackGroup, "Smoke blue", DetectedMenu, self.MenuSmoke, self, Index, SMOKECOLOR.Blue )
            MENU_GROUP_COMMAND:New( AttackGroup, "Smoke green", DetectedMenu, self.MenuSmoke, self, Index, SMOKECOLOR.Green )
            MENU_GROUP_COMMAND:New( AttackGroup, "Smoke white", DetectedMenu, self.MenuSmoke, self, Index, SMOKECOLOR.White )
            MENU_GROUP_COMMAND:New( AttackGroup, "Smoke orange", DetectedMenu, self.MenuSmoke, self, Index, SMOKECOLOR.Orange )
            MENU_GROUP_COMMAND:New( AttackGroup, "Illuminate", DetectedMenu, self.MenuIlluminate, self, Index )
          else
            if self.Designating[Index] == "Laser" then
              Report = "Lasing " .. Report
            elseif self.Designating[Index] == "Smoke" then
              Report = "Smoking " .. Report
            elseif self.Designating[Index] == "Illuminate" then
              Report = "Illuminating " .. Report
            end
            local DetectedMenu = MENU_GROUP:New( AttackGroup, Report, DesignateMenu )
            if self.Designating[Index] == "Laser" then
              MENU_GROUP_COMMAND:New( AttackGroup, "Stop lasing", DetectedMenu, self.MenuLaseOff, self, Index )
            else
            end
          end
        end
      end
    )
    
    return self
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuStatus( AttackGroup, Duration )

    self:E("Status")

    self:SendStatus( AttackGroup, Duration )  
  end
  
  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuFlashStatus( AttackGroup, Flash )

    self:E("Flash Status")

    self.FlashStatusMenu[AttackGroup] = Flash
    self:SetDesignateMenu()
  end

  
  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuAutoLase( AutoLase )

    self:E("AutoLase")

    self:SetAutoLase( AutoLase )
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuSmoke( Index, Color )

    self:E("Designate through Smoke")

    self.Designating[Index] = "Smoke"
    self:__Smoke( 1, Index, Color )    
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuIlluminate( Index )

    self:E("Designate through Illumination")

    self.Designating[Index] = "Illuminate"
    
    self:__Illuminate( 1, Index )
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuLaseOn( Index, Duration )

    self:E("Designate through Lase")
    
    self:__LaseOn( 1, Index, Duration ) 
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuLaseOff( Index, Duration )

    self:E("Lasing off")

    self.Designating[Index] = nil
    self:__LaseOff( 1, Index ) 
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:onafterLaseOn( From, Event, To, Index, Duration )
  
    self.Designating[Index] = "Laser"
    self:Lasing( Index, Duration )
  end
  

  --- 
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterLasing( From, Event, To, Index, Duration )
  
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
    
    TargetSetUnit:Flush()

    for TargetUnit, RecceData in pairs( self.Recces ) do
      local Recce = RecceData -- Wrapper.Unit#UNIT
      if not Recce:IsLasing() then
        local LaserCode = Recce:GetLaserCode() --(Not deleted when stopping with lasing).
        self.LaserCodesUsed[LaserCode] = nil
        self.Recces[TargetUnit] = nil
      end
    end

    TargetSetUnit:ForEachUnitPerThreatLevel( 10, 0,
      --- @param Wrapper.Unit#UNIT SmokeUnit
      function( TargetUnit )
        self:E("In procedure")
        if TargetUnit:IsAlive() then
          local Recce = self.Recces[TargetUnit]
          if not Recce then
            for RecceGroupID, RecceGroup in pairs( self.RecceSet:GetSet() ) do
              for UnitID, UnitData in pairs( RecceGroup:GetUnits() or {} ) do
                local RecceUnit = UnitData -- Wrapper.Unit#UNIT
                if RecceUnit:IsLasing() == false then
                  if RecceUnit:IsDetected( TargetUnit ) and RecceUnit:IsLOS( TargetUnit ) then
                    local LaserCodeIndex = math.random( 1, #self.LaserCodes )
                    local LaserCode = self.LaserCodes[LaserCodeIndex]
                    if not self.LaserCodesUsed[LaserCode] then
                      self.LaserCodesUsed[LaserCode] = LaserCodeIndex
                      local Spot = RecceUnit:LaseUnit( TargetUnit, LaserCode, Duration )
                      local AttackSet = self.AttackSet
                      function Spot:OnAfterDestroyed( From, Event, To )
                        self:E( "Destroyed Message" )
                        self.Recce:MessageToSetGroup( "Target " .. TargetUnit:GetTypeName() .. " destroyed. " .. TargetSetUnit:Count() .. " targets left.", 5, AttackSet )
                      end
                      self.Recces[TargetUnit] = RecceUnit
                      RecceUnit:MessageToSetGroup( "Marking " .. TargetUnit:GetTypeName() .. " with laser " .. RecceUnit:GetSpot().LaserCode .. " for " .. Duration .. "s.", 5, self.AttackSet )
                      break
                    end
                  else
                    RecceUnit:MessageToSetGroup( "Can't mark " .. TargetUnit:GetTypeName(), 5, self.AttackSet )
                  end
                else
                  -- The Recce is lasing, but the Target is not detected or within LOS. So stop lasing and send a report.
                  if not RecceUnit:IsDetected( TargetUnit ) or not RecceUnit:IsLOS( TargetUnit ) then
                    local Recce = self.Recces[TargetUnit] -- Wrapper.Unit#UNIT
                    if Recce then
                      Recce:LaseOff()
                      Recce:MessageToGroup( "Target " .. TargetUnit:GetTypeName() "out of LOS. Cancelling lase!", 5, self.AttackSet )
                    end
                  end  
                end
              end
            end
          else
            Recce:MessageToSetGroup( "Marking " .. TargetUnit:GetTypeName() .. " with laser " .. Recce.LaserCode .. ".", 5, self.AttackSet )
          end
        end
      end
    )

    self:__Lasing( 15, Index, Duration )
    
    self:SetDesignateMenu()

  end
    
  --- 
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterLaseOff( From, Event, To, Index )
  
    local CC = self.CC:GetPositionable()
    
    if CC then 
      CC:MessageToSetGroup( "Stopped lasing.", 5, self.AttackSet )
    end
    
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
    
    local Recces = self.Recces
    
    for TargetID, RecceData in pairs( Recces ) do
      local Recce = RecceData -- Wrapper.Unit#UNIT
      Recce:MessageToSetGroup( "Stopped lasing " .. Recce:GetSpot().Target:GetTypeName() .. ".", 5, self.AttackSet )
      Recce:LaseOff()
    end
    
    Recces = nil
    self.Recces = {}
    self.LaserCodesUsed = {}

    self:SetDesignateMenu()
  end


  --- 
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterSmoke( From, Event, To, Index, Color )
  
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
    local TargetSetUnitCount = TargetSetUnit:Count()
  
    TargetSetUnit:ForEachUnit(
      --- @param Wrapper.Unit#UNIT SmokeUnit
      function( SmokeUnit )
        self:E("In procedure")
        if math.random( 1, TargetSetUnitCount ) == math.random( 1, TargetSetUnitCount ) then
          local RecceGroup = self.RecceSet:FindNearestGroupFromPointVec2(SmokeUnit:GetPointVec2())
          local RecceUnit = RecceGroup:GetUnit( 1 )
          if RecceUnit then
            RecceUnit:MessageToSetGroup( "Smoking " .. SmokeUnit:GetTypeName() .. ".", 5, self.AttackSet )
            SCHEDULER:New( self,
              function()
                if SmokeUnit:IsAlive() then
                  SmokeUnit:Smoke( Color, 150 )
                end
              self:Done( Index )
              end, {}, math.random( 5, 20 ) 
            )
          end
        end
      end
    )
    

  end

  --- Illuminating
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterIlluminate( From, Event, To, Index )
  
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
    local TargetUnit = TargetSetUnit:GetFirst()
  
    if TargetUnit then
      local RecceGroup = self.RecceSet:FindNearestGroupFromPointVec2(TargetUnit:GetPointVec2())
      local RecceUnit = RecceGroup:GetUnit( 1 )
      if RecceUnit then
        RecceUnit:MessageToSetGroup( "Illuminating " .. TargetUnit:GetTypeName() .. ".", 5, self.AttackSet )
        SCHEDULER:New( self,
          function()
            if TargetUnit:IsAlive() then
              TargetUnit:GetPointVec3():AddY(300):IlluminationBomb()
            end
          self:Done( Index )
          end, {}, math.random( 5, 20 ) 
        )
      end
    end
  end

  --- Done
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterDone( From, Event, To, Index )

    self.Designating[Index] = nil
    self:SetDesignateMenu()
  end

end

-- Help from Ciribob

