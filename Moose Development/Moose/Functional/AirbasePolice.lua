--- **Functional** -- The AIRBASEPOLICE classes monitor airbase traffic and regulate speed while taxiing.
--
-- ===
--
-- ### Contributions: Dutch Baron - Concept & Testing
-- ### Author: FlightControl - Framework Design &  Programming
--
-- ===
-- 
-- @module AirbasePolice


--- @type AIRBASEPOLICE_BASE
-- @field Core.Set#SET_CLIENT SetClient
-- @extends Core.Base#BASE

--- Base class for AIRBASEPOLICE implementations.
-- @field #AIRBASEPOLICE_BASE
AIRBASEPOLICE_BASE = {
  ClassName = "AIRBASEPOLICE_BASE",
  SetClient = nil,
  Airbases = nil,
  AirbaseNames = nil,
}

--- @type AIRBASEPOLICE_BASE.AirbaseNames
-- @list <#string>


--- Creates a new AIRBASEPOLICE_BASE object.
-- @param #AIRBASEPOLICE_BASE self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they follow the rules of the airbase.
-- @param Airbases A table of Airbase Names.
-- @return #AIRBASEPOLICE_BASE self
function AIRBASEPOLICE_BASE:New( SetClient, Airbases, AirbaseList )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  self:E( { self.ClassName, SetClient, Airbases } )

  self.SetClient = SetClient
  self.Airbases = Airbases
  
  self.AirbaseList = AirbaseList

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
      Client:SetState( self, "Taxi", false )
    end
  )

  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, {}, 0, 2, 0.05 )

  -- This is simple slot blocker is used on the server.  
  SSB = USERFLAG:New( "SSB" )
  SSB:Set( 100 )

  return self
end


--- Smoke the airbases runways.
-- @param #AIRBASEPOLICE_BASE self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The color of the smoke around the runways.
-- @return #AIRBASEPOLICE_BASE self
function AIRBASEPOLICE_BASE:SmokeRunways( SmokeColor )

  for AirbaseID, Airbase in pairs( self.Airbases ) do
    for PointsRunwayID, PointsRunway in pairs( Airbase.PointsRunways ) do
      Airbase.ZoneRunways[PointsRunwayID]:SmokeZone( SmokeColor )
      end
  end
end


--- @param #AIRBASEPOLICE_BASE self
function AIRBASEPOLICE_BASE:_AirbaseMonitor()

  for AirbaseID, AirbaseMeta in pairs( self.Airbases ) do

    if AirbaseMeta.Monitor == true then

      self:E( AirbaseID )

      self.SetClient:ForEachClientInZone( AirbaseMeta.ZoneBoundary,

        --- @param Wrapper.Client#CLIENT Client
        function( Client )

          self:E( Client.UnitName )
          if Client:IsAlive() then
            local NotInRunwayZone = true
            for ZoneRunwayID, ZoneRunway in pairs( AirbaseMeta.ZoneRunways ) do
              NotInRunwayZone = ( Client:IsNotInZone( ZoneRunway ) == true ) and NotInRunwayZone or false
            end

            if NotInRunwayZone then
              local Taxi = self:GetState( self, "Taxi" )
              self:E( Taxi )
              if Taxi == false then
                Client:Message( "Welcome at " .. AirbaseID .. ". The maximum taxiing speed is " .. AirbaseMeta.MaximumSpeed " km/h.", 20, "ATC" )
                self:SetState( self, "Taxi", true )
              end

              -- TODO: GetVelocityKMH function usage
              local VelocityVec3 = Client:GetVelocity()
              local Velocity = ( VelocityVec3.x ^ 2 + VelocityVec3.y ^ 2 + VelocityVec3.z ^ 2 ) ^ 0.5 -- in meters / sec
              local Velocity = Velocity * 3.6 -- now it is in km/h.
              -- MESSAGE:New( "Velocity = " .. Velocity, 1 ):ToAll()
              local IsAboveRunway = Client:IsAboveRunway()
              local IsOnGround = Client:InAir() == false
              self:T( IsAboveRunway, IsOnGround )

              if IsAboveRunway and IsOnGround then

                if Velocity > AirbaseMeta.MaximumSpeed then
                  local IsSpeeding = Client:GetState( self, "Speeding" )

                  if IsSpeeding == true then
                    local SpeedingWarnings = Client:GetState( self, "Warnings" )
                    self:T( SpeedingWarnings )

                    if SpeedingWarnings <= 3 then
                      Client:Message( "Warning " .. SpeedingWarnings .. "/3! Airbase traffic rule violation! Slow down now! Your speed is " .. 
                                      string.format( "%2.0f km/h", Velocity ), 5, "ATC" )
                      Client:SetState( self, "Warnings", SpeedingWarnings + 1 )
                    else
                      MESSAGE:New( "Penalty! Player " .. Client:GetPlayerName() .. " is kicked, due to a severe airbase traffic rule violation ...", 10, "ATC" ):ToAll()
                      --- @param Wrapper.Client#CLIENT Client
                      Client:Destroy()
                      Client:SetState( self, "Speeding", false )
                      Client:SetState( self, "Warnings", 0 )
                    end

                  else
                    Client:Message( "Attention! You are speeding on the taxiway, slow down! Your speed is " .. string.format( "%2.0f km/h", Velocity ), 5, "ATC" )
                    Client:SetState( self, "Speeding", true )
                    Client:SetState( self, "Warnings", 1 )
                  end

                else
                  Client:SetState( self, "Speeding", false )
                  Client:SetState( self, "Warnings", 0 )
                end
              end

            else
              Client:SetState( self, "Speeding", false )
              Client:SetState( self, "Warnings", 0 )
              local Taxi = self:GetState( self, "Taxi" )
              if Taxi == true then
                Client:Message( "You have progressed to the runway ... Await take-off clearance ...", 20, "ATC" )
                self:SetState( self, "Taxi", false )
              end
            end
          end
        end
      )
    end
  end

  return true
