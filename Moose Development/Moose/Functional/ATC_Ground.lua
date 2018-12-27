--- **Functional** -- Monitor airbase traffic and regulate speed while taxiing.
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
--
-- ===
-- 
-- @module Functional.ATC_Ground
-- @image Air_Traffic_Control_Ground_Operations.JPG

--- @type ATC_GROUND
-- @field Core.Set#SET_CLIENT SetClient
-- @extends Core.Base#BASE

--- Base class for ATC\_GROUND implementations.
-- @field #ATC_GROUND
ATC_GROUND = {
  ClassName = "ATC_GROUND",
  SetClient = nil,
  Airbases = nil,
  AirbaseNames = nil,
  --KickSpeed = nil, -- The maximum speed in meters per second for all airbases until a player gets kicked. This is overridden at each derived class.
}

--- @type ATC_GROUND.AirbaseNames
-- @list <#string>


--- Creates a new ATC\_GROUND object.
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
    Airbase.ZoneBoundary = _DATABASE:FindAirbase( AirbaseID ):GetZone()
    Airbase.ZoneRunways = {}
    for PointsRunwayID, PointsRunway in pairs( Airbase.PointsRunways ) do
      Airbase.ZoneRunways[PointsRunwayID] = ZONE_POLYGON_BASE:New( "Runway " .. PointsRunwayID, PointsRunway )
    end
    Airbase.Monitor = self.AirbaseList and false or true -- When AirbaseList is not given, monitor every Airbase, otherwise don't monitor any (yet). 
  end

  -- Now activate the monitoring for the airbases that need to be monitored.
  for AirbaseID, AirbaseName in pairs( self.AirbaseList or {} ) do
    self.Airbases[AirbaseName].Monitor = true
  end

