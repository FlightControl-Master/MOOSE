---
-- Name: ESC-001 - Escorting Helicopters
-- Author: FlightControl
-- Date Created: 10 Mar 2017
--
-- # Situation:
-- 
-- Your client helicopter is flying in the battle field.
-- It is escorted by an MI-28N, which you can command...
-- Use the menu options to:
-- - Make the escort follow you.
-- - Report detected targets.
-- - Attack targets
-- - Flare
-- 
-- # Test cases: 
-- 
-- 1. When executing the commands, observe the MI-28N reactions.

do
  local function EventAliveHelicopter( Client )
    local EscortGroupHeli1 = SpawnEscortHeli:ReSpawn(1)
    local EscortHeli1 = ESCORT
      :New( Client, EscortGroupHeli1, "Escort Helicopter" )
      :MenuFollowAt( 100 )
      :MenuFollowAt( 200 )
      :MenuHoldAtEscortPosition( 20, 10, "Hold at %d meters for %d seconds" )
      :MenuHoldAtLeaderPosition( 120 )
      :MenuFlare( "Disperse Flares" )
      :MenuSmoke()
      :MenuReportTargets( 60, 20 )
      :MenuResumeMission()
      :MenuROE()
      :MenuAssistedAttack()
      
    EscortHeli1:SetDetection( EscortHeliDetection )

    local EscortGroupArtillery = SpawnEscortArtillery:ReSpawn(1)
    local EscortArtillery = ESCORT
      :New( Client, EscortGroupArtillery, "Escort Artillery" )
      :Menus()
  end
  
  local function EventAlivePlane( Client )
    local EscortGroupPlane2 = SpawnEscortPlane:ReSpawn(1)
    local EscortPlane2 = ESCORT
    :New( Client, EscortGroupPlane2, "Escort Test Plane" )
      :MenuFollowAt( 100 )
      :MenuFollowAt( 200 )
      :MenuHoldAtEscortPosition( 20, 10, "Hold at %d meters for %d seconds" )
      :MenuHoldAtLeaderPosition( 120 )
      :MenuFlare( "Disperse Flares" )
      :MenuSmoke()
      :MenuReportTargets( 60, 20 )
      :MenuResumeMission()
      :MenuAssistedAttack()
      :MenuROE()
      :MenuEvasion()
    
    local EscortGroupGround2 = SpawnEscortGround:ReSpawn(1)
    local EscortGround2 = ESCORT
    :New( Client, EscortGroupGround2, "Test Ground" )
    :Menus()

    local EscortGroupShip2 = SpawnEscortShip:ReSpawn(1)
    local EscortShip2 = ESCORT
    :New( Client, EscortGroupShip2, "Test Ship" )
    :Menus()
  end

  SpawnEscortHeli = SPAWN:New( "Escort Helicopter" )
  SpawnEscortPlane = SPAWN:New( "Escort Plane" )
  SpawnEscortGround = SPAWN:New( "Escort Ground" )
  SpawnEscortShip = SPAWN:New( "Escort Ship" )
  SpawnEscortArtillery = SPAWN:New( "Ground Attack Assistance" )
  
  EscortHeliSetGroup = SET_GROUP:New():FilterPrefixes("Escort Helicopter"):FilterStart()
  EscortHeliDetection = DETECTION_AREAS:New( EscortHeliSetGroup, 1000, 500 )
  
  EscortHeliDetection:BoundDetectedZones()
  EscortHeliDetection:SetDetectionInterval( 15 )

  EscortClientHeli = CLIENT:FindByName( "Lead Helicopter", "Fly around and observe the behaviour of the escort helicopter" ):Alive( EventAliveHelicopter )  
  EscortClientPlane = CLIENT:FindByName( "Lead Plane", "Fly around and observe the behaviour of the escort airplane. Select Navigate->Joun-Up and airplane should follow you. Change speed and directions." )
                                  :Alive( EventAlivePlane )                                    

end

env.info( "Test Mission loaded" )