end


--- @type AIRBASEPOLICE_CAUCASUS
-- @extends #AIRBASEPOLICE_BASE

--- # AIRBASEPOLICE_CAUCASUS, extends @{#AIRBASEPOLICE_BASE}
-- 
-- ![Banner Image](..\Presentations\AIRBASEPOLICE\Dia1.JPG)
-- 
-- The AIRBASEPOLICE_CAUCASUS class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- The maximum speed for the airbases at Caucasus is **50 km/h**.
-- 
-- The pilot will receive 3 times a warning during speeding. After the 3rd warning, if the pilot is still driving
-- faster than the maximum allowed speed, the pilot will be kicked.
-- 
-- Different airbases have different maximum speeds, according safety regulations.
-- 
-- # Airbases monitored
-- 
-- The following airbases are monitored at the Caucasus region:
-- 
--   * Anapa Vityazevo
--   * Batumi
--   * Beslan
--   * Gelendzhik
--   * Gudauta
--   * Kobuleti
--   * Krasnodar Center
--   * Krasnodar Pashkovsky
--   * Krymsk
--   * Kutaisi
--   * Maykop Khanskaya
--   * Mineralnye Vody
--   * Mozdok
--   * Nalchik
--   * Novorossiysk
--   * Senaki Kolkhi
--   * Sochi Adler
--   * Soganlug
--   * Sukhumi Babushara
--   * Tbilisi Lochini
--   * Vaziani
--
-- 
-- # Installation
-- 
-- ## In Single Player Missions
-- 
-- AIRBASEPOLICE is fully functional in single player.
-- 
-- ## In Multi Player Missions
-- 
-- AIRBASEPOLICE is NOT functional in multi player, for client machines connecting to the server, running the mission.
-- Due to a bug in DCS since release 1.5, the despawning of clients are not anymore working in multi player.
-- To work around this problem, a much better solution has been made, using the slot blocker script designed
-- by Ciribob. With the help of __Ciribob__, this script has been extended to also kick client players while in flight.
-- AIRBASEPOLICE is communicating with this modified script to kick players!
-- 
-- Install the file **SimpleSlotBlockGameGUI.lua** on the server, following the installation instructions described by Ciribob.
-- 
-- [Simple Slot Blocker from Ciribob & FlightControl](https://github.com/ciribob/DCS-SimpleSlotBlock)
-- 
-- # Script it!
-- 
-- ## 1. AIRBASEPOLICE_CAUCASUS Constructor
-- 
-- Creates a new AIRBASEPOLICE_CAUCASUS object that will monitor pilots taxiing behaviour.
-- 
--     -- This creates a new AIRBASEPOLICE_CAUCASUS object.
-- 
--     -- Create a set of all clients in the mission.
--     AllClientsSet = SET_CLIENT:New():FilterStart()
--     
--     -- Monitor for these clients the airbases.
--     AirbasePoliceCaucasus = AIRBASEPOLICE_CAUCASUS:New( AllClientsSet )
-- 
-- @field #AIRBASEPOLICE_CAUCASUS
AIRBASEPOLICE_CAUCASUS = {
  ClassName = "AIRBASEPOLICE_CAUCASUS",
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
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
      MaximumSpeed = 50,
    },
  },
}

