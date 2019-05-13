--- **Functional** - (R2.5) - Monitor and export flight model data.
-- 
-- Record flight data and export it to a csv file. 
-- 
-- ## Recorded Data:
--
--    * Time,
--    * Altitude,
--    * Temperature,
--    * Pressure,
--    * Velocity (total and x,y,z components),
--    * Acceleration (total and x,y,z components),
--    * AoA,
--    * Pitch and pitch rate,
--    * Roll and roll rate,
--    * Yaw and yaw rate,
--    * Turn rate.
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

--- Be sure!
--
-- ===
--
-- ![Banner Image](..\Presentations\FMD\FMD_Main.png)
--
-- # The FMD Concept
-- 
-- This class can be used to record flight data such as velocity, acceleration, pitch, roll, yaw and turn rates. The output is written to a csv file for later analysis.
-- 
-- # Usage
-- 
-- The script is very easy to use. It only requires the line
-- 
--     fmd=FMD:New()
--     
-- This will automatically start the FMD script.
-- 
-- Each player will get an entry "FMD" in the F-10 radio menu. There he can start or stop the data recording.
-- 
-- **IMPORTANT**
-- Due to a DCS bug, it is necessary that (in single player mode), player/clients have to **hit ESC twice** before entering an aircraft client slot.
-- Otherwise, the script will not load and now menus will be created for the player.
-- 
-- # Output
-- 
-- After the data recording is completed, the data is written to a csv file. The file name starts with **FMD** and contains the employed airframe plus a running number.
-- 
-- However, one must desanitize the **io** and **lfs** lines the DCS root directory. Otherwise, DCS will not allow data to be written to file.
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
-- @field Wrapper.Client#CLIENT client Player client.
-- @field #string actype Aircraft type.
-- @field #string name Player name.
-- @field #number dt Time step for data recording in seconds. Default 0.01 sec ==> 100 data points per second!
-- @field #number rd Recording duration in seconds.
-- @field #boolean recording If true, recording started.
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
-- @field #number Hdg Heading in degrees.
-- @field #number Atot Total acceleration m/s^2.
-- @field DCS#Vec3 a Acceleration vector.
-- @field #number DRoll Roll speed in degrees/second.
-- @field #number DPitch Pitch speed in degrees/second.
-- @field #number DYaw Yaw speed in degrees/second.

--- Main group level radio menu: F10 Other/FMD.
-- @field #table MenuF10
FMD.MenuF10={}

--- FMD mission level F10 root menu.
-- @field #table MenuF10Root
FMD.MenuF10Root=nil

--- FMD script version.
-- @field #string version
FMD.version="0.1.0"

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
  
  -- Start FMD.
  self:Start()

  return self
end

--- On after Start event.
-- @param #FMD self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FMD:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting Flight Model Data script version %s", FMD.version)
  self:I(self.lid..text)  

  -- Handle events.
  self:HandleEvent(EVENTS.Birth)
end

--- On after Stop event.
-- @param #FMD self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FMD:onafterStop(From, Event, To)

  -- Short info.
  local text=string.format("Stopping Flight Model Data script version %s", FMD.version)
  self:I(self.lid..text)  

  -- Handle events.
  self:UnHandleEvent(EVENTS.Birth) 
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

    -- Player data.
    self.players[_playername]={}
    
    local player=self.players[_playername] --#FMD.PlayerData
    
    player.scheduler=SCHEDULER:New()
    player.unit=_unit
    player.unitname=_unitName
    player.name=_playername
    player.client=CLIENT:FindByName(_unitName, nil, true)
    player.actype=_unit:GetTypeName()
    player.dt=0.01
    player.rd=30
    player.recording=false
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

  if unit and unit:IsAlive() then
  
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
    dp.o=unit:GetOrientationX()
    dp.Hdg=unit:GetHeading()
    
    return dp
  else
    return nil
  end
end

