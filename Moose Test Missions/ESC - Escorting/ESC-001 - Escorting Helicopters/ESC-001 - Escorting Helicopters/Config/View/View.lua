-- View scripts
-- Copyright (C) 2004, Eagle Dynamics.

CockpitMouse = true --false
CockpitMouseSpeedSlow = 1.0
CockpitMouseSpeedNormal = 10.0
CockpitMouseSpeedFast = 20.0
CockpitKeyboardAccelerationSlow = 5.0
CockpitKeyboardAccelerationNormal = 30.0
CockpitKeyboardAccelerationFast = 80.0
CockpitKeyboardZoomAcceleration = 300.0
DisableSnapViewsSaving = false
UseDefaultSnapViews = true
CockpitPanStepHor = 45.0
CockpitPanStepVert = 30.0
CockpitNyMove = true

CockpitHAngleAccelerateTimeMax = 0.15
CockpitVAngleAccelerateTimeMax = 0.15
CockpitZoomAccelerateTimeMax   = 0.2

function NaturalHeadMoving(tang, roll, omz)
	local r = roll
	if r > 90.0 then
		r = 180.0 - r
	elseif roll < -90.0 then
		r = -180.0 - r
	end
	local hAngle = -0.25 * r
	local vAngle = math.min(math.max(0.0, 0.4 * tang + 45.0 * omz), 90.0)
	return hAngle, vAngle
end

ExternalMouse = true
ExternalMouseSpeedSlow = 1.0
ExternalMouseSpeedNormal = 5.0
ExternalMouseSpeedFast = 20.0
ExternalViewAngleMin = 3.0
ExternalViewAngleMax = 170.0
ExternalViewAngleDefault = 60.0
ExternalKeyboardZoomAcceleration = 30.0
ExternalKeyboardZoomAccelerateTimeMax = 1.0
ExplosionExpoTime = 4.0
ExternalKeyboardAccelerationSlow = 1.0
ExternalKeyboardAccelerationNormal = 10.0
ExternalKeyboardAccelerationFast = 30.0
ExternalHAngleAccelerateTimeMax = 3.0
ExternalVAngleAccelerateTimeMax = 3.0
ExternalDistAccelerateTimeMax = 3.0
ExternalHAngleLocalAccelerateTimeMax = 3.0
ExternalVAngleLocalAccelerateTimeMax = 3.0
ExternalAngleNormalDiscreteStep = 15.0/ExternalKeyboardAccelerationNormal -- When 'S' is pressed only
ChaseCameraNyMove = true
FreeCameraAngleIncrement = 3.0
FreeCameraDistanceIncrement = 200.0
FreeCameraLeftRightIncrement = 2.0
FreeCameraAltitudeIncrement = 2.0
FreeCameraScalarSpeedAcceleration = 0.1 
xMinMap = -300000
xMaxMap = 500000
yMinMap = -400000
yMaxMap = 200000
dxMap = 150000
dyMap = 100000

head_roll_shaking = true
head_roll_shaking_max = 30.0
head_roll_shaking_compensation_gain = 0.3

-- CameraJiggle() and CameraFloat() functions make camera position
-- dependent on FPS so be careful in using the Shift-J command with tracks, please.
-- uncomment to use custom jiggle functions
--[[
function CameraJiggle(t,rnd1,rnd2,rnd3)
	local rotX, rotY, rotZ
	rotX = 0.05 * rnd1 * math.sin(37.0 * (t - 0.0))
	rotY = 0.05 * rnd2 * math.sin(41.0 * (t - 1.0))
	rotZ = 0.05 * rnd3 * math.sin(53.0 * (t - 2.0))
	return rotX, rotY, rotZ
end

function CameraFloat(t)
	local dX, dY, dZ
	dX = 0.61 * math.sin(0.7 * t) + 0.047 * math.sin(1.6 * t);
	dY = 0.43 * math.sin(0.6 * t) + 0.067 * math.sin(1.7 * t);
	dZ = 0.53 * math.sin(1.0 * t) + 0.083 * math.sin(1.9 * t);
	return dX, dY, dZ
end
--]]
--Debug keys

DEBUG_TEXT 		= 1
DEBUG_GEOMETRY 	= 2

debug_keys = {
	[DEBUG_TEXT] = 1,
	[DEBUG_GEOMETRY] = 1
}

function onDebugCommand(command)
	if command == 10000 then		
		if debug_keys[DEBUG_TEXT] ~= 0 or debug_keys[DEBUG_GEOMETRY] ~= 0 then
			debug_keys[DEBUG_GEOMETRY] = 0
			debug_keys[DEBUG_TEXT] = 0
		else
			debug_keys[DEBUG_GEOMETRY] = 1
			debug_keys[DEBUG_TEXT] = 1		
		end	
	elseif command == 10001 then 
		if debug_keys[DEBUG_TEXT] ~= 0 then
			debug_keys[DEBUG_TEXT] = 0
		else
			debug_keys[DEBUG_TEXT] = 1
		end		
	elseif command == 10002 then
		if debug_keys[DEBUG_GEOMETRY] ~= 0 then
			debug_keys[DEBUG_GEOMETRY] = 0
		else
			debug_keys[DEBUG_GEOMETRY] = 1
		end
	end
end

-- gain values for TrackIR , to unify responce on diffrent types of aircraft
TrackIR_gain_x    = -0.6
TrackIR_gain_y    =  0.3
TrackIR_gain_z    = -0.25
TrackIR_gain_roll = -90