--- Creates a new AIRBASEPOLICE_CAUCASUS object.
-- @param #AIRBASEPOLICE_CAUCASUS self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they follow the rules of the airbase.
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.Caucasus enumerator).
-- @return #AIRBASEPOLICE_CAUCASUS self
function AIRBASEPOLICE_CAUCASUS:New( SetClient, AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AIRBASEPOLICE_BASE:New( SetClient, self.Airbases, AirbaseNames ) )



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




--- @type AIRBASEPOLICE_NEVADA
-- @extends #AIRBASEPOLICE_BASE


--- # AIRBASEPOLICE_NEVADA, extends @{#AIRBASEPOLICE_BASE}
-- 
-- ![Banner Image](..\Presentations\AIRBASEPOLICE\Dia1.JPG)
-- 
-- The AIRBASEPOLICE_NEVADA class monitors the speed of the airplanes at the airbase during taxi.
-- The pilots may not drive faster than the maximum speed for the airbase, or they will be despawned.
-- 
-- The pilot will receive 3 times a warning during speeding. After the 3rd warning, if the pilot is still driving
-- faster than the maximum allowed speed, the pilot will be kicked.
-- 
-- Different airbases have different maximum speeds, according safety regulations.
-- 
-- # Airbases monitored
-- 
-- The following airbases are monitored at the Caucasus region:
-- 
--   * Nellis
--   * McCarran
--   * Creech
--   * GroomLake
--
--
-- # Installation
-- 
-- ## In Single Player Missions
-- 
-- AIRBASEPOLICE is fully functional in single player.
-- 
-- ## In Multi Player Missions
-- 
-- AIRBASEPOLICE is NOT functional in multi player, for client machines connecting to the server, running the mission.
-- Due to a bug in DCS since release 1.5, the despawning of clients are not anymore working in multi player.
-- To work around this problem, a much better solution has been made, using the slot blocker script designed
-- by Ciribob. With the help of Ciribob, this script has been extended to also kick client players while in flight.
-- AIRBASEPOLICE is communicating with this modified script to kick players!
-- 
-- Install the file **SimpleSlotBlockGameGUI.lua** on the server, following the installation instructions described by Ciribob.
-- 
-- [Simple Slot Blocker from Ciribob & FlightControl](https://github.com/ciribob/DCS-SimpleSlotBlock)
-- 
-- # Script it!
-- 
-- ## 1. AIRBASEPOLICE_NEVADA Constructor
-- 
-- Creates a new AIRBASEPOLICE_NEVADA object that will monitor pilots taxiing behaviour.
-- 
--     -- This creates a new AIRBASEPOLICE_NEVADA object.
-- 
--     -- Create a set of all clients in the mission.
--     AllClientsSet = SET_CLIENT:New():FilterStart()
--     
--     -- Monitor for these clients the airbases.
--     AirbasePoliceNevada = AIRBASEPOLICE_NEVADA:New( AllClientsSet )
-- 
-- @field #AIRBASEPOLICE_NEVADA
AIRBASEPOLICE_NEVADA = {
  ClassName = "AIRBASEPOLICE_NEVADA",
  Airbases = {
    [AIRBASE.Nevada.Nellis_AFB] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-18687,["x"]=-399380.28571429,},
          [2]={["y"]=-18620.714285714,["x"]=-399436.85714286,},
          [3]={["y"]=-16217.857142857,["x"]=-396596.85714286,},
          [4]={["y"]=-16300.142857143,["x"]=-396530,},
          [5]={["y"]=-18687,["x"]=-399380.85714286,},
        },
        [2] = {
          [1]={["y"]=-18451.571428572,["x"]=-399580.57142857,},
          [2]={["y"]=-18392.142857143,["x"]=-399628.57142857,},
          [3]={["y"]=-16011,["x"]=-396806.85714286,},
          [4]={["y"]=-16074.714285714,["x"]=-396751.71428572,},
          [5]={["y"]=-18451.571428572,["x"]=-399580.85714285,},
        },
      },
      MaximumSpeed = 50,
    },
    [AIRBASE.Nevada.McCarran_International_Airport] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-29408.428571429,["x"]=-416016.28571428,},
          [2]={["y"]=-29408.142857144,["x"]=-416105.42857142,},
          [3]={["y"]=-24680.714285715,["x"]=-416003.14285713,},
          [4]={["y"]=-24681.857142858,["x"]=-415926.57142856,},
          [5]={["y"]=-29408.42857143,["x"]=-416016.57142856,},
        },
        [2] = {
          [1]={["y"]=-28575.571428572,["x"]=-416303.14285713,},
          [2]={["y"]=-28575.571428572,["x"]=-416382.57142856,},
          [3]={["y"]=-25111.000000001,["x"]=-416309.7142857,},
          [4]={["y"]=-25111.000000001,["x"]=-416249.14285713,},
          [5]={["y"]=-28575.571428572,["x"]=-416303.7142857,},
        },
        [3] = {
          [1]={["y"]=-29331.000000001,["x"]=-416275.42857141,},
          [2]={["y"]=-29259.000000001,["x"]=-416306.85714284,},
          [3]={["y"]=-28005.571428572,["x"]=-413449.7142857,},
          [4]={["y"]=-28068.714285715,["x"]=-413422.85714284,},
          [5]={["y"]=-29331.000000001,["x"]=-416275.7142857,},
        },
        [4] = {
          [1]={["y"]=-29073.285714286,["x"]=-416386.57142856,},
          [2]={["y"]=-28997.285714286,["x"]=-416417.42857141,},
          [3]={["y"]=-27697.571428572,["x"]=-413464.57142856,},
          [4]={["y"]=-27767.857142858,["x"]=-413434.28571427,},
          [5]={["y"]=-29073.000000001,["x"]=-416386.85714284,},
        },
      },
      MaximumSpeed = 50,
    },
    [AIRBASE.Nevada.Creech_AFB] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-74237.571428571,["x"]=-360591.7142857,},
          [2]={["y"]=-74234.428571429,["x"]=-360493.71428571,},
          [3]={["y"]=-77605.285714286,["x"]=-360399.14285713,},
          [4]={["y"]=-77608.714285715,["x"]=-360498.85714285,},
          [5]={["y"]=-74237.857142857,["x"]=-360591.7142857,},
        },
        [2] = {
          [1]={["y"]=-75807.571428572,["x"]=-359073.42857142,},
          [2]={["y"]=-74770.142857144,["x"]=-360581.71428571,},
          [3]={["y"]=-74641.285714287,["x"]=-360585.42857142,},
          [4]={["y"]=-75734.142857144,["x"]=-359023.14285714,},
          [5]={["y"]=-75807.285714287,["x"]=-359073.42857142,},
        },
      },
      MaximumSpeed = 50,
    },
    [AIRBASE.Nevada.Groom_Lake_AFB] = {
      PointsRunways = {
        [1] = {
          [1]={["y"]=-86039.000000001,["x"]=-290606.28571428,},
          [2]={["y"]=-85965.285714287,["x"]=-290573.99999999,},
          [3]={["y"]=-87692.714285715,["x"]=-286634.85714285,},
          [4]={["y"]=-87756.714285715,["x"]=-286663.99999999,},
          [5]={["y"]=-86038.714285715,["x"]=-290606.85714285,},
        },
        [2] = {
          [1]={["y"]=-86808.428571429,["x"]=-290375.7142857,},
          [2]={["y"]=-86732.714285715,["x"]=-290344.28571427,},
          [3]={["y"]=-89672.714285714,["x"]=-283546.57142855,},
          [4]={["y"]=-89772.142857143,["x"]=-283587.71428569,},
          [5]={["y"]=-86808.142857143,["x"]=-290375.7142857,},
        },
      },
      MaximumSpeed = 50,
    },
  },
}