--    -- Template
--    local TemplateBoundary = GROUP:FindByName( "Template Boundary" )
--    self.Airbases.Template.ZoneBoundary = ZONE_POLYGON:New( "Template Boundary", TemplateBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
--  
--    local TemplateRunway1 = GROUP:FindByName( "Template Runway 1" )
--    self.Airbases.Template.ZoneRunways[1] = ZONE_POLYGON:New( "Template Runway 1", TemplateRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()

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
                  Client:Message( "Welcome at " .. AirbaseID .. ". The maximum taxiing speed is " .. 
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
                                 " is kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
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
                        MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. " is kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
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
                      MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. " is kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
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


--- @type ATC_GROUND_CAUCASUS
-- @extends #ATC_GROUND

--- # ATC\_GROUND\_CAUCASUS, extends @{#ATC_GROUND}
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
  Airbases = {
    [AIRBASE.Caucasus.Anapa_Vityazevo] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=242140.57142858,["x"]=-6478.8571428583,},
          [2]={["y"]=242188.57142858,["x"]=-6522.0000000011,},
          [3]={["y"]=244124.2857143,["x"]=-4344.0000000011,},
          [4]={["y"]=244068.2857143,["x"]=-4296.5714285726,},
          [5]={["y"]=242140.57142858,["x"]=-6480.0000000011,}
        },
      },
    },
    [AIRBASE.Caucasus.Batumi] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=616442.28571429,["x"]=-355090.28571429,},
          [2]={["y"]=618450.57142857,["x"]=-356522,},
          [3]={["y"]=618407.71428571,["x"]=-356584.85714286,},
          [4]={["y"]=618361.99999999,["x"]=-356554.85714286,},
          [5]={["y"]=618324.85714285,["x"]=-356599.14285715,},
          [6]={["y"]=618250.57142856,["x"]=-356543.42857143,},
          [7]={["y"]=618257.7142857,["x"]=-356496.28571429,},
          [8]={["y"]=618237.7142857,["x"]=-356459.14285715,},
          [9]={["y"]=616555.71428571,["x"]=-355258.85714286,},
          [10]={["y"]=616486.28571428,["x"]=-355280.57142858,},
          [11]={["y"]=616410.57142856,["x"]=-355227.71428572,},
          [12]={["y"]=616441.99999999,["x"]=-355179.14285715,},
          [13]={["y"]=616401.99999999,["x"]=-355147.71428572,},
          [14]={["y"]=616441.42857142,["x"]=-355092.57142858,},
        },
      },
    },
    [AIRBASE.Caucasus.Beslan] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=842104.57142857,["x"]=-148460.57142857,},
          [2]={["y"]=845225.71428572,["x"]=-148656,},
          [3]={["y"]=845220.57142858,["x"]=-148750,},
          [4]={["y"]=842098.85714286,["x"]=-148556.28571429,},
          [5]={["y"]=842104,["x"]=-148460.28571429,},
        },
      },
    },
    [AIRBASE.Caucasus.Gelendzhik] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=297834.00000001,["x"]=-51107.428571429,},
          [2]={["y"]=297786.57142858,["x"]=-51068.857142858,},
          [3]={["y"]=298946.57142858,["x"]=-49686.000000001,},
          [4]={["y"]=298993.14285715,["x"]=-49725.714285715,},
          [5]={["y"]=297835.14285715,["x"]=-51107.714285715,},
        },
      },
    },
    [AIRBASE.Caucasus.Gudauta] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=517096.57142857,["x"]=-197804.57142857,},
          [2]={["y"]=515880.85714285,["x"]=-195590.28571429,},
          [3]={["y"]=515812.28571428,["x"]=-195628.85714286,},
          [4]={["y"]=517036.57142857,["x"]=-197834.57142857,},
          [5]={["y"]=517097.99999999,["x"]=-197807.42857143,},
        },
      },
    },
    [AIRBASE.Caucasus.Kobuleti] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=634509.71428571,["x"]=-318339.42857144,},
          [2]={["y"]=636767.42857143,["x"]=-317516.57142858,},
          [3]={["y"]=636790,["x"]=-317575.71428572,},
          [4]={["y"]=634531.42857143,["x"]=-318398.00000001,},
          [5]={["y"]=634510.28571429,["x"]=-318339.71428572,},
        },
      },
    },
    [AIRBASE.Caucasus.Krasnodar_Center] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=369205.42857144,["x"]=11789.142857142,},
          [2]={["y"]=369209.71428572,["x"]=11714.857142856,},
          [3]={["y"]=366699.71428572,["x"]=11581.714285713,},
          [4]={["y"]=366698.28571429,["x"]=11659.142857142,},
          [5]={["y"]=369208.85714286,["x"]=11788.57142857,},
        },
      },
    },
    [AIRBASE.Caucasus.Krasnodar_Pashkovsky] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=385891.14285715,["x"]=8416.5714285703,},
          [2]={["y"]=385842.28571429,["x"]=8467.9999999989,},
          [3]={["y"]=384180.85714286,["x"]=6917.1428571417,},
          [4]={["y"]=384228.57142858,["x"]=6867.7142857132,},
          [5]={["y"]=385891.14285715,["x"]=8416.5714285703,},
        },
        [2] = {
          [1]={["y"]=386714.85714286,["x"]=6674.857142856,},
          [2]={["y"]=386757.71428572,["x"]=6627.7142857132,},
          [3]={["y"]=389028.57142858,["x"]=8741.4285714275,},
          [4]={["y"]=388981.71428572,["x"]=8790.5714285703,},
          [5]={["y"]=386714.57142858,["x"]=6674.5714285703,},
        },
      },
    },
    [AIRBASE.Caucasus.Krymsk] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=293522.00000001,["x"]=-7567.4285714297,},
          [2]={["y"]=293578.57142858,["x"]=-7616.0000000011,},
          [3]={["y"]=295246.00000001,["x"]=-5591.142857144,},
          [4]={["y"]=295187.71428573,["x"]=-5546.0000000011,},
          [5]={["y"]=293523.14285715,["x"]=-7568.2857142868,},
        },
      },
    },
    [AIRBASE.Caucasus.Kutaisi] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=682638,["x"]=-285202.28571429,},
          [2]={["y"]=685050.28571429,["x"]=-284507.42857144,},
          [3]={["y"]=685068.85714286,["x"]=-284578.85714286,},
          [4]={["y"]=682657.42857143,["x"]=-285264.28571429,},
          [5]={["y"]=682638.28571429,["x"]=-285202.85714286,},
        },
      },
    },
    [AIRBASE.Caucasus.Maykop_Khanskaya] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=457005.42857143,["x"]=-27668.000000001,},
          [2]={["y"]=459028.85714286,["x"]=-25168.857142858,},
          [3]={["y"]=459082.57142857,["x"]=-25216.857142858,},
          [4]={["y"]=457060,["x"]=-27714.285714287,},
          [5]={["y"]=457004.57142857,["x"]=-27669.714285715,},
        },
      },
    },
    [AIRBASE.Caucasus.Mineralnye_Vody] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=703904,["x"]=-50352.571428573,},
          [2]={["y"]=707596.28571429,["x"]=-52094.571428573,},
          [3]={["y"]=707560.57142858,["x"]=-52161.714285716,},
          [4]={["y"]=703871.71428572,["x"]=-50420.571428573,},
          [5]={["y"]=703902,["x"]=-50352.000000002,},
        },
      },
    },
    [AIRBASE.Caucasus.Mozdok] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=832201.14285715,["x"]=-83699.428571431,},
          [2]={["y"]=832212.57142857,["x"]=-83780.571428574,},
          [3]={["y"]=835730.28571429,["x"]=-83335.714285717,},
          [4]={["y"]=835718.85714286,["x"]=-83246.571428574,},
          [5]={["y"]=832200.57142857,["x"]=-83700.000000002,},
        },
      },
    },
    [AIRBASE.Caucasus.Nalchik] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=759454.28571429,["x"]=-125551.42857143,},
          [2]={["y"]=759492.85714286,["x"]=-125610.85714286,},
          [3]={["y"]=761406.28571429,["x"]=-124304.28571429,},
          [4]={["y"]=761361.14285714,["x"]=-124239.71428572,},
          [5]={["y"]=759456,["x"]=-125552.57142857,},
        },
      },
    },
    [AIRBASE.Caucasus.Novorossiysk] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=278673.14285716,["x"]=-41615.142857144,},
          [2]={["y"]=278625.42857144,["x"]=-41570.571428572,},
          [3]={["y"]=279835.42857144,["x"]=-40226.000000001,},
          [4]={["y"]=279882.2857143,["x"]=-40270.000000001,},
          [5]={["y"]=278672.00000001,["x"]=-41614.857142858,},
        },
      },
    },
    [AIRBASE.Caucasus.Senaki_Kolkhi] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=646060.85714285,["x"]=-281736,},
          [2]={["y"]=646056.57142857,["x"]=-281631.71428571,},
          [3]={["y"]=648442.28571428,["x"]=-281840.28571428,},
          [4]={["y"]=648432.28571428,["x"]=-281918.85714286,},
          [5]={["y"]=646063.71428571,["x"]=-281738.85714286,},
        },
      },
    },
    [AIRBASE.Caucasus.Sochi_Adler] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=460831.42857143,["x"]=-165180,},
          [2]={["y"]=460878.57142857,["x"]=-165257.14285714,},
          [3]={["y"]=463663.71428571,["x"]=-163793.14285714,},
          [4]={["y"]=463612.28571428,["x"]=-163697.42857143,},
          [5]={["y"]=460831.42857143,["x"]=-165177.14285714,},
        },
        [2] = {
          [1]={["y"]=460831.42857143,["x"]=-165180,},
          [2]={["y"]=460878.57142857,["x"]=-165257.14285714,},
          [3]={["y"]=463663.71428571,["x"]=-163793.14285714,},
          [4]={["y"]=463612.28571428,["x"]=-163697.42857143,},
          [5]={["y"]=460831.42857143,["x"]=-165177.14285714,},
        },
      },
    },
    [AIRBASE.Caucasus.Soganlug] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=894525.71428571,["x"]=-316964,},
          [2]={["y"]=896363.14285714,["x"]=-318634.28571428,},
          [3]={["y"]=896299.14285714,["x"]=-318702.85714286,},
          [4]={["y"]=894464,["x"]=-317031.71428571,},
          [5]={["y"]=894524.57142857,["x"]=-316963.71428571,},
        },
      },
    },
    [AIRBASE.Caucasus.Sukhumi_Babushara] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=562684,["x"]=-219779.71428571,},
          [2]={["y"]=562717.71428571,["x"]=-219718,},
          [3]={["y"]=566046.85714286,["x"]=-221376.57142857,},
          [4]={["y"]=566012.28571428,["x"]=-221446.57142857,},
          [5]={["y"]=562684.57142857,["x"]=-219782.57142857,},
        },
      },
    },
    [AIRBASE.Caucasus.Tbilisi_Lochini] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=895261.14285715,["x"]=-314652.28571428,},
          [2]={["y"]=897654.57142857,["x"]=-316523.14285714,},
          [3]={["y"]=897711.71428571,["x"]=-316450.28571429,},
          [4]={["y"]=895327.42857143,["x"]=-314568.85714286,},
          [5]={["y"]=895261.71428572,["x"]=-314656,},
        },
        [2] = {
          [1]={["y"]=895605.71428572,["x"]=-314724.57142857,},
          [2]={["y"]=897639.71428572,["x"]=-316148,},
          [3]={["y"]=897683.42857143,["x"]=-316087.14285714,},
          [4]={["y"]=895650,["x"]=-314660,},
          [5]={["y"]=895606,["x"]=-314724.85714286,}
        },
      },
    },
    [AIRBASE.Caucasus.Vaziani] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=902239.14285714,["x"]=-318190.85714286,},
          [2]={["y"]=904014.28571428,["x"]=-319994.57142857,},
          [3]={["y"]=904064.85714285,["x"]=-319945.14285715,},
          [4]={["y"]=902294.57142857,["x"]=-318146,},
          [5]={["y"]=902247.71428571,["x"]=-318190.85714286,},
        },
      },
    },
  },
}

