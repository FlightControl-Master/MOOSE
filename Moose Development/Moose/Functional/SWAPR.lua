--- **Functional** - (R2.5) - Replace client aircraft by statics until a player enters.
-- 
-- Make the DCS world a bit more lively!
--
-- **Main Features:**
--
--    * Easy!
--    
-- ## Known (DCS) Issues
-- 
--    * Does not support clients on ships.
--    * Does not support Harriers and helicopters on parking spots below a shelter.
--
-- ===
--
-- ### Author: **Hardcard** (aka Goreuncle on the MOOSE discord)
-- ### Contributions: funkyfranky
--
-- @module Functional.Swapr
-- @image Functional_SWAPR.png

--- SWAPR class.
-- @type SWAPR
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode on/off.
-- @field #string lid Log debug id text.
-- @field Core.Set#SET_CLIENT clientset Set of clients to be replaced.
-- @field #table statics Table of static objects.
-- @field #table statictemplate Table of static template
-- @extends Core.Fsm#FSM

--- Swap clients and statics
--
-- ===
--
-- ![Banner Image](..\Presentations\SWAPR\SWAPR_Main.png)
--
-- # SWAPR Concept
--
-- SWAPR will enable you to easily spawn static aircraft on client slots. When a player enters a client slot, the static object is removed and the player aircraft spawned.
-- This makes the airbases look a lot more alive.
-- 
-- # Simple Script
-- 
-- The basic script is very simple and consists of only two lines:
-- 
--      local clientset=SET_CLIENT:New():FilterActive(false):FilterOnce()
--      swapr=SWAPR:New(clientset)
--      
-- The first line defines a set of clients (here all) that will be replaced by statics.
-- The second lines initiates the SWAPR script. That's all.
-- 
-- **Note** that Harrier and helicopter clients are automatically removed from the client set if they are placed on a sheltered parking spot. Otherwise the statics would be spawned
-- on top of the shelter roof.
-- 
-- Similarly, clients on ships are removed as these would be spawned at sea level and not on the ship itself.
-- 
-- All these are *DCS side restriction* when spawning statics.
--
-- # Debugging
-- 
-- In case you have problems, it is always a good idea to have a look at your DCS log file. You find it in your "Saved Games" folder, so for example in
--     C:\Users\<yourname>\Saved Games\DCS\Logs\dcs.log
-- All output concerning the @{#SWAPR} class should have the string "SWAPR" in the corresponding line.
-- Searching for lines that contain the string "error" or "nil" can also give you a hint what's wrong.
-- 
-- The verbosity of the output can be increased by adding the following lines to your script:
-- 
--     BASE:TraceOnOff(true)
--     BASE:TraceLevel(1)
--     BASE:TraceClass("SWAPR")
-- 
-- To get even more output you can increase the trace level to 2 or even 3, c.f. @{Core.Base#BASE} for more details.
-- 
-- ## Debug Mode
-- 
-- You have the option to enable the debug mode for this class via the @{#SWAPR.SetDebugModeON} function.
-- If enabled, text messages about the helo status will be displayed on screen and marks of the pattern created on the F10 map.
--
--
-- @field #SWAPR
SWAPR = {
  ClassName      = "SWAPR",
  Debug          = false,
  lid            = nil,
  clientset      = nil,
  statics        =  {},
  statictemplate =  {},
}

--- Class version.
-- @field #string version
SWAPR.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Check for clients on ships ==> get airdrome id from first route point.
-- TODO: Check that harrier and helo clients are not spawned in shelters ==> get parking spot type for these units in _Prepare()
-- TODO: Check what happens if statics are destroyed.
-- TODO: Check what happens if clients eject, crash or are shot down.
-- TODO: Check that parking spot is not blocked by other aircraft or statics when spawning a static replacement.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new SWAPR object. 
-- @param #SWAPR self
-- @param Core.Set#SET_CLIENT clientset Set of clients to be replaced.
-- @return #SWAPR SWAPR object.
function SWAPR:New(clientset)

  -- Inherit everthing from FSM class.
  local self = BASE:Inherit(self, FSM:New()) -- #SWAPR
  
  -- Carrier type.
  self.clientset=clientset
    
  -- Log ID.
  self.lid=string.format("SWAPR | ")
  
  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  -- Events are handled directly by DCS.
  self:T(self.lid.."Events are handled directly by DCS.")
  world.addEventHandler(self)
  
  self:HandleEvent(EVENTS.RemoveUnit)
  
  -- Prepare stuff by temporarity spawning aircraft to determine the heading.
  self:_Prepare()
  
  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->  Event    -->  To State
  self:AddTransition("Stopped",       "Start",      "Running")
  self:AddTransition("*",             "Status",     "*")
  self:AddTransition("*",             "Stop",       "Stopped")


  --- Triggers the FSM event "Start" that starts the rescue helo. Initializes parameters and starts event handlers.
  -- @function [parent=#SWAPR] Start
  -- @param #SWAPR self

  --- Triggers the FSM event "Start" that starts the rescue helo after a delay. Initializes parameters and starts event handlers.
  -- @function [parent=#SWAPR] __Start
  -- @param #SWAPR self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Status" that updates the helo status.
  -- @function [parent=#SWAPR] Status
  -- @param #SWAPR self

  --- Triggers the delayed FSM event "Status" that updates the helo status.
  -- @function [parent=#SWAPR] __Status
  -- @param #SWAPR self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop" that stops the rescue helo. Event handlers are stopped.
  -- @function [parent=#SWAPR] Stop
  -- @param #SWAPR self

  --- Triggers the FSM event "Stop" that stops the rescue helo after a delay. Event handlers are stopped.
  -- @function [parent=#SWAPR] __Stop
  -- @param #SWAPR self
  -- @param #number delay Delay in seconds.
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event handler
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- General event handler.
-- @param #SWAPR self
-- @param #table Event DCS event table.
function SWAPR:onEvent(Event)
  self:F3(Event)

  if Event == nil or Event.initiator == nil then
    self:T3("Skipping onEvent. Event or Event.initiator unknown.")
    return true
  end
  
  if Unit.getByName(Event.initiator:getName()) == nil then
    self:T3("Skipping onEvent. Initiator unit name unknown.")
    --return true
  end

  -- Get unit name and category.
  local IniUnitName = Event.initiator:getName()
  local IniCategory = Event.initiator:getCategory()
  
  -- Get client.
  local client=self.clientset:FindClient(IniUnitName)
  
  -- This is not an event involving a client in the defined set.
  if not client then
    env.info("FF event not associated with client aircraft!")
    return
  end

  if Event.id==EVENTS.Birth then
  
    -----------------
    -- BIRTH EVENT --
    -----------------
  
    if IniCategory==1 then
    
      ---------------
      -- UNIT BORN --
      ---------------
    
      local IniDCSGroup  = Event.initiator:getGroup()
      local IniGroupName = Event.initiator:getGroup():getName()
    
      -- Debug info.
      env.info(string.format("FF Event birth for unit %s of group %s", tostring(IniUnitName), tostring(IniGroupName)))

      -- Get unit.
      local unit=UNIT:FindByName(IniUnitName)
            
      if unit then
      
        --unit:SmokeGreen()
        
        -- Group and name.
        local group=unit:GetGroup()
        local groupname=group:GetName()
        
        -- Check if this is prepare step to determine the heading.
        if string.find(groupname, "_SWAPR") then
          --unit:SmokeBlue()
          
          -- Get info necessary for the static template.
          local heading=unit:GetHeading()
          local coord=unit:GetCoordinate()
          local actype=unit:GetTypeName()
          local livery=self:_GetLiveryFromTemplate(IniUnitName)
          
          -- Add static template to table.
          local statictemplate=self:_AddStaticTemplate(IniUnitName, actype, coord.x, coord.z, heading, unit:GetCountry(), livery)
          
          -- Destroy unit ==> triggers a remove unit event.
          unit:Destroy()
          
          -- Replace aircraft by static.
          --self:_Aircraft2Static(unit)
          
        else
          env.info("FF client spawned!")
        
          -- Get static that is in place of the spawned client.
          local static=self.statics[IniUnitName] --Wrapper.Static#STATIC
          
          -- Remove static.
          if static then
            env.info("FF destroying static!")
            
            -- Looks like the MOOSE Destroy function is not fast enough!
            static:destroy()
            self.statics[IniUnitName]=nil
          else
            env.info("FF no static to destroy!")
          end
        
        end
        
      end
            
    elseif IniCategory==3 then
    
      -----------------
      -- STATIC BORN --
      -----------------
    
      env.info(string.format("FF Event birth for static %s", tostring(IniUnitName)))
            
      -- WORKS!
      local static=STATIC:FindByName(IniUnitName, true)
      
      -- Add spawned static to table.
      --self.statics[IniUnitName]=static
      self.statics[IniUnitName]=Event.initiator
   
    end
    
  elseif Event.id==EVENTS.PlayerLeaveUnit then
  
    -----------------
    -- PLAYER LEFT --
    -----------------
    
    env.info(string.format("FF Event player leave unit for unit %s", IniUnitName))
    
    -- Spawn static. Needs to be delayed a tad or DCS crashes to desktop.
    local statictemplate=self.statictemplate[IniUnitName]
    if statictemplate then
      self:ScheduleOnce(0.1, SWAPR._SpawnStaticAircraft, self, statictemplate)
    end
  end
  
end

--- General event handler.
-- @param #SWAPR self
-- @param Core.Event#EVENTDATA EventData Event data table.
function SWAPR:OnEventRemoveUnit(EventData)
  self:I(EventData)
  
  if EventData and EventData.IniUnitName then
  
    -- Debug info.
    env.info(string.format("FF Event removed unit %s!", EventData.IniUnitName))
      
    -- Spawn static aircraft.
    local statictemplate=self.statictemplate[EventData.IniUnitName]
    if statictemplate then
      self:ScheduleOnce(0.1, SWAPR._SpawnStaticAircraft, self, statictemplate)
    end
  
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Spawn functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add template to static table.
-- @param #SWAPR self
-- @param #string name Name of the static.
-- @param #string actype Type of the aircraft.
-- @param #number x X coordinate of spawn place.
-- @param #number y Y coordinate of spawn place.
-- @param #number heading Heading of static.
-- @param #number country Country ID of static.
-- @param #string livery Livery ID of the static.
-- @return #table Static template.
function SWAPR:_AddStaticTemplate(name, actype, x, y, heading, country, livery)

  -- Heading is in rad not degrees!
  local headingrad=0
  if heading then
    headingrad=math.rad(heading)
  end

  -- Static template table.    
  local static={
   livery_id=livery,
   heading=headingrad,
   type=actype,
   name=name,
   y=y ,
   x=x ,
   CountryID=country,
  }
  
  -- Debug info.
  self:I({statictemplate=static})

  self.statictemplate[name]=static

  return static
end

--- General event handler.
-- @param #SWAPR self
-- @param #table template The static template.
function SWAPR:_SpawnStaticAircraft(template)
  self:I({statictemplate=template})

  if template and not self.statics[template.name] then

    -- Spawn static.
    local static=coalition.addStaticObject(template.CountryID, template)

    -- Debug info.    
    self:I({spawnedstatic=static})
    env.info(string.format("FF spawned static name = %s", template.name))
    
  else
    self:T3(self.lid.."WARNING: Static template is nil!")
  end
  
end

--- Replace a whole aircraft group by statics.
-- @param #SWAPR self
-- @param Wrapper.Group#GROUP group
function SWAPR:_AircraftGroup2Statics(group)

  -- Get the group template.
  local grouptemplate=group:GetTemplate()
  
  -- Debug info.
  self:I({groupname=grouptemplate})
  
  for i,_unit in pairs(group:GetUnits()) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    -- Get unit name.
    local unitname=unit:GetName()
    
    local statictemplate=self.statictemplate[unitname]
    local static=self.statics[unitname]
    
    if statictemplate and not static then
        
      -- Destroy the unit.
      unit:Destroy()
      
      -- Spawn static aircraft instead.
      self:_SpawnStaticAircraft(statictemplate)
    end
    
  end
end

--- Replace a single aircraft unit by static.
-- @param #SWAPR self
-- @param Wrapper.Unit#UNIT unit The unit to be replaced.
function SWAPR:_Aircraft2Static(unit)

  if unit and unit:IsAlive() then

    -- Get the group template.
    local grouptemplate=unit:GetGroup():GetTemplate()
    
    -- Debug info.
    self:I({groupname=grouptemplate})
    
    -- Get unit name.
    local unitname=unit:GetName()
    
    -- Get the static template.
    local statictemplate=self.statictemplate[unitname]
    
    -- Get the static to check if there already is one.
    local static=self.statics[unitname]
    
    if statictemplate and not static then
        
      -- Destroy the unit ==> triggers a RemoveUnit event.
      unit:Destroy()
      
      -- Spawn static aircraft instead.
      self:_SpawnStaticAircraft(statictemplate)
    end
    
  end
end


--- Temporarily spawn uncontrolled aircraft at all client spots to get the correct headings.
-- @param #SWAPR self
function SWAPR:_Prepare()

  for _,_client in pairs(self.clientset:GetSet()) do
    local client=_client --Wrapper.Client#CLIENT
    
    -- Unit name
    local unitname=client.ClientName
        
    if true then
  
      -- Client group name.
      local groupname=_DATABASE.Templates.Units[unitname].GroupName
      
      -- Client group template copy.
      local grouptemplate=UTILS.DeepCopy(_DATABASE:GetGroupTemplate(groupname))
      
      -- Nillify the group ID.
      grouptemplate.groupId=nil
        
      -- Set skill.
      for i=1,#grouptemplate.units do
        local unit=grouptemplate.units[i]
        unit.skill="Good"
        -- Nillify the unit ID.
        unit.unitId=nil
      end
      
      -- Uncontrolled
      grouptemplate.uncontrolled=true
      
      -- Add _SWAPR to the group name so that we find it in birth event.
      grouptemplate.name=string.format("%s_SWAPR", groupname)
      
      -- Debug info.
      self:I({grouptemplate=grouptemplate})
          
      -- Spawn group.
      local group=_DATABASE:Spawn(grouptemplate)
      
    else
    
      local livery=self:_GetLiveryFromTemplate(unitname)
      local x,y=self:_GetPositionFromTemplate(unitname)
      local actype=self:_GetTypeFromTemplate(unitname)
      local heading=self:_GetHeadingFromTemplate(unitname)
      
      local template=self:_AddStaticTemplate(unitname, actype, x, y, heading, 1, livery)
      
      self:_SpawnStaticAircraft(template)
          
    end
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get livery from unit.
-- @param #SWAPR self
-- @param #string unitname Name of the unit.
-- @return #string Livery ID.
function SWAPR:_GetLiveryFromTemplate(unitname)

  local grouptemplate=_DATABASE:GetGroupTemplateFromUnitName(unitname)
  
  for _,unit in pairs(grouptemplate.units) do
    if unit.name==unitname then
      return tostring(unit.livery_id)
    end
  end

  return nil
end

--- Get livery from unit.
-- @param #SWAPR self
-- @param #string unitname Name of the unit.
-- @return #number X coordinate.
-- @return #number Y coordinate.
function SWAPR:_GetPositionFromTemplate(unitname)

  local grouptemplate=_DATABASE:GetGroupTemplateFromUnitName(unitname)
  
  for _,unit in pairs(grouptemplate.units) do
    if unit.name==unitname then
      return tonumber(unit.x), tonumber(unit.y)
    end
  end

  return nil, nil
end


--- Get livery from unit.
-- @param #SWAPR self
-- @param #string unitname Name of the unit.
-- @return #string Aircraft type.
function SWAPR:_GetTypeFromTemplate(unitname)

  local grouptemplate=_DATABASE:GetGroupTemplateFromUnitName(unitname)
  
  for _,unit in pairs(grouptemplate.units) do
    if unit.name==unitname then
      return tostring(unit.type)
    end
  end

  return nil
end

--- Get livery from unit.
-- @param #SWAPR self
-- @param #string unitname Name of the unit.
-- @return #number Heading in degrees.
function SWAPR:_GetHeadingFromTemplate(unitname)

  local grouptemplate=_DATABASE:GetGroupTemplateFromUnitName(unitname)
  
  for _,unit in pairs(grouptemplate.units) do
    if unit.name==unitname then
      return tonumber(unit.heading)
    end
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