--- Creates a new AIRBASEPOLICE_NEVADA object.
-- @param #AIRBASEPOLICE_NEVADA self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they follow the rules of the airbase.
-- @param AirbaseNames A list {} of airbase names (Use AIRBASE.Nevada enumerator).
-- @return #AIRBASEPOLICE_NEVADA self
function AIRBASEPOLICE_NEVADA:New( SetClient, AirbaseNames )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AIRBASEPOLICE_BASE:New( SetClient, self.Airbases, AirbaseNames ) )

--  -- Nellis
--  local NellisBoundary = GROUP:FindByName( "Nellis Boundary" )
--  self.Airbases.Nellis.ZoneBoundary = ZONE_POLYGON:New( "Nellis Boundary", NellisBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
--
--  local NellisRunway1 = GROUP:FindByName( "Nellis Runway 1" )
--  self.Airbases.Nellis.ZoneRunways[1] = ZONE_POLYGON:New( "Nellis Runway 1", NellisRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  local NellisRunway2 = GROUP:FindByName( "Nellis Runway 2" )
--  self.Airbases.Nellis.ZoneRunways[2] = ZONE_POLYGON:New( "Nellis Runway 2", NellisRunway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  -- McCarran
--  local McCarranBoundary = GROUP:FindByName( "McCarran Boundary" )
--  self.Airbases.McCarran.ZoneBoundary = ZONE_POLYGON:New( "McCarran Boundary", McCarranBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
--
--  local McCarranRunway1 = GROUP:FindByName( "McCarran Runway 1" )
--  self.Airbases.McCarran.ZoneRunways[1] = ZONE_POLYGON:New( "McCarran Runway 1", McCarranRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  local McCarranRunway2 = GROUP:FindByName( "McCarran Runway 2" )
--  self.Airbases.McCarran.ZoneRunways[2] = ZONE_POLYGON:New( "McCarran Runway 2", McCarranRunway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  local McCarranRunway3 = GROUP:FindByName( "McCarran Runway 3" )
--  self.Airbases.McCarran.ZoneRunways[3] = ZONE_POLYGON:New( "McCarran Runway 3", McCarranRunway3 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  local McCarranRunway4 = GROUP:FindByName( "McCarran Runway 4" )
--  self.Airbases.McCarran.ZoneRunways[4] = ZONE_POLYGON:New( "McCarran Runway 4", McCarranRunway4 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  -- Creech
--  local CreechBoundary = GROUP:FindByName( "Creech Boundary" )
--  self.Airbases.Creech.ZoneBoundary = ZONE_POLYGON:New( "Creech Boundary", CreechBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
--
--  local CreechRunway1 = GROUP:FindByName( "Creech Runway 1" )
--  self.Airbases.Creech.ZoneRunways[1] = ZONE_POLYGON:New( "Creech Runway 1", CreechRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  local CreechRunway2 = GROUP:FindByName( "Creech Runway 2" )
--  self.Airbases.Creech.ZoneRunways[2] = ZONE_POLYGON:New( "Creech Runway 2", CreechRunway2 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  -- Groom Lake
--  local GroomLakeBoundary = GROUP:FindByName( "GroomLake Boundary" )
--  self.Airbases.GroomLake.ZoneBoundary = ZONE_POLYGON:New( "GroomLake Boundary", GroomLakeBoundary ):SmokeZone(SMOKECOLOR.White):Flush()
--
--  local GroomLakeRunway1 = GROUP:FindByName( "GroomLake Runway 1" )
--  self.Airbases.GroomLake.ZoneRunways[1] = ZONE_POLYGON:New( "GroomLake Runway 1", GroomLakeRunway1 ):SmokeZone(SMOKECOLOR.Red):Flush()
--
--  local GroomLakeRunway2 = GROUP:FindByName( "GroomLake Runway 2" )
--  self.Airbases.GroomLake.ZoneRunways[2] = ZONE_POLYGON:New( "GroomLake Runway 2", GroomLakeRunway2 ):SmokeZone(SMOKECOLOR.Red):Flush()

end


     


     