-- View scripts 
-- Copyright (C) 2004, Eagle Dynamics.
DisableCombatViews				= false -- F5 & Ctrl-F5
ExternalObjectsLockDistance 	= 10000.0
ShowTargetInfo 					= false
CameraTerrainRestriction 		= true
hAngleRearDefault 				=  180
vAngleRearDefault 				= -8.0
vAngleRearMin    				= -90 -- -8.0
vAngleRearMax    				= 90.0

dbg_shell    = "weapons.shells.PKT_7_62_T" -- 23mm shell
dbg_shell    = "weapons.nurs.WGr21"
-- dbg_shell    = "weapons.shells.2A64_152" -- 152mm shell
dbg_shell_v0 = -1 -- Muzzle speed m/s (-1 - speed from shall database)
dbg_shell_fire_rate = 60
--reformatted per-unit data to be mod system friendly 
--this file is no longer should be edited for adding new flyable aircraft , DCS automatically check core database (i.e. where you define your aircraft in aircraft table just define ViewSettings and SnapViews tables)

function default_fighter_player(t)
	local res = { 
		CameraViewAngleLimits  = {20.000000,140.000000},
		CameraAngleRestriction = {false	   ,90.000000,0.500000},
		EyePoint               = {0.05     ,0.000000 ,0.000000},
		limits_6DOF            = {x = {-0.050000,0.4500000},y ={-0.300000,0.100000},z = {-0.220000,0.220000},roll = 90.000000},
		Allow360rotation	   = false,
		CameraAngleLimits      = {200,-80.000000,110.000000},
		ShoulderSize 		   = 0.2,  -- move body when azimuth value more then 90 degrees
	}
	if t then 
		for i,o in pairs(t) do
			res[i] = o
		end
	end
	return res
end

function fulcrum()
	return {
		Cockpit = {
					default_fighter_player({CockpitLocalPoint = {4.71,1.28,0.000000}})
		},
		Chase   = {
			LocalPoint      = {1.220000,3.750000,0.000000},
			AnglesDefault   = {180.000000,-8.000000},
		}, -- Chase 
		Arcade = {
			LocalPoint      = {-15.080000,6.350000,0.000000},
			AnglesDefault   = {0.000000,-8.000000},
		}, -- Arcade 
	}
end

