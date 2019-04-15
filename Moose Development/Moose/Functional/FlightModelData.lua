--- **Functional** - (R2.5) - Monitor and export flight model data.
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
-- @module Functional.FMData
-- @image Functional_Rat2.png


--- FMD class.
-- @type FMD
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table players Player table.
-- @field #table menuadded Table of units where the F10 radio menu was added.
-- @field #string savepath Path to save data files.
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
-- @field #FMD
FMD = {
  ClassName      = "FMD",
  Debug          = false,
  lid            = nil,
  players        = {},
  menuadded      = {},
  savepath       = nil,
}

--- Player data table.
-- @type FMD.PlayerData
-- @field Core.Scheduler#SCHEDULER scheduler Scheduler
-- @field Wrapper.Unit#UNIT unit Player unit.
-- @field #string unitname Name of the unit.
-- @field #string actype Aircraft type.
-- @field #string name Player name.
-- @field #number dt Time step for data recording in seconds. Default 0.01 sec ==> 100 data points per second!
-- @field #table data Data table.
-- @field #number SID Scheduler ID.

--- Data point table.
-- @type FMD.DataPoint
-- @field #number time Abs mission time.
-- @field #number T Temperature in degrees Celsius.
-- @field #number P Pressure.
-- @field #number Alt Altitude ASL in meters.
-- @field #number AoA Angle of Attack in degrees.
-- @field #number Pitch Pitch angle in degrees.
-- @field #number Roll Roll angle in degrees.
-- @field #number Yaw Yaw angle in degrees.
-- @field #number Climbrate Climb rate in m/s.
-- @field #number Vtot Total velocity in m/s.
-- @field DCS#Vec3 v Velocity vector. Components x,y,z in m/s.
-- @field DCS#Vec3 o Orientation vector. Components x,y,z in meters.
-- @field #number omega Angle velocity in m/s.
-- @field #number hdg Heading in degrees.
-- @field #number Atot Total acceleration m/s^2.
-- @field DCS#Vec3 a Accelleration vector.
-- @field #number DRoll Roll speed in degrees/second.
-- @field #number DPitch Pitch speed in degrees/second.
-- @field #number DYaw Yaw speed in degrees/second.

--- Main group level radio menu: F10 Other/Airboss.
-- @field #table MenuF10
FMD.MenuF10={}

--- FMD mission level F10 root menu.
-- @field #table MenuF10Root
FMD.MenuF10Root=nil

--- FMD class version.
-- @field #string version
FMD.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FMD class object.
-- @param #FMD self
-- @return #FMD self.
function FMD:New()

  -- Inherit everthing from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #FMD
  
  -- Start State.
  self:SetStartState("Stopped")
  
  -- Log string.
  self.lid="FMD | "

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start FMD script.
  self:AddTransition("*",             "Status",          "*")           -- Start FMD script.

  return self
end

--- On after Start event.
-- @param #FMD self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FMD:onafterStart(From, Event, To)

  -- Handle events.
  self:HandleEvent(EVENTS.Birth)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- FMD event handler for event birth.
-- @param #FMD self
-- @param Core.Event#EVENTDATA EventData
function FMD:OnEventBirth(EventData)
  self:F3({eventbirth = EventData})
  
  local _unitName=EventData.IniUnitName
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:T2(self.lid.."BIRTH: unit   = "..tostring(EventData.IniUnitName))
  self:T2(self.lid.."BIRTH: group  = "..tostring(EventData.IniGroupName))
  self:T2(self.lid.."BIRTH: player = "..tostring(_playername))
      
  if _unit and _playername then
  
    local _uid=_unit:GetID()
    local _group=_unit:GetGroup()
    local _callsign=_unit:GetCallsign()
    
    -- Debug output.
    local text=string.format("Pilot %s, callsign %s entered unit %s of group %s.", _playername, _callsign, _unitName, _group:GetName())
    self:T(self.lid..text)
    MESSAGE:New(text, 5):ToAllIf(self.Debug)
    
            
    -- Add Menu commands.
    self:_AddF10Commands(_unitName)

    self.players[_playername]={}
    
    local player=self.players[_playername] --#FMD.PlayerData
    
    player.scheduler=SCHEDULER:New()
    player.unit=_unit
    player.unitname=_unitName
    player.name=_playername
    player.actype=_unit:GetTypeName()
    player.dt=0.01
    player.data={}
     
  end 
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Data Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get data of unit.
-- @param #FMD self
-- @param Wrapper.Unit#UNIT unit
-- @return #FMD.DataPoint Datapoint.
function FMD:_GetDataPoint(unit)
  
  -- Current coordinate.
  local coord=unit:GetCoordinate()
  
  local dp={} --#FMD.DataPoint
  
  dp.a={}
  dp.Alt=coord.y
  dp.AoA=unit:GetAoA()
  dp.Atot=nil
  dp.P=coord:GetPressure()
  dp.Pitch=unit:GetPitch()
  dp.Roll=unit:GetRoll()
  dp.time=timer.getAbsTime()
  dp.T=coord:GetTemperature()
  dp.v=unit:GetVelocityVec3()
  dp.Vtot=UTILS.VecNorm(dp.v)
  dp.Yaw=unit:GetYaw()
  dp.o=unit:GetOrientation()
  dp.Hdg=unit:GetHeading()
  
  return dp