--- Creates a new ATC_GROUND_CAUCASUS object.
-- @param #ATC_GROUND_CAUCASUS self
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.Caucasus enumerator).
-- @return #ATC_GROUND_CAUCASUS self
function ATC_GROUND_CAUCASUS:New( AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, ATC_GROUND:New( self.Airbases, AirbaseNames ) )

  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, 0.05 )

  self:SetKickSpeedKmph( 50 )
  self:SetMaximumKickSpeedKmph( 150 )

  --    -- AnapaVityazevo
  --    local AnapaVityazevoBoundary = GROUP:FindByName( "AnapaVityazevo Boundary" )
  --    self.Airbases.AnapaVityazevo.ZoneBoundary = ZONE_POLYGON:New( "AnapaVityazevo Boundary", AnapaVityazevoBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --  
  --    local AnapaVityazevoRunway1 = GROUP:FindByName( "AnapaVityazevo Runway 1" )
  --    self.Airbases.AnapaVityazevo.ZoneRunways[1] = ZONE_POLYGON:New( "AnapaVityazevo Runway 1", AnapaVityazevoRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --  
  --
  --
  --    -- Batumi
  --    local BatumiBoundary = GROUP:FindByName( "Batumi Boundary" )
  --    self.Airbases.Batumi.ZoneBoundary = ZONE_POLYGON:New( "Batumi Boundary", BatumiBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local BatumiRunway1 = GROUP:FindByName( "Batumi Runway 1" )
  --    self.Airbases.Batumi.ZoneRunways[1] = ZONE_POLYGON:New( "Batumi Runway 1", BatumiRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Beslan
  --    local BeslanBoundary = GROUP:FindByName( "Beslan Boundary" )
  --    self.Airbases.Beslan.ZoneBoundary = ZONE_POLYGON:New( "Beslan Boundary", BeslanBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local BeslanRunway1 = GROUP:FindByName( "Beslan Runway 1" )
  --    self.Airbases.Beslan.ZoneRunways[1] = ZONE_POLYGON:New( "Beslan Runway 1", BeslanRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Gelendzhik
  --    local GelendzhikBoundary = GROUP:FindByName( "Gelendzhik Boundary" )
  --    self.Airbases.Gelendzhik.ZoneBoundary = ZONE_POLYGON:New( "Gelendzhik Boundary", GelendzhikBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local GelendzhikRunway1 = GROUP:FindByName( "Gelendzhik Runway 1" )
  --    self.Airbases.Gelendzhik.ZoneRunways[1] = ZONE_POLYGON:New( "Gelendzhik Runway 1", GelendzhikRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Gudauta
  --    local GudautaBoundary = GROUP:FindByName( "Gudauta Boundary" )
  --    self.Airbases.Gudauta.ZoneBoundary = ZONE_POLYGON:New( "Gudauta Boundary", GudautaBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local GudautaRunway1 = GROUP:FindByName( "Gudauta Runway 1" )
  --    self.Airbases.Gudauta.ZoneRunways[1] = ZONE_POLYGON:New( "Gudauta Runway 1", GudautaRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Kobuleti
  --    local KobuletiBoundary = GROUP:FindByName( "Kobuleti Boundary" )
  --    self.Airbases.Kobuleti.ZoneBoundary = ZONE_POLYGON:New( "Kobuleti Boundary", KobuletiBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local KobuletiRunway1 = GROUP:FindByName( "Kobuleti Runway 1" )
  --    self.Airbases.Kobuleti.ZoneRunways[1] = ZONE_POLYGON:New( "Kobuleti Runway 1", KobuletiRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- KrasnodarCenter
  --    local KrasnodarCenterBoundary = GROUP:FindByName( "KrasnodarCenter Boundary" )
  --    self.Airbases.KrasnodarCenter.ZoneBoundary = ZONE_POLYGON:New( "KrasnodarCenter Boundary", KrasnodarCenterBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local KrasnodarCenterRunway1 = GROUP:FindByName( "KrasnodarCenter Runway 1" )
  --    self.Airbases.KrasnodarCenter.ZoneRunways[1] = ZONE_POLYGON:New( "KrasnodarCenter Runway 1", KrasnodarCenterRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- KrasnodarPashkovsky
  --    local KrasnodarPashkovskyBoundary = GROUP:FindByName( "KrasnodarPashkovsky Boundary" )
  --    self.Airbases.KrasnodarPashkovsky.ZoneBoundary = ZONE_POLYGON:New( "KrasnodarPashkovsky Boundary", KrasnodarPashkovskyBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local KrasnodarPashkovskyRunway1 = GROUP:FindByName( "KrasnodarPashkovsky Runway 1" )
  --    self.Airbases.KrasnodarPashkovsky.ZoneRunways[1] = ZONE_POLYGON:New( "KrasnodarPashkovsky Runway 1", KrasnodarPashkovskyRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --    local KrasnodarPashkovskyRunway2 = GROUP:FindByName( "KrasnodarPashkovsky Runway 2" )
  --    self.Airbases.KrasnodarPashkovsky.ZoneRunways[2] = ZONE_POLYGON:New( "KrasnodarPashkovsky Runway 2", KrasnodarPashkovskyRunway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Krymsk
  --    local KrymskBoundary = GROUP:FindByName( "Krymsk Boundary" )
  --    self.Airbases.Krymsk.ZoneBoundary = ZONE_POLYGON:New( "Krymsk Boundary", KrymskBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local KrymskRunway1 = GROUP:FindByName( "Krymsk Runway 1" )
  --    self.Airbases.Krymsk.ZoneRunways[1] = ZONE_POLYGON:New( "Krymsk Runway 1", KrymskRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Kutaisi
  --    local KutaisiBoundary = GROUP:FindByName( "Kutaisi Boundary" )
  --    self.Airbases.Kutaisi.ZoneBoundary = ZONE_POLYGON:New( "Kutaisi Boundary", KutaisiBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local KutaisiRunway1 = GROUP:FindByName( "Kutaisi Runway 1" )
  --    self.Airbases.Kutaisi.ZoneRunways[1] = ZONE_POLYGON:New( "Kutaisi Runway 1", KutaisiRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- MaykopKhanskaya
  --    local MaykopKhanskayaBoundary = GROUP:FindByName( "MaykopKhanskaya Boundary" )
  --    self.Airbases.MaykopKhanskaya.ZoneBoundary = ZONE_POLYGON:New( "MaykopKhanskaya Boundary", MaykopKhanskayaBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local MaykopKhanskayaRunway1 = GROUP:FindByName( "MaykopKhanskaya Runway 1" )
  --    self.Airbases.MaykopKhanskaya.ZoneRunways[1] = ZONE_POLYGON:New( "MaykopKhanskaya Runway 1", MaykopKhanskayaRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- MineralnyeVody
  --    local MineralnyeVodyBoundary = GROUP:FindByName( "MineralnyeVody Boundary" )
  --    self.Airbases.MineralnyeVody.ZoneBoundary = ZONE_POLYGON:New( "MineralnyeVody Boundary", MineralnyeVodyBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local MineralnyeVodyRunway1 = GROUP:FindByName( "MineralnyeVody Runway 1" )
  --    self.Airbases.MineralnyeVody.ZoneRunways[1] = ZONE_POLYGON:New( "MineralnyeVody Runway 1", MineralnyeVodyRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Mozdok
  --    local MozdokBoundary = GROUP:FindByName( "Mozdok Boundary" )
  --    self.Airbases.Mozdok.ZoneBoundary = ZONE_POLYGON:New( "Mozdok Boundary", MozdokBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local MozdokRunway1 = GROUP:FindByName( "Mozdok Runway 1" )
  --    self.Airbases.Mozdok.ZoneRunways[1] = ZONE_POLYGON:New( "Mozdok Runway 1", MozdokRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Nalchik
  --    local NalchikBoundary = GROUP:FindByName( "Nalchik Boundary" )
  --    self.Airbases.Nalchik.ZoneBoundary = ZONE_POLYGON:New( "Nalchik Boundary", NalchikBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local NalchikRunway1 = GROUP:FindByName( "Nalchik Runway 1" )
  --    self.Airbases.Nalchik.ZoneRunways[1] = ZONE_POLYGON:New( "Nalchik Runway 1", NalchikRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Novorossiysk
  --    local NovorossiyskBoundary = GROUP:FindByName( "Novorossiysk Boundary" )
  --    self.Airbases.Novorossiysk.ZoneBoundary = ZONE_POLYGON:New( "Novorossiysk Boundary", NovorossiyskBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local NovorossiyskRunway1 = GROUP:FindByName( "Novorossiysk Runway 1" )
  --    self.Airbases.Novorossiysk.ZoneRunways[1] = ZONE_POLYGON:New( "Novorossiysk Runway 1", NovorossiyskRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- SenakiKolkhi
  --    local SenakiKolkhiBoundary = GROUP:FindByName( "SenakiKolkhi Boundary" )
  --    self.Airbases.SenakiKolkhi.ZoneBoundary = ZONE_POLYGON:New( "SenakiKolkhi Boundary", SenakiKolkhiBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local SenakiKolkhiRunway1 = GROUP:FindByName( "SenakiKolkhi Runway 1" )
  --    self.Airbases.SenakiKolkhi.ZoneRunways[1] = ZONE_POLYGON:New( "SenakiKolkhi Runway 1", SenakiKolkhiRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- SochiAdler
  --    local SochiAdlerBoundary = GROUP:FindByName( "SochiAdler Boundary" )
  --    self.Airbases.SochiAdler.ZoneBoundary = ZONE_POLYGON:New( "SochiAdler Boundary", SochiAdlerBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local SochiAdlerRunway1 = GROUP:FindByName( "SochiAdler Runway 1" )
  --    self.Airbases.SochiAdler.ZoneRunways[1] = ZONE_POLYGON:New( "SochiAdler Runway 1", SochiAdlerRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --    local SochiAdlerRunway2 = GROUP:FindByName( "SochiAdler Runway 2" )
  --    self.Airbases.SochiAdler.ZoneRunways[2] = ZONE_POLYGON:New( "SochiAdler Runway 2", SochiAdlerRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Soganlug
  --    local SoganlugBoundary = GROUP:FindByName( "Soganlug Boundary" )
  --    self.Airbases.Soganlug.ZoneBoundary = ZONE_POLYGON:New( "Soganlug Boundary", SoganlugBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local SoganlugRunway1 = GROUP:FindByName( "Soganlug Runway 1" )
  --    self.Airbases.Soganlug.ZoneRunways[1] = ZONE_POLYGON:New( "Soganlug Runway 1", SoganlugRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- SukhumiBabushara
  --    local SukhumiBabusharaBoundary = GROUP:FindByName( "SukhumiBabushara Boundary" )
  --    self.Airbases.SukhumiBabushara.ZoneBoundary = ZONE_POLYGON:New( "SukhumiBabushara Boundary", SukhumiBabusharaBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local SukhumiBabusharaRunway1 = GROUP:FindByName( "SukhumiBabushara Runway 1" )
  --    self.Airbases.SukhumiBabushara.ZoneRunways[1] = ZONE_POLYGON:New( "SukhumiBabushara Runway 1", SukhumiBabusharaRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- TbilisiLochini
  --    local TbilisiLochiniBoundary = GROUP:FindByName( "TbilisiLochini Boundary" )
  --    self.Airbases.TbilisiLochini.ZoneBoundary = ZONE_POLYGON:New( "TbilisiLochini Boundary", TbilisiLochiniBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --  
  --    local TbilisiLochiniRunway1 = GROUP:FindByName( "TbilisiLochini Runway 1" )
  --    self.Airbases.TbilisiLochini.ZoneRunways[1] = ZONE_POLYGON:New( "TbilisiLochini Runway 1", TbilisiLochiniRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --      
  --    local TbilisiLochiniRunway2 = GROUP:FindByName( "TbilisiLochini Runway 2" )
  --    self.Airbases.TbilisiLochini.ZoneRunways[2] = ZONE_POLYGON:New( "TbilisiLochini Runway 2", TbilisiLochiniRunway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --
  --    -- Vaziani
  --    local VazianiBoundary = GROUP:FindByName( "Vaziani Boundary" )
  --    self.Airbases.Vaziani.ZoneBoundary = ZONE_POLYGON:New( "Vaziani Boundary", VazianiBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --
  --    local VazianiRunway1 = GROUP:FindByName( "Vaziani Runway 1" )
  --    self.Airbases.Vaziani.ZoneRunways[1] = ZONE_POLYGON:New( "Vaziani Runway 1", VazianiRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  --
  --
  --


        -- Template
  --    local TemplateBoundary = GROUP:FindByName( "Template Boundary" )
  --    self.Airbases.Template.ZoneBoundary = ZONE_POLYGON:New( "Template Boundary", TemplateBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
  --  
  --    local TemplateRunway1 = GROUP:FindByName( "Template Runway 1" )
  --    self.Airbases.Template.ZoneRunways[1] = ZONE_POLYGON:New( "Template Runway 1", TemplateRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()

  return self
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
--    * `AIRBASE.Nevada.Mellan_Airstrip`
--    * `AIRBASE.Nevada.Mesquite`
--    * `AIRBASE.Nevada.Mina_Airport_3Q0`
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
--         AIRBASE.Nevada.Mellan_Airstrip,              
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
  Airbases = {

    [AIRBASE.Nevada.Beatty_Airport] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-174950.05857143,["x"]=-329679.65,},
          [2]={["y"]=-174946.53828571,["x"]=-331394.03885715,},
          [3]={["y"]=-174967.10971429,["x"]=-331394.32457143,},
          [4]={["y"]=-174971.01828571,["x"]=-329682.59171429,},
        },
      },
    },  
    [AIRBASE.Nevada.Boulder_City_Airport] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-1317.841714286,["x"]=-429014.92857142,},
          [2] = {["y"]=-951.26228571458,["x"]=-430310.21142856,},
          [3] = {["y"]=-978.11942857172,["x"]=-430317.06857142,},
          [4] = {["y"]=-1347.5088571432,["x"]=-429023.98485713,},
        },
        [2] = {
          [1] = {["y"]=-1879.955714286,["x"]=-429783.83742856,},
          [2] = {["y"]=-256.25257142886,["x"]=-430023.63542856,},
          [3] = {["y"]=-260.25257142886,["x"]=-430048.77828571,},
          [4] = {["y"]=-1883.955714286,["x"]=-429807.83742856,},
        },
      },
    },
    [AIRBASE.Nevada.Creech_AFB] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-74234.729142857,["x"]=-360501.80857143,},
          [2] = {["y"]=-77606.122285714,["x"]=-360417.86542857,},
          [3] = {["y"]=-77608.578,["x"]=-360486.13428571,},
          [4] = {["y"]=-74237.930571428,["x"]=-360586.25628571,},
        },
        [2] = {
          [1] = {["y"]=-75807.571428572,["x"]=-359073.42857142,},
          [2] = {["y"]=-74770.142857144,["x"]=-360581.71428571,},
          [3] = {["y"]=-74641.285714287,["x"]=-360585.42857142,},
          [4] = {["y"]=-75734.142857144,["x"]=-359023.14285714,},
        },
      },
    },
    [AIRBASE.Nevada.Echo_Bay] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=33182.919428572,["x"]=-388698.21657142,},
          [2] = {["y"]=34202.543142857,["x"]=-388469.55485714,},
          [3] = {["y"]=34207.686,["x"]=-388488.69771428,},
          [4] = {["y"]=33185.422285715,["x"]=-388717.82228571,},
        },
      },
    },
    [AIRBASE.Nevada.Groom_Lake_AFB] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-85971.465428571,["x"]=-290567.77,},
          [2] = {["y"]=-87691.155428571,["x"]=-286637.75428571,},
          [3] = {["y"]=-87756.714285715,["x"]=-286663.99999999,},
          [4] = {["y"]=-86035.940285714,["x"]=-290598.81314286,},
        },
        [2] = {
          [1] = {["y"]=-86741.547142857,["x"]=-290353.31971428,},
          [2] = {["y"]=-89672.714285714,["x"]=-283546.57142855,},
          [3] = {["y"]=-89772.142857143,["x"]=-283587.71428569,},
          [4] = {["y"]=-86799.623714285,["x"]=-290374.16771428,},
        },
      },
    },
    [AIRBASE.Nevada.Henderson_Executive_Airport] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-25837.500571429,["x"]=-426404.25257142,},
          [2] = {["y"]=-25843.509428571,["x"]=-428752.67942856,},
          [3] = {["y"]=-25902.343714286,["x"]=-428749.96399999,},
          [4] = {["y"]=-25934.667142857,["x"]=-426411.45657142,},
        },
        [2] = {
          [1] = {["y"]=-25650.296285714,["x"]=-426510.17971428,},
          [2] = {["y"]=-25632.443428571,["x"]=-428297.11428571,},
          [3] = {["y"]=-25686.690285714,["x"]=-428299.37457142,},
          [4] = {["y"]=-25708.296285714,["x"]=-426515.15114285,},
        },
      },
    },
    [AIRBASE.Nevada.Jean_Airport] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-42549.187142857,["x"]=-449663.23257143,},
          [2] = {["y"]=-43367.466285714,["x"]=-451044.77657143,},
          [3] = {["y"]=-43395.180571429,["x"]=-451028.20514286,},
          [4] = {["y"]=-42579.893142857,["x"]=-449648.18371428,},
        },
        [2] = {
          [1] = {["y"]=-42588.359428572,["x"]=-449900.14342857,},
          [2] = {["y"]=-43349.698285714,["x"]=-451185.46857143,},
          [3] = {["y"]=-43369.624571429,["x"]=-451173.49342857,},
          [4] = {["y"]=-42609.216571429,["x"]=-449891.28628571,},
        },
      },
    },
    [AIRBASE.Nevada.Laughlin_Airport] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=28231.600857143,["x"]=-515555.94114286,},
          [2] = {["y"]=28453.728285714,["x"]=-518170.78885714,},
          [3] = {["y"]=28370.788285714,["x"]=-518176.25742857,},
          [4] = {["y"]=28138.022857143,["x"]=-515573.07514286,},
        },
        [2] = {
          [1] = {["y"]=28231.600857143,["x"]=-515555.94114286,},
          [2] = {["y"]=28453.728285714,["x"]=-518170.78885714,},
          [3] = {["y"]=28370.788285714,["x"]=-518176.25742857,},
          [4] = {["y"]=28138.022857143,["x"]=-515573.07514286,},
        },
      },
    },
    [AIRBASE.Nevada.Lincoln_County] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=33222.34171429,["x"]=-223959.40171429,},
          [2]={["y"]=33200.040000004,["x"]=-225369.36828572,},
          [3]={["y"]=33177.634571428,["x"]=-225369.21485715,},
          [4]={["y"]=33201.198857147,["x"]=-223960.54457143,},
        },
      },
    },
    [AIRBASE.Nevada.McCarran_International_Airport] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-29406.035714286,["x"]=-416102.48199999,},
          [2] = {["y"]=-24680.714285715,["x"]=-416003.14285713,},
          [3] = {["y"]=-24681.857142858,["x"]=-415926.57142856,},
          [4] = {["y"]=-29408.42857143,["x"]=-416016.57142856,},
        },
        [2] = {
          [1] = {["y"]=-28567.221714286,["x"]=-416378.61799999,},
          [2] = {["y"]=-25109.912285714,["x"]=-416309.92914285,},
          [3] = {["y"]=-25112.508,["x"]=-416240.78714285,},
          [4] = {["y"]=-28576.247428571,["x"]=-416308.49514285,},
        },
        [3] = {
          [1] = {["y"]=-29255.953142857,["x"]=-416307.10657142,},
          [2] = {["y"]=-28005.571428572,["x"]=-413449.7142857,},
          [3] = {["y"]=-28068.714285715,["x"]=-413422.85714284,},
          [4] = {["y"]=-29331.000000001,["x"]=-416275.7142857,},
        },
        [4] = {
          [1] = {["y"]=-28994.901714286,["x"]=-416423.0522857,},
          [2] = {["y"]=-27697.571428572,["x"]=-413464.57142856,},
          [3] = {["y"]=-27767.857142858,["x"]=-413434.28571427,},
          [4] = {["y"]=-29073.000000001,["x"]=-416386.85714284,},
        },
      },
    },
    [AIRBASE.Nevada.Mesquite] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=68188.340285714,["x"]=-330302.54742857,},
          [2] = {["y"]=68911.303428571,["x"]=-328920.76571429,},
          [3] = {["y"]=68936.927142857,["x"]=-328933.888,},
          [4] = {["y"]=68212.460285714,["x"]=-330317.19171429,},
        },
      },
    },
    [AIRBASE.Nevada.Mina_Airport_3Q0] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-290054.57371429,["x"]=-160930.02228572,},
          [2] = {["y"]=-289469.77457143,["x"]=-162048.73571429,},
          [3] = {["y"]=-289520.06028572,["x"]=-162074.73571429,},
          [4] = {["y"]=-290104.69085714,["x"]=-160956.19457143,},
        },
      },
    },
    [AIRBASE.Nevada.Nellis_AFB] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-18614.218571428,["x"]=-399437.91085714,},
          [2] = {["y"]=-16217.857142857,["x"]=-396596.85714286,},
          [3] = {["y"]=-16300.142857143,["x"]=-396530,},
          [4] = {["y"]=-18692.543428571,["x"]=-399381.31114286,},
        },
        [2] = {
          [1] = {["y"]=-18388.948857143,["x"]=-399630.51828571,},
          [2] = {["y"]=-16011,["x"]=-396806.85714286,},
          [3] = {["y"]=-16074.714285714,["x"]=-396751.71428572,},
          [4] = {["y"]=-18451.571428572,["x"]=-399580.85714285,},
        },
      },
    },
    [AIRBASE.Nevada.Pahute_Mesa_Airstrip] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-132690.40942857,["x"]=-302733.53085714,},
          [2] = {["y"]=-133112.43228571,["x"]=-304499.70742857,},
          [3] = {["y"]=-133179.91685714,["x"]=-304485.544,},
          [4] = {["y"]=-132759.988,["x"]=-302723.326,},
        },
      },
    },
    [AIRBASE.Nevada.Tonopah_Test_Range_Airfield] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-175389.162,["x"]=-224778.07685715,},
          [2] = {["y"]=-173942.15485714,["x"]=-228210.27571429,},
          [3] = {["y"]=-174001.77085714,["x"]=-228233.60371429,},
          [4] = {["y"]=-175452.38685714,["x"]=-224806.84200001,},
        },
      },
    },
    [AIRBASE.Nevada.Tonopah_Airport] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-202128.25228571,["x"]=-196701.34314286,},
          [2] = {["y"]=-201562.40828571,["x"]=-198814.99714286,},
          [3] = {["y"]=-201591.44828571,["x"]=-198820.93714286,},
          [4] = {["y"]=-202156.06828571,["x"]=-196707.68714286,},
        },
        [2] = {
          [1] = {["y"]=-202084.57171428,["x"]=-196722.02228572,},
          [2] = {["y"]=-200592.75485714,["x"]=-197768.05571429,},
          [3] = {["y"]=-200605.37285714,["x"]=-197783.49228572,},
          [4] = {["y"]=-202097.14314285,["x"]=-196739.16514286,},
        },
      },
    },
    [AIRBASE.Nevada.North_Las_Vegas] = {
      PointsRunways = {
        [1] = {
          [1] = {["y"]=-32599.017714286,["x"]=-400913.26485714,},
          [2] = {["y"]=-30881.068857143,["x"]=-400837.94628571,},
          [3] = {["y"]=-30879.354571428,["x"]=-400873.08914285,},
          [4] = {["y"]=-32595.966285714,["x"]=-400947.13571428,},
        },
        [2] = {
          [1] = {["y"]=-32499.448571428,["x"]=-400690.99514285,},
          [2] = {["y"]=-31247.514857143,["x"]=-401868.95571428,},
          [3] = {["y"]=-31271.802857143,["x"]=-401894.97857142,},
          [4] = {["y"]=-32520.02,["x"]=-400716.99514285,},
        },
        [3] = {
          [1] = {["y"]=-31865.254857143,["x"]=-400999.74057143,},
          [2] = {["y"]=-30893.604,["x"]=-401908.85742857,},
          [3] = {["y"]=-30915.578857143,["x"]=-401936.03685714,},
          [4] = {["y"]=-31884.969142858,["x"]=-401020.59771429,},
        },
      },
    },
  },
}

