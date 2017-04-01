---
-- Name: DET-900 - Detection Test with RED FACA
-- Author: FlightControl
-- Date Created: 06 Mar 2017
--
-- # Situation:
--
-- A red FACA is detecting targets while airborne.
-- Targets are grouped within areas. A detection range and zone range is given to group the detected units.
-- This demo will group blue vehicles in areas.
-- Upon the detection capabilities of the red FACA, the blue vehicles will be grouped when detected.
-- All blue vehicles have ROE on hold.
-- 
-- # Test cases:
-- 
-- 1. Observe the tyres put around the detected areas formed
-- 2. Observe the smoking of the units detected
-- 3. Observe the areas being flexibly changed very detection run.

FACSetGroup = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterStart()

FACDetection = DETECTION_AREAS:New( FACSetGroup, 2000, 250 ):BoundDetectedZones():SmokeDetectedUnits()


FACDetection:__Start( 5 )
