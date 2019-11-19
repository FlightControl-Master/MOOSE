--- **Ops** - (R2.5) - Random Air Traffic.
-- 
-- 
-- 
-- RAT2 creates random air traffic on the map.
-- 
-- 
--
-- **Main Features:**
--
--     * It's very random.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Functional.Rat2
-- @image Functional_Rat2.png


--- RAT2 class.
-- @type RAT2
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table Qspawn Queue of ratcraft to spawn.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\RAT2\RAT2_Main.png)
--
-- # The RAT2 Concept
-- 
-- 
-- 
-- @field #RAT2
RAT2 = {
  ClassName      = "RAT2",
  Debug          =  false,
  lid            =    nil,
  Qflights       =     {},
  Qspawn         =     {},
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new RAT2 class object.
-- @param #RAT2 self
-- @return #RAT2 self.
function RAT2:New()

  -- Inherit everthing from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #RAT2
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Load",            "Stopped")     -- Load player scores from file.
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start RAT2 script.
  self:AddTransition("*",             "Status",          "*")           -- Start RAT2 script.
  
end

--- Create a new RAT2 class object.
-- @param #RAT2 self
-- @param #RATAC ratcraft The aircraft to add.
-- @return #RAT2 self.
function RAT2:AddAircraft(ratcraft)

  -- Add ratcraft to spawn queue.
  table.insert(self.Qspawn, ratcraft)

  return self
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check spawn queue and spawn aircraft if necessary.
-- @param #RAT2 self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RAT2:onafterStatus(From, Event, To)

  -- Check queue of aircraft to spawn.
  self:_CheckQueueSpawn()
  
  self:__Status(-30)
end


--- Check spawn queue and spawn aircraft if necessary.
-- @param #RAT2 self
function RAT2:_CheckQueueSpawn()

  for i,_ratcraft in pairs(self.Qspawn) do
    local ratcraft=_ratcraft --#RATAC
    
    --ratcraft.actype
    
    --- Check if
    -- Time has passed.
    -- Already enough aircraft are alive
    
      -- Try to spawn a ratcraft group.
    local spawned=self:_TrySpawnRatcraft(ratcraft)
    
    -- Remove queue item and break loop.
    if spawned then
      table.remove(self.Qspawn, i)
      break
    end
  end  
  
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Spawn functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Spawn an aircraft asset (plane or helo) at the airbase associated with the warehouse.
-- @param #RAT2 self
-- @param #RATAC ratcraft
-- @return #boolean If true, ratcraft was spawned.
function RAT2:_TrySpawnRatcraft(ratcraft)

  -- TODO: loop over departure airbases.
  
  for _,_departure in pairs(ratcraft.departures) do
  
    local departure=_departure --#RATAC.Departure
    
    local parking=nil
    
    if departure.type==RATAC.DeType.AIRBASE then
    
      -- Get parking data.
      local parking=self:_FindParking(departure.airbase, ratcraft)
    
      -- Check if enough parking is available.
      if parking then
        self:_SpawnRatcraft()
        return true
      end      
    
    
    elseif departure.type==RATAC.DeType.ZONE then
    
    end


    
  end
  
  
  return false
end


--- Spawn an aircraft asset (plane or helo) at the airbase associated with the warehouse.
-- @param #RAT2 self
-- @param #RATAC ratcraft Ratcraft to spawn.
-- @param #table parking Parking data for this asset.
-- @param #boolean uncontrolled Spawn aircraft in uncontrolled state.
-- @return Wrapper.Group#GROUP The spawned group or nil if the group could not be spawned.
function RAT2:_SpawnRatcraft(ratcraft, departure, destination, parking, uncontrolled)

  -- Prepare the spawn template.
  local template=self:_SpawnAssetPrepareTemplate(ratcraft, alias)
  
    -- Get flight path if the group goes to another warehouse by itself.
  template.route.points=self:_GetFlightplan(ratcraft, departure, destination)
  
  -- Get airbase ID and category.
  local AirbaseID = self.airbase:GetID()
  local AirbaseCategory = self:GetAirbaseCategory()
  
  -- Check enough parking spots.
  if AirbaseCategory==Airbase.Category.HELIPAD or AirbaseCategory==Airbase.Category.SHIP then
  
    --TODO Figure out what's necessary in this case.
  
  else
  
    if #parking<#template.units then
      local text=string.format("ERROR: Not enough parking! Free parking = %d < %d aircraft to be spawned.", #parking, #template.units)
      self:_DebugMessage(text)
      return nil
    end
  
  end
  
  -- Position the units.
  for i=1,#template.units do
  
    -- Unit template.
    local unit = template.units[i]
  
    if AirbaseCategory == Airbase.Category.HELIPAD or AirbaseCategory == Airbase.Category.SHIP then
  
      -- Helipads we take the position of the airbase location, since the exact location of the spawn point does not make sense.
      local coord=self.airbase:GetCoordinate()
  
      unit.x=coord.x
      unit.y=coord.z
      unit.alt=coord.y
  
      unit.parking_id = nil
      unit.parking    = nil
  
    else
  
      local coord=parking[i].Coordinate    --Core.Point#COORDINATE
      local terminal=parking[i].TerminalID --#number
  
      if self.Debug then
        coord:MarkToAll(string.format("Spawnplace unit %s terminal %d.", unit.name, terminal))
      end
  
      unit.x=coord.x
      unit.y=coord.z
      unit.alt=coord.y
  
      unit.parking_id = nil
      unit.parking    = terminal
  
    end
  
    if asset.livery then
      unit.livery_id = asset.livery
    end
    if asset.skill then
      unit.skill= asset.skill
    end
  
  end
  
  -- And template position.
  template.x = template.units[1].x
  template.y = template.units[1].y
  
  -- Uncontrolled spawning.
  template.uncontrolled=uncontrolled
  
  -- Debug info.
  self:T2({airtemplate=template})
  
  -- Spawn group.
  local group=_DATABASE:Spawn(template) --Wrapper.Group#GROUP
  
  return group
end


--- Prepare a spawn template for the asset. Deep copy of asset template, adjusting template and unit names, nillifying group and unit ids.
-- @param #RAT2 self
-- @param #RATAC ratcraft Aircraft that will be spawned.
-- @param #string alias Alias name of the group.
-- @return #table Prepared new spawn template.
function RAT2:_SpawnAssetPrepareTemplate(ratcraft, alias)

  -- Create an own copy of the template!
  local template=UTILS.DeepCopy(ratcraft.template)

  -- Set unique name.
  template.name=alias

  -- Set current(!) coalition and country.
  template.CoalitionID=ratcraft.coalition
  template.CountryID=ratcraft.country

  -- Nillify the group ID.
  template.groupId=nil

  -- No late activation.
  template.lateActivation=false

  -- Set and empty route.
  template.route = {}
  template.route.routeRelativeTOT=true
  template.route.points = {}

  -- Handle units.
  for i=1,#template.units do

    -- Unit template.
    local unit = template.units[i]

    -- Nillify the unit ID.
    unit.unitId=nil

    -- Set unit name: <alias>-01, <alias>-02, ...
    unit.name=string.format("%s-%02d", template.name , i)

  end

  return template
end

--@param #RCRAFT.Attribute _attribute Generlized attribute of unit.

--- Get the proper terminal type based on generalized attribute of the group.
--@param #RAT2 self
--@param #number _category Airbase category.
--@return Wrapper.Airbase#AIRBASE.TerminalType Terminal type for this group.
function RAT2:_GetTerminal(_attribute, _category)

  -- Default terminal is "large".
  local _terminal=AIRBASE.TerminalType.OpenBig

  if _attribute==RCRAFT.Attribute.FIGHTER then
    -- Fighter ==> small.
    _terminal=AIRBASE.TerminalType.FighterAircraft
  elseif _attribute==RCRAFT.Attribute.BOMBER or _attribute==RCRAFT.Attribute.TRANSPORTPLANE or _attribute==RCRAFT.Attribute.TANKER or _attribute==RCRAFT.Attribute.AWACS then
    -- Bigger aircraft.
    _terminal=AIRBASE.TerminalType.OpenBig
  elseif _attribute==RCRAFT.Attribute.TRANSPORTHELO or _attribute==RCRAFT.Attribute.ATTACKHELO then
    -- Helicopter.
    _terminal=AIRBASE.TerminalType.HelicopterUsable
  else
    --_terminal=AIRBASE.TerminalType.OpenMedOrBig
  end

  -- For ships, we allow medium spots for all fixed wing aircraft. There are smaller tankers and AWACS aircraft that can use a carrier.
  if _category==Airbase.Category.SHIP then
    if not (_attribute==RCRAFT.Attribute.TRANSPORTHELO or _attribute==RCRAFT.Attribute.ATTACKHELO) then
      _terminal=AIRBASE.TerminalType.OpenMedOrBig
    end
  end

  return _terminal
end


--- Seach unoccupied parking spots at the airbase for a list of assets. For each asset group a list of parking spots is returned.
-- During the search also the not yet spawned asset aircraft are considered.
-- If not enough spots for all asset units could be found, the routine returns nil!
-- @param #RAT2 self
-- @param Wrapper.Airbase#AIRBASE airbase The airbase where we search for parking spots.
-- @param #RATAC ratcraft Ratcraft.
-- @return #table Table of coordinates and terminal IDs of free parking spots. Each table entry has the elements .Coordinate and .TerminalID.
function RAT2:_FindParking(airbase, ratcraft)

  -- Init default
  local scanradius=100
  local scanunits=true
  local scanstatics=true
  local scanscenery=false
  local verysafe=false

  -- Function calculating the overlap of two (square) objects.
  local function _overlap(l1,l2,dist)
    local safedist=(l1/2+l2/2)*1.05  -- 5% safety margine added to safe distance!
    local safe = (dist > safedist)
    self:T3(string.format("l1=%.1f l2=%.1f s=%.1f d=%.1f ==> safe=%s", l1,l2,safedist,dist,tostring(safe)))
    return safe
  end

  -- Get parking spot data table. This contains all free and "non-free" spots.
  local parkingdata=airbase:GetParkingSpotsTable()

  -- List of obstacles.
  local obstacles={}

  -- Loop over all parking spots and get the currently present obstacles.
  -- How long does this take on very large airbases, i.e. those with hundereds of parking spots? Seems to be okay!
  for _,parkingspot in pairs(parkingdata) do

    -- Coordinate of the parking spot.
    local _spot=parkingspot.Coordinate   -- Core.Point#COORDINATE
    local _termid=parkingspot.TerminalID

    -- Scan a radius of 100 meters around the spot.
    local _,_,_,_units,_statics,_sceneries=_spot:ScanObjects(scanradius, scanunits, scanstatics, scanscenery)

    -- Check all units.
    for _,_unit in pairs(_units) do
      local unit=_unit --Wrapper.Unit#UNIT
      local _coord=unit:GetCoordinate()
      local _size=self:_GetObjectSize(unit:GetDCSObject())
      local _name=unit:GetName()
      table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="unit"})
    end

    -- Check all statics.
    for _,static in pairs(_statics) do
      local _vec3=static:getPoint()
      local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=static:getName()
      local _size=self:_GetObjectSize(static)
      table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="static"})
    end

    -- Check all scenery.
    for _,scenery in pairs(_sceneries) do
      local _vec3=scenery:getPoint()
      local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=scenery:getTypeName()
      local _size=self:_GetObjectSize(scenery)
      table.insert(obstacles,{coord=_coord, size=_size, name=_name, type="scenery"})
    end
    
    -- TODO check clients. Clients cannot be spawned. So we can loop over them.

  end

  -- Parking data for all assets.
  local parking={}

  -- Get terminal type of this asset
  local terminaltype=self:_GetTerminal(ratcraft.attribute, airbase:GetAirbaseCategory())

  -- Loop over all units - each one needs a spot.
  --TODO: nunits should be counted from alive units.
  for i=1,ratcraft.nunits do

    -- Loop over all parking spots.
    local gotit=false
    for _,_parkingspot in pairs(parkingdata) do
      local parkingspot=_parkingspot --Wrapper.Airbase#AIRBASE.ParkingSpot

      -- Check correct terminal type for asset. We don't want helos in shelters etc.
      if AIRBASE._CheckTerminalType(parkingspot.TerminalType, terminaltype) then

        -- Coordinate of the parking spot.
        local _spot=parkingspot.Coordinate   -- Core.Point#COORDINATE
        local _termid=parkingspot.TerminalID
        local _toac=parkingspot.TOAC

        --env.info(string.format("FF asset=%s (id=%d): needs terminal type=%d, id=%d, #obstacles=%d", _asset.templatename, _asset.uid, terminaltype, _termid, #obstacles))

        local free=true
        local problem=nil

        -- Safe parking using TO_AC from DCS result.
        if self.safeparking and _toac then
          free=false
          self:T("Parking spot %d is occupied by other aircraft taking off or landing.", _termid)
        end

        -- Loop over all obstacles.
        for _,obstacle in pairs(obstacles) do

          -- Check if aircraft overlaps with any obstacle.
          local dist=_spot:Get2DDistance(obstacle.coord)
          -- TODO: ratcraft size!
          local safe=_overlap(ratcraft.size, obstacle.size, dist)

          -- Spot is blocked.
          if not safe then
            --env.info(string.format("FF asset=%s (id=%d): spot id=%d dist=%.1fm is NOT SAFE", _asset.templatename, _asset.uid, _termid, dist))
            free=false
            problem=obstacle
            problem.dist=dist
            break
          else
            --env.info(string.format("FF asset=%s (id=%d): spot id=%d dist=%.1fm is SAFE", _asset.templatename, _asset.uid, _termid, dist))
          end

        end

        -- Check if spot is free
        if free then

          -- Add parkingspot for this asset unit.
          table.insert(parking, parkingspot)

          self:T(self.wid..string.format("Parking spot #%d is free for ratcraft unit id=%d!", _termid, i))

          -- Add the unit as obstacle so that this spot will not be available for the next unit.
          -- TODO: ratcraft templatename.
          table.insert(obstacles, {coord=_spot, size=ratcraft.size, name=ratcraft.templatename, type="ratcraft"})

          -- Break loop over parking spots.
          gotit=true
          break

        else

          -- Debug output for occupied spots.
          self:T(self.wid..string.format("Parking spot #%d is occupied or not big enough!", _termid))
          if self.Debug then
            local coord=problem.coord --Core.Point#COORDINATE
            local text=string.format("Obstacle blocking spot #%d is %s type %s with size=%.1f m and distance=%.1f m.", _termid, problem.name, problem.type, problem.size, problem.dist)
            coord:MarkToAll(string.format(text))
          end

        end

      end -- check terminal type
    end -- loop over parking spots

    -- No parking spot for at least one unit :(
    if not gotit then
      self:T(self.wid..string.format("WARNING: No free parking spot for ratcraft unit i=%d", i))
      return nil
    end
    
  end -- loop over units

  return parking
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Flightplan functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Calculate the maximum height an aircraft can reach for the given parameters.
-- @param #RAT2 self
-- @param #number D Total distance in meters from Departure to holding point at destination.
-- @param #number alphaC Climb angle in rad.
-- @param #number alphaD Descent angle in rad.
-- @param #number Hdep AGL altitude of departure point.
-- @param #number Hdest AGL altitude of destination point.
-- @param #number Deltahhold Relative altitude of holding point above destination.
-- @return #number Maximum height the aircraft can reach.
function RAT2:_GetMaxHeight(D, alphaC, alphaD, Hdep, Hdest, Deltahhold)

  local Hhold=Hdest+Deltahhold
  local hdest=Hdest-Hdep
  local hhold=hdest+Deltahhold

  local Dp=math.sqrt(D^2 + hhold^2)

  local alphaS=math.atan(hdest/D) -- slope angle
  local alphaH=math.atan(hhold/D) -- angle to holding point (could be necative!)

  local alphaCp=alphaC-alphaH  -- climb angle with slope
  local alphaDp=alphaD+alphaH  -- descent angle with slope

  -- ASA triangle.
  local gammap=math.pi-alphaCp-alphaDp
  local sCp=Dp*math.sin(alphaDp)/math.sin(gammap)
  local sDp=Dp*math.sin(alphaCp)/math.sin(gammap)

  -- Max height from departure.
  local hmax=sCp*math.sin(alphaC)

  return hmax
end


--- Make a flight plan from a departure to a destination airport.
-- @param #RAT2 self
-- @param #RATAC ratcraft Ratcraft object.
-- @param Wrapper.Airbase#AIRBASE departure Departure airbase.
-- @param Wrapper.Airbase#AIRBASE destination Destination airbase.
-- @return #table Table of flightplan waypoints.
-- @return #table Table of flightplan coordinates.
function RAT2:_GetFlightplan(ratcraft, departure, destination)

  -- Parameters in SI units (m/s, m).
  local Vmax=ratcraft.speedmax/3.6
  local Range=ratcraft.range
  local category=ratcraft.category
  local ceiling=ratcraft.DCSdesc.Hmax
  local Vymax=ratcraft.DCSdesc.VyMax

  -- Max cruise speed 90% of max speed.
  local VxCruiseMax=0.90*Vmax

  -- Min cruise speed 70% of max cruise or 600 km/h whichever is lower.
  local VxCruiseMin = math.min(VxCruiseMax*0.70, 166)

  -- Cruise speed (randomized). Expectation value at midpoint between min and max.
  local VxCruise = UTILS.RandomGaussian((VxCruiseMax-VxCruiseMin)/2+VxCruiseMin, (VxCruiseMax-VxCruiseMax)/4, VxCruiseMin, VxCruiseMax)

  -- Climb speed 90% ov Vmax but max 720 km/h.
  local VxClimb = math.min(Vmax*0.90, 200)

  -- Descent speed 60% of Vmax but max 500 km/h.
  local VxDescent = math.min(Vmax*0.60, 140)

  -- Holding speed is 90% of descent speed.
  local VxHolding = VxDescent*0.9

  -- Final leg is 90% of holding speed.
  local VxFinal = VxHolding*0.9

  -- Reasonably civil climb speed Vy=1500 ft/min = 7.6 m/s but max aircraft specific climb rate.
  local VyClimb=math.min(7.6, Vymax)

  -- Climb angle in rad.
  --local AlphaClimb=math.asin(VyClimb/VxClimb)
  local AlphaClimb=math.rad(4)

  -- Descent angle in rad. Moderate 4 degrees.
  local AlphaDescent=math.rad(4)

  -- Expected cruise level (peak of Gaussian distribution)
  local FLcruise_expect=150*RAT.unit.FL2m
  if category==Group.Category.HELICOPTER then
    FLcruise_expect=1000 -- 1000 m ASL
  end

  -------------------------
  --- DEPARTURE AIRPORT ---
  -------------------------

  -- Coordinates of departure point.
  local Pdeparture=departure:GetCoordinate()

  -- Height ASL of departure point.
  local H_departure=Pdeparture.y

  ---------------------------
  --- DESTINATION AIRPORT ---
  ---------------------------

  -- Position of destination airport.
  local Pdestination=destination:GetCoordinate()

  -- Height ASL of destination airport/zone.
  local H_destination=Pdestination.y

  -----------------------------
  --- DESCENT/HOLDING POINT ---
  -----------------------------

  -- Get a random point between 5 and 10 km away from the destination.
  local Rhmin=5000
  local Rhmax=10000

  -- For helos we set a distance between 500 to 1000 m.
  if category==Group.Category.HELICOPTER then
    Rhmin=500
    Rhmax=1000
  end

  -- Coordinates of the holding point. y is the land height at that point.
  local Pholding=Pdestination:GetRandomCoordinateInRadius(Rhmax, Rhmin)

  -- Distance from holding point to final destination (not used).
  local d_holding=Pholding:Get2DDistance(Pdestination)

  -- AGL height of holding point.
  local H_holding=Pholding.y

  ---------------
  --- GENERAL ---
  ---------------

  -- We go directly to the holding point not the destination airport. From there, planes are guided by DCS to final approach.
  local heading=Pdeparture:HeadingTo(Pholding)
  local d_total=Pdeparture:Get2DDistance(Pholding)

  ------------------------------
  --- Holding Point Altitude ---
  ------------------------------

  -- Holding point altitude. For planes between 1600 and 2400 m AGL. For helos 160 to 240 m AGL.
  local h_holding=1200
  if category==Group.Category.HELICOPTER then
    h_holding=150
  end
  h_holding=UTILS.Randomize(h_holding, 0.2)

  -- Max holding altitude.
  local DeltaholdingMax=self:_GetMaxHeight(d_total, AlphaClimb, AlphaDescent, H_departure, H_holding, 0)

  if h_holding>DeltaholdingMax then
    h_holding=math.abs(DeltaholdingMax)
  end

  -- This is the height ASL of the holding point we want to fly to.
  local Hh_holding=H_holding+h_holding

  ---------------------------
  --- Max Flight Altitude ---
  ---------------------------

  -- Get max flight altitude relative to H_departure.
  local h_max=self:_GetMaxHeight(d_total, AlphaClimb, AlphaDescent, H_departure, H_holding, h_holding)

  -- Max flight level ASL aircraft can reach for given angles and distance.
  local FLmax = h_max+H_departure

  --CRUISE
  -- Min cruise alt is just above holding point at destination or departure height, whatever is larger.
  local FLmin=math.max(H_departure, Hh_holding)

  -- Ensure that FLmax not above its service ceiling.
  FLmax=math.min(FLmax, ceiling)

  -- If the route is very short we set FLmin a bit lower than FLmax.
  if FLmin>FLmax then
    FLmin=FLmax
  end

  -- Expected cruise altitude - peak of gaussian distribution.
  if FLcruise_expect<FLmin then
    FLcruise_expect=FLmin
  end
  if FLcruise_expect>FLmax then
    FLcruise_expect=FLmax
  end

  -- Set cruise altitude. Selected from Gaussian distribution but limited to FLmin and FLmax.
  local FLcruise=UTILS.RandomGaussian(FLcruise_expect, math.abs(FLmax-FLmin)/4, FLmin, FLmax)

  -- Climb and descent heights.
  local h_climb   = FLcruise - H_departure
  local h_descent = FLcruise - Hh_holding

  -- Get distances.
  local d_climb   = h_climb/math.tan(AlphaClimb)
  local d_descent = h_descent/math.tan(AlphaDescent)
  local d_cruise  = d_total-d_climb-d_descent

  -- Debug.
  local text=string.format("Flight plan:\n")
  text=text..string.format("Vx max        = %.2f km/h\n", Vmax*3.6)
  text=text..string.format("Vx climb      = %.2f km/h\n", VxClimb*3.6)
  text=text..string.format("Vx cruise     = %.2f km/h\n", VxCruise*3.6)
  text=text..string.format("Vx descent    = %.2f km/h\n", VxDescent*3.6)
  text=text..string.format("Vx holding    = %.2f km/h\n", VxHolding*3.6)
  text=text..string.format("Vx final      = %.2f km/h\n", VxFinal*3.6)
  text=text..string.format("Vy max        = %.2f m/s\n",  Vymax)
  text=text..string.format("Vy climb      = %.2f m/s\n",  VyClimb)
  text=text..string.format("Alpha Climb   = %.2f Deg\n",  math.deg(AlphaClimb))
  text=text..string.format("Alpha Descent = %.2f Deg\n",  math.deg(AlphaDescent))
  text=text..string.format("Dist climb    = %.3f km\n",   d_climb/1000)
  text=text..string.format("Dist cruise   = %.3f km\n",   d_cruise/1000)
  text=text..string.format("Dist descent  = %.3f km\n",   d_descent/1000)
  text=text..string.format("Dist total    = %.3f km\n",   d_total/1000)
  text=text..string.format("h_climb       = %.3f km\n",   h_climb/1000)
  text=text..string.format("h_desc        = %.3f km\n",   h_descent/1000)
  text=text..string.format("h_holding     = %.3f km\n",   h_holding/1000)
  text=text..string.format("h_max         = %.3f km\n",   h_max/1000)
  text=text..string.format("FL min        = %.3f km\n",   FLmin/1000)
  text=text..string.format("FL expect     = %.3f km\n",   FLcruise_expect/1000)
  text=text..string.format("FL cruise *   = %.3f km\n",   FLcruise/1000)
  text=text..string.format("FL max        = %.3f km\n",   FLmax/1000)
  text=text..string.format("Ceiling       = %.3f km\n",   ceiling/1000)
  text=text..string.format("Max range     = %.3f km\n",   Range/1000)
  self:T(self.wid..text)

  -- Ensure that cruise distance is positve. Can be slightly negative in special cases. And we don't want to turn back.
  if d_cruise<0 then
    d_cruise=100
  end

  ------------------------
  --- Create Waypoints ---
  ------------------------

  -- Waypoints and coordinates
  local wp={}
  local c={}

  --- Departure/Take-off
  c[#c+1]=Pdeparture
  wp[#wp+1]=Pdeparture:WaypointAir("RADIO", COORDINATE.WaypointType.TakeOffParking, COORDINATE.WaypointAction.FromParkingArea, VxClimb, true, departure, nil, "Departure")

  --- Begin of Cruise
  local Pcruise=Pdeparture:Translate(d_climb, heading)
  Pcruise.y=FLcruise
  c[#c+1]=Pcruise
  wp[#wp+1]=Pcruise:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxCruise, true, nil, nil, "Cruise")

  --- Descent
  local Pdescent=Pcruise:Translate(d_cruise, heading)
  Pdescent.y=FLcruise
  c[#c+1]=Pdescent
  wp[#wp+1]=Pdescent:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxDescent, true, nil, nil, "Descent")

  --- Holding point
  Pholding.y=H_holding+h_holding
  c[#c+1]=Pholding
  wp[#wp+1]=Pholding:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxHolding, true, nil, nil, "Holding")

  --- Final destination.
  c[#c+1]=Pdestination
  wp[#wp+1]=Pdestination:WaypointAir("RADIO", COORDINATE.WaypointType.Land, COORDINATE.WaypointAction.Landing, VxFinal, true,  destination, nil, "Final Destination")


  -- Mark points at waypoints for debugging.
  if self.Debug then
    for i,coord in pairs(c) do
      local coord=coord --Core.Point#COORDINATE
      local dist=0
      if i>1 then
        dist=coord:Get2DDistance(c[i-1])
      end
      coord:MarkToAll(string.format("Waypoint %i, distance = %.2f km",i, dist/1000))
    end
  end

  return wp,c
end