--- Get data of unit.
-- @param #FMD self
-- @param #FMD.PlayerData playerData Player data.
-- @return #FMD.DataPoint Datapoint.
function FMD:_Derivative(playerData)

  local function numderiv(fpm,fpp,h)
    return 0.5*(fpp-fpm)/h
  end

  local datapoints=playerData.data
  --local dt=playerData.dt

  for i=2,#datapoints-1 do
  
    local dpm=datapoints[i-1]  --#FMD.DataPoint
    local dpp=datapoints[i+1]  --#FMD.DataPoint
    local dpi=datapoints[i]    --#FMD.DataPoint
    
    -- Time step.
    local dt=0.5*(dpp.time-dpm.time)
    
    dpi.Atot=numderiv(dpm.Vtot, dpp.Vtot, dt)

    dpi.a.x=numderiv(dpm.v.x, dpp.v.x, dt)
    dpi.a.y=numderiv(dpm.v.y, dpp.v.y, dt)    
    dpi.a.z=numderiv(dpm.v.z, dpp.v.z, dt)
    
    dpi.DPitch=numderiv(dpm.Pitch, dpp.Pitch, dt)
    --dpi.DRoll=numderiv(dpm.Roll, dpp.Roll, dt)
    dpi.DYaw=numderiv(dpm.Yaw, dpp.Yaw, dt)
    
    -- Roll shortcuts.
    local r1=dpm.Roll
    local r2=dpp.Roll
    
    -- Put roll in [0,360)
    if (r1<0) then
      r1=r1+360
    end 
    if (r2<0) then
      r2=r2+360
    end

    -- Handle case where 360 deg periodicity strikes.
    if r1<90 and r2>270 then
      r1=r1+360
    end    
    if r1>270 and r2<90 then
      r2=r2+360
    end
    
    --
    dpi.DRoll=numderiv(r1, r2, dt)
    
    local ang=UTILS.VecAngle(dpm.o, dpp.o)
    dpi.omega=numderiv(0, ang, dt)
    
  end
  
end

--- Record data
-- @param #FMD self
-- @param #FMD.PlayerData playerData Player data table.
function FMD:_RecordData(playerData)

  -- Check if we are recording already.
  if not playerData.recording then
  
      -- Inform player.
      local text=string.format("Data recording starts for %.1f sec.", playerData.rd)
      MESSAGE:New(text, 3, "FMD"):ToClient(playerData.client)
      
      -- Activate recording switch.
      playerData.recording=true    
  end
  
  -- Check if unit is alive.
  if playerData.unit and playerData.unit:IsAlive() then

    -- Get data point.
    local dp=self:_GetDataPoint(playerData.unit)
    
    -- Add data point to player table.
    table.insert(playerData.data, dp)
    
  else
    -- Stop recording if player unit is not alive.
    self:_StopRecording(playerData.unitname)
  end

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
  local data="#Time,Altitude,Temperature,Pressure,Vtot,Vx,Vy,Vz,Atot,ax,ay,az,AoA,Pitch,dPitch/dt,Roll,dRoll/dt,Yaw,dYaw/dt,Turn Rate\n"
  
  local g0=playerData.data[1] --#FMD.DataPoint
  local T0=g0.time
  
  -- Calculate derivatives.
  self:_Derivative(playerData)

  for i=2,#playerData.data-1 do
  
    local dp=playerData.data[i] --#FMD.DataPoint
    
    -- Conversion m/s == Mach. 
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
    local roll=dp.Roll or 0
    if roll<0 then
      roll=roll+360
    end
    local o=roll --dp.Roll or 0
    local p=dp.DRoll or 0
    local q=dp.Yaw or 0
    local r=dp.DYaw or 0
    local s=dp.omega or 0
    
    -- Debug output.
    self:T3(t)
    self:T3(a)
    self:T3(b)
    self:T3(c)
    self:T3(d)
    self:T3(e)
    self:T3(f)
    self:T3(g)
    self:T3(h)
    self:T3(i)
    self:T3(j)
    self:T3(k)
    self:T3(l)
    self:T3(m)
    self:T3(n)
    self:T3(o)
    self:T3(p)
    self:T3(q)
    self:T3(r)
    self:T3(s)
    
    --                         t    a    b    c    d    e    f    g    h    i    j    k    l    m    n    o    p    q    r    s
    data=data..string.format("%.2f,%.2f,%.2f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n",
                               t,   a,   b,   c,   d,   e,   f,   g,   h,   i,   j,   k,   l,   m,   n,   o,   p,   q,   r,   s)

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
        -- F10/F<X> FMD/F1 Time Interval
        --------------------------------
        local _timePath=missionCommands.addSubMenuForGroup(gid, "Time Interval", _rootPath)
        -- F10/FMD/F1 Time Interval/
        missionCommands.addCommandForGroup(gid, "Delta t=0.01 s", _timePath, self._SetTimeInterval, self, _unitName, 0.01)
        missionCommands.addCommandForGroup(gid, "Delta t=0.1 s",  _timePath, self._SetTimeInterval, self, _unitName, 0.1)
        missionCommands.addCommandForGroup(gid, "Delta t=1.0 s",  _timePath, self._SetTimeInterval, self, _unitName, 1.0)
        missionCommands.addCommandForGroup(gid, "Delta t=10 s",   _timePath, self._SetTimeInterval, self, _unitName, 10.0)
        missionCommands.addCommandForGroup(gid, "Delta t=30 s",   _timePath, self._SetTimeInterval, self, _unitName, 30.0)
        missionCommands.addCommandForGroup(gid, "Delta t=60 s",   _timePath, self._SetTimeInterval, self, _unitName, 60.0)

        -------------------------------        
        -- F10/F<X> FMD/F1 Rec Duration
        -------------------------------
        local _durPath=missionCommands.addSubMenuForGroup(gid, "Rec Duration", _rootPath)
        -- F10/FMD/F1 Rec Duration/
        missionCommands.addCommandForGroup(gid, "T=10 s",   _durPath, self._SetRecDuration, self, _unitName, 10)
        missionCommands.addCommandForGroup(gid, "T=30 s",   _durPath, self._SetRecDuration, self, _unitName, 30)
        missionCommands.addCommandForGroup(gid, "T=60 s",   _durPath, self._SetRecDuration, self, _unitName, 60)
        missionCommands.addCommandForGroup(gid, "T=5 min",  _durPath, self._SetRecDuration, self, _unitName, 5*60)
        missionCommands.addCommandForGroup(gid, "T=10 min", _durPath, self._SetRecDuration, self, _unitName, 10*60)
        
        --------------------------------        
        -- F10/F<X> FMD/
        --------------------------------
        
        -- F10/FMD/Start Recording
        missionCommands.addCommandForGroup(gid, "Start Recording", _rootPath, self._StartRecording, self, _unitName)  -- F1
        missionCommands.addCommandForGroup(gid, "Stop Recording",  _rootPath, self._StopRecording,  self, _unitName)  -- F2
        
      end
    end
  end