ViewSettings = {}
ViewSettings["A-10A"] = {
	Cockpit = {
	[1] = default_fighter_player({CockpitLocalPoint      =  {4.300000,1.282000,0.000000},
								  EyePoint  			 = {0.000000,0.000000,0.000000},
								  limits_6DOF            = {x 	 = {-0.050000,0.600000},
															y 	 = {-0.300000,0.100000},
															z 	 = {-0.250000,0.250000},
															roll =  90.000000}}),
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {0.600000,3.682000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {-27.000000,12.000000,0.000000},
		AnglesDefault   = {0.000000,-12.000000},
	}, -- Arcade 
}
ViewSettings["A-10C"] = {
	Cockpit = {
	[1] = default_fighter_player({CockpitLocalPoint      = {4.300000,1.282000,0.000000},
								  EyePoint  			 = {0.000000,0.000000,0.000000},
								  limits_6DOF            = {x 	 = {-0.050000,0.600000},
															y 	 = {-0.300000,0.100000},
															z 	 = {-0.250000,0.250000},
															roll =  90.000000}}),
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {0.600000,3.682000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {-27.000000,12.000000,0.000000},
		AnglesDefault   = {0.000000,-12.000000},
	}, -- Arcade 
}
ViewSettings["F-15C"] = {
	Cockpit = {  
	[1] = default_fighter_player({CockpitLocalPoint      = {6.210000,1.204000,0.000000}})-- player slot 1
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {2.510000,3.604000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {-13.790000,6.204000,0.000000},
		AnglesDefault   = {0.000000,-8.000000},
	}, -- Arcade 
}
ViewSettings["Ka-50"] = {
	Cockpit = {
	[1] = {-- player slot 1
		CockpitLocalPoint      = {3.188000,0.390000,0.000000},
		CameraViewAngleLimits  = {20.000000,120.000000},
		CameraAngleRestriction = {false,60.000000,0.400000},
		CameraAngleLimits      = {140.000000,-65.000000,90.000000},
		EyePoint               = {0.090000,0.000000,0.000000},
		limits_6DOF            = {x = {-0.020000,0.350000},y ={-0.150000,0.165000},z = {-0.170000,0.170000},roll = 90.000000},
	},
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {-0.512000,2.790000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {-16.812000,5.390000,0.000000},
		AnglesDefault   = {0.000000,-8.000000},
	}, -- Arcade 
}
ViewSettings["MiG-29A"] = fulcrum()
ViewSettings["MiG-29G"] = fulcrum()
ViewSettings["MiG-29S"] = fulcrum()

ViewSettings["P-51D"] = {
	Cockpit = {
	[1] = {-- player slot 1
		CockpitLocalPoint      = {-1.500000,0.618000,0.000000},
		CameraViewAngleLimits  = {20.000000,120.000000},
		CameraAngleRestriction = {false,90.000000,0.500000},
		CameraAngleLimits      = {200,-80.000000,90.000000},
		EyePoint               = {0.025000,0.100000,0.000000},
		ShoulderSize		   = 0.15,
		Allow360rotation	   = false,
		limits_6DOF            = {x = {-0.050000,0.450000},y ={-0.200000,0.200000},z = {-0.220000,0.220000},roll = 90.000000},
	},
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {0.200000,-0.652000,-0.650000},
		AnglesDefault   = {0.000000,0.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {-21.500000,5.618000,0.000000},
		AnglesDefault   = {0.000000,-8.000000},
	}, -- Arcade 
}
ViewSettings["Su-25"] = {
	Cockpit = {
	[1] = default_fighter_player({CockpitLocalPoint      = {3.352000,0.506000,0.000000}}),-- player slot 1
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {-0.348000,2.906000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {-16.648001,5.506000,0.000000},
		AnglesDefault   = {0.000000,-8.000000},
	}, -- Arcade 
}
ViewSettings["Su-25T"] = {
	Cockpit = {
	[1] = default_fighter_player({CockpitLocalPoint      = {3.406000,0.466000,0.000000}}),-- player slot 1
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {-0.294000,2.866000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {-16.594000,5.466000,0.000000},
		AnglesDefault   = {0.000000,-8.000000},
	}, -- Arcade 
}
ViewSettings["Su-25TM"] = {
	Cockpit = {
	[1] = {-- player slot 1
		CockpitLocalPoint      = {4.000000,1.000000,0.000000},
		CameraViewAngleLimits  = {20.000000,140.000000},
		CameraAngleRestriction = {true,90.000000,0.400000},
		CameraAngleLimits      = {160.000000,-70.000000,90.000000},
		EyePoint               = {0.000000,0.000000,0.000000},
		limits_6DOF            = {x = {-0.200000,0.200000},y ={-0.200000,0.200000},z = {-0.200000,0.200000},roll = 60.000000},
	},
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {4.000000,2.000000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {4.000000,2.000000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Arcade 
}
ViewSettings["Su-27"] = {
	Cockpit = {
	[1] = default_fighter_player({CockpitLocalPoint      = {7.959000,1.419000,0.000000}})-- player slot 1
	}, -- Cockpit 
	Chase = {
		LocalPoint      = {4.259000,3.819000,0.000000},
		AnglesDefault   = {180.000000,-8.000000},
	}, -- Chase 
	Arcade = {
		LocalPoint      = {-12.041000,6.419000,0.000000},
		AnglesDefault   = {0.000000,-8.000000},
	}, -- Arcade 
}

ViewSettings["Su-33"] = ViewSettings["Su-27"]
