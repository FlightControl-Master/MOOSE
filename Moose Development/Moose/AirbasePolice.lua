
--- @type AIRBASEPOLICE
-- @field Set#SET_CLIENT SetClient
-- @extends Base#BASE

AIRBASEPOLICE = {
  ClassName = "AIRBASEPOLICE",
  PolygonsTaxiways = {},
  PolygonsRunways = {},
}

--- Creates a new AIRBASEPOLICE object.
-- @param #AIRBASEPOLICE self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they follow the rules of the airbase.
-- @return #AIRBASEPOLICE self
function AIRBASEPOLICE:New( SetClient )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.SetClient = SetClient
  
  local PolygonBatumiTaxiwaysGroup1 = GROUP:FindByName( "Polygon Batumi Taxiway 1" )
  self.PolygonsTaxiways[#self.PolygonsTaxiways+1] = ZONE_POLYGON:New( "Batumi Taxiway", PolygonBatumiTaxiwaysGroup1 ):SmokeZone(POINT_VEC3.SmokeColor.White)

  local PolygonBatumiRunwaysGroup1 = GROUP:FindByName( "Polygon Batumi Runway 1" )
  self.PolygonsRunways[#self.PolygonsRunways+1] = ZONE_POLYGON:New( "Batumi Runway", PolygonBatumiRunwaysGroup1 ):SmokeZone(POINT_VEC3.SmokeColor.Red)

  self.SetClient:ForEachClient(
  
    --- @param Client#CLIENT Client
    function( Client )
      Client:SetState( self, "Speeding", false )
      Client:SetState( self, "Warnings", 0)
    end
  
  )
  self.AirbaseMonitor = SCHEDULER:New( self, self._AirbaseMonitor, {}, 0, 5, 0 ) 
  
  return self
end

--- @param #AIRBASEPOLICE self
function AIRBASEPOLICE:_AirbaseMonitor()

  for PolygonTaxiID, PolygonTaxi in pairs( self.PolygonsTaxi ) do
    self.SetClient:ForEachClientInZone( PolygonTaxi,
    
      --- @param Client#CLIENT Client
      function( Client )
        if Client:IsAlive() then
          local VelocityVec3 = Client:GetVelocity()
          local Velocity = math.abs(VelocityVec3.x) + math.abs(VelocityVec3.y) + math.abs(VelocityVec3.z)
          Client:Message( "Velocity:" .. Velocity,  1, "Test", "Police" )
          local IsAboveRunway = Client:IsAboveRunway()
          local IsOnGround = Client:InAir() == false
          self:T( IsAboveRunway, IsOnGround )
          if IsAboveRunway and IsOnGround then
            if Velocity > 10 then
              local IsSpeeding = Client:GetState( self, "Speeding" )
              if IsSpeeding == true then
                local SpeedingWarnings = Client:GetState( self, "Warnings" )
                self:T( SpeedingWarnings )
                if SpeedingWarnings <= 5 then
                  Client:Message( "You are speeding on the taxiway! Slow down or you will be removed from this airbase!  Your current velocity is " .. string.format( "%2.0f km/h", Velocity ), 5, "Speeding", "Warning " .. SpeedingWarnings .. " / 5" )
                  Client:SetState( self, "Warnings", SpeedingWarnings + 1 )
                else
                  MESSAGE:New( "Player " .. Client:GetPlayerName() .. " has been removed from the airbase, due to a speeding violation ...", 10, "Airbase Police" ):ToAll()
                  Client:GetGroup():Destroy()
                  Client:SetState( self, "Speeding", false )
                  Client:SetState( self, "Warnings", 0 )
                end
              else
                Client:Message( "You are speeding on the taxiway! Slow down please ...! Your current velocity is " .. string.format( "%2.0f km/h", Velocity ), 5, "Speeding", "Attention! " )
                Client:SetState( self, "Speeding", true )
                Client:SetState( self, "Warnings", 1 )
              end
            else
              Client:SetState( self, "Speeding", false )
              Client:SetState( self, "Warnings", 0 )
            end
          end
        end
      end
  
    )
  end
  return true
end