end

--- Get data of unit.
-- @param #FMD self
-- @param #FMD.PlayerData playerData Player data.
-- @return #FMD.DataPoint Datapoint.
function FMD:_Derivative(playerData)

  local function numderiv(fpm,fpp,h)
    return 0.5*(fpp-fpm)/h
  end
  
  self:E("derivative #"..#playerData.data)

  local datapoints=playerData.data
  local dt=playerData.dt

  for i=2,#datapoints-1 do
  
    self:E("i="..i)
  
    local dpm=datapoints[i-1]  --#FMD.DataPoint
    local dpp=datapoints[i+1]  --#FMD.DataPoint
    local dpi=datapoints[i]    --#FMD.DataPoint
    
    self:E(dpm)
    self:E(dpp)
    self:E(dpi)
    
    dpi.Atot=numderiv(dpm.Vtot, dpp.Vtot, dt)

    dpi.a.x=numderiv(dpm.v.x, dpp.v.x, dt)
    dpi.a.y=numderiv(dpm.v.y, dpp.v.y, dt)
    dpi.a.z=numderiv(dpm.v.z, dpp.v.z, dt)
    
    dpi.DPitch=numderiv(dpm.Pitch, dpp.Pitch, dt)
    dpi.DRoll=numderiv(dpm.Roll, dpp.Roll, dt)
    dpi.DYaw=numderiv(dpm.Yaw, dpp.Yaw, dt)
    
    local ang=UTILS.VecAngle(dpm.o.x, dpp.o.x)
    --local dvpp=UTILS.VecAngle(dpi.o.x, dpp.o.x)
    
    dpi.omega=numderiv(0, ang)
    
  end
  
end

--- Record data
-- @param #FMD self
-- @param #FMD.PlayerData playerData Player data table.
function FMD:_RecordData(playerData)

  local dp=self:_GetDataPoint(playerData.unit)
  
  table.insert(playerData.data, dp)

end

--- Save data.
-- @param #FMD self
-- @param #FMD.PlayerData playerData Player data table.
function FMD:_SaveData(playerData)

  -- Nothing to save.
  if playerData==nil or #playerData.data==0 or not io then
    return
  end

  --- Function that saves data to file
  local function _savefile(filename, data)
    local f = assert(io.open(filename, "wb"))
    f:write(data)
    f:close()
  end
  
  -- Set path or default.
  local path=self.savepath
  if lfs then
    path=path or lfs.writedir()
  end
  
  self:E("FF save data")

  -- Create unused file name.
  local filename=nil
  for i=1,9999 do
  
    -- Create file name.
    filename=string.format("FMD-%s_%s-%04d.csv", playerData.name, playerData.actype, i)

    -- Set path.
    if path~=nil then
      filename=path.."\\"..filename
    end
    
    -- Check if file exists.
    local _exists=UTILS.FileExists(filename)
    if not _exists then
      break
    end  
  end
  

  -- Info
  local text=string.format("Saving player %s flight data to file %s", playerData.name, filename)
  self:I(self.lid..text)

  -- Header line
  local data="#Time,Altitude,Temperature,Pressure,Vtot,Vx,Vy,Vz,Atot,ax,ay,az,AoA,Pitch,dPitch/dt,Roll,dRoll/dt,Yaw,dYaw/dt\n"
  
  local g0=playerData.data[1] --#FMD.DataPoint
  local T0=g0.time
  
  -- Calculate derivatives.
  self:_Derivative(playerData)
  
  self:E("looping data.")
  
  for i=2,#playerData.data-1 do
  
    local dp=playerData.data[i] --#FMD.DataPoint
    
    self:E("i="..i)
    self:E(dp)
    
    -- 
    local ms2mach=0.00291545
    
    local t=(dp.time-T0) or 0
    local a=dp.Alt or 0
    local b=dp.T or 0
    local c=dp.P or 0
    local d=dp.Vtot or 0
    local e=dp.v.x or 0
    local f=dp.v.y or 0
    local g=dp.v.z or 0
    local h=dp.Atot or 0
    local i=dp.a.x or 0
    local j=dp.a.y or 0
    local k=dp.a.z or 0
    local l=dp.AoA or 0
    local m=dp.Pitch or 0
    local n=dp.DPitch or 0
    local o=dp.Roll or 0
    local p=dp.DRoll or 0
    local q=dp.Yaw or 0
    local r=dp.DYaw or 0
    local s=dp.omega or 0
    self:E(data)
    self:E(t)
    self:E(a)
    self:E(b)
    self:E(c)
    self:E(d)
    self:E(e)
    self:E(f)
    self:E(g)
    self:E(h)
    self:E(i)
    self:E(j)
    self:E(k)
    self:E(l)
    self:E(m)
    self:E(n)
    self:E(o)
    self:E(p)
    self:E(q)
    self:E(r)
    self:E(s)
    --self:E(u)
    --                         t    a    b    c    d    e    f    g    h    i    j    k    l    m    n    o    p    q    r    s
    data=data..string.format("%.2f,%.2f,%.2f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f \n",
                               t,   a,   b,   c,   d,   e,   f,   g,   h,   i,   j,   k,   l,   m,   n,   o,   p,   q,   r,   s)
    --data=data..string.format("%.2f\n",t)
    self:E(data)
  end
  
  -- Save file.
  _savefile(filename, data)
  
  -- Clear data.
  playerData.data={}
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RADIO MENU Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add menu commands for player.
-- @param #FMD self
-- @param #string _unitName Name of player unit.
function FMD:_AddF10Commands(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check for player unit.
  if _unit and playername then

    -- Get group and ID.
    local group=_unit:GetGroup()
    local gid=group:GetID()
      
    if group and gid then
  
      if not self.menuadded[gid] then
      
        -- Enable switch so we don't do this twice.
        self.menuadded[gid]=true
        
        -- Set menu root path.
        local _rootPath=nil
        if FMD.MenuF10Root then
          ------------------------
          -- MISSON LEVEL MENUE --
          ------------------------          

          -- F10/FMD/...
          _rootPath=FMD.MenuF10Root
            
        else
          ------------------------
          -- GROUP LEVEL MENUES --
          ------------------------
          
          -- Main F10 menu: F10/FMD/
          if FMD.MenuF10[gid]==nil then
            FMD.MenuF10[gid]=missionCommands.addSubMenuForGroup(gid, "FMD")
          end
          
          
          -- F10/FMD/...
          _rootPath=FMD.MenuF10[gid]
          
        end
                
        --------------------------------        
        -- F10/FMD/<Carrier>/F1 Help
        --------------------------------
        
        -- F10/FMD/Start Recording
        missionCommands.addCommandForGroup(gid, "Start Recording", _rootPath, self._StartRecording, self, _unitName)  -- F1
        missionCommands.addCommandForGroup(gid, "Stop Recording",  _rootPath, self._StopRecording,  self, _unitName)  -- F2
        
      end
    end
  end
end

--- Start data recording.
-- @param #FMD self
-- @param #string _unitName Name of player unit.
function FMD:_StartRecording(_unitName)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#FMD.PlayerData
    
    if playerData then
    
      local delay=3
    
      MESSAGE:New(string.format("Flight data recording will be started in %d seconds. dt=%.3f sec", delay, playerData.dt)):ToAll()
    
      playerData.SID=playerData.scheduler:Schedule(nil, self._RecordData, {self, playerData}, delay, playerData.dt)
    end
  end

end

--- Stop data recording.
-- @param #FMD self
-- @param #string _unitName Name of player unit.
function FMD:_StopRecording(_unitName)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#FMD.PlayerData
    
    if playerData then
    
      -- Stop scheduler.
      playerData.scheduler:Stop(playerData.SID)
      
      -- Save data.
      self:_SaveData(playerData)
      
    end
  end

end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #FMD self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function FMD:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
    
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      if DCSunit and unit and playername then
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end




