--- **Functional** - Monitor airbase traffic and regulate speed while taxiing.
--
-- ===
--
-- ## Features:
-- 
--   * Monitor speed of the airplanes of players during taxi.
--   * Communicate ATC ground operations.
--   * Kick speeding players during taxi.
-- 
-- ===
-- 
-- ## Missions:
-- 
-- [ABP - Airbase Police](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/ABP%20-%20Airbase%20Police)
--
-- ===
--
-- ### Contributions: Dutch Baron - Concept & Testing
-- ### Author: FlightControl - Framework Design &  Programming
-- ### Refactoring to use the Runway auto-detection: Applevangelist
-- @date August 2022
--
-- ===
-- 
-- @module Functional.ATC_Ground
-- @image Air_Traffic_Control_Ground_Operations.JPG

--- @type ATC_GROUND
-- @field Core.Set#SET_CLIENT SetClient
-- @extends Core.Base#BASE

--- [DEPRECATED, use ATC_GROUND_UNIVERSAL] Base class for ATC\_GROUND implementations.
-- @field #ATC_GROUND
ATC_GROUND = {
  ClassName = "ATC_GROUND",
  SetClient = nil,
  Airbases = nil,
  AirbaseNames = nil,
}

--- @type ATC_GROUND.AirbaseNames
-- @list <#string>


--- [DEPRECATED, use ATC_GROUND_UNIVERSAL] Creates a new ATC\_GROUND object.
-- @param #ATC_GROUND self
-- @param Airbases A table of Airbase Names.
-- @return #ATC_GROUND self
function ATC_GROUND:New( Airbases, AirbaseList )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() ) -- #ATC_GROUND
  self:E( { self.ClassName, Airbases } )

  self.Airbases = Airbases
  self.AirbaseList = AirbaseList
  
  self.SetClient = SET_CLIENT:New():FilterCategories( "plane" ):FilterStart()
  

  for AirbaseID, Airbase in pairs( self.Airbases ) do
    -- Specified ZoneBoundary is used if set or Airbase radius by default
    if Airbase.ZoneBoundary then
      Airbase.ZoneBoundary = ZONE_POLYGON_BASE:New( "Boundary " .. AirbaseID, Airbase.ZoneBoundary )
    else
      Airbase.ZoneBoundary = _DATABASE:FindAirbase( AirbaseID ):GetZone()
    end

    Airbase.ZoneRunways = {}
    if Airbase.PointsRunways then
      for PointsRunwayID, PointsRunway in pairs( Airbase.PointsRunways ) do
        Airbase.ZoneRunways[PointsRunwayID] = ZONE_POLYGON_BASE:New( "Runway " .. PointsRunwayID, PointsRunway )
      end
    end
    Airbase.Monitor = self.AirbaseList and false or true -- When AirbaseList is not given, monitor every Airbase, otherwise don't monitor any (yet). 
  end

  -- Now activate the monitoring for the airbases that need to be monitored.
  for AirbaseID, AirbaseName in pairs( self.AirbaseList or {} ) do
    self.Airbases[AirbaseName].Monitor = true
  end

  self.SetClient:ForEachClient(
    --- @param Wrapper.Client#CLIENT Client
    function( Client )
      Client:SetState( self, "Speeding", false )
      Client:SetState( self, "Warnings", 0)
      Client:SetState( self, "IsOffRunway", false )
      Client:SetState( self, "OffRunwayWarnings", 0 )
      Client:SetState( self, "Taxi", false )
    end
  )

  -- This is simple slot blocker is used on the server.  
  SSB = USERFLAG:New( "SSB" )
  SSB:Set( 100 )
  
  return self
end

--- Smoke the airbases runways.
-- @param #ATC_GROUND self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The color of the smoke around the runways.
-- @return #ATC_GROUND self
function ATC_GROUND:SmokeRunways( SmokeColor )

  for AirbaseID, Airbase in pairs( self.Airbases ) do
    for PointsRunwayID, PointsRunway in pairs( Airbase.PointsRunways ) do
      Airbase.ZoneRunways[PointsRunwayID]:SmokeZone( SmokeColor )
      end
  end
end

--- Set the maximum speed in meters per second (Mps) until the player gets kicked.
-- An airbase can be specified to set the kick speed for.
-- @param #ATC_GROUND self
-- @param #number KickSpeed The speed in Mps.
-- @param Wrapper.Airbase#AIRBASE Airbase (optional) The airbase to set the kick speed for.
-- @return #ATC_GROUND self
-- @usage
-- 
--   -- Declare Atc_Ground using one of those, depending on the map.
-- 
--   Atc_Ground = ATC_GROUND_CAUCAUS:New()
--   Atc_Ground = ATC_GROUND_NEVADA:New()
--   Atc_Ground = ATC_GROUND_NORMANDY:New()
--   Atc_Ground = ATC_GROUND_PERSIANGULF:New()
--   
--   -- Then use one of these methods...
-- 
--   Atc_Ground:SetKickSpeed( UTILS.KmphToMps( 80 ) ) -- Kick the players at 80 kilometers per hour
-- 
--   Atc_Ground:SetKickSpeed( UTILS.MiphToMps( 100 ) ) -- Kick the players at 100 miles per hour
-- 
--   Atc_Ground:SetKickSpeed( 24 ) -- Kick the players at 24 meters per second ( 24 * 3.6 = 86.4 kilometers per hour )
-- 
function ATC_GROUND:SetKickSpeed( KickSpeed, Airbase )

  if not Airbase then
    self.KickSpeed = KickSpeed
  else
    self.Airbases[Airbase].KickSpeed = KickSpeed
  end
  
  return self
end

--- Set the maximum speed in Kmph until the player gets kicked.
-- @param #ATC_GROUND self
-- @param #number KickSpeed Set the speed in Kmph.
-- @param Wrapper.Airbase#AIRBASE Airbase (optional) The airbase to set the kick speed for.
-- @return #ATC_GROUND self
-- 
--   Atc_Ground:SetKickSpeedKmph( 80 ) -- Kick the players at 80 kilometers per hour
-- 
function ATC_GROUND:SetKickSpeedKmph( KickSpeed, Airbase )

  self:SetKickSpeed( UTILS.KmphToMps( KickSpeed ), Airbase )
  
  return self
end

--- Set the maximum speed in Miph until the player gets kicked.
-- @param #ATC_GROUND self
-- @param #number KickSpeedMiph Set the speed in Mph.
-- @param Wrapper.Airbase#AIRBASE Airbase (optional) The airbase to set the kick speed for.
-- @return #ATC_GROUND self
-- 
--   Atc_Ground:SetKickSpeedMiph( 100 ) -- Kick the players at 100 miles per hour
-- 
function ATC_GROUND:SetKickSpeedMiph( KickSpeedMiph, Airbase )

  self:SetKickSpeed( UTILS.MiphToMps( KickSpeedMiph ), Airbase )
  
  return self
end


--- Set the maximum kick speed in meters per second (Mps) until the player gets kicked.
-- There are no warnings given if this speed is reached, and is to prevent players to take off from the airbase!
-- An airbase can be specified to set the maximum kick speed for.
-- @param #ATC_GROUND self
-- @param #number MaximumKickSpeed The speed in Mps.
-- @param Wrapper.Airbase#AIRBASE Airbase (optional) The airbase to set the kick speed for.
-- @return #ATC_GROUND self
-- @usage
-- 
--   -- Declare Atc_Ground using one of those, depending on the map.
-- 
--   Atc_Ground = ATC_GROUND_CAUCAUS:New()
--   Atc_Ground = ATC_GROUND_NEVADA:New()
--   Atc_Ground = ATC_GROUND_NORMANDY:New()
--   Atc_Ground = ATC_GROUND_PERSIANGULF:New()
--   
--   -- Then use one of these methods...
-- 
--   Atc_Ground:SetMaximumKickSpeed( UTILS.KmphToMps( 80 ) ) -- Kick the players at 80 kilometers per hour
-- 
--   Atc_Ground:SetMaximumKickSpeed( UTILS.MiphToMps( 100 ) ) -- Kick the players at 100 miles per hour
-- 
--   Atc_Ground:SetMaximumKickSpeed( 24 ) -- Kick the players at 24 meters per second ( 24 * 3.6 = 86.4 kilometers per hour )
-- 
function ATC_GROUND:SetMaximumKickSpeed( MaximumKickSpeed, Airbase )

  if not Airbase then
    self.MaximumKickSpeed = MaximumKickSpeed
  else
    self.Airbases[Airbase].MaximumKickSpeed = MaximumKickSpeed
  end
  
  return self