end


--- Set recording duration.
-- @param #FMD self
-- @param #string _unitName Name of player unit.
-- @param #number rd Recording duration in sec.
function FMD:_SetRecDuration(_unitName, rd)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#FMD.PlayerData
    
    if playerData then
    
      -- Set dt.
      playerData.rd=rd

      -- Inform player.
      local text=string.format("Data recording duration set to %.1f sec.", playerData.rd)
      MESSAGE:New(text, 10, "FMD"):ToClient(playerData.client)
    
    end
  end
end


--- Set time interval for data recording.
-- @param #FMD self
-- @param #string _unitName Name of player unit.
-- @param #number dt Time interval in seconds.
function FMD:_SetTimeInterval(_unitName, dt)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#FMD.PlayerData
    
    if playerData then
    
      -- Set dt.
      playerData.dt=dt

      -- Inform player.
      local text=string.format("Data recording time interval set to %.3f sec.", playerData.dt)
      MESSAGE:New(text, 10, "FMD"):ToClient(playerData.client)    
    
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
    
      -- Delay before recording starts.
      local delay=3
    
      -- Inform player.
      local text=string.format("Data recording will be started in %d seconds with %.3f sec timestep for %.1f sec.", delay, playerData.dt, playerData.rd)
      MESSAGE:New(text, 3, "FMD"):ToClient(playerData.client)
    
      -- Start scheduler.
      playerData.SID=playerData.scheduler:Schedule(nil, self._RecordData, {self, playerData}, delay, playerData.dt, 0.0)
      
      -- Stop scheduler once.
      playerData.scheduler:ScheduleOnce(playerData.rd+delay, self._StopRecording, self,_unitName)
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
    
      local ndata=#playerData.data
    
      -- Inform player.
      local text=string.format("Data recording stopped. Data points recorded: %d", ndata)
      MESSAGE:New(text, 10, "FMD"):ToClient(playerData.client)
      
      -- No recording switch.
      playerData.recording=false
    
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

