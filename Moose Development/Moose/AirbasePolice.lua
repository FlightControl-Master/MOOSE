--- This module contains the AIRBASEPOLICE classes.
--
-- ===
--
-- 1) @{AirbasePolice#AIRBASEPOLICE_BASE} class, extends @{Base#BASE}
-- ==================================================================
-- The @{AirbasePolice#AIRBASEPOLICE_BASE} class provides the main methods to monitor CLIENT behaviour at airbases.
-- CLIENTS should not be allowed to:
--
--   * Don't taxi faster than 40 km/h.
--   * Don't take-off on taxiways.
--   * Avoid to hit other planes on the airbase.
--   * Obey ground control orders.
--
-- 2) @{AirbasePolice#AIRBASEPOLICE_CAUCASUS} class, extends @{AirbasePolice#AIRBASEPOLICE_BASE}
-- =============================================================================================
-- All the airbases on the caucasus map can be monitored using this class.
-- If you want to monitor specific airbases, you need to use the @{#AIRBASEPOLICE_BASE.Monitor}() method, which takes a table or airbase names.
-- The following names can be given:
--   * AnapaVityazevo
--   * Batumi
--   * Beslan
--   * Gelendzhik
--   * Gudauta
--   * Kobuleti
--   * KrasnodarCenter
--   * KrasnodarPashkovsky
--   * Krymsk
--   * Kutaisi
--   * MaykopKhanskaya
--   * MineralnyeVody
--   * Mozdok
--   * Nalchik
--   * Novorossiysk
--   * SenakiKolkhi
--   * SochiAdler
--   * Soganlug
--   * SukhumiBabushara
--   * TbilisiLochini
--   * Vaziani
--
-- 3) @{AirbasePolice#AIRBASEPOLICE_NEVADA} class, extends @{AirbasePolice#AIRBASEPOLICE_BASE}
-- =============================================================================================
-- All the airbases on the NEVADA map can be monitored using this class.
-- If you want to monitor specific airbases, you need to use the @{#AIRBASEPOLICE_BASE.Monitor}() method, which takes a table or airbase names.
-- The following names can be given:
--   * Nellis
--   * McCarran
--   * Creech
--   * Groom Lake
--
-- ### Contributions: Dutch Baron - Concept & Testing
-- ### Author: FlightControl - Framework Design &  Programming
--
-- @module AirbasePolice





--- @type AIRBASEPOLICE_BASE
-- @field Set#SET_CLIENT SetClient
-- @extends Base#BASE

AIRBASEPOLICE_BASE = {
  ClassName = "AIRBASEPOLICE_BASE",
  SetClient = nil,
  Airbases = nil,
  AirbaseNames = nil,
}


--- Creates a new AIRBASEPOLICE_BASE object.
-- @param #AIRBASEPOLICE_BASE self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they follow the rules of the airbase.
-- @param Airbases A table of Airbase Names.
-- @return #AIRBASEPOLICE_BASE self
function AIRBASEPOLICE_BASE:New( SetClient, Airbases )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  self:E( { self.ClassName, SetClient, Airbases } )

  self.SetClient = SetClient
  self.Airbases = Airbases

  for AirbaseID, Airbase in pairs( self.Airbases ) do
    Airbase.ZoneBoundary = ZONE_POLYGON_BASE:New( "Boundary", Airbase.PointsBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
    for PointsRunwayID, PointsRunway in pairs( Airbase.PointsRunways ) do
      Airbase.ZoneRunways[PointsRunwayID] = ZONE_POLYGON_BASE:New( "Runway " .. PointsRunwayID, PointsRunway ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
      end
  end

--    -- Template
--    local TemplateBoundary = GROUP:FindByName( "Template Boundary" )
--    self.Airbases.Template.ZoneBoundary = ZONE_POLYGON:New( "Template Boundary", TemplateBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
--  
--    local TemplateRunway1 = GROUP:FindByName( "Template Runway 1" )
--    self.Airbases.Template.ZoneRunways[1] = ZONE_POLYGON:New( "Template Runway 1", TemplateRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()

  self.SetClient:ForEachClient(
    --- @param Client#CLIENT Client
    function( Client )
      Client:SetState( self, "Speeding", false )
      Client:SetState( self, "Warnings", 0)
      Client:SetState( self, "Taxi", false )
    end
  )

  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, {}, 0, 2, 0.05 )

  return self
end

--- @type AIRBASEPOLICE_BASE.AirbaseNames
-- @list <#string>

--- Monitor a table of airbase names.
-- @param #AIRBASEPOLICE_BASE self
-- @param #AIRBASEPOLICE_BASE.AirbaseNames AirbaseNames A list of AirbaseNames to monitor. If this parameters is nil, then all airbases will be monitored.
-- @return #AIRBASEPOLICE_BASE self
function AIRBASEPOLICE_BASE:Monitor( AirbaseNames )

  if AirbaseNames then
    if type( AirbaseNames ) == "table" then
      self.AirbaseNames = AirbaseNames
    else
      self.AirbaseNames = { AirbaseNames }
    end
  end
end

--- @param #AIRBASEPOLICE_BASE self
function AIRBASEPOLICE_BASE:_AirbaseMonitor()

  for AirbaseID, Airbase in pairs( self.Airbases ) do

    if not self.AirbaseNames or self.AirbaseNames[AirbaseID] then

      self:E( AirbaseID )

      self.SetClient:ForEachClientInZone( Airbase.ZoneBoundary,

        --- @param Client#CLIENT Client
        function( Client )

          self:E( Client.UnitName )
          if Client:IsAlive() then
            local NotInRunwayZone = true
            for ZoneRunwayID, ZoneRunway in pairs( Airbase.ZoneRunways ) do
              NotInRunwayZone = ( Client:IsNotInZone( ZoneRunway ) == true ) and NotInRunwayZone or false
            end

            if NotInRunwayZone then
              local Taxi = self:GetState( self, "Taxi" )
              self:E( Taxi )
              if Taxi == false then
                Client:Message( "Welcome at " .. AirbaseID .. ". The maximum taxiing speed is " .. Airbase.MaximumSpeed " km/h.", 20, "ATC" )
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

                if Velocity > Airbase.MaximumSpeed then
                  local IsSpeeding = Client:GetState( self, "Speeding" )

                  if IsSpeeding == true then
                    local SpeedingWarnings = Client:GetState( self, "Warnings" )
                    self:T( SpeedingWarnings )

                    if SpeedingWarnings <= 3 then
                      Client:Message( "You are speeding on the taxiway! Slow down or you will be removed from this airbase! Your current velocity is " .. string.format( "%2.0f km/h", Velocity ), 5, "Warning " .. SpeedingWarnings .. " / 3" )
                      Client:SetState( self, "Warnings", SpeedingWarnings + 1 )
                    else
                      MESSAGE:New( "Player " .. Client:GetPlayerName() .. " has been removed from the airbase, due to a speeding violation ...", 10, "Airbase Police" ):ToAll()
                      Client:GetGroup():Destroy()
                      Client:SetState( self, "Speeding", false )
                      Client:SetState( self, "Warnings", 0 )
                    end

                  else
                    Client:Message( "You are speeding on the taxiway, slow down now! Your current velocity is " .. string.format( "%2.0f km/h", Velocity ), 5, "Attention! " )
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
-- @field Set#SET_CLIENT SetClient
-- @extends #AIRBASEPOLICE_BASE

AIRBASEPOLICE_CAUCASUS = {
  ClassName = "AIRBASEPOLICE_CAUCASUS",
  Airbases = {
    AnapaVityazevo = {
      PointsBoundary = {
        [1]={["y"]=242234.85714287,["x"]=-6616.5714285726,},
        [2]={["y"]=241060.57142858,["x"]=-5585.142857144,},
        [3]={["y"]=243806.2857143,["x"]=-3962.2857142868,},
        [4]={["y"]=245240.57142858,["x"]=-4816.5714285726,},
        [5]={["y"]=244783.42857144,["x"]=-5630.8571428583,},
        [6]={["y"]=243800.57142858,["x"]=-5065.142857144,},
        [7]={["y"]=242232.00000001,["x"]=-6622.2857142868,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=242140.57142858,["x"]=-6478.8571428583,},
          [2]={["y"]=242188.57142858,["x"]=-6522.0000000011,},
          [3]={["y"]=244124.2857143,["x"]=-4344.0000000011,},
          [4]={["y"]=244068.2857143,["x"]=-4296.5714285726,},
          [5]={["y"]=242140.57142858,["x"]=-6480.0000000011,}
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Batumi = {
      PointsBoundary = {
        [1]={["y"]=617567.14285714,["x"]=-355313.14285715,},
        [2]={["y"]=616181.42857142,["x"]=-354800.28571429,},
        [3]={["y"]=616007.14285714,["x"]=-355128.85714286,},
        [4]={["y"]=618230,["x"]=-356914.57142858,},
        [5]={["y"]=618727.14285714,["x"]=-356166,},
        [6]={["y"]=617572.85714285,["x"]=-355308.85714286,},
      },
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
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Beslan = {
      PointsBoundary = {
        [1]={["y"]=842082.57142857,["x"]=-148445.14285715,},
        [2]={["y"]=845237.71428572,["x"]=-148639.71428572,},
        [3]={["y"]=845232,["x"]=-148765.42857143,},
        [4]={["y"]=844220.57142857,["x"]=-149168.28571429,},
        [5]={["y"]=843274.85714286,["x"]=-149125.42857143,},
        [6]={["y"]=842077.71428572,["x"]=-148554,},
        [7]={["y"]=842083.42857143,["x"]=-148445.42857143,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=842104.57142857,["x"]=-148460.57142857,},
          [2]={["y"]=845225.71428572,["x"]=-148656,},
          [3]={["y"]=845220.57142858,["x"]=-148750,},
          [4]={["y"]=842098.85714286,["x"]=-148556.28571429,},
          [5]={["y"]=842104,["x"]=-148460.28571429,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Gelendzhik = {
      PointsBoundary = {
        [1]={["y"]=297856.00000001,["x"]=-51151.428571429,},
        [2]={["y"]=299044.57142858,["x"]=-49720.000000001,},
        [3]={["y"]=298861.71428572,["x"]=-49580.000000001,},
        [4]={["y"]=298198.85714286,["x"]=-49842.857142858,},
        [5]={["y"]=297990.28571429,["x"]=-50151.428571429,},
        [6]={["y"]=297696.00000001,["x"]=-51054.285714286,},
        [7]={["y"]=297850.28571429,["x"]=-51160.000000001,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=297834.00000001,["x"]=-51107.428571429,},
          [2]={["y"]=297786.57142858,["x"]=-51068.857142858,},
          [3]={["y"]=298946.57142858,["x"]=-49686.000000001,},
          [4]={["y"]=298993.14285715,["x"]=-49725.714285715,},
          [5]={["y"]=297835.14285715,["x"]=-51107.714285715,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Gudauta = {
      PointsBoundary = {
        [1]={["y"]=517246.57142857,["x"]=-197850.28571429,},
        [2]={["y"]=516749.42857142,["x"]=-198070.28571429,},
        [3]={["y"]=515755.14285714,["x"]=-197598.85714286,},
        [4]={["y"]=515369.42857142,["x"]=-196538.85714286,},
        [5]={["y"]=515623.71428571,["x"]=-195618.85714286,},
        [6]={["y"]=515946.57142857,["x"]=-195510.28571429,},
        [7]={["y"]=517243.71428571,["x"]=-197858.85714286,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=517096.57142857,["x"]=-197804.57142857,},
          [2]={["y"]=515880.85714285,["x"]=-195590.28571429,},
          [3]={["y"]=515812.28571428,["x"]=-195628.85714286,},
          [4]={["y"]=517036.57142857,["x"]=-197834.57142857,},
          [5]={["y"]=517097.99999999,["x"]=-197807.42857143,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Kobuleti = {
      PointsBoundary = {
        [1]={["y"]=634427.71428571,["x"]=-318290.28571429,},
        [2]={["y"]=635033.42857143,["x"]=-317550.2857143,},
        [3]={["y"]=635864.85714286,["x"]=-317333.14285715,},
        [4]={["y"]=636967.71428571,["x"]=-317261.71428572,},
        [5]={["y"]=637144.85714286,["x"]=-317913.14285715,},
        [6]={["y"]=634630.57142857,["x"]=-318687.42857144,},
        [7]={["y"]=634424.85714286,["x"]=-318290.2857143,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=634509.71428571,["x"]=-318339.42857144,},
          [2]={["y"]=636767.42857143,["x"]=-317516.57142858,},
          [3]={["y"]=636790,["x"]=-317575.71428572,},
          [4]={["y"]=634531.42857143,["x"]=-318398.00000001,},
          [5]={["y"]=634510.28571429,["x"]=-318339.71428572,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    KrasnodarCenter = {
      PointsBoundary = {
        [1]={["y"]=366680.28571429,["x"]=11699.142857142,},
        [2]={["y"]=366654.28571429,["x"]=11225.142857142,},
        [3]={["y"]=367497.14285715,["x"]=11082.285714285,},
        [4]={["y"]=368025.71428572,["x"]=10396.57142857,},
        [5]={["y"]=369854.28571429,["x"]=11367.999999999,},
        [6]={["y"]=369840.00000001,["x"]=11910.857142856,},
        [7]={["y"]=366682.57142858,["x"]=11697.999999999,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=369205.42857144,["x"]=11789.142857142,},
          [2]={["y"]=369209.71428572,["x"]=11714.857142856,},
          [3]={["y"]=366699.71428572,["x"]=11581.714285713,},
          [4]={["y"]=366698.28571429,["x"]=11659.142857142,},
          [5]={["y"]=369208.85714286,["x"]=11788.57142857,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    KrasnodarPashkovsky = {
      PointsBoundary = {
        [1]={["y"]=386754,["x"]=6476.5714285703,},
        [2]={["y"]=389182.57142858,["x"]=8722.2857142846,},
        [3]={["y"]=388832.57142858,["x"]=9086.5714285703,},
        [4]={["y"]=386961.14285715,["x"]=7707.9999999989,},
        [5]={["y"]=385404,["x"]=9179.4285714274,},
        [6]={["y"]=383239.71428572,["x"]=7386.5714285703,},
        [7]={["y"]=383954,["x"]=6486.5714285703,},
        [8]={["y"]=385775.42857143,["x"]=8097.9999999989,},
        [9]={["y"]=386804,["x"]=7319.4285714274,},
        [10]={["y"]=386375.42857143,["x"]=6797.9999999989,},
        [11]={["y"]=386746.85714286,["x"]=6472.2857142846,},
      },
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
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Krymsk = {
      PointsBoundary = {
        [1]={["y"]=293338.00000001,["x"]=-7575.4285714297,},
        [2]={["y"]=295199.42857144,["x"]=-5434.0000000011,},
        [3]={["y"]=295595.14285715,["x"]=-6239.7142857154,},
        [4]={["y"]=294152.2857143,["x"]=-8325.4285714297,},
        [5]={["y"]=293345.14285715,["x"]=-7596.8571428582,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=293522.00000001,["x"]=-7567.4285714297,},
          [2]={["y"]=293578.57142858,["x"]=-7616.0000000011,},
          [3]={["y"]=295246.00000001,["x"]=-5591.142857144,},
          [4]={["y"]=295187.71428573,["x"]=-5546.0000000011,},
          [5]={["y"]=293523.14285715,["x"]=-7568.2857142868,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Kutaisi = {
      PointsBoundary = {
        [1]={["y"]=682087.42857143,["x"]=-284512.85714286,},
        [2]={["y"]=685387.42857143,["x"]=-283662.85714286,},
        [3]={["y"]=685294.57142857,["x"]=-284977.14285715,},
        [4]={["y"]=682744.57142857,["x"]=-286505.71428572,},
        [5]={["y"]=682094.57142857,["x"]=-284527.14285715,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=682638,["x"]=-285202.28571429,},
          [2]={["y"]=685050.28571429,["x"]=-284507.42857144,},
          [3]={["y"]=685068.85714286,["x"]=-284578.85714286,},
          [4]={["y"]=682657.42857143,["x"]=-285264.28571429,},
          [5]={["y"]=682638.28571429,["x"]=-285202.85714286,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    MaykopKhanskaya = {
      PointsBoundary = {
        [1]={["y"]=456876.28571429,["x"]=-27665.42857143,},
        [2]={["y"]=457800,["x"]=-28392.857142858,},
        [3]={["y"]=459368.57142857,["x"]=-26378.571428573,},
        [4]={["y"]=459425.71428572,["x"]=-25242.857142858,},
        [5]={["y"]=458961.42857143,["x"]=-24964.285714287,},
        [6]={["y"]=456878.57142857,["x"]=-27667.714285715,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=457005.42857143,["x"]=-27668.000000001,},
          [2]={["y"]=459028.85714286,["x"]=-25168.857142858,},
          [3]={["y"]=459082.57142857,["x"]=-25216.857142858,},
          [4]={["y"]=457060,["x"]=-27714.285714287,},
          [5]={["y"]=457004.57142857,["x"]=-27669.714285715,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    MineralnyeVody = {
      PointsBoundary = {
        [1]={["y"]=703857.14285714,["x"]=-50226.000000002,},
        [2]={["y"]=707385.71428571,["x"]=-51911.714285716,},
        [3]={["y"]=707595.71428571,["x"]=-51434.857142859,},
        [4]={["y"]=707900,["x"]=-51568.857142859,},
        [5]={["y"]=707542.85714286,["x"]=-52326.000000002,},
        [6]={["y"]=706628.57142857,["x"]=-52568.857142859,},
        [7]={["y"]=705142.85714286,["x"]=-51790.285714288,},
        [8]={["y"]=703678.57142857,["x"]=-50611.714285716,},
        [9]={["y"]=703857.42857143,["x"]=-50226.857142859,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=703904,["x"]=-50352.571428573,},
          [2]={["y"]=707596.28571429,["x"]=-52094.571428573,},
          [3]={["y"]=707560.57142858,["x"]=-52161.714285716,},
          [4]={["y"]=703871.71428572,["x"]=-50420.571428573,},
          [5]={["y"]=703902,["x"]=-50352.000000002,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Mozdok = {
      PointsBoundary = {
        [1]={["y"]=832123.42857143,["x"]=-83608.571428573,},
        [2]={["y"]=835916.28571429,["x"]=-83144.285714288,},
        [3]={["y"]=835474.28571429,["x"]=-84170.571428573,},
        [4]={["y"]=832911.42857143,["x"]=-84470.571428573,},
        [5]={["y"]=832487.71428572,["x"]=-85565.714285716,},
        [6]={["y"]=831573.42857143,["x"]=-85351.42857143,},
        [7]={["y"]=832123.71428572,["x"]=-83610.285714288,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=832201.14285715,["x"]=-83699.428571431,},
          [2]={["y"]=832212.57142857,["x"]=-83780.571428574,},
          [3]={["y"]=835730.28571429,["x"]=-83335.714285717,},
          [4]={["y"]=835718.85714286,["x"]=-83246.571428574,},
          [5]={["y"]=832200.57142857,["x"]=-83700.000000002,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Nalchik = {
      PointsBoundary = {
        [1]={["y"]=759370,["x"]=-125502.85714286,},
        [2]={["y"]=761384.28571429,["x"]=-124177.14285714,},
        [3]={["y"]=761472.85714286,["x"]=-124325.71428572,},
        [4]={["y"]=761092.85714286,["x"]=-125048.57142857,},
        [5]={["y"]=760295.71428572,["x"]=-125685.71428572,},
        [6]={["y"]=759444.28571429,["x"]=-125734.28571429,},
        [7]={["y"]=759375.71428572,["x"]=-125511.42857143,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=759454.28571429,["x"]=-125551.42857143,},
          [2]={["y"]=759492.85714286,["x"]=-125610.85714286,},
          [3]={["y"]=761406.28571429,["x"]=-124304.28571429,},
          [4]={["y"]=761361.14285714,["x"]=-124239.71428572,},
          [5]={["y"]=759456,["x"]=-125552.57142857,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Novorossiysk = {
      PointsBoundary = {
        [1]={["y"]=278677.71428573,["x"]=-41656.571428572,},
        [2]={["y"]=278446.2857143,["x"]=-41453.714285715,},
        [3]={["y"]=278989.14285716,["x"]=-40188.000000001,},
        [4]={["y"]=279717.71428573,["x"]=-39968.000000001,},
        [5]={["y"]=280020.57142859,["x"]=-40208.000000001,},
        [6]={["y"]=278674.85714287,["x"]=-41660.857142858,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=278673.14285716,["x"]=-41615.142857144,},
          [2]={["y"]=278625.42857144,["x"]=-41570.571428572,},
          [3]={["y"]=279835.42857144,["x"]=-40226.000000001,},
          [4]={["y"]=279882.2857143,["x"]=-40270.000000001,},
          [5]={["y"]=278672.00000001,["x"]=-41614.857142858,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    SenakiKolkhi = {
      PointsBoundary = {
        [1]={["y"]=646036.57142857,["x"]=-281778.85714286,},
        [2]={["y"]=646045.14285714,["x"]=-281191.71428571,},
        [3]={["y"]=647032.28571429,["x"]=-280598.85714285,},
        [4]={["y"]=647669.42857143,["x"]=-281273.14285714,},
        [5]={["y"]=648323.71428571,["x"]=-281370.28571428,},
        [6]={["y"]=648520.85714286,["x"]=-281978.85714285,},
        [7]={["y"]=646039.42857143,["x"]=-281783.14285714,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=646060.85714285,["x"]=-281736,},
          [2]={["y"]=646056.57142857,["x"]=-281631.71428571,},
          [3]={["y"]=648442.28571428,["x"]=-281840.28571428,},
          [4]={["y"]=648432.28571428,["x"]=-281918.85714286,},
          [5]={["y"]=646063.71428571,["x"]=-281738.85714286,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    SochiAdler = {
      PointsBoundary = {
        [1]={["y"]=460642.28571428,["x"]=-164861.71428571,},
        [2]={["y"]=462820.85714285,["x"]=-163368.85714286,},
        [3]={["y"]=463649.42857142,["x"]=-163340.28571429,},
        [4]={["y"]=463835.14285714,["x"]=-164040.28571429,},
        [5]={["y"]=462535.14285714,["x"]=-165654.57142857,},
        [6]={["y"]=460678,["x"]=-165247.42857143,},
        [7]={["y"]=460635.14285714,["x"]=-164876,},
      },
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
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Soganlug = {
      PointsBoundary = {
        [1]={["y"]=894530.85714286,["x"]=-316928.28571428,},
        [2]={["y"]=896422.28571428,["x"]=-318622.57142857,},
        [3]={["y"]=896090.85714286,["x"]=-318934,},
        [4]={["y"]=894019.42857143,["x"]=-317119.71428571,},
        [5]={["y"]=894533.71428571,["x"]=-316925.42857143,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=894525.71428571,["x"]=-316964,},
          [2]={["y"]=896363.14285714,["x"]=-318634.28571428,},
          [3]={["y"]=896299.14285714,["x"]=-318702.85714286,},
          [4]={["y"]=894464,["x"]=-317031.71428571,},
          [5]={["y"]=894524.57142857,["x"]=-316963.71428571,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    SukhumiBabushara = {
      PointsBoundary = {
        [1]={["y"]=562541.14285714,["x"]=-219852.28571429,},
        [2]={["y"]=562691.14285714,["x"]=-219395.14285714,},
        [3]={["y"]=564326.85714286,["x"]=-219523.71428571,},
        [4]={["y"]=566262.57142857,["x"]=-221166.57142857,},
        [5]={["y"]=566069.71428571,["x"]=-221580.85714286,},
        [6]={["y"]=562534,["x"]=-219873.71428571,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=562684,["x"]=-219779.71428571,},
          [2]={["y"]=562717.71428571,["x"]=-219718,},
          [3]={["y"]=566046.85714286,["x"]=-221376.57142857,},
          [4]={["y"]=566012.28571428,["x"]=-221446.57142857,},
          [5]={["y"]=562684.57142857,["x"]=-219782.57142857,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    TbilisiLochini = {
      PointsBoundary = {
        [1]={["y"]=895172.85714286,["x"]=-314667.42857143,},
        [2]={["y"]=895337.42857143,["x"]=-314143.14285714,},
        [3]={["y"]=895990.28571429,["x"]=-314036,},
        [4]={["y"]=897730.28571429,["x"]=-315284.57142857,},
        [5]={["y"]=897901.71428571,["x"]=-316284.57142857,},
        [6]={["y"]=897684.57142857,["x"]=-316618.85714286,},
        [7]={["y"]=895173.14285714,["x"]=-314667.42857143,},
      },
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
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Vaziani = {
      PointsBoundary = {
        [1]={["y"]=902122,["x"]=-318163.71428572,},
        [2]={["y"]=902678.57142857,["x"]=-317594,},
        [3]={["y"]=903275.71428571,["x"]=-317405.42857143,},
        [4]={["y"]=903418.57142857,["x"]=-317891.14285714,},
        [5]={["y"]=904292.85714286,["x"]=-318748.28571429,},
        [6]={["y"]=904542,["x"]=-319740.85714286,},
        [7]={["y"]=904042,["x"]=-320166.57142857,},
        [8]={["y"]=902121.42857143,["x"]=-318164.85714286,},
      },
      PointsRunways = {
        [1] = {
          [1]={["y"]=902239.14285714,["x"]=-318190.85714286,},
          [2]={["y"]=904014.28571428,["x"]=-319994.57142857,},
          [3]={["y"]=904064.85714285,["x"]=-319945.14285715,},
          [4]={["y"]=902294.57142857,["x"]=-318146,},
          [5]={["y"]=902247.71428571,["x"]=-318190.85714286,},
        },
      },
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
  },
}

--- Creates a new AIRBASEPOLICE_CAUCASUS object.
-- @param #AIRBASEPOLICE_CAUCASUS self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they follow the rules of the airbase.
-- @return #AIRBASEPOLICE_CAUCASUS self
function AIRBASEPOLICE_CAUCASUS:New( SetClient )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AIRBASEPOLICE_BASE:New( SetClient, self.Airbases ) )

  --    -- AnapaVityazevo
  --    local AnapaVityazevoBoundary = GROUP:FindByName( "AnapaVityazevo Boundary" )
  --    self.Airbases.AnapaVityazevo.ZoneBoundary = ZONE_POLYGON:New( "AnapaVityazevo Boundary", AnapaVityazevoBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --  
  --    local AnapaVityazevoRunway1 = GROUP:FindByName( "AnapaVityazevo Runway 1" )
  --    self.Airbases.AnapaVityazevo.ZoneRunways[1] = ZONE_POLYGON:New( "AnapaVityazevo Runway 1", AnapaVityazevoRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --  
  --
  --
  --    -- Batumi
  --    local BatumiBoundary = GROUP:FindByName( "Batumi Boundary" )
  --    self.Airbases.Batumi.ZoneBoundary = ZONE_POLYGON:New( "Batumi Boundary", BatumiBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local BatumiRunway1 = GROUP:FindByName( "Batumi Runway 1" )
  --    self.Airbases.Batumi.ZoneRunways[1] = ZONE_POLYGON:New( "Batumi Runway 1", BatumiRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Beslan
  --    local BeslanBoundary = GROUP:FindByName( "Beslan Boundary" )
  --    self.Airbases.Beslan.ZoneBoundary = ZONE_POLYGON:New( "Beslan Boundary", BeslanBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local BeslanRunway1 = GROUP:FindByName( "Beslan Runway 1" )
  --    self.Airbases.Beslan.ZoneRunways[1] = ZONE_POLYGON:New( "Beslan Runway 1", BeslanRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Gelendzhik
  --    local GelendzhikBoundary = GROUP:FindByName( "Gelendzhik Boundary" )
  --    self.Airbases.Gelendzhik.ZoneBoundary = ZONE_POLYGON:New( "Gelendzhik Boundary", GelendzhikBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local GelendzhikRunway1 = GROUP:FindByName( "Gelendzhik Runway 1" )
  --    self.Airbases.Gelendzhik.ZoneRunways[1] = ZONE_POLYGON:New( "Gelendzhik Runway 1", GelendzhikRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Gudauta
  --    local GudautaBoundary = GROUP:FindByName( "Gudauta Boundary" )
  --    self.Airbases.Gudauta.ZoneBoundary = ZONE_POLYGON:New( "Gudauta Boundary", GudautaBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local GudautaRunway1 = GROUP:FindByName( "Gudauta Runway 1" )
  --    self.Airbases.Gudauta.ZoneRunways[1] = ZONE_POLYGON:New( "Gudauta Runway 1", GudautaRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Kobuleti
  --    local KobuletiBoundary = GROUP:FindByName( "Kobuleti Boundary" )
  --    self.Airbases.Kobuleti.ZoneBoundary = ZONE_POLYGON:New( "Kobuleti Boundary", KobuletiBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local KobuletiRunway1 = GROUP:FindByName( "Kobuleti Runway 1" )
  --    self.Airbases.Kobuleti.ZoneRunways[1] = ZONE_POLYGON:New( "Kobuleti Runway 1", KobuletiRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- KrasnodarCenter
  --    local KrasnodarCenterBoundary = GROUP:FindByName( "KrasnodarCenter Boundary" )
  --    self.Airbases.KrasnodarCenter.ZoneBoundary = ZONE_POLYGON:New( "KrasnodarCenter Boundary", KrasnodarCenterBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local KrasnodarCenterRunway1 = GROUP:FindByName( "KrasnodarCenter Runway 1" )
  --    self.Airbases.KrasnodarCenter.ZoneRunways[1] = ZONE_POLYGON:New( "KrasnodarCenter Runway 1", KrasnodarCenterRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- KrasnodarPashkovsky
  --    local KrasnodarPashkovskyBoundary = GROUP:FindByName( "KrasnodarPashkovsky Boundary" )
  --    self.Airbases.KrasnodarPashkovsky.ZoneBoundary = ZONE_POLYGON:New( "KrasnodarPashkovsky Boundary", KrasnodarPashkovskyBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local KrasnodarPashkovskyRunway1 = GROUP:FindByName( "KrasnodarPashkovsky Runway 1" )
  --    self.Airbases.KrasnodarPashkovsky.ZoneRunways[1] = ZONE_POLYGON:New( "KrasnodarPashkovsky Runway 1", KrasnodarPashkovskyRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --    local KrasnodarPashkovskyRunway2 = GROUP:FindByName( "KrasnodarPashkovsky Runway 2" )
  --    self.Airbases.KrasnodarPashkovsky.ZoneRunways[2] = ZONE_POLYGON:New( "KrasnodarPashkovsky Runway 2", KrasnodarPashkovskyRunway2 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Krymsk
  --    local KrymskBoundary = GROUP:FindByName( "Krymsk Boundary" )
  --    self.Airbases.Krymsk.ZoneBoundary = ZONE_POLYGON:New( "Krymsk Boundary", KrymskBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local KrymskRunway1 = GROUP:FindByName( "Krymsk Runway 1" )
  --    self.Airbases.Krymsk.ZoneRunways[1] = ZONE_POLYGON:New( "Krymsk Runway 1", KrymskRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Kutaisi
  --    local KutaisiBoundary = GROUP:FindByName( "Kutaisi Boundary" )
  --    self.Airbases.Kutaisi.ZoneBoundary = ZONE_POLYGON:New( "Kutaisi Boundary", KutaisiBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local KutaisiRunway1 = GROUP:FindByName( "Kutaisi Runway 1" )
  --    self.Airbases.Kutaisi.ZoneRunways[1] = ZONE_POLYGON:New( "Kutaisi Runway 1", KutaisiRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- MaykopKhanskaya
  --    local MaykopKhanskayaBoundary = GROUP:FindByName( "MaykopKhanskaya Boundary" )
  --    self.Airbases.MaykopKhanskaya.ZoneBoundary = ZONE_POLYGON:New( "MaykopKhanskaya Boundary", MaykopKhanskayaBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local MaykopKhanskayaRunway1 = GROUP:FindByName( "MaykopKhanskaya Runway 1" )
  --    self.Airbases.MaykopKhanskaya.ZoneRunways[1] = ZONE_POLYGON:New( "MaykopKhanskaya Runway 1", MaykopKhanskayaRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- MineralnyeVody
  --    local MineralnyeVodyBoundary = GROUP:FindByName( "MineralnyeVody Boundary" )
  --    self.Airbases.MineralnyeVody.ZoneBoundary = ZONE_POLYGON:New( "MineralnyeVody Boundary", MineralnyeVodyBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local MineralnyeVodyRunway1 = GROUP:FindByName( "MineralnyeVody Runway 1" )
  --    self.Airbases.MineralnyeVody.ZoneRunways[1] = ZONE_POLYGON:New( "MineralnyeVody Runway 1", MineralnyeVodyRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Mozdok
  --    local MozdokBoundary = GROUP:FindByName( "Mozdok Boundary" )
  --    self.Airbases.Mozdok.ZoneBoundary = ZONE_POLYGON:New( "Mozdok Boundary", MozdokBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local MozdokRunway1 = GROUP:FindByName( "Mozdok Runway 1" )
  --    self.Airbases.Mozdok.ZoneRunways[1] = ZONE_POLYGON:New( "Mozdok Runway 1", MozdokRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Nalchik
  --    local NalchikBoundary = GROUP:FindByName( "Nalchik Boundary" )
  --    self.Airbases.Nalchik.ZoneBoundary = ZONE_POLYGON:New( "Nalchik Boundary", NalchikBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local NalchikRunway1 = GROUP:FindByName( "Nalchik Runway 1" )
  --    self.Airbases.Nalchik.ZoneRunways[1] = ZONE_POLYGON:New( "Nalchik Runway 1", NalchikRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Novorossiysk
  --    local NovorossiyskBoundary = GROUP:FindByName( "Novorossiysk Boundary" )
  --    self.Airbases.Novorossiysk.ZoneBoundary = ZONE_POLYGON:New( "Novorossiysk Boundary", NovorossiyskBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local NovorossiyskRunway1 = GROUP:FindByName( "Novorossiysk Runway 1" )
  --    self.Airbases.Novorossiysk.ZoneRunways[1] = ZONE_POLYGON:New( "Novorossiysk Runway 1", NovorossiyskRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- SenakiKolkhi
  --    local SenakiKolkhiBoundary = GROUP:FindByName( "SenakiKolkhi Boundary" )
  --    self.Airbases.SenakiKolkhi.ZoneBoundary = ZONE_POLYGON:New( "SenakiKolkhi Boundary", SenakiKolkhiBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local SenakiKolkhiRunway1 = GROUP:FindByName( "SenakiKolkhi Runway 1" )
  --    self.Airbases.SenakiKolkhi.ZoneRunways[1] = ZONE_POLYGON:New( "SenakiKolkhi Runway 1", SenakiKolkhiRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- SochiAdler
  --    local SochiAdlerBoundary = GROUP:FindByName( "SochiAdler Boundary" )
  --    self.Airbases.SochiAdler.ZoneBoundary = ZONE_POLYGON:New( "SochiAdler Boundary", SochiAdlerBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local SochiAdlerRunway1 = GROUP:FindByName( "SochiAdler Runway 1" )
  --    self.Airbases.SochiAdler.ZoneRunways[1] = ZONE_POLYGON:New( "SochiAdler Runway 1", SochiAdlerRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --    local SochiAdlerRunway2 = GROUP:FindByName( "SochiAdler Runway 2" )
  --    self.Airbases.SochiAdler.ZoneRunways[2] = ZONE_POLYGON:New( "SochiAdler Runway 2", SochiAdlerRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Soganlug
  --    local SoganlugBoundary = GROUP:FindByName( "Soganlug Boundary" )
  --    self.Airbases.Soganlug.ZoneBoundary = ZONE_POLYGON:New( "Soganlug Boundary", SoganlugBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local SoganlugRunway1 = GROUP:FindByName( "Soganlug Runway 1" )
  --    self.Airbases.Soganlug.ZoneRunways[1] = ZONE_POLYGON:New( "Soganlug Runway 1", SoganlugRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- SukhumiBabushara
  --    local SukhumiBabusharaBoundary = GROUP:FindByName( "SukhumiBabushara Boundary" )
  --    self.Airbases.SukhumiBabushara.ZoneBoundary = ZONE_POLYGON:New( "SukhumiBabushara Boundary", SukhumiBabusharaBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local SukhumiBabusharaRunway1 = GROUP:FindByName( "SukhumiBabushara Runway 1" )
  --    self.Airbases.SukhumiBabushara.ZoneRunways[1] = ZONE_POLYGON:New( "SukhumiBabushara Runway 1", SukhumiBabusharaRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- TbilisiLochini
  --    local TbilisiLochiniBoundary = GROUP:FindByName( "TbilisiLochini Boundary" )
  --    self.Airbases.TbilisiLochini.ZoneBoundary = ZONE_POLYGON:New( "TbilisiLochini Boundary", TbilisiLochiniBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --  
  --    local TbilisiLochiniRunway1 = GROUP:FindByName( "TbilisiLochini Runway 1" )
  --    self.Airbases.TbilisiLochini.ZoneRunways[1] = ZONE_POLYGON:New( "TbilisiLochini Runway 1", TbilisiLochiniRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --      
  --    local TbilisiLochiniRunway2 = GROUP:FindByName( "TbilisiLochini Runway 2" )
  --    self.Airbases.TbilisiLochini.ZoneRunways[2] = ZONE_POLYGON:New( "TbilisiLochini Runway 2", TbilisiLochiniRunway2 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --
  --    -- Vaziani
  --    local VazianiBoundary = GROUP:FindByName( "Vaziani Boundary" )
  --    self.Airbases.Vaziani.ZoneBoundary = ZONE_POLYGON:New( "Vaziani Boundary", VazianiBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --
  --    local VazianiRunway1 = GROUP:FindByName( "Vaziani Runway 1" )
  --    self.Airbases.Vaziani.ZoneRunways[1] = ZONE_POLYGON:New( "Vaziani Runway 1", VazianiRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
  --
  --
  --


        -- Template
  --    local TemplateBoundary = GROUP:FindByName( "Template Boundary" )
  --    self.Airbases.Template.ZoneBoundary = ZONE_POLYGON:New( "Template Boundary", TemplateBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
  --  
  --    local TemplateRunway1 = GROUP:FindByName( "Template Runway 1" )
  --    self.Airbases.Template.ZoneRunways[1] = ZONE_POLYGON:New( "Template Runway 1", TemplateRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()

  return self

end




--- @type AIRBASEPOLICE_NEVADA
-- @extends AirbasePolice#AIRBASEPOLICE_BASE
AIRBASEPOLICE_NEVADA = {
  ClassName = "AIRBASEPOLICE_NEVADA",
  Airbases = {
    Nellis = {
      PointsBoundary = {
        [1]={["y"]=-17814.714285714,["x"]=-399823.14285714,},
        [2]={["y"]=-16875.857142857,["x"]=-398763.14285714,},
        [3]={["y"]=-16251.571428571,["x"]=-398988.85714286,},
        [4]={["y"]=-16163,["x"]=-398693.14285714,},
        [5]={["y"]=-16328.714285714,["x"]=-398034.57142857,},
        [6]={["y"]=-15943,["x"]=-397571.71428571,},
        [7]={["y"]=-15711.571428571,["x"]=-397551.71428571,},
        [8]={["y"]=-15748.714285714,["x"]=-396806,},
        [9]={["y"]=-16288.714285714,["x"]=-396517.42857143,},
        [10]={["y"]=-16751.571428571,["x"]=-396308.85714286,},
        [11]={["y"]=-17263,["x"]=-396234.57142857,},
        [12]={["y"]=-17577.285714286,["x"]=-396640.28571429,},
        [13]={["y"]=-17614.428571429,["x"]=-397400.28571429,},
        [14]={["y"]=-19405.857142857,["x"]=-399428.85714286,},
        [15]={["y"]=-19234.428571429,["x"]=-399683.14285714,},
        [16]={["y"]=-18708.714285714,["x"]=-399408.85714286,},
        [17]={["y"]=-18397.285714286,["x"]=-399657.42857143,},
        [18]={["y"]=-17814.428571429,["x"]=-399823.42857143,},
      },
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
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    McCarran = {
      PointsBoundary = {
        [1]={["y"]=-29455.285714286,["x"]=-416277.42857142,},
        [2]={["y"]=-28860.142857143,["x"]=-416492,},
        [3]={["y"]=-25044.428571429,["x"]=-416344.85714285,},
        [4]={["y"]=-24580.142857143,["x"]=-415959.14285714,},
        [5]={["y"]=-25073,["x"]=-415630.57142857,},
        [6]={["y"]=-25087.285714286,["x"]=-415130.57142857,},
        [7]={["y"]=-25830.142857143,["x"]=-414866.28571428,},
        [8]={["y"]=-26658.714285715,["x"]=-414880.57142857,},
        [9]={["y"]=-26973,["x"]=-415273.42857142,},
        [10]={["y"]=-27380.142857143,["x"]=-415187.71428571,},
        [11]={["y"]=-27715.857142857,["x"]=-414144.85714285,},
        [12]={["y"]=-27551.571428572,["x"]=-413473.42857142,},
        [13]={["y"]=-28630.142857143,["x"]=-413201.99999999,},
        [14]={["y"]=-29494.428571429,["x"]=-415437.71428571,},
        [15]={["y"]=-29455.571428572,["x"]=-416277.71428571,},
      },
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
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    Creech = {
      PointsBoundary = {
        [1]={["y"]=-74522.714285715,["x"]=-360887.99999998,},
        [2]={["y"]=-74197,["x"]=-360556.57142855,},
        [3]={["y"]=-74402.714285715,["x"]=-359639.42857141,},
        [4]={["y"]=-74637,["x"]=-359279.42857141,},
        [5]={["y"]=-75759.857142857,["x"]=-359005.14285712,},
        [6]={["y"]=-75834.142857143,["x"]=-359045.14285712,},
        [7]={["y"]=-75902.714285714,["x"]=-359782.28571427,},
        [8]={["y"]=-76099.857142857,["x"]=-360399.42857141,},
        [9]={["y"]=-77314.142857143,["x"]=-360219.42857141,},
        [10]={["y"]=-77728.428571429,["x"]=-360445.14285713,},
        [11]={["y"]=-77585.571428571,["x"]=-360585.14285713,},
        [12]={["y"]=-76471.285714286,["x"]=-360819.42857141,},
        [13]={["y"]=-76325.571428571,["x"]=-360942.28571427,},
        [14]={["y"]=-74671.857142857,["x"]=-360927.7142857,},
        [15]={["y"]=-74522.714285714,["x"]=-360888.85714284,},
      },
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
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
    GroomLake = {
      PointsBoundary = {
        [1]={["y"]=-88916.714285714,["x"]=-289102.28571425,},
        [2]={["y"]=-87023.571428572,["x"]=-290388.57142857,},
        [3]={["y"]=-85916.428571429,["x"]=-290674.28571428,},
        [4]={["y"]=-87645.000000001,["x"]=-286567.14285714,},
        [5]={["y"]=-88380.714285715,["x"]=-286388.57142857,},
        [6]={["y"]=-89670.714285715,["x"]=-283524.28571428,},
        [7]={["y"]=-89797.857142858,["x"]=-283567.14285714,},
        [8]={["y"]=-88635.000000001,["x"]=-286749.99999999,},
        [9]={["y"]=-89177.857142858,["x"]=-287207.14285714,},
        [10]={["y"]=-89092.142857144,["x"]=-288892.85714285,},
        [11]={["y"]=-88917.000000001,["x"]=-289102.85714285,},
      },
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
      ZoneBoundary = {},
      ZoneRunways = {},
      MaximumSpeed = 50,
    },
  },
}

--- Creates a new AIRBASEPOLICE_NEVADA object.
-- @param #AIRBASEPOLICE_NEVADA self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they follow the rules of the airbase.
-- @return #AIRBASEPOLICE_NEVADA self
function AIRBASEPOLICE_NEVADA:New( SetClient )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AIRBASEPOLICE_BASE:New( SetClient, self.Airbases ) )

--  -- Nellis
--  local NellisBoundary = GROUP:FindByName( "Nellis Boundary" )
--  self.Airbases.Nellis.ZoneBoundary = ZONE_POLYGON:New( "Nellis Boundary", NellisBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
--
--  local NellisRunway1 = GROUP:FindByName( "Nellis Runway 1" )
--  self.Airbases.Nellis.ZoneRunways[1] = ZONE_POLYGON:New( "Nellis Runway 1", NellisRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  local NellisRunway2 = GROUP:FindByName( "Nellis Runway 2" )
--  self.Airbases.Nellis.ZoneRunways[2] = ZONE_POLYGON:New( "Nellis Runway 2", NellisRunway2 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  -- McCarran
--  local McCarranBoundary = GROUP:FindByName( "McCarran Boundary" )
--  self.Airbases.McCarran.ZoneBoundary = ZONE_POLYGON:New( "McCarran Boundary", McCarranBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
--
--  local McCarranRunway1 = GROUP:FindByName( "McCarran Runway 1" )
--  self.Airbases.McCarran.ZoneRunways[1] = ZONE_POLYGON:New( "McCarran Runway 1", McCarranRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  local McCarranRunway2 = GROUP:FindByName( "McCarran Runway 2" )
--  self.Airbases.McCarran.ZoneRunways[2] = ZONE_POLYGON:New( "McCarran Runway 2", McCarranRunway2 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  local McCarranRunway3 = GROUP:FindByName( "McCarran Runway 3" )
--  self.Airbases.McCarran.ZoneRunways[3] = ZONE_POLYGON:New( "McCarran Runway 3", McCarranRunway3 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  local McCarranRunway4 = GROUP:FindByName( "McCarran Runway 4" )
--  self.Airbases.McCarran.ZoneRunways[4] = ZONE_POLYGON:New( "McCarran Runway 4", McCarranRunway4 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  -- Creech
--  local CreechBoundary = GROUP:FindByName( "Creech Boundary" )
--  self.Airbases.Creech.ZoneBoundary = ZONE_POLYGON:New( "Creech Boundary", CreechBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
--
--  local CreechRunway1 = GROUP:FindByName( "Creech Runway 1" )
--  self.Airbases.Creech.ZoneRunways[1] = ZONE_POLYGON:New( "Creech Runway 1", CreechRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  local CreechRunway2 = GROUP:FindByName( "Creech Runway 2" )
--  self.Airbases.Creech.ZoneRunways[2] = ZONE_POLYGON:New( "Creech Runway 2", CreechRunway2 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  -- Groom Lake
--  local GroomLakeBoundary = GROUP:FindByName( "GroomLake Boundary" )
--  self.Airbases.GroomLake.ZoneBoundary = ZONE_POLYGON:New( "GroomLake Boundary", GroomLakeBoundary ):SmokeZone(POINT_VEC3.SmokeColor.White):Flush()
--
--  local GroomLakeRunway1 = GROUP:FindByName( "GroomLake Runway 1" )
--  self.Airbases.GroomLake.ZoneRunways[1] = ZONE_POLYGON:New( "GroomLake Runway 1", GroomLakeRunway1 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()
--
--  local GroomLakeRunway2 = GROUP:FindByName( "GroomLake Runway 2" )
--  self.Airbases.GroomLake.ZoneRunways[2] = ZONE_POLYGON:New( "GroomLake Runway 2", GroomLakeRunway2 ):SmokeZone(POINT_VEC3.SmokeColor.Red):Flush()

end


     


     