end

--- Set the maximum kick speed in kilometers per hour (Kmph) until the player gets kicked.
-- There are no warnings given if this speed is reached, and is to prevent players to take off from the airbase!
-- An airbase can be specified to set the maximum kick speed for.
-- @param #ATC_GROUND self
-- @param #number MaximumKickSpeed Set the speed in Kmph.
-- @param Wrapper.Airbase#AIRBASE Airbase (optional) The airbase to set the kick speed for.
-- @return #ATC_GROUND self
-- 
--   Atc_Ground:SetMaximumKickSpeedKmph( 150 ) -- Kick the players at 150 kilometers per hour
-- 
function ATC_GROUND:SetMaximumKickSpeedKmph( MaximumKickSpeed, Airbase )

  self:SetMaximumKickSpeed( UTILS.KmphToMps( MaximumKickSpeed ), Airbase )
  
  return self
end

--- Set the maximum kick speed in miles per hour (Miph) until the player gets kicked.
-- There are no warnings given if this speed is reached, and is to prevent players to take off from the airbase!
-- An airbase can be specified to set the maximum kick speed for.
-- @param #ATC_GROUND self
-- @param #number MaximumKickSpeedMiph Set the speed in Mph.
-- @param Wrapper.Airbase#AIRBASE Airbase (optional) The airbase to set the kick speed for.
-- @return #ATC_GROUND self
-- 
--   Atc_Ground:SetMaximumKickSpeedMiph( 100 ) -- Kick the players at 100 miles per hour
-- 
function ATC_GROUND:SetMaximumKickSpeedMiph( MaximumKickSpeedMiph, Airbase )

  self:SetMaximumKickSpeed( UTILS.MiphToMps( MaximumKickSpeedMiph ), Airbase )
  
  return self
end

--- @param #ATC_GROUND self
function ATC_GROUND:_AirbaseMonitor()

  self.SetClient:ForEachClient(
    --- @param Wrapper.Client#CLIENT Client
    function( Client )

      if Client:IsAlive() then

        local IsOnGround = Client:InAir() == false

        for AirbaseID, AirbaseMeta in pairs( self.Airbases ) do
          self:E( AirbaseID, AirbaseMeta.KickSpeed )
  
          if AirbaseMeta.Monitor == true and Client:IsInZone( AirbaseMeta.ZoneBoundary )  then

            local NotInRunwayZone = true
            for ZoneRunwayID, ZoneRunway in pairs( AirbaseMeta.ZoneRunways ) do
              NotInRunwayZone = ( Client:IsNotInZone( ZoneRunway ) == true ) and NotInRunwayZone or false
            end

            if NotInRunwayZone then
              
              if IsOnGround then
                local Taxi = Client:GetState( self, "Taxi" )
                self:E( Taxi )
                if Taxi == false then
                  local Velocity = VELOCITY:New( AirbaseMeta.KickSpeed or self.KickSpeed )
                  Client:Message( "Welcome to " .. AirbaseID .. ". The maximum taxiing speed is " .. 
                                  Velocity:ToString() , 20, "ATC" )
                  Client:SetState( self, "Taxi", true )
                end
  
                -- TODO: GetVelocityKMH function usage
                local Velocity = VELOCITY_POSITIONABLE:New( Client )
                --MESSAGE:New( "Velocity = " .. Velocity:ToString(), 1 ):ToAll()
                local IsAboveRunway = Client:IsAboveRunway()
                self:T( IsAboveRunway, IsOnGround )
  
                if IsOnGround then
                  local Speeding = false
                  if AirbaseMeta.MaximumKickSpeed then 
                    if Velocity:Get() > AirbaseMeta.MaximumKickSpeed then
                      Speeding = true
                    end
                  else
                    if Velocity:Get() > self.MaximumKickSpeed then
                      Speeding = true
                    end
                  end
                  if Speeding == true then
                    MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. 
                                 " has been kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
                    Client:Destroy()
                    Client:SetState( self, "Speeding", false )
                    Client:SetState( self, "Warnings", 0 )
                  end
                end                  
                  
  
                if IsOnGround then
  
                  local Speeding = false
                  if AirbaseMeta.KickSpeed then -- If there is a speed defined for the airbase, use that only.
                    if Velocity:Get() > AirbaseMeta.KickSpeed then
                      Speeding = true
                    end
                  else
                    if Velocity:Get() > self.KickSpeed then
                      Speeding = true
                    end
                  end
                  if Speeding == true then  
                    local IsSpeeding = Client:GetState( self, "Speeding" )
  
                    if IsSpeeding == true then
                      local SpeedingWarnings = Client:GetState( self, "Warnings" )
                      self:T( SpeedingWarnings )
  
                      if SpeedingWarnings <= 3 then
                        Client:Message( "Warning " .. SpeedingWarnings .. "/3! Airbase traffic rule violation! Slow down now! Your speed is " .. 
                                        Velocity:ToString(), 5, "ATC" )
                        Client:SetState( self, "Warnings", SpeedingWarnings + 1 )
                      else
                        MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. " has been kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
                        --- @param Wrapper.Client#CLIENT Client
                        Client:Destroy()
                        Client:SetState( self, "Speeding", false )
                        Client:SetState( self, "Warnings", 0 )
                      end
  
                    else
                      Client:Message( "Attention! You are speeding on the taxiway, slow down! Your speed is " .. 
                                      Velocity:ToString(), 5, "ATC" )
                      Client:SetState( self, "Speeding", true )
                      Client:SetState( self, "Warnings", 1 )
                    end
  
                  else
                    Client:SetState( self, "Speeding", false )
                    Client:SetState( self, "Warnings", 0 )
                  end
                end

                if IsOnGround and not IsAboveRunway then
  
                  local IsOffRunway = Client:GetState( self, "IsOffRunway" )
  
                  if IsOffRunway == true then
                    local OffRunwayWarnings = Client:GetState( self, "OffRunwayWarnings" )
                    self:T( OffRunwayWarnings )
  
                    if OffRunwayWarnings <= 3 then
                      Client:Message( "Warning " .. OffRunwayWarnings .. "/3! Airbase traffic rule violation! Get back on the taxi immediately!", 5, "ATC" )
                      Client:SetState( self, "OffRunwayWarnings", OffRunwayWarnings + 1 )
                    else
                      MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. " has been kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
                      --- @param Wrapper.Client#CLIENT Client
                      Client:Destroy()
                      Client:SetState( self, "IsOffRunway", false )
                      Client:SetState( self, "OffRunwayWarnings", 0 )
                    end
                  else
                    Client:Message( "Attention! You are off the taxiway. Get back on the taxiway immediately!", 5, "ATC" )
                    Client:SetState( self, "IsOffRunway", true )
                    Client:SetState( self, "OffRunwayWarnings", 1 )
                  end
  
                else
                  Client:SetState( self, "IsOffRunway", false )
                  Client:SetState( self, "OffRunwayWarnings", 0 )
                end
              end
            else
              Client:SetState( self, "Speeding", false )
              Client:SetState( self, "Warnings", 0 )
              Client:SetState( self, "IsOffRunway", false )
              Client:SetState( self, "OffRunwayWarnings", 0 )
              local Taxi = Client:GetState( self, "Taxi" )
              if Taxi == true then
                Client:Message( "You have progressed to the runway ... Await take-off clearance ...", 20, "ATC" )
                Client:SetState( self, "Taxi", false )
              end
            end
          end
        end
      else
        Client:SetState( self, "Taxi", false )
      end
    end
  )

  return true
end

