--- **Ops** - (R2.5) - Aerial refueling tanker.
--
-- **Main Features:**
--
--    * Monitor flight status of elements or entire group.
--    * Create a mission queue.
--    * Inherits FLIGHTGROUP class.
--
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.AwacsGroup
-- @image OPS_AwacsGroup.png


--- AWACSGROUP class.
-- @type AWACSGROUP
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @extends Ops.FlightGroup#FLIGHTGROUP

--- *To invent an airplane is nothing. To build one is something. To fly is everything.* -- Otto Lilienthal
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\AWACSGROUP_Main.jpg)
--
-- # The AWACSGROUP Concept
--
-- # Events
-- 
-- 
-- # Tasking
-- 
-- 
-- # Examples
-- 
-- 
--  
--
--
-- @field #AWACSGROUP
AWACSGROUP = {
  ClassName          = "AWACSGROUP",
  Debug              = false,
  lid                =   nil,
  awacszones        =   nil,
  missionqueue       =    {},
  currentmission     =   nil,
  missioncounter     =   nil,
}

--- Tanker mission table.
-- @type AWACSGROUP.Mission
-- @field #string name Name of the mission.
-- @field #number mid ID of the mission.
-- @field #number tid ID of the assigned FLIGHTGROUP task.
-- @field Core.Zone#ZONE zone Mission zone.
-- @field #number duration Duration of mission.
-- @field #number altitude Altitude of orbit in meters ASL.
-- @field #number distance Length of orbit leg in meters.
-- @field #number heading Heading of orbit in degrees.
-- @field #number speed Speed in m/s.
-- @field #number Tadded Time the mission was added.
-- @field #number Tstart Start time in seconds.
-- @field #number Tstarted Time the mission was started.
-- @field #number Tstop Time the mission is stopped.
-- @field #number Tsopped Time the mission was stopped.

--- AWACSGROUP class version.
-- @field #string version
AWACSGROUP.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add orbit task.
-- TODO: Add client queue.
-- TODO: Add menu?

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AWACSGROUP object and start the FSM.
-- @param #AWACSGROUP self
-- @param #string groupname Name of the group.
-- @return #AWACSGROUP self
function AWACSGROUP:New(groupname)


end