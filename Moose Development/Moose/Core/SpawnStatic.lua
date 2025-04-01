
--[[
local CA_SET=SET_CLIENT:New():HandleCASlots():FilterCoalitions("blue"):FilterStart()

function CA_SET:OnAfterAdded(From,Event,To,ObjectName,Object)
  MESSAGE:New("Player joined CA Slot: "..ObjectName,10,"CA"):ToAll()
  local client = Object -- Wrapper.Client#CLIENT
  local group = client:GetGroup()
  if group then
    MENU_GROUP:New(group,"Test CA")
  end
end

  local e = {}
  function e:onEvent(event)
      local m = {}
      m[#m+1] = "Event ID: "
      m[#m+1] = event.id
      if event.initiator then 
         m[#m+1] = "\nInitiator : "
         m[#m+1] = event.initiator:getName()
      end
      if event.weapon then 
         m[#m+1] = "\nWeapon : "
         m[#m+1] = event.weapon :getTypeName()
      end 
      if event.target then 
         m[#m+1] = "\nTarget : "
         m[#m+1] = event.target :getName()
      end 
      env.info(table.concat(m))
  end
  world.addEventHandler(e)
  
  local recce = PLAYERRECCE:New(Name,Coalition,PlayerSet)
  
  
  US_Patrol_Plane = SPAWN
                      :New("Bird Dog")
                      :InitLimit(1,4)
                      :OnSpawnGroup(function ( SpawnedGroup )
                        -- Setup AI Patrol
                        PatrolZone = ZONE:New("Conflict Zone Alpha")
                        EngageZone = ZONE:New("Conflict Zone Alpha")
                        EngageZone:Draw()
                        AICaszone = AI_CAS_ZONE:New(PatrolZone, 100, 1000, 100, 100, EngageZone, "RADIO")
                        AICaszone:SetControllable(SpawnedGroup)
                        --AICaszone:SetEngageRange(2000)
                        AICaszone:__Start(1)
                      end
                      )
                      :SpawnScheduled(30, 0)
  
--]]

local grp = GROUP:FindByName("IR Blinker")
grp:NewIRMarker(true,90)

function DestGroup()
  if grp and grp:IsAlive() then 
    grp:Destroy()
  end
end

function DisableMarker()
  if grp and grp:IsAlive() then 
    grp:DisableIRMarker()
  end
end

function EnableMarker()
  if grp and grp:IsAlive() then 
    grp:EnableIRMarker()
  end
end

function RespGroup()
  if grp and not grp:IsAlive() then 
    grp:Respawn()
  end
end

local mymsrs = MSRS:New(nil,243,0)
local jammersound=SOUNDFILE:New("beacon.ogg", "C:\\Users\\post\\Saved Games\\DCS\\Missions\\", 2, true)
function Play()  
  mymsrs:PlaySoundFile(jammersound)
end

local topmenu = MENU_COALITION:New(coalition.side.BLUE,"IR Marker Test")
local startmenu = MENU_COALITION_COMMAND:New(coalition.side.BLUE,"Enable IR",topmenu,EnableMarker)
local stopmenu = MENU_COALITION_COMMAND:New(coalition.side.BLUE,"Disable IR",topmenu,DisableMarker)
local destmenu = MENU_COALITION_COMMAND:New(coalition.side.BLUE,"Destroy Group",topmenu,DestGroup)
local respmenu = MENU_COALITION_COMMAND:New(coalition.side.BLUE,"Respawn Group",topmenu,RespGroup)
local respmenu = MENU_COALITION_COMMAND:New(coalition.side.BLUE,"Play Sound",topmenu,Play)

local testzone = ZONE:New("Testzone")
testzone:Trigger(grp)

function testzone:OnAfterObjectDead(From,Event,To,Controllable)
  MESSAGE:New("Object Dead",15,"Test"):ToAll():ToLog()
end

function testzone:OnAfterZoneEmpty(From,Event,To)
  MESSAGE:New("Zone Empty",15,"Test"):ToAll():ToLog()
end

local BlueBorder = ZONE:New("Blue Border")
local RedBorder = ZONE:New("Red Border")
local Conflict = ZONE:New("Conflict")

BlueBorder:DrawZone(-1,{0,0,1},1,{0,0,1},.2,1,true)
RedBorder:DrawZone(-1,{1,0,0},1,{1,0,0},.2,1,true)
Conflict:DrawZone(-1,{1,254/255,1/33},1,{1,254/255,1/33},.2,1,true)

BASE:TraceOn()
BASE:TraceClass("SHORAD")

local mymantis = MANTIS:New("Red Defense","Red SAM","Red EWR",hq,"red",true,awacs,true)
mymantis:AddZones({RedBorder},{BlueBorder},{Conflict})
mymantis.verbose = true
mymantis.debug = true
mymantis:Start()

local myctld = CTLD:New()

function myctld:OnAfterCratesDropped(From,Event,To,Group,Unit,Cargotable)
  if Unit and string.find(Unit:GetTypeName(),"Mosquito",1,true) then
    myctld:_BuildCrates(Group,Unit,true)
  end
end