---
-- @type ATC_GROUND_UNIVERSAL
-- @field Core.Set#SET_CLIENT SetClient
-- @field #string Version
-- @field #string ClassName
-- @field #table Airbases
-- @field #table AirbaseList
-- @field #number KickSpeed
-- @extends Core.Base#BASE

--- Base class for ATC\_GROUND\_UNIVERSAL implementations.
-- @field #ATC_GROUND_UNIVERSAL
ATC_GROUND_UNIVERSAL = {
  ClassName = "ATC_GROUND_UNIVERSAL",
  Version = "0.0.1",
  SetClient = nil,
  Airbases = nil,
  AirbaseList = nil,
  KickSpeed = nil, -- The maximum speed in meters per second for all airbases until a player gets kicked. This is overridden at each derived class.
}

--- Creates a new ATC\_GROUND\_UNIVERSAL object. This works on any map.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param AirbaseList (Optional) A table of Airbase Names.
-- @return #ATC_GROUND_UNIVERSAL self
function ATC_GROUND_UNIVERSAL:New(AirbaseList)

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() ) -- #ATC_GROUND
  self:E( { self.ClassName } )

  self.Airbases = {}

  for _name,_ in pairs(_DATABASE.AIRBASES) do
    self.Airbases[_name]={}  
  end
  
  self.AirbaseList = AirbaseList
  
  self.SetClient = SET_CLIENT:New():FilterCategories( "plane" ):FilterStart()
  

  for AirbaseID, Airbase in pairs( self.Airbases ) do
    -- Specified ZoneBoundary is used if set or Airbase radius by default
    if Airbase.ZoneBoundary then
      Airbase.ZoneBoundary = ZONE_POLYGON_BASE:New( "Boundary " .. AirbaseID, Airbase.ZoneBoundary )
    else
      Airbase.ZoneBoundary = _DATABASE:FindAirbase( AirbaseID ):GetZone()
    end

    Airbase.ZoneRunways = AIRBASE:FindByName(AirbaseID):GetRunways()
    Airbase.Monitor = self.AirbaseList and false or true -- When AirbaseList is not given, monitor every Airbase, otherwise don't monitor any (yet). 
  end

  -- Now activate the monitoring for the airbases that need to be monitored.
  for AirbaseID, AirbaseName in pairs( self.AirbaseList or {} ) do
    self.Airbases[AirbaseName].Monitor = true
  end

  self.SetClient:ForEachClient(
    --- @param Wrapper.Client#CLIENT Client
    function( Client )
      Client:SetState( self, "Speeding", false )
      Client:SetState( self, "Warnings", 0)
      Client:SetState( self, "IsOffRunway", false )
      Client:SetState( self, "OffRunwayWarnings", 0 )
      Client:SetState( self, "Taxi", false )
    end
  )

  -- This is simple slot blocker is used on the server.  
  SSB = USERFLAG:New( "SSB" )
  SSB:Set( 100 )
  
  -- Kickspeed
  self.KickSpeed = UTILS.KnotsToMps(10)
  self:SetMaximumKickSpeedMiph(30)
  
  return self
end


--- Add a specific Airbase Boundary if you don't want to use the round zone that is auto-created.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #string Airbase The name of the Airbase
-- @param Core.Zone#ZONE Zone The ZONE object to be used, e.g. a ZONE_POLYGON
-- @return #ATC_GROUND_UNIVERSAL self
function ATC_GROUND_UNIVERSAL:SetAirbaseBoundaries(Airbase, Zone)
  self.Airbases[Airbase].ZoneBoundary = Zone
  return self
end

--- Smoke the airbases runways.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The color of the smoke around the runways.
-- @return #ATC_GROUND_UNIVERSAL self
function ATC_GROUND_UNIVERSAL:SmokeRunways( SmokeColor )
  
  local SmokeColor = SmokeColor or SMOKECOLOR.Red
  for AirbaseID, Airbase in pairs( self.Airbases ) do
    if Airbase.ZoneRunways then
      for _,_runwaydata in pairs (Airbase.ZoneRunways) do
        local runwaydata = _runwaydata -- Wrapper.Airbase#AIRBASE.Runway
        runwaydata.zone:SmokeZone(SmokeColor)
      end
    end
  end
  
  return self
end

--- Draw the airbases runways.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #table Color The color of the line around the runways, in RGB, e.g `{1,0,0}` for red.
-- @return #ATC_GROUND_UNIVERSAL self
function ATC_GROUND_UNIVERSAL:DrawRunways( Color )
  
  local Color = Color or {1,0,0}
  for AirbaseID, Airbase in pairs( self.Airbases ) do
    if Airbase.ZoneRunways then
      for _,_runwaydata in pairs (Airbase.ZoneRunways) do
        local runwaydata = _runwaydata -- Wrapper.Airbase#AIRBASE.Runway
        runwaydata.zone:DrawZone(-1,Color)
      end
    end
  end
  
  return self
end

--- Draw the airbases boundaries.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #table Color The color of the line around the runways, in RGB, e.g `{1,0,0}` for red.
-- @return #ATC_GROUND_UNIVERSAL self
function ATC_GROUND_UNIVERSAL:DrawBoundaries( Color )
  
  local Color = Color or {1,0,0}
  for AirbaseID, Airbase in pairs( self.Airbases ) do
    if Airbase.ZoneBoundary then
       Airbase.ZoneBoundary:DrawZone(-1, Color) 
    end
  end
  
  return self
end

--- Set the maximum speed in meters per second (Mps) until the player gets kicked.
-- An airbase can be specified to set the kick speed for.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #number KickSpeed The speed in Mps.
-- @param #string Airbase (optional) The airbase name to set the kick speed for.
-- @return #ATC_GROUND_UNIVERSAL self
-- @usage
-- 
--   -- Declare Atc_Ground
-- 
--   Atc_Ground = ATC_GROUND_UNIVERSAL:New()
--   
--   -- Then use one of these methods...
-- 
--   Atc_Ground:SetKickSpeed( UTILS.KmphToMps( 80 ) ) -- Kick the players at 80 kilometers per hour
-- 
--   Atc_Ground:SetKickSpeed( UTILS.MiphToMps( 100 ) ) -- Kick the players at 100 miles per hour
-- 
--   Atc_Ground:SetKickSpeed( 24 ) -- Kick the players at 24 meters per second ( 24 * 3.6 = 86.4 kilometers per hour )
-- 
function ATC_GROUND_UNIVERSAL:SetKickSpeed( KickSpeed, Airbase )

  if not Airbase then
    self.KickSpeed = KickSpeed
  else
    self.Airbases[Airbase].KickSpeed = KickSpeed
  end
  
  return self
end

--- Set the maximum speed in Kmph until the player gets kicked.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #number KickSpeed Set the speed in Kmph.
-- @param #string Airbase (optional) The airbase name to set the kick speed for.
-- @return #ATC_GROUND_UNIVERSAL self
-- 
--   Atc_Ground:SetKickSpeedKmph( 80 ) -- Kick the players at 80 kilometers per hour
-- 
function ATC_GROUND_UNIVERSAL:SetKickSpeedKmph( KickSpeed, Airbase )

  self:SetKickSpeed( UTILS.KmphToMps( KickSpeed ), Airbase )
  
  return self
end

--- Set the maximum speed in Miph until the player gets kicked.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #number KickSpeedMiph Set the speed in Mph.
-- @param #string Airbase (optional) The airbase name to set the kick speed for.
-- @return #ATC_GROUND_UNIVERSAL self
-- 
--   Atc_Ground:SetKickSpeedMiph( 100 ) -- Kick the players at 100 miles per hour
-- 
function ATC_GROUND_UNIVERSAL:SetKickSpeedMiph( KickSpeedMiph, Airbase )

  self:SetKickSpeed( UTILS.MiphToMps( KickSpeedMiph ), Airbase )
  
  return self
end