--- Creates a new ATC_GROUND_NEVADA object.
-- @param #ATC_GROUND_NEVADA self
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.Nevada enumerator).
-- @return #ATC_GROUND_NEVADA self
function ATC_GROUND_NEVADA:New( AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, ATC_GROUND:New( self.Airbases, AirbaseNames ) )

  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, 0.05 )

  self:SetKickSpeedKmph( 50 )
  self:SetMaximumKickSpeedKmph( 150 )

  -- These lines here are for the demonstration mission.
  -- They create in the dcs.log the coordinates of the runway polygons, that are then
  -- taken by the moose designer from the dcs.log and reworked to define the
  -- Airbases structure, which is part of the class.
  -- When new airbases are added or airbases are changed on the map,
  -- the MOOSE designer willde-comment this section and apply the changes in the demo
  -- mission, and do a re-run to create a new dcs.log, and then add the changed coordinates
  -- in the Airbases structure.
  -- So, this needs to stay commented normally once a map has been finished.

  --[[
  
  -- Beatty
  do 
    local VillagePrefix = "Beatty" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  -- Boulder
  do 
    local VillagePrefix = "Boulder" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  -- Creech
  do
    local VillagePrefix = "Creech" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- Echo
  do 
    local VillagePrefix = "Echo" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- Groom Lake
  do
    local VillagePrefix = "GroomLake" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  -- Henderson
  do 
    local VillagePrefix = "Henderson" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  -- Jean
  do 
    local VillagePrefix = "Jean" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- Laughlin
  do 
    local VillagePrefix = "Laughlin" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  -- Lincoln
  do 
    local VillagePrefix = "Lincoln" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- McCarran
  do
    local VillagePrefix = "McCarran" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway3 = GROUP:FindByName( VillagePrefix .. " 3" )
    local Zone3 = ZONE_POLYGON:New( VillagePrefix .. " 3", Runway3 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway4 = GROUP:FindByName( VillagePrefix .. " 4" )
    local Zone4 = ZONE_POLYGON:New( VillagePrefix .. " 4", Runway4 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- Mesquite
  do 
    local VillagePrefix = "Mesquite" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- Mina
  do 
    local VillagePrefix = "Mina" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- Nellis
  do
    local VillagePrefix = "Nellis" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  -- Pahute
  do 
    local VillagePrefix = "Pahute" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- TonopahTR
  do 
    local VillagePrefix = "TonopahTR" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- Tonopah
  do 
    local VillagePrefix = "Tonopah" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end

  -- Vegas
  do 
    local VillagePrefix = "Vegas" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway3 = GROUP:FindByName( VillagePrefix .. " 3" )
    local Zone3 = ZONE_POLYGON:New( VillagePrefix .. " 3", Runway3 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  --]]
  
  return self
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
-- The default maximum speed for the airbases at Caucasus is **40 km/h**. Warnings are given if this speed limit is trespassed.
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
  Airbases = {
    [AIRBASE.Normandy.Azeville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-74194.387714285,["x"]=-2691.1399999998,},
          [2]={["y"]=-73160.282571428,["x"]=-2310.0274285712,},
          [3]={["y"]=-73141.711142857,["x"]=-2357.7417142855,},
          [4]={["y"]=-74176.959142857,["x"]=-2741.997142857,},
        },
      },
    },
    [AIRBASE.Normandy.Bazenville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-19246.209999999,["x"]=-21246.748,},
          [2]={["y"]=-17883.70142857,["x"]=-20219.009714285,},
          [3]={["y"]=-17855.415714285,["x"]=-20256.438285714,},
          [4]={["y"]=-19217.791999999,["x"]=-21283.597714285,},
        },
      },
    },
    [AIRBASE.Normandy.Beny_sur_Mer] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-8592.7442857133,["x"]=-20386.15542857,},
          [2]={["y"]=-8404.4931428561,["x"]=-21744.113142856,},
          [3]={["y"]=-8267.9917142847,["x"]=-21724.97742857,},
          [4]={["y"]=-8451.0482857133,["x"]=-20368.87542857,},
        },
      },
    },
    [AIRBASE.Normandy.Beuzeville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-71552.573428571,["x"]=-8744.3688571427,},
          [2]={["y"]=-72577.765714285,["x"]=-9638.5682857141,},
          [3]={["y"]=-72609.304285714,["x"]=-9601.2954285712,},
          [4]={["y"]=-71585.849428571,["x"]=-8709.9648571426,},
        },
      },
    },
    [AIRBASE.Normandy.Biniville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-84757.320285714,["x"]=-7377.1354285713,},
          [2]={["y"]=-84271.482,["x"]=-7956.4859999999,},
          [3]={["y"]=-84299.482,["x"]=-7981.6288571427,},
          [4]={["y"]=-84784.969714286,["x"]=-7402.0588571427,},
        },
      },
    },
    [AIRBASE.Normandy.Brucheville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-65546.792857142,["x"]=-14615.640857143,},
          [2]={["y"]=-66914.692,["x"]=-15232.713714285,},
          [3]={["y"]=-66896.527714285,["x"]=-15271.948571428,},
          [4]={["y"]=-65528.393714285,["x"]=-14657.995714286,},
        },
      },
    },
    [AIRBASE.Normandy.Cardonville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-54280.445428571,["x"]=-15843.749142857,},
          [2]={["y"]=-53646.998571428,["x"]=-17143.012285714,},
          [3]={["y"]=-53683.93,["x"]=-17161.317428571,},
          [4]={["y"]=-54323.354571428,["x"]=-15855.004,},
        },
      },
    },
    [AIRBASE.Normandy.Carpiquet] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-10751.325714285,["x"]=-34229.494,},
          [2]={["y"]=-9283.5279999993,["x"]=-35192.352857142,},
          [3]={["y"]=-9325.2005714274,["x"]=-35260.967714285,},
          [4]={["y"]=-10794.90942857,["x"]=-34287.041428571,},
        },
      },
    },
    [AIRBASE.Normandy.Chailey] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=12895.585714292,["x"]=164683.05657144,},
          [2]={["y"]=11410.727142863,["x"]=163606.54485715,},
          [3]={["y"]=11363.012857149,["x"]=163671.97342858,},
          [4]={["y"]=12797.537142863,["x"]=164711.01857144,},
          [5]={["y"]=12862.902857149,["x"]=164726.99685715,},
        },
        [2] = {
          [1]={["y"]=11805.316000006,["x"]=164502.90971429,},
          [2]={["y"]=11997.280857149,["x"]=163032.65542858,},
          [3]={["y"]=11918.640857149,["x"]=163023.04657144,},
          [4]={["y"]=11726.973428578,["x"]=164489.94257143,},
        },
      },
    },
    [AIRBASE.Normandy.Chippelle] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-48540.313999999,["x"]=-28884.795999999,},
          [2]={["y"]=-47251.820285713,["x"]=-28140.128571427,},
          [3]={["y"]=-47274.551714285,["x"]=-28103.758285713,},
          [4]={["y"]=-48555.657714285,["x"]=-28839.90142857,},
        },
      },
    },
    [AIRBASE.Normandy.Cretteville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-78351.723142857,["x"]=-18177.725428571,},
          [2]={["y"]=-77220.322285714,["x"]=-19125.687714286,},
          [3]={["y"]=-77247.899428571,["x"]=-19158.49,},
          [4]={["y"]=-78380.008857143,["x"]=-18208.011142857,},
        },
      },
    },
    [AIRBASE.Normandy.Cricqueville_en_Bessin] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-50875.034571428,["x"]=-14322.404571428,},
          [2]={["y"]=-50681.148571428,["x"]=-15825.258,},
          [3]={["y"]=-50717.434285713,["x"]=-15829.829428571,},
          [4]={["y"]=-50910.569428571,["x"]=-14327.562857142,},
        },
      },
    },
    [AIRBASE.Normandy.Deux_Jumeaux] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-49575.410857142,["x"]=-16575.161142857,},
          [2]={["y"]=-48149.077999999,["x"]=-16952.193428571,},
          [3]={["y"]=-48159.935142856,["x"]=-16996.764857142,},
          [4]={["y"]=-49584.839428571,["x"]=-16617.732571428,},
        },
      },
    },
    [AIRBASE.Normandy.Evreux] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=112906.84828572,["x"]=-45585.824857142,},
          [2]={["y"]=112050.38228572,["x"]=-46811.871999999,},
          [3]={["y"]=111980.05371429,["x"]=-46762.173142856,},
          [4]={["y"]=112833.54542857,["x"]=-45540.010571428,},
        },
        [2] = {
          [1]={["y"]=112046.02085714,["x"]=-45091.056571428,},
          [2]={["y"]=112488.668,["x"]=-46623.617999999,},
          [3]={["y"]=112405.66914286,["x"]=-46647.419142856,},
          [4]={["y"]=111966.03657143,["x"]=-45112.604285713,},
        },
      },
    },
    [AIRBASE.Normandy.Ford] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-26506.13971428,["x"]=147514.39971429,},
          [2]={["y"]=-25012.977428565,["x"]=147566.14485715,},
          [3]={["y"]=-25009.851428565,["x"]=147482.63600001,},
          [4]={["y"]=-26503.693999994,["x"]=147427.33228572,},
        },
        [2] = {
          [1]={["y"]=-25169.701999994,["x"]=148421.09257143,},
          [2]={["y"]=-26092.421999994,["x"]=147190.89628572,},
          [3]={["y"]=-26158.136285708,["x"]=147240.89628572,},
          [4]={["y"]=-25252.357999994,["x"]=148448.64457143,},
        },
      },
    },
    [AIRBASE.Normandy.Funtington] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-44698.388571423,["x"]=152952.17257143,},
          [2]={["y"]=-46452.993142851,["x"]=152388.77885714,},
          [3]={["y"]=-46476.361142851,["x"]=152470.05885714,},
          [4]={["y"]=-44787.256571423,["x"]=153009.52,},
          [5]={["y"]=-44715.581428566,["x"]=153002.08714286,},
        },
        [2] = {
          [1]={["y"]=-45792.665999994,["x"]=153123.894,},
          [2]={["y"]=-46068.084857137,["x"]=151665.98342857,},
          [3]={["y"]=-46148.632285708,["x"]=151681.58685714,},
          [4]={["y"]=-45871.25971428,["x"]=153136.82714286,},
        },
      },
    },
    [AIRBASE.Normandy.Lantheuil] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-17158.84542857,["x"]=-24602.999428571,},
          [2]={["y"]=-15978.59342857,["x"]=-23922.978571428,},
          [3]={["y"]=-15932.021999999,["x"]=-24004.121428571,},
          [4]={["y"]=-17090.734857142,["x"]=-24673.248,},
        },
      },
    },
    [AIRBASE.Normandy.Lessay] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-87667.304571429,["x"]=-33220.165714286,},
          [2]={["y"]=-86146.607714286,["x"]=-34248.483142857,},
          [3]={["y"]=-86191.538285714,["x"]=-34316.991142857,},
          [4]={["y"]=-87712.212,["x"]=-33291.774857143,},
        },
        [2] = {
          [1]={["y"]=-87125.123142857,["x"]=-34183.682571429,},
          [2]={["y"]=-85803.278285715,["x"]=-33498.428857143,},
          [3]={["y"]=-85768.408285715,["x"]=-33570.13,},
          [4]={["y"]=-87087.688571429,["x"]=-34258.272285715,},
        },
      },
    },
    [AIRBASE.Normandy.Lignerolles] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-35279.611714285,["x"]=-35232.026857142,},
          [2]={["y"]=-33804.948857142,["x"]=-35770.713999999,},
          [3]={["y"]=-33789.876285713,["x"]=-35726.655714284,},
          [4]={["y"]=-35263.548285713,["x"]=-35192.75542857,},
        },
      },
    },
    [AIRBASE.Normandy.Longues_sur_Mer] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-29444.070285713,["x"]=-16334.105428571,},
          [2]={["y"]=-28265.52942857,["x"]=-17011.557999999,},
          [3]={["y"]=-28344.74742857,["x"]=-17143.587999999,},
          [4]={["y"]=-29529.616285713,["x"]=-16477.766571428,},
        },
      },
    },
    [AIRBASE.Normandy.Maupertus] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-85605.340857143,["x"]=16175.267714286,},
          [2]={["y"]=-84132.567142857,["x"]=15895.905714286,},
          [3]={["y"]=-84139.995142857,["x"]=15847.623714286,},
          [4]={["y"]=-85613.626571429,["x"]=16132.410571429,},
        },
      },
    },
    [AIRBASE.Normandy.Meautis] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-72642.527714286,["x"]=-24593.622285714,},
          [2]={["y"]=-71298.672571429,["x"]=-24352.651142857,},
          [3]={["y"]=-71290.101142857,["x"]=-24398.365428571,},
          [4]={["y"]=-72631.715714286,["x"]=-24639.966857143,},
        },
      },
    },
    [AIRBASE.Normandy.Le_Molay] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-41876.526857142,["x"]=-26701.052285713,},
          [2]={["y"]=-40979.545714285,["x"]=-25675.045999999,},
          [3]={["y"]=-41017.687428571,["x"]=-25644.272571427,},
          [4]={["y"]=-41913.638285713,["x"]=-26665.137999999,},
        },
      },
    },
    [AIRBASE.Normandy.Needs_Oar_Point] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-83882.441142851,["x"]=141429.83314286,},
          [2]={["y"]=-85138.159428566,["x"]=140187.52828572,},
          [3]={["y"]=-85208.323428566,["x"]=140161.04371429,},
          [4]={["y"]=-85245.751999994,["x"]=140201.61514286,},
          [5]={["y"]=-83939.966571423,["x"]=141485.22085714,},
        },
        [2] = {
          [1]={["y"]=-84528.76571428,["x"]=141988.01428572,},
          [2]={["y"]=-84116.98971428,["x"]=140565.78685714,},
          [3]={["y"]=-84199.35771428,["x"]=140541.14685714,},
          [4]={["y"]=-84605.051428566,["x"]=141966.01428572,},
        },
      },
    },
    [AIRBASE.Normandy.Picauville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-80808.838571429,["x"]=-11834.554571428,},
          [2]={["y"]=-79531.574285714,["x"]=-12311.274,},
          [3]={["y"]=-79549.355428571,["x"]=-12356.928285714,},
          [4]={["y"]=-80827.815142857,["x"]=-11901.835142857,},
        },
      },
    },
    [AIRBASE.Normandy.Rucqueville] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-20023.988857141,["x"]=-26569.565428571,},
          [2]={["y"]=-18688.92542857,["x"]=-26571.086571428,},
          [3]={["y"]=-18688.012571427,["x"]=-26611.252285713,},
          [4]={["y"]=-20022.218857141,["x"]=-26608.505428571,},
        },
      },
    },
    [AIRBASE.Normandy.Saint_Pierre_du_Mont] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-48015.384571428,["x"]=-11886.631714285,},
          [2]={["y"]=-46540.412285713,["x"]=-11945.226571428,},
          [3]={["y"]=-46541.349999999,["x"]=-11991.174571428,},
          [4]={["y"]=-48016.837142856,["x"]=-11929.371142857,},
        },
      },
    },
    [AIRBASE.Normandy.Sainte_Croix_sur_Mer] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-15877.817999999,["x"]=-18812.579999999,},
          [2]={["y"]=-14464.377142856,["x"]=-18807.46,},
          [3]={["y"]=-14463.879714285,["x"]=-18759.706857142,},
          [4]={["y"]=-15878.229142856,["x"]=-18764.071428571,},
        },
      },
    },
    [AIRBASE.Normandy.Sainte_Laurent_sur_Mer] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-41676.834857142,["x"]=-14475.109428571,},
          [2]={["y"]=-40566.11142857,["x"]=-14817.319999999,},
          [3]={["y"]=-40579.543999999,["x"]=-14860.059999999,},
          [4]={["y"]=-41687.120571427,["x"]=-14509.680857142,},
        },
      },
    },
    [AIRBASE.Normandy.Sommervieu] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-26821.913714284,["x"]=-21390.466571427,},
          [2]={["y"]=-25465.308857142,["x"]=-21296.859999999,},
          [3]={["y"]=-25462.451714284,["x"]=-21343.717142856,},
          [4]={["y"]=-26818.002285713,["x"]=-21440.532857142,},
        },
      },
    },
    [AIRBASE.Normandy.Tangmere] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-34684.581142851,["x"]=150459.61657143,},
          [2]={["y"]=-33250.625428566,["x"]=149954.17,},
          [3]={["y"]=-33275.724285708,["x"]=149874.69028572,},
          [4]={["y"]=-34709.020571423,["x"]=150377.93742857,},
        },
        [2] = {
          [1]={["y"]=-33103.438857137,["x"]=150812.72542857,},
          [2]={["y"]=-34410.246285708,["x"]=150009.73142857,},
          [3]={["y"]=-34453.535142851,["x"]=150082.02685714,},
          [4]={["y"]=-33176.545999994,["x"]=150870.22542857,},
        },
      },
    },
  },
}


