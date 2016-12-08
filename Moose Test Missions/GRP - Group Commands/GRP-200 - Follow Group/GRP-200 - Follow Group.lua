
--Create Spawn Groups
local SpawnPlane1 = SPAWN:New("Plane 1")
local SpawnPlane2 = SPAWN:New("Plane 2")

--Spawn Groups into world
local GroupPlane1 = SpawnPlane1:Spawn()
--local GroupPlane1 = GROUP:FindByName( "Plane 1" )
local GroupPlane2 = SpawnPlane2:Spawn()
--local GroupPlane2 = GROUP:FindByName( "Plane 2" )

--Create Task for plane2 (follow groupPlane1 at Vec3 offset) (Note: I think I need to be using controllers here)
--i.e. cntrlPlane1 = groupPlane1.getController(groupPlane1)

local PointVec3 = POINT_VEC3:New( 100, 0, -100 ) -- This is a Vec3 class.

local FollowDCSTask = GroupPlane2:TaskFollow( GroupPlane1, PointVec3:GetVec3() )

--Activate Task (Either PushTask/SetTask?)
-- PushTask will push a task on the execution queue of the group.
-- SetTask will delete all tasks from the current group queue, and executes this task.

GroupPlane2:SetTask( FollowDCSTask, 1 )