--- Set the maximum kick speed in meters per second (Mps) until the player gets kicked.
-- There are no warnings given if this speed is reached, and is to prevent players to take off from the airbase!
-- An airbase can be specified to set the maximum kick speed for.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #number MaximumKickSpeed The speed in Mps.
-- @param #string Airbase (optional) The airbase name to set the kick speed for.
-- @return #ATC_GROUND_UNIVERSAL self
-- @usage
-- 
--   -- Declare Atc_Ground
-- 
--   Atc_Ground = ATC_GROUND_UNIVERSAL:New()
--   
--   -- Then use one of these methods...
-- 
--   Atc_Ground:SetMaximumKickSpeed( UTILS.KmphToMps( 80 ) ) -- Kick the players at 80 kilometers per hour
-- 
--   Atc_Ground:SetMaximumKickSpeed( UTILS.MiphToMps( 100 ) ) -- Kick the players at 100 miles per hour
-- 
--   Atc_Ground:SetMaximumKickSpeed( 24 ) -- Kick the players at 24 meters per second ( 24 * 3.6 = 86.4 kilometers per hour )
-- 
function ATC_GROUND_UNIVERSAL:SetMaximumKickSpeed( MaximumKickSpeed, Airbase )

  if not Airbase then
    self.MaximumKickSpeed = MaximumKickSpeed
  else
    self.Airbases[Airbase].MaximumKickSpeed = MaximumKickSpeed
  end
  
  return self
end

--- Set the maximum kick speed in kilometers per hour (Kmph) until the player gets kicked.
-- There are no warnings given if this speed is reached, and is to prevent players to take off from the airbase!
-- An airbase can be specified to set the maximum kick speed for.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #number MaximumKickSpeed Set the speed in Kmph.
-- @param #string Airbase (optional) The airbase name to set the kick speed for.
-- @return #ATC_GROUND_UNIVERSAL self
-- 
--   Atc_Ground:SetMaximumKickSpeedKmph( 150 ) -- Kick the players at 150 kilometers per hour
-- 
function ATC_GROUND_UNIVERSAL:SetMaximumKickSpeedKmph( MaximumKickSpeed, Airbase )

  self:SetMaximumKickSpeed( UTILS.KmphToMps( MaximumKickSpeed ), Airbase )
  
  return self
end

--- Set the maximum kick speed in miles per hour (Miph) until the player gets kicked.
-- There are no warnings given if this speed is reached, and is to prevent players to take off from the airbase!
-- An airbase can be specified to set the maximum kick speed for.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param #number MaximumKickSpeedMiph Set the speed in Mph.
-- @param #string Airbase (optional) The airbase name to set the kick speed for.
-- @return #ATC_GROUND_UNIVERSAL self
-- 
--   Atc_Ground:SetMaximumKickSpeedMiph( 100 ) -- Kick the players at 100 miles per hour
-- 
function ATC_GROUND_UNIVERSAL:SetMaximumKickSpeedMiph( MaximumKickSpeedMiph, Airbase )

  self:SetMaximumKickSpeed( UTILS.MiphToMps( MaximumKickSpeedMiph ), Airbase )
  
  return self
end

--- [Internal] Monitoring function
-- @param #ATC_GROUND_UNIVERSAL self
-- @return #ATC_GROUND_UNIVERSAL self
function ATC_GROUND_UNIVERSAL:_AirbaseMonitor()

  self.SetClient:ForEachClient(
    --- @param Wrapper.Client#CLIENT Client
    function( Client )

      if Client:IsAlive() then

        local IsOnGround = Client:InAir() == false

        for AirbaseID, AirbaseMeta in pairs( self.Airbases ) do
          self:E( AirbaseID, AirbaseMeta.KickSpeed )
  
          if AirbaseMeta.Monitor == true and Client:IsInZone( AirbaseMeta.ZoneBoundary )  then

            local NotInRunwayZone = true
            
            if AirbaseMeta.ZoneRunways then
              for _,_runwaydata in pairs (AirbaseMeta.ZoneRunways) do
                local runwaydata = _runwaydata -- Wrapper.Airbase#AIRBASE.Runway
                  NotInRunwayZone = ( Client:IsNotInZone( _runwaydata.zone ) == true ) and NotInRunwayZone or false
              end
            end

            if NotInRunwayZone then
              
              if IsOnGround then
                local Taxi = Client:GetState( self, "Taxi" )
                self:E( Taxi )
                if Taxi == false then
                  local Velocity = VELOCITY:New( AirbaseMeta.KickSpeed or self.KickSpeed )
                  Client:Message( "Welcome to " .. AirbaseID .. ". The maximum taxiing speed is " .. 
                                  Velocity:ToString() , 20, "ATC" )
                  Client:SetState( self, "Taxi", true )
                end
  
                -- TODO: GetVelocityKMH function usage
                local Velocity = VELOCITY_POSITIONABLE:New( Client )
                --MESSAGE:New( "Velocity = " .. Velocity:ToString(), 1 ):ToAll()
                local IsAboveRunway = Client:IsAboveRunway()
                self:T( {IsAboveRunway, IsOnGround, Velocity:Get() })
  
                if IsOnGround then
                  local Speeding = false
                  if AirbaseMeta.MaximumKickSpeed then 
                    if Velocity:Get() > AirbaseMeta.MaximumKickSpeed then
                      Speeding = true
                    end
                  else
                    if Velocity:Get() > self.MaximumKickSpeed then
                      Speeding = true
                    end
                  end
                  if Speeding == true then
                    MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. 
                                 " has been kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
                    Client:Destroy()
                    Client:SetState( self, "Speeding", false )
                    Client:SetState( self, "Warnings", 0 )
                  end
                end                  
                  
  
                if IsOnGround then
  
                  local Speeding = false
                  if AirbaseMeta.KickSpeed then -- If there is a speed defined for the airbase, use that only.
                    if Velocity:Get() > AirbaseMeta.KickSpeed then
                      Speeding = true
                    end
                  else
                    if Velocity:Get() > self.KickSpeed then
                      Speeding = true
                    end
                  end
                  if Speeding == true then  
                    local IsSpeeding = Client:GetState( self, "Speeding" )
  
                    if IsSpeeding == true then
                      local SpeedingWarnings = Client:GetState( self, "Warnings" )
                      self:T( SpeedingWarnings )
  
                      if SpeedingWarnings <= 3 then
                        Client:Message( "Warning " .. SpeedingWarnings .. "/3! Airbase traffic rule violation! Slow down now! Your speed is " .. 
                                        Velocity:ToString(), 5, "ATC" )
                        Client:SetState( self, "Warnings", SpeedingWarnings + 1 )
                      else
                        MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. " has been kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
                        --- @param Wrapper.Client#CLIENT Client
                        Client:Destroy()
                        Client:SetState( self, "Speeding", false )
                        Client:SetState( self, "Warnings", 0 )
                      end
  
                    else
                      Client:Message( "Attention! You are speeding on the taxiway, slow down! Your speed is " .. 
                                      Velocity:ToString(), 5, "ATC" )
                      Client:SetState( self, "Speeding", true )
                      Client:SetState( self, "Warnings", 1 )
                    end
  
                  else
                    Client:SetState( self, "Speeding", false )
                    Client:SetState( self, "Warnings", 0 )
                  end
                end

                if IsOnGround and not IsAboveRunway then
  
                  local IsOffRunway = Client:GetState( self, "IsOffRunway" )
  
                  if IsOffRunway == true then
                    local OffRunwayWarnings = Client:GetState( self, "OffRunwayWarnings" )
                    self:T( OffRunwayWarnings )
  
                    if OffRunwayWarnings <= 3 then
                      Client:Message( "Warning " .. OffRunwayWarnings .. "/3! Airbase traffic rule violation! Get back on the taxi immediately!", 5, "ATC" )
                      Client:SetState( self, "OffRunwayWarnings", OffRunwayWarnings + 1 )
                    else
                      MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. " has been kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
                      --- @param Wrapper.Client#CLIENT Client
                      Client:Destroy()
                      Client:SetState( self, "IsOffRunway", false )
                      Client:SetState( self, "OffRunwayWarnings", 0 )
                    end
                  else
                    Client:Message( "Attention! You are off the taxiway. Get back on the taxiway immediately!", 5, "ATC" )
                    Client:SetState( self, "IsOffRunway", true )
                    Client:SetState( self, "OffRunwayWarnings", 1 )
                  end
  
                else
                  Client:SetState( self, "IsOffRunway", false )
                  Client:SetState( self, "OffRunwayWarnings", 0 )
                end
              end
            else
              Client:SetState( self, "Speeding", false )
              Client:SetState( self, "Warnings", 0 )
              Client:SetState( self, "IsOffRunway", false )
              Client:SetState( self, "OffRunwayWarnings", 0 )
              local Taxi = Client:GetState( self, "Taxi" )
              if Taxi == true then
                Client:Message( "You have progressed to the runway ... Await take-off clearance ...", 20, "ATC" )
                Client:SetState( self, "Taxi", false )
              end
            end
          end
        end
      else
        Client:SetState( self, "Taxi", false )
      end
    end
  )

  return true