--- Creates a new ATC_GROUND_NORMANDY object.
-- @param #ATC_GROUND_NORMANDY self
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.Normandy enumerator).
-- @return #ATC_GROUND_NORMANDY self
function ATC_GROUND_NORMANDY:New( AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, ATC_GROUND:New( self.Airbases, AirbaseNames ) ) -- #ATC_GROUND_NORMANDY

  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, { self }, 0, 2, 0.05 )
  
  self:SetKickSpeedKmph( 40 )
  self:SetMaximumKickSpeedKmph( 100 )

  -- These lines here are for the demonstration mission.
  -- They create in the dcs.log the coordinates of the runway polygons, that are then
  -- taken by the moose designer from the dcs.log and reworked to define the
  -- Airbases structure, which is part of the class.
  -- When new airbases are added or airbases are changed on the map,
  -- the MOOSE designer willde-comment this section and apply the changes in the demo
  -- mission, and do a re-run to create a new dcs.log, and then add the changed coordinates
  -- in the Airbases structure.
  -- So, this needs to stay commented normally once a map has been finished.
  
  --[[
  
  -- Azeville
  do
    local VillagePrefix = "Azeville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Bazenville
  do
    local VillagePrefix = "Bazenville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Beny
  do
    local VillagePrefix = "Beny" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Beuzeville
  do
    local VillagePrefix = "Beuzeville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Biniville
  do
    local VillagePrefix = "Biniville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Brucheville
  do
    local VillagePrefix = "Brucheville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Cardonville
  do
    local VillagePrefix = "Cardonville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Carpiquet
  do
    local VillagePrefix = "Carpiquet" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Chailey
  do
    local VillagePrefix = "Chailey" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Chippelle
  do
    local VillagePrefix = "Chippelle" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Cretteville
  do
    local VillagePrefix = "Cretteville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Cricqueville
  do
    local VillagePrefix = "Cricqueville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Deux
  do
    local VillagePrefix = "Deux" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Evreux
  do
    local VillagePrefix = "Evreux" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Ford
  do
    local VillagePrefix = "Ford" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Funtington
  do
    local VillagePrefix = "Funtington" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Lantheuil
  do
    local VillagePrefix = "Lantheuil" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Lessay
  do
    local VillagePrefix = "Lessay" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Lignerolles
  do
    local VillagePrefix = "Lignerolles" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Longues
  do
    local VillagePrefix = "Longues" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Maupertus 
  do
    local VillagePrefix = "Maupertus" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Meautis
  do
    local VillagePrefix = "Meautis" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Molay
  do
    local VillagePrefix = "Molay" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Oar
  do
    local VillagePrefix = "Oar" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Picauville
  do
    local VillagePrefix = "Picauville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Rucqueville
  do
    local VillagePrefix = "Rucqueville" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- SaintPierre
  do
    local VillagePrefix = "SaintPierre" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- SainteCroix
  do
    local VillagePrefix = "SainteCroix" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  --SainteLaurent
  do
    local VillagePrefix = "SainteLaurent" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Sommervieu
  do
    local VillagePrefix = "Sommervieu" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  
  -- Tangmere
  do
    local VillagePrefix = "Tangmere" 
    local Runway1 = GROUP:FindByName( VillagePrefix .. " 1" )
    local Zone1 = ZONE_POLYGON:New( VillagePrefix .. " 1", Runway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
    local Runway2 = GROUP:FindByName( VillagePrefix .. " 2" )
    local Zone2 = ZONE_POLYGON:New( VillagePrefix .. " 2", Runway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
  end
  
  --]]
  
  return self
end

     


     