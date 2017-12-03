--- **Functional** -- Management of target **Designation**. Lase, smoke and illuminate targets.
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
  -- In order to prevent an overflow in the DesignateObject of detected targets, there is a maximum
  -- amount of DetectionItems that can be put in **scope** of the DesignateObject.
  -- We call this the **MaximumDesignations** term.
  -- 
  -- As part of the Detect Event, the DetectionItems list is used by the DesignateObject to provide the Players with:
  -- 
  --   * The RecceGroups are reporting to each AttackGroup, sending **Messages** containing the Threat Level and the TargetSet composition.
  --   * **Menu options** are created and updated for each AttackGroup, containing the Detection ID and the Coordinates.
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
  --   * **Designating** ( Group ): The designation process.
  -- 
  -- ### 2.2 DESIGNATE Events
  -- 
  --   * **@{#DESIGNATE.Detect}**: Detect targets.
  --   * **@{#DESIGNATE.LaseOn}**: Lase the targets with the specified Index.
  --   * **@{#DESIGNATE.LaseOff}**: Stop lasing the targets with the specified Index.
  --   * **@{#DESIGNATE.Smoke}**: Smoke the targets with the specified Index.
  --   * **@{#DESIGNATE.Status}**: Report designation status.
  -- 
  -- ## 3. Maximum Designations
  -- 
  -- In order to prevent an overflow of designations due to many Detected Targets, there is a 
  -- Maximum Designations scope that is set in the DesignationObject.
  -- 
  -- The method @{#DESIGNATE.SetMaximumDesignations}() will put a limit on the amount of designations put in scope of the DesignationObject.
  -- Using the menu system, the player can "forget" a designation, so that gradually a new designation can be put in scope when detected.
  -- 
  -- ## 4. Laser codes
  -- 
  -- ### 4.1. Set possible laser codes
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
  -- ### 4.2. Auto generate laser codes
  -- 
  -- Use the method @{#DESIGNATE.GenerateLaserCodes}() to generate all possible laser codes. Logic implemented and advised by Ciribob!
  -- 
  -- ### 4.3. Add specific lase codes to the lase menu
  -- 
  -- Certain plane types can only drop laser guided ordonnance when targets are lased with specific laser codes.
  -- The SU-25T needs targets to be lased using laser code 1113.
  -- The A-10A needs targets to be lased using laser code 1680.
  -- 
  -- The method @{#DESIGNATE.AddMenuLaserCode}() to allow a player to lase a target using a specific laser code.
  -- Remove such a lase menu option using @{#DESIGNATE.RemoveMenuLaserCode}().
  -- 
  -- ## 5. Autolase to automatically lase detected targets.
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
  -- ## 6. Target prioritization on threat level
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
  -- ## 6. Designate Menu Location for a Mission
  -- 
  -- You can make DESIGNATE work for a @{Mission#MISSION} object. In this way, the designate menu will not appear in the root of the radio menu, but in the menu of the Mission.
  -- Use the method @{#DESIGNATE.SetMission}() to set the @{Mission} object for the designate function.
  -- 
  -- ## 7. Status Report
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
  DESIGNATE = {
    ClassName = "DESIGNATE",
  }

  --- DESIGNATE Constructor. This class is an abstract class and should not be instantiated.
  -- @param #DESIGNATE self
  -- @param Tasking.CommandCenter#COMMANDCENTER CC
  -- @param Functional.Detection#DETECTION_BASE Detection
  -- @param Core.Set#SET_GROUP AttackSet The Attack collection of GROUP objects to designate and report for.
  -- @param Tasking.Mission#MISSION Mission (Optional) The Mission where the menu needs to be attached.
  -- @return #DESIGNATE
  function DESIGNATE:New( CC, Detection, AttackSet, Mission )
  
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
    self:SetDesignateName()
    
    self.LaseDuration = 60
    
    self:SetFlashStatusMenu( false )
    self:SetMission( Mission )
    
    self:SetLaserCodes( { 1688, 1130, 4785, 6547, 1465, 4578 } ) -- set self.LaserCodes
    self:SetAutoLase( false, false ) -- set self.Autolase and don't send message.
    
    self:SetThreatLevelPrioritization( false ) -- self.ThreatLevelPrioritization, default is threat level priorization off
    self:SetMaximumDesignations( 5 ) -- Sets the maximum designations. The default is 5 designations.
    self:SetMaximumDistanceDesignations( 12000 )  -- Sets the maximum distance on which designations can be accepted. The default is 8000 meters.
    self:SetMaximumMarkings( 2 ) -- Per target group, a maximum of 2 markings will be made by default.

    self:SetDesignateMenu()
    
    self.LaserCodesUsed = {}
    
    self.MenuLaserCodes = {} -- This map contains the laser codes that will be shown in the designate menu to lase with specific laser codes.
        
    self.Detection:__Start( 2 )
    
    self:__Detect( -15 )
    
    self.MarkScheduler = SCHEDULER:New( self )
    
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


  --- Set the maximum amount of designations.
  -- @param #DESIGNATE self
  -- @param #number MaximumDesignations
  -- @return #DESIGNATE
  function DESIGNATE:SetMaximumDesignations( MaximumDesignations )
    self.MaximumDesignations = MaximumDesignations
    return self
  end
  

  --- Set the maximum ground designation distance.
  -- @param #DESIGNATE self
  -- @param #number MaximumDistanceGroundDesignation Maximum ground designation distance in meters.
  -- @return #DESIGNATE
  function DESIGNATE:SetMaximumDistanceGroundDesignation( MaximumDistanceGroundDesignation )
    self.MaximumDistanceGroundDesignation = MaximumDistanceGroundDesignation
    return self
  end
  
  
  --- Set the maximum air designation distance.
  -- @param #DESIGNATE self
  -- @param #number MaximumDistanceAirDesignation Maximum air designation distance in meters.
  -- @return #DESIGNATE
  function DESIGNATE:SetMaximumDistanceAirDesignation( MaximumDistanceAirDesignation )
    self.MaximumDistanceAirDesignation = MaximumDistanceAirDesignation
    return self
  end
  
  
  --- Set the overall maximum distance when designations can be accepted.
  -- @param #DESIGNATE self
  -- @param #number MaximumDistanceDesignations Maximum distance in meters to accept designations.
  -- @return #DESIGNATE
  function DESIGNATE:SetMaximumDistanceDesignations( MaximumDistanceDesignations )
    self.MaximumDistanceDesignations = MaximumDistanceDesignations
    return self
  end
  
  
  --- Set the maximum amount of markings FACs will do, per designated target group.
  -- @param #DESIGNATE self
  -- @param #number MaximumMarkings Maximum markings FACs will do, per designated target group.
  -- @return #DESIGNATE
  function DESIGNATE:SetMaximumMarkings( MaximumMarkings )
    self.MaximumMarkings = MaximumMarkings
    return self
  end
  
  
  --- Set an array of possible laser codes.
  -- Each new lase will select a code from this table.
  -- @param #DESIGNATE self
  -- @param #list<#number> LaserCodes
  -- @return #DESIGNATE
  function DESIGNATE:SetLaserCodes( LaserCodes ) --R2.1

    self.LaserCodes = ( type( LaserCodes ) == "table" ) and LaserCodes or { LaserCodes }
    self:E( { LaserCodes = self.LaserCodes } )
    
    self.LaserCodesUsed = {}

    return self
  end
  

  --- Add a specific lase code to the designate lase menu to lase targets with a specific laser code.
  -- The MenuText will appear in the lase menu.
  -- @param #DESIGNATE self
  -- @param #number LaserCode The specific laser code to be added to the lase menu.
  -- @param #string MenuText The text to be shown to the player. If you specify a %d in the MenuText, the %d will be replaced with the LaserCode specified.
  -- @return #DESIGNATE
  -- @usage
  --   RecceDesignation:AddMenuLaserCode( 1113, "Lase with %d for Su-25T" )
  --   RecceDesignation:AddMenuLaserCode( 1680, "Lase with %d for A-10A" )
  -- 
  function DESIGNATE:AddMenuLaserCode( LaserCode, MenuText )

    self.MenuLaserCodes[LaserCode] = MenuText
    self:SetDesignateMenu()
    
    return self
  end
  
  
  --- Removes a specific lase code from the designate lase menu.
  -- @param #DESIGNATE self
  -- @param #number LaserCode The specific laser code that was set to be added to the lase menu.
  -- @return #DESIGNATE
  -- @usage
  --   RecceDesignation:RemoveMenuLaserCode( 1113 )
  --   
  function DESIGNATE:RemoveMenuLaserCode( LaserCode )

    self.MenuLaserCodes[LaserCode] = nil
    self:SetDesignateMenu()

    return self
  end
  
  
  

  --- Set the name of the designation. The name will appear in the menu.
  -- This method can be used to control different designations for different plane types.
  -- @param #DESIGNATE self
  -- @param #string DesignateName
  -- @return #DESIGNATE
  function DESIGNATE:SetDesignateName( DesignateName ) 

    self.DesignateName = "Designation" .. ( DesignateName and ( " for " .. DesignateName ) or "" )

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
  -- @param #boolean AutoLase (optional) true sets autolase on, false off. Default is off.
  -- @param #boolean Message (optional) true is send message, false or nil won't send a message. Default is no message sent.
  -- @return #DESIGNATE
  function DESIGNATE:SetAutoLase( AutoLase, Message )

    self.AutoLase = AutoLase or false
    
    if Message then
      local AutoLaseOnOff = ( self.AutoLase == true ) and "On" or "Off"
      local CC = self.CC:GetPositionable()
      if CC then
        CC:MessageToSetGroup( self.DesignateName .. ": Auto Lase " .. AutoLaseOnOff .. ".", 15, self.AttackSet )
      end
    end

    self:CoordinateLase()
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
  
  --- Set the MISSION object for which designate will function.
  -- When a MISSION object is assigned, the menu for the designation will be located at the Mission Menu.
  -- @param #DESIGNATE self
  -- @param Tasking.Mission#MISSION Mission The MISSION object.
  -- @return #DESIGNATE
  function DESIGNATE:SetMission( Mission ) --R2.2

    self.Mission = Mission

    return self
  end
  

  --- 
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterDetect()
    
    self:__Detect( -math.random( 60 ) )
    
    self:DesignationScope()
    self:CoordinateLase()
    self:SendStatus()
    self:SetDesignateMenu()      
  
    return self
  end


  --- Adapt the designation scope according the detected items.
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:DesignationScope()

    local DetectedItems = self.Detection:GetDetectedItems()
    
    local DetectedItemCount = 0
    
    for DesignateIndex, Designating in pairs( self.Designating ) do
      local DetectedItem = DetectedItems[DesignateIndex]
      if DetectedItem then
        -- Check LOS...
        local IsDetected = self.Detection:IsDetectedItemDetected( DetectedItem )
        self:F({IsDetected = IsDetected, DetectedItem })
        if IsDetected == false then
          self:F("Removing")
          -- This Detection is obsolete, remove from the designate scope
          self.Designating[DesignateIndex] = nil
          self.AttackSet:ForEachGroup(
            function( AttackGroup )
              if AttackGroup:IsAlive() then
                local DetectionText = self.Detection:DetectedItemReportSummary( DesignateIndex, AttackGroup ):Text( ", " )
                self.CC:GetPositionable():MessageToGroup( "Targets out of LOS\n" .. DetectionText, 10, AttackGroup, self.DesignateName )
              end
            end
          )
        else
          DetectedItemCount = DetectedItemCount + 1
        end
      else
        -- This Detection is obsolete, remove from the designate scope
        self.Designating[DesignateIndex] = nil
      end
    end
    
    if DetectedItemCount < 5 then
      for DesignateIndex, DetectedItem in pairs( DetectedItems ) do
        local IsDetected = self.Detection:IsDetectedItemDetected( DetectedItem )
        if IsDetected == true then
          self:F( { DistanceRecce = DetectedItem.DistanceRecce } )
          if DetectedItem.DistanceRecce <= self.MaximumDistanceDesignations then
            if self.Designating[DesignateIndex] == nil then
              -- ok, we added one item to the designate scope.
              self.AttackSet:ForEachGroup(
                function( AttackGroup )
                  local DetectionText = self.Detection:DetectedItemReportSummary( DesignateIndex, AttackGroup ):Text( ", " )
                  self.CC:GetPositionable():MessageToGroup( "Targets detected at \n" .. DetectionText, 10, AttackGroup, self.DesignateName )
                end
              )
              self.Designating[DesignateIndex] = ""
              break
            end
          end
        end
      end
    end
    
    return self
  end

  --- Coordinates the Auto Lase.
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:CoordinateLase()

    local DetectedItems = self.Detection:GetDetectedItems()
    
    for DesignateIndex, Designating in pairs( self.Designating ) do
      local DetectedItem = DetectedItems[DesignateIndex]
      if DetectedItem then
        if self.AutoLase then
          self:LaseOn( DesignateIndex, self.LaseDuration )
        end
      end
    end 
    
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

          local DetectedReport = REPORT:New( "Targets ready for Designation:" )
          local DetectedItems = self.Detection:GetDetectedItems()
          
          for DesignateIndex, Designating in pairs( self.Designating ) do
            local DetectedItem = DetectedItems[DesignateIndex]
            if DetectedItem then
              local Report = self.Detection:DetectedItemReportSummary( DesignateIndex, AttackGroup ):Text( ", " )
              DetectedReport:Add( string.rep( "-", 140 ) )
              DetectedReport:Add( " - " .. Report )
            end
          end
          
          local CC = self.CC:GetPositionable()
      
          CC:MessageToGroup( DetectedReport:Text( "\n" ), Duration, AttackGroup, self.DesignateName )
          
          local DesignationReport = REPORT:New( "Marking Targets:\n" )
      
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
      
          CC:MessageToGroup( DesignationReport:Text(), Duration, AttackGroup, self.DesignateName )
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
        self.MenuDesignate = self.MenuDesignate or {}
        
        local MissionMenu = nil
        
        if self.Mission then
          MissionMenu = self.Mission:GetRootMenu( AttackGroup )
        end
        
        local MenuTime = timer.getTime()
        
        self.MenuDesignate[AttackGroup] = MENU_GROUP:New( AttackGroup, self.DesignateName, MissionMenu ):SetTime( MenuTime ):SetTag( self.DesignateName ) 
        local MenuDesignate = self.MenuDesignate[AttackGroup] -- Core.Menu#MENU_GROUP

        -- Set Menu option for auto lase

        if self.AutoLase then        
          MENU_GROUP_COMMAND:New( AttackGroup, "Auto Lase Off", MenuDesignate, self.MenuAutoLase, self, false ):SetTime( MenuTime ):SetTag( self.DesignateName )
        else
          MENU_GROUP_COMMAND:New( AttackGroup, "Auto Lase On", MenuDesignate, self.MenuAutoLase, self, true ):SetTime( MenuTime ):SetTag( self.DesignateName )
        end        

        local StatusMenu = MENU_GROUP:New( AttackGroup, "Status", MenuDesignate ):SetTime( MenuTime ):SetTag( self.DesignateName )
        MENU_GROUP_COMMAND:New( AttackGroup, "Report Status 15s", StatusMenu, self.MenuStatus, self, AttackGroup, 15 ):SetTime( MenuTime ):SetTag( self.DesignateName )
        MENU_GROUP_COMMAND:New( AttackGroup, "Report Status 30s", StatusMenu, self.MenuStatus, self, AttackGroup, 30 ):SetTime( MenuTime ):SetTag( self.DesignateName )
        MENU_GROUP_COMMAND:New( AttackGroup, "Report Status 60s", StatusMenu, self.MenuStatus, self, AttackGroup, 60 ):SetTime( MenuTime ):SetTag( self.DesignateName )
        
        if self.FlashStatusMenu[AttackGroup] then
          MENU_GROUP_COMMAND:New( AttackGroup, "Flash Status Report Off", StatusMenu, self.MenuFlashStatus, self, AttackGroup, false ):SetTime( MenuTime ):SetTag( self.DesignateName )
        else
           MENU_GROUP_COMMAND:New( AttackGroup, "Flash Status Report On", StatusMenu, self.MenuFlashStatus, self, AttackGroup, true ):SetTime( MenuTime ):SetTag( self.DesignateName )
        end        
      
        for DesignateIndex, Designating in pairs( self.Designating ) do

          local DetectedItem = self.Detection:GetDetectedItem( DesignateIndex )

          if DetectedItem then
          
            local Coord = self.Detection:GetDetectedItemCoordinate( DesignateIndex )
            local ID = self.Detection:GetDetectedItemID( DesignateIndex )
            local MenuText = ID .. ", " .. Coord:ToStringA2G( AttackGroup )
            
            if Designating == "" then
              MenuText = "(-) " .. MenuText
              local DetectedMenu = MENU_GROUP:New( AttackGroup, MenuText, MenuDesignate ):SetTime( MenuTime ):SetTag( self.DesignateName )
              MENU_GROUP_COMMAND:New( AttackGroup, "Search other target", DetectedMenu, self.MenuForget, self, DesignateIndex ):SetTime( MenuTime ):SetTag( self.DesignateName )
              for LaserCode, MenuText in pairs( self.MenuLaserCodes ) do
                MENU_GROUP_COMMAND:New( AttackGroup, string.format( MenuText, LaserCode ), DetectedMenu, self.MenuLaseCode, self, DesignateIndex, 60, LaserCode ):SetTime( MenuTime ):SetTag( self.DesignateName )
              end
              MENU_GROUP_COMMAND:New( AttackGroup, "Lase with random laser code(s)", DetectedMenu, self.MenuLaseOn, self, DesignateIndex, 60 ):SetTime( MenuTime ):SetTag( self.DesignateName )
              MENU_GROUP_COMMAND:New( AttackGroup, "Smoke red", DetectedMenu, self.MenuSmoke, self, DesignateIndex, SMOKECOLOR.Red ):SetTime( MenuTime ):SetTag( self.DesignateName )
              MENU_GROUP_COMMAND:New( AttackGroup, "Smoke blue", DetectedMenu, self.MenuSmoke, self, DesignateIndex, SMOKECOLOR.Blue ):SetTime( MenuTime ):SetTag( self.DesignateName )
              MENU_GROUP_COMMAND:New( AttackGroup, "Smoke green", DetectedMenu, self.MenuSmoke, self, DesignateIndex, SMOKECOLOR.Green ):SetTime( MenuTime ):SetTag( self.DesignateName )
              MENU_GROUP_COMMAND:New( AttackGroup, "Smoke white", DetectedMenu, self.MenuSmoke, self, DesignateIndex, SMOKECOLOR.White ):SetTime( MenuTime ):SetTag( self.DesignateName )
              MENU_GROUP_COMMAND:New( AttackGroup, "Smoke orange", DetectedMenu, self.MenuSmoke, self, DesignateIndex, SMOKECOLOR.Orange ):SetTime( MenuTime ):SetTag( self.DesignateName )
              MENU_GROUP_COMMAND:New( AttackGroup, "Illuminate", DetectedMenu, self.MenuIlluminate, self, DesignateIndex ):SetTime( MenuTime ):SetTag( self.DesignateName )
            else
              if Designating == "Laser" then
                MenuText = "(L) " .. MenuText
              elseif Designating == "Smoke" then
                MenuText = "(S) " .. MenuText
              elseif Designating == "Illuminate" then
                MenuText = "(I) " .. MenuText
              end
              local DetectedMenu = MENU_GROUP:New( AttackGroup, MenuText, MenuDesignate ):SetTime( MenuTime ):SetTag( self.DesignateName )
              if Designating == "Laser" then
                MENU_GROUP_COMMAND:New( AttackGroup, "Stop lasing", DetectedMenu, self.MenuLaseOff, self, DesignateIndex ):SetTime( MenuTime ):SetTag( self.DesignateName )
              else
              end
            end
          end
        end
        MenuDesignate:Remove( MenuTime, self.DesignateName )
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
  function DESIGNATE:MenuForget( Index )

    self:E("Forget")

    self.Designating[Index] = nil
    self:SetDesignateMenu()
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuAutoLase( AutoLase )

    self:E("AutoLase")

    self:SetAutoLase( AutoLase, true )
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuSmoke( Index, Color )

    self:E("Designate through Smoke")

    self.Designating[Index] = "Smoke"
    self:Smoke( Index, Color )    
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
    self:SetDesignateMenu()
  end


  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuLaseCode( Index, Duration, LaserCode )

    self:E( "Designate through Lase using " .. LaserCode )
    
    self:__LaseOn( 1, Index, Duration, LaserCode ) 
    self:SetDesignateMenu()
  end


  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:MenuLaseOff( Index, Duration )

    self:E("Lasing off")

    self.Designating[Index] = ""
    self:__LaseOff( 1, Index ) 
    self:SetDesignateMenu()
  end

  --- 
  -- @param #DESIGNATE self
  function DESIGNATE:onafterLaseOn( From, Event, To, Index, Duration, LaserCode )
  
    self.Designating[Index] = "Laser"
    self.LaseStart = timer.getTime()
    self.LaseDuration = Duration
    self:__Lasing( -1, Index, Duration, LaserCode )
  end
  

  --- 
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterLasing( From, Event, To, Index, Duration, LaserCodeRequested )
  
  
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )

    local MarkingCount = 0
    local MarkedTypes = {}
    local ReportTypes = REPORT:New()
    local ReportLaserCodes = REPORT:New()
    
    TargetSetUnit:Flush()

    --self:F( { Recces = self.Recces } ) 
    for TargetUnit, RecceData in pairs( self.Recces ) do
      local Recce = RecceData -- Wrapper.Unit#UNIT
      self:F( { TargetUnit = TargetUnit, Recce = Recce:GetName() } )
      if not Recce:IsLasing() then
        local LaserCode = Recce:GetLaserCode() -- (Not deleted when stopping with lasing).
        self:F( { ClearingLaserCode = LaserCode } )
        self.LaserCodesUsed[LaserCode] = nil
        self.Recces[TargetUnit] = nil
      end
    end
    
    -- If a specific lasercode is requested, we disable one active lase!
    if LaserCodeRequested then
      for TargetUnit, RecceData in pairs( self.Recces ) do -- We break after the first has been processed.
        local Recce = RecceData -- Wrapper.Unit#UNIT
        self:F( { TargetUnit = TargetUnit, Recce = Recce:GetName() } )
        if Recce:IsLasing() then
          -- When a Recce is lasing, we switch the lasing off, and clear the references to the lasing in the DESIGNATE class.
          Recce:LaseOff() -- Switch off the lasing.
          local LaserCode = Recce:GetLaserCode() -- (Not deleted when stopping with lasing).
          self:F( { ClearingLaserCode = LaserCode } )
          self.LaserCodesUsed[LaserCode] = nil
          self.Recces[TargetUnit] = nil
          break
        end
      end
    end    
    
    if self.AutoLase or ( not self.AutoLase and ( self.LaseStart + Duration >= timer.getTime() ) ) then

      TargetSetUnit:ForEachUnitPerThreatLevel( 10, 0,
        --- @param Wrapper.Unit#UNIT SmokeUnit
        function( TargetUnit )
        
          self:F( { TargetUnit = TargetUnit:GetName() } )
  
          if MarkingCount < self.MaximumMarkings then
  
            if TargetUnit:IsAlive() then
    
              local Recce = self.Recces[TargetUnit]
    
              if not Recce then
    
                self:E( "Lasing..." )
                self.RecceSet:Flush()
    
                for RecceGroupID, RecceGroup in pairs( self.RecceSet:GetSet() ) do
                  for UnitID, UnitData in pairs( RecceGroup:GetUnits() or {} ) do
    
                    local RecceUnit = UnitData -- Wrapper.Unit#UNIT
                    local RecceUnitDesc = RecceUnit:GetDesc()
                    --self:F( { RecceUnit = RecceUnit:GetName(), RecceDescription = RecceUnitDesc } )
    
                    if RecceUnit:IsLasing() == false then
                      --self:F( { IsDetected = RecceUnit:IsDetected( TargetUnit ), IsLOS = RecceUnit:IsLOS( TargetUnit ) } )
    
                      if RecceUnit:IsDetected( TargetUnit ) and RecceUnit:IsLOS( TargetUnit ) then
    
                        local LaserCodeIndex = math.random( 1, #self.LaserCodes )
                        local LaserCode = self.LaserCodes[LaserCodeIndex]
                        --self:F( { LaserCode = LaserCode, LaserCodeUsed = self.LaserCodesUsed[LaserCode] } )
    
                        if LaserCodeRequested and LaserCodeRequested ~= LaserCode then
                          LaserCode = LaserCodeRequested
                          LaserCodeRequested = nil
                        end
    
                        if not self.LaserCodesUsed[LaserCode] then
    
                          self.LaserCodesUsed[LaserCode] = LaserCodeIndex
                          local Spot = RecceUnit:LaseUnit( TargetUnit, LaserCode, Duration )
                          local AttackSet = self.AttackSet
                          local DesignateName = self.DesignateName
    
                          function Spot:OnAfterDestroyed( From, Event, To )
                            self.Recce:MessageToSetGroup( "Target " .. TargetUnit:GetTypeName() .. " destroyed. " .. TargetSetUnit:Count() .. " targets left.", 
                                                          5, AttackSet, self.DesignateName )
                          end
    
                          self.Recces[TargetUnit] = RecceUnit
                          RecceUnit:MessageToSetGroup( "Marking " .. TargetUnit:GetTypeName() .. " with laser " .. RecceUnit:GetSpot().LaserCode .. " for " .. Duration .. "s.", 
                                                       5, self.AttackSet, DesignateName )
                          -- OK. We have assigned for the Recce a TargetUnit. We can exit the function.
                          MarkingCount = MarkingCount + 1
                          local TargetUnitType = TargetUnit:GetTypeName()
                          if not MarkedTypes[TargetUnitType] then
                            MarkedTypes[TargetUnitType] = true
                            ReportTypes:Add(TargetUnitType)
                          end
                          ReportLaserCodes:Add(RecceUnit.LaserCode)
                          return
                        end
                      else
                        --RecceUnit:MessageToSetGroup( "Can't mark " .. TargetUnit:GetTypeName(), 5, self.AttackSet )
                      end
                    else
                      -- The Recce is lasing, but the Target is not detected or within LOS. So stop lasing and send a report.
    
                      if not RecceUnit:IsDetected( TargetUnit ) or not RecceUnit:IsLOS( TargetUnit ) then
    
                        local Recce = self.Recces[TargetUnit] -- Wrapper.Unit#UNIT
    
                        if Recce then
                          Recce:LaseOff()
                          Recce:MessageToSetGroup( "Target " .. TargetUnit:GetTypeName() "out of LOS. Cancelling lase!", 5, self.AttackSet, self.DesignateName )
                        end
                      else
                        MarkingCount = MarkingCount + 1
                        local TargetUnitType = TargetUnit:GetTypeName()
                        if not MarkedTypes[TargetUnitType] then
                          MarkedTypes[TargetUnitType] = true
                          ReportTypes:Add(TargetUnitType)
                        end
                        ReportLaserCodes:Add(RecceUnit.LaserCode)
                      end  
                    end
                  end
                end
              else
                MarkingCount = MarkingCount + 1
                local TargetUnitType = TargetUnit:GetTypeName()
                if not MarkedTypes[TargetUnitType] then
                  MarkedTypes[TargetUnitType] = true
                  ReportTypes:Add(TargetUnitType)
                end
                ReportLaserCodes:Add(Recce.LaserCode)
                --Recce:MessageToSetGroup( self.DesignateName .. ": Marking " .. TargetUnit:GetTypeName() .. " with laser " .. Recce.LaserCode .. ".", 5, self.AttackSet )
              end
            end
          end
        end
      )

      local MarkedTypesText = ReportTypes:Text(', ')
      local MarkedLaserCodesText = ReportLaserCodes:Text(', ')
      for MarkedType, MarketCount in pairs( MarkedTypes ) do
        self.CC:GetPositionable():MessageToSetGroup( "Marking " .. MarkingCount .. " x " .. MarkedTypesText .. " with lasers " .. MarkedLaserCodesText .. ".", 5, self.AttackSet, self.DesignateName )
      end
  
      self:__Lasing( -30, Index, Duration, LaserCodeRequested )
      
      self:SetDesignateMenu()

    else
      self:__LaseOff( 1 )
    end

  end
    
  --- 
  -- @param #DESIGNATE self
  -- @return #DESIGNATE
  function DESIGNATE:onafterLaseOff( From, Event, To, Index )
  
    local CC = self.CC:GetPositionable()
    
    if CC then 
      CC:MessageToSetGroup( "Stopped lasing.", 5, self.AttackSet, self.DesignateName )
    end
    
    local TargetSetUnit = self.Detection:GetDetectedSet( Index )
    
    local Recces = self.Recces
    
    for TargetID, RecceData in pairs( Recces ) do
      local Recce = RecceData -- Wrapper.Unit#UNIT
      Recce:MessageToSetGroup( "Stopped lasing " .. Recce:GetSpot().Target:GetTypeName() .. ".", 5, self.AttackSet, self.DesignateName )
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
  
    local MarkedCount = 0
  
    TargetSetUnit:ForEachUnitPerThreatLevel( 10, 0,
      --- @param Wrapper.Unit#UNIT SmokeUnit
      function( SmokeUnit )

        if MarkedCount < self.MaximumMarkings then
      
          MarkedCount = MarkedCount + 1        
      
          self:E( "Smoking ..." )

          local RecceGroup = self.RecceSet:FindNearestGroupFromPointVec2(SmokeUnit:GetPointVec2())
          local RecceUnit = RecceGroup:GetUnit( 1 )

          if RecceUnit then

            RecceUnit:MessageToSetGroup( "Smoking " .. SmokeUnit:GetTypeName() .. ".", 5, self.AttackSet, self.DesignateName )

            self.MarkScheduler:Schedule( self,
              function()
                if SmokeUnit:IsAlive() then
                  SmokeUnit:Smoke( Color, 50, 2 )
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
        RecceUnit:MessageToSetGroup( "Illuminating " .. TargetUnit:GetTypeName() .. ".", 5, self.AttackSet, self.DesignateName )
        self.MarkScheduler:Schedule( self,
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