end

--- Start SCHEDULER for ATC_GROUND_UNIVERSAL object.
-- @param #ATC_GROUND_UNIVERSAL self
-- @param RepeatScanSeconds Time in second for defining occurency of alerts.
-- @return #ATC_GROUND_UNIVERSAL self
function ATC_GROUND_UNIVERSAL:Start( RepeatScanSeconds )
  RepeatScanSeconds = RepeatScanSeconds or 0.05
  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, RepeatScanSeconds )
  return self
end

--- @type ATC_GROUND_CAUCASUS
-- @extends #ATC_GROUND

--- # ATC\_GROUND\_CAUCASUS, extends @{#ATC_GROUND_UNIVERSAL}
-- 
-- The ATC\_GROUND\_CAUCASUS class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- ---
--
-- ![Banner Image](..\Presentations\ATC_GROUND\Dia1.JPG)
--
-- ---
--  
-- The default maximum speed for the airbases at Caucasus is **50 km/h**. Warnings are given if this speed limit is trespassed.
-- Players will be immediately kicked when driving faster than **150 km/h** on the taxi way.
-- 
-- 
-- The pilot will receive 3 times a warning during speeding. After the 3rd warning, if the pilot is still driving
-- faster than the maximum allowed speed, the pilot will be kicked.
-- 
-- Different airbases have different maximum speeds, according safety regulations.
-- 
-- # Airbases monitored
-- 
-- The following airbases are monitored at the Caucasus region.
-- Use the @{Wrapper.Airbase#AIRBASE.Caucasus} enumeration to select the airbases to be monitored.
-- 
--   * `AIRBASE.Caucasus.Anapa_Vityazevo`
--   * `AIRBASE.Caucasus.Batumi`
--   * `AIRBASE.Caucasus.Beslan`
--   * `AIRBASE.Caucasus.Gelendzhik`
--   * `AIRBASE.Caucasus.Gudauta`
--   * `AIRBASE.Caucasus.Kobuleti`
--   * `AIRBASE.Caucasus.Krasnodar_Center`
--   * `AIRBASE.Caucasus.Krasnodar_Pashkovsky`
--   * `AIRBASE.Caucasus.Krymsk`
--   * `AIRBASE.Caucasus.Kutaisi`
--   * `AIRBASE.Caucasus.Maykop_Khanskaya`
--   * `AIRBASE.Caucasus.Mineralnye_Vody`
--   * `AIRBASE.Caucasus.Mozdok`
--   * `AIRBASE.Caucasus.Nalchik`
--   * `AIRBASE.Caucasus.Novorossiysk`
--   * `AIRBASE.Caucasus.Senaki_Kolkhi`
--   * `AIRBASE.Caucasus.Sochi_Adler`
--   * `AIRBASE.Caucasus.Soganlug`
--   * `AIRBASE.Caucasus.Sukhumi_Babushara`
--   * `AIRBASE.Caucasus.Tbilisi_Lochini`
--   * `AIRBASE.Caucasus.Vaziani`
--
-- 
-- # Installation
-- 
-- ## In Single Player Missions
-- 
-- ATC\_GROUND is fully functional in single player.
-- 
-- ## In Multi Player Missions
-- 
-- ATC\_GROUND is functional in multi player, however ...
-- 
-- Due to a bug in DCS since release 1.5, the despawning of clients are not anymore working in multi player.
-- To **work around this problem**, a much better solution has been made, using the **slot blocker** script designed
-- by Ciribob. 
-- 
-- With the help of __Ciribob__, this script has been extended to also kick client players while in flight.
-- ATC\_GROUND is communicating with this modified script to kick players!
-- 
-- Install the file **SimpleSlotBlockGameGUI.lua** on the server, following the installation instructions described by Ciribob.
-- 
-- [Simple Slot Blocker from Ciribob & FlightControl](https://github.com/ciribob/DCS-SimpleSlotBlock)
-- 
-- # Script it!
-- 
-- ## 1. ATC\_GROUND\_CAUCASUS Constructor
-- 
-- Creates a new ATC_GROUND_CAUCASUS object that will monitor pilots taxiing behaviour.
-- 
--     -- This creates a new ATC_GROUND_CAUCASUS object.
-- 
--     -- Monitor all the airbases.
--     ATC_Ground = ATC_GROUND_CAUCASUS:New()
--     
--     -- Monitor specific airbases only.
-- 
--     ATC_Ground = ATC_GROUND_CAUCASUS:New(
--       { AIRBASE.Caucasus.Gelendzhik,     
--         AIRBASE.Caucasus.Krymsk          
--       }                                  
--     )                                    
-- 
-- ## 2. Set various options
-- 
-- There are various methods that you can use to tweak the behaviour of the ATC\_GROUND classes.
-- 
-- ### 2.1 Speed limit at an airbase.
-- 
--   * @{#ATC_GROUND.SetKickSpeed}(): Set the speed limit allowed at an airbase in meters per second.
--   * @{#ATC_GROUND.SetKickSpeedKmph}(): Set the speed limit allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetKickSpeedMiph}(): Set the speed limit allowed at an airbase in miles per hour.
--   
-- ### 2.2 Prevent Takeoff at an airbase. Players will be kicked immediately.
-- 
--   * @{#ATC_GROUND.SetMaximumKickSpeed}(): Set the maximum speed allowed at an airbase in meters per second. 
--   * @{#ATC_GROUND.SetMaximumKickSpeedKmph}(): Set the maximum speed allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetMaximumKickSpeedMiph}(): Set the maximum speed allowed at an airbase in miles per hour.
--   
-- 
-- @field #ATC_GROUND_CAUCASUS
ATC_GROUND_CAUCASUS = {
  ClassName = "ATC_GROUND_CAUCASUS",
}

--- Creates a new ATC_GROUND_CAUCASUS object.
-- @param #ATC_GROUND_CAUCASUS self
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.Caucasus enumerator).
-- @return #ATC_GROUND_CAUCASUS self
function ATC_GROUND_CAUCASUS:New( AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, ATC_GROUND_UNIVERSAL:New(AirbaseNames) )

  self:SetKickSpeedKmph( 50 )
  self:SetMaximumKickSpeedKmph( 150 )

  return self
end


--- Start SCHEDULER for ATC_GROUND_CAUCASUS object.
-- @param #ATC_GROUND_CAUCASUS self
-- @param RepeatScanSeconds Time in second for defining occurency of alerts.
-- @return nothing
function ATC_GROUND_CAUCASUS:Start( RepeatScanSeconds )
  RepeatScanSeconds = RepeatScanSeconds or 0.05
  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, RepeatScanSeconds )
end



--- @type ATC_GROUND_NEVADA
-- @extends #ATC_GROUND


--- # ATC\_GROUND\_NEVADA, extends @{#ATC_GROUND}
-- 
-- The ATC\_GROUND\_NEVADA class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- ---
--
-- ![Banner Image](..\Presentations\ATC_GROUND\Dia1.JPG)
-- 
-- ---
-- 
-- The default maximum speed for the airbases at Nevada is **50 km/h**. Warnings are given if this speed limit is trespassed.
-- Players will be immediately kicked when driving faster than **150 km/h** on the taxi way.
-- 
-- The ATC\_GROUND\_NEVADA class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- The pilot will receive 3 times a warning during speeding. After the 3rd warning, if the pilot is still driving
-- faster than the maximum allowed speed, the pilot will be kicked.
-- 
-- Different airbases have different maximum speeds, according safety regulations.
-- 
-- # Airbases monitored
-- 
-- The following airbases are monitored at the Nevada region.
-- Use the @{Wrapper.Airbase#AIRBASE.Nevada} enumeration to select the airbases to be monitored.
-- 
--    * `AIRBASE.Nevada.Beatty_Airport`
--    * `AIRBASE.Nevada.Boulder_City_Airport`
--    * `AIRBASE.Nevada.Creech_AFB`
--    * `AIRBASE.Nevada.Echo_Bay`
--    * `AIRBASE.Nevada.Groom_Lake_AFB`
--    * `AIRBASE.Nevada.Henderson_Executive_Airport`
--    * `AIRBASE.Nevada.Jean_Airport`
--    * `AIRBASE.Nevada.Laughlin_Airport`
--    * `AIRBASE.Nevada.Lincoln_County`
--    * `AIRBASE.Nevada.McCarran_International_Airport`
--    * `AIRBASE.Nevada.Mesquite`
--    * `AIRBASE.Nevada.Mina_Airport`
--    * `AIRBASE.Nevada.Nellis_AFB`
--    * `AIRBASE.Nevada.North_Las_Vegas`
--    * `AIRBASE.Nevada.Pahute_Mesa_Airstrip`
--    * `AIRBASE.Nevada.Tonopah_Airport`
--    * `AIRBASE.Nevada.Tonopah_Test_Range_Airfield`
--
-- # Installation
-- 
-- ## In Single Player Missions
-- 
-- ATC\_GROUND is fully functional in single player.
-- 
-- ## In Multi Player Missions
-- 
-- ATC\_GROUND is functional in multi player, however ...
-- 
-- Due to a bug in DCS since release 1.5, the despawning of clients are not anymore working in multi player.
-- To **work around this problem**, a much better solution has been made, using the **slot blocker** script designed
-- by Ciribob. 
-- 
-- With the help of __Ciribob__, this script has been extended to also kick client players while in flight.
-- ATC\_GROUND is communicating with this modified script to kick players!
-- 
-- Install the file **SimpleSlotBlockGameGUI.lua** on the server, following the installation instructions described by Ciribob.
-- 
-- [Simple Slot Blocker from Ciribob & FlightControl](https://github.com/ciribob/DCS-SimpleSlotBlock)
-- 
-- # Script it!
-- 
-- ## 1. ATC_GROUND_NEVADA Constructor
-- 
-- Creates a new ATC_GROUND_NEVADA object that will monitor pilots taxiing behaviour.
-- 
--     -- This creates a new ATC_GROUND_NEVADA object.
-- 
--     -- Monitor all the airbases.
--     ATC_Ground = ATC_GROUND_NEVADA:New()
-- 
--    
--     -- Monitor specific airbases.
--     ATC_Ground = ATC_GROUND_NEVADA:New(              
--       { AIRBASE.Nevada.Laughlin_Airport,                        
--         AIRBASE.Nevada.Lincoln_County,               
--         AIRBASE.Nevada.North_Las_Vegas,              
--         AIRBASE.Nevada.McCarran_International_Airport
--       }                                              
--     )                                                
-- 
-- ## 2. Set various options
-- 
-- There are various methods that you can use to tweak the behaviour of the ATC\_GROUND classes.
-- 
-- ### 2.1 Speed limit at an airbase.
-- 
--   * @{#ATC_GROUND.SetKickSpeed}(): Set the speed limit allowed at an airbase in meters per second.
--   * @{#ATC_GROUND.SetKickSpeedKmph}(): Set the speed limit allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetKickSpeedMiph}(): Set the speed limit allowed at an airbase in miles per hour.
--   
-- ### 2.2 Prevent Takeoff at an airbase. Players will be kicked immediately.
-- 
--   * @{#ATC_GROUND.SetMaximumKickSpeed}(): Set the maximum speed allowed at an airbase in meters per second. 
--   * @{#ATC_GROUND.SetMaximumKickSpeedKmph}(): Set the maximum speed allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetMaximumKickSpeedMiph}(): Set the maximum speed allowed at an airbase in miles per hour.
-- 
--   
-- @field #ATC_GROUND_NEVADA
ATC_GROUND_NEVADA = {
  ClassName = "ATC_GROUND_NEVADA",
}

--- Creates a new ATC_GROUND_NEVADA object.
-- @param #ATC_GROUND_NEVADA self
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.Nevada enumerator).
-- @return #ATC_GROUND_NEVADA self
function ATC_GROUND_NEVADA:New( AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, ATC_GROUND_UNIVERSAL:New( AirbaseNames ) )

  self:SetKickSpeedKmph( 50 )
  self:SetMaximumKickSpeedKmph( 150 )

  return self
end

--- Start SCHEDULER for ATC_GROUND_NEVADA object.
-- @param #ATC_GROUND_NEVADA self
-- @param RepeatScanSeconds Time in second for defining occurency of alerts.
-- @return nothing
function ATC_GROUND_NEVADA:Start( RepeatScanSeconds )
  RepeatScanSeconds = RepeatScanSeconds or 0.05
  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, RepeatScanSeconds )
end


--- @type ATC_GROUND_NORMANDY
-- @extends #ATC_GROUND


--- # ATC\_GROUND\_NORMANDY, extends @{#ATC_GROUND}
-- 
-- The ATC\_GROUND\_NORMANDY class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- ---
-- 
-- ![Banner Image](..\Presentations\ATC_GROUND\Dia1.JPG)
-- 
-- ---
-- 
-- The default maximum speed for the airbases at Normandy is **40 km/h**. Warnings are given if this speed limit is trespassed.
-- Players will be immediately kicked when driving faster than **100 km/h** on the taxi way.
-- 
-- The ATC\_GROUND\_NORMANDY class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- The pilot will receive 3 times a warning during speeding. After the 3rd warning, if the pilot is still driving
-- faster than the maximum allowed speed, the pilot will be kicked.
-- 
-- Different airbases have different maximum speeds, according safety regulations.
-- 
-- # Airbases monitored
-- 
-- The following airbases are monitored at the Normandy region.
-- Use the @{Wrapper.Airbase#AIRBASE.Normandy} enumeration to select the airbases to be monitored.
-- 
--   * `AIRBASE.Normandy.Azeville`
--   * `AIRBASE.Normandy.Bazenville`
--   * `AIRBASE.Normandy.Beny_sur_Mer`
--   * `AIRBASE.Normandy.Beuzeville`
--   * `AIRBASE.Normandy.Biniville`
--   * `AIRBASE.Normandy.Brucheville`
--   * `AIRBASE.Normandy.Cardonville`
--   * `AIRBASE.Normandy.Carpiquet`
--   * `AIRBASE.Normandy.Chailey`
--   * `AIRBASE.Normandy.Chippelle`
--   * `AIRBASE.Normandy.Cretteville`
--   * `AIRBASE.Normandy.Cricqueville_en_Bessin`
--   * `AIRBASE.Normandy.Deux_Jumeaux`
--   * `AIRBASE.Normandy.Evreux`
--   * `AIRBASE.Normandy.Ford`
--   * `AIRBASE.Normandy.Funtington`
--   * `AIRBASE.Normandy.Lantheuil`
--   * `AIRBASE.Normandy.Le_Molay`
--   * `AIRBASE.Normandy.Lessay`
--   * `AIRBASE.Normandy.Lignerolles`
--   * `AIRBASE.Normandy.Longues_sur_Mer`
--   * `AIRBASE.Normandy.Maupertus`
--   * `AIRBASE.Normandy.Meautis`
--   * `AIRBASE.Normandy.Needs_Oar_Point`
--   * `AIRBASE.Normandy.Picauville`
--   * `AIRBASE.Normandy.Rucqueville`
--   * `AIRBASE.Normandy.Saint_Pierre_du_Mont`
--   * `AIRBASE.Normandy.Sainte_Croix_sur_Mer`
--   * `AIRBASE.Normandy.Sainte_Laurent_sur_Mer`
--   * `AIRBASE.Normandy.Sommervieu`
--   * `AIRBASE.Normandy.Tangmere`
--   * `AIRBASE.Normandy.Argentan`
--   * `AIRBASE.Normandy.Goulet`
--   * `AIRBASE.Normandy.Essay`
--   * `AIRBASE.Normandy.Hauterive`
--   * `AIRBASE.Normandy.Barville`
--   * `AIRBASE.Normandy.Conches`
--   * `AIRBASE.Normandy.Vrigny`
--
-- # Installation
-- 
-- ## In Single Player Missions
-- 
-- ATC\_GROUND is fully functional in single player.
-- 
-- ## In Multi Player Missions
-- 
-- ATC\_GROUND is functional in multi player, however ...
-- 
-- Due to a bug in DCS since release 1.5, the despawning of clients are not anymore working in multi player.
-- To **work around this problem**, a much better solution has been made, using the **slot blocker** script designed
-- by Ciribob. 
-- 
-- With the help of __Ciribob__, this script has been extended to also kick client players while in flight.
-- ATC\_GROUND is communicating with this modified script to kick players!
-- 
-- Install the file **SimpleSlotBlockGameGUI.lua** on the server, following the installation instructions described by Ciribob.
-- 
-- [Simple Slot Blocker from Ciribob & FlightControl](https://github.com/ciribob/DCS-SimpleSlotBlock)
-- 
-- # Script it!
-- 
-- ## 1. ATC_GROUND_NORMANDY Constructor
-- 
-- Creates a new ATC_GROUND_NORMANDY object that will monitor pilots taxiing behaviour.
-- 
--     -- This creates a new ATC_GROUND_NORMANDY object.
-- 
--     -- Monitor for these clients the airbases.
--     AirbasePoliceCaucasus = ATC_GROUND_NORMANDY:New()
--     
--     ATC_Ground = ATC_GROUND_NORMANDY:New( 
--       { AIRBASE.Normandy.Chippelle,
--         AIRBASE.Normandy.Beuzeville 
--       } 
--     )
-- 
--     
-- ## 2. Set various options
-- 
-- There are various methods that you can use to tweak the behaviour of the ATC\_GROUND classes.
-- 
-- ### 2.1 Speed limit at an airbase.
-- 
--   * @{#ATC_GROUND.SetKickSpeed}(): Set the speed limit allowed at an airbase in meters per second.
--   * @{#ATC_GROUND.SetKickSpeedKmph}(): Set the speed limit allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetKickSpeedMiph}(): Set the speed limit allowed at an airbase in miles per hour.
--   
-- ### 2.2 Prevent Takeoff at an airbase. Players will be kicked immediately.
-- 
--   * @{#ATC_GROUND.SetMaximumKickSpeed}(): Set the maximum speed allowed at an airbase in meters per second. 
--   * @{#ATC_GROUND.SetMaximumKickSpeedKmph}(): Set the maximum speed allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetMaximumKickSpeedMiph}(): Set the maximum speed allowed at an airbase in miles per hour.
--   
-- @field #ATC_GROUND_NORMANDY
ATC_GROUND_NORMANDY = {
  ClassName = "ATC_GROUND_NORMANDY", 
}


--- Creates a new ATC_GROUND_NORMANDY object.
-- @param #ATC_GROUND_NORMANDY self
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.Normandy enumerator).
-- @return #ATC_GROUND_NORMANDY self
function ATC_GROUND_NORMANDY:New( AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, ATC_GROUND_UNIVERSAL:New( AirbaseNames ) ) -- #ATC_GROUND_NORMANDY
  
  self:SetKickSpeedKmph( 40 )
  self:SetMaximumKickSpeedKmph( 100 )
  
  return self
end

     
--- Start SCHEDULER for ATC_GROUND_NORMANDY object.
-- @param #ATC_GROUND_NORMANDY self
-- @param RepeatScanSeconds Time in second for defining occurency of alerts.
-- @return nothing
function ATC_GROUND_NORMANDY:Start( RepeatScanSeconds )
  RepeatScanSeconds = RepeatScanSeconds or 0.05
  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, RepeatScanSeconds )
end

--- @type ATC_GROUND_PERSIANGULF
-- @extends #ATC_GROUND


--- # ATC\_GROUND\_PERSIANGULF, extends @{#ATC_GROUND}
-- 
-- The ATC\_GROUND\_PERSIANGULF class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- ---
-- 
-- ![Banner Image](..\Presentations\ATC_GROUND\Dia1.JPG)
-- 
-- ---
-- 
-- The default maximum speed for the airbases at Persian Gulf is **50 km/h**. Warnings are given if this speed limit is trespassed.
-- Players will be immediately kicked when driving faster than **150 km/h** on the taxi way.
-- 
-- The ATC\_GROUND\_PERSIANGULF class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- The pilot will receive 3 times a warning during speeding. After the 3rd warning, if the pilot is still driving
-- faster than the maximum allowed speed, the pilot will be kicked.
-- 
-- Different airbases have different maximum speeds, according safety regulations.
-- 
-- # Airbases monitored
-- 
-- The following airbases are monitored at the PersianGulf region.
-- Use the @{Wrapper.Airbase#AIRBASE.PersianGulf} enumeration to select the airbases to be monitored.
-- 
--   * `AIRBASE.PersianGulf.Abu_Musa_Island_Airport`
--   * `AIRBASE.PersianGulf.Al_Dhafra_AB`
--   * `AIRBASE.PersianGulf.Al_Maktoum_Intl`
--   * `AIRBASE.PersianGulf.Al_Minhad_AB`
--   * `AIRBASE.PersianGulf.Bandar_Abbas_Intl`
--   * `AIRBASE.PersianGulf.Bandar_Lengeh`
--   * `AIRBASE.PersianGulf.Dubai_Intl`
--   * `AIRBASE.PersianGulf.Fujairah_Intl`
--   * `AIRBASE.PersianGulf.Havadarya`
--   * `AIRBASE.PersianGulf.Kerman_Airport`
--   * `AIRBASE.PersianGulf.Khasab`
--   * `AIRBASE.PersianGulf.Lar_Airbase`
--   * `AIRBASE.PersianGulf.Qeshm_Island`
--   * `AIRBASE.PersianGulf.Sharjah_Intl`
--   * `AIRBASE.PersianGulf.Shiraz_International_Airport`
--   * `AIRBASE.PersianGulf.Sir_Abu_Nuayr`
--   * `AIRBASE.PersianGulf.Sirri_Island`
--   * `AIRBASE.PersianGulf.Tunb_Island_AFB`
--   * `AIRBASE.PersianGulf.Tunb_Kochak`
--   * `AIRBASE.PersianGulf.Sas_Al_Nakheel_Airport`
--   * `AIRBASE.PersianGulf.Bandar_e_Jask_airfield`
--   * `AIRBASE.PersianGulf.Abu_Dhabi_International_Airport`
--   * `AIRBASE.PersianGulf.Al_Bateen_Airport`
--   * `AIRBASE.PersianGulf.Kish_International_Airport`
--   * `AIRBASE.PersianGulf.Al_Ain_International_Airport`
--   * `AIRBASE.PersianGulf.Lavan_Island_Airport`
--   * `AIRBASE.PersianGulf.Jiroft_Airport`
--
-- # Installation
-- 
-- ## In Single Player Missions
-- 
-- ATC\_GROUND is fully functional in single player.
-- 
-- ## In Multi Player Missions
-- 
-- ATC\_GROUND is functional in multi player, however ...
-- 
-- Due to a bug in DCS since release 1.5, the despawning of clients are not anymore working in multi player.
-- To **work around this problem**, a much better solution has been made, using the **slot blocker** script designed
-- by Ciribob. 
-- 
-- With the help of __Ciribob__, this script has been extended to also kick client players while in flight.
-- ATC\_GROUND is communicating with this modified script to kick players!
-- 
-- Install the file **SimpleSlotBlockGameGUI.lua** on the server, following the installation instructions described by Ciribob.
-- 
-- [Simple Slot Blocker from Ciribob & FlightControl](https://github.com/ciribob/DCS-SimpleSlotBlock)
-- 
-- # Script it!
-- 
-- ## 1. ATC_GROUND_PERSIANGULF Constructor
-- 
-- Creates a new ATC_GROUND_PERSIANGULF object that will monitor pilots taxiing behaviour.
-- 
--     -- This creates a new ATC_GROUND_PERSIANGULF object.
-- 
--     -- Monitor for these clients the airbases.
--     AirbasePoliceCaucasus = ATC_GROUND_PERSIANGULF:New()
--     
--     ATC_Ground = ATC_GROUND_PERSIANGULF:New( 
--       { AIRBASE.PersianGulf.Kerman_Airport,
--         AIRBASE.PersianGulf.Al_Minhad_AB 
--       } 
--     )
-- 
--     
-- ## 2. Set various options
-- 
-- There are various methods that you can use to tweak the behaviour of the ATC\_GROUND classes.
-- 
-- ### 2.1 Speed limit at an airbase.
-- 
--   * @{#ATC_GROUND.SetKickSpeed}(): Set the speed limit allowed at an airbase in meters per second.
--   * @{#ATC_GROUND.SetKickSpeedKmph}(): Set the speed limit allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetKickSpeedMiph}(): Set the speed limit allowed at an airbase in miles per hour.
--   
-- ### 2.2 Prevent Takeoff at an airbase. Players will be kicked immediately.
-- 
--   * @{#ATC_GROUND.SetMaximumKickSpeed}(): Set the maximum speed allowed at an airbase in meters per second. 
--   * @{#ATC_GROUND.SetMaximumKickSpeedKmph}(): Set the maximum speed allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetMaximumKickSpeedMiph}(): Set the maximum speed allowed at an airbase in miles per hour.
--   
-- @field #ATC_GROUND_PERSIANGULF
ATC_GROUND_PERSIANGULF = {
  ClassName = "ATC_GROUND_PERSIANGULF",
}

--- Creates a new ATC_GROUND_PERSIANGULF object.
-- @param #ATC_GROUND_PERSIANGULF self
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.PersianGulf enumerator).
-- @return #ATC_GROUND_PERSIANGULF self
function ATC_GROUND_PERSIANGULF:New( AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, ATC_GROUND_UNIVERSAL:New( AirbaseNames ) ) -- #ATC_GROUND_PERSIANGULF
  
  self:SetKickSpeedKmph( 50 )
  self:SetMaximumKickSpeedKmph( 150 )
  
end

--- Start SCHEDULER for ATC_GROUND_PERSIANGULF object.
-- @param #ATC_GROUND_PERSIANGULF self
-- @param RepeatScanSeconds Time in second for defining occurency of alerts.
-- @return nothing
function ATC_GROUND_PERSIANGULF:Start( RepeatScanSeconds )
  RepeatScanSeconds = RepeatScanSeconds or 0.05
  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, RepeatScanSeconds )
end
          

 --- @type ATC_GROUND_MARIANAISLANDS
-- @extends #ATC_GROUND

     

--- # ATC\_GROUND\_MARIANA, extends @{#ATC_GROUND}
-- 
-- The ATC\_GROUND\_MARIANA class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- ---
-- 
-- ![Banner Image](..\Presentations\ATC_GROUND\Dia1.JPG)
-- 
-- ---
-- 
-- The default maximum speed for the airbases at Persian Gulf is **50 km/h**. Warnings are given if this speed limit is trespassed.
-- Players will be immediately kicked when driving faster than **150 km/h** on the taxi way.
-- 
-- The ATC\_GROUND\_MARIANA class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- The pilot will receive 3 times a warning during speeding. After the 3rd warning, if the pilot is still driving
-- faster than the maximum allowed speed, the pilot will be kicked.
-- 
-- Different airbases have different maximum speeds, according safety regulations.
-- 
-- # Airbases monitored
-- 
-- The following airbases are monitored at the Mariana Island region.
-- Use the @{Wrapper.Airbase#AIRBASE.MarianaIslands} enumeration to select the airbases to be monitored.
-- 
-- * AIRBASE.MarianaIslands.Rota_Intl
-- * AIRBASE.MarianaIslands.Andersen_AFB
-- * AIRBASE.MarianaIslands.Antonio_B_Won_Pat_Intl
-- * AIRBASE.MarianaIslands.Saipan_Intl
-- * AIRBASE.MarianaIslands.Tinian_Intl
-- * AIRBASE.MarianaIslands.Olf_Orote
--
-- # Installation
-- 
-- ## In Single Player Missions
-- 
-- ATC\_GROUND is fully functional in single player.
-- 
-- ## In Multi Player Missions
-- 
-- ATC\_GROUND is functional in multi player, however ...
-- 
-- Due to a bug in DCS since release 1.5, the despawning of clients are not anymore working in multi player.
-- To **work around this problem**, a much better solution has been made, using the **slot blocker** script designed
-- by Ciribob. 
-- 
-- With the help of __Ciribob__, this script has been extended to also kick client players while in flight.
-- ATC\_GROUND is communicating with this modified script to kick players!
-- 
-- Install the file **SimpleSlotBlockGameGUI.lua** on the server, following the installation instructions described by Ciribob.
-- 
-- [Simple Slot Blocker from Ciribob & FlightControl](https://github.com/ciribob/DCS-SimpleSlotBlock)
-- 
-- # Script it!
-- 
-- ## 1. ATC_GROUND_MARIANAISLANDS Constructor
-- 
-- Creates a new ATC_GROUND_MARIANAISLANDS object that will monitor pilots taxiing behaviour.
-- 
--     -- This creates a new ATC_GROUND_MARIANAISLANDS object.
-- 
--     -- Monitor for these clients the airbases.
--     AirbasePoliceCaucasus = ATC_GROUND_MARIANAISLANDS:New()
--     
--     ATC_Ground = ATC_GROUND_MARIANAISLANDS:New( 
--       { AIRBASE.MarianaIslands.Andersen_AFB,
--         AIRBASE.MarianaIslands.Saipan_Intl 
--       } 
--     )
-- 
--     
-- ## 2. Set various options
-- 
-- There are various methods that you can use to tweak the behaviour of the ATC\_GROUND classes.
-- 
-- ### 2.1 Speed limit at an airbase.
-- 
--   * @{#ATC_GROUND.SetKickSpeed}(): Set the speed limit allowed at an airbase in meters per second.
--   * @{#ATC_GROUND.SetKickSpeedKmph}(): Set the speed limit allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetKickSpeedMiph}(): Set the speed limit allowed at an airbase in miles per hour.
--   
-- ### 2.2 Prevent Takeoff at an airbase. Players will be kicked immediately.
-- 
--   * @{#ATC_GROUND.SetMaximumKickSpeed}(): Set the maximum speed allowed at an airbase in meters per second. 
--   * @{#ATC_GROUND.SetMaximumKickSpeedKmph}(): Set the maximum speed allowed at an airbase in kilometers per hour.
--   * @{#ATC_GROUND.SetMaximumKickSpeedMiph}(): Set the maximum speed allowed at an airbase in miles per hour.
--     
---- @field #ATC_GROUND_MARIANAISLANDS
ATC_GROUND_MARIANAISLANDS = {
  ClassName = "ATC_GROUND_MARIANAISLANDS",
}

--- Creates a new ATC_GROUND_MARIANAISLANDS object.
-- @param #ATC_GROUND_MARIANAISLANDS self
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.MarianaIslands enumerator).
-- @return #ATC_GROUND_MARIANAISLANDS self
function ATC_GROUND_MARIANAISLANDS:New( AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, ATC_GROUND_UNIVERSAL:New( self.Airbases, AirbaseNames ) )

  self:SetKickSpeedKmph( 50 )
  self:SetMaximumKickSpeedKmph( 150 )

  return self
end

--- Start SCHEDULER for ATC_GROUND_MARIANAISLANDS object.
-- @param #ATC_GROUND_MARIANAISLANDS self
-- @param RepeatScanSeconds Time in second for defining occurency of alerts.
-- @return nothing
function ATC_GROUND_MARIANAISLANDS:Start( RepeatScanSeconds )
  RepeatScanSeconds = RepeatScanSeconds or 0.05
  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, RepeatScanSeconds )
end
