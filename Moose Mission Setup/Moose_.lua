env.info('*** MOOSE STATIC INCLUDE START *** ')
env.info('Moose Generation Timestamp: 20171031_1115')
env.setErrorMessageBoxEnabled(false)
routines={}
routines.majorVersion=3
routines.minorVersion=3
routines.build=22
routines.utils={}
routines.utils.deepCopy=function(object)
local lookup_table={}
local function _copy(object)
if type(object)~="table"then
return object
elseif lookup_table[object]then
return lookup_table[object]
end
local new_table={}
lookup_table[object]=new_table
for index,value in pairs(object)do
new_table[_copy(index)]=_copy(value)
end
return setmetatable(new_table,getmetatable(object))
end
local objectreturn=_copy(object)
return objectreturn
end
routines.utils.oneLineSerialize=function(tbl)
lookup_table={}
local function _Serialize(tbl)
if type(tbl)=='table'then
if lookup_table[tbl]then
return lookup_table[object]
end
local tbl_str={}
lookup_table[tbl]=tbl_str
tbl_str[#tbl_str+1]='{'
for ind,val in pairs(tbl)do
local ind_str={}
if type(ind)=="number"then
ind_str[#ind_str+1]='['
ind_str[#ind_str+1]=tostring(ind)
ind_str[#ind_str+1]=']='
else
ind_str[#ind_str+1]='['
ind_str[#ind_str+1]=routines.utils.basicSerialize(ind)
ind_str[#ind_str+1]=']='
end
local val_str={}
if((type(val)=='number')or(type(val)=='boolean'))then
val_str[#val_str+1]=tostring(val)
val_str[#val_str+1]=','
tbl_str[#tbl_str+1]=table.concat(ind_str)
tbl_str[#tbl_str+1]=table.concat(val_str)
elseif type(val)=='string'then
val_str[#val_str+1]=routines.utils.basicSerialize(val)
val_str[#val_str+1]=','
tbl_str[#tbl_str+1]=table.concat(ind_str)
tbl_str[#tbl_str+1]=table.concat(val_str)
elseif type(val)=='nil'then
val_str[#val_str+1]='nil,'
tbl_str[#tbl_str+1]=table.concat(ind_str)
tbl_str[#tbl_str+1]=table.concat(val_str)
elseif type(val)=='table'then
if ind=="__index"then
else
val_str[#val_str+1]=_Serialize(val)
val_str[#val_str+1]=','
tbl_str[#tbl_str+1]=table.concat(ind_str)
tbl_str[#tbl_str+1]=table.concat(val_str)
end
elseif type(val)=='function'then
else
end
end
tbl_str[#tbl_str+1]='}'
return table.concat(tbl_str)
else
return tostring(tbl)
end
end
local objectreturn=_Serialize(tbl)
return objectreturn
end
routines.utils.basicSerialize=function(s)
if s==nil then
return"\"\""
else
if((type(s)=='number')or(type(s)=='boolean')or(type(s)=='function')or(type(s)=='table')or(type(s)=='userdata'))then
return tostring(s)
elseif type(s)=='string'then
s=string.format('%q',s)
return s
end
end
end
routines.utils.toDegree=function(angle)
return angle*180/math.pi
end
routines.utils.toRadian=function(angle)
return angle*math.pi/180
end
routines.utils.metersToNM=function(meters)
return meters/1852
end
routines.utils.metersToFeet=function(meters)
return meters/0.3048
end
routines.utils.NMToMeters=function(NM)
return NM*1852
end
routines.utils.feetToMeters=function(feet)
return feet*0.3048
end
routines.utils.mpsToKnots=function(mps)
return mps*3600/1852
end
routines.utils.mpsToKmph=function(mps)
return mps*3.6
end
routines.utils.knotsToMps=function(knots)
return knots*1852/3600
end
routines.utils.kmphToMps=function(kmph)
return kmph/3.6
end
function routines.utils.makeVec2(Vec3)
if Vec3.z then
return{x=Vec3.x,y=Vec3.z}
else
return{x=Vec3.x,y=Vec3.y}
end
end
function routines.utils.makeVec3(Vec2,y)
if not Vec2.z then
if not y then
y=0
end
return{x=Vec2.x,y=y,z=Vec2.y}
else
return{x=Vec2.x,y=Vec2.y,z=Vec2.z}
end
end
function routines.utils.makeVec3GL(Vec2,offset)
local adj=offset or 0
if not Vec2.z then
return{x=Vec2.x,y=(land.getHeight(Vec2)+adj),z=Vec2.y}
else
return{x=Vec2.x,y=(land.getHeight({x=Vec2.x,y=Vec2.z})+adj),z=Vec2.z}
end
end
routines.utils.zoneToVec3=function(zone)
local new={}
if type(zone)=='table'and zone.point then
new.x=zone.point.x
new.y=zone.point.y
new.z=zone.point.z
return new
elseif type(zone)=='string'then
zone=trigger.misc.getZone(zone)
if zone then
new.x=zone.point.x
new.y=zone.point.y
new.z=zone.point.z
return new
end
end
end
function routines.utils.getDir(vec,point)
local dir=math.atan2(vec.z,vec.x)
dir=dir+routines.getNorthCorrection(point)
if dir<0 then
dir=dir+2*math.pi
end
return dir
end
function routines.utils.get2DDist(point1,point2)
point1=routines.utils.makeVec3(point1)
point2=routines.utils.makeVec3(point2)
return routines.vec.mag({x=point1.x-point2.x,y=0,z=point1.z-point2.z})
end
function routines.utils.get3DDist(point1,point2)
return routines.vec.mag({x=point1.x-point2.x,y=point1.y-point2.y,z=point1.z-point2.z})
end
routines.vec={}
routines.vec.add=function(vec1,vec2)
return{x=vec1.x+vec2.x,y=vec1.y+vec2.y,z=vec1.z+vec2.z}
end
routines.vec.sub=function(vec1,vec2)
return{x=vec1.x-vec2.x,y=vec1.y-vec2.y,z=vec1.z-vec2.z}
end
routines.vec.scalarMult=function(vec,mult)
return{x=vec.x*mult,y=vec.y*mult,z=vec.z*mult}
end
routines.vec.scalar_mult=routines.vec.scalarMult
routines.vec.dp=function(vec1,vec2)
return vec1.x*vec2.x+vec1.y*vec2.y+vec1.z*vec2.z
end
routines.vec.cp=function(vec1,vec2)
return{x=vec1.y*vec2.z-vec1.z*vec2.y,y=vec1.z*vec2.x-vec1.x*vec2.z,z=vec1.x*vec2.y-vec1.y*vec2.x}
end
routines.vec.mag=function(vec)
return(vec.x^2+vec.y^2+vec.z^2)^0.5
end
routines.vec.getUnitVec=function(vec)
local mag=routines.vec.mag(vec)
return{x=vec.x/mag,y=vec.y/mag,z=vec.z/mag}
end
routines.vec.rotateVec2=function(vec2,theta)
return{x=vec2.x*math.cos(theta)-vec2.y*math.sin(theta),y=vec2.x*math.sin(theta)+vec2.y*math.cos(theta)}
end
routines.tostringMGRS=function(MGRS,acc)
if acc==0 then
return MGRS.UTMZone..' '..MGRS.MGRSDigraph
else
return MGRS.UTMZone..' '..MGRS.MGRSDigraph..' '..string.format('%0'..acc..'d',routines.utils.round(MGRS.Easting/(10^(5-acc)),0))
..' '..string.format('%0'..acc..'d',routines.utils.round(MGRS.Northing/(10^(5-acc)),0))
end
end
routines.tostringLL=function(lat,lon,acc,DMS)
local latHemi,lonHemi
if lat>0 then
latHemi='N'
else
latHemi='S'
end
if lon>0 then
lonHemi='E'
else
lonHemi='W'
end
lat=math.abs(lat)
lon=math.abs(lon)
local latDeg=math.floor(lat)
local latMin=(lat-latDeg)*60
local lonDeg=math.floor(lon)
local lonMin=(lon-lonDeg)*60
if DMS then
local oldLatMin=latMin
latMin=math.floor(latMin)
local latSec=routines.utils.round((oldLatMin-latMin)*60,acc)
local oldLonMin=lonMin
lonMin=math.floor(lonMin)
local lonSec=routines.utils.round((oldLonMin-lonMin)*60,acc)
if latSec==60 then
latSec=0
latMin=latMin+1
end
if lonSec==60 then
lonSec=0
lonMin=lonMin+1
end
local secFrmtStr
if acc<=0 then
secFrmtStr='%02d'
else
local width=3+acc
secFrmtStr='%0'..width..'.'..acc..'f'
end
return string.format('%02d',latDeg)..' '..string.format('%02d',latMin)..'\' '..string.format(secFrmtStr,latSec)..'"'..latHemi..'   '
..string.format('%02d',lonDeg)..' '..string.format('%02d',lonMin)..'\' '..string.format(secFrmtStr,lonSec)..'"'..lonHemi
else
latMin=routines.utils.round(latMin,acc)
lonMin=routines.utils.round(lonMin,acc)
if latMin==60 then
latMin=0
latDeg=latDeg+1
end
if lonMin==60 then
lonMin=0
lonDeg=lonDeg+1
end
local minFrmtStr
if acc<=0 then
minFrmtStr='%02d'
else
local width=3+acc
minFrmtStr='%0'..width..'.'..acc..'f'
end
return string.format('%02d',latDeg)..' '..string.format(minFrmtStr,latMin)..'\''..latHemi..'   '
..string.format('%02d',lonDeg)..' '..string.format(minFrmtStr,lonMin)..'\''..lonHemi
end
end
routines.tostringBR=function(az,dist,alt,metric)
az=routines.utils.round(routines.utils.toDegree(az),0)
if metric then
dist=routines.utils.round(dist/1000,2)
else
dist=routines.utils.round(routines.utils.metersToNM(dist),2)
end
local s=string.format('%03d',az)..' for '..dist
if alt then
if metric then
s=s..' at '..routines.utils.round(alt,0)
else
s=s..' at '..routines.utils.round(routines.utils.metersToFeet(alt),0)
end
end
return s
end
routines.getNorthCorrection=function(point)
if not point.z then
point.z=point.y
point.y=0
end
local lat,lon=coord.LOtoLL(point)
local north_posit=coord.LLtoLO(lat+1,lon)
return math.atan2(north_posit.z-point.z,north_posit.x-point.x)
end
do
local idNum=0
routines.addEventHandler=function(f)
local handler={}
idNum=idNum+1
handler.id=idNum
handler.f=f
handler.onEvent=function(self,event)
self.f(event)
end
world.addEventHandler(handler)
end
routines.removeEventHandler=function(id)
for key,handler in pairs(world.eventHandlers)do
if handler.id and handler.id==id then
world.eventHandlers[key]=nil
return true
end
end
return false
end
end
function routines.getRandPointInCircle(point,radius,innerRadius)
local theta=2*math.pi*math.random()
local rad=math.random()+math.random()
if rad>1 then
rad=2-rad
end
local radMult
if innerRadius and innerRadius<=radius then
radMult=(radius-innerRadius)*rad+innerRadius
else
radMult=radius*rad
end
if not point.z then
point.z=point.y
end
local rndCoord
if radius>0 then
rndCoord={x=math.cos(theta)*radMult+point.x,y=math.sin(theta)*radMult+point.z}
else
rndCoord={x=point.x,y=point.z}
end
return rndCoord
end
routines.goRoute=function(group,path)
local misTask={
id='Mission',
params={
route={
points=routines.utils.deepCopy(path),
},
},
}
if type(group)=='string'then
group=Group.getByName(group)
end
local groupCon=group:getController()
if groupCon then
groupCon:setTask(misTask)
return true
end
Controller.setTask(groupCon,misTask)
return false
end
routines.ground={}
routines.fixedWing={}
routines.heli={}
routines.ground.buildWP=function(point,overRideForm,overRideSpeed)
local wp={}
wp.x=point.x
if point.z then
wp.y=point.z
else
wp.y=point.y
end
local form,speed
if point.speed and not overRideSpeed then
wp.speed=point.speed
elseif type(overRideSpeed)=='number'then
wp.speed=overRideSpeed
else
wp.speed=routines.utils.kmphToMps(20)
end
if point.form and not overRideForm then
form=point.form
else
form=overRideForm
end
if not form then
wp.action='Cone'
else
form=string.lower(form)
if form=='off_road'or form=='off road'then
wp.action='Off Road'
elseif form=='on_road'or form=='on road'then
wp.action='On Road'
elseif form=='rank'or form=='line_abrest'or form=='line abrest'or form=='lineabrest'then
wp.action='Rank'
elseif form=='cone'then
wp.action='Cone'
elseif form=='diamond'then
wp.action='Diamond'
elseif form=='vee'then
wp.action='Vee'
elseif form=='echelon_left'or form=='echelon left'or form=='echelonl'then
wp.action='EchelonL'
elseif form=='echelon_right'or form=='echelon right'or form=='echelonr'then
wp.action='EchelonR'
else
wp.action='Cone'
end
end
wp.type='Turning Point'
return wp
end
routines.fixedWing.buildWP=function(point,WPtype,speed,alt,altType)
local wp={}
wp.x=point.x
if point.z then
wp.y=point.z
else
wp.y=point.y
end
if alt and type(alt)=='number'then
wp.alt=alt
else
wp.alt=2000
end
if altType then
altType=string.lower(altType)
if altType=='radio'or'agl'then
wp.alt_type='RADIO'
elseif altType=='baro'or'asl'then
wp.alt_type='BARO'
end
else
wp.alt_type='RADIO'
end
if point.speed then
speed=point.speed
end
if point.type then
WPtype=point.type
end
if not speed then
wp.speed=routines.utils.kmphToMps(500)
else
wp.speed=speed
end
if not WPtype then
wp.action='Turning Point'
else
WPtype=string.lower(WPtype)
if WPtype=='flyover'or WPtype=='fly over'or WPtype=='fly_over'then
wp.action='Fly Over Point'
elseif WPtype=='turningpoint'or WPtype=='turning point'or WPtype=='turning_point'then
wp.action='Turning Point'
else
wp.action='Turning Point'
end
end
wp.type='Turning Point'
return wp
end
routines.heli.buildWP=function(point,WPtype,speed,alt,altType)
local wp={}
wp.x=point.x
if point.z then
wp.y=point.z
else
wp.y=point.y
end
if alt and type(alt)=='number'then
wp.alt=alt
else
wp.alt=500
end
if altType then
altType=string.lower(altType)
if altType=='radio'or'agl'then
wp.alt_type='RADIO'
elseif altType=='baro'or'asl'then
wp.alt_type='BARO'
end
else
wp.alt_type='RADIO'
end
if point.speed then
speed=point.speed
end
if point.type then
WPtype=point.type
end
if not speed then
wp.speed=routines.utils.kmphToMps(200)
else
wp.speed=speed
end
if not WPtype then
wp.action='Turning Point'
else
WPtype=string.lower(WPtype)
if WPtype=='flyover'or WPtype=='fly over'or WPtype=='fly_over'then
wp.action='Fly Over Point'
elseif WPtype=='turningpoint'or WPtype=='turning point'or WPtype=='turning_point'then
wp.action='Turning Point'
else
wp.action='Turning Point'
end
end
wp.type='Turning Point'
return wp
end
routines.groupToRandomPoint=function(vars)
local group=vars.group
local point=vars.point
local radius=vars.radius or 0
local innerRadius=vars.innerRadius
local form=vars.form or'Cone'
local heading=vars.heading or math.random()*2*math.pi
local headingDegrees=vars.headingDegrees
local speed=vars.speed or routines.utils.kmphToMps(20)
local useRoads
if not vars.disableRoads then
useRoads=true
else
useRoads=false
end
local path={}
if headingDegrees then
heading=headingDegrees*math.pi/180
end
if heading>=2*math.pi then
heading=heading-2*math.pi
end
local rndCoord=routines.getRandPointInCircle(point,radius,innerRadius)
local offset={}
local posStart=routines.getLeadPos(group)
offset.x=routines.utils.round(math.sin(heading-(math.pi/2))*50+rndCoord.x,3)
offset.z=routines.utils.round(math.cos(heading+(math.pi/2))*50+rndCoord.y,3)
path[#path+1]=routines.ground.buildWP(posStart,form,speed)
if useRoads==true and((point.x-posStart.x)^2+(point.z-posStart.z)^2)^0.5>radius*1.3 then
path[#path+1]=routines.ground.buildWP({['x']=posStart.x+11,['z']=posStart.z+11},'off_road',speed)
path[#path+1]=routines.ground.buildWP(posStart,'on_road',speed)
path[#path+1]=routines.ground.buildWP(offset,'on_road',speed)
else
path[#path+1]=routines.ground.buildWP({['x']=posStart.x+25,['z']=posStart.z+25},form,speed)
end
path[#path+1]=routines.ground.buildWP(offset,form,speed)
path[#path+1]=routines.ground.buildWP(rndCoord,form,speed)
routines.goRoute(group,path)
return
end
routines.groupRandomDistSelf=function(gpData,dist,form,heading,speed)
local pos=routines.getLeadPos(gpData)
local fakeZone={}
fakeZone.radius=dist or math.random(300,1000)
fakeZone.point={x=pos.x,y,pos.y,z=pos.z}
routines.groupToRandomZone(gpData,fakeZone,form,heading,speed)
return
end
routines.groupToRandomZone=function(gpData,zone,form,heading,speed)
if type(gpData)=='string'then
gpData=Group.getByName(gpData)
end
if type(zone)=='string'then
zone=trigger.misc.getZone(zone)
elseif type(zone)=='table'and not zone.radius then
zone=trigger.misc.getZone(zone[math.random(1,#zone)])
end
if speed then
speed=routines.utils.kmphToMps(speed)
end
local vars={}
vars.group=gpData
vars.radius=zone.radius
vars.form=form
vars.headingDegrees=heading
vars.speed=speed
vars.point=routines.utils.zoneToVec3(zone)
routines.groupToRandomPoint(vars)
return
end
routines.isTerrainValid=function(coord,terrainTypes)
if coord.z then
coord.y=coord.z
end
local typeConverted={}
if type(terrainTypes)=='string'then
for constId,constData in pairs(land.SurfaceType)do
if string.lower(constId)==string.lower(terrainTypes)or string.lower(constData)==string.lower(terrainTypes)then
table.insert(typeConverted,constId)
end
end
elseif type(terrainTypes)=='table'then
for typeId,typeData in pairs(terrainTypes)do
for constId,constData in pairs(land.SurfaceType)do
if string.lower(constId)==string.lower(typeData)or string.lower(constData)==string.lower(typeId)then
table.insert(typeConverted,constId)
end
end
end
end
for validIndex,validData in pairs(typeConverted)do
if land.getSurfaceType(coord)==land.SurfaceType[validData]then
return true
end
end
return false
end
routines.groupToPoint=function(gpData,point,form,heading,speed,useRoads)
if type(point)=='string'then
point=trigger.misc.getZone(point)
end
if speed then
speed=routines.utils.kmphToMps(speed)
end
local vars={}
vars.group=gpData
vars.form=form
vars.headingDegrees=heading
vars.speed=speed
vars.disableRoads=useRoads
vars.point=routines.utils.zoneToVec3(point)
routines.groupToRandomPoint(vars)
return
end
routines.getLeadPos=function(group)
if type(group)=='string'then
group=Group.getByName(group)
end
local units=group:getUnits()
local leader=units[1]
if not leader then
local lowestInd=math.huge
for ind,unit in pairs(units)do
if ind<lowestInd then
lowestInd=ind
leader=unit
end
end
end
if leader and Unit.isExist(leader)then
return leader:getPosition().p
end
end
routines.getMGRSString=function(vars)
local units=vars.units
local acc=vars.acc or 5
local avgPos=routines.getAvgPos(units)
if avgPos then
return routines.tostringMGRS(coord.LLtoMGRS(coord.LOtoLL(avgPos)),acc)
end
end
routines.getLLString=function(vars)
local units=vars.units
local acc=vars.acc or 3
local DMS=vars.DMS
local avgPos=routines.getAvgPos(units)
if avgPos then
local lat,lon=coord.LOtoLL(avgPos)
return routines.tostringLL(lat,lon,acc,DMS)
end
end
routines.getBRStringZone=function(vars)
local zone=trigger.misc.getZone(vars.zone)
local ref=routines.utils.makeVec3(vars.ref,0)
local alt=vars.alt
local metric=vars.metric
if zone then
local vec={x=zone.point.x-ref.x,y=zone.point.y-ref.y,z=zone.point.z-ref.z}
local dir=routines.utils.getDir(vec,ref)
local dist=routines.utils.get2DDist(zone.point,ref)
if alt then
alt=zone.y
end
return routines.tostringBR(dir,dist,alt,metric)
else
env.info('routines.getBRStringZone: error: zone is nil')
end
end
routines.getBRString=function(vars)
local units=vars.units
local ref=routines.utils.makeVec3(vars.ref,0)
local alt=vars.alt
local metric=vars.metric
local avgPos=routines.getAvgPos(units)
if avgPos then
local vec={x=avgPos.x-ref.x,y=avgPos.y-ref.y,z=avgPos.z-ref.z}
local dir=routines.utils.getDir(vec,ref)
local dist=routines.utils.get2DDist(avgPos,ref)
if alt then
alt=avgPos.y
end
return routines.tostringBR(dir,dist,alt,metric)
end
end
routines.getLeadingPos=function(vars)
local units=vars.units
local heading=vars.heading
local radius=vars.radius
if vars.headingDegrees then
heading=routines.utils.toRadian(vars.headingDegrees)
end
local unitPosTbl={}
for i=1,#units do
local unit=Unit.getByName(units[i])
if unit and unit:isExist()then
unitPosTbl[#unitPosTbl+1]=unit:getPosition().p
end
end
if#unitPosTbl>0 then
local maxPos=-math.huge
local maxPosInd
for i=1,#unitPosTbl do
local rotatedVec2=routines.vec.rotateVec2(routines.utils.makeVec2(unitPosTbl[i]),heading)
if(not maxPos)or maxPos<rotatedVec2.x then
maxPos=rotatedVec2.x
maxPosInd=i
end
end
local avgPos
if radius then
local maxUnitPos=unitPosTbl[maxPosInd]
local avgx,avgy,avgz,totNum=0,0,0,0
for i=1,#unitPosTbl do
if routines.utils.get2DDist(maxUnitPos,unitPosTbl[i])<=radius then
avgx=avgx+unitPosTbl[i].x
avgy=avgy+unitPosTbl[i].y
avgz=avgz+unitPosTbl[i].z
totNum=totNum+1
end
end
avgPos={x=avgx/totNum,y=avgy/totNum,z=avgz/totNum}
else
avgPos=unitPosTbl[maxPosInd]
end
return avgPos
end
end
routines.getLeadingMGRSString=function(vars)
local pos=routines.getLeadingPos(vars)
if pos then
local acc=vars.acc or 5
return routines.tostringMGRS(coord.LLtoMGRS(coord.LOtoLL(pos)),acc)
end
end
routines.getLeadingLLString=function(vars)
local pos=routines.getLeadingPos(vars)
if pos then
local acc=vars.acc or 3
local DMS=vars.DMS
local lat,lon=coord.LOtoLL(pos)
return routines.tostringLL(lat,lon,acc,DMS)
end
end
routines.getLeadingBRString=function(vars)
local pos=routines.getLeadingPos(vars)
if pos then
local ref=vars.ref
local alt=vars.alt
local metric=vars.metric
local vec={x=pos.x-ref.x,y=pos.y-ref.y,z=pos.z-ref.z}
local dir=routines.utils.getDir(vec,ref)
local dist=routines.utils.get2DDist(pos,ref)
if alt then
alt=pos.y
end
return routines.tostringBR(dir,dist,alt,metric)
end
end
routines.msgMGRS=function(vars)
local units=vars.units
local acc=vars.acc
local text=vars.text
local displayTime=vars.displayTime
local msgFor=vars.msgFor
local s=routines.getMGRSString{units=units,acc=acc}
local newText
if string.find(text,'%%s')then
newText=string.format(text,s)
else
newText=text..s
end
routines.message.add{
text=newText,
displayTime=displayTime,
msgFor=msgFor
}
end
routines.msgLL=function(vars)
local units=vars.units
local acc=vars.acc
local DMS=vars.DMS
local text=vars.text
local displayTime=vars.displayTime
local msgFor=vars.msgFor
local s=routines.getLLString{units=units,acc=acc,DMS=DMS}
local newText
if string.find(text,'%%s')then
newText=string.format(text,s)
else
newText=text..s
end
routines.message.add{
text=newText,
displayTime=displayTime,
msgFor=msgFor
}
end
routines.msgBR=function(vars)
local units=vars.units
local ref=vars.ref
local alt=vars.alt
local metric=vars.metric
local text=vars.text
local displayTime=vars.displayTime
local msgFor=vars.msgFor
local s=routines.getBRString{units=units,ref=ref,alt=alt,metric=metric}
local newText
if string.find(text,'%%s')then
newText=string.format(text,s)
else
newText=text..s
end
routines.message.add{
text=newText,
displayTime=displayTime,
msgFor=msgFor
}
end
routines.msgBullseye=function(vars)
if string.lower(vars.ref)=='red'then
vars.ref=routines.DBs.missionData.bullseye.red
routines.msgBR(vars)
elseif string.lower(vars.ref)=='blue'then
vars.ref=routines.DBs.missionData.bullseye.blue
routines.msgBR(vars)
end
end
routines.msgBRA=function(vars)
if Unit.getByName(vars.ref)then
vars.ref=Unit.getByName(vars.ref):getPosition().p
if not vars.alt then
vars.alt=true
end
routines.msgBR(vars)
end
end
routines.msgLeadingMGRS=function(vars)
local units=vars.units
local heading=vars.heading
local radius=vars.radius
local headingDegrees=vars.headingDegrees
local acc=vars.acc
local text=vars.text
local displayTime=vars.displayTime
local msgFor=vars.msgFor
local s=routines.getLeadingMGRSString{units=units,heading=heading,radius=radius,headingDegrees=headingDegrees,acc=acc}
local newText
if string.find(text,'%%s')then
newText=string.format(text,s)
else
newText=text..s
end
routines.message.add{
text=newText,
displayTime=displayTime,
msgFor=msgFor
}
end
routines.msgLeadingLL=function(vars)
local units=vars.units
local heading=vars.heading
local radius=vars.radius
local headingDegrees=vars.headingDegrees
local acc=vars.acc
local DMS=vars.DMS
local text=vars.text
local displayTime=vars.displayTime
local msgFor=vars.msgFor
local s=routines.getLeadingLLString{units=units,heading=heading,radius=radius,headingDegrees=headingDegrees,acc=acc,DMS=DMS}
local newText
if string.find(text,'%%s')then
newText=string.format(text,s)
else
newText=text..s
end
routines.message.add{
text=newText,
displayTime=displayTime,
msgFor=msgFor
}
end
routines.msgLeadingBR=function(vars)
local units=vars.units
local heading=vars.heading
local radius=vars.radius
local headingDegrees=vars.headingDegrees
local metric=vars.metric
local alt=vars.alt
local ref=vars.ref
local text=vars.text
local displayTime=vars.displayTime
local msgFor=vars.msgFor
local s=routines.getLeadingBRString{units=units,heading=heading,radius=radius,headingDegrees=headingDegrees,metric=metric,alt=alt,ref=ref}
local newText
if string.find(text,'%%s')then
newText=string.format(text,s)
else
newText=text..s
end
routines.message.add{
text=newText,
displayTime=displayTime,
msgFor=msgFor
}
end
function spairs(t,order)
local keys={}
for k in pairs(t)do keys[#keys+1]=k end
if order then
table.sort(keys,function(a,b)return order(t,a,b)end)
else
table.sort(keys)
end
local i=0
return function()
i=i+1
if keys[i]then
return keys[i],t[keys[i]]
end
end
end
function routines.IsPartOfGroupInZones(CargoGroup,LandingZones)
local CurrentZoneID=nil
if CargoGroup then
local CargoUnits=CargoGroup:getUnits()
for CargoUnitID,CargoUnit in pairs(CargoUnits)do
if CargoUnit and CargoUnit:getLife()>=1.0 then
CurrentZoneID=routines.IsUnitInZones(CargoUnit,LandingZones)
if CurrentZoneID then
break
end
end
end
end
return CurrentZoneID
end
function routines.IsUnitInZones(TransportUnit,LandingZones)
local TransportZoneResult=nil
local TransportZonePos=nil
local TransportZone=nil
if TransportUnit then
local TransportUnitPos=TransportUnit:getPosition().p
if type(LandingZones)=="table"then
for LandingZoneID,LandingZoneName in pairs(LandingZones)do
TransportZone=trigger.misc.getZone(LandingZoneName)
if TransportZone then
TransportZonePos={radius=TransportZone.radius,x=TransportZone.point.x,y=TransportZone.point.y,z=TransportZone.point.z}
if(((TransportUnitPos.x-TransportZonePos.x)^2+(TransportUnitPos.z-TransportZonePos.z)^2)^0.5<=TransportZonePos.radius)then
TransportZoneResult=LandingZoneID
break
end
end
end
else
TransportZone=trigger.misc.getZone(LandingZones)
TransportZonePos={radius=TransportZone.radius,x=TransportZone.point.x,y=TransportZone.point.y,z=TransportZone.point.z}
if(((TransportUnitPos.x-TransportZonePos.x)^2+(TransportUnitPos.z-TransportZonePos.z)^2)^0.5<=TransportZonePos.radius)then
TransportZoneResult=1
end
end
if TransportZoneResult then
else
end
return TransportZoneResult
else
return nil
end
end
function routines.IsUnitNearZonesRadius(TransportUnit,LandingZones,ZoneRadius)
local TransportZoneResult=nil
local TransportZonePos=nil
local TransportZone=nil
if TransportUnit then
local TransportUnitPos=TransportUnit:getPosition().p
if type(LandingZones)=="table"then
for LandingZoneID,LandingZoneName in pairs(LandingZones)do
TransportZone=trigger.misc.getZone(LandingZoneName)
if TransportZone then
TransportZonePos={radius=TransportZone.radius,x=TransportZone.point.x,y=TransportZone.point.y,z=TransportZone.point.z}
if(((TransportUnitPos.x-TransportZonePos.x)^2+(TransportUnitPos.z-TransportZonePos.z)^2)^0.5<=ZoneRadius)then
TransportZoneResult=LandingZoneID
break
end
end
end
else
TransportZone=trigger.misc.getZone(LandingZones)
TransportZonePos={radius=TransportZone.radius,x=TransportZone.point.x,y=TransportZone.point.y,z=TransportZone.point.z}
if(((TransportUnitPos.x-TransportZonePos.x)^2+(TransportUnitPos.z-TransportZonePos.z)^2)^0.5<=ZoneRadius)then
TransportZoneResult=1
end
end
if TransportZoneResult then
else
end
return TransportZoneResult
else
return nil
end
end
function routines.IsStaticInZones(TransportStatic,LandingZones)
local TransportZoneResult=nil
local TransportZonePos=nil
local TransportZone=nil
local TransportStaticPos=TransportStatic:getPosition().p
if type(LandingZones)=="table"then
for LandingZoneID,LandingZoneName in pairs(LandingZones)do
TransportZone=trigger.misc.getZone(LandingZoneName)
if TransportZone then
TransportZonePos={radius=TransportZone.radius,x=TransportZone.point.x,y=TransportZone.point.y,z=TransportZone.point.z}
if(((TransportStaticPos.x-TransportZonePos.x)^2+(TransportStaticPos.z-TransportZonePos.z)^2)^0.5<=TransportZonePos.radius)then
TransportZoneResult=LandingZoneID
break
end
end
end
else
TransportZone=trigger.misc.getZone(LandingZones)
TransportZonePos={radius=TransportZone.radius,x=TransportZone.point.x,y=TransportZone.point.y,z=TransportZone.point.z}
if(((TransportStaticPos.x-TransportZonePos.x)^2+(TransportStaticPos.z-TransportZonePos.z)^2)^0.5<=TransportZonePos.radius)then
TransportZoneResult=1
end
end
return TransportZoneResult
end
function routines.IsUnitInRadius(CargoUnit,ReferencePosition,Radius)
local Valid=true
local CargoPos=CargoUnit:getPosition().p
local ReferenceP=ReferencePosition.p
if(((CargoPos.x-ReferenceP.x)^2+(CargoPos.z-ReferenceP.z)^2)^0.5<=Radius)then
else
Valid=false
end
return Valid
end
function routines.IsPartOfGroupInRadius(CargoGroup,ReferencePosition,Radius)
local Valid=true
Valid=routines.ValidateGroup(CargoGroup,"CargoGroup",Valid)
local CargoUnits=CargoGroup:getUnits()
for CargoUnitId,CargoUnit in pairs(CargoUnits)do
local CargoUnitPos=CargoUnit:getPosition().p
local ReferenceP=ReferencePosition.p
if(((CargoUnitPos.x-ReferenceP.x)^2+(CargoUnitPos.z-ReferenceP.z)^2)^0.5<=Radius)then
else
Valid=false
break
end
end
return Valid
end
function routines.ValidateString(Variable,VariableName,Valid)
if type(Variable)=="string"then
if Variable==""then
error("routines.ValidateString: error: "..VariableName.." must be filled out!")
Valid=false
end
else
error("routines.ValidateString: error: "..VariableName.." is not a string.")
Valid=false
end
return Valid
end
function routines.ValidateNumber(Variable,VariableName,Valid)
if type(Variable)=="number"then
else
error("routines.ValidateNumber: error: "..VariableName.." is not a number.")
Valid=false
end
return Valid
end
function routines.ValidateGroup(Variable,VariableName,Valid)
if Variable==nil then
error("routines.ValidateGroup: error: "..VariableName.." is a nil value!")
Valid=false
end
return Valid
end
function routines.ValidateZone(LandingZones,VariableName,Valid)
if LandingZones==nil then
error("routines.ValidateGroup: error: "..VariableName.." is a nil value!")
Valid=false
end
if type(LandingZones)=="table"then
for LandingZoneID,LandingZoneName in pairs(LandingZones)do
if trigger.misc.getZone(LandingZoneName)==nil then
error("routines.ValidateGroup: error: Zone "..LandingZoneName.." does not exist!")
Valid=false
break
end
end
else
if trigger.misc.getZone(LandingZones)==nil then
error("routines.ValidateGroup: error: Zone "..LandingZones.." does not exist!")
Valid=false
end
end
return Valid
end
function routines.ValidateEnumeration(Variable,VariableName,Enum,Valid)
local ValidVariable=false
for EnumId,EnumData in pairs(Enum)do
if Variable==EnumData then
ValidVariable=true
break
end
end
if ValidVariable then
else
error('TransportValidateEnum: " .. VariableName .. " is not a valid type.'..Variable)
Valid=false
end
return Valid
end
function routines.getGroupRoute(groupIdent,task)
local gpId=groupIdent
if type(groupIdent)=='string'and not tonumber(groupIdent)then
gpId=_DATABASE.Templates.Groups[groupIdent].groupId
end
for coa_name,coa_data in pairs(env.mission.coalition)do
if(coa_name=='red'or coa_name=='blue')and type(coa_data)=='table'then
if coa_data.country then
for cntry_id,cntry_data in pairs(coa_data.country)do
for obj_type_name,obj_type_data in pairs(cntry_data)do
if obj_type_name=="helicopter"or obj_type_name=="ship"or obj_type_name=="plane"or obj_type_name=="vehicle"then
if((type(obj_type_data)=='table')and obj_type_data.group and(type(obj_type_data.group)=='table')and(#obj_type_data.group>0))then
for group_num,group_data in pairs(obj_type_data.group)do
if group_data and group_data.groupId==gpId then
if group_data.route and group_data.route.points and#group_data.route.points>0 then
local points={}
for point_num,point in pairs(group_data.route.points)do
local routeData={}
if not point.point then
routeData.x=point.x
routeData.y=point.y
else
routeData.point=point.point
end
routeData.form=point.action
routeData.speed=point.speed
routeData.alt=point.alt
routeData.alt_type=point.alt_type
routeData.airdromeId=point.airdromeId
routeData.helipadId=point.helipadId
routeData.type=point.type
routeData.action=point.action
if task then
routeData.task=point.task
end
points[point_num]=routeData
end
return points
end
return
end
end
end
end
end
end
end
end
end
end
routines.ground.patrolRoute=function(vars)
local tempRoute={}
local useRoute={}
local gpData=vars.gpData
if type(gpData)=='string'then
gpData=Group.getByName(gpData)
end
local useGroupRoute
if not vars.useGroupRoute then
useGroupRoute=vars.gpData
else
useGroupRoute=vars.useGroupRoute
end
local routeProvided=false
if not vars.route then
if useGroupRoute then
tempRoute=routines.getGroupRoute(useGroupRoute)
end
else
useRoute=vars.route
local posStart=routines.getLeadPos(gpData)
useRoute[1]=routines.ground.buildWP(posStart,useRoute[1].action,useRoute[1].speed)
routeProvided=true
end
local overRideSpeed=vars.speed or'default'
local pType=vars.pType
local offRoadForm=vars.offRoadForm or'default'
local onRoadForm=vars.onRoadForm or'default'
if routeProvided==false and#tempRoute>0 then
local posStart=routines.getLeadPos(gpData)
useRoute[#useRoute+1]=routines.ground.buildWP(posStart,offRoadForm,overRideSpeed)
for i=1,#tempRoute do
local tempForm=tempRoute[i].action
local tempSpeed=tempRoute[i].speed
if offRoadForm=='default'then
tempForm=tempRoute[i].action
end
if onRoadForm=='default'then
onRoadForm='On Road'
end
if(string.lower(tempRoute[i].action)=='on road'or string.lower(tempRoute[i].action)=='onroad'or string.lower(tempRoute[i].action)=='on_road')then
tempForm=onRoadForm
else
tempForm=offRoadForm
end
if type(overRideSpeed)=='number'then
tempSpeed=overRideSpeed
end
useRoute[#useRoute+1]=routines.ground.buildWP(tempRoute[i],tempForm,tempSpeed)
end
if pType and string.lower(pType)=='doubleback'then
local curRoute=routines.utils.deepCopy(useRoute)
for i=#curRoute,2,-1 do
useRoute[#useRoute+1]=routines.ground.buildWP(curRoute[i],curRoute[i].action,curRoute[i].speed)
end
end
useRoute[1].action=useRoute[#useRoute].action
end
local cTask3={}
local newPatrol={}
newPatrol.route=useRoute
newPatrol.gpData=gpData:getName()
cTask3[#cTask3+1]='routines.ground.patrolRoute('
cTask3[#cTask3+1]=routines.utils.oneLineSerialize(newPatrol)
cTask3[#cTask3+1]=')'
cTask3=table.concat(cTask3)
local tempTask={
id='WrappedAction',
params={
action={
id='Script',
params={
command=cTask3,
},
},
},
}
useRoute[#useRoute].task=tempTask
routines.goRoute(gpData,useRoute)
return
end
routines.ground.patrol=function(gpData,pType,form,speed)
local vars={}
if type(gpData)=='table'and gpData:getName()then
gpData=gpData:getName()
end
vars.useGroupRoute=gpData
vars.gpData=gpData
vars.pType=pType
vars.offRoadForm=form
vars.speed=speed
routines.ground.patrolRoute(vars)
return
end
function routines.GetUnitHeight(CheckUnit)
local UnitPoint=CheckUnit:getPoint()
local UnitPosition={x=UnitPoint.x,y=UnitPoint.z}
local UnitHeight=UnitPoint.y
local LandHeight=land.getHeight(UnitPosition)
return UnitHeight-LandHeight
end
Su34Status={status={}}
boardMsgRed={statusMsg=""}
boardMsgAll={timeMsg=""}
SpawnSettings={}
Su34MenuPath={}
Su34Menus=0
function Su34AttackCarlVinson(groupName)
local groupSu34=Group.getByName(groupName)
local controllerSu34=groupSu34.getController(groupSu34)
local groupCarlVinson=Group.getByName("US Carl Vinson #001")
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.OPEN_FIRE)
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
if groupCarlVinson~=nil then
controllerSu34.pushTask(controllerSu34,{id='AttackGroup',params={groupId=groupCarlVinson:getID(),expend=AI.Task.WeaponExpend.ALL,attackQtyLimit=true}})
end
Su34Status.status[groupName]=1
MessageToRed(string.format('%s: ',groupName)..'Attacking carrier Carl Vinson. ',10,'RedStatus'..groupName)
end
function Su34AttackWest(groupName)
local groupSu34=Group.getByName(groupName)
local controllerSu34=groupSu34.getController(groupSu34)
local groupShipWest1=Group.getByName("US Ship West #001")
local groupShipWest2=Group.getByName("US Ship West #002")
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.OPEN_FIRE)
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
if groupShipWest1~=nil then
controllerSu34.pushTask(controllerSu34,{id='AttackGroup',params={groupId=groupShipWest1:getID(),expend=AI.Task.WeaponExpend.ALL,attackQtyLimit=true}})
end
if groupShipWest2~=nil then
controllerSu34.pushTask(controllerSu34,{id='AttackGroup',params={groupId=groupShipWest2:getID(),expend=AI.Task.WeaponExpend.ALL,attackQtyLimit=true}})
end
Su34Status.status[groupName]=2
MessageToRed(string.format('%s: ',groupName)..'Attacking invading ships in the west. ',10,'RedStatus'..groupName)
end
function Su34AttackNorth(groupName)
local groupSu34=Group.getByName(groupName)
local controllerSu34=groupSu34.getController(groupSu34)
local groupShipNorth1=Group.getByName("US Ship North #001")
local groupShipNorth2=Group.getByName("US Ship North #002")
local groupShipNorth3=Group.getByName("US Ship North #003")
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.OPEN_FIRE)
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
if groupShipNorth1~=nil then
controllerSu34.pushTask(controllerSu34,{id='AttackGroup',params={groupId=groupShipNorth1:getID(),expend=AI.Task.WeaponExpend.ALL,attackQtyLimit=false}})
end
if groupShipNorth2~=nil then
controllerSu34.pushTask(controllerSu34,{id='AttackGroup',params={groupId=groupShipNorth2:getID(),expend=AI.Task.WeaponExpend.ALL,attackQtyLimit=false}})
end
if groupShipNorth3~=nil then
controllerSu34.pushTask(controllerSu34,{id='AttackGroup',params={groupId=groupShipNorth3:getID(),expend=AI.Task.WeaponExpend.ALL,attackQtyLimit=false}})
end
Su34Status.status[groupName]=3
MessageToRed(string.format('%s: ',groupName)..'Attacking invading ships in the north. ',10,'RedStatus'..groupName)
end
function Su34Orbit(groupName)
local groupSu34=Group.getByName(groupName)
local controllerSu34=groupSu34:getController()
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.WEAPON_HOLD)
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
controllerSu34:pushTask({id='ControlledTask',params={task={id='Orbit',params={pattern=AI.Task.OrbitPattern.RACE_TRACK}},stopCondition={duration=600}}})
Su34Status.status[groupName]=4
MessageToRed(string.format('%s: ',groupName)..'In orbit and awaiting further instructions. ',10,'RedStatus'..groupName)
end
function Su34TakeOff(groupName)
local groupSu34=Group.getByName(groupName)
local controllerSu34=groupSu34:getController()
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.WEAPON_HOLD)
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE)
Su34Status.status[groupName]=8
MessageToRed(string.format('%s: ',groupName)..'Take-Off. ',10,'RedStatus'..groupName)
end
function Su34Hold(groupName)
local groupSu34=Group.getByName(groupName)
local controllerSu34=groupSu34:getController()
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.WEAPON_HOLD)
controllerSu34.setOption(controllerSu34,AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE)
Su34Status.status[groupName]=5
MessageToRed(string.format('%s: ',groupName)..'Holding Weapons. ',10,'RedStatus'..groupName)
end
function Su34RTB(groupName)
Su34Status.status[groupName]=6
MessageToRed(string.format('%s: ',groupName)..'Return to Krasnodar. ',10,'RedStatus'..groupName)
end
function Su34Destroyed(groupName)
Su34Status.status[groupName]=7
MessageToRed(string.format('%s: ',groupName)..'Destroyed. ',30,'RedStatus'..groupName)
end
function GroupAlive(groupName)
local groupTest=Group.getByName(groupName)
local groupExists=false
if groupTest then
groupExists=groupTest:isExist()
end
return groupExists
end
function Su34IsDead()
end
function Su34OverviewStatus()
local msg=""
local currentStatus=0
local Exists=false
for groupName,currentStatus in pairs(Su34Status.status)do
env.info(('Su34 Overview Status: GroupName = '..groupName))
Alive=GroupAlive(groupName)
if Alive then
if currentStatus==1 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."Attacking carrier Carl Vinson. "
elseif currentStatus==2 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."Attacking supporting ships in the west. "
elseif currentStatus==3 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."Attacking invading ships in the north. "
elseif currentStatus==4 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."In orbit and awaiting further instructions. "
elseif currentStatus==5 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."Holding Weapons. "
elseif currentStatus==6 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."Return to Krasnodar. "
elseif currentStatus==7 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."Destroyed. "
elseif currentStatus==8 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."Take-Off. "
end
else
if currentStatus==7 then
msg=msg..string.format("%s: ",groupName)
msg=msg.."Destroyed. "
else
Su34Destroyed(groupName)
end
end
end
boardMsgRed.statusMsg=msg
end
function UpdateBoardMsg()
Su34OverviewStatus()
MessageToRed(boardMsgRed.statusMsg,15,'RedStatus')
end
function MusicReset(flg)
trigger.action.setUserFlag(95,flg)
end
function PlaneActivate(groupNameFormat,flg)
local groupName=groupNameFormat..string.format("#%03d",trigger.misc.getUserFlag(flg))
trigger.action.activateGroup(Group.getByName(groupName))
end
function Su34Menu(groupName)
local groupSu34=Group.getByName(groupName)
if Su34Status.status[groupName]==1 or
Su34Status.status[groupName]==2 or
Su34Status.status[groupName]==3 or
Su34Status.status[groupName]==4 or
Su34Status.status[groupName]==5 then
if Su34MenuPath[groupName]==nil then
if planeMenuPath==nil then
planeMenuPath=missionCommands.addSubMenuForCoalition(
coalition.side.RED,
"SU-34 anti-ship flights",
nil
)
end
Su34MenuPath[groupName]=missionCommands.addSubMenuForCoalition(
coalition.side.RED,
"Flight "..groupName,
planeMenuPath
)
missionCommands.addCommandForCoalition(
coalition.side.RED,
"Attack carrier Carl Vinson",
Su34MenuPath[groupName],
Su34AttackCarlVinson,
groupName
)
missionCommands.addCommandForCoalition(
coalition.side.RED,
"Attack ships in the west",
Su34MenuPath[groupName],
Su34AttackWest,
groupName
)
missionCommands.addCommandForCoalition(
coalition.side.RED,
"Attack ships in the north",
Su34MenuPath[groupName],
Su34AttackNorth,
groupName
)
missionCommands.addCommandForCoalition(
coalition.side.RED,
"Hold position and await instructions",
Su34MenuPath[groupName],
Su34Orbit,
groupName
)
missionCommands.addCommandForCoalition(
coalition.side.RED,
"Report status",
Su34MenuPath[groupName],
Su34OverviewStatus
)
end
else
if Su34MenuPath[groupName]then
missionCommands.removeItemForCoalition(coalition.side.RED,Su34MenuPath[groupName])
end
end
end
function ChooseInfantry(TeleportPrefixTable,TeleportMax)
TeleportPrefixTableCount=#TeleportPrefixTable
TeleportPrefixTableIndex=math.random(1,TeleportPrefixTableCount)
local TeleportFound=false
local TeleportLoop=true
local Index=TeleportPrefixTableIndex
local TeleportPrefix=''
while TeleportLoop do
TeleportPrefix=TeleportPrefixTable[Index]
if SpawnSettings[TeleportPrefix]then
if SpawnSettings[TeleportPrefix]['SpawnCount']-1<TeleportMax then
SpawnSettings[TeleportPrefix]['SpawnCount']=SpawnSettings[TeleportPrefix]['SpawnCount']+1
TeleportFound=true
else
TeleportFound=false
end
else
SpawnSettings[TeleportPrefix]={}
SpawnSettings[TeleportPrefix]['SpawnCount']=0
TeleportFound=true
end
if TeleportFound then
TeleportLoop=false
else
if Index<TeleportPrefixTableCount then
Index=Index+1
else
TeleportLoop=false
end
end
end
if TeleportFound==false then
TeleportLoop=true
Index=1
while TeleportLoop do
TeleportPrefix=TeleportPrefixTable[Index]
if SpawnSettings[TeleportPrefix]then
if SpawnSettings[TeleportPrefix]['SpawnCount']-1<TeleportMax then
SpawnSettings[TeleportPrefix]['SpawnCount']=SpawnSettings[TeleportPrefix]['SpawnCount']+1
TeleportFound=true
else
TeleportFound=false
end
else
SpawnSettings[TeleportPrefix]={}
SpawnSettings[TeleportPrefix]['SpawnCount']=0
TeleportFound=true
end
if TeleportFound then
TeleportLoop=false
else
if Index<TeleportPrefixTableIndex then
Index=Index+1
else
TeleportLoop=false
end
end
end
end
local TeleportGroupName=''
if TeleportFound==true then
TeleportGroupName=TeleportPrefix..string.format("#%03d",SpawnSettings[TeleportPrefix]['SpawnCount'])
else
TeleportGroupName=''
end
return TeleportGroupName
end
SpawnedInfantry=0
function LandCarrier(CarrierGroup,LandingZonePrefix)
local controllerGroup=CarrierGroup:getController()
local LandingZone=trigger.misc.getZone(LandingZonePrefix)
local LandingZonePos={}
LandingZonePos.x=LandingZone.point.x+math.random(LandingZone.radius*-1,LandingZone.radius)
LandingZonePos.y=LandingZone.point.z+math.random(LandingZone.radius*-1,LandingZone.radius)
controllerGroup:pushTask({id='Land',params={point=LandingZonePos,durationFlag=true,duration=10}})
end
EscortCount=0
function EscortCarrier(CarrierGroup,EscortPrefix,EscortLastWayPoint,EscortEngagementDistanceMax,EscortTargetTypes)
local CarrierName=CarrierGroup:getName()
local EscortMission={}
local CarrierMission={}
local EscortMission=SpawnMissionGroup(EscortPrefix)
local CarrierMission=SpawnMissionGroup(CarrierGroup:getName())
if EscortMission~=nil and CarrierMission~=nil then
EscortCount=EscortCount+1
EscortMissionName=string.format(EscortPrefix..'#Escort %s',CarrierName)
EscortMission.name=EscortMissionName
EscortMission.groupId=nil
EscortMission.lateActivation=false
EscortMission.taskSelected=false
local EscortUnits=#EscortMission.units
for u=1,EscortUnits do
EscortMission.units[u].name=string.format(EscortPrefix..'#Escort %s %02d',CarrierName,u)
EscortMission.units[u].unitId=nil
end
EscortMission.route.points[1].task={id="ComboTask",
params=
{
tasks=
{
[1]=
{
enabled=true,
auto=false,
id="Escort",
number=1,
params=
{
lastWptIndexFlagChangedManually=false,
groupId=CarrierGroup:getID(),
lastWptIndex=nil,
lastWptIndexFlag=false,
engagementDistMax=EscortEngagementDistanceMax,
targetTypes=EscortTargetTypes,
pos=
{
y=20,
x=20,
z=0,
}
}
}
}
}
}
SpawnGroupAdd(EscortPrefix,EscortMission)
end
end
function SendMessageToCarrier(CarrierGroup,CarrierMessage)
if CarrierGroup~=nil then
MessageToGroup(CarrierGroup,CarrierMessage,30,'Carrier/'..CarrierGroup:getName())
end
end
function MessageToGroup(MsgGroup,MsgText,MsgTime,MsgName)
if type(MsgGroup)=='string'then
MsgGroup=Group.getByName(MsgGroup)
end
if MsgGroup~=nil then
local MsgTable={}
MsgTable.text=MsgText
MsgTable.displayTime=MsgTime
MsgTable.msgFor={units={MsgGroup:getUnits()[1]:getName()}}
MsgTable.name=MsgName
end
end
function MessageToUnit(UnitName,MsgText,MsgTime,MsgName)
if UnitName~=nil then
local MsgTable={}
MsgTable.text=MsgText
MsgTable.displayTime=MsgTime
MsgTable.msgFor={units={UnitName}}
MsgTable.name=MsgName
end
end
function MessageToAll(MsgText,MsgTime,MsgName)
MESSAGE:New(MsgText,MsgTime,"Message"):ToCoalition(coalition.side.RED):ToCoalition(coalition.side.BLUE)
end
function MessageToRed(MsgText,MsgTime,MsgName)
MESSAGE:New(MsgText,MsgTime,"To Red Coalition"):ToCoalition(coalition.side.RED)
end
function MessageToBlue(MsgText,MsgTime,MsgName)
MESSAGE:New(MsgText,MsgTime,"To Blue Coalition"):ToCoalition(coalition.side.RED)
end
function getCarrierHeight(CarrierGroup)
if CarrierGroup~=nil then
if table.getn(CarrierGroup:getUnits())==1 then
local CarrierUnit=CarrierGroup:getUnits()[1]
local CurrentPoint=CarrierUnit:getPoint()
local CurrentPosition={x=CurrentPoint.x,y=CurrentPoint.z}
local CarrierHeight=CurrentPoint.y
local LandHeight=land.getHeight(CurrentPosition)
return CarrierHeight-LandHeight
else
return 999999
end
else
return 999999
end
end
function GetUnitHeight(CheckUnit)
local UnitPoint=CheckUnit:getPoint()
local UnitPosition={x=CurrentPoint.x,y=CurrentPoint.z}
local UnitHeight=CurrentPoint.y
local LandHeight=land.getHeight(CurrentPosition)
return UnitHeight-LandHeight
end
_MusicTable={}
_MusicTable.Files={}
_MusicTable.Queue={}
_MusicTable.FileCnt=0
function MusicRegister(SndRef,SndFile,SndTime)
env.info(('MusicRegister: SndRef = '..SndRef))
env.info(('MusicRegister: SndFile = '..SndFile))
env.info(('MusicRegister: SndTime = '..SndTime))
_MusicTable.FileCnt=_MusicTable.FileCnt+1
_MusicTable.Files[_MusicTable.FileCnt]={}
_MusicTable.Files[_MusicTable.FileCnt].Ref=SndRef
_MusicTable.Files[_MusicTable.FileCnt].File=SndFile
_MusicTable.Files[_MusicTable.FileCnt].Time=SndTime
if not _MusicTable.Function then
_MusicTable.Function=routines.scheduleFunction(MusicScheduler,{},timer.getTime()+10,10)
end
end
function MusicToPlayer(SndRef,PlayerName,SndContinue)
local PlayerUnits=AlivePlayerUnits()
for PlayerUnitIdx,PlayerUnit in pairs(PlayerUnits)do
local PlayerUnitName=PlayerUnit:getPlayerName()
if PlayerName==PlayerUnitName then
PlayerGroup=PlayerUnit:getGroup()
if PlayerGroup then
MusicToGroup(SndRef,PlayerGroup,SndContinue)
end
break
end
end
end
function MusicToGroup(SndRef,SndGroup,SndContinue)
if SndGroup~=nil then
if _MusicTable and _MusicTable.FileCnt>0 then
if SndGroup:isExist()then
if MusicCanStart(SndGroup:getUnit(1):getPlayerName())then
local SndIdx=0
if SndRef==''then
SndIdx=math.random(1,_MusicTable.FileCnt)
else
for SndIdx=1,_MusicTable.FileCnt do
if _MusicTable.Files[SndIdx].Ref==SndRef then
break
end
end
end
trigger.action.outSoundForGroup(SndGroup:getID(),_MusicTable.Files[SndIdx].File)
MessageToGroup(SndGroup,'Playing '.._MusicTable.Files[SndIdx].File,15,'Music-'..SndGroup:getUnit(1):getPlayerName())
local SndQueueRef=SndGroup:getUnit(1):getPlayerName()
if _MusicTable.Queue[SndQueueRef]==nil then
_MusicTable.Queue[SndQueueRef]={}
end
_MusicTable.Queue[SndQueueRef].Start=timer.getTime()
_MusicTable.Queue[SndQueueRef].PlayerName=SndGroup:getUnit(1):getPlayerName()
_MusicTable.Queue[SndQueueRef].Group=SndGroup
_MusicTable.Queue[SndQueueRef].ID=SndGroup:getID()
_MusicTable.Queue[SndQueueRef].Ref=SndIdx
_MusicTable.Queue[SndQueueRef].Continue=SndContinue
_MusicTable.Queue[SndQueueRef].Type=Group
end
end
end
end
end
function MusicCanStart(PlayerName)
local MusicOut=false
if _MusicTable['Queue']~=nil and _MusicTable.FileCnt>0 then
local PlayerFound=false
local MusicStart=0
local MusicTime=0
for SndQueueIdx,SndQueue in pairs(_MusicTable.Queue)do
if SndQueue.PlayerName==PlayerName then
PlayerFound=true
MusicStart=SndQueue.Start
MusicTime=_MusicTable.Files[SndQueue.Ref].Time
break
end
end
if PlayerFound then
if MusicStart+MusicTime<=timer.getTime()then
MusicOut=true
end
else
MusicOut=true
end
end
if MusicOut then
else
end
return MusicOut
end
function MusicScheduler()
if _MusicTable['Queue']~=nil and _MusicTable.FileCnt>0 then
for SndQueueIdx,SndQueue in pairs(_MusicTable.Queue)do
if SndQueue.Continue then
if MusicCanStart(SndQueue.PlayerName)then
MusicToPlayer('',SndQueue.PlayerName,true)
end
end
end
end
end
env.info(('Init: Scripts Loaded v1.1'))
SMOKECOLOR=trigger.smokeColor
FLARECOLOR=trigger.flareColor
UTILS={
_MarkID=1
}
UTILS.IsInstanceOf=function(object,className)
if not type(className)=='string'then
if type(className)=='table'and className.IsInstanceOf~=nil then
className=className.ClassName
else
local err_str='className parameter should be a string; parameter received: '..type(className)
self:E(err_str)
return false
end
end
if type(object)=='table'and object.IsInstanceOf~=nil then
return object:IsInstanceOf(className)
else
local basicDataTypes={'string','number','function','boolean','nil','table'}
for _,basicDataType in ipairs(basicDataTypes)do
if className==basicDataType then
return type(object)==basicDataType
end
end
end
return false
end
UTILS.DeepCopy=function(object)
local lookup_table={}
local function _copy(object)
if type(object)~="table"then
return object
elseif lookup_table[object]then
return lookup_table[object]
end
local new_table={}
lookup_table[object]=new_table
for index,value in pairs(object)do
new_table[_copy(index)]=_copy(value)
end
return setmetatable(new_table,getmetatable(object))
end
local objectreturn=_copy(object)
return objectreturn
end
UTILS.OneLineSerialize=function(tbl)
lookup_table={}
local function _Serialize(tbl)
if type(tbl)=='table'then
if lookup_table[tbl]then
return lookup_table[object]
end
local tbl_str={}
lookup_table[tbl]=tbl_str
tbl_str[#tbl_str+1]='{'
for ind,val in pairs(tbl)do
local ind_str={}
if type(ind)=="number"then
ind_str[#ind_str+1]='['
ind_str[#ind_str+1]=tostring(ind)
ind_str[#ind_str+1]=']='
else
ind_str[#ind_str+1]='['
ind_str[#ind_str+1]=routines.utils.basicSerialize(ind)
ind_str[#ind_str+1]=']='
end
local val_str={}
if((type(val)=='number')or(type(val)=='boolean'))then
val_str[#val_str+1]=tostring(val)
val_str[#val_str+1]=','
tbl_str[#tbl_str+1]=table.concat(ind_str)
tbl_str[#tbl_str+1]=table.concat(val_str)
elseif type(val)=='string'then
val_str[#val_str+1]=routines.utils.basicSerialize(val)
val_str[#val_str+1]=','
tbl_str[#tbl_str+1]=table.concat(ind_str)
tbl_str[#tbl_str+1]=table.concat(val_str)
elseif type(val)=='nil'then
val_str[#val_str+1]='nil,'
tbl_str[#tbl_str+1]=table.concat(ind_str)
tbl_str[#tbl_str+1]=table.concat(val_str)
elseif type(val)=='table'then
if ind=="__index"then
else
val_str[#val_str+1]=_Serialize(val)
val_str[#val_str+1]=','
tbl_str[#tbl_str+1]=table.concat(ind_str)
tbl_str[#tbl_str+1]=table.concat(val_str)
end
elseif type(val)=='function'then
tbl_str[#tbl_str+1]="f() "..tostring(ind)
tbl_str[#tbl_str+1]=','
else
env.info('unable to serialize value type '..routines.utils.basicSerialize(type(val))..' at index '..tostring(ind))
env.info(debug.traceback())
end
end
tbl_str[#tbl_str+1]='}'
return table.concat(tbl_str)
else
return tostring(tbl)
end
end
local objectreturn=_Serialize(tbl)
return objectreturn
end
UTILS.BasicSerialize=function(s)
if s==nil then
return"\"\""
else
if((type(s)=='number')or(type(s)=='boolean')or(type(s)=='function')or(type(s)=='table')or(type(s)=='userdata'))then
return tostring(s)
elseif type(s)=='string'then
s=string.format('%q',s)
return s
end
end
end
UTILS.ToDegree=function(angle)
return angle*180/math.pi
end
UTILS.ToRadian=function(angle)
return angle*math.pi/180
end
UTILS.MetersToNM=function(meters)
return meters/1852
end
UTILS.MetersToFeet=function(meters)
return meters/0.3048
end
UTILS.NMToMeters=function(NM)
return NM*1852
end
UTILS.FeetToMeters=function(feet)
return feet*0.3048
end
UTILS.MpsToKnots=function(mps)
return mps*3600/1852
end
UTILS.MpsToKmph=function(mps)
return mps*3.6
end
UTILS.KnotsToMps=function(knots)
return knots*1852/3600
end
UTILS.KnotsToKmph=function(knots)
return knots*1.852
end
UTILS.KmphToMps=function(kmph)
return kmph/3.6
end
UTILS.tostringLL=function(lat,lon,acc,DMS)
local latHemi,lonHemi
if lat>0 then
latHemi='N'
else
latHemi='S'
end
if lon>0 then
lonHemi='E'
else
lonHemi='W'
end
lat=math.abs(lat)
lon=math.abs(lon)
local latDeg=math.floor(lat)
local latMin=(lat-latDeg)*60
local lonDeg=math.floor(lon)
local lonMin=(lon-lonDeg)*60
if DMS then
local oldLatMin=latMin
latMin=math.floor(latMin)
local latSec=UTILS.Round((oldLatMin-latMin)*60,acc)
local oldLonMin=lonMin
lonMin=math.floor(lonMin)
local lonSec=UTILS.Round((oldLonMin-lonMin)*60,acc)
if latSec==60 then
latSec=0
latMin=latMin+1
end
if lonSec==60 then
lonSec=0
lonMin=lonMin+1
end
local secFrmtStr
secFrmtStr='%02d'
return string.format('%02d',latDeg)..' '..string.format('%02d',latMin)..'\' '..string.format(secFrmtStr,latSec)..'"'..latHemi..'   '
..string.format('%02d',lonDeg)..' '..string.format('%02d',lonMin)..'\' '..string.format(secFrmtStr,lonSec)..'"'..lonHemi
else
latMin=UTILS.Round(latMin,acc)
lonMin=UTILS.Round(lonMin,acc)
if latMin==60 then
latMin=0
latDeg=latDeg+1
end
if lonMin==60 then
lonMin=0
lonDeg=lonDeg+1
end
local minFrmtStr
if acc<=0 then
minFrmtStr='%02d'
else
local width=3+acc
minFrmtStr='%0'..width..'.'..acc..'f'
end
return string.format('%02d',latDeg)..' '..string.format(minFrmtStr,latMin)..'\''..latHemi..'   '
..string.format('%02d',lonDeg)..' '..string.format(minFrmtStr,lonMin)..'\''..lonHemi
end
end
UTILS.tostringMGRS=function(MGRS,acc)
if acc==0 then
return MGRS.UTMZone..' '..MGRS.MGRSDigraph
else
return MGRS.UTMZone..' '..MGRS.MGRSDigraph..' '..string.format('%0'..acc..'d',UTILS.Round(MGRS.Easting/(10^(5-acc)),0))
..' '..string.format('%0'..acc..'d',UTILS.Round(MGRS.Northing/(10^(5-acc)),0))
end
end
function UTILS.Round(num,idp)
local mult=10^(idp or 0)
return math.floor(num*mult+0.5)/mult
end
function UTILS.DoString(s)
local f,err=loadstring(s)
if f then
return true,f()
else
return false,err
end
end
function UTILS.spairs(t,order)
local keys={}
for k in pairs(t)do keys[#keys+1]=k end
if order then
table.sort(keys,function(a,b)return order(t,a,b)end)
else
table.sort(keys)
end
local i=0
return function()
i=i+1
if keys[i]then
return keys[i],t[keys[i]]
end
end
end
function UTILS.GetMarkID()
UTILS._MarkID=UTILS._MarkID+1
return UTILS._MarkID
end
function UTILS.IsInRadius(InVec2,Vec2,Radius)
local InRadius=((InVec2.x-Vec2.x)^2+(InVec2.y-Vec2.y)^2)^0.5<=Radius
return InRadius
end
function UTILS.IsInSphere(InVec3,Vec3,Radius)
local InSphere=((InVec3.x-Vec3.x)^2+(InVec3.y-Vec3.y)^2+(InVec3.z-Vec3.z)^2)^0.5<=Radius
return InSphere
end
local _TraceOnOff=true
local _TraceLevel=1
local _TraceAll=false
local _TraceClass={}
local _TraceClassMethod={}
local _ClassID=0
BASE={
ClassName="BASE",
ClassID=0,
Events={},
States={},
}
BASE.__={}
BASE._={
Schedules={}
}
FORMATION={
Cone="Cone",
Vee="Vee"
}
function BASE:New()
local self=routines.utils.deepCopy(self)
_ClassID=_ClassID+1
self.ClassID=_ClassID
return self
end
function BASE:Inherit(Child,Parent)
local Child=routines.utils.deepCopy(Child)
if Child~=nil then
if rawget(Child,"__")then
setmetatable(Child,{__index=Child.__})
setmetatable(Child.__,{__index=Parent})
else
setmetatable(Child,{__index=Parent})
end
end
return Child
end
function BASE:GetParent(Child)
local Parent
if Child.ClassName=='BASE'then
Parent=nil
elseif rawget(Child,"__")then
Parent=getmetatable(Child.__).__index
else
Parent=getmetatable(Child).__index
end
return Parent
end
function BASE:IsInstanceOf(ClassName)
if type(ClassName)~='string'then
if type(ClassName)=='table'and ClassName.ClassName~=nil then
ClassName=ClassName.ClassName
else
local err_str='className parameter should be a string; parameter received: '..type(ClassName)
self:E(err_str)
return false
end
end
ClassName=string.upper(ClassName)
if string.upper(self.ClassName)==ClassName then
return true
end
local Parent=self:GetParent(self)
while Parent do
if string.upper(Parent.ClassName)==ClassName then
return true
end
Parent=Parent:GetParent(Parent)
end
return false
end
function BASE:GetClassNameAndID()
return string.format('%s#%09d',self.ClassName,self.ClassID)
end
function BASE:GetClassName()
return self.ClassName
end
function BASE:GetClassID()
return self.ClassID
end
do
function BASE:EventDispatcher()
return _EVENTDISPATCHER
end
function BASE:GetEventPriority()
return self._.EventPriority or 5
end
function BASE:SetEventPriority(EventPriority)
self._.EventPriority=EventPriority
end
function BASE:EventRemoveAll()
self:EventDispatcher():RemoveAll(self)
return self
end
function BASE:HandleEvent(Event,EventFunction)
self:EventDispatcher():OnEventGeneric(EventFunction,self,Event)
return self
end
function BASE:UnHandleEvent(Event)
self:EventDispatcher():RemoveEvent(self,Event)
return self
end
end
function BASE:CreateEventBirth(EventTime,Initiator,IniUnitName,place,subplace)
self:F({EventTime,Initiator,IniUnitName,place,subplace})
local Event={
id=world.event.S_EVENT_BIRTH,
time=EventTime,
initiator=Initiator,
IniUnitName=IniUnitName,
place=place,
subplace=subplace
}
world.onEvent(Event)
end
function BASE:CreateEventCrash(EventTime,Initiator)
self:F({EventTime,Initiator})
local Event={
id=world.event.S_EVENT_CRASH,
time=EventTime,
initiator=Initiator,
}
world.onEvent(Event)
end
function BASE:CreateEventTakeoff(EventTime,Initiator)
self:F({EventTime,Initiator})
local Event={
id=world.event.S_EVENT_TAKEOFF,
time=EventTime,
initiator=Initiator,
}
world.onEvent(Event)
end
function BASE:onEvent(event)
if self then
for EventID,EventObject in pairs(self.Events)do
if EventObject.EventEnabled then
if event.id==EventObject.Event then
if self==EventObject.Self then
if event.initiator and event.initiator:isExist()then
event.IniUnitName=event.initiator:getName()
end
if event.target and event.target:isExist()then
event.TgtUnitName=event.target:getName()
end
end
end
end
end
end
end
do
function BASE:ScheduleOnce(Start,SchedulerFunction,...)
self:F2({Start})
self:T3({...})
local ObjectName="-"
ObjectName=self.ClassName..self.ClassID
self:F3({"ScheduleOnce: ",ObjectName,Start})
self.SchedulerObject=self
local ScheduleID=_SCHEDULEDISPATCHER:AddSchedule(
self,
SchedulerFunction,
{...},
Start,
nil,
nil,
nil
)
self._.Schedules[#self.Schedules+1]=ScheduleID
return self._.Schedules
end
function BASE:ScheduleRepeat(Start,Repeat,RandomizeFactor,Stop,SchedulerFunction,...)
self:F2({Start})
self:T3({...})
local ObjectName="-"
ObjectName=self.ClassName..self.ClassID
self:F3({"ScheduleRepeat: ",ObjectName,Start,Repeat,RandomizeFactor,Stop})
self.SchedulerObject=self
local ScheduleID=_SCHEDULEDISPATCHER:AddSchedule(
self,
SchedulerFunction,
{...},
Start,
Repeat,
RandomizeFactor,
Stop
)
self._.Schedules[SchedulerFunction]=ScheduleID
return self._.Schedules
end
function BASE:ScheduleStop(SchedulerFunction)
self:F3({"ScheduleStop:"})
_SCHEDULEDISPATCHER:Stop(self,self._.Schedules[SchedulerFunction])
end
end
function BASE:SetState(Object,Key,Value)
local ClassNameAndID=Object:GetClassNameAndID()
self.States[ClassNameAndID]=self.States[ClassNameAndID]or{}
self.States[ClassNameAndID][Key]=Value
return self.States[ClassNameAndID][Key]
end
function BASE:GetState(Object,Key)
local ClassNameAndID=Object:GetClassNameAndID()
if self.States[ClassNameAndID]then
local Value=self.States[ClassNameAndID][Key]or false
return Value
end
return nil
end
function BASE:ClearState(Object,StateName)
local ClassNameAndID=Object:GetClassNameAndID()
if self.States[ClassNameAndID]then
self.States[ClassNameAndID][StateName]=nil
end
end
function BASE:TraceOnOff(TraceOnOff)
_TraceOnOff=TraceOnOff
end
function BASE:IsTrace()
if debug and(_TraceAll==true)or(_TraceClass[self.ClassName]or _TraceClassMethod[self.ClassName])then
return true
else
return false
end
end
function BASE:TraceLevel(Level)
_TraceLevel=Level
self:E("Tracing level "..Level)
end
function BASE:TraceAll(TraceAll)
_TraceAll=TraceAll
if _TraceAll then
self:E("Tracing all methods in MOOSE ")
else
self:E("Switched off tracing all methods in MOOSE")
end
end
function BASE:TraceClass(Class)
_TraceClass[Class]=true
_TraceClassMethod[Class]={}
self:E("Tracing class "..Class)
end
function BASE:TraceClassMethod(Class,Method)
if not _TraceClassMethod[Class]then
_TraceClassMethod[Class]={}
_TraceClassMethod[Class].Method={}
end
_TraceClassMethod[Class].Method[Method]=true
self:E("Tracing method "..Method.." of class "..Class)
end
function BASE:_F(Arguments,DebugInfoCurrentParam,DebugInfoFromParam)
if debug and(_TraceAll==true)or(_TraceClass[self.ClassName]or _TraceClassMethod[self.ClassName])then
local DebugInfoCurrent=DebugInfoCurrentParam and DebugInfoCurrentParam or debug.getinfo(2,"nl")
local DebugInfoFrom=DebugInfoFromParam and DebugInfoFromParam or debug.getinfo(3,"l")
local Function="function"
if DebugInfoCurrent.name then
Function=DebugInfoCurrent.name
end
if _TraceAll==true or _TraceClass[self.ClassName]or _TraceClassMethod[self.ClassName].Method[Function]then
local LineCurrent=0
if DebugInfoCurrent.currentline then
LineCurrent=DebugInfoCurrent.currentline
end
local LineFrom=0
if DebugInfoFrom then
LineFrom=DebugInfoFrom.currentline
end
env.info(string.format("%6d(%6d)/%1s:%20s%05d.%s(%s)",LineCurrent,LineFrom,"F",self.ClassName,self.ClassID,Function,routines.utils.oneLineSerialize(Arguments)))
end
end
end
function BASE:F(Arguments)
if debug and _TraceOnOff then
local DebugInfoCurrent=debug.getinfo(2,"nl")
local DebugInfoFrom=debug.getinfo(3,"l")
if _TraceLevel>=1 then
self:_F(Arguments,DebugInfoCurrent,DebugInfoFrom)
end
end
end
function BASE:F2(Arguments)
if debug and _TraceOnOff then
local DebugInfoCurrent=debug.getinfo(2,"nl")
local DebugInfoFrom=debug.getinfo(3,"l")
if _TraceLevel>=2 then
self:_F(Arguments,DebugInfoCurrent,DebugInfoFrom)
end
end
end
function BASE:F3(Arguments)
if debug and _TraceOnOff then
local DebugInfoCurrent=debug.getinfo(2,"nl")
local DebugInfoFrom=debug.getinfo(3,"l")
if _TraceLevel>=3 then
self:_F(Arguments,DebugInfoCurrent,DebugInfoFrom)
end
end
end
function BASE:_T(Arguments,DebugInfoCurrentParam,DebugInfoFromParam)
if debug and(_TraceAll==true)or(_TraceClass[self.ClassName]or _TraceClassMethod[self.ClassName])then
local DebugInfoCurrent=DebugInfoCurrentParam and DebugInfoCurrentParam or debug.getinfo(2,"nl")
local DebugInfoFrom=DebugInfoFromParam and DebugInfoFromParam or debug.getinfo(3,"l")
local Function="function"
if DebugInfoCurrent.name then
Function=DebugInfoCurrent.name
end
if _TraceAll==true or _TraceClass[self.ClassName]or _TraceClassMethod[self.ClassName].Method[Function]then
local LineCurrent=0
if DebugInfoCurrent.currentline then
LineCurrent=DebugInfoCurrent.currentline
end
local LineFrom=0
if DebugInfoFrom then
LineFrom=DebugInfoFrom.currentline
end
env.info(string.format("%6d(%6d)/%1s:%20s%05d.%s",LineCurrent,LineFrom,"T",self.ClassName,self.ClassID,routines.utils.oneLineSerialize(Arguments)))
end
end
end
function BASE:T(Arguments)
if debug and _TraceOnOff then
local DebugInfoCurrent=debug.getinfo(2,"nl")
local DebugInfoFrom=debug.getinfo(3,"l")
if _TraceLevel>=1 then
self:_T(Arguments,DebugInfoCurrent,DebugInfoFrom)
end
end
end
function BASE:T2(Arguments)
if debug and _TraceOnOff then
local DebugInfoCurrent=debug.getinfo(2,"nl")
local DebugInfoFrom=debug.getinfo(3,"l")
if _TraceLevel>=2 then
self:_T(Arguments,DebugInfoCurrent,DebugInfoFrom)
end
end
end
function BASE:T3(Arguments)
if debug and _TraceOnOff then
local DebugInfoCurrent=debug.getinfo(2,"nl")
local DebugInfoFrom=debug.getinfo(3,"l")
if _TraceLevel>=3 then
self:_T(Arguments,DebugInfoCurrent,DebugInfoFrom)
end
end
end
function BASE:E(Arguments)
if debug then
local DebugInfoCurrent=debug.getinfo(2,"nl")
local DebugInfoFrom=debug.getinfo(3,"l")
local Function="function"
if DebugInfoCurrent.name then
Function=DebugInfoCurrent.name
end
local LineCurrent=DebugInfoCurrent.currentline
local LineFrom=-1
if DebugInfoFrom then
LineFrom=DebugInfoFrom.currentline
end
env.info(string.format("%6d(%6d)/%1s:%20s%05d.%s(%s)",LineCurrent,LineFrom,"E",self.ClassName,self.ClassID,Function,routines.utils.oneLineSerialize(Arguments)))
end
end
REPORT={
ClassName="REPORT",
Title="",
}
function REPORT:New(Title)
local self=BASE:Inherit(self,BASE:New())
self.Report={}
self:SetTitle(Title or"")
self:SetIndent(3)
return self
end
function REPORT:HasText()
return#self.Report>0
end
function REPORT:SetIndent(Indent)
self.Indent=Indent
return self
end
function REPORT:Add(Text)
self.Report[#self.Report+1]=Text
return self
end
function REPORT:AddIndent(Text)
self.Report[#self.Report+1]=string.rep(" ",self.Indent)..Text:gsub("\n","\n"..string.rep(" ",self.Indent))
return self
end
function REPORT:Text(Delimiter)
Delimiter=Delimiter or"\n"
local ReportText=(self.Title~=""and self.Title..Delimiter or self.Title)..table.concat(self.Report,Delimiter)or""
return ReportText
end
function REPORT:SetTitle(Title)
self.Title=Title
return self
end
function REPORT:GetCount()
return#self.Report
end
SCHEDULER={
ClassName="SCHEDULER",
Schedules={},
}
function SCHEDULER:New(SchedulerObject,SchedulerFunction,SchedulerArguments,Start,Repeat,RandomizeFactor,Stop)
local self=BASE:Inherit(self,BASE:New())
self:F2({Start,Repeat,RandomizeFactor,Stop})
local ScheduleID=nil
self.MasterObject=SchedulerObject
if SchedulerFunction then
ScheduleID=self:Schedule(SchedulerObject,SchedulerFunction,SchedulerArguments,Start,Repeat,RandomizeFactor,Stop)
end
return self,ScheduleID
end
function SCHEDULER:Schedule(SchedulerObject,SchedulerFunction,SchedulerArguments,Start,Repeat,RandomizeFactor,Stop)
self:F2({Start,Repeat,RandomizeFactor,Stop})
self:T3({SchedulerArguments})
local ObjectName="-"
if SchedulerObject and SchedulerObject.ClassName and SchedulerObject.ClassID then
ObjectName=SchedulerObject.ClassName..SchedulerObject.ClassID
end
self:F3({"Schedule :",ObjectName,tostring(SchedulerObject),Start,Repeat,RandomizeFactor,Stop})
self.SchedulerObject=SchedulerObject
local ScheduleID=_SCHEDULEDISPATCHER:AddSchedule(
self,
SchedulerFunction,
SchedulerArguments,
Start,
Repeat,
RandomizeFactor,
Stop
)
self.Schedules[#self.Schedules+1]=ScheduleID
return ScheduleID
end
function SCHEDULER:Start(ScheduleID)
self:F3({ScheduleID})
_SCHEDULEDISPATCHER:Start(self,ScheduleID)
end
function SCHEDULER:Stop(ScheduleID)
self:F3({ScheduleID})
_SCHEDULEDISPATCHER:Stop(self,ScheduleID)
end
function SCHEDULER:Remove(ScheduleID)
self:F3({ScheduleID})
_SCHEDULEDISPATCHER:Remove(self,ScheduleID)
end
function SCHEDULER:Clear()
self:F3()
_SCHEDULEDISPATCHER:Clear(self)
end
SCHEDULEDISPATCHER={
ClassName="SCHEDULEDISPATCHER",
CallID=0,
}
function SCHEDULEDISPATCHER:New()
local self=BASE:Inherit(self,BASE:New())
self:F3()
return self
end
function SCHEDULEDISPATCHER:AddSchedule(Scheduler,ScheduleFunction,ScheduleArguments,Start,Repeat,Randomize,Stop)
self:F2({Scheduler,ScheduleFunction,ScheduleArguments,Start,Repeat,Randomize,Stop})
self.CallID=self.CallID+1
local CallID=self.CallID.."#"..(Scheduler.MasterObject and Scheduler.MasterObject.GetClassNameAndID and Scheduler.MasterObject:GetClassNameAndID()or"")or""
self.PersistentSchedulers=self.PersistentSchedulers or{}
self.ObjectSchedulers=self.ObjectSchedulers or setmetatable({},{__mode="v"})
if Scheduler.MasterObject then
self.ObjectSchedulers[CallID]=Scheduler
self:F3({CallID=CallID,ObjectScheduler=tostring(self.ObjectSchedulers[CallID]),MasterObject=tostring(Scheduler.MasterObject)})
else
self.PersistentSchedulers[CallID]=Scheduler
self:F3({CallID=CallID,PersistentScheduler=self.PersistentSchedulers[CallID]})
end
self.Schedule=self.Schedule or setmetatable({},{__mode="k"})
self.Schedule[Scheduler]=self.Schedule[Scheduler]or{}
self.Schedule[Scheduler][CallID]={}
self.Schedule[Scheduler][CallID].Function=ScheduleFunction
self.Schedule[Scheduler][CallID].Arguments=ScheduleArguments
self.Schedule[Scheduler][CallID].StartTime=timer.getTime()+(Start or 0)
self.Schedule[Scheduler][CallID].Start=Start+.1
self.Schedule[Scheduler][CallID].Repeat=Repeat or 0
self.Schedule[Scheduler][CallID].Randomize=Randomize or 0
self.Schedule[Scheduler][CallID].Stop=Stop
self:T3(self.Schedule[Scheduler][CallID])
self.Schedule[Scheduler][CallID].CallHandler=function(CallID)
self:F2(CallID)
local ErrorHandler=function(errmsg)
env.info("Error in timer function: "..errmsg)
if debug~=nil then
env.info(debug.traceback())
end
return errmsg
end
local Scheduler=self.ObjectSchedulers[CallID]
if not Scheduler then
Scheduler=self.PersistentSchedulers[CallID]
end
if Scheduler then
local MasterObject=tostring(Scheduler.MasterObject)
local Schedule=self.Schedule[Scheduler][CallID]
local ScheduleObject=Scheduler.SchedulerObject
local ScheduleFunction=Schedule.Function
local ScheduleArguments=Schedule.Arguments
local Start=Schedule.Start
local Repeat=Schedule.Repeat or 0
local Randomize=Schedule.Randomize or 0
local Stop=Schedule.Stop or 0
local ScheduleID=Schedule.ScheduleID
local Status,Result
if ScheduleObject then
local function Timer()
return ScheduleFunction(ScheduleObject,unpack(ScheduleArguments))
end
Status,Result=xpcall(Timer,ErrorHandler)
else
local function Timer()
return ScheduleFunction(unpack(ScheduleArguments))
end
Status,Result=xpcall(Timer,ErrorHandler)
end
local CurrentTime=timer.getTime()
local StartTime=Schedule.StartTime
self:F3({Master=MasterObject,CurrentTime=CurrentTime,StartTime=StartTime,Start=Start,Repeat=Repeat,Randomize=Randomize,Stop=Stop})
if Status and((Result==nil)or(Result and Result~=false))then
if Repeat~=0 and((Stop==0)or(Stop~=0 and CurrentTime<=StartTime+Stop))then
local ScheduleTime=
CurrentTime+
Repeat+
math.random(
-(Randomize*Repeat/2),
(Randomize*Repeat/2)
)+
0.01
return ScheduleTime
else
self:Stop(Scheduler,CallID)
end
else
self:Stop(Scheduler,CallID)
end
else
self:E("Scheduled obsolete call for CallID: "..CallID)
end
return nil
end
self:Start(Scheduler,CallID)
return CallID
end
function SCHEDULEDISPATCHER:RemoveSchedule(Scheduler,CallID)
self:F2({Remove=CallID,Scheduler=Scheduler})
if CallID then
self:Stop(Scheduler,CallID)
self.Schedule[Scheduler][CallID]=nil
end
end
function SCHEDULEDISPATCHER:Start(Scheduler,CallID)
self:F2({Start=CallID,Scheduler=Scheduler})
if CallID then
local Schedule=self.Schedule[Scheduler]
if not Schedule[CallID].ScheduleID then
Schedule[CallID].StartTime=timer.getTime()
Schedule[CallID].ScheduleID=timer.scheduleFunction(
Schedule[CallID].CallHandler,
CallID,
timer.getTime()+Schedule[CallID].Start
)
end
else
for CallID,Schedule in pairs(self.Schedule[Scheduler]or{})do
self:Start(Scheduler,CallID)
end
end
end
function SCHEDULEDISPATCHER:Stop(Scheduler,CallID)
self:F2({Stop=CallID,Scheduler=Scheduler})
if CallID then
local Schedule=self.Schedule[Scheduler]
if Schedule[CallID].ScheduleID then
timer.removeFunction(Schedule[CallID].ScheduleID)
Schedule[CallID].ScheduleID=nil
end
else
for CallID,Schedule in pairs(self.Schedule[Scheduler]or{})do
self:Stop(Scheduler,CallID)
end
end
end
function SCHEDULEDISPATCHER:Clear(Scheduler)
self:F2({Scheduler=Scheduler})
for CallID,Schedule in pairs(self.Schedule[Scheduler]or{})do
self:Stop(Scheduler,CallID)
end
end
EVENT={
ClassName="EVENT",
ClassID=0,
}
world.event.S_EVENT_NEW_CARGO=world.event.S_EVENT_MAX+1000
world.event.S_EVENT_DELETE_CARGO=world.event.S_EVENT_MAX+1001
EVENTS={
Shot=world.event.S_EVENT_SHOT,
Hit=world.event.S_EVENT_HIT,
Takeoff=world.event.S_EVENT_TAKEOFF,
Land=world.event.S_EVENT_LAND,
Crash=world.event.S_EVENT_CRASH,
Ejection=world.event.S_EVENT_EJECTION,
Refueling=world.event.S_EVENT_REFUELING,
Dead=world.event.S_EVENT_DEAD,
PilotDead=world.event.S_EVENT_PILOT_DEAD,
BaseCaptured=world.event.S_EVENT_BASE_CAPTURED,
MissionStart=world.event.S_EVENT_MISSION_START,
MissionEnd=world.event.S_EVENT_MISSION_END,
TookControl=world.event.S_EVENT_TOOK_CONTROL,
RefuelingStop=world.event.S_EVENT_REFUELING_STOP,
Birth=world.event.S_EVENT_BIRTH,
HumanFailure=world.event.S_EVENT_HUMAN_FAILURE,
EngineStartup=world.event.S_EVENT_ENGINE_STARTUP,
EngineShutdown=world.event.S_EVENT_ENGINE_SHUTDOWN,
PlayerEnterUnit=world.event.S_EVENT_PLAYER_ENTER_UNIT,
PlayerLeaveUnit=world.event.S_EVENT_PLAYER_LEAVE_UNIT,
PlayerComment=world.event.S_EVENT_PLAYER_COMMENT,
ShootingStart=world.event.S_EVENT_SHOOTING_START,
ShootingEnd=world.event.S_EVENT_SHOOTING_END,
NewCargo=world.event.S_EVENT_NEW_CARGO,
DeleteCargo=world.event.S_EVENT_DELETE_CARGO,
}
local _EVENTMETA={
[world.event.S_EVENT_SHOT]={
Order=1,
Side="I",
Event="OnEventShot",
Text="S_EVENT_SHOT"
},
[world.event.S_EVENT_HIT]={
Order=1,
Side="T",
Event="OnEventHit",
Text="S_EVENT_HIT"
},
[world.event.S_EVENT_TAKEOFF]={
Order=1,
Side="I",
Event="OnEventTakeoff",
Text="S_EVENT_TAKEOFF"
},
[world.event.S_EVENT_LAND]={
Order=1,
Side="I",
Event="OnEventLand",
Text="S_EVENT_LAND"
},
[world.event.S_EVENT_CRASH]={
Order=-1,
Side="I",
Event="OnEventCrash",
Text="S_EVENT_CRASH"
},
[world.event.S_EVENT_EJECTION]={
Order=1,
Side="I",
Event="OnEventEjection",
Text="S_EVENT_EJECTION"
},
[world.event.S_EVENT_REFUELING]={
Order=1,
Side="I",
Event="OnEventRefueling",
Text="S_EVENT_REFUELING"
},
[world.event.S_EVENT_DEAD]={
Order=-1,
Side="I",
Event="OnEventDead",
Text="S_EVENT_DEAD"
},
[world.event.S_EVENT_PILOT_DEAD]={
Order=1,
Side="I",
Event="OnEventPilotDead",
Text="S_EVENT_PILOT_DEAD"
},
[world.event.S_EVENT_BASE_CAPTURED]={
Order=1,
Side="I",
Event="OnEventBaseCaptured",
Text="S_EVENT_BASE_CAPTURED"
},
[world.event.S_EVENT_MISSION_START]={
Order=1,
Side="N",
Event="OnEventMissionStart",
Text="S_EVENT_MISSION_START"
},
[world.event.S_EVENT_MISSION_END]={
Order=1,
Side="N",
Event="OnEventMissionEnd",
Text="S_EVENT_MISSION_END"
},
[world.event.S_EVENT_TOOK_CONTROL]={
Order=1,
Side="N",
Event="OnEventTookControl",
Text="S_EVENT_TOOK_CONTROL"
},
[world.event.S_EVENT_REFUELING_STOP]={
Order=1,
Side="I",
Event="OnEventRefuelingStop",
Text="S_EVENT_REFUELING_STOP"
},
[world.event.S_EVENT_BIRTH]={
Order=1,
Side="I",
Event="OnEventBirth",
Text="S_EVENT_BIRTH"
},
[world.event.S_EVENT_HUMAN_FAILURE]={
Order=1,
Side="I",
Event="OnEventHumanFailure",
Text="S_EVENT_HUMAN_FAILURE"
},
[world.event.S_EVENT_ENGINE_STARTUP]={
Order=1,
Side="I",
Event="OnEventEngineStartup",
Text="S_EVENT_ENGINE_STARTUP"
},
[world.event.S_EVENT_ENGINE_SHUTDOWN]={
Order=1,
Side="I",
Event="OnEventEngineShutdown",
Text="S_EVENT_ENGINE_SHUTDOWN"
},
[world.event.S_EVENT_PLAYER_ENTER_UNIT]={
Order=1,
Side="I",
Event="OnEventPlayerEnterUnit",
Text="S_EVENT_PLAYER_ENTER_UNIT"
},
[world.event.S_EVENT_PLAYER_LEAVE_UNIT]={
Order=-1,
Side="I",
Event="OnEventPlayerLeaveUnit",
Text="S_EVENT_PLAYER_LEAVE_UNIT"
},
[world.event.S_EVENT_PLAYER_COMMENT]={
Order=1,
Side="I",
Event="OnEventPlayerComment",
Text="S_EVENT_PLAYER_COMMENT"
},
[world.event.S_EVENT_SHOOTING_START]={
Order=1,
Side="I",
Event="OnEventShootingStart",
Text="S_EVENT_SHOOTING_START"
},
[world.event.S_EVENT_SHOOTING_END]={
Order=1,
Side="I",
Event="OnEventShootingEnd",
Text="S_EVENT_SHOOTING_END"
},
[EVENTS.NewCargo]={
Order=1,
Event="OnEventNewCargo",
Text="S_EVENT_NEW_CARGO"
},
[EVENTS.DeleteCargo]={
Order=1,
Event="OnEventDeleteCargo",
Text="S_EVENT_DELETE_CARGO"
},
}
function EVENT:New()
local self=BASE:Inherit(self,BASE:New())
self:F2()
self.EventHandler=world.addEventHandler(self)
return self
end
function EVENT:Init(EventID,EventClass)
self:F3({_EVENTMETA[EventID].Text,EventClass})
if not self.Events[EventID]then
self.Events[EventID]={}
end
local EventPriority=EventClass:GetEventPriority()
if not self.Events[EventID][EventPriority]then
self.Events[EventID][EventPriority]=setmetatable({},{__mode="k"})
end
if not self.Events[EventID][EventPriority][EventClass]then
self.Events[EventID][EventPriority][EventClass]={}
end
return self.Events[EventID][EventPriority][EventClass]
end
function EVENT:RemoveEvent(EventClass,EventID)
self:F2({"Removing subscription for class: ",EventClass:GetClassNameAndID()})
local EventPriority=EventClass:GetEventPriority()
self.Events=self.Events or{}
self.Events[EventID]=self.Events[EventID]or{}
self.Events[EventID][EventPriority]=self.Events[EventID][EventPriority]or{}
self.Events[EventID][EventPriority][EventClass]=self.Events[EventID][EventPriority][EventClass]
self.Events[EventID][EventPriority][EventClass]=nil
end
function EVENT:Reset(EventObject)
self:E({"Resetting subscriptions for class: ",EventObject:GetClassNameAndID()})
local EventPriority=EventObject:GetEventPriority()
for EventID,EventData in pairs(self.Events)do
if self.EventsDead then
if self.EventsDead[EventID]then
if self.EventsDead[EventID][EventPriority]then
if self.EventsDead[EventID][EventPriority][EventObject]then
self.Events[EventID][EventPriority][EventObject]=self.EventsDead[EventID][EventPriority][EventObject]
end
end
end
end
end
end
function EVENT:RemoveAll(EventObject)
self:F3({EventObject:GetClassNameAndID()})
local EventClass=EventObject:GetClassNameAndID()
local EventPriority=EventClass:GetEventPriority()
for EventID,EventData in pairs(self.Events)do
self.Events[EventID][EventPriority][EventClass]=nil
end
end
function EVENT:OnEventForTemplate(EventTemplate,EventFunction,EventClass,EventID)
self:F2(EventTemplate.name)
for EventUnitID,EventUnit in pairs(EventTemplate.units)do
self:OnEventForUnit(EventUnit.name,EventFunction,EventClass,EventID)
end
return self
end
function EVENT:OnEventGeneric(EventFunction,EventClass,EventID)
self:F2({EventID})
local EventData=self:Init(EventID,EventClass)
EventData.EventFunction=EventFunction
return self
end
function EVENT:OnEventForUnit(UnitName,EventFunction,EventClass,EventID)
self:F2(UnitName)
local EventData=self:Init(EventID,EventClass)
EventData.EventUnit=true
EventData.EventFunction=EventFunction
return self
end
function EVENT:OnEventForGroup(GroupName,EventFunction,EventClass,EventID,...)
self:E(GroupName)
local Event=self:Init(EventID,EventClass)
Event.EventGroup=true
Event.EventFunction=EventFunction
Event.Params=arg
return self
end
do
function EVENT:OnBirthForTemplate(EventTemplate,EventFunction,EventClass)
self:F2(EventTemplate.name)
self:OnEventForTemplate(EventTemplate,EventFunction,EventClass,EVENTS.Birth)
return self
end
end
do
function EVENT:OnCrashForTemplate(EventTemplate,EventFunction,EventClass)
self:F2(EventTemplate.name)
self:OnEventForTemplate(EventTemplate,EventFunction,EventClass,EVENTS.Crash)
return self
end
end
do
function EVENT:OnDeadForTemplate(EventTemplate,EventFunction,EventClass)
self:F2(EventTemplate.name)
self:OnEventForTemplate(EventTemplate,EventFunction,EventClass,EVENTS.Dead)
return self
end
end
do
function EVENT:OnLandForTemplate(EventTemplate,EventFunction,EventClass)
self:F2(EventTemplate.name)
self:OnEventForTemplate(EventTemplate,EventFunction,EventClass,EVENTS.Land)
return self
end
end
do
function EVENT:OnTakeOffForTemplate(EventTemplate,EventFunction,EventClass)
self:F2(EventTemplate.name)
self:OnEventForTemplate(EventTemplate,EventFunction,EventClass,EVENTS.Takeoff)
return self
end
end
do
function EVENT:OnEngineShutDownForTemplate(EventTemplate,EventFunction,EventClass)
self:F2(EventTemplate.name)
self:OnEventForTemplate(EventTemplate,EventFunction,EventClass,EVENTS.EngineShutdown)
return self
end
end
do
function EVENT:CreateEventNewCargo(Cargo)
self:F({Cargo})
local Event={
id=EVENTS.NewCargo,
time=timer.getTime(),
cargo=Cargo,
}
world.onEvent(Event)
end
function EVENT:CreateEventDeleteCargo(Cargo)
self:F({Cargo})
local Event={
id=EVENTS.DeleteCargo,
time=timer.getTime(),
cargo=Cargo,
}
world.onEvent(Event)
end
function EVENT:CreateEventPlayerEnterUnit(PlayerUnit)
self:F({PlayerUnit})
local Event={
id=EVENTS.PlayerEnterUnit,
time=timer.getTime(),
initiator=PlayerUnit:GetDCSObject()
}
world.onEvent(Event)
end
end
function EVENT:onEvent(Event)
local ErrorHandler=function(errmsg)
env.info("Error in SCHEDULER function:"..errmsg)
if debug~=nil then
env.info(debug.traceback())
end
return errmsg
end
local EventMeta=_EVENTMETA[Event.id]
if self and
self.Events and
self.Events[Event.id]and
(Event.initiator~=nil or(Event.initiator==nil and Event.id~=EVENTS.PlayerLeaveUnit))then
if Event.initiator then
Event.IniObjectCategory=Event.initiator:getCategory()
if Event.IniObjectCategory==Object.Category.UNIT then
Event.IniDCSUnit=Event.initiator
Event.IniDCSUnitName=Event.IniDCSUnit:getName()
Event.IniUnitName=Event.IniDCSUnitName
Event.IniDCSGroup=Event.IniDCSUnit:getGroup()
Event.IniUnit=UNIT:FindByName(Event.IniDCSUnitName)
if not Event.IniUnit then
Event.IniUnit=CLIENT:FindByName(Event.IniDCSUnitName,'',true)
end
Event.IniDCSGroupName=""
if Event.IniDCSGroup and Event.IniDCSGroup:isExist()then
Event.IniDCSGroupName=Event.IniDCSGroup:getName()
Event.IniGroup=GROUP:FindByName(Event.IniDCSGroupName)
if Event.IniGroup then
Event.IniGroupName=Event.IniDCSGroupName
end
end
Event.IniPlayerName=Event.IniDCSUnit:getPlayerName()
Event.IniCoalition=Event.IniDCSUnit:getCoalition()
Event.IniTypeName=Event.IniDCSUnit:getTypeName()
Event.IniCategory=Event.IniDCSUnit:getDesc().category
end
if Event.IniObjectCategory==Object.Category.STATIC then
Event.IniDCSUnit=Event.initiator
Event.IniDCSUnitName=Event.IniDCSUnit:getName()
Event.IniUnitName=Event.IniDCSUnitName
Event.IniUnit=STATIC:FindByName(Event.IniDCSUnitName,false)
Event.IniCoalition=Event.IniDCSUnit:getCoalition()
Event.IniCategory=Event.IniDCSUnit:getDesc().category
Event.IniTypeName=Event.IniDCSUnit:getTypeName()
end
if Event.IniObjectCategory==Object.Category.SCENERY then
Event.IniDCSUnit=Event.initiator
Event.IniDCSUnitName=Event.IniDCSUnit:getName()
Event.IniUnitName=Event.IniDCSUnitName
Event.IniUnit=SCENERY:Register(Event.IniDCSUnitName,Event.initiator)
Event.IniCategory=Event.IniDCSUnit:getDesc().category
Event.IniTypeName=Event.initiator:isExist()and Event.IniDCSUnit:getTypeName()or"SCENERY"
end
end
if Event.target then
Event.TgtObjectCategory=Event.target:getCategory()
if Event.TgtObjectCategory==Object.Category.UNIT then
Event.TgtDCSUnit=Event.target
Event.TgtDCSGroup=Event.TgtDCSUnit:getGroup()
Event.TgtDCSUnitName=Event.TgtDCSUnit:getName()
Event.TgtUnitName=Event.TgtDCSUnitName
Event.TgtUnit=UNIT:FindByName(Event.TgtDCSUnitName)
Event.TgtDCSGroupName=""
if Event.TgtDCSGroup and Event.TgtDCSGroup:isExist()then
Event.TgtDCSGroupName=Event.TgtDCSGroup:getName()
Event.TgtGroup=GROUP:FindByName(Event.TgtDCSGroupName)
if Event.TgtGroup then
Event.TgtGroupName=Event.TgtDCSGroupName
end
end
Event.TgtPlayerName=Event.TgtDCSUnit:getPlayerName()
Event.TgtCoalition=Event.TgtDCSUnit:getCoalition()
Event.TgtCategory=Event.TgtDCSUnit:getDesc().category
Event.TgtTypeName=Event.TgtDCSUnit:getTypeName()
end
if Event.TgtObjectCategory==Object.Category.STATIC then
Event.TgtDCSUnit=Event.target
Event.TgtDCSUnitName=Event.TgtDCSUnit:getName()
Event.TgtUnitName=Event.TgtDCSUnitName
Event.TgtUnit=STATIC:FindByName(Event.TgtDCSUnitName)
Event.TgtCoalition=Event.TgtDCSUnit:getCoalition()
Event.TgtCategory=Event.TgtDCSUnit:getDesc().category
Event.TgtTypeName=Event.TgtDCSUnit:getTypeName()
end
if Event.TgtObjectCategory==Object.Category.SCENERY then
Event.TgtDCSUnit=Event.target
Event.TgtDCSUnitName=Event.TgtDCSUnit:getName()
Event.TgtUnitName=Event.TgtDCSUnitName
Event.TgtUnit=SCENERY:Register(Event.TgtDCSUnitName,Event.target)
Event.TgtCategory=Event.TgtDCSUnit:getDesc().category
Event.TgtTypeName=Event.TgtDCSUnit:getTypeName()
end
end
if Event.weapon then
Event.Weapon=Event.weapon
Event.WeaponName=Event.Weapon:getTypeName()
Event.WeaponUNIT=CLIENT:Find(Event.Weapon,'',true)
Event.WeaponPlayerName=Event.WeaponUNIT and Event.Weapon:getPlayerName()
Event.WeaponCoalition=Event.WeaponUNIT and Event.Weapon:getCoalition()
Event.WeaponCategory=Event.WeaponUNIT and Event.Weapon:getDesc().category
Event.WeaponTypeName=Event.WeaponUNIT and Event.Weapon:getTypeName()
end
if Event.cargo then
Event.Cargo=Event.cargo
Event.CargoName=Event.cargo.Name
end
local PriorityOrder=EventMeta.Order
local PriorityBegin=PriorityOrder==-1 and 5 or 1
local PriorityEnd=PriorityOrder==-1 and 1 or 5
if Event.IniObjectCategory~=Object.Category.STATIC then
self:E({EventMeta.Text,Event,Event.IniDCSUnitName,Event.TgtDCSUnitName,PriorityOrder})
end
for EventPriority=PriorityBegin,PriorityEnd,PriorityOrder do
if self.Events[Event.id][EventPriority]then
for EventClass,EventData in pairs(self.Events[Event.id][EventPriority])do
Event.IniGroup=GROUP:FindByName(Event.IniDCSGroupName)
Event.TgtGroup=GROUP:FindByName(Event.TgtDCSGroupName)
if EventData.EventUnit then
if EventClass:IsAlive()or
Event.id==EVENTS.Crash or
Event.id==EVENTS.Dead then
local UnitName=EventClass:GetName()
if(EventMeta.Side=="I"and UnitName==Event.IniDCSUnitName)or
(EventMeta.Side=="T"and UnitName==Event.TgtDCSUnitName)then
if EventData.EventFunction then
if Event.IniObjectCategory~=3 then
self:E({"Calling EventFunction for UNIT ",EventClass:GetClassNameAndID(),", Unit ",Event.IniUnitName,EventPriority})
end
local Result,Value=xpcall(
function()
return EventData.EventFunction(EventClass,Event)
end,ErrorHandler)
else
local EventFunction=EventClass[EventMeta.Event]
if EventFunction and type(EventFunction)=="function"then
if Event.IniObjectCategory~=3 then
self:E({"Calling "..EventMeta.Event.." for Class ",EventClass:GetClassNameAndID(),EventPriority})
end
local Result,Value=xpcall(
function()
return EventFunction(EventClass,Event)
end,ErrorHandler)
end
end
end
else
self:RemoveEvent(EventClass,Event.id)
end
else
if EventData.EventGroup then
if EventClass:IsAlive()or
Event.id==EVENTS.Crash or
Event.id==EVENTS.Dead then
local GroupName=EventClass:GetName()
if(EventMeta.Side=="I"and GroupName==Event.IniDCSGroupName)or
(EventMeta.Side=="T"and GroupName==Event.TgtDCSGroupName)then
if EventData.EventFunction then
if Event.IniObjectCategory~=3 then
self:E({"Calling EventFunction for GROUP ",EventClass:GetClassNameAndID(),", Unit ",Event.IniUnitName,EventPriority})
end
local Result,Value=xpcall(
function()
return EventData.EventFunction(EventClass,Event,unpack(EventData.Params))
end,ErrorHandler)
else
local EventFunction=EventClass[EventMeta.Event]
if EventFunction and type(EventFunction)=="function"then
if Event.IniObjectCategory~=3 then
self:E({"Calling "..EventMeta.Event.." for GROUP ",EventClass:GetClassNameAndID(),EventPriority})
end
local Result,Value=xpcall(
function()
return EventFunction(EventClass,Event,unpack(EventData.Params))
end,ErrorHandler)
end
end
end
else
end
else
if not EventData.EventUnit then
if EventData.EventFunction then
if Event.IniObjectCategory~=3 then
self:F2({"Calling EventFunction for Class ",EventClass:GetClassNameAndID(),EventPriority})
end
local Result,Value=xpcall(
function()
return EventData.EventFunction(EventClass,Event)
end,ErrorHandler)
else
local EventFunction=EventClass[EventMeta.Event]
if EventFunction and type(EventFunction)=="function"then
if Event.IniObjectCategory~=3 then
self:F2({"Calling "..EventMeta.Event.." for Class ",EventClass:GetClassNameAndID(),EventPriority})
end
local Result,Value=xpcall(
function()
local Result,Value=EventFunction(EventClass,Event)
return Result,Value
end,ErrorHandler)
end
end
end
end
end
end
end
end
else
self:E({EventMeta.Text,Event})
end
Event=nil
end
EVENTHANDLER={
ClassName="EVENTHANDLER",
ClassID=0,
}
function EVENTHANDLER:New()
self=BASE:Inherit(self,BASE:New())
return self
end
SETTINGS={
ClassName="SETTINGS",
}
do
function SETTINGS:Set(PlayerName)
if PlayerName==nil then
local self=BASE:Inherit(self,BASE:New())
self:SetMetric()
self:SetA2G_BR()
self:SetA2A_BRAA()
self:SetLL_Accuracy(3)
self:SetMGRS_Accuracy(5)
self:SetMessageTime(MESSAGE.Type.Briefing,180)
self:SetMessageTime(MESSAGE.Type.Detailed,60)
self:SetMessageTime(MESSAGE.Type.Information,30)
self:SetMessageTime(MESSAGE.Type.Overview,60)
self:SetMessageTime(MESSAGE.Type.Update,15)
return self
else
local Settings=_DATABASE:GetPlayerSettings(PlayerName)
if not Settings then
Settings=BASE:Inherit(self,BASE:New())
_DATABASE:SetPlayerSettings(PlayerName,Settings)
end
return Settings
end
end
function SETTINGS:SetMetric()
self.Metric=true
end
function SETTINGS:IsMetric()
return(self.Metric~=nil and self.Metric==true)or(self.Metric==nil and _SETTINGS:IsMetric())
end
function SETTINGS:SetImperial()
self.Metric=false
end
function SETTINGS:IsImperial()
return(self.Metric~=nil and self.Metric==false)or(self.Metric==nil and _SETTINGS:IsMetric())
end
function SETTINGS:SetLL_Accuracy(LL_Accuracy)
self.LL_Accuracy=LL_Accuracy
end
function SETTINGS:GetLL_DDM_Accuracy()
return self.LL_DDM_Accuracy or _SETTINGS:GetLL_DDM_Accuracy()
end
function SETTINGS:SetMGRS_Accuracy(MGRS_Accuracy)
self.MGRS_Accuracy=MGRS_Accuracy
end
function SETTINGS:GetMGRS_Accuracy()
return self.MGRS_Accuracy or _SETTINGS:GetMGRS_Accuracy()
end
function SETTINGS:SetMessageTime(MessageType,MessageTime)
self.MessageTypeTimings=self.MessageTypeTimings or{}
self.MessageTypeTimings[MessageType]=MessageTime
end
function SETTINGS:GetMessageTime(MessageType)
return(self.MessageTypeTimings and self.MessageTypeTimings[MessageType])or _SETTINGS:GetMessageTime(MessageType)
end
function SETTINGS:SetA2G_LL_DMS()
self.A2GSystem="LL DMS"
end
function SETTINGS:SetA2G_LL_DDM()
self.A2GSystem="LL DDM"
end
function SETTINGS:IsA2G_LL_DMS()
return(self.A2GSystem and self.A2GSystem=="LL DMS")or(not self.A2GSystem and _SETTINGS:IsA2G_LL_DMS())
end
function SETTINGS:IsA2G_LL_DDM()
return(self.A2GSystem and self.A2GSystem=="LL DDM")or(not self.A2GSystem and _SETTINGS:IsA2G_LL_DDM())
end
function SETTINGS:SetA2G_MGRS()
self.A2GSystem="MGRS"
end
function SETTINGS:IsA2G_MGRS()
return(self.A2GSystem and self.A2GSystem=="MGRS")or(not self.A2GSystem and _SETTINGS:IsA2G_MGRS())
end
function SETTINGS:SetA2G_BR()
self.A2GSystem="BR"
end
function SETTINGS:IsA2G_BR()
return(self.A2GSystem and self.A2GSystem=="BR")or(not self.A2GSystem and _SETTINGS:IsA2G_BR())
end
function SETTINGS:SetA2A_BRAA()
self.A2ASystem="BRAA"
end
function SETTINGS:IsA2A_BRAA()
self:E({BRA=(self.A2ASystem and self.A2ASystem=="BRAA")or(not self.A2ASystem and _SETTINGS:IsA2A_BRAA())})
return(self.A2ASystem and self.A2ASystem=="BRAA")or(not self.A2ASystem and _SETTINGS:IsA2A_BRAA())
end
function SETTINGS:SetA2A_BULLS()
self.A2ASystem="BULLS"
end
function SETTINGS:IsA2A_BULLS()
return(self.A2ASystem and self.A2ASystem=="BULLS")or(not self.A2ASystem and _SETTINGS:IsA2A_BULLS())
end
function SETTINGS:SetA2A_LL_DMS()
self.A2ASystem="LL DMS"
end
function SETTINGS:SetA2A_LL_DDM()
self.A2ASystem="LL DDM"
end
function SETTINGS:IsA2A_LL_DMS()
return(self.A2ASystem and self.A2ASystem=="LL DMS")or(not self.A2ASystem and _SETTINGS:IsA2A_LL_DMS())
end
function SETTINGS:IsA2A_LL_DDM()
return(self.A2ASystem and self.A2ASystem=="LL DDM")or(not self.A2ASystem and _SETTINGS:IsA2A_LL_DDM())
end
function SETTINGS:SetA2A_MGRS()
self.A2ASystem="MGRS"
end
function SETTINGS:IsA2A_MGRS()
return(self.A2ASystem and self.A2ASystem=="MGRS")or(not self.A2ASystem and _SETTINGS:IsA2A_MGRS())
end
function SETTINGS:SetSystemMenu(MenuGroup,RootMenu)
local MenuText="System Settings"
local MenuTime=timer.getTime()
local SettingsMenu=MENU_GROUP:New(MenuGroup,MenuText,RootMenu):SetTime(MenuTime)
local A2GCoordinateMenu=MENU_GROUP:New(MenuGroup,"A2G Coordinate System",SettingsMenu):SetTime(MenuTime)
if not self:IsA2G_LL_DMS()then
MENU_GROUP_COMMAND:New(MenuGroup,"Lat/Lon Degree Min Sec (LL DMS)",A2GCoordinateMenu,self.A2GMenuSystem,self,MenuGroup,RootMenu,"LL DMS"):SetTime(MenuTime)
end
if not self:IsA2G_LL_DDM()then
MENU_GROUP_COMMAND:New(MenuGroup,"Lat/Lon Degree Dec Min (LL DDM)",A2GCoordinateMenu,self.A2GMenuSystem,self,MenuGroup,RootMenu,"LL DDM"):SetTime(MenuTime)
end
if self:IsA2G_LL_DDM()then
MENU_GROUP_COMMAND:New(MenuGroup,"LL DDM Accuracy 1",A2GCoordinateMenu,self.MenuLL_DDM_Accuracy,self,MenuGroup,RootMenu,1):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"LL DDM Accuracy 2",A2GCoordinateMenu,self.MenuLL_DDM_Accuracy,self,MenuGroup,RootMenu,2):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"LL DDM Accuracy 3",A2GCoordinateMenu,self.MenuLL_DDM_Accuracy,self,MenuGroup,RootMenu,3):SetTime(MenuTime)
end
if not self:IsA2G_BR()then
MENU_GROUP_COMMAND:New(MenuGroup,"Bearing, Range (BR)",A2GCoordinateMenu,self.A2GMenuSystem,self,MenuGroup,RootMenu,"BR"):SetTime(MenuTime)
end
if not self:IsA2G_MGRS()then
MENU_GROUP_COMMAND:New(MenuGroup,"Military Grid (MGRS)",A2GCoordinateMenu,self.A2GMenuSystem,self,MenuGroup,RootMenu,"MGRS"):SetTime(MenuTime)
end
if self:IsA2G_MGRS()then
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 1",A2GCoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,1):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 2",A2GCoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,2):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 3",A2GCoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,3):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 4",A2GCoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,4):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 5",A2GCoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,5):SetTime(MenuTime)
end
local A2ACoordinateMenu=MENU_GROUP:New(MenuGroup,"A2A Coordinate System",SettingsMenu):SetTime(MenuTime)
if not self:IsA2A_LL_DMS()then
MENU_GROUP_COMMAND:New(MenuGroup,"Lat/Lon Degree Min Sec (LL DMS)",A2ACoordinateMenu,self.A2AMenuSystem,self,MenuGroup,RootMenu,"LL DMS"):SetTime(MenuTime)
end
if not self:IsA2A_LL_DDM()then
MENU_GROUP_COMMAND:New(MenuGroup,"Lat/Lon Degree Dec Min (LL DDM)",A2ACoordinateMenu,self.A2AMenuSystem,self,MenuGroup,RootMenu,"LL DDM"):SetTime(MenuTime)
end
if self:IsA2A_LL_DDM()then
MENU_GROUP_COMMAND:New(MenuGroup,"LL DDM Accuracy 1",A2ACoordinateMenu,self.MenuLL_DDM_Accuracy,self,MenuGroup,RootMenu,1):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"LL DDM Accuracy 2",A2ACoordinateMenu,self.MenuLL_DDM_Accuracy,self,MenuGroup,RootMenu,2):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"LL DDM Accuracy 3",A2ACoordinateMenu,self.MenuLL_DDM_Accuracy,self,MenuGroup,RootMenu,3):SetTime(MenuTime)
end
if not self:IsA2A_BULLS()then
MENU_GROUP_COMMAND:New(MenuGroup,"Bullseye (BULLS)",A2ACoordinateMenu,self.A2AMenuSystem,self,MenuGroup,RootMenu,"BULLS"):SetTime(MenuTime)
end
if not self:IsA2A_BRAA()then
MENU_GROUP_COMMAND:New(MenuGroup,"Bearing Range Altitude Aspect (BRAA)",A2ACoordinateMenu,self.A2AMenuSystem,self,MenuGroup,RootMenu,"BRAA"):SetTime(MenuTime)
end
if not self:IsA2A_MGRS()then
MENU_GROUP_COMMAND:New(MenuGroup,"Military Grid (MGRS)",A2ACoordinateMenu,self.A2AMenuSystem,self,MenuGroup,RootMenu,"MGRS"):SetTime(MenuTime)
end
if self:IsA2A_MGRS()then
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 1",A2ACoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,1):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 2",A2ACoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,2):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 3",A2ACoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,3):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 4",A2ACoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,4):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"MGRS Accuracy 5",A2ACoordinateMenu,self.MenuMGRS_Accuracy,self,MenuGroup,RootMenu,5):SetTime(MenuTime)
end
local MetricsMenu=MENU_GROUP:New(MenuGroup,"Measures and Weights System",SettingsMenu):SetTime(MenuTime)
if self:IsMetric()then
MENU_GROUP_COMMAND:New(MenuGroup,"Imperial (Miles,Feet)",MetricsMenu,self.MenuMWSystem,self,MenuGroup,RootMenu,false):SetTime(MenuTime)
end
if self:IsImperial()then
MENU_GROUP_COMMAND:New(MenuGroup,"Metric (Kilometers,Meters)",MetricsMenu,self.MenuMWSystem,self,MenuGroup,RootMenu,true):SetTime(MenuTime)
end
local MessagesMenu=MENU_GROUP:New(MenuGroup,"Messages and Reports",SettingsMenu):SetTime(MenuTime)
local UpdateMessagesMenu=MENU_GROUP:New(MenuGroup,"Update Messages",MessagesMenu):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"Off",UpdateMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Update,0):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"5 seconds",UpdateMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Update,5):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"10 seconds",UpdateMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Update,10):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"15 seconds",UpdateMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Update,15):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"30 seconds",UpdateMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Update,30):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"1 minute",UpdateMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Update,60):SetTime(MenuTime)
local InformationMessagesMenu=MENU_GROUP:New(MenuGroup,"Information Messages",MessagesMenu):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"5 seconds",InformationMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Information,5):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"10 seconds",InformationMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Information,10):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"15 seconds",InformationMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Information,15):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"30 seconds",InformationMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Information,30):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"1 minute",InformationMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Information,60):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"2 minutes",InformationMessagesMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Information,120):SetTime(MenuTime)
local BriefingReportsMenu=MENU_GROUP:New(MenuGroup,"Briefing Reports",MessagesMenu):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"15 seconds",BriefingReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Briefing,15):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"30 seconds",BriefingReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Briefing,30):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"1 minute",BriefingReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Briefing,60):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"2 minutes",BriefingReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Briefing,120):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"3 minutes",BriefingReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Briefing,180):SetTime(MenuTime)
local OverviewReportsMenu=MENU_GROUP:New(MenuGroup,"Overview Reports",MessagesMenu):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"15 seconds",OverviewReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Overview,15):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"30 seconds",OverviewReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Overview,30):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"1 minute",OverviewReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Overview,60):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"2 minutes",OverviewReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Overview,120):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"3 minutes",OverviewReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.Overview,180):SetTime(MenuTime)
local DetailedReportsMenu=MENU_GROUP:New(MenuGroup,"Detailed Reports",MessagesMenu):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"15 seconds",DetailedReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.DetailedReportsMenu,15):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"30 seconds",DetailedReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.DetailedReportsMenu,30):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"1 minute",DetailedReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.DetailedReportsMenu,60):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"2 minutes",DetailedReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.DetailedReportsMenu,120):SetTime(MenuTime)
MENU_GROUP_COMMAND:New(MenuGroup,"3 minutes",DetailedReportsMenu,self.MenuMessageTimingsSystem,self,MenuGroup,RootMenu,MESSAGE.Type.DetailedReportsMenu,180):SetTime(MenuTime)
SettingsMenu:Remove(MenuTime)
return self
end
function SETTINGS:SetPlayerMenu(PlayerUnit)
local PlayerGroup=PlayerUnit:GetGroup()
local PlayerName=PlayerUnit:GetPlayerName()
local PlayerNames=PlayerGroup:GetPlayerNames()
local PlayerMenu=MENU_GROUP:New(PlayerGroup,'Settings "'..PlayerName..'"')
self.PlayerMenu=PlayerMenu
local A2GCoordinateMenu=MENU_GROUP:New(PlayerGroup,"A2G Coordinate System",PlayerMenu)
if not self:IsA2G_LL_DMS()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Lat/Lon Degree Min Sec (LL DMS)",A2GCoordinateMenu,self.MenuGroupA2GSystem,self,PlayerUnit,PlayerGroup,PlayerName,"LL DMS")
end
if not self:IsA2G_LL_DDM()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Lat/Lon Degree Dec Min (LL DDM)",A2GCoordinateMenu,self.MenuGroupA2GSystem,self,PlayerUnit,PlayerGroup,PlayerName,"LL DDM")
end
if self:IsA2G_LL_DDM()then
MENU_GROUP_COMMAND:New(PlayerGroup,"LL DDM Accuracy 1",A2GCoordinateMenu,self.MenuGroupLL_DDM_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,1)
MENU_GROUP_COMMAND:New(PlayerGroup,"LL DDM Accuracy 2",A2GCoordinateMenu,self.MenuGroupLL_DDM_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,2)
MENU_GROUP_COMMAND:New(PlayerGroup,"LL DDM Accuracy 3",A2GCoordinateMenu,self.MenuGroupLL_DDM_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,3)
end
if not self:IsA2G_BR()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Bearing, Range (BR)",A2GCoordinateMenu,self.MenuGroupA2GSystem,self,PlayerUnit,PlayerGroup,PlayerName,"BR")
end
if not self:IsA2G_MGRS()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Military Grid (MGRS)",A2GCoordinateMenu,self.MenuGroupA2GSystem,self,PlayerUnit,PlayerGroup,PlayerName,"MGRS")
end
if self:IsA2G_MGRS()then
MENU_GROUP_COMMAND:New(PlayerGroup,"MGRS Accuracy 1",A2GCoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,1)
MENU_GROUP_COMMAND:New(PlayerGroup,"MGRS Accuracy 2",A2GCoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,2)
MENU_GROUP_COMMAND:New(PlayerGroup,"MGRS Accuracy 3",A2GCoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,3)
MENU_GROUP_COMMAND:New(PlayerGroup,"MGRS Accuracy 4",A2GCoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,4)
MENU_GROUP_COMMAND:New(PlayerGroup,"MGRS Accuracy 5",A2GCoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,5)
end
local A2ACoordinateMenu=MENU_GROUP:New(PlayerGroup,"A2A Coordinate System",PlayerMenu)
if not self:IsA2A_LL_DMS()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Lat/Lon Degree Min Sec (LL DMS)",A2GCoordinateMenu,self.MenuGroupA2GSystem,self,PlayerUnit,PlayerGroup,PlayerName,"LL DMS")
end
if not self:IsA2A_LL_DDM()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Lat/Lon Degree Dec Min (LL DDM)",A2GCoordinateMenu,self.MenuGroupA2GSystem,self,PlayerUnit,PlayerGroup,PlayerName,"LL DDM")
end
if self:IsA2A_LL_DDM()then
MENU_GROUP_COMMAND:New(PlayerGroup,"LL DDM Accuracy 1",A2GCoordinateMenu,self.MenuGroupLL_DDM_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,1)
MENU_GROUP_COMMAND:New(PlayerGroup,"LL DDM Accuracy 2",A2GCoordinateMenu,self.MenuGroupLL_DDM_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,2)
MENU_GROUP_COMMAND:New(PlayerGroup,"LL DDM Accuracy 3",A2GCoordinateMenu,self.MenuGroupLL_DDM_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,3)
end
if not self:IsA2A_BULLS()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Bullseye (BULLS)",A2ACoordinateMenu,self.MenuGroupA2ASystem,self,PlayerUnit,PlayerGroup,PlayerName,"BULLS")
end
if not self:IsA2A_BRAA()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Bearing Range Altitude Aspect (BRAA)",A2ACoordinateMenu,self.MenuGroupA2ASystem,self,PlayerUnit,PlayerGroup,PlayerName,"BRAA")
end
if not self:IsA2A_MGRS()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Military Grid (MGRS)",A2ACoordinateMenu,self.MenuGroupA2ASystem,self,PlayerUnit,PlayerGroup,PlayerName,"MGRS")
end
if self:IsA2A_MGRS()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Military Grid (MGRS) Accuracy 1",A2ACoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,1)
MENU_GROUP_COMMAND:New(PlayerGroup,"Military Grid (MGRS) Accuracy 2",A2ACoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,2)
MENU_GROUP_COMMAND:New(PlayerGroup,"Military Grid (MGRS) Accuracy 3",A2ACoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,3)
MENU_GROUP_COMMAND:New(PlayerGroup,"Military Grid (MGRS) Accuracy 4",A2ACoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,4)
MENU_GROUP_COMMAND:New(PlayerGroup,"Military Grid (MGRS) Accuracy 5",A2ACoordinateMenu,self.MenuGroupMGRS_AccuracySystem,self,PlayerUnit,PlayerGroup,PlayerName,5)
end
local MetricsMenu=MENU_GROUP:New(PlayerGroup,"Measures and Weights System",PlayerMenu)
if self:IsMetric()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Imperial (Miles,Feet)",MetricsMenu,self.MenuGroupMWSystem,self,PlayerUnit,PlayerGroup,PlayerName,false)
end
if self:IsImperial()then
MENU_GROUP_COMMAND:New(PlayerGroup,"Metric (Kilometers,Meters)",MetricsMenu,self.MenuGroupMWSystem,self,PlayerUnit,PlayerGroup,PlayerName,true)
end
local MessagesMenu=MENU_GROUP:New(PlayerGroup,"Messages and Reports",PlayerMenu)
local UpdateMessagesMenu=MENU_GROUP:New(PlayerGroup,"Update Messages",MessagesMenu)
MENU_GROUP_COMMAND:New(PlayerGroup,"Off",UpdateMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Update,0)
MENU_GROUP_COMMAND:New(PlayerGroup,"5 seconds",UpdateMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Update,5)
MENU_GROUP_COMMAND:New(PlayerGroup,"10 seconds",UpdateMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Update,10)
MENU_GROUP_COMMAND:New(PlayerGroup,"15 seconds",UpdateMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Update,15)
MENU_GROUP_COMMAND:New(PlayerGroup,"30 seconds",UpdateMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Update,30)
MENU_GROUP_COMMAND:New(PlayerGroup,"1 minute",UpdateMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Update,60)
local InformationMessagesMenu=MENU_GROUP:New(PlayerGroup,"Information Messages",MessagesMenu)
MENU_GROUP_COMMAND:New(PlayerGroup,"5 seconds",InformationMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Information,5)
MENU_GROUP_COMMAND:New(PlayerGroup,"10 seconds",InformationMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Information,10)
MENU_GROUP_COMMAND:New(PlayerGroup,"15 seconds",InformationMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Information,15)
MENU_GROUP_COMMAND:New(PlayerGroup,"30 seconds",InformationMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Information,30)
MENU_GROUP_COMMAND:New(PlayerGroup,"1 minute",InformationMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Information,60)
MENU_GROUP_COMMAND:New(PlayerGroup,"2 minutes",InformationMessagesMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Information,120)
local BriefingReportsMenu=MENU_GROUP:New(PlayerGroup,"Briefing Reports",MessagesMenu)
MENU_GROUP_COMMAND:New(PlayerGroup,"15 seconds",BriefingReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Briefing,15)
MENU_GROUP_COMMAND:New(PlayerGroup,"30 seconds",BriefingReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Briefing,30)
MENU_GROUP_COMMAND:New(PlayerGroup,"1 minute",BriefingReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Briefing,60)
MENU_GROUP_COMMAND:New(PlayerGroup,"2 minutes",BriefingReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Briefing,120)
MENU_GROUP_COMMAND:New(PlayerGroup,"3 minutes",BriefingReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Briefing,180)
local OverviewReportsMenu=MENU_GROUP:New(PlayerGroup,"Overview Reports",MessagesMenu)
MENU_GROUP_COMMAND:New(PlayerGroup,"15 seconds",OverviewReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Overview,15)
MENU_GROUP_COMMAND:New(PlayerGroup,"30 seconds",OverviewReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Overview,30)
MENU_GROUP_COMMAND:New(PlayerGroup,"1 minute",OverviewReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Overview,60)
MENU_GROUP_COMMAND:New(PlayerGroup,"2 minutes",OverviewReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Overview,120)
MENU_GROUP_COMMAND:New(PlayerGroup,"3 minutes",OverviewReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.Overview,180)
local DetailedReportsMenu=MENU_GROUP:New(PlayerGroup,"Detailed Reports",MessagesMenu)
MENU_GROUP_COMMAND:New(PlayerGroup,"15 seconds",DetailedReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.DetailedReportsMenu,15)
MENU_GROUP_COMMAND:New(PlayerGroup,"30 seconds",DetailedReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.DetailedReportsMenu,30)
MENU_GROUP_COMMAND:New(PlayerGroup,"1 minute",DetailedReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.DetailedReportsMenu,60)
MENU_GROUP_COMMAND:New(PlayerGroup,"2 minutes",DetailedReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.DetailedReportsMenu,120)
MENU_GROUP_COMMAND:New(PlayerGroup,"3 minutes",DetailedReportsMenu,self.MenuGroupMessageTimingsSystem,self,PlayerUnit,PlayerGroup,PlayerName,MESSAGE.Type.DetailedReportsMenu,180)
return self
end
function SETTINGS:RemovePlayerMenu(PlayerUnit)
if self.PlayerMenu then
self.PlayerMenu:Remove()
end
return self
end
function SETTINGS:A2GMenuSystem(MenuGroup,RootMenu,A2GSystem)
self.A2GSystem=A2GSystem
MESSAGE:New(string.format("Settings: Default A2G coordinate system set to %s for all players!",A2GSystem),5):ToAll()
self:SetSystemMenu(MenuGroup,RootMenu)
end
function SETTINGS:A2AMenuSystem(MenuGroup,RootMenu,A2ASystem)
self.A2ASystem=A2ASystem
MESSAGE:New(string.format("Settings: Default A2A coordinate system set to %s for all players!",A2ASystem),5):ToAll()
self:SetSystemMenu(MenuGroup,RootMenu)
end
function SETTINGS:MenuLL_DDM_Accuracy(MenuGroup,RootMenu,LL_Accuracy)
self.LL_Accuracy=LL_Accuracy
MESSAGE:New(string.format("Settings: Default LL accuracy set to %s for all players!",LL_Accuracy),5):ToAll()
self:SetSystemMenu(MenuGroup,RootMenu)
end
function SETTINGS:MenuMGRS_Accuracy(MenuGroup,RootMenu,MGRS_Accuracy)
self.MGRS_Accuracy=MGRS_Accuracy
MESSAGE:New(string.format("Settings: Default MGRS accuracy set to %s for all players!",MGRS_Accuracy),5):ToAll()
self:SetSystemMenu(MenuGroup,RootMenu)
end
function SETTINGS:MenuMWSystem(MenuGroup,RootMenu,MW)
self.Metric=MW
MESSAGE:New(string.format("Settings: Default measurement format set to %s for all players!",MW and"Metric"or"Imperial"),5):ToAll()
self:SetSystemMenu(MenuGroup,RootMenu)
end
function SETTINGS:MenuMessageTimingsSystem(MenuGroup,RootMenu,MessageType,MessageTime)
self:SetMessageTime(MessageType,MessageTime)
MESSAGE:New(string.format("Settings: Default message time set for %s to %d.",MessageType,MessageTime),5):ToAll()
end
do
function SETTINGS:MenuGroupA2GSystem(PlayerUnit,PlayerGroup,PlayerName,A2GSystem)
BASE:E({self,PlayerUnit:GetName(),A2GSystem})
self.A2GSystem=A2GSystem
MESSAGE:New(string.format("Settings: A2G format set to %s for player %s.",A2GSystem,PlayerName),5):ToGroup(PlayerGroup)
self:RemovePlayerMenu(PlayerUnit)
self:SetPlayerMenu(PlayerUnit)
end
function SETTINGS:MenuGroupA2ASystem(PlayerUnit,PlayerGroup,PlayerName,A2ASystem)
self.A2ASystem=A2ASystem
MESSAGE:New(string.format("Settings: A2A format set to %s for player %s.",A2ASystem,PlayerName),5):ToGroup(PlayerGroup)
self:RemovePlayerMenu(PlayerUnit)
self:SetPlayerMenu(PlayerUnit)
end
function SETTINGS:MenuGroupLL_DDM_AccuracySystem(PlayerUnit,PlayerGroup,PlayerName,LL_Accuracy)
self.LL_Accuracy=LL_Accuracy
MESSAGE:New(string.format("Settings: A2G LL format accuracy set to %d for player %s.",LL_Accuracy,PlayerName),5):ToGroup(PlayerGroup)
self:RemovePlayerMenu(PlayerUnit)
self:SetPlayerMenu(PlayerUnit)
end
function SETTINGS:MenuGroupMGRS_AccuracySystem(PlayerUnit,PlayerGroup,PlayerName,MGRS_Accuracy)
self.MGRS_Accuracy=MGRS_Accuracy
MESSAGE:New(string.format("Settings: A2G MGRS format accuracy set to %d for player %s.",MGRS_Accuracy,PlayerName),5):ToGroup(PlayerGroup)
self:RemovePlayerMenu(PlayerUnit)
self:SetPlayerMenu(PlayerUnit)
end
function SETTINGS:MenuGroupMWSystem(PlayerUnit,PlayerGroup,PlayerName,MW)
self.Metric=MW
MESSAGE:New(string.format("Settings: Measurement format set to %s for player %s.",MW and"Metric"or"Imperial",PlayerName),5):ToGroup(PlayerGroup)
self:RemovePlayerMenu(PlayerUnit)
self:SetPlayerMenu(PlayerUnit)
end
function SETTINGS:MenuGroupMessageTimingsSystem(PlayerUnit,PlayerGroup,PlayerName,MessageType,MessageTime)
self:SetMessageTime(MessageType,MessageTime)
MESSAGE:New(string.format("Settings: Default message time set for %s to %d.",MessageType,MessageTime),5):ToGroup(PlayerGroup)
end
end
end
do
MENU_BASE={
ClassName="MENU_BASE",
MenuPath=nil,
MenuText="",
MenuParentPath=nil
}
function MENU_BASE:New(MenuText,ParentMenu)
local MenuParentPath={}
if ParentMenu~=nil then
MenuParentPath=ParentMenu.MenuPath
end
local self=BASE:Inherit(self,BASE:New())
self.MenuPath=nil
self.MenuText=MenuText
self.MenuParentPath=MenuParentPath
self.Menus={}
self.MenuCount=0
self.MenuRemoveParent=false
self.MenuTime=timer.getTime()
return self
end
function MENU_BASE:GetMenu(MenuText)
self:F2({Menu=self.Menus[MenuText]})
return self.Menus[MenuText]
end
function MENU_BASE:SetRemoveParent(RemoveParent)
self:F2({RemoveParent})
self.MenuRemoveParent=RemoveParent
return self
end
function MENU_BASE:SetTime(MenuTime)
self.MenuTime=MenuTime
return self
end
function MENU_BASE:SetTag(MenuTag)
self.MenuTag=MenuTag
return self
end
end
do
MENU_COMMAND_BASE={
ClassName="MENU_COMMAND_BASE",
CommandMenuFunction=nil,
CommandMenuArgument=nil,
MenuCallHandler=nil,
}
function MENU_COMMAND_BASE:New(MenuText,ParentMenu,CommandMenuFunction,CommandMenuArguments)
local self=BASE:Inherit(self,MENU_BASE:New(MenuText,ParentMenu))
local ErrorHandler=function(errmsg)
env.info("MOOSE error in MENU COMMAND function: "..errmsg)
if debug~=nil then
env.info(debug.traceback())
end
return errmsg
end
self:SetCommandMenuFunction(CommandMenuFunction)
self:SetCommandMenuArguments(CommandMenuArguments)
self.MenuCallHandler=function()
local function MenuFunction()
return self.CommandMenuFunction(unpack(self.CommandMenuArguments))
end
local Status,Result=xpcall(MenuFunction,ErrorHandler)
end
return self
end
function MENU_COMMAND_BASE:SetCommandMenuFunction(CommandMenuFunction)
self.CommandMenuFunction=CommandMenuFunction
return self
end
function MENU_COMMAND_BASE:SetCommandMenuArguments(CommandMenuArguments)
self.CommandMenuArguments=CommandMenuArguments
return self
end
end
do
MENU_MISSION={
ClassName="MENU_MISSION"
}
function MENU_MISSION:New(MenuText,ParentMenu)
local self=BASE:Inherit(self,MENU_BASE:New(MenuText,ParentMenu))
self:F({MenuText,ParentMenu})
self.MenuText=MenuText
self.ParentMenu=ParentMenu
self.Menus={}
self:T({MenuText})
self.MenuPath=missionCommands.addSubMenu(MenuText,self.MenuParentPath)
self:T({self.MenuPath})
if ParentMenu and ParentMenu.Menus then
ParentMenu.Menus[self.MenuPath]=self
end
return self
end
function MENU_MISSION:RemoveSubMenus()
self:F(self.MenuPath)
for MenuID,Menu in pairs(self.Menus)do
Menu:Remove()
end
end
function MENU_MISSION:Remove()
self:F(self.MenuPath)
self:RemoveSubMenus()
missionCommands.removeItem(self.MenuPath)
if self.ParentMenu then
self.ParentMenu.Menus[self.MenuPath]=nil
end
return nil
end
end
do
MENU_MISSION_COMMAND={
ClassName="MENU_MISSION_COMMAND"
}
function MENU_MISSION_COMMAND:New(MenuText,ParentMenu,CommandMenuFunction,...)
local self=BASE:Inherit(self,MENU_COMMAND_BASE:New(MenuText,ParentMenu,CommandMenuFunction,arg))
self.MenuText=MenuText
self.ParentMenu=ParentMenu
self:T({MenuText,CommandMenuFunction,arg})
self.MenuPath=missionCommands.addCommand(MenuText,self.MenuParentPath,self.MenuCallHandler)
ParentMenu.Menus[self.MenuPath]=self
return self
end
function MENU_MISSION_COMMAND:Remove()
self:F(self.MenuPath)
missionCommands.removeItem(self.MenuPath)
if self.ParentMenu then
self.ParentMenu.Menus[self.MenuPath]=nil
end
return nil
end
end
do
MENU_COALITION={
ClassName="MENU_COALITION"
}
function MENU_COALITION:New(Coalition,MenuText,ParentMenu)
local self=BASE:Inherit(self,MENU_BASE:New(MenuText,ParentMenu))
self:F({Coalition,MenuText,ParentMenu})
self.Coalition=Coalition
self.MenuText=MenuText
self.ParentMenu=ParentMenu
self.Menus={}
self:T({MenuText})
self.MenuPath=missionCommands.addSubMenuForCoalition(Coalition,MenuText,self.MenuParentPath)
self:T({self.MenuPath})
if ParentMenu and ParentMenu.Menus then
ParentMenu.Menus[self.MenuPath]=self
end
return self
end
function MENU_COALITION:RemoveSubMenus()
self:F(self.MenuPath)
for MenuID,Menu in pairs(self.Menus)do
Menu:Remove()
end
end
function MENU_COALITION:Remove()
self:F(self.MenuPath)
self:RemoveSubMenus()
missionCommands.removeItemForCoalition(self.Coalition,self.MenuPath)
if self.ParentMenu then
self.ParentMenu.Menus[self.MenuPath]=nil
end
return nil
end
end
do
MENU_COALITION_COMMAND={
ClassName="MENU_COALITION_COMMAND"
}
function MENU_COALITION_COMMAND:New(Coalition,MenuText,ParentMenu,CommandMenuFunction,...)
local self=BASE:Inherit(self,MENU_COMMAND_BASE:New(MenuText,ParentMenu,CommandMenuFunction,arg))
self.MenuCoalition=Coalition
self.MenuText=MenuText
self.ParentMenu=ParentMenu
self:T({MenuText,CommandMenuFunction,arg})
self.MenuPath=missionCommands.addCommandForCoalition(self.MenuCoalition,MenuText,self.MenuParentPath,self.MenuCallHandler)
ParentMenu.Menus[self.MenuPath]=self
return self
end
function MENU_COALITION_COMMAND:Remove()
self:F(self.MenuPath)
missionCommands.removeItemForCoalition(self.MenuCoalition,self.MenuPath)
if self.ParentMenu then
self.ParentMenu.Menus[self.MenuPath]=nil
end
return nil
end
end
do
local _MENUCLIENTS={}
MENU_CLIENT={
ClassName="MENU_CLIENT"
}
function MENU_CLIENT:New(Client,MenuText,ParentMenu)
local MenuParentPath={}
if ParentMenu~=nil then
MenuParentPath=ParentMenu.MenuPath
end
local self=BASE:Inherit(self,MENU_BASE:New(MenuText,MenuParentPath))
self:F({Client,MenuText,ParentMenu})
self.MenuClient=Client
self.MenuClientGroupID=Client:GetClientGroupID()
self.MenuParentPath=MenuParentPath
self.MenuText=MenuText
self.ParentMenu=ParentMenu
self.Menus={}
if not _MENUCLIENTS[self.MenuClientGroupID]then
_MENUCLIENTS[self.MenuClientGroupID]={}
end
local MenuPath=_MENUCLIENTS[self.MenuClientGroupID]
self:T({Client:GetClientGroupName(),MenuPath[table.concat(MenuParentPath)],MenuParentPath,MenuText})
local MenuPathID=table.concat(MenuParentPath).."/"..MenuText
if MenuPath[MenuPathID]then
missionCommands.removeItemForGroup(self.MenuClient:GetClientGroupID(),MenuPath[MenuPathID])
end
self.MenuPath=missionCommands.addSubMenuForGroup(self.MenuClient:GetClientGroupID(),MenuText,MenuParentPath)
MenuPath[MenuPathID]=self.MenuPath
self:T({Client:GetClientGroupName(),self.MenuPath})
if ParentMenu and ParentMenu.Menus then
ParentMenu.Menus[self.MenuPath]=self
end
return self
end
function MENU_CLIENT:RemoveSubMenus()
self:F(self.MenuPath)
for MenuID,Menu in pairs(self.Menus)do
Menu:Remove()
end
end
function MENU_CLIENT:Remove()
self:F(self.MenuPath)
self:RemoveSubMenus()
if not _MENUCLIENTS[self.MenuClientGroupID]then
_MENUCLIENTS[self.MenuClientGroupID]={}
end
local MenuPath=_MENUCLIENTS[self.MenuClientGroupID]
if MenuPath[table.concat(self.MenuParentPath).."/"..self.MenuText]then
MenuPath[table.concat(self.MenuParentPath).."/"..self.MenuText]=nil
end
missionCommands.removeItemForGroup(self.MenuClient:GetClientGroupID(),self.MenuPath)
self.ParentMenu.Menus[self.MenuPath]=nil
return nil
end
MENU_CLIENT_COMMAND={
ClassName="MENU_CLIENT_COMMAND"
}
function MENU_CLIENT_COMMAND:New(Client,MenuText,ParentMenu,CommandMenuFunction,...)
local MenuParentPath={}
if ParentMenu~=nil then
MenuParentPath=ParentMenu.MenuPath
end
local self=BASE:Inherit(self,MENU_COMMAND_BASE:New(MenuText,MenuParentPath,CommandMenuFunction,arg))
self.MenuClient=Client
self.MenuClientGroupID=Client:GetClientGroupID()
self.MenuParentPath=MenuParentPath
self.MenuText=MenuText
self.ParentMenu=ParentMenu
if not _MENUCLIENTS[self.MenuClientGroupID]then
_MENUCLIENTS[self.MenuClientGroupID]={}
end
local MenuPath=_MENUCLIENTS[self.MenuClientGroupID]
self:T({Client:GetClientGroupName(),MenuPath[table.concat(MenuParentPath)],MenuParentPath,MenuText,CommandMenuFunction,arg})
local MenuPathID=table.concat(MenuParentPath).."/"..MenuText
if MenuPath[MenuPathID]then
missionCommands.removeItemForGroup(self.MenuClient:GetClientGroupID(),MenuPath[MenuPathID])
end
self.MenuPath=missionCommands.addCommandForGroup(self.MenuClient:GetClientGroupID(),MenuText,MenuParentPath,self.MenuCallHandler)
MenuPath[MenuPathID]=self.MenuPath
if ParentMenu and ParentMenu.Menus then
ParentMenu.Menus[self.MenuPath]=self
end
return self
end
function MENU_CLIENT_COMMAND:Remove()
self:F(self.MenuPath)
if not _MENUCLIENTS[self.MenuClientGroupID]then
_MENUCLIENTS[self.MenuClientGroupID]={}
end
local MenuPath=_MENUCLIENTS[self.MenuClientGroupID]
if MenuPath[table.concat(self.MenuParentPath).."/"..self.MenuText]then
MenuPath[table.concat(self.MenuParentPath).."/"..self.MenuText]=nil
end
missionCommands.removeItemForGroup(self.MenuClient:GetClientGroupID(),self.MenuPath)
self.ParentMenu.Menus[self.MenuPath]=nil
return nil
end
end
do
local _MENUGROUPS={}
MENU_GROUP={
ClassName="MENU_GROUP"
}
function MENU_GROUP:New(MenuGroup,MenuText,ParentMenu)
MenuGroup._Menus=MenuGroup._Menus or{}
local Path=(ParentMenu and(table.concat(ParentMenu.MenuPath or{},"@").."@"..MenuText))or MenuText
if MenuGroup._Menus[Path]then
self=MenuGroup._Menus[Path]
else
self=BASE:Inherit(self,MENU_BASE:New(MenuText,ParentMenu))
MenuGroup._Menus[Path]=self
self.MenuGroup=MenuGroup
self.Path=Path
self.MenuGroupID=MenuGroup:GetID()
self.MenuText=MenuText
self.ParentMenu=ParentMenu
self:T({"Adding Menu ",MenuText,self.MenuParentPath})
self.MenuPath=missionCommands.addSubMenuForGroup(self.MenuGroupID,MenuText,self.MenuParentPath)
if self.ParentMenu and self.ParentMenu.Menus then
self.ParentMenu.Menus[MenuText]=self
self:F({self.ParentMenu.Menus,MenuText})
self.ParentMenu.MenuCount=self.ParentMenu.MenuCount+1
end
end
return self
end
function MENU_GROUP:RemoveSubMenus(MenuTime,MenuTag)
self:T({"Removing Group SubMenus:",MenuTime,MenuTag,self.MenuGroup:GetName(),self.MenuPath})
for MenuText,Menu in pairs(self.Menus)do
Menu:Remove(MenuTime,MenuTag)
end
end
function MENU_GROUP:Remove(MenuTime,MenuTag)
self:RemoveSubMenus(MenuTime,MenuTag)
if not MenuTime or self.MenuTime~=MenuTime then
if(not MenuTag)or(MenuTag and self.MenuTag and MenuTag==self.MenuTag)then
if self.MenuGroup._Menus[self.Path]then
self=self.MenuGroup._Menus[self.Path]
missionCommands.removeItemForGroup(self.MenuGroupID,self.MenuPath)
if self.ParentMenu then
self.ParentMenu.Menus[self.MenuText]=nil
self.ParentMenu.MenuCount=self.ParentMenu.MenuCount-1
if self.ParentMenu.MenuCount==0 then
if self.MenuRemoveParent==true then
self:T2("Removing Parent Menu ")
self.ParentMenu:Remove()
end
end
end
end
self:T({"Removing Group Menu:",MenuGroup=self.MenuGroup:GetName()})
self.MenuGroup._Menus[self.Path]=nil
self=nil
end
end
return nil
end
MENU_GROUP_COMMAND={
ClassName="MENU_GROUP_COMMAND"
}
function MENU_GROUP_COMMAND:New(MenuGroup,MenuText,ParentMenu,CommandMenuFunction,...)
MenuGroup._Menus=MenuGroup._Menus or{}
local Path=(ParentMenu and(table.concat(ParentMenu.MenuPath or{},"@").."@"..MenuText))or MenuText
if MenuGroup._Menus[Path]then
self=MenuGroup._Menus[Path]
self:SetCommandMenuFunction(CommandMenuFunction)
self:SetCommandMenuArguments(arg)
return self
end
self=BASE:Inherit(self,MENU_COMMAND_BASE:New(MenuText,ParentMenu,CommandMenuFunction,arg))
MenuGroup._Menus[Path]=self
self.Path=Path
self.MenuGroup=MenuGroup
self.MenuGroupID=MenuGroup:GetID()
self.MenuText=MenuText
self.ParentMenu=ParentMenu
self:F({"Adding Group Command Menu:",MenuGroup=MenuGroup:GetName(),MenuText=MenuText,MenuPath=self.MenuParentPath})
self.MenuPath=missionCommands.addCommandForGroup(self.MenuGroupID,MenuText,self.MenuParentPath,self.MenuCallHandler)
if self.ParentMenu and self.ParentMenu.Menus then
self.ParentMenu.Menus[MenuText]=self
self.ParentMenu.MenuCount=self.ParentMenu.MenuCount+1
self:F2({ParentMenu.Menus,MenuText})
end
return self
end
function MENU_GROUP_COMMAND:Remove(MenuTime,MenuTag)
if not MenuTime or self.MenuTime~=MenuTime then
if(not MenuTag)or(MenuTag and self.MenuTag and MenuTag==self.MenuTag)then
if self.MenuGroup._Menus[self.Path]then
self=self.MenuGroup._Menus[self.Path]
missionCommands.removeItemForGroup(self.MenuGroupID,self.MenuPath)
self.ParentMenu.Menus[self.MenuText]=nil
self.ParentMenu.MenuCount=self.ParentMenu.MenuCount-1
if self.ParentMenu.MenuCount==0 then
if self.MenuRemoveParent==true then
self:T2("Removing Parent Menu ")
self.ParentMenu:Remove()
end
end
self.MenuGroup._Menus[self.Path]=nil
self=nil
end
end
end
return nil
end
end
ZONE_BASE={
ClassName="ZONE_BASE",
ZoneName="",
ZoneProbability=1,
}
function ZONE_BASE:New(ZoneName)
local self=BASE:Inherit(self,BASE:New())
self:F(ZoneName)
self.ZoneName=ZoneName
return self
end
function ZONE_BASE:GetName()
self:F2()
return self.ZoneName
end
function ZONE_BASE:IsVec2InZone(Vec2)
self:F2(Vec2)
return false
end
function ZONE_BASE:IsVec3InZone(Vec3)
self:F2(Vec3)
local InZone=self:IsVec2InZone({x=Vec3.x,y=Vec3.z})
return InZone
end
function ZONE_BASE:IsPointVec2InZone(PointVec2)
self:F2(PointVec2)
local InZone=self:IsVec2InZone(PointVec2:GetVec2())
return InZone
end
function ZONE_BASE:IsPointVec3InZone(PointVec3)
self:F2(PointVec3)
local InZone=self:IsPointVec2InZone(PointVec3)
return InZone
end
function ZONE_BASE:GetVec2()
self:F2(self.ZoneName)
return nil
end
function ZONE_BASE:GetPointVec2()
self:F2(self.ZoneName)
local Vec2=self:GetVec2()
local PointVec2=POINT_VEC2:NewFromVec2(Vec2)
self:T2({PointVec2})
return PointVec2
end
function ZONE_BASE:GetCoordinate()
self:F2(self.ZoneName)
local Vec2=self:GetVec2()
local Coordinate=COORDINATE:NewFromVec2(Vec2)
self:T2({Coordinate})
return Coordinate
end
function ZONE_BASE:GetVec3(Height)
self:F2(self.ZoneName)
Height=Height or 0
local Vec2=self:GetVec2()
local Vec3={x=Vec2.x,y=Height and Height or land.getHeight(self:GetVec2()),z=Vec2.y}
self:T2({Vec3})
return Vec3
end
function ZONE_BASE:GetPointVec3(Height)
self:F2(self.ZoneName)
local Vec3=self:GetVec3(Height)
local PointVec3=POINT_VEC3:NewFromVec3(Vec3)
self:T2({PointVec3})
return PointVec3
end
function ZONE_BASE:GetCoordinate(Height)
self:F2(self.ZoneName)
local Vec3=self:GetVec3(Height)
local PointVec3=COORDINATE:NewFromVec3(Vec3)
self:T2({PointVec3})
return PointVec3
end
function ZONE_BASE:GetRandomVec2()
return nil
end
function ZONE_BASE:GetRandomPointVec2()
return nil
end
function ZONE_BASE:GetRandomPointVec3()
return nil
end
function ZONE_BASE:GetBoundingSquare()
return nil
end
function ZONE_BASE:BoundZone()
self:F2()
end
function ZONE_BASE:SmokeZone(SmokeColor)
self:F2(SmokeColor)
end
function ZONE_BASE:SetZoneProbability(ZoneProbability)
self:F2(ZoneProbability)
self.ZoneProbability=ZoneProbability or 1
return self
end
function ZONE_BASE:GetZoneProbability()
self:F2()
return self.ZoneProbability
end
function ZONE_BASE:GetZoneMaybe()
self:F2()
local Randomization=math.random()
if Randomization<=self.ZoneProbability then
return self
else
return nil
end
end
ZONE_RADIUS={
ClassName="ZONE_RADIUS",
}
function ZONE_RADIUS:New(ZoneName,Vec2,Radius)
local self=BASE:Inherit(self,ZONE_BASE:New(ZoneName))
self:F({ZoneName,Vec2,Radius})
self.Radius=Radius
self.Vec2=Vec2
return self
end
function ZONE_RADIUS:BoundZone(Points,CountryID,UnBound)
local Point={}
local Vec2=self:GetVec2()
Points=Points and Points or 360
local Angle
local RadialBase=math.pi*2
for Angle=0,360,(360/Points)do
local Radial=Angle*RadialBase/360
Point.x=Vec2.x+math.cos(Radial)*self:GetRadius()
Point.y=Vec2.y+math.sin(Radial)*self:GetRadius()
local CountryName=_DATABASE.COUNTRY_NAME[CountryID]
local Tire={
["country"]=CountryName,
["category"]="Fortifications",
["canCargo"]=false,
["shape_name"]="H-tyre_B_WF",
["type"]="Black_Tyre_WF",
["y"]=Point.y,
["x"]=Point.x,
["name"]=string.format("%s-Tire #%0d",self:GetName(),Angle),
["heading"]=0,
}
local Group=coalition.addStaticObject(CountryID,Tire)
if UnBound and UnBound==true then
Group:destroy()
end
end
return self
end
function ZONE_RADIUS:SmokeZone(SmokeColor,Points)
self:F2(SmokeColor)
local Point={}
local Vec2=self:GetVec2()
Points=Points and Points or 360
local Angle
local RadialBase=math.pi*2
for Angle=0,360,360/Points do
local Radial=Angle*RadialBase/360
Point.x=Vec2.x+math.cos(Radial)*self:GetRadius()
Point.y=Vec2.y+math.sin(Radial)*self:GetRadius()
POINT_VEC2:New(Point.x,Point.y):Smoke(SmokeColor)
end
return self
end
function ZONE_RADIUS:FlareZone(FlareColor,Points,Azimuth)
self:F2({FlareColor,Azimuth})
local Point={}
local Vec2=self:GetVec2()
Points=Points and Points or 360
local Angle
local RadialBase=math.pi*2
for Angle=0,360,360/Points do
local Radial=Angle*RadialBase/360
Point.x=Vec2.x+math.cos(Radial)*self:GetRadius()
Point.y=Vec2.y+math.sin(Radial)*self:GetRadius()
POINT_VEC2:New(Point.x,Point.y):Flare(FlareColor,Azimuth)
end
return self
end
function ZONE_RADIUS:GetRadius()
self:F2(self.ZoneName)
self:T2({self.Radius})
return self.Radius
end
function ZONE_RADIUS:SetRadius(Radius)
self:F2(self.ZoneName)
self.Radius=Radius
self:T2({self.Radius})
return self.Radius
end
function ZONE_RADIUS:GetVec2()
self:F2(self.ZoneName)
self:T2({self.Vec2})
return self.Vec2
end
function ZONE_RADIUS:SetVec2(Vec2)
self:F2(self.ZoneName)
self.Vec2=Vec2
self:T2({self.Vec2})
return self.Vec2
end
function ZONE_RADIUS:GetVec3(Height)
self:F2({self.ZoneName,Height})
Height=Height or 0
local Vec2=self:GetVec2()
local Vec3={x=Vec2.x,y=land.getHeight(self:GetVec2())+Height,z=Vec2.y}
self:T2({Vec3})
return Vec3
end
function ZONE_RADIUS:IsVec2InZone(Vec2)
self:F2(Vec2)
local ZoneVec2=self:GetVec2()
if ZoneVec2 then
if((Vec2.x-ZoneVec2.x)^2+(Vec2.y-ZoneVec2.y)^2)^0.5<=self:GetRadius()then
return true
end
end
return false
end
function ZONE_RADIUS:IsVec3InZone(Vec3)
self:F2(Vec3)
local InZone=self:IsVec2InZone({x=Vec3.x,y=Vec3.z})
return InZone
end
function ZONE_RADIUS:GetRandomVec2(inner,outer)
self:F(self.ZoneName,inner,outer)
local Point={}
local Vec2=self:GetVec2()
local _inner=inner or 0
local _outer=outer or self:GetRadius()
local angle=math.random()*math.pi*2;
Point.x=Vec2.x+math.cos(angle)*math.random(_inner,_outer);
Point.y=Vec2.y+math.sin(angle)*math.random(_inner,_outer);
self:T({Point})
return Point
end
function ZONE_RADIUS:GetRandomPointVec2(inner,outer)
self:F(self.ZoneName,inner,outer)
local PointVec2=POINT_VEC2:NewFromVec2(self:GetRandomVec2())
self:T3({PointVec2})
return PointVec2
end
function ZONE_RADIUS:GetRandomPointVec3(inner,outer)
self:F(self.ZoneName,inner,outer)
local PointVec3=POINT_VEC3:NewFromVec2(self:GetRandomVec2())
self:T3({PointVec3})
return PointVec3
end
function ZONE_RADIUS:GetRandomCoordinate(inner,outer)
self:F(self.ZoneName,inner,outer)
local Coordinate=COORDINATE:NewFromVec2(self:GetRandomVec2())
self:T3({Coordinate=Coordinate})
return Coordinate
end
ZONE={
ClassName="ZONE",
}
function ZONE:New(ZoneName)
local Zone=trigger.misc.getZone(ZoneName)
if not Zone then
error("Zone "..ZoneName.." does not exist.")
return nil
end
local self=BASE:Inherit(self,ZONE_RADIUS:New(ZoneName,{x=Zone.point.x,y=Zone.point.z},Zone.radius))
self:F(ZoneName)
self.Zone=Zone
return self
end
ZONE_UNIT={
ClassName="ZONE_UNIT",
}
function ZONE_UNIT:New(ZoneName,ZoneUNIT,Radius)
local self=BASE:Inherit(self,ZONE_RADIUS:New(ZoneName,ZoneUNIT:GetVec2(),Radius))
self:F({ZoneName,ZoneUNIT:GetVec2(),Radius})
self.ZoneUNIT=ZoneUNIT
self.LastVec2=ZoneUNIT:GetVec2()
return self
end
function ZONE_UNIT:GetVec2()
self:F2(self.ZoneName)
local ZoneVec2=self.ZoneUNIT:GetVec2()
if ZoneVec2 then
self.LastVec2=ZoneVec2
return ZoneVec2
else
return self.LastVec2
end
self:T2({ZoneVec2})
return nil
end
function ZONE_UNIT:GetRandomVec2()
self:F(self.ZoneName)
local RandomVec2={}
local Vec2=self.ZoneUNIT:GetVec2()
if not Vec2 then
Vec2=self.LastVec2
end
local angle=math.random()*math.pi*2;
RandomVec2.x=Vec2.x+math.cos(angle)*math.random()*self:GetRadius();
RandomVec2.y=Vec2.y+math.sin(angle)*math.random()*self:GetRadius();
self:T({RandomVec2})
return RandomVec2
end
function ZONE_UNIT:GetVec3(Height)
self:F2(self.ZoneName)
Height=Height or 0
local Vec2=self:GetVec2()
local Vec3={x=Vec2.x,y=land.getHeight(self:GetVec2())+Height,z=Vec2.y}
self:T2({Vec3})
return Vec3
end
ZONE_GROUP={
ClassName="ZONE_GROUP",
}
function ZONE_GROUP:New(ZoneName,ZoneGROUP,Radius)
local self=BASE:Inherit(self,ZONE_RADIUS:New(ZoneName,ZoneGROUP:GetVec2(),Radius))
self:F({ZoneName,ZoneGROUP:GetVec2(),Radius})
self._.ZoneGROUP=ZoneGROUP
return self
end
function ZONE_GROUP:GetVec2()
self:F(self.ZoneName)
local ZoneVec2=self._.ZoneGROUP:GetVec2()
self:T({ZoneVec2})
return ZoneVec2
end
function ZONE_GROUP:GetRandomVec2()
self:F(self.ZoneName)
local Point={}
local Vec2=self._.ZoneGROUP:GetVec2()
local angle=math.random()*math.pi*2;
Point.x=Vec2.x+math.cos(angle)*math.random()*self:GetRadius();
Point.y=Vec2.y+math.sin(angle)*math.random()*self:GetRadius();
self:T({Point})
return Point
end
function ZONE_GROUP:GetRandomPointVec2(inner,outer)
self:F(self.ZoneName,inner,outer)
local PointVec2=POINT_VEC2:NewFromVec2(self:GetRandomVec2())
self:T3({PointVec2})
return PointVec2
end
ZONE_POLYGON_BASE={
ClassName="ZONE_POLYGON_BASE",
}
function ZONE_POLYGON_BASE:New(ZoneName,PointsArray)
local self=BASE:Inherit(self,ZONE_BASE:New(ZoneName))
self:F({ZoneName,PointsArray})
local i=0
self._.Polygon={}
for i=1,#PointsArray do
self._.Polygon[i]={}
self._.Polygon[i].x=PointsArray[i].x
self._.Polygon[i].y=PointsArray[i].y
end
return self
end
function ZONE_POLYGON_BASE:GetVec2()
self:F(self.ZoneName)
local Bounds=self:GetBoundingSquare()
return{x=(Bounds.x2+Bounds.x1)/2,y=(Bounds.y2+Bounds.y1)/2}
end
function ZONE_POLYGON_BASE:Flush()
self:F2()
self:E({Polygon=self.ZoneName,Coordinates=self._.Polygon})
return self
end
function ZONE_POLYGON_BASE:BoundZone(UnBound)
local i
local j
local Segments=10
i=1
j=#self._.Polygon
while i<=#self._.Polygon do
self:T({i,j,self._.Polygon[i],self._.Polygon[j]})
local DeltaX=self._.Polygon[j].x-self._.Polygon[i].x
local DeltaY=self._.Polygon[j].y-self._.Polygon[i].y
for Segment=0,Segments do
local PointX=self._.Polygon[i].x+(Segment*DeltaX/Segments)
local PointY=self._.Polygon[i].y+(Segment*DeltaY/Segments)
local Tire={
["country"]="USA",
["category"]="Fortifications",
["canCargo"]=false,
["shape_name"]="H-tyre_B_WF",
["type"]="Black_Tyre_WF",
["y"]=PointY,
["x"]=PointX,
["name"]=string.format("%s-Tire #%0d",self:GetName(),((i-1)*Segments)+Segment),
["heading"]=0,
}
local Group=coalition.addStaticObject(country.id.USA,Tire)
if UnBound and UnBound==true then
Group:destroy()
end
end
j=i
i=i+1
end
return self
end
function ZONE_POLYGON_BASE:SmokeZone(SmokeColor)
self:F2(SmokeColor)
local i
local j
local Segments=10
i=1
j=#self._.Polygon
while i<=#self._.Polygon do
self:T({i,j,self._.Polygon[i],self._.Polygon[j]})
local DeltaX=self._.Polygon[j].x-self._.Polygon[i].x
local DeltaY=self._.Polygon[j].y-self._.Polygon[i].y
for Segment=0,Segments do
local PointX=self._.Polygon[i].x+(Segment*DeltaX/Segments)
local PointY=self._.Polygon[i].y+(Segment*DeltaY/Segments)
POINT_VEC2:New(PointX,PointY):Smoke(SmokeColor)
end
j=i
i=i+1
end
return self
end
function ZONE_POLYGON_BASE:IsVec2InZone(Vec2)
self:F2(Vec2)
local Next
local Prev
local InPolygon=false
Next=1
Prev=#self._.Polygon
while Next<=#self._.Polygon do
self:T({Next,Prev,self._.Polygon[Next],self._.Polygon[Prev]})
if(((self._.Polygon[Next].y>Vec2.y)~=(self._.Polygon[Prev].y>Vec2.y))and
(Vec2.x<(self._.Polygon[Prev].x-self._.Polygon[Next].x)*(Vec2.y-self._.Polygon[Next].y)/(self._.Polygon[Prev].y-self._.Polygon[Next].y)+self._.Polygon[Next].x)
)then
InPolygon=not InPolygon
end
self:T2({InPolygon=InPolygon})
Prev=Next
Next=Next+1
end
self:T({InPolygon=InPolygon})
return InPolygon
end
function ZONE_POLYGON_BASE:GetRandomVec2()
self:F2()
local Vec2Found=false
local Vec2
local BS=self:GetBoundingSquare()
self:T2(BS)
while Vec2Found==false do
Vec2={x=math.random(BS.x1,BS.x2),y=math.random(BS.y1,BS.y2)}
self:T2(Vec2)
if self:IsVec2InZone(Vec2)then
Vec2Found=true
end
end
self:T2(Vec2)
return Vec2
end
function ZONE_POLYGON_BASE:GetRandomPointVec2()
self:F2()
local PointVec2=POINT_VEC2:NewFromVec2(self:GetRandomVec2())
self:T2(PointVec2)
return PointVec2
end
function ZONE_POLYGON_BASE:GetRandomPointVec3()
self:F2()
local PointVec3=POINT_VEC3:NewFromVec2(self:GetRandomVec2())
self:T2(PointVec3)
return PointVec3
end
function ZONE_POLYGON_BASE:GetRandomCoordinate()
self:F2()
local Coordinate=COORDINATE:NewFromVec2(self:GetRandomVec2())
self:T2(Coordinate)
return Coordinate
end
function ZONE_POLYGON_BASE:GetBoundingSquare()
local x1=self._.Polygon[1].x
local y1=self._.Polygon[1].y
local x2=self._.Polygon[1].x
local y2=self._.Polygon[1].y
for i=2,#self._.Polygon do
self:T2({self._.Polygon[i],x1,y1,x2,y2})
x1=(x1>self._.Polygon[i].x)and self._.Polygon[i].x or x1
x2=(x2<self._.Polygon[i].x)and self._.Polygon[i].x or x2
y1=(y1>self._.Polygon[i].y)and self._.Polygon[i].y or y1
y2=(y2<self._.Polygon[i].y)and self._.Polygon[i].y or y2
end
return{x1=x1,y1=y1,x2=x2,y2=y2}
end
ZONE_POLYGON={
ClassName="ZONE_POLYGON",
}
function ZONE_POLYGON:New(ZoneName,ZoneGroup)
local GroupPoints=ZoneGroup:GetTaskRoute()
local self=BASE:Inherit(self,ZONE_POLYGON_BASE:New(ZoneName,GroupPoints))
self:F({ZoneName,ZoneGroup,self._.Polygon})
return self
end
DATABASE={
ClassName="DATABASE",
Templates={
Units={},
Groups={},
Statics={},
ClientsByName={},
ClientsByID={},
},
UNITS={},
UNITS_Index={},
STATICS={},
GROUPS={},
PLAYERS={},
PLAYERSJOINED={},
PLAYERUNITS={},
CLIENTS={},
CARGOS={},
AIRBASES={},
COUNTRY_ID={},
COUNTRY_NAME={},
NavPoints={},
PLAYERSETTINGS={},
ZONENAMES={},
}
local _DATABASECoalition=
{
[1]="Red",
[2]="Blue",
}
local _DATABASECategory=
{
["plane"]=Unit.Category.AIRPLANE,
["helicopter"]=Unit.Category.HELICOPTER,
["vehicle"]=Unit.Category.GROUND_UNIT,
["ship"]=Unit.Category.SHIP,
["static"]=Unit.Category.STRUCTURE,
}
function DATABASE:New()
local self=BASE:Inherit(self,BASE:New())
self:SetEventPriority(1)
self:HandleEvent(EVENTS.Birth,self._EventOnBirth)
self:HandleEvent(EVENTS.Dead,self._EventOnDeadOrCrash)
self:HandleEvent(EVENTS.Crash,self._EventOnDeadOrCrash)
self:HandleEvent(EVENTS.NewCargo)
self:HandleEvent(EVENTS.DeleteCargo)
self:HandleEvent(EVENTS.PlayerEnterUnit,self._EventOnPlayerEnterUnit)
self:HandleEvent(EVENTS.PlayerLeaveUnit,self._EventOnPlayerLeaveUnit)
self:_RegisterTemplates()
self:_RegisterGroupsAndUnits()
self:_RegisterClients()
self:_RegisterStatics()
self:_RegisterAirbases()
self.UNITS_Position=0
local function CheckPlayers(self)
local CoalitionsData={AlivePlayersRed=coalition.getPlayers(coalition.side.RED),AlivePlayersBlue=coalition.getPlayers(coalition.side.BLUE)}
for CoalitionId,CoalitionData in pairs(CoalitionsData)do
for UnitId,UnitData in pairs(CoalitionData)do
if UnitData and UnitData:isExist()then
local UnitName=UnitData:getName()
local PlayerName=UnitData:getPlayerName()
local PlayerUnit=UNIT:Find(UnitData)
if PlayerName and PlayerName~=""then
if self.PLAYERS[PlayerName]==nil or self.PLAYERS[PlayerName]~=UnitName then
self:AddPlayer(UnitName,PlayerName)
local Settings=SETTINGS:Set(PlayerName)
Settings:SetPlayerMenu(PlayerUnit)
end
end
end
end
end
end
self:E("Scheduling")
PlayerCheckSchedule=SCHEDULER:New(nil,CheckPlayers,{self},1,1)
return self
end
function DATABASE:FindUnit(UnitName)
local UnitFound=self.UNITS[UnitName]
return UnitFound
end
function DATABASE:AddUnit(DCSUnitName)
if not self.UNITS[DCSUnitName]then
local UnitRegister=UNIT:Register(DCSUnitName)
self.UNITS[DCSUnitName]=UNIT:Register(DCSUnitName)
table.insert(self.UNITS_Index,DCSUnitName)
end
return self.UNITS[DCSUnitName]
end
function DATABASE:DeleteUnit(DCSUnitName)
self.UNITS[DCSUnitName]=nil
end
function DATABASE:AddStatic(DCSStaticName)
if not self.STATICS[DCSStaticName]then
self.STATICS[DCSStaticName]=STATIC:Register(DCSStaticName)
end
end
function DATABASE:DeleteStatic(DCSStaticName)
end
function DATABASE:FindStatic(StaticName)
local StaticFound=self.STATICS[StaticName]
return StaticFound
end
function DATABASE:FindAirbase(AirbaseName)
local AirbaseFound=self.AIRBASES[AirbaseName]
return AirbaseFound
end
function DATABASE:AddAirbase(AirbaseName)
if not self.AIRBASES[AirbaseName]then
self.AIRBASES[AirbaseName]=AIRBASE:Register(AirbaseName)
end
end
function DATABASE:DeleteAirbase(AirbaseName)
self.AIRBASES[AirbaseName]=nil
end
function DATABASE:FindAirbase(AirbaseName)
local AirbaseFound=self.AIRBASES[AirbaseName]
return AirbaseFound
end
function DATABASE:AddCargo(Cargo)
if not self.CARGOS[Cargo.Name]then
self.CARGOS[Cargo.Name]=Cargo
end
end
function DATABASE:DeleteCargo(CargoName)
self.CARGOS[CargoName]=nil
end
function DATABASE:FindCargo(CargoName)
local CargoFound=self.CARGOS[CargoName]
return CargoFound
end
function DATABASE:FindClient(ClientName)
local ClientFound=self.CLIENTS[ClientName]
return ClientFound
end
function DATABASE:AddClient(ClientName)
if not self.CLIENTS[ClientName]then
self.CLIENTS[ClientName]=CLIENT:Register(ClientName)
end
return self.CLIENTS[ClientName]
end
function DATABASE:FindGroup(GroupName)
local GroupFound=self.GROUPS[GroupName]
return GroupFound
end
function DATABASE:AddGroup(GroupName)
if not self.GROUPS[GroupName]then
self:E({"Add GROUP:",GroupName})
self.GROUPS[GroupName]=GROUP:Register(GroupName)
end
return self.GROUPS[GroupName]
end
function DATABASE:AddPlayer(UnitName,PlayerName)
if PlayerName then
self:E({"Add player for unit:",UnitName,PlayerName})
self.PLAYERS[PlayerName]=UnitName
self.PLAYERUNITS[UnitName]=PlayerName
self.PLAYERSJOINED[PlayerName]=PlayerName
end
end
function DATABASE:DeletePlayer(UnitName,PlayerName)
if PlayerName then
self:E({"Clean player:",PlayerName})
self.PLAYERS[PlayerName]=nil
self.PLAYERUNITS[UnitName]=PlayerName
end
end
function DATABASE:Spawn(SpawnTemplate)
self:F(SpawnTemplate.name)
self:T({SpawnTemplate.SpawnCountryID,SpawnTemplate.SpawnCategoryID})
local SpawnCoalitionID=SpawnTemplate.CoalitionID
local SpawnCountryID=SpawnTemplate.CountryID
local SpawnCategoryID=SpawnTemplate.CategoryID
SpawnTemplate.CoalitionID=nil
SpawnTemplate.CountryID=nil
SpawnTemplate.CategoryID=nil
self:_RegisterGroupTemplate(SpawnTemplate,SpawnCoalitionID,SpawnCategoryID,SpawnCountryID)
self:T3(SpawnTemplate)
coalition.addGroup(SpawnCountryID,SpawnCategoryID,SpawnTemplate)
SpawnTemplate.CoalitionID=SpawnCoalitionID
SpawnTemplate.CountryID=SpawnCountryID
SpawnTemplate.CategoryID=SpawnCategoryID
local SpawnGroup=self:AddGroup(SpawnTemplate.name)
for UnitID,UnitData in pairs(SpawnTemplate.units)do
self:AddUnit(UnitData.name)
end
return SpawnGroup
end
function DATABASE:SetStatusGroup(GroupName,Status)
self:F2(Status)
self.Templates.Groups[GroupName].Status=Status
end
function DATABASE:GetStatusGroup(GroupName)
self:F2(Status)
if self.Templates.Groups[GroupName]then
return self.Templates.Groups[GroupName].Status
else
return""
end
end
function DATABASE:_RegisterGroupTemplate(GroupTemplate,CoalitionID,CategoryID,CountryID)
local GroupTemplateName=env.getValueDictByKey(GroupTemplate.name)
local TraceTable={}
if not self.Templates.Groups[GroupTemplateName]then
self.Templates.Groups[GroupTemplateName]={}
self.Templates.Groups[GroupTemplateName].Status=nil
end
if GroupTemplate.route and GroupTemplate.route.spans then
GroupTemplate.route.spans=nil
end
GroupTemplate.CategoryID=CategoryID
GroupTemplate.CoalitionID=CoalitionID
GroupTemplate.CountryID=CountryID
self.Templates.Groups[GroupTemplateName].GroupName=GroupTemplateName
self.Templates.Groups[GroupTemplateName].Template=GroupTemplate
self.Templates.Groups[GroupTemplateName].groupId=GroupTemplate.groupId
self.Templates.Groups[GroupTemplateName].UnitCount=#GroupTemplate.units
self.Templates.Groups[GroupTemplateName].Units=GroupTemplate.units
self.Templates.Groups[GroupTemplateName].CategoryID=CategoryID
self.Templates.Groups[GroupTemplateName].CoalitionID=CoalitionID
self.Templates.Groups[GroupTemplateName].CountryID=CountryID
TraceTable[#TraceTable+1]="Group"
TraceTable[#TraceTable+1]=self.Templates.Groups[GroupTemplateName].GroupName
TraceTable[#TraceTable+1]="Coalition"
TraceTable[#TraceTable+1]=self.Templates.Groups[GroupTemplateName].CoalitionID
TraceTable[#TraceTable+1]="Category"
TraceTable[#TraceTable+1]=self.Templates.Groups[GroupTemplateName].CategoryID
TraceTable[#TraceTable+1]="Country"
TraceTable[#TraceTable+1]=self.Templates.Groups[GroupTemplateName].CountryID
TraceTable[#TraceTable+1]="Units"
for unit_num,UnitTemplate in pairs(GroupTemplate.units)do
UnitTemplate.name=env.getValueDictByKey(UnitTemplate.name)
self.Templates.Units[UnitTemplate.name]={}
self.Templates.Units[UnitTemplate.name].UnitName=UnitTemplate.name
self.Templates.Units[UnitTemplate.name].Template=UnitTemplate
self.Templates.Units[UnitTemplate.name].GroupName=GroupTemplateName
self.Templates.Units[UnitTemplate.name].GroupTemplate=GroupTemplate
self.Templates.Units[UnitTemplate.name].GroupId=GroupTemplate.groupId
self.Templates.Units[UnitTemplate.name].CategoryID=CategoryID
self.Templates.Units[UnitTemplate.name].CoalitionID=CoalitionID
self.Templates.Units[UnitTemplate.name].CountryID=CountryID
if UnitTemplate.skill and(UnitTemplate.skill=="Client"or UnitTemplate.skill=="Player")then
self.Templates.ClientsByName[UnitTemplate.name]=UnitTemplate
self.Templates.ClientsByName[UnitTemplate.name].CategoryID=CategoryID
self.Templates.ClientsByName[UnitTemplate.name].CoalitionID=CoalitionID
self.Templates.ClientsByName[UnitTemplate.name].CountryID=CountryID
self.Templates.ClientsByID[UnitTemplate.unitId]=UnitTemplate
end
TraceTable[#TraceTable+1]=self.Templates.Units[UnitTemplate.name].UnitName
end
self:E(TraceTable)
end
function DATABASE:GetGroupTemplate(GroupName)
local GroupTemplate=self.Templates.Groups[GroupName].Template
GroupTemplate.SpawnCoalitionID=self.Templates.Groups[GroupName].CoalitionID
GroupTemplate.SpawnCategoryID=self.Templates.Groups[GroupName].CategoryID
GroupTemplate.SpawnCountryID=self.Templates.Groups[GroupName].CountryID
return GroupTemplate
end
function DATABASE:_RegisterStaticTemplate(StaticTemplate,CoalitionID,CategoryID,CountryID)
local TraceTable={}
local StaticTemplateName=env.getValueDictByKey(StaticTemplate.name)
self.Templates.Statics[StaticTemplateName]=self.Templates.Statics[StaticTemplateName]or{}
StaticTemplate.CategoryID=CategoryID
StaticTemplate.CoalitionID=CoalitionID
StaticTemplate.CountryID=CountryID
self.Templates.Statics[StaticTemplateName].StaticName=StaticTemplateName
self.Templates.Statics[StaticTemplateName].GroupTemplate=StaticTemplate
self.Templates.Statics[StaticTemplateName].UnitTemplate=StaticTemplate.units[1]
self.Templates.Statics[StaticTemplateName].CategoryID=CategoryID
self.Templates.Statics[StaticTemplateName].CoalitionID=CoalitionID
self.Templates.Statics[StaticTemplateName].CountryID=CountryID
TraceTable[#TraceTable+1]="Static"
TraceTable[#TraceTable+1]=self.Templates.Statics[StaticTemplateName].GroupName
TraceTable[#TraceTable+1]="Coalition"
TraceTable[#TraceTable+1]=self.Templates.Statics[StaticTemplateName].CoalitionID
TraceTable[#TraceTable+1]="Category"
TraceTable[#TraceTable+1]=self.Templates.Statics[StaticTemplateName].CategoryID
TraceTable[#TraceTable+1]="Country"
TraceTable[#TraceTable+1]=self.Templates.Statics[StaticTemplateName].CountryID
self:E(TraceTable)
end
function DATABASE:GetStaticUnitTemplate(StaticName)
local StaticTemplate=self.Templates.Statics[StaticName].UnitTemplate
StaticTemplate.SpawnCoalitionID=self.Templates.Statics[StaticName].CoalitionID
StaticTemplate.SpawnCategoryID=self.Templates.Statics[StaticName].CategoryID
StaticTemplate.SpawnCountryID=self.Templates.Statics[StaticName].CountryID
return StaticTemplate
end
function DATABASE:GetGroupNameFromUnitName(UnitName)
return self.Templates.Units[UnitName].GroupName
end
function DATABASE:GetGroupTemplateFromUnitName(UnitName)
return self.Templates.Units[UnitName].GroupTemplate
end
function DATABASE:GetCoalitionFromClientTemplate(ClientName)
return self.Templates.ClientsByName[ClientName].CoalitionID
end
function DATABASE:GetCategoryFromClientTemplate(ClientName)
return self.Templates.ClientsByName[ClientName].CategoryID
end
function DATABASE:GetCountryFromClientTemplate(ClientName)
return self.Templates.ClientsByName[ClientName].CountryID
end
function DATABASE:GetCoalitionFromAirbase(AirbaseName)
return self.AIRBASES[AirbaseName]:GetCoalition()
end
function DATABASE:GetCategoryFromAirbase(AirbaseName)
return self.AIRBASES[AirbaseName]:GetCategory()
end
function DATABASE:_RegisterPlayers()
local CoalitionsData={AlivePlayersRed=coalition.getPlayers(coalition.side.RED),AlivePlayersBlue=coalition.getPlayers(coalition.side.BLUE)}
for CoalitionId,CoalitionData in pairs(CoalitionsData)do
for UnitId,UnitData in pairs(CoalitionData)do
self:T3({"UnitData:",UnitData})
if UnitData and UnitData:isExist()then
local UnitName=UnitData:getName()
local PlayerName=UnitData:getPlayerName()
if not self.PLAYERS[PlayerName]then
self:E({"Add player for unit:",UnitName,PlayerName})
self:AddPlayer(UnitName,PlayerName)
end
end
end
end
return self
end
function DATABASE:_RegisterGroupsAndUnits()
local CoalitionsData={GroupsRed=coalition.getGroups(coalition.side.RED),GroupsBlue=coalition.getGroups(coalition.side.BLUE)}
for CoalitionId,CoalitionData in pairs(CoalitionsData)do
for DCSGroupId,DCSGroup in pairs(CoalitionData)do
if DCSGroup:isExist()then
local DCSGroupName=DCSGroup:getName()
self:E({"Register Group:",DCSGroupName})
self:AddGroup(DCSGroupName)
for DCSUnitId,DCSUnit in pairs(DCSGroup:getUnits())do
local DCSUnitName=DCSUnit:getName()
self:E({"Register Unit:",DCSUnitName})
self:AddUnit(DCSUnitName)
end
else
self:E({"Group does not exist: ",DCSGroup})
end
end
end
return self
end
function DATABASE:_RegisterClients()
for ClientName,ClientTemplate in pairs(self.Templates.ClientsByName)do
self:E({"Register Client:",ClientName})
self:AddClient(ClientName)
end
return self
end
function DATABASE:_RegisterStatics()
local CoalitionsData={GroupsRed=coalition.getStaticObjects(coalition.side.RED),GroupsBlue=coalition.getStaticObjects(coalition.side.BLUE)}
for CoalitionId,CoalitionData in pairs(CoalitionsData)do
for DCSStaticId,DCSStatic in pairs(CoalitionData)do
if DCSStatic:isExist()then
local DCSStaticName=DCSStatic:getName()
self:E({"Register Static:",DCSStaticName})
self:AddStatic(DCSStaticName)
else
self:E({"Static does not exist: ",DCSStatic})
end
end
end
return self
end
function DATABASE:_RegisterAirbases()
local CoalitionsData={AirbasesRed=coalition.getAirbases(coalition.side.RED),AirbasesBlue=coalition.getAirbases(coalition.side.BLUE),AirbasesNeutral=coalition.getAirbases(coalition.side.NEUTRAL)}
for CoalitionId,CoalitionData in pairs(CoalitionsData)do
for DCSAirbaseId,DCSAirbase in pairs(CoalitionData)do
local DCSAirbaseName=DCSAirbase:getName()
self:E({"Register Airbase:",DCSAirbaseName})
self:AddAirbase(DCSAirbaseName)
end
end
return self
end
function DATABASE:_EventOnBirth(Event)
self:F2({Event})
if Event.IniDCSUnit then
if Event.IniObjectCategory==3 then
self:AddStatic(Event.IniDCSUnitName)
else
if Event.IniObjectCategory==1 then
self:AddUnit(Event.IniDCSUnitName)
self:AddGroup(Event.IniDCSGroupName)
end
end
end
end
function DATABASE:_EventOnDeadOrCrash(Event)
self:F2({Event})
if Event.IniDCSUnit then
if Event.IniObjectCategory==3 then
if self.STATICS[Event.IniDCSUnitName]then
self:DeleteStatic(Event.IniDCSUnitName)
end
else
if Event.IniObjectCategory==1 then
if self.UNITS[Event.IniDCSUnitName]then
self:DeleteUnit(Event.IniDCSUnitName)
end
end
end
end
end
function DATABASE:_EventOnPlayerEnterUnit(Event)
self:F2({Event})
if Event.IniUnit then
if Event.IniObjectCategory==1 then
self:AddUnit(Event.IniDCSUnitName)
self:AddGroup(Event.IniDCSGroupName)
local PlayerName=Event.IniUnit:GetPlayerName()
if not self.PLAYERS[PlayerName]then
self:AddPlayer(Event.IniUnitName,PlayerName)
end
local Settings=SETTINGS:Set(PlayerName)
Settings:SetPlayerMenu(Event.IniUnit)
end
end
end
function DATABASE:_EventOnPlayerLeaveUnit(Event)
self:F2({Event})
if Event.IniUnit then
if Event.IniObjectCategory==1 then
local PlayerName=Event.IniUnit:GetPlayerName()
if self.PLAYERS[PlayerName]then
local Settings=SETTINGS:Set(PlayerName)
Settings:RemovePlayerMenu(Event.IniUnit)
self:DeletePlayer(Event.IniUnit,PlayerName)
end
end
end
end
function DATABASE:ForEach(IteratorFunction,FinalizeFunction,arg,Set)
self:F2(arg)
local function CoRoutine()
local Count=0
for ObjectID,Object in pairs(Set)do
self:T2(Object)
IteratorFunction(Object,unpack(arg))
Count=Count+1
end
return true
end
local co=CoRoutine
local function Schedule()
local status,res=co()
self:T3({status,res})
if status==false then
error(res)
end
if res==false then
return true
end
if FinalizeFunction then
FinalizeFunction(unpack(arg))
end
return false
end
local Scheduler=SCHEDULER:New(self,Schedule,{},0.001,0.001,0)
return self
end
function DATABASE:ForEachStatic(IteratorFunction,FinalizeFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,FinalizeFunction,arg,self.STATICS)
return self
end
function DATABASE:ForEachUnit(IteratorFunction,FinalizeFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,FinalizeFunction,arg,self.UNITS)
return self
end
function DATABASE:ForEachGroup(IteratorFunction,FinalizeFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,FinalizeFunction,arg,self.GROUPS)
return self
end
function DATABASE:ForEachPlayer(IteratorFunction,FinalizeFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,FinalizeFunction,arg,self.PLAYERS)
return self
end
function DATABASE:ForEachPlayerJoined(IteratorFunction,FinalizeFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,FinalizeFunction,arg,self.PLAYERSJOINED)
return self
end
function DATABASE:ForEachPlayerUnit(IteratorFunction,FinalizeFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,FinalizeFunction,arg,self.PLAYERUNITS)
return self
end
function DATABASE:ForEachClient(IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.CLIENTS)
return self
end
function DATABASE:ForEachCargo(IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.CARGOS)
return self
end
function DATABASE:OnEventNewCargo(EventData)
self:F2({EventData})
if EventData.Cargo then
self:AddCargo(EventData.Cargo)
end
end
function DATABASE:OnEventDeleteCargo(EventData)
self:F2({EventData})
if EventData.Cargo then
self:DeleteCargo(EventData.Cargo.Name)
end
end
function DATABASE:GetPlayerSettings(PlayerName)
self:F2({PlayerName})
return self.PLAYERSETTINGS[PlayerName]
end
function DATABASE:SetPlayerSettings(PlayerName,Settings)
self:F2({PlayerName,Settings})
self.PLAYERSETTINGS[PlayerName]=Settings
end
function DATABASE:_RegisterTemplates()
self:F2()
self.Navpoints={}
self.UNITS={}
for CoalitionName,coa_data in pairs(env.mission.coalition)do
if(CoalitionName=='red'or CoalitionName=='blue')and type(coa_data)=='table'then
local CoalitionSide=coalition.side[string.upper(CoalitionName)]
self.Navpoints[CoalitionName]={}
if coa_data.nav_points then
for nav_ind,nav_data in pairs(coa_data.nav_points)do
if type(nav_data)=='table'then
self.Navpoints[CoalitionName][nav_ind]=routines.utils.deepCopy(nav_data)
self.Navpoints[CoalitionName][nav_ind]['name']=nav_data.callsignStr
self.Navpoints[CoalitionName][nav_ind]['point']={}
self.Navpoints[CoalitionName][nav_ind]['point']['x']=nav_data.x
self.Navpoints[CoalitionName][nav_ind]['point']['y']=0
self.Navpoints[CoalitionName][nav_ind]['point']['z']=nav_data.y
end
end
end
if coa_data.country then
for cntry_id,cntry_data in pairs(coa_data.country)do
local CountryName=string.upper(cntry_data.name)
local CountryID=cntry_data.id
self.COUNTRY_ID[CountryName]=CountryID
self.COUNTRY_NAME[CountryID]=CountryName
if type(cntry_data)=='table'then
for obj_type_name,obj_type_data in pairs(cntry_data)do
if obj_type_name=="helicopter"or obj_type_name=="ship"or obj_type_name=="plane"or obj_type_name=="vehicle"or obj_type_name=="static"then
local CategoryName=obj_type_name
if((type(obj_type_data)=='table')and obj_type_data.group and(type(obj_type_data.group)=='table')and(#obj_type_data.group>0))then
for group_num,Template in pairs(obj_type_data.group)do
if obj_type_name~="static"and Template and Template.units and type(Template.units)=='table'then
self:_RegisterGroupTemplate(
Template,
CoalitionSide,
_DATABASECategory[string.lower(CategoryName)],
CountryID
)
else
self:_RegisterStaticTemplate(
Template,
CoalitionSide,
_DATABASECategory[string.lower(CategoryName)],
CountryID
)
end
end
end
end
end
end
end
end
end
end
for ZoneID,ZoneData in pairs(env.mission.triggers.zones)do
local ZoneName=ZoneData.name
self.ZONENAMES[ZoneName]=ZoneName
end
return self
end
SET_BASE={
ClassName="SET_BASE",
Filter={},
Set={},
List={},
Index={},
}
function SET_BASE:New(Database)
local self=BASE:Inherit(self,BASE:New())
self.Database=Database
self.YieldInterval=10
self.TimeInterval=0.001
self.Set={}
self.Index={}
self.CallScheduler=SCHEDULER:New(self)
self:SetEventPriority(2)
return self
end
function SET_BASE:_Find(ObjectName)
local ObjectFound=self.Set[ObjectName]
return ObjectFound
end
function SET_BASE:GetSet()
self:F2()
return self.Set
end
function SET_BASE:Add(ObjectName,Object)
self:F(ObjectName)
self.Set[ObjectName]=Object
table.insert(self.Index,ObjectName)
end
function SET_BASE:AddObject(Object)
self:F2(Object.ObjectName)
self:T(Object.UnitName)
self:T(Object.ObjectName)
self:Add(Object.ObjectName,Object)
end
function SET_BASE:Remove(ObjectName)
local Object=self.Set[ObjectName]
self:F3({ObjectName,Object})
if Object then
for Index,Key in ipairs(self.Index)do
if Key==ObjectName then
table.remove(self.Index,Index)
self.Set[ObjectName]=nil
break
end
end
end
end
function SET_BASE:Get(ObjectName)
self:F(ObjectName)
local Object=self.Set[ObjectName]
self:T3({ObjectName,Object})
return Object
end
function SET_BASE:GetFirst()
local ObjectName=self.Index[1]
local FirstObject=self.Set[ObjectName]
self:T3({FirstObject})
return FirstObject
end
function SET_BASE:GetLast()
local ObjectName=self.Index[#self.Index]
local LastObject=self.Set[ObjectName]
self:T3({LastObject})
return LastObject
end
function SET_BASE:GetRandom()
local RandomItem=self.Set[self.Index[math.random(#self.Index)]]
self:T3({RandomItem})
return RandomItem
end
function SET_BASE:Count()
return self.Index and#self.Index or 0
end
function SET_BASE:SetDatabase(BaseSet)
local OtherFilter=routines.utils.deepCopy(BaseSet.Filter)
self.Filter=OtherFilter
self.Database=BaseSet:GetSet()
return self
end
function SET_BASE:SetIteratorIntervals(YieldInterval,TimeInterval)
self.YieldInterval=YieldInterval
self.TimeInterval=TimeInterval
return self
end
function SET_BASE:FilterOnce()
for ObjectName,Object in pairs(self.Database)do
if self:IsIncludeObject(Object)then
self:Add(ObjectName,Object)
end
end
return self
end
function SET_BASE:_FilterStart()
for ObjectName,Object in pairs(self.Database)do
if self:IsIncludeObject(Object)then
self:E({"Adding Object:",ObjectName})
self:Add(ObjectName,Object)
end
end
self:HandleEvent(EVENTS.Birth,self._EventOnBirth)
self:HandleEvent(EVENTS.Dead,self._EventOnDeadOrCrash)
self:HandleEvent(EVENTS.Crash,self._EventOnDeadOrCrash)
self:HandleEvent(EVENTS.PlayerEnterUnit,self._EventOnPlayerEnterUnit)
self:HandleEvent(EVENTS.PlayerLeaveUnit,self._EventOnPlayerLeaveUnit)
return self
end
function SET_BASE:FilterDeads()
self:HandleEvent(EVENTS.Dead,self._EventOnDeadOrCrash)
return self
end
function SET_BASE:FilterCrashes()
self:HandleEvent(EVENTS.Crash,self._EventOnDeadOrCrash)
return self
end
function SET_BASE:FilterStop()
self:UnHandleEvent(EVENTS.Birth)
self:UnHandleEvent(EVENTS.Dead)
self:UnHandleEvent(EVENTS.Crash)
return self
end
function SET_BASE:FindNearestObjectFromPointVec2(PointVec2)
self:F2(PointVec2)
local NearestObject=nil
local ClosestDistance=nil
for ObjectID,ObjectData in pairs(self.Set)do
if NearestObject==nil then
NearestObject=ObjectData
ClosestDistance=PointVec2:DistanceFromVec2(ObjectData:GetVec2())
else
local Distance=PointVec2:DistanceFromVec2(ObjectData:GetVec2())
if Distance<ClosestDistance then
NearestObject=ObjectData
ClosestDistance=Distance
end
end
end
return NearestObject
end
function SET_BASE:_EventOnBirth(Event)
self:F3({Event})
if Event.IniDCSUnit then
local ObjectName,Object=self:AddInDatabase(Event)
self:T3(ObjectName,Object)
if Object and self:IsIncludeObject(Object)then
self:Add(ObjectName,Object)
end
end
end
function SET_BASE:_EventOnDeadOrCrash(Event)
self:F3({Event})
if Event.IniDCSUnit then
local ObjectName,Object=self:FindInDatabase(Event)
if ObjectName then
self:Remove(ObjectName)
end
end
end
function SET_BASE:_EventOnPlayerEnterUnit(Event)
self:F3({Event})
if Event.IniDCSUnit then
local ObjectName,Object=self:AddInDatabase(Event)
self:T3(ObjectName,Object)
if self:IsIncludeObject(Object)then
self:Add(ObjectName,Object)
end
end
end
function SET_BASE:_EventOnPlayerLeaveUnit(Event)
self:F3({Event})
local ObjectName=Event.IniDCSUnit
if Event.IniDCSUnit then
if Event.IniDCSGroup then
local GroupUnits=Event.IniDCSGroup:getUnits()
local PlayerCount=0
for _,DCSUnit in pairs(GroupUnits)do
if DCSUnit~=Event.IniDCSUnit then
if DCSUnit:getPlayerName()~=nil then
PlayerCount=PlayerCount+1
end
end
end
self:E(PlayerCount)
if PlayerCount==0 then
self:Remove(Event.IniDCSGroupName)
end
end
end
end
function SET_BASE:ForEach(IteratorFunction,arg,Set,Function,FunctionArguments)
self:F3(arg)
Set=Set or self:GetSet()
arg=arg or{}
local function CoRoutine()
local Count=0
for ObjectID,ObjectData in pairs(Set)do
local Object=ObjectData
self:T3(Object)
if Function then
if Function(unpack(FunctionArguments),Object)==true then
IteratorFunction(Object,unpack(arg))
end
else
IteratorFunction(Object,unpack(arg))
end
Count=Count+1
end
return true
end
local co=CoRoutine
local function Schedule()
local status,res=co()
self:T3({status,res})
if status==false then
error(res)
end
if res==false then
return true
end
return false
end
Schedule()
return self
end
function SET_BASE:IsIncludeObject(Object)
self:F3(Object)
return true
end
function SET_BASE:GetObjectNames()
self:F3()
local ObjectNames=""
for ObjectName,Object in pairs(self.Set)do
ObjectNames=ObjectNames..ObjectName..", "
end
return ObjectNames
end
function SET_BASE:Flush()
self:F3()
local ObjectNames=""
for ObjectName,Object in pairs(self.Set)do
ObjectNames=ObjectNames..ObjectName..", "
end
self:E({"Objects in Set:",ObjectNames})
return ObjectNames
end
SET_GROUP={
ClassName="SET_GROUP",
Filter={
Coalitions=nil,
Categories=nil,
Countries=nil,
GroupPrefixes=nil,
},
FilterMeta={
Coalitions={
red=coalition.side.RED,
blue=coalition.side.BLUE,
neutral=coalition.side.NEUTRAL,
},
Categories={
plane=Group.Category.AIRPLANE,
helicopter=Group.Category.HELICOPTER,
ground=Group.Category.GROUND,
ship=Group.Category.SHIP,
structure=Group.Category.STRUCTURE,
},
},
}
function SET_GROUP:New()
local self=BASE:Inherit(self,SET_BASE:New(_DATABASE.GROUPS))
return self
end
function SET_GROUP:AddGroupsByName(AddGroupNames)
local AddGroupNamesArray=(type(AddGroupNames)=="table")and AddGroupNames or{AddGroupNames}
for AddGroupID,AddGroupName in pairs(AddGroupNamesArray)do
self:Add(AddGroupName,GROUP:FindByName(AddGroupName))
end
return self
end
function SET_GROUP:RemoveGroupsByName(RemoveGroupNames)
local RemoveGroupNamesArray=(type(RemoveGroupNames)=="table")and RemoveGroupNames or{RemoveGroupNames}
for RemoveGroupID,RemoveGroupName in pairs(RemoveGroupNamesArray)do
self:Remove(RemoveGroupName.GroupName)
end
return self
end
function SET_GROUP:FindGroup(GroupName)
local GroupFound=self.Set[GroupName]
return GroupFound
end
function SET_GROUP:FindNearestGroupFromPointVec2(PointVec2)
self:F2(PointVec2)
local NearestGroup=nil
local ClosestDistance=nil
for ObjectID,ObjectData in pairs(self.Set)do
if NearestGroup==nil then
NearestGroup=ObjectData
ClosestDistance=PointVec2:DistanceFromVec2(ObjectData:GetVec2())
else
local Distance=PointVec2:DistanceFromVec2(ObjectData:GetVec2())
if Distance<ClosestDistance then
NearestGroup=ObjectData
ClosestDistance=Distance
end
end
end
return NearestGroup
end
function SET_GROUP:FilterCoalitions(Coalitions)
if not self.Filter.Coalitions then
self.Filter.Coalitions={}
end
if type(Coalitions)~="table"then
Coalitions={Coalitions}
end
for CoalitionID,Coalition in pairs(Coalitions)do
self.Filter.Coalitions[Coalition]=Coalition
end
return self
end
function SET_GROUP:FilterCategories(Categories)
if not self.Filter.Categories then
self.Filter.Categories={}
end
if type(Categories)~="table"then
Categories={Categories}
end
for CategoryID,Category in pairs(Categories)do
self.Filter.Categories[Category]=Category
end
return self
end
function SET_GROUP:FilterCategoryGround()
self:FilterCategories("ground")
return self
end
function SET_GROUP:FilterCategoryAirplane()
self:FilterCategories("plane")
return self
end
function SET_GROUP:FilterCategoryHelicopter()
self:FilterCategories("helicopter")
return self
end
function SET_GROUP:FilterCategoryShip()
self:FilterCategories("ship")
return self
end
function SET_GROUP:FilterCategoryStructure()
self:FilterCategories("structure")
return self
end
function SET_GROUP:FilterCountries(Countries)
if not self.Filter.Countries then
self.Filter.Countries={}
end
if type(Countries)~="table"then
Countries={Countries}
end
for CountryID,Country in pairs(Countries)do
self.Filter.Countries[Country]=Country
end
return self
end
function SET_GROUP:FilterPrefixes(Prefixes)
if not self.Filter.GroupPrefixes then
self.Filter.GroupPrefixes={}
end
if type(Prefixes)~="table"then
Prefixes={Prefixes}
end
for PrefixID,Prefix in pairs(Prefixes)do
self.Filter.GroupPrefixes[Prefix]=Prefix
end
return self
end
function SET_GROUP:FilterStart()
if _DATABASE then
self:_FilterStart()
end
return self
end
function SET_GROUP:_EventOnDeadOrCrash(Event)
self:F3({Event})
if Event.IniDCSUnit then
local ObjectName,Object=self:FindInDatabase(Event)
if ObjectName then
if Event.IniDCSGroup:getSize()==1 then
self:Remove(ObjectName)
end
end
end
end
function SET_GROUP:AddInDatabase(Event)
self:F3({Event})
if Event.IniObjectCategory==1 then
if not self.Database[Event.IniDCSGroupName]then
self.Database[Event.IniDCSGroupName]=GROUP:Register(Event.IniDCSGroupName)
self:T3(self.Database[Event.IniDCSGroupName])
end
end
return Event.IniDCSGroupName,self.Database[Event.IniDCSGroupName]
end
function SET_GROUP:FindInDatabase(Event)
self:F3({Event})
return Event.IniDCSGroupName,self.Database[Event.IniDCSGroupName]
end
function SET_GROUP:ForEachGroup(IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set)
return self
end
function SET_GROUP:ForEachGroupCompletelyInZone(ZoneObject,IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set,
function(ZoneObject,GroupObject)
if GroupObject:IsCompletelyInZone(ZoneObject)then
return true
else
return false
end
end,{ZoneObject})
return self
end
function SET_GROUP:ForEachGroupPartlyInZone(ZoneObject,IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set,
function(ZoneObject,GroupObject)
if GroupObject:IsPartlyInZone(ZoneObject)then
return true
else
return false
end
end,{ZoneObject})
return self
end
function SET_GROUP:ForEachGroupNotInZone(ZoneObject,IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set,
function(ZoneObject,GroupObject)
if GroupObject:IsNotInZone(ZoneObject)then
return true
else
return false
end
end,{ZoneObject})
return self
end
function SET_GROUP:AllCompletelyInZone(Zone)
self:F2(Zone)
local Set=self:GetSet()
for GroupID,GroupData in pairs(Set)do
if not GroupData:IsCompletelyInZone(Zone)then
return false
end
end
return true
end
function SET_GROUP:AnyCompletelyInZone(Zone)
self:F2(Zone)
local Set=self:GetSet()
for GroupID,GroupData in pairs(Set)do
if GroupData:IsCompletelyInZone(Zone)then
return true
end
end
return false
end
function SET_GROUP:AnyInZone(Zone)
self:F2(Zone)
local Set=self:GetSet()
for GroupID,GroupData in pairs(Set)do
if GroupData:IsPartlyInZone(Zone)or GroupData:IsCompletelyInZone(Zone)then
return true
end
end
return false
end
function SET_GROUP:AnyPartlyInZone(Zone)
self:F2(Zone)
local IsPartlyInZone=false
local Set=self:GetSet()
for GroupID,GroupData in pairs(Set)do
if GroupData:IsCompletelyInZone(Zone)then
return false
elseif GroupData:IsPartlyInZone(Zone)then
IsPartlyInZone=true
end
end
if IsPartlyInZone then
return true
else
return false
end
end
function SET_GROUP:NoneInZone(Zone)
self:F2(Zone)
local Set=self:GetSet()
for GroupID,GroupData in pairs(Set)do
if not GroupData:IsNotInZone(Zone)then
return false
end
end
return true
end
function SET_GROUP:CountInZone(Zone)
self:F2(Zone)
local Count=0
local Set=self:GetSet()
for GroupID,GroupData in pairs(Set)do
if GroupData:IsCompletelyInZone(Zone)then
Count=Count+1
end
end
return Count
end
function SET_GROUP:CountUnitInZone(Zone)
self:F2(Zone)
local Count=0
local Set=self:GetSet()
for GroupID,GroupData in pairs(Set)do
Count=Count+GroupData:CountInZone(Zone)
end
return Count
end
function SET_GROUP:IsIncludeObject(MooseGroup)
self:F2(MooseGroup)
local MooseGroupInclude=true
if self.Filter.Coalitions then
local MooseGroupCoalition=false
for CoalitionID,CoalitionName in pairs(self.Filter.Coalitions)do
self:T3({"Coalition:",MooseGroup:GetCoalition(),self.FilterMeta.Coalitions[CoalitionName],CoalitionName})
if self.FilterMeta.Coalitions[CoalitionName]and self.FilterMeta.Coalitions[CoalitionName]==MooseGroup:GetCoalition()then
MooseGroupCoalition=true
end
end
MooseGroupInclude=MooseGroupInclude and MooseGroupCoalition
end
if self.Filter.Categories then
local MooseGroupCategory=false
for CategoryID,CategoryName in pairs(self.Filter.Categories)do
self:T3({"Category:",MooseGroup:GetCategory(),self.FilterMeta.Categories[CategoryName],CategoryName})
if self.FilterMeta.Categories[CategoryName]and self.FilterMeta.Categories[CategoryName]==MooseGroup:GetCategory()then
MooseGroupCategory=true
end
end
MooseGroupInclude=MooseGroupInclude and MooseGroupCategory
end
if self.Filter.Countries then
local MooseGroupCountry=false
for CountryID,CountryName in pairs(self.Filter.Countries)do
self:T3({"Country:",MooseGroup:GetCountry(),CountryName})
if country.id[CountryName]==MooseGroup:GetCountry()then
MooseGroupCountry=true
end
end
MooseGroupInclude=MooseGroupInclude and MooseGroupCountry
end
if self.Filter.GroupPrefixes then
local MooseGroupPrefix=false
for GroupPrefixId,GroupPrefix in pairs(self.Filter.GroupPrefixes)do
self:T3({"Prefix:",string.find(MooseGroup:GetName(),GroupPrefix,1),GroupPrefix})
if string.find(MooseGroup:GetName(),GroupPrefix:gsub("-","%%-"),1)then
MooseGroupPrefix=true
end
end
MooseGroupInclude=MooseGroupInclude and MooseGroupPrefix
end
self:T2(MooseGroupInclude)
return MooseGroupInclude
end
SET_UNIT={
ClassName="SET_UNIT",
Units={},
Filter={
Coalitions=nil,
Categories=nil,
Types=nil,
Countries=nil,
UnitPrefixes=nil,
},
FilterMeta={
Coalitions={
red=coalition.side.RED,
blue=coalition.side.BLUE,
neutral=coalition.side.NEUTRAL,
},
Categories={
plane=Unit.Category.AIRPLANE,
helicopter=Unit.Category.HELICOPTER,
ground=Unit.Category.GROUND_UNIT,
ship=Unit.Category.SHIP,
structure=Unit.Category.STRUCTURE,
},
},
}
function SET_UNIT:New()
local self=BASE:Inherit(self,SET_BASE:New(_DATABASE.UNITS))
return self
end
function SET_UNIT:AddUnit(AddUnit)
self:F2(AddUnit:GetName())
self:Add(AddUnit:GetName(),AddUnit)
return self
end
function SET_UNIT:AddUnitsByName(AddUnitNames)
local AddUnitNamesArray=(type(AddUnitNames)=="table")and AddUnitNames or{AddUnitNames}
self:T(AddUnitNamesArray)
for AddUnitID,AddUnitName in pairs(AddUnitNamesArray)do
self:Add(AddUnitName,UNIT:FindByName(AddUnitName))
end
return self
end
function SET_UNIT:RemoveUnitsByName(RemoveUnitNames)
local RemoveUnitNamesArray=(type(RemoveUnitNames)=="table")and RemoveUnitNames or{RemoveUnitNames}
for RemoveUnitID,RemoveUnitName in pairs(RemoveUnitNamesArray)do
self:Remove(RemoveUnitName)
end
return self
end
function SET_UNIT:FindUnit(UnitName)
local UnitFound=self.Set[UnitName]
return UnitFound
end
function SET_UNIT:FilterCoalitions(Coalitions)
if not self.Filter.Coalitions then
self.Filter.Coalitions={}
end
if type(Coalitions)~="table"then
Coalitions={Coalitions}
end
for CoalitionID,Coalition in pairs(Coalitions)do
self.Filter.Coalitions[Coalition]=Coalition
end
return self
end
function SET_UNIT:FilterCategories(Categories)
if not self.Filter.Categories then
self.Filter.Categories={}
end
if type(Categories)~="table"then
Categories={Categories}
end
for CategoryID,Category in pairs(Categories)do
self.Filter.Categories[Category]=Category
end
return self
end
function SET_UNIT:FilterTypes(Types)
if not self.Filter.Types then
self.Filter.Types={}
end
if type(Types)~="table"then
Types={Types}
end
for TypeID,Type in pairs(Types)do
self.Filter.Types[Type]=Type
end
return self
end
function SET_UNIT:FilterCountries(Countries)
if not self.Filter.Countries then
self.Filter.Countries={}
end
if type(Countries)~="table"then
Countries={Countries}
end
for CountryID,Country in pairs(Countries)do
self.Filter.Countries[Country]=Country
end
return self
end
function SET_UNIT:FilterPrefixes(Prefixes)
if not self.Filter.UnitPrefixes then
self.Filter.UnitPrefixes={}
end
if type(Prefixes)~="table"then
Prefixes={Prefixes}
end
for PrefixID,Prefix in pairs(Prefixes)do
self.Filter.UnitPrefixes[Prefix]=Prefix
end
return self
end
function SET_UNIT:FilterHasRadar(RadarTypes)
self.Filter.RadarTypes=self.Filter.RadarTypes or{}
if type(RadarTypes)~="table"then
RadarTypes={RadarTypes}
end
for RadarTypeID,RadarType in pairs(RadarTypes)do
self.Filter.RadarTypes[RadarType]=RadarType
end
return self
end
function SET_UNIT:FilterHasSEAD()
self.Filter.SEAD=true
return self
end
function SET_UNIT:FilterStart()
if _DATABASE then
self:_FilterStart()
end
return self
end
function SET_UNIT:AddInDatabase(Event)
self:F3({Event})
if Event.IniObjectCategory==1 then
if not self.Database[Event.IniDCSUnitName]then
self.Database[Event.IniDCSUnitName]=UNIT:Register(Event.IniDCSUnitName)
self:T3(self.Database[Event.IniDCSUnitName])
end
end
return Event.IniDCSUnitName,self.Database[Event.IniDCSUnitName]
end
function SET_UNIT:FindInDatabase(Event)
self:F2({Event.IniDCSUnitName,self.Set[Event.IniDCSUnitName],Event})
return Event.IniDCSUnitName,self.Set[Event.IniDCSUnitName]
end
function SET_UNIT:ForEachUnit(IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set)
return self
end
function SET_UNIT:ForEachUnitPerThreatLevel(FromThreatLevel,ToThreatLevel,IteratorFunction,...)
self:F2(arg)
local ThreatLevelSet={}
if self:Count()~=0 then
for UnitName,UnitObject in pairs(self.Set)do
local Unit=UnitObject
local ThreatLevel=Unit:GetThreatLevel()
ThreatLevelSet[ThreatLevel]=ThreatLevelSet[ThreatLevel]or{}
ThreatLevelSet[ThreatLevel].Set=ThreatLevelSet[ThreatLevel].Set or{}
ThreatLevelSet[ThreatLevel].Set[UnitName]=UnitObject
self:E({ThreatLevel=ThreatLevel,ThreatLevelSet=ThreatLevelSet[ThreatLevel].Set})
end
local ThreatLevelIncrement=FromThreatLevel<=ToThreatLevel and 1 or-1
for ThreatLevel=FromThreatLevel,ToThreatLevel,ThreatLevelIncrement do
self:E({ThreatLevel=ThreatLevel})
local ThreatLevelItem=ThreatLevelSet[ThreatLevel]
if ThreatLevelItem then
self:ForEach(IteratorFunction,arg,ThreatLevelItem.Set)
end
end
end
return self
end
function SET_UNIT:ForEachUnitCompletelyInZone(ZoneObject,IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set,
function(ZoneObject,UnitObject)
if UnitObject:IsInZone(ZoneObject)then
return true
else
return false
end
end,{ZoneObject})
return self
end
function SET_UNIT:ForEachUnitNotInZone(ZoneObject,IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set,
function(ZoneObject,UnitObject)
if UnitObject:IsNotInZone(ZoneObject)then
return true
else
return false
end
end,{ZoneObject})
return self
end
function SET_UNIT:GetUnitTypes()
self:F2()
local MT={}
local UnitTypes={}
for UnitID,UnitData in pairs(self:GetSet())do
local TextUnit=UnitData
if TextUnit:IsAlive()then
local UnitType=TextUnit:GetTypeName()
if not UnitTypes[UnitType]then
UnitTypes[UnitType]=1
else
UnitTypes[UnitType]=UnitTypes[UnitType]+1
end
end
end
for UnitTypeID,UnitType in pairs(UnitTypes)do
MT[#MT+1]=UnitType.." of "..UnitTypeID
end
return UnitTypes
end
function SET_UNIT:GetUnitTypesText()
self:F2()
local MT={}
local UnitTypes=self:GetUnitTypes()
for UnitTypeID,UnitType in pairs(UnitTypes)do
MT[#MT+1]=UnitType.." of "..UnitTypeID
end
return table.concat(MT,", ")
end
function SET_UNIT:GetUnitThreatLevels()
self:F2()
local UnitThreatLevels={}
for UnitID,UnitData in pairs(self:GetSet())do
local ThreatUnit=UnitData
if ThreatUnit:IsAlive()then
local UnitThreatLevel,UnitThreatLevelText=ThreatUnit:GetThreatLevel()
local ThreatUnitName=ThreatUnit:GetName()
UnitThreatLevels[UnitThreatLevel]=UnitThreatLevels[UnitThreatLevel]or{}
UnitThreatLevels[UnitThreatLevel].UnitThreatLevelText=UnitThreatLevelText
UnitThreatLevels[UnitThreatLevel].Units=UnitThreatLevels[UnitThreatLevel].Units or{}
UnitThreatLevels[UnitThreatLevel].Units[ThreatUnitName]=ThreatUnit
end
end
return UnitThreatLevels
end
function SET_UNIT:CalculateThreatLevelA2G()
local MaxThreatLevelA2G=0
local MaxThreatText=""
for UnitName,UnitData in pairs(self:GetSet())do
local ThreatUnit=UnitData
local ThreatLevelA2G,ThreatText=ThreatUnit:GetThreatLevel()
if ThreatLevelA2G>MaxThreatLevelA2G then
MaxThreatLevelA2G=ThreatLevelA2G
MaxThreatText=ThreatText
end
end
self:F({MaxThreatLevelA2G=MaxThreatLevelA2G,MaxThreatText=MaxThreatText})
return MaxThreatLevelA2G,MaxThreatText
end
function SET_UNIT:GetCoordinate()
local Coordinate=self:GetFirst():GetCoordinate()
local x1=Coordinate.x
local x2=Coordinate.x
local y1=Coordinate.y
local y2=Coordinate.y
local z1=Coordinate.z
local z2=Coordinate.z
local MaxVelocity=0
local AvgHeading=nil
local MovingCount=0
for UnitName,UnitData in pairs(self:GetSet())do
local Unit=UnitData
local Coordinate=Unit:GetCoordinate()
x1=(Coordinate.x<x1)and Coordinate.x or x1
x2=(Coordinate.x>x2)and Coordinate.x or x2
y1=(Coordinate.y<y1)and Coordinate.y or y1
y2=(Coordinate.y>y2)and Coordinate.y or y2
z1=(Coordinate.y<z1)and Coordinate.z or z1
z2=(Coordinate.y>z2)and Coordinate.z or z2
local Velocity=Coordinate:GetVelocity()
if Velocity~=0 then
MaxVelocity=(MaxVelocity<Velocity)and Velocity or MaxVelocity
local Heading=Coordinate:GetHeading()
AvgHeading=AvgHeading and(AvgHeading+Heading)or Heading
MovingCount=MovingCount+1
end
end
AvgHeading=AvgHeading and(AvgHeading/MovingCount)
Coordinate.x=(x2-x1)/2+x1
Coordinate.y=(y2-y1)/2+y1
Coordinate.z=(z2-z1)/2+z1
Coordinate:SetHeading(AvgHeading)
Coordinate:SetVelocity(MaxVelocity)
self:F({Coordinate=Coordinate})
return Coordinate
end
function SET_UNIT:GetVelocity()
local Coordinate=self:GetFirst():GetCoordinate()
local MaxVelocity=0
for UnitName,UnitData in pairs(self:GetSet())do
local Unit=UnitData
local Coordinate=Unit:GetCoordinate()
local Velocity=Coordinate:GetVelocity()
if Velocity~=0 then
MaxVelocity=(MaxVelocity<Velocity)and Velocity or MaxVelocity
end
end
self:F({MaxVelocity=MaxVelocity})
return MaxVelocity
end
function SET_UNIT:GetHeading()
local HeadingSet=nil
local MovingCount=0
for UnitName,UnitData in pairs(self:GetSet())do
local Unit=UnitData
local Coordinate=Unit:GetCoordinate()
local Velocity=Coordinate:GetVelocity()
if Velocity~=0 then
local Heading=Coordinate:GetHeading()
if HeadingSet==nil then
HeadingSet=Heading
else
local HeadingDiff=(HeadingSet-Heading+180+360)%360-180
HeadingDiff=math.abs(HeadingDiff)
if HeadingDiff>5 then
HeadingSet=nil
break
end
end
end
end
return HeadingSet
end
function SET_UNIT:HasRadar(RadarType)
self:F2(RadarType)
local RadarCount=0
for UnitID,UnitData in pairs(self:GetSet())do
local UnitSensorTest=UnitData
local HasSensors
if RadarType then
HasSensors=UnitSensorTest:HasSensors(Unit.SensorType.RADAR,RadarType)
else
HasSensors=UnitSensorTest:HasSensors(Unit.SensorType.RADAR)
end
self:T3(HasSensors)
if HasSensors then
RadarCount=RadarCount+1
end
end
return RadarCount
end
function SET_UNIT:HasSEAD()
self:F2()
local SEADCount=0
for UnitID,UnitData in pairs(self:GetSet())do
local UnitSEAD=UnitData
if UnitSEAD:IsAlive()then
local UnitSEADAttributes=UnitSEAD:GetDesc().attributes
local HasSEAD=UnitSEAD:HasSEAD()
self:T3(HasSEAD)
if HasSEAD then
SEADCount=SEADCount+1
end
end
end
return SEADCount
end
function SET_UNIT:HasGroundUnits()
self:F2()
local GroundUnitCount=0
for UnitID,UnitData in pairs(self:GetSet())do
local UnitTest=UnitData
if UnitTest:IsGround()then
GroundUnitCount=GroundUnitCount+1
end
end
return GroundUnitCount
end
function SET_UNIT:HasFriendlyUnits(FriendlyCoalition)
self:F2()
local FriendlyUnitCount=0
for UnitID,UnitData in pairs(self:GetSet())do
local UnitTest=UnitData
if UnitTest:IsFriendly(FriendlyCoalition)then
FriendlyUnitCount=FriendlyUnitCount+1
end
end
return FriendlyUnitCount
end
function SET_UNIT:IsIncludeObject(MUnit)
self:F2(MUnit)
local MUnitInclude=true
if self.Filter.Coalitions then
local MUnitCoalition=false
for CoalitionID,CoalitionName in pairs(self.Filter.Coalitions)do
self:T3({"Coalition:",MUnit:GetCoalition(),self.FilterMeta.Coalitions[CoalitionName],CoalitionName})
if self.FilterMeta.Coalitions[CoalitionName]and self.FilterMeta.Coalitions[CoalitionName]==MUnit:GetCoalition()then
MUnitCoalition=true
end
end
MUnitInclude=MUnitInclude and MUnitCoalition
end
if self.Filter.Categories then
local MUnitCategory=false
for CategoryID,CategoryName in pairs(self.Filter.Categories)do
self:T3({"Category:",MUnit:GetDesc().category,self.FilterMeta.Categories[CategoryName],CategoryName})
if self.FilterMeta.Categories[CategoryName]and self.FilterMeta.Categories[CategoryName]==MUnit:GetDesc().category then
MUnitCategory=true
end
end
MUnitInclude=MUnitInclude and MUnitCategory
end
if self.Filter.Types then
local MUnitType=false
for TypeID,TypeName in pairs(self.Filter.Types)do
self:T3({"Type:",MUnit:GetTypeName(),TypeName})
if TypeName==MUnit:GetTypeName()then
MUnitType=true
end
end
MUnitInclude=MUnitInclude and MUnitType
end
if self.Filter.Countries then
local MUnitCountry=false
for CountryID,CountryName in pairs(self.Filter.Countries)do
self:T3({"Country:",MUnit:GetCountry(),CountryName})
if country.id[CountryName]==MUnit:GetCountry()then
MUnitCountry=true
end
end
MUnitInclude=MUnitInclude and MUnitCountry
end
if self.Filter.UnitPrefixes then
local MUnitPrefix=false
for UnitPrefixId,UnitPrefix in pairs(self.Filter.UnitPrefixes)do
self:T3({"Prefix:",string.find(MUnit:GetName(),UnitPrefix,1),UnitPrefix})
if string.find(MUnit:GetName(),UnitPrefix,1)then
MUnitPrefix=true
end
end
MUnitInclude=MUnitInclude and MUnitPrefix
end
if self.Filter.RadarTypes then
local MUnitRadar=false
for RadarTypeID,RadarType in pairs(self.Filter.RadarTypes)do
self:T3({"Radar:",RadarType})
if MUnit:HasSensors(Unit.SensorType.RADAR,RadarType)==true then
if MUnit:GetRadar()==true then
self:T3("RADAR Found")
end
MUnitRadar=true
end
end
MUnitInclude=MUnitInclude and MUnitRadar
end
if self.Filter.SEAD then
local MUnitSEAD=false
if MUnit:HasSEAD()==true then
self:T3("SEAD Found")
MUnitSEAD=true
end
MUnitInclude=MUnitInclude and MUnitSEAD
end
self:T2(MUnitInclude)
return MUnitInclude
end
function SET_UNIT:GetTypeNames(Delimiter)
Delimiter=Delimiter or", "
local TypeReport=REPORT:New()
local Types={}
for UnitName,UnitData in pairs(self:GetSet())do
local Unit=UnitData
local UnitTypeName=Unit:GetTypeName()
if not Types[UnitTypeName]then
Types[UnitTypeName]=UnitTypeName
TypeReport:Add(UnitTypeName)
end
end
return TypeReport:Text(Delimiter)
end
SET_CLIENT={
ClassName="SET_CLIENT",
Clients={},
Filter={
Coalitions=nil,
Categories=nil,
Types=nil,
Countries=nil,
ClientPrefixes=nil,
},
FilterMeta={
Coalitions={
red=coalition.side.RED,
blue=coalition.side.BLUE,
neutral=coalition.side.NEUTRAL,
},
Categories={
plane=Unit.Category.AIRPLANE,
helicopter=Unit.Category.HELICOPTER,
ground=Unit.Category.GROUND_UNIT,
ship=Unit.Category.SHIP,
structure=Unit.Category.STRUCTURE,
},
},
}
function SET_CLIENT:New()
local self=BASE:Inherit(self,SET_BASE:New(_DATABASE.CLIENTS))
return self
end
function SET_CLIENT:AddClientsByName(AddClientNames)
local AddClientNamesArray=(type(AddClientNames)=="table")and AddClientNames or{AddClientNames}
for AddClientID,AddClientName in pairs(AddClientNamesArray)do
self:Add(AddClientName,CLIENT:FindByName(AddClientName))
end
return self
end
function SET_CLIENT:RemoveClientsByName(RemoveClientNames)
local RemoveClientNamesArray=(type(RemoveClientNames)=="table")and RemoveClientNames or{RemoveClientNames}
for RemoveClientID,RemoveClientName in pairs(RemoveClientNamesArray)do
self:Remove(RemoveClientName.ClientName)
end
return self
end
function SET_CLIENT:FindClient(ClientName)
local ClientFound=self.Set[ClientName]
return ClientFound
end
function SET_CLIENT:FilterCoalitions(Coalitions)
if not self.Filter.Coalitions then
self.Filter.Coalitions={}
end
if type(Coalitions)~="table"then
Coalitions={Coalitions}
end
for CoalitionID,Coalition in pairs(Coalitions)do
self.Filter.Coalitions[Coalition]=Coalition
end
return self
end
function SET_CLIENT:FilterCategories(Categories)
if not self.Filter.Categories then
self.Filter.Categories={}
end
if type(Categories)~="table"then
Categories={Categories}
end
for CategoryID,Category in pairs(Categories)do
self.Filter.Categories[Category]=Category
end
return self
end
function SET_CLIENT:FilterTypes(Types)
if not self.Filter.Types then
self.Filter.Types={}
end
if type(Types)~="table"then
Types={Types}
end
for TypeID,Type in pairs(Types)do
self.Filter.Types[Type]=Type
end
return self
end
function SET_CLIENT:FilterCountries(Countries)
if not self.Filter.Countries then
self.Filter.Countries={}
end
if type(Countries)~="table"then
Countries={Countries}
end
for CountryID,Country in pairs(Countries)do
self.Filter.Countries[Country]=Country
end
return self
end
function SET_CLIENT:FilterPrefixes(Prefixes)
if not self.Filter.ClientPrefixes then
self.Filter.ClientPrefixes={}
end
if type(Prefixes)~="table"then
Prefixes={Prefixes}
end
for PrefixID,Prefix in pairs(Prefixes)do
self.Filter.ClientPrefixes[Prefix]=Prefix
end
return self
end
function SET_CLIENT:FilterStart()
if _DATABASE then
self:_FilterStart()
end
return self
end
function SET_CLIENT:AddInDatabase(Event)
self:F3({Event})
return Event.IniDCSUnitName,self.Database[Event.IniDCSUnitName]
end
function SET_CLIENT:FindInDatabase(Event)
self:F3({Event})
return Event.IniDCSUnitName,self.Database[Event.IniDCSUnitName]
end
function SET_CLIENT:ForEachClient(IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set)
return self
end
function SET_CLIENT:ForEachClientInZone(ZoneObject,IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set,
function(ZoneObject,ClientObject)
if ClientObject:IsInZone(ZoneObject)then
return true
else
return false
end
end,{ZoneObject})
return self
end
function SET_CLIENT:ForEachClientNotInZone(ZoneObject,IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set,
function(ZoneObject,ClientObject)
if ClientObject:IsNotInZone(ZoneObject)then
return true
else
return false
end
end,{ZoneObject})
return self
end
function SET_CLIENT:IsIncludeObject(MClient)
self:F2(MClient)
local MClientInclude=true
if MClient then
local MClientName=MClient.UnitName
if self.Filter.Coalitions then
local MClientCoalition=false
for CoalitionID,CoalitionName in pairs(self.Filter.Coalitions)do
local ClientCoalitionID=_DATABASE:GetCoalitionFromClientTemplate(MClientName)
self:T3({"Coalition:",ClientCoalitionID,self.FilterMeta.Coalitions[CoalitionName],CoalitionName})
if self.FilterMeta.Coalitions[CoalitionName]and self.FilterMeta.Coalitions[CoalitionName]==ClientCoalitionID then
MClientCoalition=true
end
end
self:T({"Evaluated Coalition",MClientCoalition})
MClientInclude=MClientInclude and MClientCoalition
end
if self.Filter.Categories then
local MClientCategory=false
for CategoryID,CategoryName in pairs(self.Filter.Categories)do
local ClientCategoryID=_DATABASE:GetCategoryFromClientTemplate(MClientName)
self:T3({"Category:",ClientCategoryID,self.FilterMeta.Categories[CategoryName],CategoryName})
if self.FilterMeta.Categories[CategoryName]and self.FilterMeta.Categories[CategoryName]==ClientCategoryID then
MClientCategory=true
end
end
self:T({"Evaluated Category",MClientCategory})
MClientInclude=MClientInclude and MClientCategory
end
if self.Filter.Types then
local MClientType=false
for TypeID,TypeName in pairs(self.Filter.Types)do
self:T3({"Type:",MClient:GetTypeName(),TypeName})
if TypeName==MClient:GetTypeName()then
MClientType=true
end
end
self:T({"Evaluated Type",MClientType})
MClientInclude=MClientInclude and MClientType
end
if self.Filter.Countries then
local MClientCountry=false
for CountryID,CountryName in pairs(self.Filter.Countries)do
local ClientCountryID=_DATABASE:GetCountryFromClientTemplate(MClientName)
self:T3({"Country:",ClientCountryID,country.id[CountryName],CountryName})
if country.id[CountryName]and country.id[CountryName]==ClientCountryID then
MClientCountry=true
end
end
self:T({"Evaluated Country",MClientCountry})
MClientInclude=MClientInclude and MClientCountry
end
if self.Filter.ClientPrefixes then
local MClientPrefix=false
for ClientPrefixId,ClientPrefix in pairs(self.Filter.ClientPrefixes)do
self:T3({"Prefix:",string.find(MClient.UnitName,ClientPrefix,1),ClientPrefix})
if string.find(MClient.UnitName,ClientPrefix,1)then
MClientPrefix=true
end
end
self:T({"Evaluated Prefix",MClientPrefix})
MClientInclude=MClientInclude and MClientPrefix
end
end
self:T2(MClientInclude)
return MClientInclude
end
SET_AIRBASE={
ClassName="SET_AIRBASE",
Airbases={},
Filter={
Coalitions=nil,
},
FilterMeta={
Coalitions={
red=coalition.side.RED,
blue=coalition.side.BLUE,
neutral=coalition.side.NEUTRAL,
},
Categories={
airdrome=Airbase.Category.AIRDROME,
helipad=Airbase.Category.HELIPAD,
ship=Airbase.Category.SHIP,
},
},
}
function SET_AIRBASE:New()
local self=BASE:Inherit(self,SET_BASE:New(_DATABASE.AIRBASES))
return self
end
function SET_AIRBASE:AddAirbasesByName(AddAirbaseNames)
local AddAirbaseNamesArray=(type(AddAirbaseNames)=="table")and AddAirbaseNames or{AddAirbaseNames}
for AddAirbaseID,AddAirbaseName in pairs(AddAirbaseNamesArray)do
self:Add(AddAirbaseName,AIRBASE:FindByName(AddAirbaseName))
end
return self
end
function SET_AIRBASE:RemoveAirbasesByName(RemoveAirbaseNames)
local RemoveAirbaseNamesArray=(type(RemoveAirbaseNames)=="table")and RemoveAirbaseNames or{RemoveAirbaseNames}
for RemoveAirbaseID,RemoveAirbaseName in pairs(RemoveAirbaseNamesArray)do
self:Remove(RemoveAirbaseName.AirbaseName)
end
return self
end
function SET_AIRBASE:FindAirbase(AirbaseName)
local AirbaseFound=self.Set[AirbaseName]
return AirbaseFound
end
function SET_AIRBASE:FilterCoalitions(Coalitions)
if not self.Filter.Coalitions then
self.Filter.Coalitions={}
end
if type(Coalitions)~="table"then
Coalitions={Coalitions}
end
for CoalitionID,Coalition in pairs(Coalitions)do
self.Filter.Coalitions[Coalition]=Coalition
end
return self
end
function SET_AIRBASE:FilterCategories(Categories)
if not self.Filter.Categories then
self.Filter.Categories={}
end
if type(Categories)~="table"then
Categories={Categories}
end
for CategoryID,Category in pairs(Categories)do
self.Filter.Categories[Category]=Category
end
return self
end
function SET_AIRBASE:FilterStart()
if _DATABASE then
self:_FilterStart()
end
return self
end
function SET_AIRBASE:AddInDatabase(Event)
self:F3({Event})
return Event.IniDCSUnitName,self.Database[Event.IniDCSUnitName]
end
function SET_AIRBASE:FindInDatabase(Event)
self:F3({Event})
return Event.IniDCSUnitName,self.Database[Event.IniDCSUnitName]
end
function SET_AIRBASE:ForEachAirbase(IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set)
return self
end
function SET_AIRBASE:FindNearestAirbaseFromPointVec2(PointVec2)
self:F2(PointVec2)
local NearestAirbase=self:FindNearestObjectFromPointVec2(PointVec2)
return NearestAirbase
end
function SET_AIRBASE:IsIncludeObject(MAirbase)
self:F2(MAirbase)
local MAirbaseInclude=true
if MAirbase then
local MAirbaseName=MAirbase:GetName()
if self.Filter.Coalitions then
local MAirbaseCoalition=false
for CoalitionID,CoalitionName in pairs(self.Filter.Coalitions)do
local AirbaseCoalitionID=_DATABASE:GetCoalitionFromAirbase(MAirbaseName)
self:T3({"Coalition:",AirbaseCoalitionID,self.FilterMeta.Coalitions[CoalitionName],CoalitionName})
if self.FilterMeta.Coalitions[CoalitionName]and self.FilterMeta.Coalitions[CoalitionName]==AirbaseCoalitionID then
MAirbaseCoalition=true
end
end
self:T({"Evaluated Coalition",MAirbaseCoalition})
MAirbaseInclude=MAirbaseInclude and MAirbaseCoalition
end
if self.Filter.Categories then
local MAirbaseCategory=false
for CategoryID,CategoryName in pairs(self.Filter.Categories)do
local AirbaseCategoryID=_DATABASE:GetCategoryFromAirbase(MAirbaseName)
self:T3({"Category:",AirbaseCategoryID,self.FilterMeta.Categories[CategoryName],CategoryName})
if self.FilterMeta.Categories[CategoryName]and self.FilterMeta.Categories[CategoryName]==AirbaseCategoryID then
MAirbaseCategory=true
end
end
self:T({"Evaluated Category",MAirbaseCategory})
MAirbaseInclude=MAirbaseInclude and MAirbaseCategory
end
end
self:T2(MAirbaseInclude)
return MAirbaseInclude
end
SET_CARGO={
ClassName="SET_CARGO",
Cargos={},
Filter={
Coalitions=nil,
Types=nil,
Countries=nil,
ClientPrefixes=nil,
},
FilterMeta={
Coalitions={
red=coalition.side.RED,
blue=coalition.side.BLUE,
neutral=coalition.side.NEUTRAL,
},
},
}
function SET_CARGO:New()
local self=BASE:Inherit(self,SET_BASE:New(_DATABASE.CARGOS))
return self
end
function SET_CARGO:AddCargosByName(AddCargoNames)
local AddCargoNamesArray=(type(AddCargoNames)=="table")and AddCargoNames or{AddCargoNames}
for AddCargoID,AddCargoName in pairs(AddCargoNamesArray)do
self:Add(AddCargoName,CARGO:FindByName(AddCargoName))
end
return self
end
function SET_CARGO:RemoveCargosByName(RemoveCargoNames)
local RemoveCargoNamesArray=(type(RemoveCargoNames)=="table")and RemoveCargoNames or{RemoveCargoNames}
for RemoveCargoID,RemoveCargoName in pairs(RemoveCargoNamesArray)do
self:Remove(RemoveCargoName.CargoName)
end
return self
end
function SET_CARGO:FindCargo(CargoName)
local CargoFound=self.Set[CargoName]
return CargoFound
end
function SET_CARGO:FilterCoalitions(Coalitions)
if not self.Filter.Coalitions then
self.Filter.Coalitions={}
end
if type(Coalitions)~="table"then
Coalitions={Coalitions}
end
for CoalitionID,Coalition in pairs(Coalitions)do
self.Filter.Coalitions[Coalition]=Coalition
end
return self
end
function SET_CARGO:FilterTypes(Types)
if not self.Filter.Types then
self.Filter.Types={}
end
if type(Types)~="table"then
Types={Types}
end
for TypeID,Type in pairs(Types)do
self.Filter.Types[Type]=Type
end
return self
end
function SET_CARGO:FilterCountries(Countries)
if not self.Filter.Countries then
self.Filter.Countries={}
end
if type(Countries)~="table"then
Countries={Countries}
end
for CountryID,Country in pairs(Countries)do
self.Filter.Countries[Country]=Country
end
return self
end
function SET_CARGO:FilterPrefixes(Prefixes)
if not self.Filter.CargoPrefixes then
self.Filter.CargoPrefixes={}
end
if type(Prefixes)~="table"then
Prefixes={Prefixes}
end
for PrefixID,Prefix in pairs(Prefixes)do
self.Filter.CargoPrefixes[Prefix]=Prefix
end
return self
end
function SET_CARGO:FilterStart()
if _DATABASE then
self:_FilterStart()
end
self:HandleEvent(EVENTS.NewCargo)
self:HandleEvent(EVENTS.DeleteCargo)
return self
end
function SET_CARGO:AddInDatabase(Event)
self:F3({Event})
return Event.IniDCSUnitName,self.Database[Event.IniDCSUnitName]
end
function SET_CARGO:FindInDatabase(Event)
self:F3({Event})
return Event.IniDCSUnitName,self.Database[Event.IniDCSUnitName]
end
function SET_CARGO:ForEachCargo(IteratorFunction,...)
self:F2(arg)
self:ForEach(IteratorFunction,arg,self.Set)
return self
end
function SET_CARGO:FindNearestCargoFromPointVec2(PointVec2)
self:F2(PointVec2)
local NearestCargo=self:FindNearestObjectFromPointVec2(PointVec2)
return NearestCargo
end
function SET_CARGO:IsIncludeObject(MCargo)
self:F2(MCargo)
local MCargoInclude=true
if MCargo then
local MCargoName=MCargo:GetName()
if self.Filter.Coalitions then
local MCargoCoalition=false
for CoalitionID,CoalitionName in pairs(self.Filter.Coalitions)do
local CargoCoalitionID=MCargo:GetCoalition()
self:T3({"Coalition:",CargoCoalitionID,self.FilterMeta.Coalitions[CoalitionName],CoalitionName})
if self.FilterMeta.Coalitions[CoalitionName]and self.FilterMeta.Coalitions[CoalitionName]==CargoCoalitionID then
MCargoCoalition=true
end
end
self:T({"Evaluated Coalition",MCargoCoalition})
MCargoInclude=MCargoInclude and MCargoCoalition
end
if self.Filter.Types then
local MCargoType=false
for TypeID,TypeName in pairs(self.Filter.Types)do
self:T3({"Type:",MCargo:GetType(),TypeName})
if TypeName==MCargo:GetType()then
MCargoType=true
end
end
self:T({"Evaluated Type",MCargoType})
MCargoInclude=MCargoInclude and MCargoType
end
if self.Filter.CargoPrefixes then
local MCargoPrefix=false
for CargoPrefixId,CargoPrefix in pairs(self.Filter.CargoPrefixes)do
self:T3({"Prefix:",string.find(MCargo.Name,CargoPrefix,1),CargoPrefix})
if string.find(MCargo.Name,CargoPrefix,1)then
MCargoPrefix=true
end
end
self:T({"Evaluated Prefix",MCargoPrefix})
MCargoInclude=MCargoInclude and MCargoPrefix
end
end
self:T2(MCargoInclude)
return MCargoInclude
end
function SET_CARGO:OnEventNewCargo(EventData)
if EventData.Cargo then
if EventData.Cargo and self:IsIncludeObject(EventData.Cargo)then
self:Add(EventData.Cargo.Name,EventData.Cargo)
end
end
end
function SET_CARGO:OnEventDeleteCargo(EventData)
self:F3({EventData})
if EventData.Cargo then
local Cargo=_DATABASE:FindCargo(EventData.Cargo.Name)
if Cargo and Cargo.Name then
self:Remove(Cargo.Name)
end
end
end
do
COORDINATE={
ClassName="COORDINATE",
}
function COORDINATE:New(x,y,z)
local self=BASE:Inherit(self,BASE:New())
self.x=x
self.y=y
self.z=z
return self
end
function COORDINATE:NewFromVec2(Vec2,LandHeightAdd)
local LandHeight=land.getHeight(Vec2)
LandHeightAdd=LandHeightAdd or 0
LandHeight=LandHeight+LandHeightAdd
local self=self:New(Vec2.x,LandHeight,Vec2.y)
self:F2(self)
return self
end
function COORDINATE:NewFromVec3(Vec3)
local self=self:New(Vec3.x,Vec3.y,Vec3.z)
self:F2(self)
return self
end
function COORDINATE:GetVec3()
return{x=self.x,y=self.y,z=self.z}
end
function COORDINATE:GetVec2()
return{x=self.x,y=self.z}
end
function COORDINATE:DistanceFromVec2(Vec2Reference)
self:F2(Vec2Reference)
local Distance=((Vec2Reference.x-self.x)^2+(Vec2Reference.y-self.z)^2)^0.5
self:T2(Distance)
return Distance
end
function COORDINATE:Translate(Distance,Angle)
local SX=self.x
local SY=self.z
local Radians=Angle/180*math.pi
local TX=Distance*math.cos(Radians)+SX
local TY=Distance*math.sin(Radians)+SY
return COORDINATE:NewFromVec2({x=TX,y=TY})
end
function COORDINATE:GetRandomVec2InRadius(OuterRadius,InnerRadius)
self:F2({OuterRadius,InnerRadius})
local Theta=2*math.pi*math.random()
local Radials=math.random()+math.random()
if Radials>1 then
Radials=2-Radials
end
local RadialMultiplier
if InnerRadius and InnerRadius<=OuterRadius then
RadialMultiplier=(OuterRadius-InnerRadius)*Radials+InnerRadius
else
RadialMultiplier=OuterRadius*Radials
end
local RandomVec2
if OuterRadius>0 then
RandomVec2={x=math.cos(Theta)*RadialMultiplier+self.x,y=math.sin(Theta)*RadialMultiplier+self.z}
else
RandomVec2={x=self.x,y=self.z}
end
return RandomVec2
end
function COORDINATE:GetRandomVec3InRadius(OuterRadius,InnerRadius)
local RandomVec2=self:GetRandomVec2InRadius(OuterRadius,InnerRadius)
local y=self.y+math.random(InnerRadius,OuterRadius)
local RandomVec3={x=RandomVec2.x,y=y,z=RandomVec2.y}
return RandomVec3
end
function COORDINATE:GetLandHeight()
local Vec2={x=self.x,y=self.z}
return land.getHeight(Vec2)
end
function COORDINATE:SetHeading(Heading)
self.Heading=Heading
end
function COORDINATE:GetHeading()
return self.Heading
end
function COORDINATE:SetVelocity(Velocity)
self.Velocity=Velocity
end
function COORDINATE:GetVelocity()
local Velocity=self.Velocity
return Velocity or 0
end
function COORDINATE:GetMovingText(Settings)
return self:GetVelocityText(Settings)..", "..self:GetHeadingText(Settings)
end
function COORDINATE:GetDirectionVec3(TargetCoordinate)
return{x=TargetCoordinate.x-self.x,y=TargetCoordinate.y-self.y,z=TargetCoordinate.z-self.z}
end
function COORDINATE:GetNorthCorrectionRadians()
local TargetVec3=self:GetVec3()
local lat,lon=coord.LOtoLL(TargetVec3)
local north_posit=coord.LLtoLO(lat+1,lon)
return math.atan2(north_posit.z-TargetVec3.z,north_posit.x-TargetVec3.x)
end
function COORDINATE:GetAngleRadians(DirectionVec3)
local DirectionRadians=math.atan2(DirectionVec3.z,DirectionVec3.x)
if DirectionRadians<0 then
DirectionRadians=DirectionRadians+2*math.pi
end
return DirectionRadians
end
function COORDINATE:GetAngleDegrees(DirectionVec3)
local AngleRadians=self:GetAngleRadians(DirectionVec3)
local Angle=UTILS.ToDegree(AngleRadians)
return Angle
end
function COORDINATE:Get2DDistance(TargetCoordinate)
local TargetVec3=TargetCoordinate:GetVec3()
local SourceVec3=self:GetVec3()
return((TargetVec3.x-SourceVec3.x)^2+(TargetVec3.z-SourceVec3.z)^2)^0.5
end
function COORDINATE:Get3DDistance(TargetCoordinate)
local TargetVec3=TargetCoordinate:GetVec3()
local SourceVec3=self:GetVec3()
return((TargetVec3.x-SourceVec3.x)^2+(TargetVec3.y-SourceVec3.y)^2+(TargetVec3.z-SourceVec3.z)^2)^0.5
end
function COORDINATE:GetBearingText(AngleRadians,Precision,Settings)
local Settings=Settings or _SETTINGS
local AngleDegrees=UTILS.Round(UTILS.ToDegree(AngleRadians),Precision)
local s=string.format('%03d°',AngleDegrees)
return s
end
function COORDINATE:GetDistanceText(Distance,Settings)
local Settings=Settings or _SETTINGS
local DistanceText
if Settings:IsMetric()then
DistanceText=" for "..UTILS.Round(Distance/1000,2).." km"
else
DistanceText=" for "..UTILS.Round(UTILS.MetersToNM(Distance),2).." miles"
end
return DistanceText
end
function COORDINATE:GetAltitudeText(Settings)
local Altitude=self.y
local Settings=Settings or _SETTINGS
if Altitude~=0 then
if Settings:IsMetric()then
return" at "..UTILS.Round(self.y,-3).." meters"
else
return" at "..UTILS.Round(UTILS.MetersToFeet(self.y),-3).." feet"
end
else
return""
end
end
function COORDINATE:GetVelocityText(Settings)
local Velocity=self:GetVelocity()
local Settings=Settings or _SETTINGS
if Velocity then
if Settings:IsMetric()then
return string.format(" moving at %d km/h",UTILS.MpsToKmph(Velocity))
else
return string.format(" moving at %d mi/h",UTILS.MpsToKmph(Velocity)/1.852)
end
else
return" stationary"
end
end
function COORDINATE:GetHeadingText(Settings)
local Heading=self:GetHeading()
if Heading then
return string.format(" bearing %3d°",Heading)
else
return" bearing unknown"
end
end
function COORDINATE:GetBRText(AngleRadians,Distance,Settings)
local Settings=Settings or _SETTINGS
local BearingText=self:GetBearingText(AngleRadians,0,Settings)
local DistanceText=self:GetDistanceText(Distance,Settings)
local BRText=BearingText..DistanceText
return BRText
end
function COORDINATE:GetBRAText(AngleRadians,Distance,Settings)
local Settings=Settings or _SETTINGS
local BearingText=self:GetBearingText(AngleRadians,0,Settings)
local DistanceText=self:GetDistanceText(Distance,Settings)
local AltitudeText=self:GetAltitudeText(Settings)
local BRAText=BearingText..DistanceText..AltitudeText
return BRAText
end
function COORDINATE:Translate(Distance,Angle)
local SX=self.x
local SZ=self.z
local Radians=Angle/180*math.pi
local TX=Distance*math.cos(Radians)+SX
local TZ=Distance*math.sin(Radians)+SZ
return COORDINATE:New(TX,self.y,TZ)
end
function COORDINATE:WaypointAir(AltType,Type,Action,Speed,SpeedLocked)
self:F2({AltType,Type,Action,Speed,SpeedLocked})
local RoutePoint={}
RoutePoint.x=self.x
RoutePoint.y=self.z
RoutePoint.alt=self.y
RoutePoint.alt_type=AltType or"RADIO"
RoutePoint.type=Type or nil
RoutePoint.action=Action or nil
RoutePoint.speed=(Speed and Speed/3.6)or(500/3.6)
RoutePoint.speed_locked=true
RoutePoint.task={}
RoutePoint.task.id="ComboTask"
RoutePoint.task.params={}
RoutePoint.task.params.tasks={}
return RoutePoint
end
function COORDINATE:WaypointGround(Speed,Formation)
self:F2({Formation,Speed})
local RoutePoint={}
RoutePoint.x=self.x
RoutePoint.y=self.z
RoutePoint.action=Formation or""
RoutePoint.speed=(Speed or 999)/3.6
RoutePoint.speed_locked=true
RoutePoint.task={}
RoutePoint.task.id="ComboTask"
RoutePoint.task.params={}
RoutePoint.task.params.tasks={}
return RoutePoint
end
function COORDINATE:Explosion(ExplosionIntensity)
self:F2({ExplosionIntensity})
trigger.action.explosion(self:GetVec3(),ExplosionIntensity)
end
function COORDINATE:IlluminationBomb()
self:F2()
trigger.action.illuminationBomb(self:GetVec3())
end
function COORDINATE:Smoke(SmokeColor)
self:F2({SmokeColor})
trigger.action.smoke(self:GetVec3(),SmokeColor)
end
function COORDINATE:SmokeGreen()
self:F2()
self:Smoke(SMOKECOLOR.Green)
end
function COORDINATE:SmokeRed()
self:F2()
self:Smoke(SMOKECOLOR.Red)
end
function COORDINATE:SmokeWhite()
self:F2()
self:Smoke(SMOKECOLOR.White)
end
function COORDINATE:SmokeOrange()
self:F2()
self:Smoke(SMOKECOLOR.Orange)
end
function COORDINATE:SmokeBlue()
self:F2()
self:Smoke(SMOKECOLOR.Blue)
end
function COORDINATE:Flare(FlareColor,Azimuth)
self:F2({FlareColor})
trigger.action.signalFlare(self:GetVec3(),FlareColor,Azimuth and Azimuth or 0)
end
function COORDINATE:FlareWhite(Azimuth)
self:F2(Azimuth)
self:Flare(FLARECOLOR.White,Azimuth)
end
function COORDINATE:FlareYellow(Azimuth)
self:F2(Azimuth)
self:Flare(FLARECOLOR.Yellow,Azimuth)
end
function COORDINATE:FlareGreen(Azimuth)
self:F2(Azimuth)
self:Flare(FLARECOLOR.Green,Azimuth)
end
function COORDINATE:FlareRed(Azimuth)
self:F2(Azimuth)
self:Flare(FLARECOLOR.Red,Azimuth)
end
do
function COORDINATE:MarkToAll(MarkText)
local MarkID=UTILS.GetMarkID()
trigger.action.markToAll(MarkID,MarkText,self:GetVec3())
return MarkID
end
function COORDINATE:MarkToCoalition(MarkText,Coalition)
local MarkID=UTILS.GetMarkID()
trigger.action.markToCoalition(MarkID,MarkText,self:GetVec3(),Coalition)
return MarkID
end
function COORDINATE:MarkToCoalitionRed(MarkText)
return self:MarkToCoalition(MarkText,coalition.side.RED)
end
function COORDINATE:MarkToCoalitionBlue(MarkText)
return self:MarkToCoalition(MarkText,coalition.side.BLUE)
end
function COORDINATE:MarkToGroup(MarkText,MarkGroup)
local MarkID=UTILS.GetMarkID()
trigger.action.markToGroup(MarkID,MarkText,self:GetVec3(),MarkGroup:GetID())
return MarkID
end
function COORDINATE:RemoveMark(MarkID)
trigger.action.removeMark(MarkID)
end
end
function COORDINATE:IsLOS(ToCoordinate)
local FromVec3=self:GetVec3()
FromVec3.y=FromVec3.y+2
local ToVec3=ToCoordinate:GetVec3()
ToVec3.y=ToVec3.y+2
local IsLOS=land.isVisible(FromVec3,ToVec3)
return IsLOS
end
function COORDINATE:IsInRadius(Coordinate,Radius)
local InVec2=self:GetVec2()
local Vec2=Coordinate:GetVec2()
local InRadius=UTILS.IsInRadius(InVec2,Vec2,Radius)
return InRadius
end
function COORDINATE:IsInSphere(Coordinate,Radius)
local InVec3=self:GetVec3()
local Vec3=Coordinate:GetVec3()
local InSphere=UTILS.IsInSphere(InVec3,Vec3,Radius)
return InSphere
end
function COORDINATE:ToStringBR(FromCoordinate,Settings)
local DirectionVec3=FromCoordinate:GetDirectionVec3(self)
local AngleRadians=self:GetAngleRadians(DirectionVec3)
local Distance=self:Get2DDistance(FromCoordinate)
return"BR, "..self:GetBRText(AngleRadians,Distance,Settings)
end
function COORDINATE:ToStringBRA(FromCoordinate,Settings)
local DirectionVec3=FromCoordinate:GetDirectionVec3(self)
local AngleRadians=self:GetAngleRadians(DirectionVec3)
local Distance=FromCoordinate:Get2DDistance(self)
local Altitude=self:GetAltitudeText()
return"BRA, "..self:GetBRAText(AngleRadians,Distance,Settings)
end
function COORDINATE:ToStringBULLS(Coalition,Settings)
local TargetCoordinate=COORDINATE:NewFromVec3(coalition.getMainRefPoint(Coalition))
local DirectionVec3=self:GetDirectionVec3(TargetCoordinate)
local AngleRadians=self:GetAngleRadians(DirectionVec3)
local Distance=self:Get2DDistance(TargetCoordinate)
local Altitude=self:GetAltitudeText()
return"BULLS, "..self:GetBRText(AngleRadians,Distance,Settings)
end
function COORDINATE:ToStringAspect(TargetCoordinate)
local Heading=self.Heading
local DirectionVec3=self:GetDirectionVec3(TargetCoordinate)
local Angle=self:GetAngleDegrees(DirectionVec3)
if Heading then
local Aspect=Angle-Heading
if Aspect>-135 and Aspect<=-45 then
return"Flanking"
end
if Aspect>-45 and Aspect<=45 then
return"Hot"
end
if Aspect>45 and Aspect<=135 then
return"Flanking"
end
if Aspect>135 or Aspect<=-135 then
return"Cold"
end
end
return""
end
function COORDINATE:ToStringLLDMS(Settings)
local LL_Accuracy=Settings and Settings.LL_Accuracy or _SETTINGS.LL_Accuracy
local lat,lon=coord.LOtoLL(self:GetVec3())
return"LL DMS, "..UTILS.tostringLL(lat,lon,LL_Accuracy,true)
end
function COORDINATE:ToStringLLDDM(Settings)
local LL_Accuracy=Settings and Settings.LL_Accuracy or _SETTINGS.LL_Accuracy
local lat,lon=coord.LOtoLL(self:GetVec3())
return"LL DDM, "..UTILS.tostringLL(lat,lon,LL_Accuracy,false)
end
function COORDINATE:ToStringMGRS(Settings)
local MGRS_Accuracy=Settings and Settings.MGRS_Accuracy or _SETTINGS.MGRS_Accuracy
local lat,lon=coord.LOtoLL(self:GetVec3())
local MGRS=coord.LLtoMGRS(lat,lon)
return"MGRS, "..UTILS.tostringMGRS(MGRS,MGRS_Accuracy)
end
function COORDINATE:ToStringFromRP(ReferenceCoord,ReferenceName,Controllable,Settings)
self:E({ReferenceCoord=ReferenceCoord,ReferenceName=ReferenceName})
local Settings=Settings or(Controllable and _DATABASE:GetPlayerSettings(Controllable:GetPlayerName()))or _SETTINGS
local IsAir=Controllable and Controllable:IsAirPlane()or false
if IsAir then
local DirectionVec3=ReferenceCoord:GetDirectionVec3(self)
local AngleRadians=self:GetAngleRadians(DirectionVec3)
local Distance=self:Get2DDistance(ReferenceCoord)
return"Targets are the last seen "..self:GetBRText(AngleRadians,Distance,Settings).." from "..ReferenceName
else
local DirectionVec3=ReferenceCoord:GetDirectionVec3(self)
local AngleRadians=self:GetAngleRadians(DirectionVec3)
local Distance=self:Get2DDistance(ReferenceCoord)
return"Target are located "..self:GetBRText(AngleRadians,Distance,Settings).." from "..ReferenceName
end
return nil
end
function COORDINATE:ToStringA2G(Controllable,Settings)
self:F({Controllable=Controllable and Controllable:GetName()})
local Settings=Settings or(Controllable and _DATABASE:GetPlayerSettings(Controllable:GetPlayerName()))or _SETTINGS
if Settings:IsA2G_BR()then
if Controllable then
local Coordinate=Controllable:GetCoordinate()
return Controllable and self:ToStringBR(Coordinate,Settings)or self:ToStringMGRS(Settings)
else
return self:ToStringMGRS(Settings)
end
end
if Settings:IsA2G_LL_DMS()then
return self:ToStringLLDMS(Settings)
end
if Settings:IsA2G_LL_DDM()then
return self:ToStringLLDDM(Settings)
end
if Settings:IsA2G_MGRS()then
return self:ToStringMGRS(Settings)
end
return nil
end
function COORDINATE:ToStringA2A(Controllable,Settings)
self:F({Controllable=Controllable and Controllable:GetName()})
local Settings=Settings or(Controllable and _DATABASE:GetPlayerSettings(Controllable:GetPlayerName()))or _SETTINGS
if Settings:IsA2A_BRAA()then
if Controllable then
local Coordinate=Controllable:GetCoordinate()
return self:ToStringBRA(Coordinate,Settings)
else
return self:ToStringMGRS(Settings)
end
end
if Settings:IsA2A_BULLS()then
local Coalition=Controllable:GetCoalition()
return self:ToStringBULLS(Coalition,Settings)
end
if Settings:IsA2A_LL_DMS()then
return self:ToStringLLDMS(Settings)
end
if Settings:IsA2A_LL_DDM()then
return self:ToStringLLDDM(Settings)
end
if Settings:IsA2A_MGRS()then
return self:ToStringMGRS(Settings)
end
return nil
end
function COORDINATE:ToString(Controllable,Settings,Task)
self:F({Controllable=Controllable and Controllable:GetName()})
local Settings=Settings or(Controllable and _DATABASE:GetPlayerSettings(Controllable:GetPlayerName()))or _SETTINGS
local ModeA2A=true
if Task then
if Task:IsInstanceOf(TASK_A2A)then
ModeA2A=true
else
if Task:IsInstanceOf(TASK_A2G)then
ModeA2A=false
else
if Task:IsInstanceOf(TASK_CARGO)then
ModeA2A=false
end
end
end
else
local IsAir=Controllable and Controllable:IsAirPlane()or false
if IsAir then
ModeA2A=true
else
ModeA2A=false
end
end
if ModeA2A==true then
return self:ToStringA2A(Controllable,Settings)
else
return self:ToStringA2G(Controllable,Settings)
end
return nil
end
end
do
POINT_VEC3={
ClassName="POINT_VEC3",
Metric=true,
RoutePointAltType={
BARO="BARO",
},
RoutePointType={
TakeOffParking="TakeOffParking",
TurningPoint="Turning Point",
},
RoutePointAction={
FromParkingArea="From Parking Area",
TurningPoint="Turning Point",
},
}
function POINT_VEC3:New(x,y,z)
local self=BASE:Inherit(self,COORDINATE:New(x,y,z))
self:F2(self)
return self
end
function POINT_VEC3:NewFromVec2(Vec2,LandHeightAdd)
local self=BASE:Inherit(self,COORDINATE:NewFromVec2(Vec2,LandHeightAdd))
self:F2(self)
return self
end
function POINT_VEC3:NewFromVec3(Vec3)
local self=BASE:Inherit(self,COORDINATE:NewFromVec3(Vec3))
self:F2(self)
return self
end
function POINT_VEC3:GetX()
return self.x
end
function POINT_VEC3:GetY()
return self.y
end
function POINT_VEC3:GetZ()
return self.z
end
function POINT_VEC3:SetX(x)
self.x=x
return self
end
function POINT_VEC3:SetY(y)
self.y=y
return self
end
function POINT_VEC3:SetZ(z)
self.z=z
return self
end
function POINT_VEC3:AddX(x)
self.x=self.x+x
return self
end
function POINT_VEC3:AddY(y)
self.y=self.y+y
return self
end
function POINT_VEC3:AddZ(z)
self.z=self.z+z
return self
end
function POINT_VEC3:GetRandomPointVec3InRadius(OuterRadius,InnerRadius)
return POINT_VEC3:NewFromVec3(self:GetRandomVec3InRadius(OuterRadius,InnerRadius))
end
end
do
POINT_VEC2={
ClassName="POINT_VEC2",
}
function POINT_VEC2:New(x,y,LandHeightAdd)
local LandHeight=land.getHeight({["x"]=x,["y"]=y})
LandHeightAdd=LandHeightAdd or 0
LandHeight=LandHeight+LandHeightAdd
local self=BASE:Inherit(self,COORDINATE:New(x,LandHeight,y))
self:F2(self)
return self
end
function POINT_VEC2:NewFromVec2(Vec2,LandHeightAdd)
local LandHeight=land.getHeight(Vec2)
LandHeightAdd=LandHeightAdd or 0
LandHeight=LandHeight+LandHeightAdd
local self=BASE:Inherit(self,COORDINATE:NewFromVec2(Vec2,LandHeightAdd))
self:F2(self)
return self
end
function POINT_VEC2:NewFromVec3(Vec3)
local self=BASE:Inherit(self,COORDINATE:NewFromVec3(Vec3))
self:F2(self)
return self
end
function POINT_VEC2:GetX()
return self.x
end
function POINT_VEC2:GetY()
return self.z
end
function POINT_VEC2:SetX(x)
self.x=x
return self
end
function POINT_VEC2:SetY(y)
self.z=y
return self
end
function POINT_VEC2:GetLat()
return self.x
end
function POINT_VEC2:SetLat(x)
self.x=x
return self
end
function POINT_VEC2:GetLon()
return self.z
end
function POINT_VEC2:SetLon(z)
self.z=z
return self
end
function POINT_VEC2:GetAlt()
return self.y~=0 or land.getHeight({x=self.x,y=self.z})
end
function POINT_VEC2:SetAlt(Altitude)
self.y=Altitude or land.getHeight({x=self.x,y=self.z})
return self
end
function POINT_VEC2:AddX(x)
self.x=self.x+x
return self
end
function POINT_VEC2:AddY(y)
self.z=self.z+y
return self
end
function POINT_VEC2:AddAlt(Altitude)
self.y=land.getHeight({x=self.x,y=self.z})+Altitude or 0
return self
end
function POINT_VEC2:GetRandomPointVec2InRadius(OuterRadius,InnerRadius)
self:F2({OuterRadius,InnerRadius})
return POINT_VEC2:NewFromVec2(self:GetRandomVec2InRadius(OuterRadius,InnerRadius))
end
function POINT_VEC2:DistanceFromPointVec2(PointVec2Reference)
self:F2(PointVec2Reference)
local Distance=((PointVec2Reference.x-self.x)^2+(PointVec2Reference.z-self.z)^2)^0.5
self:T2(Distance)
return Distance
end
end
MESSAGE={
ClassName="MESSAGE",
MessageCategory=0,
MessageID=0,
}
MESSAGE.Type={
Update="Update",
Information="Information",
Briefing="Briefing Report",
Overview="Overview Report",
Detailed="Detailed Report"
}
function MESSAGE:New(MessageText,MessageDuration,MessageCategory)
local self=BASE:Inherit(self,BASE:New())
self:F({MessageText,MessageDuration,MessageCategory})
self.MessageType=nil
if MessageCategory and MessageCategory~=""then
if MessageCategory:sub(-1)~="\n"then
self.MessageCategory=MessageCategory..": "
else
self.MessageCategory=MessageCategory:sub(1,-2)..":\n"
end
else
self.MessageCategory=""
end
self.MessageDuration=MessageDuration or 5
self.MessageTime=timer.getTime()
self.MessageText=MessageText:gsub("^\n","",1):gsub("\n$","",1)
self.MessageSent=false
self.MessageGroup=false
self.MessageCoalition=false
return self
end
function MESSAGE:NewType(MessageText,MessageType)
local self=BASE:Inherit(self,BASE:New())
self:F({MessageText})
self.MessageType=MessageType
self.MessageTime=timer.getTime()
self.MessageText=MessageText:gsub("^\n","",1):gsub("\n$","",1)
return self
end
function MESSAGE:ToClient(Client,Settings)
self:F(Client)
if Client and Client:GetClientGroupID()then
if self.MessageType then
local Settings=Settings or(Client and _DATABASE:GetPlayerSettings(Client:GetPlayerName()))or _SETTINGS
self.MessageDuration=Settings:GetMessageTime(self.MessageType)
self.MessageCategory=self.MessageType..": "
end
if self.MessageDuration~=0 then
local ClientGroupID=Client:GetClientGroupID()
self:T(self.MessageCategory..self.MessageText:gsub("\n$",""):gsub("\n$","").." / "..self.MessageDuration)
trigger.action.outTextForGroup(ClientGroupID,self.MessageCategory..self.MessageText:gsub("\n$",""):gsub("\n$",""),self.MessageDuration)
end
end
return self
end
function MESSAGE:ToGroup(Group,Settings)
self:F(Group.GroupName)
if Group then
if self.MessageType then
local Settings=Settings or(Group and _DATABASE:GetPlayerSettings(Group:GetPlayerName()))or _SETTINGS
self.MessageDuration=Settings:GetMessageTime(self.MessageType)
self.MessageCategory=self.MessageType..": "
end
if self.MessageDuration~=0 then
self:T(self.MessageCategory..self.MessageText:gsub("\n$",""):gsub("\n$","").." / "..self.MessageDuration)
trigger.action.outTextForGroup(Group:GetID(),self.MessageCategory..self.MessageText:gsub("\n$",""):gsub("\n$",""),self.MessageDuration)
end
end
return self
end
function MESSAGE:ToBlue()
self:F()
self:ToCoalition(coalition.side.BLUE)
return self
end
function MESSAGE:ToRed()
self:F()
self:ToCoalition(coalition.side.RED)
return self
end
function MESSAGE:ToCoalition(CoalitionSide,Settings)
self:F(CoalitionSide)
if self.MessageType then
local Settings=Settings or _SETTINGS
self.MessageDuration=Settings:GetMessageTime(self.MessageType)
self.MessageCategory=self.MessageType..": "
end
if CoalitionSide then
if self.MessageDuration~=0 then
self:T(self.MessageCategory..self.MessageText:gsub("\n$",""):gsub("\n$","").." / "..self.MessageDuration)
trigger.action.outTextForCoalition(CoalitionSide,self.MessageCategory..self.MessageText:gsub("\n$",""):gsub("\n$",""),self.MessageDuration)
end
end
return self
end
function MESSAGE:ToCoalitionIf(CoalitionSide,Condition)
self:F(CoalitionSide)
if Condition and Condition==true then
self:ToCoalition(CoalitionSide)
end
return self
end
function MESSAGE:ToAll()
self:F()
if self.MessageType then
local Settings=Settings or _SETTINGS
self.MessageDuration=Settings:GetMessageTime(self.MessageType)
self.MessageCategory=self.MessageType..": "
end
if self.MessageDuration~=0 then
self:T(self.MessageCategory..self.MessageText:gsub("\n$",""):gsub("\n$","").." / "..self.MessageDuration)
trigger.action.outText(self.MessageCategory..self.MessageText:gsub("\n$",""):gsub("\n$",""),self.MessageDuration)
end
return self
end
function MESSAGE:ToAllIf(Condition)
if Condition and Condition==true then
self:ToAll()
end
return self
end
do
FSM={
ClassName="FSM",
}
function FSM:New(FsmT)
self=BASE:Inherit(self,BASE:New())
self.options=options or{}
self.options.subs=self.options.subs or{}
self.current=self.options.initial or'none'
self.Events={}
self.subs={}
self.endstates={}
self.Scores={}
self._StartState="none"
self._Transitions={}
self._Processes={}
self._EndStates={}
self._Scores={}
self._EventSchedules={}
self.CallScheduler=SCHEDULER:New(self)
return self
end
function FSM:SetStartState(State)
self._StartState=State
self.current=State
end
function FSM:GetStartState()
return self._StartState or{}
end
function FSM:AddTransition(From,Event,To)
local Transition={}
Transition.From=From
Transition.Event=Event
Transition.To=To
self:T2(Transition)
self._Transitions[Transition]=Transition
self:_eventmap(self.Events,Transition)
end
function FSM:GetTransitions()
return self._Transitions or{}
end
function FSM:AddProcess(From,Event,Process,ReturnEvents)
self:T({From,Event})
local Sub={}
Sub.From=From
Sub.Event=Event
Sub.fsm=Process
Sub.StartEvent="Start"
Sub.ReturnEvents=ReturnEvents
self._Processes[Sub]=Sub
self:_submap(self.subs,Sub,nil)
self:AddTransition(From,Event,From)
return Process
end
function FSM:GetProcesses()
return self._Processes or{}
end
function FSM:GetProcess(From,Event)
for ProcessID,Process in pairs(self:GetProcesses())do
if Process.From==From and Process.Event==Event then
return Process.fsm
end
end
error("Sub-Process from state "..From.." with event "..Event.." not found!")
end
function FSM:AddEndState(State)
self._EndStates[State]=State
self.endstates[State]=State
end
function FSM:GetEndStates()
return self._EndStates or{}
end
function FSM:AddScore(State,ScoreText,Score)
self:F({State,ScoreText,Score})
self._Scores[State]=self._Scores[State]or{}
self._Scores[State].ScoreText=ScoreText
self._Scores[State].Score=Score
return self
end
function FSM:AddScoreProcess(From,Event,State,ScoreText,Score)
self:F({From,Event,State,ScoreText,Score})
local Process=self:GetProcess(From,Event)
Process._Scores[State]=Process._Scores[State]or{}
Process._Scores[State].ScoreText=ScoreText
Process._Scores[State].Score=Score
self:T(Process._Scores)
return Process
end
function FSM:GetScores()
return self._Scores or{}
end
function FSM:GetSubs()
return self.options.subs
end
function FSM:LoadCallBacks(CallBackTable)
for name,callback in pairs(CallBackTable or{})do
self[name]=callback
end
end
function FSM:_eventmap(Events,EventStructure)
local Event=EventStructure.Event
local __Event="__"..EventStructure.Event
self[Event]=self[Event]or self:_create_transition(Event)
self[__Event]=self[__Event]or self:_delayed_transition(Event)
self:T2("Added methods: "..Event..", "..__Event)
Events[Event]=self.Events[Event]or{map={}}
self:_add_to_map(Events[Event].map,EventStructure)
end
function FSM:_submap(subs,sub,name)
subs[sub.From]=subs[sub.From]or{}
subs[sub.From][sub.Event]=subs[sub.From][sub.Event]or{}
subs[sub.From][sub.Event][sub]={}
subs[sub.From][sub.Event][sub].fsm=sub.fsm
subs[sub.From][sub.Event][sub].StartEvent=sub.StartEvent
subs[sub.From][sub.Event][sub].ReturnEvents=sub.ReturnEvents or{}
subs[sub.From][sub.Event][sub].name=name
subs[sub.From][sub.Event][sub].fsmparent=self
end
function FSM:_call_handler(handler,params,EventName)
local ErrorHandler=function(errmsg)
env.info("Error in SCHEDULER function:"..errmsg)
if debug~=nil then
env.info(debug.traceback())
end
return errmsg
end
if self[handler]then
self:T2("Calling "..handler)
self._EventSchedules[EventName]=nil
local Result,Value=xpcall(function()return self[handler](self,unpack(params))end,ErrorHandler)
return Value
end
end
function FSM._handler(self,EventName,...)
local Can,to=self:can(EventName)
if to=="*"then
to=self.current
end
if Can then
local from=self.current
local params={from,EventName,to,...}
if self.Controllable then
self:T("FSM Transition for "..self.Controllable.ControllableName.." :"..self.current.." --> "..EventName.." --> "..to)
else
self:T("FSM Transition:"..self.current.." --> "..EventName.." --> "..to)
end
if(self:_call_handler("onbefore"..EventName,params,EventName)==false)
or(self:_call_handler("OnBefore"..EventName,params,EventName)==false)
or(self:_call_handler("onleave"..from,params,EventName)==false)
or(self:_call_handler("OnLeave"..from,params,EventName)==false)then
self:T("Cancel Transition")
return false
end
self.current=to
local execute=true
local subtable=self:_gosub(from,EventName)
for _,sub in pairs(subtable)do
self:T("calling sub start event: "..sub.StartEvent)
sub.fsm.fsmparent=self
sub.fsm.ReturnEvents=sub.ReturnEvents
sub.fsm[sub.StartEvent](sub.fsm)
execute=false
end
local fsmparent,Event=self:_isendstate(to)
if fsmparent and Event then
self:F2({"end state: ",fsmparent,Event})
self:_call_handler("onenter"..to,params,EventName)
self:_call_handler("OnEnter"..to,params,EventName)
self:_call_handler("onafter"..EventName,params,EventName)
self:_call_handler("OnAfter"..EventName,params,EventName)
self:_call_handler("onstatechange",params,EventName)
fsmparent[Event](fsmparent)
execute=false
end
if execute then
self:_call_handler("onenter"..to,params,EventName)
self:_call_handler("OnEnter"..to,params,EventName)
self:_call_handler("onafter"..EventName,params,EventName)
self:_call_handler("OnAfter"..EventName,params,EventName)
self:_call_handler("onstatechange",params,EventName)
end
else
self:T("Cannot execute transition.")
self:T({From=self.current,Event=EventName,To=to,Can=Can})
end
return nil
end
function FSM:_delayed_transition(EventName)
return function(self,DelaySeconds,...)
self:T2("Delayed Event: "..EventName)
local CallID=0
if DelaySeconds~=nil then
if DelaySeconds<0 then
DelaySeconds=math.abs(DelaySeconds)
if not self._EventSchedules[EventName]then
CallID=self.CallScheduler:Schedule(self,self._handler,{EventName,...},DelaySeconds or 1)
self._EventSchedules[EventName]=CallID
else
end
else
CallID=self.CallScheduler:Schedule(self,self._handler,{EventName,...},DelaySeconds or 1)
end
else
error("FSM: An asynchronous event trigger requires a DelaySeconds parameter!!! This can be positive or negative! Sorry, but will not process this.")
end
self:T2({CallID=CallID})
end
end
function FSM:_create_transition(EventName)
return function(self,...)return self._handler(self,EventName,...)end
end
function FSM:_gosub(ParentFrom,ParentEvent)
local fsmtable={}
if self.subs[ParentFrom]and self.subs[ParentFrom][ParentEvent]then
self:T({ParentFrom,ParentEvent,self.subs[ParentFrom],self.subs[ParentFrom][ParentEvent]})
return self.subs[ParentFrom][ParentEvent]
else
return{}
end
end
function FSM:_isendstate(Current)
local FSMParent=self.fsmparent
if FSMParent and self.endstates[Current]then
self:T({state=Current,endstates=self.endstates,endstate=self.endstates[Current]})
FSMParent.current=Current
local ParentFrom=FSMParent.current
self:T(ParentFrom)
self:T(self.ReturnEvents)
local Event=self.ReturnEvents[Current]
self:T({ParentFrom,Event,self.ReturnEvents})
if Event then
return FSMParent,Event
else
self:T({"Could not find parent event name for state ",ParentFrom})
end
end
return nil
end
function FSM:_add_to_map(Map,Event)
self:F3({Map,Event})
if type(Event.From)=='string'then
Map[Event.From]=Event.To
else
for _,From in ipairs(Event.From)do
Map[From]=Event.To
end
end
self:T3({Map,Event})
end
function FSM:GetState()
return self.current
end
function FSM:Is(State)
return self.current==State
end
function FSM:is(state)
return self.current==state
end
function FSM:can(e)
local Event=self.Events[e]
self:F3({self.current,Event})
local To=Event and Event.map[self.current]or Event.map['*']
return To~=nil,To
end
function FSM:cannot(e)
return not self:can(e)
end
end
do
FSM_CONTROLLABLE={
ClassName="FSM_CONTROLLABLE",
}
function FSM_CONTROLLABLE:New(FSMT,Controllable)
local self=BASE:Inherit(self,FSM:New(FSMT))
if Controllable then
self:SetControllable(Controllable)
end
self:AddTransition("*","Stop","Stopped")
return self
end
function FSM_CONTROLLABLE:OnAfterStop(Controllable,From,Event,To)
self.CallScheduler:Clear()
end
function FSM_CONTROLLABLE:SetControllable(FSMControllable)
self.Controllable=FSMControllable
end
function FSM_CONTROLLABLE:GetControllable()
return self.Controllable
end
function FSM_CONTROLLABLE:_call_handler(handler,params,EventName)
local ErrorHandler=function(errmsg)
env.info("Error in SCHEDULER function:"..errmsg)
if debug~=nil then
env.info(debug.traceback())
end
return errmsg
end
if self[handler]then
self:F3("Calling "..handler)
self._EventSchedules[EventName]=nil
local Result,Value=xpcall(function()return self[handler](self,self.Controllable,unpack(params))end,ErrorHandler)
return Value
end
end
end
do
FSM_PROCESS={
ClassName="FSM_PROCESS",
}
function FSM_PROCESS:New(Controllable,Task)
local self=BASE:Inherit(self,FSM_CONTROLLABLE:New())
self:Assign(Controllable,Task)
return self
end
function FSM_PROCESS:Init(FsmProcess)
self:T("No Initialisation")
end
function FSM_PROCESS:_call_handler(handler,params,EventName)
local ErrorHandler=function(errmsg)
env.info("Error in FSM_PROCESS call handler:"..errmsg)
if debug~=nil then
env.info(debug.traceback())
end
return errmsg
end
if self[handler]then
self:F3("Calling "..handler)
self._EventSchedules[EventName]=nil
local Result,Value=xpcall(function()return self[handler](self,self.Controllable,self.Task,unpack(params))end,ErrorHandler)
return Value
end
end
function FSM_PROCESS:Copy(Controllable,Task)
self:T({self:GetClassNameAndID()})
local NewFsm=self:New(Controllable,Task)
NewFsm:Assign(Controllable,Task)
NewFsm:Init(self)
NewFsm:SetStartState(self:GetStartState())
for TransitionID,Transition in pairs(self:GetTransitions())do
NewFsm:AddTransition(Transition.From,Transition.Event,Transition.To)
end
for ProcessID,Process in pairs(self:GetProcesses())do
local FsmProcess=NewFsm:AddProcess(Process.From,Process.Event,Process.fsm:Copy(Controllable,Task),Process.ReturnEvents)
end
for EndStateID,EndState in pairs(self:GetEndStates())do
self:T(EndState)
NewFsm:AddEndState(EndState)
end
for ScoreID,Score in pairs(self:GetScores())do
self:T(Score)
NewFsm:AddScore(ScoreID,Score.ScoreText,Score.Score)
end
return NewFsm
end
function FSM_PROCESS:Remove()
self:F({self:GetClassNameAndID()})
self:F("Clearing Schedules")
self.CallScheduler:Clear()
for ProcessID,Process in pairs(self:GetProcesses())do
if Process.fsm then
Process.fsm:Remove()
Process.fsm=nil
end
end
return self
end
function FSM_PROCESS:SetTask(Task)
self.Task=Task
return self
end
function FSM_PROCESS:GetTask()
return self.Task
end
function FSM_PROCESS:GetMission()
return self.Task.Mission
end
function FSM_PROCESS:GetCommandCenter()
return self:GetTask():GetMission():GetCommandCenter()
end
function FSM_PROCESS:Message(Message)
self:F({Message=Message})
local CC=self:GetCommandCenter()
local TaskGroup=self.Controllable:GetGroup()
local PlayerName=self.Controllable:GetPlayerName()
PlayerName=PlayerName and" ("..PlayerName..")"or""
local Callsign=self.Controllable:GetCallsign()
local Prefix=Callsign and" @ "..Callsign..PlayerName or""
Message=Prefix..": "..Message
CC:MessageToGroup(Message,TaskGroup)
end
function FSM_PROCESS:Assign(ProcessUnit,Task)
self:SetControllable(ProcessUnit)
self:SetTask(Task)
return self
end
function FSM_PROCESS:onenterAssigned(ProcessUnit)
self:T("Assign")
self.Task:Assign()
end
function FSM_PROCESS:onenterFailed(ProcessUnit)
self:T("Failed")
self.Task:Fail()
end
function FSM_PROCESS:onstatechange(ProcessUnit,Task,From,Event,To,Dummy)
self:T({ProcessUnit:GetName(),From,Event,To,Dummy,self:IsTrace()})
if self:IsTrace()then
end
self:T({Scores=self._Scores,To=To})
if self._Scores[To]then
local Task=self.Task
local Scoring=Task:GetScoring()
if Scoring then
Scoring:_AddMissionTaskScore(Task.Mission,ProcessUnit,self._Scores[To].ScoreText,self._Scores[To].Score)
end
end
end
end
do
FSM_TASK={
ClassName="FSM_TASK",
}
function FSM_TASK:New(FSMT)
local self=BASE:Inherit(self,FSM_CONTROLLABLE:New(FSMT))
self["onstatechange"]=self.OnStateChange
return self
end
function FSM_TASK:_call_handler(handler,params,EventName)
if self[handler]then
self:T("Calling "..handler)
self._EventSchedules[EventName]=nil
return self[handler](self,unpack(params))
end
end
end
do
FSM_SET={
ClassName="FSM_SET",
}
function FSM_SET:New(FSMSet)
self=BASE:Inherit(self,FSM:New())
if FSMSet then
self:Set(FSMSet)
end
return self
end
function FSM_SET:Set(FSMSet)
self:F(FSMSet)
self.Set=FSMSet
end
function FSM_SET:Get()
return self.Controllable
end
function FSM_SET:_call_handler(handler,params,EventName)
if self[handler]then
self:T("Calling "..handler)
self._EventSchedules[EventName]=nil
return self[handler](self,self.Set,unpack(params))
end
end
end
RADIO={
ClassName="RADIO",
FileName="",
Frequency=0,
Modulation=radio.modulation.AM,
Subtitle="",
SubtitleDuration=0,
Power=100,
Loop=true,
}
function RADIO:New(Positionable)
local self=BASE:Inherit(self,BASE:New())
self.Loop=true
self:F(Positionable)
if Positionable:GetPointVec2()then
self.Positionable=Positionable
return self
end
self:E({"The passed positionable is invalid, no RADIO created",Positionable})
return nil
end
function RADIO:SetFileName(FileName)
self:F2(FileName)
if type(FileName)=="string"then
if FileName:find(".ogg")or FileName:find(".wav")then
if not FileName:find("l10n/DEFAULT/")then
FileName="l10n/DEFAULT/"..FileName
end
self.FileName=FileName
return self
end
end
self:E({"File name invalid. Maybe something wrong with the extension ?",self.FileName})
return self
end
function RADIO:SetFrequency(Frequency)
self:F2(Frequency)
if type(Frequency)=="number"then
if(Frequency>=30 and Frequency<88)or(Frequency>=108 and Frequency<152)or(Frequency>=225 and Frequency<400)then
self.Frequency=Frequency*1000000
if self.Positionable.ClassName=="UNIT"or self.Positionable.ClassName=="GROUP"then
self.Positionable:SetCommand({
id="SetFrequency",
params={
frequency=self.Frequency,
modulation=self.Modulation,
}
})
end
return self
end
end
self:E({"Frequency is outside of DCS Frequency ranges (30-80, 108-152, 225-400). Frequency unchanged.",self.Frequency})
return self
end
function RADIO:SetModulation(Modulation)
self:F2(Modulation)
if type(Modulation)=="number"then
if Modulation==radio.modulation.AM or Modulation==radio.modulation.FM then
self.Modulation=Modulation
return self
end
end
self:E({"Modulation is invalid. Use DCS's enum radio.modulation. Modulation unchanged.",self.Modulation})
return self
end
function RADIO:SetPower(Power)
self:F2(Power)
if type(Power)=="number"then
self.Power=math.floor(math.abs(Power))
return self
end
self:E({"Power is invalid. Power unchanged.",self.Power})
return self
end
function RADIO:SetLoop(Loop)
self:F2(Loop)
if type(Loop)=="boolean"then
self.Loop=Loop
return self
end
self:E({"Loop is invalid. Loop unchanged.",self.Loop})
return self
end
function RADIO:SetSubtitle(Subtitle,SubtitleDuration)
self:F2({Subtitle,SubtitleDuration})
if type(Subtitle)=="string"then
self.Subtitle=Subtitle
else
self.Subtitle=""
self:E({"Subtitle is invalid. Subtitle reset.",self.Subtitle})
end
if type(SubtitleDuration)=="number"then
if math.floor(math.abs(SubtitleDuration))==SubtitleDuration then
self.SubtitleDuration=SubtitleDuration
return self
end
end
self.SubtitleDuration=0
self:E({"SubtitleDuration is invalid. SubtitleDuration reset.",self.SubtitleDuration})
end
function RADIO:NewGenericTransmission(FileName,Frequency,Modulation,Power,Loop)
self:F({FileName,Frequency,Modulation,Power})
self:SetFileName(FileName)
if Frequency then self:SetFrequency(Frequency)end
if Modulation then self:SetModulation(Modulation)end
if Power then self:SetPower(Power)end
if Loop then self:SetLoop(Loop)end
return self
end
function RADIO:NewUnitTransmission(FileName,Subtitle,SubtitleDuration,Frequency,Modulation,Loop)
self:F({FileName,Subtitle,SubtitleDuration,Frequency,Modulation,Loop})
self:SetFileName(FileName)
if Subtitle then self:SetSubtitle(Subtitle)end
if SubtitleDuration then self:SetSubtitleDuration(SubtitleDuration)end
if Frequency then self:SetFrequency(Frequency)end
if Modulation then self:SetModulation(Modulation)end
if Loop then self:SetLoop(Loop)end
return self
end
function RADIO:Broadcast()
self:F()
if self.Positionable.ClassName=="UNIT"or self.Positionable.ClassName=="GROUP"then
self:T2("Broadcasting from a UNIT or a GROUP")
self.Positionable:SetCommand({
id="TransmitMessage",
params={
file=self.FileName,
duration=self.SubtitleDuration,
subtitle=self.Subtitle,
loop=self.Loop,
}
})
else
self:T2("Broadcasting from a POSITIONABLE")
trigger.action.radioTransmission(self.FileName,self.Positionable:GetPositionVec3(),self.Modulation,self.Loop,self.Frequency,self.Power,tostring(self.ID))
end
return self
end
function RADIO:StopBroadcast()
self:F()
if self.Positionable.ClassName=="UNIT"or self.Positionable.ClassName=="GROUP"then
self.Positionable:SetCommand({
id="StopTransmission",
params={}
})
else
trigger.action.stopRadioTransmission(tostring(self.ID))
end
return self
end
BEACON={
ClassName="BEACON",
}
function BEACON:New(Positionable)
local self=BASE:Inherit(self,BASE:New())
self:F(Positionable)
if Positionable:GetPointVec2()then
self.Positionable=Positionable
return self
end
self:E({"The passed positionable is invalid, no BEACON created",Positionable})
return nil
end
function BEACON:_TACANToFrequency(TACANChannel,TACANMode)
self:F3({TACANChannel,TACANMode})
if type(TACANChannel)~="number"then
if TACANMode~="X"and TACANMode~="Y"then
return nil
end
end
local A=1151
local B=64
if TACANChannel<64 then
B=1
end
if TACANMode=='Y'then
A=1025
if TACANChannel<64 then
A=1088
end
else
if TACANChannel<64 then
A=962
end
end
return(A+TACANChannel-B)*1000000
end
function BEACON:AATACAN(TACANChannel,Message,Bearing,BeaconDuration)
self:F({TACANChannel,Message,Bearing,BeaconDuration})
local IsValid=true
if not self.Positionable:IsAir()then
self:E({"The POSITIONABLE you want to attach the AA Tacan Beacon is not an aircraft ! The BEACON is not emitting",self.Positionable})
IsValid=false
end
local Frequency=self:_TACANToFrequency(TACANChannel,"Y")
if not Frequency then
self:E({"The passed TACAN channel is invalid, the BEACON is not emitting"})
IsValid=false
end
local System
if Bearing then
System=5
else
System=14
end
if IsValid then
self:T2({"AA TACAN BEACON started !"})
self.Positionable:SetCommand({
id="ActivateBeacon",
params={
type=4,
system=System,
callsign=Message,
frequency=Frequency,
}
})
if BeaconDuration then
SCHEDULER:New(nil,
function()
self:StopAATACAN()
end,{},BeaconDuration)
end
end
return self
end
function BEACON:StopAATACAN()
self:F()
if not self.Positionable then
self:E({"Start the beacon first before stoping it !"})
else
self.Positionable:SetCommand({
id='DeactivateBeacon',
params={
}
})
end
end
function BEACON:RadioBeacon(FileName,Frequency,Modulation,Power,BeaconDuration)
self:F({FileName,Frequency,Modulation,Power,BeaconDuration})
local IsValid=false
if type(FileName)=="string"then
if FileName:find(".ogg")or FileName:find(".wav")then
if not FileName:find("l10n/DEFAULT/")then
FileName="l10n/DEFAULT/"..FileName
end
IsValid=true
end
end
if not IsValid then
self:E({"File name invalid. Maybe something wrong with the extension ? ",FileName})
end
if type(Frequency)~="number"and IsValid then
self:E({"Frequency invalid. ",Frequency})
IsValid=false
end
Frequency=Frequency*1000000
if Modulation~=radio.modulation.AM and Modulation~=radio.modulation.FM and IsValid then
self:E({"Modulation is invalid. Use DCS's enum radio.modulation.",Modulation})
IsValid=false
end
if type(Power)~="number"and IsValid then
self:E({"Power is invalid. ",Power})
IsValid=false
end
Power=math.floor(math.abs(Power))
if IsValid then
self:T2({"Activating Beacon on ",Frequency,Modulation})
trigger.action.radioTransmission(FileName,self.Positionable:GetPositionVec3(),Modulation,true,Frequency,Power,tostring(self.ID))
if BeaconDuration then
SCHEDULER:New(nil,
function()
self:StopRadioBeacon()
end,{},BeaconDuration)
end
end
end
function BEACON:StopRadioBeacon()
self:F()
trigger.action.stopRadioTransmission(tostring(self.ID))
end
SPAWNSTATIC={
ClassName="SPAWNSTATIC",
}
function SPAWNSTATIC:NewFromStatic(SpawnTemplatePrefix,CountryID)
local self=BASE:Inherit(self,BASE:New())
self:F({SpawnTemplatePrefix})
local TemplateStatic=StaticObject.getByName(SpawnTemplatePrefix)
if TemplateStatic then
self.SpawnTemplatePrefix=SpawnTemplatePrefix
self.CountryID=CountryID
self.SpawnIndex=0
else
error("SPAWNSTATIC:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '"..SpawnTemplatePrefix.."'")
end
self:SetEventPriority(5)
return self
end
function SPAWNSTATIC:NewFromType(SpawnTypeName,SpawnShapeName,SpawnCategory,CountryID)
local self=BASE:Inherit(self,BASE:New())
self:F({SpawnTypeName})
self.SpawnTypeName=SpawnTypeName
self.CountryID=CountryID
self.SpawnIndex=0
self:SetEventPriority(5)
return self
end
function SPAWNSTATIC:SpawnFromPointVec2(PointVec2,Heading,NewName)
self:F({PointVec2,Heading,NewName})
local CountryName=_DATABASE.COUNTRY_NAME[self.CountryID]
local StaticTemplate=_DATABASE:GetStaticUnitTemplate(self.SpawnTemplatePrefix)
StaticTemplate.x=PointVec2:GetLat()
StaticTemplate.y=PointVec2:GetLon()
StaticTemplate.name=NewName or string.format("%s#%05d",self.SpawnTemplatePrefix,self.SpawnIndex)
StaticTemplate.heading=(Heading/180)*math.pi
StaticTemplate.CountryID=nil
StaticTemplate.CoalitionID=nil
StaticTemplate.CategoryID=nil
local Static=coalition.addStaticObject(self.CountryID,StaticTemplate)
self.SpawnIndex=self.SpawnIndex+1
return Static
end
function SPAWNSTATIC:SpawnFromZone(Zone,Heading,NewName)
self:F({Zone,Heading,NewName})
local Static=self:SpawnFromPointVec2(Zone:GetPointVec2(),Heading,NewName)
return Static
end
CARGOS={}
do
CARGO={
ClassName="CARGO",
Type=nil,
Name=nil,
Weight=nil,
CargoObject=nil,
CargoCarrier=nil,
Representable=false,
Slingloadable=false,
Moveable=false,
Containable=false,
}
function CARGO:New(Type,Name,Weight)
local self=BASE:Inherit(self,FSM:New())
self:F({Type,Name,Weight})
self:SetStartState("UnLoaded")
self:AddTransition({"UnLoaded","Boarding"},"Board","Boarding")
self:AddTransition("Boarding","Boarding","Boarding")
self:AddTransition("Boarding","CancelBoarding","UnLoaded")
self:AddTransition("Boarding","Load","Loaded")
self:AddTransition("UnLoaded","Load","Loaded")
self:AddTransition("Loaded","UnBoard","UnBoarding")
self:AddTransition("UnBoarding","UnBoarding","UnBoarding")
self:AddTransition("UnBoarding","UnLoad","UnLoaded")
self:AddTransition("Loaded","UnLoad","UnLoaded")
self:AddTransition("*","Damaged","Damaged")
self:AddTransition("*","Destroyed","Destroyed")
self:AddTransition("*","Respawn","UnLoaded")
self.Type=Type
self.Name=Name
self.Weight=Weight
self.CargoObject=nil
self.CargoCarrier=nil
self.Representable=false
self.Slingloadable=false
self.Moveable=false
self.Containable=false
self:SetDeployed(false)
self.CargoScheduler=SCHEDULER:New()
CARGOS[self.Name]=self
return self
end
function CARGO:Destroy()
if self.CargoObject then
self.CargoObject:Destroy()
end
self:Destroyed()
end
function CARGO:GetName()
return self.Name
end
function CARGO:GetObjectName()
if self:IsLoaded()then
return self.CargoCarrier:GetName()
else
return self.CargoObject:GetName()
end
end
function CARGO:GetType()
return self.Type
end
function CARGO:GetCoordinate()
return self.CargoObject:GetCoordinate()
end
function CARGO:IsDestroyed()
return self:Is("Destroyed")
end
function CARGO:IsLoaded()
return self:Is("Loaded")
end
function CARGO:IsUnLoaded()
return self:Is("UnLoaded")
end
function CARGO:IsAlive()
if self:IsLoaded()then
return self.CargoCarrier:IsAlive()
else
return self.CargoObject:IsAlive()
end
end
function CARGO:SetDeployed(Deployed)
self.Deployed=Deployed
end
function CARGO:IsDeployed()
return self.Deployed
end
function CARGO:Spawn(PointVec2)
self:F()
end
function CARGO:Flare(FlareColor)
if self:IsUnLoaded()then
trigger.action.signalFlare(self.CargoObject:GetVec3(),FlareColor,0)
end
end
function CARGO:FlareWhite()
self:Flare(trigger.flareColor.White)
end
function CARGO:FlareYellow()
self:Flare(trigger.flareColor.Yellow)
end
function CARGO:FlareGreen()
self:Flare(trigger.flareColor.Green)
end
function CARGO:FlareRed()
self:Flare(trigger.flareColor.Red)
end
function CARGO:Smoke(SmokeColor,Range)
self:F2()
if self:IsUnLoaded()then
if Range then
trigger.action.smoke(self.CargoObject:GetRandomVec3(Range),SmokeColor)
else
trigger.action.smoke(self.CargoObject:GetVec3(),SmokeColor)
end
end
end
function CARGO:SmokeGreen()
self:Smoke(trigger.smokeColor.Green,Range)
end
function CARGO:SmokeRed()
self:Smoke(trigger.smokeColor.Red,Range)
end
function CARGO:SmokeWhite()
self:Smoke(trigger.smokeColor.White,Range)
end
function CARGO:SmokeOrange()
self:Smoke(trigger.smokeColor.Orange,Range)
end
function CARGO:SmokeBlue()
self:Smoke(trigger.smokeColor.Blue,Range)
end
function CARGO:IsInZone(Zone)
self:F({Zone})
if self:IsLoaded()then
return Zone:IsPointVec2InZone(self.CargoCarrier:GetPointVec2())
else
self:F({Size=self.CargoObject:GetSize(),Units=self.CargoObject:GetUnits()})
if self.CargoObject:GetSize()~=0 then
return Zone:IsPointVec2InZone(self.CargoObject:GetPointVec2())
else
return false
end
end
return nil
end
function CARGO:IsNear(PointVec2,NearRadius)
self:F({PointVec2,NearRadius})
local Distance=PointVec2:DistanceFromPointVec2(self.CargoObject:GetPointVec2())
self:T(Distance)
if Distance<=NearRadius then
return true
else
return false
end
end
function CARGO:GetPointVec2()
return self.CargoObject:GetPointVec2()
end
function CARGO:GetCoordinate()
return self.CargoObject:GetCoordinate()
end
function CARGO:SetWeight(Weight)
self.Weight=Weight
return self
end
end
do
CARGO_REPRESENTABLE={
ClassName="CARGO_REPRESENTABLE"
}
function CARGO_REPRESENTABLE:New(CargoObject,Type,Name,Weight,ReportRadius,NearRadius)
local self=BASE:Inherit(self,CARGO:New(Type,Name,Weight,ReportRadius,NearRadius))
self:F({Type,Name,Weight,ReportRadius,NearRadius})
return self
end
function CARGO_REPRESENTABLE:RouteTo(ToPointVec2,Speed)
self:F2(ToPointVec2)
local Points={}
local PointStartVec2=self.CargoObject:GetPointVec2()
Points[#Points+1]=PointStartVec2:WaypointGround(Speed)
Points[#Points+1]=ToPointVec2:WaypointGround(Speed)
local TaskRoute=self.CargoObject:TaskRoute(Points)
self.CargoObject:SetTask(TaskRoute,2)
return self
end
end
do
CARGO_REPORTABLE={
ClassName="CARGO_REPORTABLE"
}
function CARGO_REPORTABLE:New(CargoObject,Type,Name,Weight,ReportRadius)
local self=BASE:Inherit(self,CARGO:New(Type,Name,Weight))
self:F({Type,Name,Weight,ReportRadius})
self.CargoSet=SET_CARGO:New()
self.ReportRadius=ReportRadius or 1000
self.CargoObject=CargoObject
return self
end
function CARGO_REPORTABLE:IsInRadius(PointVec2)
self:F({PointVec2})
local Distance=0
if self:IsLoaded()then
Distance=PointVec2:DistanceFromPointVec2(self.CargoCarrier:GetPointVec2())
else
Distance=PointVec2:DistanceFromPointVec2(self.CargoObject:GetPointVec2())
end
self:T(Distance)
if Distance<=self.ReportRadius then
return true
else
return false
end
end
function CARGO_REPORTABLE:MessageToGroup(Message,TaskGroup,Name)
local Prefix=Name and"@ "..Name..": "or"@ "..TaskGroup:GetCallsign()..": "
Message=Prefix..Message
MESSAGE:New(Message,20,"Cargo: "..self:GetName()):ToGroup(TaskGroup)
end
function CARGO_REPORTABLE:GetBoardingRange()
return self.ReportRadius
end
function CARGO_REPORTABLE:Respawn()
self:F({"Respawning"})
for CargoID,CargoData in pairs(self.CargoSet:GetSet())do
local Cargo=CargoData
Cargo:Destroy()
Cargo:SetStartState("UnLoaded")
end
local CargoObject=self.CargoObject
CargoObject:Destroy()
local Template=CargoObject:GetTemplate()
CargoObject:Respawn(Template)
self:SetDeployed(false)
local WeightGroup=0
self:SetStartState("UnLoaded")
end
end
do
CARGO_UNIT={
ClassName="CARGO_UNIT"
}
function CARGO_UNIT:New(CargoUnit,Type,Name,Weight,NearRadius)
local self=BASE:Inherit(self,CARGO_REPRESENTABLE:New(CargoUnit,Type,Name,Weight,NearRadius))
self:F({Type,Name,Weight,NearRadius})
self:T(CargoUnit)
self.CargoObject=CargoUnit
self:T(self.ClassName)
self:SetEventPriority(5)
return self
end
function CARGO_UNIT:Destroy()
self:F({CargoName=self:GetName()})
_EVENTDISPATCHER:CreateEventDeleteCargo(self)
return self
end
function CARGO_UNIT:onenterUnBoarding(From,Event,To,ToPointVec2,NearRadius)
self:F({From,Event,To,ToPointVec2,NearRadius})
NearRadius=NearRadius or 25
local Angle=180
local Speed=60
local DeployDistance=9
local RouteDistance=60
if From=="Loaded"then
local CargoCarrier=self.CargoCarrier
local CargoCarrierPointVec2=CargoCarrier:GetPointVec2()
local CargoCarrierHeading=self.CargoCarrier:GetHeading()
local CargoDeployHeading=((CargoCarrierHeading+Angle)>=360)and(CargoCarrierHeading+Angle-360)or(CargoCarrierHeading+Angle)
local CargoRoutePointVec2=CargoCarrierPointVec2:Translate(RouteDistance,CargoDeployHeading)
ToPointVec2=ToPointVec2 or CargoRoutePointVec2
local DirectionVec3=CargoCarrierPointVec2:GetDirectionVec3(ToPointVec2)
local Angle=CargoCarrierPointVec2:GetAngleDegrees(DirectionVec3)
local CargoDeployPointVec2=CargoCarrierPointVec2:Translate(DeployDistance,Angle)
local FromPointVec2=CargoCarrierPointVec2
if self.CargoObject then
self.CargoObject:ReSpawn(CargoDeployPointVec2:GetVec3(),CargoDeployHeading)
self:F({"CargoUnits:",self.CargoObject:GetGroup():GetName()})
self.CargoCarrier=nil
local Points={}
Points[#Points+1]=CargoCarrierPointVec2:WaypointGround(Speed)
Points[#Points+1]=ToPointVec2:WaypointGround(Speed)
local TaskRoute=self.CargoObject:TaskRoute(Points)
self.CargoObject:SetTask(TaskRoute,1)
self:__UnBoarding(1,ToPointVec2,NearRadius)
end
end
end
function CARGO_UNIT:onleaveUnBoarding(From,Event,To,ToPointVec2,NearRadius)
self:F({From,Event,To,ToPointVec2,NearRadius})
NearRadius=NearRadius or 25
local Angle=180
local Speed=10
local Distance=5
if From=="UnBoarding"then
if self:IsNear(ToPointVec2,NearRadius)then
return true
else
self:__UnBoarding(1,ToPointVec2,NearRadius)
end
return false
end
end
function CARGO_UNIT:onafterUnBoarding(From,Event,To,ToPointVec2,NearRadius)
self:F({From,Event,To,ToPointVec2,NearRadius})
NearRadius=NearRadius or 25
self.CargoInAir=self.CargoObject:InAir()
self:T(self.CargoInAir)
if not self.CargoInAir then
end
self:__UnLoad(1,ToPointVec2,NearRadius)
end
function CARGO_UNIT:onenterUnLoaded(From,Event,To,ToPointVec2)
self:F({ToPointVec2,From,Event,To})
local Angle=180
local Speed=10
local Distance=5
if From=="Loaded"then
local StartPointVec2=self.CargoCarrier:GetPointVec2()
local CargoCarrierHeading=self.CargoCarrier:GetHeading()
local CargoDeployHeading=((CargoCarrierHeading+Angle)>=360)and(CargoCarrierHeading+Angle-360)or(CargoCarrierHeading+Angle)
local CargoDeployPointVec2=StartPointVec2:Translate(Distance,CargoDeployHeading)
ToPointVec2=ToPointVec2 or POINT_VEC2:New(CargoDeployPointVec2:GetX(),CargoDeployPointVec2:GetY())
if self.CargoObject then
self.CargoObject:ReSpawn(ToPointVec2:GetVec3(),0)
self.CargoCarrier=nil
end
end
if self.OnUnLoadedCallBack then
self.OnUnLoadedCallBack(self,unpack(self.OnUnLoadedParameters))
self.OnUnLoadedCallBack=nil
end
end
function CARGO_UNIT:onafterBoard(From,Event,To,CargoCarrier,NearRadius,...)
self:F({From,Event,To,CargoCarrier,NearRadius})
local NearRadius=NearRadius or 25
self.CargoInAir=self.CargoObject:InAir()
self:T(self.CargoInAir)
if not self.CargoInAir then
if self:IsNear(CargoCarrier:GetPointVec2(),NearRadius)then
self:Load(CargoCarrier,NearRadius,...)
else
local Speed=90
local Angle=180
local Distance=5
NearRadius=NearRadius or 25
local CargoCarrierPointVec2=CargoCarrier:GetPointVec2()
local CargoCarrierHeading=CargoCarrier:GetHeading()
local CargoDeployHeading=((CargoCarrierHeading+Angle)>=360)and(CargoCarrierHeading+Angle-360)or(CargoCarrierHeading+Angle)
local CargoDeployPointVec2=CargoCarrierPointVec2:Translate(Distance,CargoDeployHeading)
local Points={}
local PointStartVec2=self.CargoObject:GetPointVec2()
Points[#Points+1]=PointStartVec2:WaypointGround(Speed)
Points[#Points+1]=CargoDeployPointVec2:WaypointGround(Speed)
local TaskRoute=self.CargoObject:TaskRoute(Points)
self.CargoObject:SetTask(TaskRoute,2)
self:__Boarding(-1,CargoCarrier,NearRadius)
self.RunCount=0
end
end
end
function CARGO_UNIT:onafterBoarding(From,Event,To,CargoCarrier,NearRadius,...)
self:F({From,Event,To,CargoCarrier.UnitName,NearRadius})
if CargoCarrier and CargoCarrier:IsAlive()then
if CargoCarrier:InAir()==false then
if self:IsNear(CargoCarrier:GetPointVec2(),NearRadius)then
self:__Load(1,CargoCarrier,...)
else
self:__Boarding(-1,CargoCarrier,NearRadius,...)
self.RunCount=self.RunCount+1
if self.RunCount>=20 then
self.RunCount=0
local Speed=90
local Angle=180
local Distance=5
NearRadius=NearRadius or 25
local CargoCarrierPointVec2=CargoCarrier:GetPointVec2()
local CargoCarrierHeading=CargoCarrier:GetHeading()
local CargoDeployHeading=((CargoCarrierHeading+Angle)>=360)and(CargoCarrierHeading+Angle-360)or(CargoCarrierHeading+Angle)
local CargoDeployPointVec2=CargoCarrierPointVec2:Translate(Distance,CargoDeployHeading)
local Points={}
local PointStartVec2=self.CargoObject:GetPointVec2()
Points[#Points+1]=PointStartVec2:WaypointGround(Speed)
Points[#Points+1]=CargoDeployPointVec2:WaypointGround(Speed)
local TaskRoute=self.CargoObject:TaskRoute(Points)
self.CargoObject:SetTask(TaskRoute,0.2)
end
end
else
self.CargoObject:MessageToGroup("Cancelling Boarding... Get back on the ground!",5,CargoCarrier:GetGroup(),self:GetName())
self:CancelBoarding(CargoCarrier,NearRadius,...)
self.CargoObject:SetCommand(self.CargoObject:CommandStopRoute(true))
end
else
self:E("Something is wrong")
end
end
function CARGO_UNIT:onenterBoarding(From,Event,To,CargoCarrier,NearRadius,...)
self:F({From,Event,To,CargoCarrier.UnitName,NearRadius})
local Speed=90
local Angle=180
local Distance=5
local NearRadius=NearRadius or 25
if From=="UnLoaded"or From=="Boarding"then
end
end
function CARGO_UNIT:onenterLoaded(From,Event,To,CargoCarrier)
self:F({From,Event,To,CargoCarrier})
self.CargoCarrier=CargoCarrier
if self.CargoObject then
self:T("Destroying")
self.CargoObject:Destroy()
end
end
end
do
CARGO_GROUP={
ClassName="CARGO_GROUP",
}
function CARGO_GROUP:New(CargoGroup,Type,Name,ReportRadius)
local self=BASE:Inherit(self,CARGO_REPORTABLE:New(CargoGroup,Type,Name,0,ReportRadius))
self:F({Type,Name,ReportRadius})
self.CargoObject=CargoGroup
self:SetDeployed(false)
self.CargoGroup=CargoGroup
local WeightGroup=0
for UnitID,UnitData in pairs(CargoGroup:GetUnits())do
local Unit=UnitData
local WeightUnit=Unit:GetDesc().massEmpty
WeightGroup=WeightGroup+WeightUnit
local CargoUnit=CARGO_UNIT:New(Unit,Type,Unit:GetName(),WeightUnit)
self.CargoSet:Add(CargoUnit:GetName(),CargoUnit)
end
self:SetWeight(WeightGroup)
self:T({"Weight Cargo",WeightGroup})
_EVENTDISPATCHER:CreateEventNewCargo(self)
self:HandleEvent(EVENTS.Dead,self.OnEventCargoDead)
self:HandleEvent(EVENTS.Crash,self.OnEventCargoDead)
self:HandleEvent(EVENTS.PlayerLeaveUnit,self.OnEventCargoDead)
self:SetEventPriority(4)
return self
end
function CARGO_GROUP:OnEventCargoDead(EventData)
local Destroyed=false
if self:IsDestroyed()or self:IsUnLoaded()then
Destroyed=true
for CargoID,CargoData in pairs(self.CargoSet:GetSet())do
local Cargo=CargoData
if Cargo:IsAlive()then
Destroyed=false
else
Cargo:Destroyed()
end
end
else
local CarrierName=self.CargoCarrier:GetName()
if CarrierName==EventData.IniDCSUnitName then
MESSAGE:New("Cargo is lost from carrier "..CarrierName,15):ToAll()
Destroyed=true
self.CargoCarrier:ClearCargo()
end
end
if Destroyed then
self:Destroyed()
self:E({"Cargo group destroyed"})
end
end
function CARGO_GROUP:onenterBoarding(From,Event,To,CargoCarrier,NearRadius,...)
self:F({CargoCarrier.UnitName,From,Event,To})
local NearRadius=NearRadius or 25
if From=="UnLoaded"then
self.CargoSet:ForEach(
function(Cargo,...)
Cargo:__Board(1,CargoCarrier,NearRadius,...)
end,...
)
self:__Boarding(1,CargoCarrier,NearRadius,...)
end
end
function CARGO_GROUP:onenterLoaded(From,Event,To,CargoCarrier,...)
self:F({From,Event,To,CargoCarrier,...})
if From=="UnLoaded"then
for CargoID,Cargo in pairs(self.CargoSet:GetSet())do
Cargo:Load(CargoCarrier)
end
end
self.CargoCarrier=CargoCarrier
end
function CARGO_GROUP:onafterBoarding(From,Event,To,CargoCarrier,NearRadius,...)
self:F({CargoCarrier.UnitName,From,Event,To})
local NearRadius=NearRadius or 25
local Boarded=true
local Cancelled=false
local Dead=true
self.CargoSet:Flush()
for CargoID,Cargo in pairs(self.CargoSet:GetSet())do
self:T({Cargo:GetName(),Cargo.current})
if not Cargo:is("Loaded")then
Boarded=false
end
if Cargo:is("UnLoaded")then
Cancelled=true
end
if not Cargo:is("Destroyed")then
Dead=false
end
end
if not Dead then
if not Cancelled then
if not Boarded then
self:__Boarding(1,CargoCarrier,NearRadius,...)
else
self:__Load(1,CargoCarrier,...)
end
else
self:__CancelBoarding(1,CargoCarrier,NearRadius,...)
end
else
self:__Destroyed(1,CargoCarrier,NearRadius,...)
end
end
function CARGO_GROUP:GetCount()
return self.CargoSet:Count()
end
function CARGO_GROUP:onenterUnBoarding(From,Event,To,ToPointVec2,NearRadius,...)
self:F({From,Event,To,ToPointVec2,NearRadius})
NearRadius=NearRadius or 25
local Timer=1
if From=="Loaded"then
if self.CargoObject then
self.CargoObject:Destroy()
end
self.CargoSet:ForEach(
function(Cargo,NearRadius)
Cargo:__UnBoard(Timer,ToPointVec2,NearRadius)
Timer=Timer+10
end,{NearRadius}
)
self:__UnBoarding(1,ToPointVec2,NearRadius,...)
end
end
function CARGO_GROUP:onleaveUnBoarding(From,Event,To,ToPointVec2,NearRadius,...)
self:F({From,Event,To,ToPointVec2,NearRadius})
local Angle=180
local Speed=10
local Distance=5
if From=="UnBoarding"then
local UnBoarded=true
for CargoID,Cargo in pairs(self.CargoSet:GetSet())do
self:T(Cargo.current)
if not Cargo:is("UnLoaded")then
UnBoarded=false
end
end
if UnBoarded then
return true
else
self:__UnBoarding(1,ToPointVec2,NearRadius,...)
end
return false
end
end
function CARGO_GROUP:onafterUnBoarding(From,Event,To,ToPointVec2,NearRadius,...)
self:F({From,Event,To,ToPointVec2,NearRadius})
self:__UnLoad(1,ToPointVec2,...)
end
function CARGO_GROUP:onenterUnLoaded(From,Event,To,ToPointVec2,...)
self:F({From,Event,To,ToPointVec2})
if From=="Loaded"then
self.CargoSet:ForEach(
function(Cargo)
Cargo:UnLoad(ToPointVec2)
end
)
end
end
function CARGO_GROUP:RespawnOnDestroyed(RespawnDestroyed)
self:F({"In function RespawnOnDestroyed"})
if RespawnDestroyed then
self.onenterDestroyed=function(self)
self:F("IN FUNCTION")
self:Respawn()
end
else
self.onenterDestroyed=nil
end
end
end
do
CARGO_PACKAGE={
ClassName="CARGO_PACKAGE"
}
function CARGO_PACKAGE:New(CargoCarrier,Type,Name,Weight,ReportRadius,NearRadius)
local self=BASE:Inherit(self,CARGO_REPRESENTABLE:New(CargoCarrier,Type,Name,Weight,ReportRadius,NearRadius))
self:F({Type,Name,Weight,ReportRadius,NearRadius})
self:T(CargoCarrier)
self.CargoCarrier=CargoCarrier
return self
end
function CARGO_PACKAGE:onafterOnBoard(From,Event,To,CargoCarrier,Speed,BoardDistance,LoadDistance,Angle)
self:F()
self.CargoInAir=self.CargoCarrier:InAir()
self:T(self.CargoInAir)
if not self.CargoInAir then
local Points={}
local StartPointVec2=self.CargoCarrier:GetPointVec2()
local CargoCarrierHeading=CargoCarrier:GetHeading()
local CargoDeployHeading=((CargoCarrierHeading+Angle)>=360)and(CargoCarrierHeading+Angle-360)or(CargoCarrierHeading+Angle)
self:T({CargoCarrierHeading,CargoDeployHeading})
local CargoDeployPointVec2=CargoCarrier:GetPointVec2():Translate(BoardDistance,CargoDeployHeading)
Points[#Points+1]=StartPointVec2:WaypointGround(Speed)
Points[#Points+1]=CargoDeployPointVec2:WaypointGround(Speed)
local TaskRoute=self.CargoCarrier:TaskRoute(Points)
self.CargoCarrier:SetTask(TaskRoute,1)
end
self:Boarded(CargoCarrier,Speed,BoardDistance,LoadDistance,Angle)
end
function CARGO_PACKAGE:IsNear(CargoCarrier)
self:F()
local CargoCarrierPoint=CargoCarrier:GetPointVec2()
local Distance=CargoCarrierPoint:DistanceFromPointVec2(self.CargoCarrier:GetPointVec2())
self:T(Distance)
if Distance<=self.NearRadius then
return true
else
return false
end
end
function CARGO_PACKAGE:onafterOnBoarded(From,Event,To,CargoCarrier,Speed,BoardDistance,LoadDistance,Angle)
self:F()
if self:IsNear(CargoCarrier)then
self:__Load(1,CargoCarrier,Speed,LoadDistance,Angle)
else
self:__Boarded(1,CargoCarrier,Speed,BoardDistance,LoadDistance,Angle)
end
end
function CARGO_PACKAGE:onafterUnBoard(From,Event,To,CargoCarrier,Speed,UnLoadDistance,UnBoardDistance,Radius,Angle)
self:F()
self.CargoInAir=self.CargoCarrier:InAir()
self:T(self.CargoInAir)
if not self.CargoInAir then
self:_Next(self.FsmP.UnLoad,UnLoadDistance,Angle)
local Points={}
local StartPointVec2=CargoCarrier:GetPointVec2()
local CargoCarrierHeading=self.CargoCarrier:GetHeading()
local CargoDeployHeading=((CargoCarrierHeading+Angle)>=360)and(CargoCarrierHeading+Angle-360)or(CargoCarrierHeading+Angle)
self:T({CargoCarrierHeading,CargoDeployHeading})
local CargoDeployPointVec2=StartPointVec2:Translate(UnBoardDistance,CargoDeployHeading)
Points[#Points+1]=StartPointVec2:WaypointGround(Speed)
Points[#Points+1]=CargoDeployPointVec2:WaypointGround(Speed)
local TaskRoute=CargoCarrier:TaskRoute(Points)
CargoCarrier:SetTask(TaskRoute,1)
end
self:__UnBoarded(1,CargoCarrier,Speed)
end
function CARGO_PACKAGE:onafterUnBoarded(From,Event,To,CargoCarrier,Speed)
self:F()
if self:IsNear(CargoCarrier)then
self:__UnLoad(1,CargoCarrier,Speed)
else
self:__UnBoarded(1,CargoCarrier,Speed)
end
end
function CARGO_PACKAGE:onafterLoad(From,Event,To,CargoCarrier,Speed,LoadDistance,Angle)
self:F()
self.CargoCarrier=CargoCarrier
local StartPointVec2=self.CargoCarrier:GetPointVec2()
local CargoCarrierHeading=self.CargoCarrier:GetHeading()
local CargoDeployHeading=((CargoCarrierHeading+Angle)>=360)and(CargoCarrierHeading+Angle-360)or(CargoCarrierHeading+Angle)
local CargoDeployPointVec2=StartPointVec2:Translate(LoadDistance,CargoDeployHeading)
local Points={}
Points[#Points+1]=StartPointVec2:WaypointGround(Speed)
Points[#Points+1]=CargoDeployPointVec2:WaypointGround(Speed)
local TaskRoute=self.CargoCarrier:TaskRoute(Points)
self.CargoCarrier:SetTask(TaskRoute,1)
end
function CARGO_PACKAGE:onafterUnLoad(From,Event,To,CargoCarrier,Speed,Distance,Angle)
self:F()
local StartPointVec2=self.CargoCarrier:GetPointVec2()
local CargoCarrierHeading=self.CargoCarrier:GetHeading()
local CargoDeployHeading=((CargoCarrierHeading+Angle)>=360)and(CargoCarrierHeading+Angle-360)or(CargoCarrierHeading+Angle)
local CargoDeployPointVec2=StartPointVec2:Translate(Distance,CargoDeployHeading)
self.CargoCarrier=CargoCarrier
local Points={}
Points[#Points+1]=StartPointVec2:WaypointGround(Speed)
Points[#Points+1]=CargoDeployPointVec2:WaypointGround(Speed)
local TaskRoute=self.CargoCarrier:TaskRoute(Points)
self.CargoCarrier:SetTask(TaskRoute,1)
end
end
do
SPOT={
ClassName="SPOT",
}
function SPOT:New(Recce)
local self=BASE:Inherit(self,FSM:New())
self:F({})
self:SetStartState("Off")
self:AddTransition("Off","LaseOn","On")
self:AddTransition("On","Lasing","On")
self:AddTransition({"On","Destroyed"},"LaseOff","Off")
self:AddTransition("*","Destroyed","Destroyed")
self.Recce=Recce
self.LaseScheduler=SCHEDULER:New(self)
self:SetEventPriority(5)
self.Lasing=false
return self
end
function SPOT:onafterLaseOn(From,Event,To,Target,LaserCode,Duration)
self:E({"LaseOn",Target,LaserCode,Duration})
local function StopLase(self)
self:LaseOff()
end
self.Target=Target
self.LaserCode=LaserCode
self.Lasing=true
local RecceDcsUnit=self.Recce:GetDCSObject()
self.SpotIR=Spot.createInfraRed(RecceDcsUnit,{x=0,y=2,z=0},Target:GetPointVec3():AddY(1):GetVec3())
self.SpotLaser=Spot.createLaser(RecceDcsUnit,{x=0,y=2,z=0},Target:GetPointVec3():AddY(1):GetVec3(),LaserCode)
if Duration then
self.ScheduleID=self.LaseScheduler:Schedule(self,StopLase,{self},Duration)
end
self:HandleEvent(EVENTS.Dead)
self:__Lasing(-1)
end
function SPOT:OnEventDead(EventData)
self:E({Dead=EventData.IniDCSUnitName,Target=self.Target})
if self.Target then
if EventData.IniDCSUnitName==self.Target:GetName()then
self:E({"Target dead ",self.Target:GetName()})
self:Destroyed()
self:LaseOff()
end
end
end
function SPOT:onafterLasing(From,Event,To)
if self.Target:IsAlive()then
self.SpotIR:setPoint(self.Target:GetPointVec3():AddY(1):AddY(math.random(-100,100)/100):AddX(math.random(-100,100)/100):GetVec3())
self.SpotLaser:setPoint(self.Target:GetPointVec3():AddY(1):GetVec3())
self:__Lasing(-0.2)
else
self:E({"Target is not alive",self.Target:IsAlive()})
end
end
function SPOT:onafterLaseOff(From,Event,To)
self:E({"Stopped lasing for ",self.Target:GetName(),SpotIR=self.SportIR,SpotLaser=self.SpotLaser})
self.Lasing=false
self.SpotIR:destroy()
self.SpotLaser:destroy()
self.SpotIR=nil
self.SpotLaser=nil
if self.ScheduleID then
self.LaseScheduler:Stop(self.ScheduleID)
end
self.ScheduleID=nil
self.Target=nil
return self
end
function SPOT:IsLasing()
return self.Lasing
end
end
OBJECT={
ClassName="OBJECT",
ObjectName="",
}
function OBJECT:New(ObjectName,Test)
local self=BASE:Inherit(self,BASE:New())
self:F2(ObjectName)
self.ObjectName=ObjectName
return self
end
function OBJECT:GetID()
self:F2(self.ObjectName)
local DCSObject=self:GetDCSObject()
if DCSObject then
local ObjectID=DCSObject:getID()
return ObjectID
end
return nil
end
function OBJECT:Destroy()
self:F2(self.ObjectName)
local DCSObject=self:GetDCSObject()
if DCSObject then
DCSObject:destroy()
end
return nil
end
IDENTIFIABLE={
ClassName="IDENTIFIABLE",
IdentifiableName="",
}
local _CategoryName={
[Unit.Category.AIRPLANE]="Airplane",
[Unit.Category.HELICOPTER]="Helicoper",
[Unit.Category.GROUND_UNIT]="Ground Identifiable",
[Unit.Category.SHIP]="Ship",
[Unit.Category.STRUCTURE]="Structure",
}
function IDENTIFIABLE:New(IdentifiableName)
local self=BASE:Inherit(self,OBJECT:New(IdentifiableName))
self:F2(IdentifiableName)
self.IdentifiableName=IdentifiableName
return self
end
function IDENTIFIABLE:IsAlive()
self:F3(self.IdentifiableName)
local DCSIdentifiable=self:GetDCSObject()
if DCSIdentifiable then
local IdentifiableIsAlive=DCSIdentifiable:isExist()
return IdentifiableIsAlive
end
return false
end
function IDENTIFIABLE:GetName()
self:F2(self.IdentifiableName)
local IdentifiableName=self.IdentifiableName
return IdentifiableName
end
function IDENTIFIABLE:GetTypeName()
self:F2(self.IdentifiableName)
local DCSIdentifiable=self:GetDCSObject()
if DCSIdentifiable then
local IdentifiableTypeName=DCSIdentifiable:getTypeName()
self:T3(IdentifiableTypeName)
return IdentifiableTypeName
end
self:E(self.ClassName.." "..self.IdentifiableName.." not found!")
return nil
end
function IDENTIFIABLE:GetCategory()
self:F2(self.ObjectName)
local DCSObject=self:GetDCSObject()
if DCSObject then
local ObjectCategory=DCSObject:getCategory()
self:T3(ObjectCategory)
return ObjectCategory
end
return nil
end
function IDENTIFIABLE:GetCategoryName()
local DCSIdentifiable=self:GetDCSObject()
if DCSIdentifiable then
local IdentifiableCategoryName=_CategoryName[self:GetDesc().category]
return IdentifiableCategoryName
end
self:E(self.ClassName.." "..self.IdentifiableName.." not found!")
return nil
end
function IDENTIFIABLE:GetCoalition()
self:F2(self.IdentifiableName)
local DCSIdentifiable=self:GetDCSObject()
if DCSIdentifiable then
local IdentifiableCoalition=DCSIdentifiable:getCoalition()
self:T3(IdentifiableCoalition)
return IdentifiableCoalition
end
self:E(self.ClassName.." "..self.IdentifiableName.." not found!")
return nil
end
function IDENTIFIABLE:GetCountry()
self:F2(self.IdentifiableName)
local DCSIdentifiable=self:GetDCSObject()
if DCSIdentifiable then
local IdentifiableCountry=DCSIdentifiable:getCountry()
self:T3(IdentifiableCountry)
return IdentifiableCountry
end
self:E(self.ClassName.." "..self.IdentifiableName.." not found!")
return nil
end
function IDENTIFIABLE:GetDesc()
self:F2(self.IdentifiableName)
local DCSIdentifiable=self:GetDCSObject()
if DCSIdentifiable then
local IdentifiableDesc=DCSIdentifiable:getDesc()
self:T2(IdentifiableDesc)
return IdentifiableDesc
end
self:E(self.ClassName.." "..self.IdentifiableName.." not found!")
return nil
end
function IDENTIFIABLE:GetCallsign()
return''
end
function IDENTIFIABLE:GetThreatLevel()
return 0,"Scenery"
end
POSITIONABLE={
ClassName="POSITIONABLE",
PositionableName="",
}
POSITIONABLE.__={}
POSITIONABLE.__.Cargo={}
function POSITIONABLE:New(PositionableName)
local self=BASE:Inherit(self,IDENTIFIABLE:New(PositionableName))
self.PositionableName=PositionableName
return self
end
function POSITIONABLE:GetPositionVec3()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionablePosition=DCSPositionable:getPosition().p
self:T3(PositionablePosition)
return PositionablePosition
end
return nil
end
function POSITIONABLE:GetVec2()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionableVec3=DCSPositionable:getPosition().p
local PositionableVec2={}
PositionableVec2.x=PositionableVec3.x
PositionableVec2.y=PositionableVec3.z
self:T2(PositionableVec2)
return PositionableVec2
end
return nil
end
function POSITIONABLE:GetPointVec2()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionableVec3=DCSPositionable:getPosition().p
local PositionablePointVec2=POINT_VEC2:NewFromVec3(PositionableVec3)
self:T2(PositionablePointVec2)
return PositionablePointVec2
end
return nil
end
function POSITIONABLE:GetPointVec3()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionableVec3=self:GetPositionVec3()
local PositionablePointVec3=POINT_VEC3:NewFromVec3(PositionableVec3)
self:T2(PositionablePointVec3)
return PositionablePointVec3
end
return nil
end
function POSITIONABLE:GetCoordinate()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionableVec3=self:GetPositionVec3()
local PositionableCoordinate=COORDINATE:NewFromVec3(PositionableVec3)
PositionableCoordinate:SetHeading(self:GetHeading())
PositionableCoordinate:SetVelocity(self:GetVelocityMPS())
self:T2(PositionableCoordinate)
return PositionableCoordinate
end
return nil
end
function POSITIONABLE:GetRandomVec3(Radius)
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionablePointVec3=DCSPositionable:getPosition().p
if Radius then
local PositionableRandomVec3={}
local angle=math.random()*math.pi*2;
PositionableRandomVec3.x=PositionablePointVec3.x+math.cos(angle)*math.random()*Radius;
PositionableRandomVec3.y=PositionablePointVec3.y
PositionableRandomVec3.z=PositionablePointVec3.z+math.sin(angle)*math.random()*Radius;
self:T3(PositionableRandomVec3)
return PositionableRandomVec3
else
self:E("Radius is nil, returning the PointVec3 of the POSITIONABLE",PositionablePointVec3)
return PositionablePointVec3
end
end
return nil
end
function POSITIONABLE:GetVec3()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionableVec3=DCSPositionable:getPosition().p
self:T3(PositionableVec3)
return PositionableVec3
end
return nil
end
function POSITIONABLE:GetBoundingBox()
self:F2()
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionableDesc=DCSPositionable:getDesc()
if PositionableDesc then
local PositionableBox=PositionableDesc.box
return PositionableBox
end
end
return nil
end
function POSITIONABLE:GetAltitude()
self:F2()
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionablePointVec3=DCSPositionable:getPoint()
return PositionablePointVec3.y
end
return nil
end
function POSITIONABLE:IsAboveRunway()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local Vec2=self:GetVec2()
local SurfaceType=land.getSurfaceType(Vec2)
local IsAboveRunway=SurfaceType==land.SurfaceType.RUNWAY
self:T2(IsAboveRunway)
return IsAboveRunway
end
return nil
end
function POSITIONABLE:GetHeading()
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionablePosition=DCSPositionable:getPosition()
if PositionablePosition then
local PositionableHeading=math.atan2(PositionablePosition.x.z,PositionablePosition.x.x)
if PositionableHeading<0 then
PositionableHeading=PositionableHeading+2*math.pi
end
PositionableHeading=PositionableHeading*180/math.pi
self:T2(PositionableHeading)
return PositionableHeading
end
end
return nil
end
function POSITIONABLE:InAir()
self:F2(self.PositionableName)
return nil
end
function POSITIONABLE:GetVelocity()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionableVelocityVec3=DCSPositionable:getVelocity()
self:T3(PositionableVelocityVec3)
return PositionableVelocityVec3
end
return nil
end
function POSITIONABLE:GetHeight()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionablePosition=DCSPositionable:getPosition()
if PositionablePosition then
local PositionableHeight=PositionablePosition.p.y
self:T2(PositionableHeight)
return PositionableHeight
end
end
return nil
end
function POSITIONABLE:GetVelocityKMH()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local VelocityVec3=self:GetVelocity()
local Velocity=(VelocityVec3.x^2+VelocityVec3.y^2+VelocityVec3.z^2)^0.5
local Velocity=Velocity*3.6
self:T3(Velocity)
return Velocity
end
return 0
end
function POSITIONABLE:GetVelocityMPS()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local VelocityVec3=self:GetVelocity()
local Velocity=(VelocityVec3.x^2+VelocityVec3.y^2+VelocityVec3.z^2)^0.5
self:T3(Velocity)
return Velocity
end
return 0
end
function POSITIONABLE:GetMessageText(Message,Name)
local DCSObject=self:GetDCSObject()
if DCSObject then
Name=Name and(" ("..Name..")")or""
local Callsign=string.format("[%s]",self:GetCallsign()~=""and self:GetCallsign()or self:GetName())
local MessageText=Callsign..Name..": "..Message
return MessageText
end
return nil
end
function POSITIONABLE:GetMessage(Message,Duration,Name)
local DCSObject=self:GetDCSObject()
if DCSObject then
local MessageText=self:GetMessageText(Message,Name)
return MESSAGE:New(MessageText,Duration)
end
return nil
end
function POSITIONABLE:GetMessageType(Message,MessageType,Name)
local DCSObject=self:GetDCSObject()
if DCSObject then
local MessageText=self:GetMessageText(Message,Name)
return MESSAGE:NewType(MessageText,MessageType)
end
return nil
end
function POSITIONABLE:MessageToAll(Message,Duration,Name)
self:F2({Message,Duration})
local DCSObject=self:GetDCSObject()
if DCSObject then
self:GetMessage(Message,Duration,Name):ToAll()
end
return nil
end
function POSITIONABLE:MessageToCoalition(Message,Duration,MessageCoalition)
self:F2({Message,Duration})
local Name=""
local DCSObject=self:GetDCSObject()
if DCSObject then
if MessageCoalition==coalition.side.BLUE then
Name="Blue coalition"
end
if MessageCoalition==coalition.side.RED then
Name="Red coalition"
end
self:GetMessage(Message,Duration,Name):ToCoalition(MessageCoalition)
end
return nil
end
function POSITIONABLE:MessageTypeToCoalition(Message,MessageType,MessageCoalition)
self:F2({Message,MessageType})
local Name=""
local DCSObject=self:GetDCSObject()
if DCSObject then
if MessageCoalition==coalition.side.BLUE then
Name="Blue coalition"
end
if MessageCoalition==coalition.side.RED then
Name="Red coalition"
end
self:GetMessageType(Message,MessageType,Name):ToCoalition(MessageCoalition)
end
return nil
end
function POSITIONABLE:MessageToRed(Message,Duration,Name)
self:F2({Message,Duration})
local DCSObject=self:GetDCSObject()
if DCSObject then
self:GetMessage(Message,Duration,Name):ToRed()
end
return nil
end
function POSITIONABLE:MessageToBlue(Message,Duration,Name)
self:F2({Message,Duration})
local DCSObject=self:GetDCSObject()
if DCSObject then
self:GetMessage(Message,Duration,Name):ToBlue()
end
return nil
end
function POSITIONABLE:MessageToClient(Message,Duration,Client,Name)
self:F2({Message,Duration})
local DCSObject=self:GetDCSObject()
if DCSObject then
self:GetMessage(Message,Duration,Name):ToClient(Client)
end
return nil
end
function POSITIONABLE:MessageToGroup(Message,Duration,MessageGroup,Name)
self:F2({Message,Duration})
local DCSObject=self:GetDCSObject()
if DCSObject then
if DCSObject:isExist()then
self:GetMessage(Message,Duration,Name):ToGroup(MessageGroup)
end
end
return nil
end
function POSITIONABLE:MessageTypeToGroup(Message,MessageType,MessageGroup,Name)
self:F2({Message,MessageType})
local DCSObject=self:GetDCSObject()
if DCSObject then
if DCSObject:isExist()then
self:GetMessageType(Message,MessageType,Name):ToGroup(MessageGroup)
end
end
return nil
end
function POSITIONABLE:MessageToSetGroup(Message,Duration,MessageSetGroup,Name)
self:F2({Message,Duration})
local DCSObject=self:GetDCSObject()
if DCSObject then
if DCSObject:isExist()then
MessageSetGroup:ForEachGroup(
function(MessageGroup)
self:GetMessage(Message,Duration,Name):ToGroup(MessageGroup)
end
)
end
end
return nil
end
function POSITIONABLE:Message(Message,Duration,Name)
self:F2({Message,Duration})
local DCSObject=self:GetDCSObject()
if DCSObject then
self:GetMessage(Message,Duration,Name):ToGroup(self)
end
return nil
end
function POSITIONABLE:GetRadio()
self:F2(self)
return RADIO:New(self)
end
function POSITIONABLE:GetBeacon()
self:F2(self)
return BEACON:New(self)
end
function POSITIONABLE:LaseUnit(Target,LaserCode,Duration)
self:F2()
LaserCode=LaserCode or math.random(1000,9999)
local RecceDcsUnit=self:GetDCSObject()
local TargetVec3=Target:GetVec3()
self:E("bulding spot")
self.Spot=SPOT:New(self)
self.Spot:LaseOn(Target,LaserCode,Duration)
self.LaserCode=LaserCode
return self.Spot
end
function POSITIONABLE:LaseOff()
self:F2()
if self.Spot then
self.Spot:LaseOff()
self.Spot=nil
end
return self
end
function POSITIONABLE:IsLasing()
self:F2()
local Lasing=false
if self.Spot then
Lasing=self.Spot:IsLasing()
end
return Lasing
end
function POSITIONABLE:GetSpot()
return self.Spot
end
function POSITIONABLE:GetLaserCode()
return self.LaserCode
end
function POSITIONABLE:AddCargo(Cargo)
self.__.Cargo[Cargo]=Cargo
return self
end
function POSITIONABLE:RemoveCargo(Cargo)
self.__.Cargo[Cargo]=nil
return self
end
function POSITIONABLE:HasCargo(Cargo)
return self.__.Cargo[Cargo]
end
function POSITIONABLE:ClearCargo()
self.__.Cargo={}
end
function POSITIONABLE:CargoItemCount()
local ItemCount=0
for CargoName,Cargo in pairs(self.__.Cargo)do
ItemCount=ItemCount+Cargo:GetCount()
end
return ItemCount
end
function POSITIONABLE:Flare(FlareColor)
self:F2()
trigger.action.signalFlare(self:GetVec3(),FlareColor,0)
end
function POSITIONABLE:FlareWhite()
self:F2()
trigger.action.signalFlare(self:GetVec3(),trigger.flareColor.White,0)
end
function POSITIONABLE:FlareYellow()
self:F2()
trigger.action.signalFlare(self:GetVec3(),trigger.flareColor.Yellow,0)
end
function POSITIONABLE:FlareGreen()
self:F2()
trigger.action.signalFlare(self:GetVec3(),trigger.flareColor.Green,0)
end
function POSITIONABLE:FlareRed()
self:F2()
local Vec3=self:GetVec3()
if Vec3 then
trigger.action.signalFlare(Vec3,trigger.flareColor.Red,0)
end
end
function POSITIONABLE:Smoke(SmokeColor,Range,AddHeight)
self:F2()
if Range then
local Vec3=self:GetRandomVec3(Range)
Vec3.y=Vec3.y+AddHeight or 0
trigger.action.smoke(Vec3,SmokeColor)
else
local Vec3=self:GetVec3()
Vec3.y=Vec3.y+AddHeight or 0
trigger.action.smoke(self:GetVec3(),SmokeColor)
end
end
function POSITIONABLE:SmokeGreen()
self:F2()
trigger.action.smoke(self:GetVec3(),trigger.smokeColor.Green)
end
function POSITIONABLE:SmokeRed()
self:F2()
trigger.action.smoke(self:GetVec3(),trigger.smokeColor.Red)
end
function POSITIONABLE:SmokeWhite()
self:F2()
trigger.action.smoke(self:GetVec3(),trigger.smokeColor.White)
end
function POSITIONABLE:SmokeOrange()
self:F2()
trigger.action.smoke(self:GetVec3(),trigger.smokeColor.Orange)
end
function POSITIONABLE:SmokeBlue()
self:F2()
trigger.action.smoke(self:GetVec3(),trigger.smokeColor.Blue)
end
CONTROLLABLE={
ClassName="CONTROLLABLE",
ControllableName="",
WayPointFunctions={},
}
function CONTROLLABLE:New(ControllableName)
local self=BASE:Inherit(self,POSITIONABLE:New(ControllableName))
self:F2(ControllableName)
self.ControllableName=ControllableName
self.TaskScheduler=SCHEDULER:New(self)
return self
end
function CONTROLLABLE:_GetController()
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local ControllableController=DCSControllable:getController()
return ControllableController
end
return nil
end
function CONTROLLABLE:GetUnits()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local DCSUnits=DCSControllable:getUnits()
local Units={}
for Index,UnitData in pairs(DCSUnits)do
Units[#Units+1]=UNIT:Find(UnitData)
end
self:T3(Units)
return Units
end
return nil
end
function CONTROLLABLE:GetLife()
self:F2(self.ControllableName)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local UnitLife=0
local Units=self:GetUnits()
if#Units==1 then
local Unit=Units[1]
UnitLife=Unit:GetLife()
else
local UnitLifeTotal=0
for UnitID,Unit in pairs(Units)do
local Unit=Unit
UnitLifeTotal=UnitLifeTotal+Unit:GetLife()
end
UnitLife=UnitLifeTotal/#Units
end
return UnitLife
end
return nil
end
function CONTROLLABLE:GetLife0()
self:F2(self.ControllableName)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local UnitLife=0
local Units=self:GetUnits()
if#Units==1 then
local Unit=Units[1]
UnitLife=Unit:GetLife0()
else
local UnitLifeTotal=0
for UnitID,Unit in pairs(Units)do
local Unit=Unit
UnitLifeTotal=UnitLifeTotal+Unit:GetLife0()
end
UnitLife=UnitLifeTotal/#Units
end
return UnitLife
end
return nil
end
function CONTROLLABLE:GetFuel()
self:F(self.ControllableName)
return nil
end
function CONTROLLABLE:ClearTasks()
self:F2()
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
Controller:resetTask()
return self
end
return nil
end
function CONTROLLABLE:PopCurrentTask()
self:F2()
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
Controller:popTask()
return self
end
return nil
end
function CONTROLLABLE:PushTask(DCSTask,WaitTime)
self:F2()
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if WaitTime then
self.TaskScheduler:Schedule(Controller,Controller.pushTask,{DCSTask},WaitTime)
else
Controller:pushTask(DCSTask)
end
return self
end
return nil
end
function CONTROLLABLE:SetTask(DCSTask,WaitTime)
self:F2({DCSTask=DCSTask})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local DCSControllableName=self:GetName()
local function SetTask(Controller,DCSTask)
if self and self:IsAlive()then
local Controller=self:_GetController()
Controller:setTask(DCSTask)
else
BASE:E(DCSControllableName.." is not alive anymore. Cannot set DCSTask "..DCSTask)
end
end
if not WaitTime or WaitTime==0 then
SetTask(self,DCSTask)
else
self.TaskScheduler:Schedule(self,SetTask,{DCSTask},WaitTime)
end
return self
end
return nil
end
function CONTROLLABLE:HasTask()
local HasTaskResult=false
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
HasTaskResult=Controller:hasTask()
end
return HasTaskResult
end
function CONTROLLABLE:TaskCondition(time,userFlag,userFlagValue,condition,duration,lastWayPoint)
self:F2({time,userFlag,userFlagValue,condition,duration,lastWayPoint})
local DCSStopCondition={}
DCSStopCondition.time=time
DCSStopCondition.userFlag=userFlag
DCSStopCondition.userFlagValue=userFlagValue
DCSStopCondition.condition=condition
DCSStopCondition.duration=duration
DCSStopCondition.lastWayPoint=lastWayPoint
self:T3({DCSStopCondition})
return DCSStopCondition
end
function CONTROLLABLE:TaskControlled(DCSTask,DCSStopCondition)
self:F2({DCSTask,DCSStopCondition})
local DCSTaskControlled
DCSTaskControlled={
id='ControlledTask',
params={
task=DCSTask,
stopCondition=DCSStopCondition
}
}
self:T3({DCSTaskControlled})
return DCSTaskControlled
end
function CONTROLLABLE:TaskCombo(DCSTasks)
self:F2({DCSTasks})
local DCSTaskCombo
DCSTaskCombo={
id='ComboTask',
params={
tasks=DCSTasks
}
}
for TaskID,Task in ipairs(DCSTasks)do
self:T(Task)
end
self:T3({DCSTaskCombo})
return DCSTaskCombo
end
function CONTROLLABLE:TaskWrappedAction(DCSCommand,Index)
self:F2({DCSCommand})
local DCSTaskWrappedAction
DCSTaskWrappedAction={
id="WrappedAction",
enabled=true,
number=Index or 1,
auto=false,
params={
action=DCSCommand,
},
}
self:T3({DCSTaskWrappedAction})
return DCSTaskWrappedAction
end
function CONTROLLABLE:SetTaskWaypoint(Waypoint,Task)
Waypoint.task=self:TaskCombo({Task})
self:T3({Waypoint.task})
return Waypoint.task
end
function CONTROLLABLE:SetCommand(DCSCommand)
self:F2(DCSCommand)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
Controller:setCommand(DCSCommand)
return self
end
return nil
end
function CONTROLLABLE:CommandSwitchWayPoint(FromWayPoint,ToWayPoint)
self:F2({FromWayPoint,ToWayPoint})
local CommandSwitchWayPoint={
id='SwitchWaypoint',
params={
fromWaypointIndex=FromWayPoint,
goToWaypointIndex=ToWayPoint,
},
}
self:T3({CommandSwitchWayPoint})
return CommandSwitchWayPoint
end
function CONTROLLABLE:CommandStopRoute(StopRoute)
self:F2({StopRoute})
local CommandStopRoute={
id='StopRoute',
params={
value=StopRoute,
},
}
self:T3({CommandStopRoute})
return CommandStopRoute
end
function CONTROLLABLE:TaskAttackGroup(AttackGroup,WeaponType,WeaponExpend,AttackQty,Direction,Altitude,AttackQtyLimit)
self:F2({self.ControllableName,AttackGroup,WeaponType,WeaponExpend,AttackQty,Direction,Altitude,AttackQtyLimit})
local DirectionEnabled=nil
if Direction then
DirectionEnabled=true
end
local AltitudeEnabled=nil
if Altitude then
AltitudeEnabled=true
end
local DCSTask
DCSTask={id='AttackGroup',
params={
groupId=AttackGroup:GetID(),
weaponType=WeaponType,
expend=WeaponExpend,
attackQty=AttackQty,
directionEnabled=DirectionEnabled,
direction=Direction,
altitudeEnabled=AltitudeEnabled,
altitude=Altitude,
attackQtyLimit=AttackQtyLimit,
},
},
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskAttackUnit(AttackUnit,GroupAttack,WeaponExpend,AttackQty,Direction,Altitude,Visible,WeaponType)
self:F2({self.ControllableName,AttackUnit,GroupAttack,WeaponExpend,AttackQty,Direction,Altitude,Visible,WeaponType})
local DCSTask
DCSTask={
id='AttackUnit',
params={
unitId=AttackUnit:GetID(),
groupAttack=GroupAttack or false,
visible=Visible or false,
expend=WeaponExpend or"Auto",
directionEnabled=Direction and true or false,
direction=Direction,
altitudeEnabled=Altitude and true or false,
altitude=Altitude or 30,
attackQtyLimit=AttackQty and true or false,
attackQty=AttackQty,
weaponType=WeaponType
}
}
self:T3(DCSTask)
return DCSTask
end
function CONTROLLABLE:TaskBombing(Vec2,GroupAttack,WeaponExpend,AttackQty,Direction,Altitude,WeaponType)
self:F2({self.ControllableName,Vec2,GroupAttack,WeaponExpend,AttackQty,Direction,Altitude,WeaponType})
local DCSTask
DCSTask={
id='Bombing',
params={
point=Vec2,
groupAttack=GroupAttack or false,
expend=WeaponExpend or"Auto",
attackQtyLimit=AttackQty and true or false,
attackQty=AttackQty,
directionEnabled=Direction and true or false,
direction=Direction,
altitudeEnabled=Altitude and true or false,
altitude=Altitude or 30,
weaponType=WeaponType,
},
},
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskAttackMapObject(Vec2,GroupAttack,WeaponExpend,AttackQty,Direction,Altitude,WeaponType)
self:F2({self.ControllableName,Vec2,GroupAttack,WeaponExpend,AttackQty,Direction,Altitude,WeaponType})
local DCSTask
DCSTask={
id='AttackMapObject',
params={
point=Vec2,
groupAttack=GroupAttack or false,
expend=WeaponExpend or"Auto",
attackQtyLimit=AttackQty and true or false,
attackQty=AttackQty,
directionEnabled=Direction and true or false,
direction=Direction,
altitudeEnabled=Altitude and true or false,
altitude=Altitude or 30,
weaponType=WeaponType,
},
},
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskOrbitCircleAtVec2(Point,Altitude,Speed)
self:F2({self.ControllableName,Point,Altitude,Speed})
local LandHeight=land.getHeight(Point)
self:T3({LandHeight})
local DCSTask={id='Orbit',
params={pattern=AI.Task.OrbitPattern.CIRCLE,
point=Point,
speed=Speed,
altitude=Altitude+LandHeight
}
}
return DCSTask
end
function CONTROLLABLE:TaskOrbitCircle(Altitude,Speed)
self:F2({self.ControllableName,Altitude,Speed})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local ControllablePoint=self:GetVec2()
return self:TaskOrbitCircleAtVec2(ControllablePoint,Altitude,Speed)
end
return nil
end
function CONTROLLABLE:TaskHoldPosition()
self:F2({self.ControllableName})
return self:TaskOrbitCircle(30,10)
end
function CONTROLLABLE:TaskBombingRunway(Airbase,WeaponType,WeaponExpend,AttackQty,Direction,ControllableAttack)
self:F2({self.ControllableName,Airbase,WeaponType,WeaponExpend,AttackQty,Direction,ControllableAttack})
local DCSTask
DCSTask={id='BombingRunway',
params={
point=Airbase:GetID(),
weaponType=WeaponType,
expend=WeaponExpend,
attackQty=AttackQty,
direction=Direction,
controllableAttack=ControllableAttack,
},
},
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskRefueling()
self:F2({self.ControllableName})
local DCSTask
DCSTask={id='Refueling',
params={
},
},
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskLandAtVec2(Point,Duration)
self:F2({self.ControllableName,Point,Duration})
local DCSTask
if Duration and Duration>0 then
DCSTask={id='Land',
params={
point=Point,
durationFlag=true,
duration=Duration,
},
}
else
DCSTask={id='Land',
params={
point=Point,
durationFlag=false,
},
}
end
self:T3(DCSTask)
return DCSTask
end
function CONTROLLABLE:TaskLandAtZone(Zone,Duration,RandomPoint)
self:F2({self.ControllableName,Zone,Duration,RandomPoint})
local Point
if RandomPoint then
Point=Zone:GetRandomVec2()
else
Point=Zone:GetVec2()
end
local DCSTask=self:TaskLandAtVec2(Point,Duration)
self:T3(DCSTask)
return DCSTask
end
function CONTROLLABLE:TaskFollow(FollowControllable,Vec3,LastWaypointIndex)
self:F2({self.ControllableName,FollowControllable,Vec3,LastWaypointIndex})
local LastWaypointIndexFlag=false
if LastWaypointIndex then
LastWaypointIndexFlag=true
end
local DCSTask
DCSTask={
id='Follow',
params={
groupId=FollowControllable:GetID(),
pos=Vec3,
lastWptIndexFlag=LastWaypointIndexFlag,
lastWptIndex=LastWaypointIndex
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskEscort(FollowControllable,Vec3,LastWaypointIndex,EngagementDistance,TargetTypes)
self:F2({self.ControllableName,FollowControllable,Vec3,LastWaypointIndex,EngagementDistance,TargetTypes})
local LastWaypointIndexFlag=false
if LastWaypointIndex then
LastWaypointIndexFlag=true
end
local DCSTask
DCSTask={id='Escort',
params={
groupId=FollowControllable:GetID(),
pos=Vec3,
lastWptIndexFlag=LastWaypointIndexFlag,
lastWptIndex=LastWaypointIndex,
engagementDistMax=EngagementDistance,
targetTypes=TargetTypes,
},
},
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskFireAtPoint(Vec2,Radius,AmmoCount)
self:F2({self.ControllableName,Vec2,Radius,AmmoCount})
local DCSTask
DCSTask={id='FireAtPoint',
params={
point=Vec2,
radius=Radius,
expendQty=100,
expendQtyEnabled=false,
}
}
if AmmoCount then
DCSTask.params.expendQty=AmmoCount
DCSTask.params.expendQtyEnabled=true
end
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskHold()
self:F2({self.ControllableName})
local DCSTask
DCSTask={id='Hold',
params={
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskFAC_AttackGroup(AttackGroup,WeaponType,Designation,Datalink)
self:F2({self.ControllableName,AttackGroup,WeaponType,Designation,Datalink})
local DCSTask
DCSTask={id='FAC_AttackGroup',
params={
groupId=AttackGroup:GetID(),
weaponType=WeaponType,
designation=Designation,
datalink=Datalink,
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskEngageTargets(Distance,TargetTypes,Priority)
self:F2({self.ControllableName,Distance,TargetTypes,Priority})
local DCSTask
DCSTask={id='EngageTargets',
params={
maxDist=Distance,
targetTypes=TargetTypes,
priority=Priority
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskEngageTargetsInZone(Vec2,Radius,TargetTypes,Priority)
self:F2({self.ControllableName,Vec2,Radius,TargetTypes,Priority})
local DCSTask
DCSTask={id='EngageTargetsInZone',
params={
point=Vec2,
zoneRadius=Radius,
targetTypes=TargetTypes,
priority=Priority
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskEngageGroup(AttackGroup,Priority,WeaponType,WeaponExpend,AttackQty,Direction,Altitude,AttackQtyLimit)
self:F2({self.ControllableName,AttackGroup,Priority,WeaponType,WeaponExpend,AttackQty,Direction,Altitude,AttackQtyLimit})
local DirectionEnabled=nil
if Direction then
DirectionEnabled=true
end
local AltitudeEnabled=nil
if Altitude then
AltitudeEnabled=true
end
local DCSTask
DCSTask={id='EngageControllable',
params={
groupId=AttackGroup:GetID(),
weaponType=WeaponType,
expend=WeaponExpend,
attackQty=AttackQty,
directionEnabled=DirectionEnabled,
direction=Direction,
altitudeEnabled=AltitudeEnabled,
altitude=Altitude,
attackQtyLimit=AttackQtyLimit,
priority=Priority,
},
},
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskEngageUnit(EngageUnit,Priority,GroupAttack,WeaponExpend,AttackQty,Direction,Altitude,Visible,ControllableAttack)
self:F2({self.ControllableName,EngageUnit,Priority,GroupAttack,WeaponExpend,AttackQty,Direction,Altitude,Visible,ControllableAttack})
local DCSTask
DCSTask={id='EngageUnit',
params={
unitId=EngageUnit:GetID(),
priority=Priority or 1,
groupAttack=GroupAttack or false,
visible=Visible or false,
expend=WeaponExpend or"Auto",
directionEnabled=Direction and true or false,
direction=Direction,
altitudeEnabled=Altitude and true or false,
altitude=Altitude,
attackQtyLimit=AttackQty and true or false,
attackQty=AttackQty,
controllableAttack=ControllableAttack,
},
},
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskAWACS()
self:F2({self.ControllableName})
local DCSTask
DCSTask={id='AWACS',
params={
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskTanker()
self:F2({self.ControllableName})
local DCSTask
DCSTask={id='Tanker',
params={
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskEWR()
self:F2({self.ControllableName})
local DCSTask
DCSTask={id='EWR',
params={
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskFAC_EngageGroup(AttackGroup,Priority,WeaponType,Designation,Datalink)
self:F2({self.ControllableName,AttackGroup,WeaponType,Priority,Designation,Datalink})
local DCSTask
DCSTask={id='FAC_EngageControllable',
params={
groupId=AttackGroup:GetID(),
weaponType=WeaponType,
designation=Designation,
datalink=Datalink,
priority=Priority,
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:EnRouteTaskFAC(Radius,Priority)
self:F2({self.ControllableName,Radius,Priority})
local DCSTask
DCSTask={id='FAC',
params={
radius=Radius,
priority=Priority
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskEmbarking(Point,Duration,EmbarkingControllable)
self:F2({self.ControllableName,Point,Duration,EmbarkingControllable.DCSControllable})
local DCSTask
DCSTask={id='Embarking',
params={x=Point.x,
y=Point.y,
duration=Duration,
controllablesForEmbarking={EmbarkingControllable.ControllableID},
durationFlag=true,
distributionFlag=false,
distribution={},
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskEmbarkToTransport(Point,Radius)
self:F2({self.ControllableName,Point,Radius})
local DCSTask
DCSTask={id='EmbarkToTransport',
params={x=Point.x,
y=Point.y,
zoneRadius=Radius,
}
}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:TaskFunction(FunctionString,...)
self:F2({FunctionString,arg})
local DCSTask
local DCSScript={}
DCSScript[#DCSScript+1]="local MissionControllable = GROUP:Find( ... ) "
if arg and arg.n>0 then
local ArgumentKey='_'..tostring(arg):match("table: (.*)")
self:SetState(self,ArgumentKey,arg)
DCSScript[#DCSScript+1]="local Arguments = MissionControllable:GetState( MissionControllable, '"..ArgumentKey.."' ) "
DCSScript[#DCSScript+1]=FunctionString.."( MissionControllable, unpack( Arguments ) )"
else
DCSScript[#DCSScript+1]=FunctionString.."( MissionControllable )"
end
DCSTask=self:TaskWrappedAction(
self:CommandDoScript(
table.concat(DCSScript)
)
)
self:T(DCSTask)
return DCSTask
end
function CONTROLLABLE:TaskMission(TaskMission)
self:F2(Points)
local DCSTask
DCSTask={id='Mission',params={TaskMission,},}
self:T3({DCSTask})
return DCSTask
end
do
function CONTROLLABLE:PatrolRoute()
local PatrolGroup=self
if not self:IsInstanceOf("GROUP")then
PatrolGroup=self:GetGroup()
end
self:E({PatrolGroup=PatrolGroup:GetName()})
if PatrolGroup:IsGround()or PatrolGroup:IsShip()then
local Waypoints=PatrolGroup:GetTemplateRoutePoints()
local FromCoord=PatrolGroup:GetCoordinate()
local From=FromCoord:WaypointGround(120)
table.insert(Waypoints,1,From)
local TaskRoute=PatrolGroup:TaskFunction("CONTROLLABLE.PatrolRoute")
self:E({Waypoints=Waypoints})
local Waypoint=Waypoints[#Waypoints]
PatrolGroup:SetTaskWaypoint(Waypoint,TaskRoute)
PatrolGroup:Route(Waypoints)
end
end
function CONTROLLABLE:PatrolRouteRandom(Speed,Formation,ToWaypoint)
local PatrolGroup=self
if not self:IsInstanceOf("GROUP")then
PatrolGroup=self:GetGroup()
end
self:E({PatrolGroup=PatrolGroup:GetName()})
if PatrolGroup:IsGround()or PatrolGroup:IsShip()then
local Waypoints=PatrolGroup:GetTemplateRoutePoints()
local FromCoord=PatrolGroup:GetCoordinate()
local FromWaypoint=1
if ToWaypoint then
FromWaypoint=ToWaypoint
end
local ToWaypoint
repeat
ToWaypoint=math.random(1,#Waypoints)
until(ToWaypoint~=FromWaypoint)
self:E({FromWaypoint=FromWaypoint,ToWaypoint=ToWaypoint})
local Waypoint=Waypoints[ToWaypoint]
local ToCoord=COORDINATE:NewFromVec2({x=Waypoint.x,y=Waypoint.y})
local Route={}
Route[#Route+1]=FromCoord:WaypointGround(0)
Route[#Route+1]=ToCoord:WaypointGround(Speed,Formation)
local TaskRouteToZone=PatrolGroup:TaskFunction("CONTROLLABLE.PatrolRouteRandom",Speed,Formation,ToWaypoint)
PatrolGroup:SetTaskWaypoint(Route[#Route],TaskRouteToZone)
PatrolGroup:Route(Route,1)
end
end
function CONTROLLABLE:PatrolZones(ZoneList,Speed,Formation)
if not type(ZoneList)=="table"then
ZoneList={ZoneList}
end
local PatrolGroup=self
if not self:IsInstanceOf("GROUP")then
PatrolGroup=self:GetGroup()
end
self:E({PatrolGroup=PatrolGroup:GetName()})
if PatrolGroup:IsGround()or PatrolGroup:IsShip()then
local Waypoints=PatrolGroup:GetTemplateRoutePoints()
local Waypoint=Waypoints[math.random(1,#Waypoints)]
local FromCoord=PatrolGroup:GetCoordinate()
local RandomZone=ZoneList[math.random(1,#ZoneList)]
local ToCoord=RandomZone:GetRandomCoordinate(10)
local Route={}
Route[#Route+1]=FromCoord:WaypointGround(120)
Route[#Route+1]=ToCoord:WaypointGround(Speed,Formation)
local TaskRouteToZone=PatrolGroup:TaskFunction("CONTROLLABLE.PatrolZones",ZoneList,Speed,Formation)
PatrolGroup:SetTaskWaypoint(Route[#Route],TaskRouteToZone)
PatrolGroup:Route(Route,1)
end
end
end
function CONTROLLABLE:TaskRoute(Points)
self:F2(Points)
local DCSTask
DCSTask={id='Mission',params={route={points=Points,},},}
self:T3({DCSTask})
return DCSTask
end
function CONTROLLABLE:RouteToVec2(Point,Speed)
self:F2({Point,Speed})
local ControllablePoint=self:GetUnit(1):GetVec2()
local PointFrom={}
PointFrom.x=ControllablePoint.x
PointFrom.y=ControllablePoint.y
PointFrom.type="Turning Point"
PointFrom.action="Turning Point"
PointFrom.speed=Speed
PointFrom.speed_locked=true
PointFrom.properties={
["vnav"]=1,
["scale"]=0,
["angle"]=0,
["vangle"]=0,
["steer"]=2,
}
local PointTo={}
PointTo.x=Point.x
PointTo.y=Point.y
PointTo.type="Turning Point"
PointTo.action="Fly Over Point"
PointTo.speed=Speed
PointTo.speed_locked=true
PointTo.properties={
["vnav"]=1,
["scale"]=0,
["angle"]=0,
["vangle"]=0,
["steer"]=2,
}
local Points={PointFrom,PointTo}
self:T3(Points)
self:Route(Points)
return self
end
function CONTROLLABLE:RouteToVec3(Point,Speed)
self:F2({Point,Speed})
local ControllableVec3=self:GetUnit(1):GetVec3()
local PointFrom={}
PointFrom.x=ControllableVec3.x
PointFrom.y=ControllableVec3.z
PointFrom.alt=ControllableVec3.y
PointFrom.alt_type="BARO"
PointFrom.type="Turning Point"
PointFrom.action="Turning Point"
PointFrom.speed=Speed
PointFrom.speed_locked=true
PointFrom.properties={
["vnav"]=1,
["scale"]=0,
["angle"]=0,
["vangle"]=0,
["steer"]=2,
}
local PointTo={}
PointTo.x=Point.x
PointTo.y=Point.z
PointTo.alt=Point.y
PointTo.alt_type="BARO"
PointTo.type="Turning Point"
PointTo.action="Fly Over Point"
PointTo.speed=Speed
PointTo.speed_locked=true
PointTo.properties={
["vnav"]=1,
["scale"]=0,
["angle"]=0,
["vangle"]=0,
["steer"]=2,
}
local Points={PointFrom,PointTo}
self:T3(Points)
self:Route(Points)
return self
end
function CONTROLLABLE:Route(Route,DelaySeconds)
self:F2(Route)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local RouteTask=self:TaskRoute(Route)
self:SetTask(RouteTask,DelaySeconds or 1)
return self
end
return nil
end
function CONTROLLABLE:RouteGroundTo(ToCoordinate,Speed,Formation,DelaySeconds)
local FromCoordinate=self:GetCoordinate()
local FromWP=FromCoordinate:WaypointGround()
local ToWP=ToCoordinate:WaypointGround(Speed,Formation)
self:Route({FromWP,ToWP},DelaySeconds)
return self
end
function CONTROLLABLE:RouteAirTo(ToCoordinate,AltType,Type,Action,Speed,DelaySeconds)
local FromCoordinate=self:GetCoordinate()
local FromWP=FromCoordinate:WaypointAir()
local ToWP=ToCoordinate:WaypointAir(AltType,Type,Action,Speed)
self:Route({FromWP,ToWP},DelaySeconds)
return self
end
function CONTROLLABLE:TaskRouteToZone(Zone,Randomize,Speed,Formation)
self:F2(Zone)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local ControllablePoint=self:GetVec2()
local PointFrom={}
PointFrom.x=ControllablePoint.x
PointFrom.y=ControllablePoint.y
PointFrom.type="Turning Point"
PointFrom.action=Formation or"Cone"
PointFrom.speed=20/1.6
local PointTo={}
local ZonePoint
if Randomize then
ZonePoint=Zone:GetRandomVec2()
else
ZonePoint=Zone:GetVec2()
end
PointTo.x=ZonePoint.x
PointTo.y=ZonePoint.y
PointTo.type="Turning Point"
if Formation then
PointTo.action=Formation
else
PointTo.action="Cone"
end
if Speed then
PointTo.speed=Speed
else
PointTo.speed=20/1.6
end
local Points={PointFrom,PointTo}
self:T3(Points)
self:Route(Points)
return self
end
return nil
end
function CONTROLLABLE:TaskRouteToVec2(Vec2,Speed,Formation)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local ControllablePoint=self:GetVec2()
local PointFrom={}
PointFrom.x=ControllablePoint.x
PointFrom.y=ControllablePoint.y
PointFrom.type="Turning Point"
PointFrom.action=Formation or"Cone"
PointFrom.speed=20/1.6
local PointTo={}
PointTo.x=Vec2.x
PointTo.y=Vec2.y
PointTo.type="Turning Point"
if Formation then
PointTo.action=Formation
else
PointTo.action="Cone"
end
if Speed then
PointTo.speed=Speed
else
PointTo.speed=60/3.6
end
local Points={PointFrom,PointTo}
self:T3(Points)
self:Route(Points)
return self
end
return nil
end
function CONTROLLABLE:CommandDoScript(DoScript)
local DCSDoScript={
id="Script",
params={
command=DoScript,
},
}
self:T3(DCSDoScript)
return DCSDoScript
end
function CONTROLLABLE:GetTaskMission()
self:F2(self.ControllableName)
return routines.utils.deepCopy(_DATABASE.Templates.Controllables[self.ControllableName].Template)
end
function CONTROLLABLE:GetTaskRoute()
self:F2(self.ControllableName)
return routines.utils.deepCopy(_DATABASE.Templates.Controllables[self.ControllableName].Template.route.points)
end
function CONTROLLABLE:CopyRoute(Begin,End,Randomize,Radius)
self:F2({Begin,End})
local Points={}
local ControllableName=string.match(self:GetName(),".*#")
if ControllableName then
ControllableName=ControllableName:sub(1,-2)
else
ControllableName=self:GetName()
end
self:T3({ControllableName})
local Template=_DATABASE.Templates.Controllables[ControllableName].Template
if Template then
if not Begin then
Begin=0
end
if not End then
End=0
end
for TPointID=Begin+1,#Template.route.points-End do
if Template.route.points[TPointID]then
Points[#Points+1]=routines.utils.deepCopy(Template.route.points[TPointID])
if Randomize then
if not Radius then
Radius=500
end
Points[#Points].x=Points[#Points].x+math.random(Radius*-1,Radius)
Points[#Points].y=Points[#Points].y+math.random(Radius*-1,Radius)
end
end
end
return Points
else
error("Template not found for Controllable : "..ControllableName)
end
return nil
end
function CONTROLLABLE:GetDetectedTargets(DetectVisual,DetectOptical,DetectRadar,DetectIRST,DetectRWR,DetectDLINK)
self:F2(self.ControllableName)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local DetectionVisual=(DetectVisual and DetectVisual==true)and Controller.Detection.VISUAL or nil
local DetectionOptical=(DetectOptical and DetectOptical==true)and Controller.Detection.OPTICAL or nil
local DetectionRadar=(DetectRadar and DetectRadar==true)and Controller.Detection.RADAR or nil
local DetectionIRST=(DetectIRST and DetectIRST==true)and Controller.Detection.IRST or nil
local DetectionRWR=(DetectRWR and DetectRWR==true)and Controller.Detection.RWR or nil
local DetectionDLINK=(DetectDLINK and DetectDLINK==true)and Controller.Detection.DLINK or nil
self:T({DetectionVisual,DetectionOptical,DetectionRadar,DetectionIRST,DetectionRWR,DetectionDLINK})
return self:_GetController():getDetectedTargets(DetectionVisual,DetectionOptical,DetectionRadar,DetectionIRST,DetectionRWR,DetectionDLINK)
end
return nil
end
function CONTROLLABLE:IsTargetDetected(DCSObject,DetectVisual,DetectOptical,DetectRadar,DetectIRST,DetectRWR,DetectDLINK)
self:F2(self.ControllableName)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local DetectionVisual=(DetectVisual and DetectVisual==true)and Controller.Detection.VISUAL or nil
local DetectionOptical=(DetectOptical and DetectOptical==true)and Controller.Detection.OPTICAL or nil
local DetectionRadar=(DetectRadar and DetectRadar==true)and Controller.Detection.RADAR or nil
local DetectionIRST=(DetectIRST and DetectIRST==true)and Controller.Detection.IRST or nil
local DetectionRWR=(DetectRWR and DetectRWR==true)and Controller.Detection.RWR or nil
local DetectionDLINK=(DetectDLINK and DetectDLINK==true)and Controller.Detection.DLINK or nil
local Controller=self:_GetController()
local TargetIsDetected,TargetIsVisible,TargetLastTime,TargetKnowType,TargetKnowDistance,TargetLastPos,TargetLastVelocity
=Controller:isTargetDetected(DCSObject,DetectionVisual,DetectionOptical,DetectionRadar,DetectionIRST,DetectionRWR,DetectionDLINK)
return TargetIsDetected,TargetIsVisible,TargetLastTime,TargetKnowType,TargetKnowDistance,TargetLastPos,TargetLastVelocity
end
return nil
end
function CONTROLLABLE:OptionROEHoldFirePossible()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
if self:IsAir()or self:IsGround()or self:IsShip()then
return true
end
return false
end
return nil
end
function CONTROLLABLE:OptionROEHoldFire()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.WEAPON_HOLD)
elseif self:IsGround()then
Controller:setOption(AI.Option.Ground.id.ROE,AI.Option.Ground.val.ROE.WEAPON_HOLD)
elseif self:IsShip()then
Controller:setOption(AI.Option.Naval.id.ROE,AI.Option.Naval.val.ROE.WEAPON_HOLD)
end
return self
end
return nil
end
function CONTROLLABLE:OptionROEReturnFirePossible()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
if self:IsAir()or self:IsGround()or self:IsShip()then
return true
end
return false
end
return nil
end
function CONTROLLABLE:OptionROEReturnFire()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.RETURN_FIRE)
elseif self:IsGround()then
Controller:setOption(AI.Option.Ground.id.ROE,AI.Option.Ground.val.ROE.RETURN_FIRE)
elseif self:IsShip()then
Controller:setOption(AI.Option.Naval.id.ROE,AI.Option.Naval.val.ROE.RETURN_FIRE)
end
return self
end
return nil
end
function CONTROLLABLE:OptionROEOpenFirePossible()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
if self:IsAir()or self:IsGround()or self:IsShip()then
return true
end
return false
end
return nil
end
function CONTROLLABLE:OptionROEOpenFire()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.OPEN_FIRE)
elseif self:IsGround()then
Controller:setOption(AI.Option.Ground.id.ROE,AI.Option.Ground.val.ROE.OPEN_FIRE)
elseif self:IsShip()then
Controller:setOption(AI.Option.Naval.id.ROE,AI.Option.Naval.val.ROE.OPEN_FIRE)
end
return self
end
return nil
end
function CONTROLLABLE:OptionROEWeaponFreePossible()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
if self:IsAir()then
return true
end
return false
end
return nil
end
function CONTROLLABLE:OptionROEWeaponFree()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.ROE,AI.Option.Air.val.ROE.WEAPON_FREE)
end
return self
end
return nil
end
function CONTROLLABLE:OptionROTNoReactionPossible()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
if self:IsAir()then
return true
end
return false
end
return nil
end
function CONTROLLABLE:OptionROTNoReaction()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION)
end
return self
end
return nil
end
function CONTROLLABLE:OptionROTPassiveDefensePossible()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
if self:IsAir()then
return true
end
return false
end
return nil
end
function CONTROLLABLE:OptionROTPassiveDefense()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.PASSIVE_DEFENCE)
end
return self
end
return nil
end
function CONTROLLABLE:OptionROTEvadeFirePossible()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
if self:IsAir()then
return true
end
return false
end
return nil
end
function CONTROLLABLE:OptionROTEvadeFire()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
end
return self
end
return nil
end
function CONTROLLABLE:OptionROTVerticalPossible()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
if self:IsAir()then
return true
end
return false
end
return nil
end
function CONTROLLABLE:OptionROTVertical()
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT,AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE)
end
return self
end
return nil
end
function CONTROLLABLE:OptionRTBBingoFuel(RTB)
self:F2({self.ControllableName})
RTB=RTB or true
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.Air.id.RTB_ON_BINGO,RTB)
end
return self
end
return nil
end
function CONTROLLABLE:OptionRTBAmmo(WeaponsFlag)
self:F2({self.ControllableName})
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local Controller=self:_GetController()
if self:IsAir()then
Controller:setOption(AI.Option.GROUND.id.RTB_ON_OUT_OF_AMMO,WeaponsFlag)
end
return self
end
return nil
end
function CONTROLLABLE:WayPointInitialize(WayPoints)
self:F({WayPoints})
if WayPoints then
self.WayPoints=WayPoints
else
self.WayPoints=self:GetTaskRoute()
end
return self
end
function CONTROLLABLE:GetWayPoints()
self:F()
if self.WayPoints then
return self.WayPoints
end
return nil
end
function CONTROLLABLE:WayPointFunction(WayPoint,WayPointIndex,WayPointFunction,...)
self:F2({WayPoint,WayPointIndex,WayPointFunction})
table.insert(self.WayPoints[WayPoint].task.params.tasks,WayPointIndex)
self.WayPoints[WayPoint].task.params.tasks[WayPointIndex]=self:TaskFunction(WayPointFunction,arg)
return self
end
function CONTROLLABLE:WayPointExecute(WayPoint,WaitTime)
self:F({WayPoint,WaitTime})
if not WayPoint then
WayPoint=1
end
for TaskPointID=1,WayPoint-1 do
table.remove(self.WayPoints,1)
end
self:T3(self.WayPoints)
self:SetTask(self:TaskRoute(self.WayPoints),WaitTime)
return self
end
function CONTROLLABLE:IsAirPlane()
self:F2()
local DCSObject=self:GetDCSObject()
if DCSObject then
local Category=DCSObject:getDesc().category
return Category==Unit.Category.AIRPLANE
end
return nil
end
function CONTROLLABLE:GetSize()
local DCSObject=self:GetDCSObject()
if DCSObject then
return 1
else
return 0
end
end
GROUP={
ClassName="GROUP",
}
GROUP.Takeoff={
Air=1,
Runway=2,
Hot=3,
Cold=4,
}
GROUPTEMPLATE={}
GROUPTEMPLATE.Takeoff={
[GROUP.Takeoff.Air]={"Turning Point","Turning Point"},
[GROUP.Takeoff.Runway]={"TakeOff","From Runway"},
[GROUP.Takeoff.Hot]={"TakeOffParkingHot","From Parking Area Hot"},
[GROUP.Takeoff.Cold]={"TakeOffParking","From Parking Area"}
}
function GROUP:Register(GroupName)
self=BASE:Inherit(self,CONTROLLABLE:New(GroupName))
self:F2(GroupName)
self.GroupName=GroupName
self:SetEventPriority(4)
return self
end
function GROUP:Find(DCSGroup)
local GroupName=DCSGroup:getName()
local GroupFound=_DATABASE:FindGroup(GroupName)
return GroupFound
end
function GROUP:FindByName(GroupName)
local GroupFound=_DATABASE:FindGroup(GroupName)
return GroupFound
end
function GROUP:GetDCSObject()
local DCSGroup=Group.getByName(self.GroupName)
if DCSGroup then
return DCSGroup
end
return nil
end
function GROUP:GetPositionVec3()
self:F2(self.PositionableName)
local DCSPositionable=self:GetDCSObject()
if DCSPositionable then
local PositionablePosition=DCSPositionable:getUnits()[1]:getPosition().p
self:T3(PositionablePosition)
return PositionablePosition
end
return nil
end
function GROUP:IsAlive()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
if DCSGroup:isExist()then
local DCSUnit=DCSGroup:getUnit(1)
if DCSUnit then
local GroupIsAlive=DCSUnit:isActive()
self:T3(GroupIsAlive)
return GroupIsAlive
end
end
end
return nil
end
function GROUP:Destroy()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
for Index,UnitData in pairs(DCSGroup:getUnits())do
self:CreateEventCrash(timer.getTime(),UnitData)
end
DCSGroup:destroy()
DCSGroup=nil
end
return nil
end
function GROUP:GetCategory()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupCategory=DCSGroup:getCategory()
self:T3(GroupCategory)
return GroupCategory
end
return nil
end
function GROUP:GetCategoryName()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local CategoryNames={
[Group.Category.AIRPLANE]="Airplane",
[Group.Category.HELICOPTER]="Helicopter",
[Group.Category.GROUND]="Ground Unit",
[Group.Category.SHIP]="Ship",
}
local GroupCategory=DCSGroup:getCategory()
self:T3(GroupCategory)
return CategoryNames[GroupCategory]
end
return nil
end
function GROUP:GetCoalition()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupCoalition=DCSGroup:getCoalition()
self:T3(GroupCoalition)
return GroupCoalition
end
return nil
end
function GROUP:GetCountry()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupCountry=DCSGroup:getUnit(1):getCountry()
self:T3(GroupCountry)
return GroupCountry
end
return nil
end
function GROUP:GetUnit(UnitNumber)
self:F2({self.GroupName,UnitNumber})
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local DCSUnit=DCSGroup:getUnit(UnitNumber)
local UnitFound=UNIT:Find(DCSGroup:getUnit(UnitNumber))
self:T2(UnitFound)
return UnitFound
end
return nil
end
function GROUP:GetDCSUnit(UnitNumber)
self:F2({self.GroupName,UnitNumber})
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local DCSUnitFound=DCSGroup:getUnit(UnitNumber)
self:T3(DCSUnitFound)
return DCSUnitFound
end
return nil
end
function GROUP:GetSize()
self:F2({self.GroupName})
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupSize=DCSGroup:getSize()
if GroupSize then
self:T3(GroupSize)
return GroupSize
else
return 0
end
end
return nil
end
function GROUP:GetInitialSize()
self:F2({self.GroupName})
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupInitialSize=DCSGroup:getInitialSize()
self:T3(GroupInitialSize)
return GroupInitialSize
end
return nil
end
function GROUP:GetDCSUnits()
self:F2({self.GroupName})
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local DCSUnits=DCSGroup:getUnits()
self:T3(DCSUnits)
return DCSUnits
end
return nil
end
function GROUP:Activate()
self:F2({self.GroupName})
trigger.action.activateGroup(self:GetDCSObject())
return self:GetDCSObject()
end
function GROUP:GetTypeName()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupTypeName=DCSGroup:getUnit(1):getTypeName()
self:T3(GroupTypeName)
return(GroupTypeName)
end
return nil
end
function GROUP:GetPlayerName()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local PlayerName=DCSGroup:getUnit(1):getPlayerName()
self:T3(PlayerName)
return(PlayerName)
end
return nil
end
function GROUP:GetCallsign()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupCallSign=DCSGroup:getUnit(1):getCallsign()
self:T3(GroupCallSign)
return GroupCallSign
end
return nil
end
function GROUP:GetVec2()
self:F2(self.GroupName)
local UnitPoint=self:GetUnit(1)
UnitPoint:GetVec2()
local GroupPointVec2=UnitPoint:GetVec2()
self:T3(GroupPointVec2)
return GroupPointVec2
end
function GROUP:GetVec3()
self:F2(self.GroupName)
local GroupVec3=self:GetUnit(1):GetVec3()
self:T3(GroupVec3)
return GroupVec3
end
function GROUP:GetPointVec2()
self:F2(self.GroupName)
local FirstUnit=self:GetUnit(1)
if FirstUnit then
local FirstUnitPointVec2=FirstUnit:GetPointVec2()
self:T3(FirstUnitPointVec2)
return FirstUnitPointVec2
end
return nil
end
function GROUP:GetCoordinate()
self:F2(self.PositionableName)
local FirstUnit=self:GetUnit(1)
if FirstUnit then
local FirstUnitCoordinate=FirstUnit:GetCoordinate()
self:T3(FirstUnitCoordinate)
return FirstUnitCoordinate
end
return nil
end
function GROUP:GetRandomVec3(Radius)
self:F2(self.GroupName)
local FirstUnit=self:GetUnit(1)
if FirstUnit then
local FirstUnitRandomPointVec3=FirstUnit:GetRandomVec3(Radius)
self:T3(FirstUnitRandomPointVec3)
return FirstUnitRandomPointVec3
end
return nil
end
function GROUP:GetHeading()
self:F2(self.GroupName)
local GroupSize=self:GetSize()
local HeadingAccumulator=0
if GroupSize then
for i=1,GroupSize do
HeadingAccumulator=HeadingAccumulator+self:GetUnit(i):GetHeading()
end
return math.floor(HeadingAccumulator/GroupSize)
end
return nil
end
function GROUP:GetFuel()
self:F(self.ControllableName)
local DCSControllable=self:GetDCSObject()
if DCSControllable then
local GroupSize=self:GetSize()
local TotalFuel=0
for UnitID,UnitData in pairs(self:GetUnits())do
local Unit=UnitData
local UnitFuel=Unit:GetFuel()
self:F({Fuel=UnitFuel})
TotalFuel=TotalFuel+UnitFuel
end
local GroupFuel=TotalFuel/GroupSize
return GroupFuel
end
return 0
end
do
function GROUP:IsCompletelyInZone(Zone)
self:F2({self.GroupName,Zone})
if not self:IsAlive()then return false end
for UnitID,UnitData in pairs(self:GetUnits())do
local Unit=UnitData
if Zone:IsVec3InZone(Unit:GetVec3())then
else
return false
end
end
return true
end
function GROUP:IsPartlyInZone(Zone)
self:F2({self.GroupName,Zone})
local IsOneUnitInZone=false
local IsOneUnitOutsideZone=false
if not self:IsAlive()then return false end
for UnitID,UnitData in pairs(self:GetUnits())do
local Unit=UnitData
if Zone:IsVec3InZone(Unit:GetVec3())then
IsOneUnitInZone=true
else
IsOneUnitOutsideZone=true
end
end
if IsOneUnitInZone and IsOneUnitOutsideZone then
return true
else
return false
end
end
function GROUP:IsNotInZone(Zone)
self:F2({self.GroupName,Zone})
if not self:IsAlive()then return true end
for UnitID,UnitData in pairs(self:GetUnits())do
local Unit=UnitData
if Zone:IsVec3InZone(Unit:GetVec3())then
return false
end
end
return true
end
function GROUP:CountInZone(Zone)
self:F2({self.GroupName,Zone})
local Count=0
if not self:IsAlive()then return Count end
for UnitID,UnitData in pairs(self:GetUnits())do
local Unit=UnitData
if Zone:IsVec3InZone(Unit:GetVec3())then
Count=Count+1
end
end
return Count
end
function GROUP:IsAir()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local IsAirResult=DCSGroup:getCategory()==Group.Category.AIRPLANE or DCSGroup:getCategory()==Group.Category.HELICOPTER
self:T3(IsAirResult)
return IsAirResult
end
return nil
end
function GROUP:IsHelicopter()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupCategory=DCSGroup:getCategory()
self:T2(GroupCategory)
return GroupCategory==Group.Category.HELICOPTER
end
return nil
end
function GROUP:IsAirPlane()
self:F2()
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupCategory=DCSGroup:getCategory()
self:T2(GroupCategory)
return GroupCategory==Group.Category.AIRPLANE
end
return nil
end
function GROUP:IsGround()
self:F2()
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupCategory=DCSGroup:getCategory()
self:T2(GroupCategory)
return GroupCategory==Group.Category.GROUND
end
return nil
end
function GROUP:IsShip()
self:F2()
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupCategory=DCSGroup:getCategory()
self:T2(GroupCategory)
return GroupCategory==Group.Category.SHIP
end
return nil
end
function GROUP:AllOnGround()
self:F2()
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local AllOnGroundResult=true
for Index,UnitData in pairs(DCSGroup:getUnits())do
if UnitData:inAir()then
AllOnGroundResult=false
end
end
self:T3(AllOnGroundResult)
return AllOnGroundResult
end
return nil
end
end
do
function GROUP:SetAIOnOff(AIOnOff)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local DCSController=DCSGroup:getController()
if DCSController then
DCSController:setOnOff(AIOnOff)
return self
end
end
return nil
end
function GROUP:SetAIOn()
return self:SetAIOnOff(true)
end
function GROUP:SetAIOff()
return self:SetAIOnOff(false)
end
end
function GROUP:GetMaxVelocity()
self:F2()
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local GroupVelocityMax=0
for Index,UnitData in pairs(DCSGroup:getUnits())do
local UnitVelocityVec3=UnitData:getVelocity()
local UnitVelocity=math.abs(UnitVelocityVec3.x)+math.abs(UnitVelocityVec3.y)+math.abs(UnitVelocityVec3.z)
if UnitVelocity>GroupVelocityMax then
GroupVelocityMax=UnitVelocity
end
end
return GroupVelocityMax
end
return nil
end
function GROUP:GetMinHeight()
self:F2()
end
function GROUP:GetMaxHeight()
self:F2()
end
function GROUP:Respawn(Template)
if self:IsAlive()then
local Vec3=self:GetVec3()
Template.x=Vec3.x
Template.y=Vec3.z
self:E(#Template.units)
for UnitID,UnitData in pairs(self:GetUnits())do
local GroupUnit=UnitData
self:E(GroupUnit:GetName())
if GroupUnit:IsAlive()then
local GroupUnitVec3=GroupUnit:GetVec3()
local GroupUnitHeading=GroupUnit:GetHeading()
Template.units[UnitID].alt=GroupUnitVec3.y
Template.units[UnitID].x=GroupUnitVec3.x
Template.units[UnitID].y=GroupUnitVec3.z
Template.units[UnitID].heading=GroupUnitHeading
self:E({UnitID,Template.units[UnitID],Template.units[UnitID]})
end
end
end
self:Destroy()
_DATABASE:Spawn(Template)
self:ResetEvents()
end
function GROUP:GetTemplate()
local GroupName=self:GetName()
return UTILS.DeepCopy(_DATABASE:GetGroupTemplate(GroupName))
end
function GROUP:GetTemplateRoutePoints()
local GroupName=self:GetName()
return UTILS.DeepCopy(_DATABASE:GetGroupTemplate(GroupName).route.points)
end
function GROUP:SetTemplateControlled(Template,Controlled)
Template.uncontrolled=not Controlled
return Template
end
function GROUP:SetTemplateCountry(Template,CountryID)
Template.CountryID=CountryID
return Template
end
function GROUP:SetTemplateCoalition(Template,CoalitionID)
Template.CoalitionID=CoalitionID
return Template
end
function GROUP:GetTaskMission()
self:F2(self.GroupName)
return routines.utils.deepCopy(_DATABASE.Templates.Groups[self.GroupName].Template)
end
function GROUP:GetTaskRoute()
self:F2(self.GroupName)
return routines.utils.deepCopy(_DATABASE.Templates.Groups[self.GroupName].Template.route.points)
end
function GROUP:CopyRoute(Begin,End,Randomize,Radius)
self:F2({Begin,End})
local Points={}
local GroupName=string.match(self:GetName(),".*#")
if GroupName then
GroupName=GroupName:sub(1,-2)
else
GroupName=self:GetName()
end
self:T3({GroupName})
local Template=_DATABASE.Templates.Groups[GroupName].Template
if Template then
if not Begin then
Begin=0
end
if not End then
End=0
end
for TPointID=Begin+1,#Template.route.points-End do
if Template.route.points[TPointID]then
Points[#Points+1]=routines.utils.deepCopy(Template.route.points[TPointID])
if Randomize then
if not Radius then
Radius=500
end
Points[#Points].x=Points[#Points].x+math.random(Radius*-1,Radius)
Points[#Points].y=Points[#Points].y+math.random(Radius*-1,Radius)
end
end
end
return Points
else
error("Template not found for Group : "..GroupName)
end
return nil
end
function GROUP:CalculateThreatLevelA2G()
local MaxThreatLevelA2G=0
for UnitName,UnitData in pairs(self:GetUnits())do
local ThreatUnit=UnitData
local ThreatLevelA2G=ThreatUnit:GetThreatLevel()
if ThreatLevelA2G>MaxThreatLevelA2G then
MaxThreatLevelA2G=ThreatLevelA2G
end
end
self:T3(MaxThreatLevelA2G)
return MaxThreatLevelA2G
end
function GROUP:InAir()
self:F2(self.GroupName)
local DCSGroup=self:GetDCSObject()
if DCSGroup then
local DCSUnit=DCSGroup:getUnit(1)
if DCSUnit then
local GroupInAir=DCSGroup:getUnit(1):inAir()
self:T3(GroupInAir)
return GroupInAir
end
end
return nil
end
do
function GROUP:RouteRTB(RTBAirbase,Speed)
self:F2({RTBAirbase,Speed})
local DCSGroup=self:GetDCSObject()
if DCSGroup then
if RTBAirbase then
local GroupPoint=self:GetVec2()
local GroupVelocity=self:GetUnit(1):GetDesc().speedMax
local PointFrom={}
PointFrom.x=GroupPoint.x
PointFrom.y=GroupPoint.y
PointFrom.type="Turning Point"
PointFrom.action="Turning Point"
PointFrom.speed=GroupVelocity
local PointTo={}
local AirbasePointVec2=RTBAirbase:GetPointVec2()
local AirbaseAirPoint=AirbasePointVec2:WaypointAir(
POINT_VEC3.RoutePointAltType.BARO,
"Land",
"Landing",
Speed or self:GetUnit(1):GetDesc().speedMax
)
AirbaseAirPoint["airdromeId"]=RTBAirbase:GetID()
AirbaseAirPoint["speed_locked"]=true,
self:E(AirbaseAirPoint)
local Points={PointFrom,AirbaseAirPoint}
self:T3(Points)
local Template=self:GetTemplate()
Template.route.points=Points
self:Respawn(Template)
self:Route(Points)
self:Respawn(Template)
else
self:ClearTasks()
end
end
return self
end
end
function GROUP:OnReSpawn(ReSpawnFunction)
self.ReSpawnFunction=ReSpawnFunction
end
do
function GROUP:HandleEvent(Event,EventFunction,...)
self:EventDispatcher():OnEventForGroup(self:GetName(),EventFunction,self,Event,...)
return self
end
function GROUP:UnHandleEvent(Event)
self:EventDispatcher():RemoveEvent(self,Event)
return self
end
function GROUP:ResetEvents()
self:EventDispatcher():Reset(self)
for UnitID,UnitData in pairs(self:GetUnits())do
UnitData:ResetEvents()
end
return self
end
end
do
function GROUP:GetPlayerNames()
local PlayerNames={}
local Units=self:GetUnits()
for UnitID,UnitData in pairs(Units)do
local Unit=UnitData
local PlayerName=Unit:GetPlayerName()
if PlayerName and PlayerName~=""then
PlayerNames=PlayerNames or{}
table.insert(PlayerNames,PlayerName)
end
end
self:F2(PlayerNames)
return PlayerNames
end
end
UNIT={
ClassName="UNIT",
}
function UNIT:Register(UnitName)
local self=BASE:Inherit(self,CONTROLLABLE:New(UnitName))
self.UnitName=UnitName
self:SetEventPriority(3)
return self
end
function UNIT:Find(DCSUnit)
local UnitName=DCSUnit:getName()
local UnitFound=_DATABASE:FindUnit(UnitName)
return UnitFound
end
function UNIT:FindByName(UnitName)
local UnitFound=_DATABASE:FindUnit(UnitName)
return UnitFound
end
function UNIT:Name()
return self.UnitName
end
function UNIT:GetDCSObject()
local DCSUnit=Unit.getByName(self.UnitName)
if DCSUnit then
return DCSUnit
end
return nil
end
function UNIT:ReSpawn(SpawnVec3,Heading)
local SpawnGroupTemplate=UTILS.DeepCopy(_DATABASE:GetGroupTemplateFromUnitName(self:Name()))
self:T(SpawnGroupTemplate)
local SpawnGroup=self:GetGroup()
if SpawnGroup then
local Vec3=SpawnGroup:GetVec3()
SpawnGroupTemplate.x=SpawnVec3.x
SpawnGroupTemplate.y=SpawnVec3.z
self:E(#SpawnGroupTemplate.units)
for UnitID,UnitData in pairs(SpawnGroup:GetUnits())do
local GroupUnit=UnitData
self:E(GroupUnit:GetName())
if GroupUnit:IsAlive()then
local GroupUnitVec3=GroupUnit:GetVec3()
local GroupUnitHeading=GroupUnit:GetHeading()
SpawnGroupTemplate.units[UnitID].alt=GroupUnitVec3.y
SpawnGroupTemplate.units[UnitID].x=GroupUnitVec3.x
SpawnGroupTemplate.units[UnitID].y=GroupUnitVec3.z
SpawnGroupTemplate.units[UnitID].heading=GroupUnitHeading
self:E({UnitID,SpawnGroupTemplate.units[UnitID],SpawnGroupTemplate.units[UnitID]})
end
end
end
for UnitTemplateID,UnitTemplateData in pairs(SpawnGroupTemplate.units)do
self:T(UnitTemplateData.name)
if UnitTemplateData.name==self:Name()then
self:T("Adjusting")
SpawnGroupTemplate.units[UnitTemplateID].alt=SpawnVec3.y
SpawnGroupTemplate.units[UnitTemplateID].x=SpawnVec3.x
SpawnGroupTemplate.units[UnitTemplateID].y=SpawnVec3.z
SpawnGroupTemplate.units[UnitTemplateID].heading=Heading
self:E({UnitTemplateID,SpawnGroupTemplate.units[UnitTemplateID],SpawnGroupTemplate.units[UnitTemplateID]})
else
self:E(SpawnGroupTemplate.units[UnitTemplateID].name)
local GroupUnit=UNIT:FindByName(SpawnGroupTemplate.units[UnitTemplateID].name)
if GroupUnit and GroupUnit:IsAlive()then
local GroupUnitVec3=GroupUnit:GetVec3()
local GroupUnitHeading=GroupUnit:GetHeading()
UnitTemplateData.alt=GroupUnitVec3.y
UnitTemplateData.x=GroupUnitVec3.x
UnitTemplateData.y=GroupUnitVec3.z
UnitTemplateData.heading=GroupUnitHeading
else
if SpawnGroupTemplate.units[UnitTemplateID].name~=self:Name()then
self:T("nilling")
SpawnGroupTemplate.units[UnitTemplateID].delete=true
end
end
end
end
local i=1
while i<=#SpawnGroupTemplate.units do
local UnitTemplateData=SpawnGroupTemplate.units[i]
self:T(UnitTemplateData.name)
if UnitTemplateData.delete then
table.remove(SpawnGroupTemplate.units,i)
else
i=i+1
end
end
_DATABASE:Spawn(SpawnGroupTemplate)
end
function UNIT:IsActive()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitIsActive=DCSUnit:isActive()
return UnitIsActive
end
return nil
end
function UNIT:IsAlive()
self:F3(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitIsAlive=DCSUnit:isExist()and DCSUnit:isActive()
return UnitIsAlive
end
return nil
end
function UNIT:GetCallsign()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitCallSign=DCSUnit:getCallsign()
return UnitCallSign
end
self:E(self.ClassName.." "..self.UnitName.." not found!")
return nil
end
function UNIT:GetPlayerName()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local PlayerName=DCSUnit:getPlayerName()
if PlayerName==nil then
PlayerName=""
end
return PlayerName
end
return nil
end
function UNIT:GetNumber()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitNumber=DCSUnit:getNumber()
return UnitNumber
end
return nil
end
function UNIT:GetGroup()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitGroup=GROUP:Find(DCSUnit:getGroup())
return UnitGroup
end
return nil
end
function UNIT:GetPrefix()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitPrefix=string.match(self.UnitName,".*#"):sub(1,-2)
self:T3(UnitPrefix)
return UnitPrefix
end
return nil
end
function UNIT:GetAmmo()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitAmmo=DCSUnit:getAmmo()
return UnitAmmo
end
return nil
end
function UNIT:GetSensors()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitSensors=DCSUnit:getSensors()
return UnitSensors
end
return nil
end
function UNIT:HasSensors(...)
self:F2(arg)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local HasSensors=DCSUnit:hasSensors(unpack(arg))
return HasSensors
end
return nil
end
function UNIT:HasSEAD()
self:F2()
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitSEADAttributes=DCSUnit:getDesc().attributes
local HasSEAD=false
if UnitSEADAttributes["RADAR_BAND1_FOR_ARM"]and UnitSEADAttributes["RADAR_BAND1_FOR_ARM"]==true or
UnitSEADAttributes["RADAR_BAND2_FOR_ARM"]and UnitSEADAttributes["RADAR_BAND2_FOR_ARM"]==true then
HasSEAD=true
end
return HasSEAD
end
return nil
end
function UNIT:GetRadar()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitRadarOn,UnitRadarObject=DCSUnit:getRadar()
return UnitRadarOn,UnitRadarObject
end
return nil,nil
end
function UNIT:GetFuel()
self:F(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitFuel=DCSUnit:getFuel()
return UnitFuel
end
return nil
end
function UNIT:GetUnits()
self:F2({self.UnitName})
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local DCSUnits=DCSUnit:getUnits()
local Units={}
Units[1]=UNIT:Find(DCSUnit)
self:T3(Units)
return Units
end
return nil
end
function UNIT:GetLife()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitLife=DCSUnit:getLife()
return UnitLife
end
return-1
end
function UNIT:GetLife0()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitLife0=DCSUnit:getLife0()
return UnitLife0
end
return 0
end
function UNIT:GetCategoryName()
self:F3(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local CategoryNames={
[Unit.Category.AIRPLANE]="Airplane",
[Unit.Category.HELICOPTER]="Helicopter",
[Unit.Category.GROUND_UNIT]="Ground Unit",
[Unit.Category.SHIP]="Ship",
[Unit.Category.STRUCTURE]="Structure",
}
local UnitCategory=DCSUnit:getDesc().category
self:T3(UnitCategory)
return CategoryNames[UnitCategory]
end
return nil
end
function UNIT:GetThreatLevel()
local ThreatLevel=0
local ThreatText=""
local Descriptor=self:GetDesc()
if Descriptor then
local Attributes=Descriptor.attributes
self:T(Attributes)
if self:IsGround()then
self:T("Ground")
local ThreatLevels={
"Unarmed",
"Infantry",
"Old Tanks & APCs",
"Tanks & IFVs without ATGM",
"Tanks & IFV with ATGM",
"Modern Tanks",
"AAA",
"IR Guided SAMs",
"SR SAMs",
"MR SAMs",
"LR SAMs"
}
if Attributes["LR SAM"]then ThreatLevel=10
elseif Attributes["MR SAM"]then ThreatLevel=9
elseif Attributes["SR SAM"]and
not Attributes["IR Guided SAM"]then ThreatLevel=8
elseif(Attributes["SR SAM"]or Attributes["MANPADS"])and
Attributes["IR Guided SAM"]then ThreatLevel=7
elseif Attributes["AAA"]then ThreatLevel=6
elseif Attributes["Modern Tanks"]then ThreatLevel=5
elseif(Attributes["Tanks"]or Attributes["IFV"])and
Attributes["ATGM"]then ThreatLevel=4
elseif(Attributes["Tanks"]or Attributes["IFV"])and
not Attributes["ATGM"]then ThreatLevel=3
elseif Attributes["Old Tanks"]or Attributes["APC"]or Attributes["Artillery"]then ThreatLevel=2
elseif Attributes["Infantry"]then ThreatLevel=1
end
ThreatText=ThreatLevels[ThreatLevel+1]
end
if self:IsAir()then
self:T("Air")
local ThreatLevels={
"Unarmed",
"Tanker",
"AWACS",
"Transport Helicopter",
"UAV",
"Bomber",
"Strategic Bomber",
"Attack Helicopter",
"Battleplane",
"Multirole Fighter",
"Fighter"
}
if Attributes["Fighters"]then ThreatLevel=10
elseif Attributes["Multirole fighters"]then ThreatLevel=9
elseif Attributes["Battleplanes"]then ThreatLevel=8
elseif Attributes["Attack helicopters"]then ThreatLevel=7
elseif Attributes["Strategic bombers"]then ThreatLevel=6
elseif Attributes["Bombers"]then ThreatLevel=5
elseif Attributes["UAVs"]then ThreatLevel=4
elseif Attributes["Transport helicopters"]then ThreatLevel=3
elseif Attributes["AWACS"]then ThreatLevel=2
elseif Attributes["Tankers"]then ThreatLevel=1
end
ThreatText=ThreatLevels[ThreatLevel+1]
end
if self:IsShip()then
self:T("Ship")
local ThreatLevels={
"Unarmed ship",
"Light armed ships",
"Corvettes",
"",
"Frigates",
"",
"Cruiser",
"",
"Destroyer",
"",
"Aircraft Carrier"
}
if Attributes["Aircraft Carriers"]then ThreatLevel=10
elseif Attributes["Destroyers"]then ThreatLevel=8
elseif Attributes["Cruisers"]then ThreatLevel=6
elseif Attributes["Frigates"]then ThreatLevel=4
elseif Attributes["Corvettes"]then ThreatLevel=2
elseif Attributes["Light armed ships"]then ThreatLevel=1
end
ThreatText=ThreatLevels[ThreatLevel+1]
end
end
self:T2(ThreatLevel)
return ThreatLevel,ThreatText
end
function UNIT:IsInZone(Zone)
self:F2({self.UnitName,Zone})
if self:IsAlive()then
local IsInZone=Zone:IsVec3InZone(self:GetVec3())
self:T2({IsInZone})
return IsInZone
end
return false
end
function UNIT:IsNotInZone(Zone)
self:F2({self.UnitName,Zone})
if self:IsAlive()then
local IsInZone=not Zone:IsVec3InZone(self:GetVec3())
self:T({IsInZone})
return IsInZone
else
return false
end
end
function UNIT:OtherUnitInRadius(AwaitUnit,Radius)
self:F2({self.UnitName,AwaitUnit.UnitName,Radius})
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitVec3=self:GetVec3()
local AwaitUnitVec3=AwaitUnit:GetVec3()
if(((UnitVec3.x-AwaitUnitVec3.x)^2+(UnitVec3.z-AwaitUnitVec3.z)^2)^0.5<=Radius)then
self:T3("true")
return true
else
self:T3("false")
return false
end
end
return nil
end
function UNIT:IsAir()
self:F2()
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitDescriptor=DCSUnit:getDesc()
self:T3({UnitDescriptor.category,Unit.Category.AIRPLANE,Unit.Category.HELICOPTER})
local IsAirResult=(UnitDescriptor.category==Unit.Category.AIRPLANE)or(UnitDescriptor.category==Unit.Category.HELICOPTER)
self:T3(IsAirResult)
return IsAirResult
end
return nil
end
function UNIT:IsGround()
self:F2()
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitDescriptor=DCSUnit:getDesc()
self:T3({UnitDescriptor.category,Unit.Category.GROUND_UNIT})
local IsGroundResult=(UnitDescriptor.category==Unit.Category.GROUND_UNIT)
self:T3(IsGroundResult)
return IsGroundResult
end
return nil
end
function UNIT:IsFriendly(FriendlyCoalition)
self:F2()
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitCoalition=DCSUnit:getCoalition()
self:T3({UnitCoalition,FriendlyCoalition})
local IsFriendlyResult=(UnitCoalition==FriendlyCoalition)
self:E(IsFriendlyResult)
return IsFriendlyResult
end
return nil
end
function UNIT:IsShip()
self:F2()
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitDescriptor=DCSUnit:getDesc()
self:T3({UnitDescriptor.category,Unit.Category.SHIP})
local IsShipResult=(UnitDescriptor.category==Unit.Category.SHIP)
self:T3(IsShipResult)
return IsShipResult
end
return nil
end
function UNIT:InAir()
self:F2(self.UnitName)
local DCSUnit=self:GetDCSObject()
if DCSUnit then
local UnitInAir=DCSUnit:inAir()
self:T3(UnitInAir)
return UnitInAir
end
return nil
end
do
function UNIT:HandleEvent(Event,EventFunction)
self:EventDispatcher():OnEventForUnit(self:GetName(),EventFunction,self,Event)
return self
end
function UNIT:UnHandleEvent(Event)
self:EventDispatcher():RemoveForUnit(self:GetName(),self,Event)
return self
end
function UNIT:ResetEvents()
self:EventDispatcher():Reset(self)
return self
end
end
do
function UNIT:IsDetected(TargetUnit)
local TargetIsDetected,TargetIsVisible,TargetLastTime,TargetKnowType,TargetKnowDistance,TargetLastPos,TargetLastVelocity=self:IsTargetDetected(TargetUnit:GetDCSObject())
return TargetIsDetected
end
function UNIT:IsLOS(TargetUnit)
local IsLOS=self:GetPointVec3():IsLOS(TargetUnit:GetPointVec3())
return IsLOS
end
end
CLIENT={
ONBOARDSIDE={
NONE=0,
LEFT=1,
RIGHT=2,
BACK=3,
FRONT=4
},
ClassName="CLIENT",
ClientName=nil,
ClientAlive=false,
ClientTransport=false,
ClientBriefingShown=false,
_Menus={},
_Tasks={},
Messages={
}
}
function CLIENT:Find(DCSUnit,Error)
local ClientName=DCSUnit:getName()
local ClientFound=_DATABASE:FindClient(ClientName)
if ClientFound then
ClientFound:F(ClientName)
return ClientFound
end
if not Error then
error("CLIENT not found for: "..ClientName)
end
end
function CLIENT:FindByName(ClientName,ClientBriefing,Error)
local ClientFound=_DATABASE:FindClient(ClientName)
if ClientFound then
ClientFound:F({ClientName,ClientBriefing})
ClientFound:AddBriefing(ClientBriefing)
ClientFound.MessageSwitch=true
return ClientFound
end
if not Error then
error("CLIENT not found for: "..ClientName)
end
end
function CLIENT:Register(ClientName)
local self=BASE:Inherit(self,UNIT:Register(ClientName))
self:F(ClientName)
self.ClientName=ClientName
self.MessageSwitch=true
self.ClientAlive2=false
self.AliveCheckScheduler=SCHEDULER:New(self,self._AliveCheckScheduler,{"Client Alive "..ClientName},1,5)
self:E(self)
return self
end
function CLIENT:Transport()
self:F()
self.ClientTransport=true
return self
end
function CLIENT:AddBriefing(ClientBriefing)
self:F(ClientBriefing)
self.ClientBriefing=ClientBriefing
self.ClientBriefingShown=false
return self
end
function CLIENT:ShowBriefing()
self:F({self.ClientName,self.ClientBriefingShown})
if not self.ClientBriefingShown then
self.ClientBriefingShown=true
local Briefing=""
if self.ClientBriefing then
Briefing=Briefing..self.ClientBriefing
end
Briefing=Briefing.." Press [LEFT ALT]+[B] to view the complete mission briefing."
self:Message(Briefing,60,"Briefing")
end
return self
end
function CLIENT:ShowMissionBriefing(MissionBriefing)
self:F({self.ClientName})
if MissionBriefing then
self:Message(MissionBriefing,60,"Mission Briefing")
end
return self
end
function CLIENT:Reset(ClientName)
self:F()
self._Menus={}
end
function CLIENT:IsMultiSeated()
self:F(self.ClientName)
local ClientMultiSeatedTypes={
["Mi-8MT"]="Mi-8MT",
["UH-1H"]="UH-1H",
["P-51B"]="P-51B"
}
if self:IsAlive()then
local ClientTypeName=self:GetClientGroupUnit():GetTypeName()
if ClientMultiSeatedTypes[ClientTypeName]then
return true
end
end
return false
end
function CLIENT:Alive(CallBackFunction,...)
self:F()
self.ClientCallBack=CallBackFunction
self.ClientParameters=arg
return self
end
function CLIENT:_AliveCheckScheduler(SchedulerName)
self:F3({SchedulerName,self.ClientName,self.ClientAlive2,self.ClientBriefingShown,self.ClientCallBack})
if self:IsAlive()then
if self.ClientAlive2==false then
self:ShowBriefing()
if self.ClientCallBack then
self:T("Calling Callback function")
self.ClientCallBack(self,unpack(self.ClientParameters))
end
self.ClientAlive2=true
end
else
if self.ClientAlive2==true then
self.ClientAlive2=false
end
end
return true
end
function CLIENT:GetDCSGroup()
self:F3()
local ClientUnit=Unit.getByName(self.ClientName)
local CoalitionsData={AlivePlayersRed=coalition.getPlayers(coalition.side.RED),AlivePlayersBlue=coalition.getPlayers(coalition.side.BLUE)}
for CoalitionId,CoalitionData in pairs(CoalitionsData)do
self:T3({"CoalitionData:",CoalitionData})
for UnitId,UnitData in pairs(CoalitionData)do
self:T3({"UnitData:",UnitData})
if UnitData and UnitData:isExist()then
if ClientUnit then
local ClientGroup=ClientUnit:getGroup()
if ClientGroup then
self:T3("ClientGroup = "..self.ClientName)
if ClientGroup:isExist()and UnitData:getGroup():isExist()then
if ClientGroup:getID()==UnitData:getGroup():getID()then
self:T3("Normal logic")
self:T3(self.ClientName.." : group found!")
self.ClientGroupID=ClientGroup:getID()
self.ClientGroupName=ClientGroup:getName()
return ClientGroup
end
else
self:T3("Bug 1.5 logic")
local ClientGroupTemplate=_DATABASE.Templates.Units[self.ClientName].GroupTemplate
self.ClientGroupID=ClientGroupTemplate.groupId
self.ClientGroupName=_DATABASE.Templates.Units[self.ClientName].GroupName
self:T3(self.ClientName.." : group found in bug 1.5 resolvement logic!")
return ClientGroup
end
end
else
end
end
end
end
if ClientUnit then
local ClientGroup=ClientUnit:getGroup()
if ClientGroup then
self:T3("ClientGroup = "..self.ClientName)
if ClientGroup:isExist()then
self:T3("Normal logic")
self:T3(self.ClientName.." : group found!")
return ClientGroup
end
end
end
self.ClientGroupID=nil
self.ClientGroupUnit=nil
return nil
end
function CLIENT:GetClientGroupID()
local ClientGroup=self:GetDCSGroup()
return self.ClientGroupID
end
function CLIENT:GetClientGroupName()
local ClientGroup=self:GetDCSGroup()
self:T(self.ClientGroupName)
return self.ClientGroupName
end
function CLIENT:GetClientGroupUnit()
self:F2()
local ClientDCSUnit=Unit.getByName(self.ClientName)
self:T(self.ClientDCSUnit)
if ClientDCSUnit and ClientDCSUnit:isExist()then
local ClientUnit=_DATABASE:FindUnit(self.ClientName)
self:T2(ClientUnit)
return ClientUnit
end
end
function CLIENT:GetClientGroupDCSUnit()
self:F2()
local ClientDCSUnit=Unit.getByName(self.ClientName)
if ClientDCSUnit and ClientDCSUnit:isExist()then
self:T2(ClientDCSUnit)
return ClientDCSUnit
end
end
function CLIENT:IsTransport()
self:F()
return self.ClientTransport
end
function CLIENT:ShowCargo()
self:F()
local CargoMsg=""
for CargoName,Cargo in pairs(CARGOS)do
if self==Cargo:IsLoadedInClient()then
CargoMsg=CargoMsg..Cargo.CargoName.." Type:"..Cargo.CargoType.." Weight: "..Cargo.CargoWeight.."\n"
end
end
if CargoMsg==""then
CargoMsg="empty"
end
self:Message(CargoMsg,15,"Co-Pilot: Cargo Status",30)
end
function CLIENT.SwitchMessages(PrmTable)
PrmTable[1].MessageSwitch=PrmTable[2]
end
function CLIENT:Message(Message,MessageDuration,MessageCategory,MessageInterval,MessageID)
self:F({Message,MessageDuration,MessageCategory,MessageInterval})
if self.MessageSwitch==true then
if MessageCategory==nil then
MessageCategory="Messages"
end
if MessageID~=nil then
if self.Messages[MessageID]==nil then
self.Messages[MessageID]={}
self.Messages[MessageID].MessageId=MessageID
self.Messages[MessageID].MessageTime=timer.getTime()
self.Messages[MessageID].MessageDuration=MessageDuration
if MessageInterval==nil then
self.Messages[MessageID].MessageInterval=600
else
self.Messages[MessageID].MessageInterval=MessageInterval
end
MESSAGE:New(Message,MessageDuration,MessageCategory):ToClient(self)
else
if self:GetClientGroupDCSUnit()and not self:GetClientGroupDCSUnit():inAir()then
if timer.getTime()-self.Messages[MessageID].MessageTime>=self.Messages[MessageID].MessageDuration+10 then
MESSAGE:New(Message,MessageDuration,MessageCategory):ToClient(self)
self.Messages[MessageID].MessageTime=timer.getTime()
end
else
if timer.getTime()-self.Messages[MessageID].MessageTime>=self.Messages[MessageID].MessageDuration+self.Messages[MessageID].MessageInterval then
MESSAGE:New(Message,MessageDuration,MessageCategory):ToClient(self)
self.Messages[MessageID].MessageTime=timer.getTime()
end
end
end
else
MESSAGE:New(Message,MessageDuration,MessageCategory):ToClient(self)
end
end
end
STATIC={
ClassName="STATIC",
}
function STATIC:FindByName(StaticName,RaiseError)
local StaticFound=_DATABASE:FindStatic(StaticName)
self.StaticName=StaticName
if StaticFound then
StaticFound:F3({StaticName})
return StaticFound
end
if RaiseError==nil or RaiseError==true then
error("STATIC not found for: "..StaticName)
end
return nil
end
function STATIC:Register(StaticName)
local self=BASE:Inherit(self,POSITIONABLE:New(StaticName))
self.StaticName=StaticName
return self
end
function STATIC:GetDCSObject()
local DCSStatic=StaticObject.getByName(self.StaticName)
if DCSStatic then
return DCSStatic
end
return nil
end
function STATIC:GetThreatLevel()
return 1,"Static"
end
AIRBASE={
ClassName="AIRBASE",
CategoryName={
[Airbase.Category.AIRDROME]="Airdrome",
[Airbase.Category.HELIPAD]="Helipad",
[Airbase.Category.SHIP]="Ship",
},
}
AIRBASE.Caucasus={
["Gelendzhik"]="Gelendzhik",
["Krasnodar_Pashkovsky"]="Krasnodar-Pashkovsky",
["Sukhumi_Babushara"]="Sukhumi-Babushara",
["Gudauta"]="Gudauta",
["Batumi"]="Batumi",
["Senaki_Kolkhi"]="Senaki-Kolkhi",
["Kobuleti"]="Kobuleti",
["Kutaisi"]="Kutaisi",
["Tbilisi_Lochini"]="Tbilisi-Lochini",
["Soganlug"]="Soganlug",
["Vaziani"]="Vaziani",
["Anapa_Vityazevo"]="Anapa-Vityazevo",
["Krasnodar_Center"]="Krasnodar-Center",
["Novorossiysk"]="Novorossiysk",
["Krymsk"]="Krymsk",
["Maykop_Khanskaya"]="Maykop-Khanskaya",
["Sochi_Adler"]="Sochi-Adler",
["Mineralnye_Vody"]="Mineralnye Vody",
["Nalchik"]="Nalchik",
["Mozdok"]="Mozdok",
["Beslan"]="Beslan",
}
AIRBASE.Nevada={
["Creech_AFB"]="Creech AFB",
["Groom_Lake_AFB"]="Groom Lake AFB",
["McCarran_International_Airport"]="McCarran International Airport",
["Nellis_AFB"]="Nellis AFB",
["Beatty_Airport"]="Beatty Airport",
["Boulder_City_Airport"]="Boulder City Airport",
["Echo_Bay"]="Echo Bay",
["Henderson_Executive_Airport"]="Henderson Executive Airport",
["Jean_Airport"]="Jean Airport",
["Laughlin_Airport"]="Laughlin Airport",
["Lincoln_County"]="Lincoln County",
["Mellan_Airstrip"]="Mellan Airstrip",
["Mesquite"]="Mesquite",
["Mina_Airport_3Q0"]="Mina Airport 3Q0",
["North_Las_Vegas"]="North Las Vegas",
["Pahute_Mesa_Airstrip"]="Pahute Mesa Airstrip",
["Tonopah_Airport"]="Tonopah Airport",
["Tonopah_Test_Range_Airfield"]="Tonopah Test Range Airfield",
}
AIRBASE.Normandy={
["Saint_Pierre_du_Mont"]="Saint Pierre du Mont",
["Lignerolles"]="Lignerolles",
["Cretteville"]="Cretteville",
["Maupertus"]="Maupertus",
["Brucheville"]="Brucheville",
["Meautis"]="Meautis",
["Cricqueville_en_Bessin"]="Cricqueville-en-Bessin",
["Lessay"]="Lessay",
["Sainte_Laurent_sur_Mer"]="Sainte-Laurent-sur-Mer",
["Biniville"]="Biniville",
["Cardonville"]="Cardonville",
["Deux_Jumeaux"]="Deux Jumeaux",
["Chippelle"]="Chippelle",
["Beuzeville"]="Beuzeville",
["Azeville"]="Azeville",
["Picauville"]="Picauville",
["Le_Molay"]="Le Molay",
["Longues_sur_Mer"]="Longues-sur-Mer",
["Carpiquet"]="Carpiquet",
["Bazenville"]="Bazenville",
["Sainte_Croix_sur_Mer"]="Sainte-Croix-sur-Mer",
["Beny_sur_Mer"]="Beny-sur-Mer",
["Rucqueville"]="Rucqueville",
["Sommervieu"]="Sommervieu",
["Lantheuil"]="Lantheuil",
["Evreux"]="Evreux",
["Chailey"]="Chailey",
["Needs_Oar_Point"]="Needs Oar Point",
["Funtington"]="Funtington",
["Tangmere"]="Tangmere",
["Ford"]="Ford",
}
function AIRBASE:Register(AirbaseName)
local self=BASE:Inherit(self,POSITIONABLE:New(AirbaseName))
self.AirbaseName=AirbaseName
self.AirbaseZone=ZONE_RADIUS:New(AirbaseName,self:GetVec2(),8000)
return self
end
function AIRBASE:Find(DCSAirbase)
local AirbaseName=DCSAirbase:getName()
local AirbaseFound=_DATABASE:FindAirbase(AirbaseName)
return AirbaseFound
end
function AIRBASE:FindByName(AirbaseName)
local AirbaseFound=_DATABASE:FindAirbase(AirbaseName)
return AirbaseFound
end
function AIRBASE:GetDCSObject()
local DCSAirbase=Airbase.getByName(self.AirbaseName)
if DCSAirbase then
return DCSAirbase
end
return nil
end
function AIRBASE:GetZone()
return self.AirbaseZone
end
SCENERY={
ClassName="SCENERY",
}
function SCENERY:Register(SceneryName,SceneryObject)
local self=BASE:Inherit(self,POSITIONABLE:New(SceneryName))
self.SceneryName=SceneryName
self.SceneryObject=SceneryObject
return self
end
function SCENERY:GetDCSObject()
return self.SceneryObject
end
function SCENERY:GetThreatLevel()
return 0,"Scenery"
end
SCORING={
ClassName="SCORING",
ClassID=0,
Players={},
}
local _SCORINGCoalition=
{
[1]="Red",
[2]="Blue",
}
local _SCORINGCategory=
{
[Unit.Category.AIRPLANE]="Plane",
[Unit.Category.HELICOPTER]="Helicopter",
[Unit.Category.GROUND_UNIT]="Vehicle",
[Unit.Category.SHIP]="Ship",
[Unit.Category.STRUCTURE]="Structure",
}
function SCORING:New(GameName)
local self=BASE:Inherit(self,BASE:New())
if GameName then
self.GameName=GameName
else
error("A game name must be given to register the scoring results")
end
self.ScoringObjects={}
self.ScoringZones={}
self:SetMessagesToAll()
self:SetMessagesHit(false)
self:SetMessagesDestroy(true)
self:SetMessagesScore(true)
self:SetMessagesZone(true)
self:SetScaleDestroyScore(10)
self:SetScaleDestroyPenalty(30)
self:SetFratricide(self.ScaleDestroyPenalty*3)
self:SetCoalitionChangePenalty(self.ScaleDestroyPenalty)
self:SetDisplayMessagePrefix()
self:HandleEvent(EVENTS.Dead,self._EventOnDeadOrCrash)
self:HandleEvent(EVENTS.Crash,self._EventOnDeadOrCrash)
self:HandleEvent(EVENTS.Hit,self._EventOnHit)
self:HandleEvent(EVENTS.PlayerEnterUnit)
self:HandleEvent(EVENTS.PlayerLeaveUnit)
self:OpenCSV(GameName)
return self
end
function SCORING:SetDisplayMessagePrefix(DisplayMessagePrefix)
self.DisplayMessagePrefix=DisplayMessagePrefix or""
return self
end
function SCORING:SetScaleDestroyScore(Scale)
self.ScaleDestroyScore=Scale
return self
end
function SCORING:SetScaleDestroyPenalty(Scale)
self.ScaleDestroyPenalty=Scale
return self
end
function SCORING:AddUnitScore(ScoreUnit,Score)
local UnitName=ScoreUnit:GetName()
self.ScoringObjects[UnitName]=Score
return self
end
function SCORING:RemoveUnitScore(ScoreUnit)
local UnitName=ScoreUnit:GetName()
self.ScoringObjects[UnitName]=nil
return self
end
function SCORING:AddStaticScore(ScoreStatic,Score)
local StaticName=ScoreStatic:GetName()
self.ScoringObjects[StaticName]=Score
return self
end
function SCORING:RemoveStaticScore(ScoreStatic)
local StaticName=ScoreStatic:GetName()
self.ScoringObjects[StaticName]=nil
return self
end
function SCORING:AddScoreGroup(ScoreGroup,Score)
local ScoreUnits=ScoreGroup:GetUnits()
for ScoreUnitID,ScoreUnit in pairs(ScoreUnits)do
local UnitName=ScoreUnit:GetName()
self.ScoringObjects[UnitName]=Score
end
return self
end
function SCORING:AddZoneScore(ScoreZone,Score)
local ZoneName=ScoreZone:GetName()
self.ScoringZones[ZoneName]={}
self.ScoringZones[ZoneName].ScoreZone=ScoreZone
self.ScoringZones[ZoneName].Score=Score
return self
end
function SCORING:RemoveZoneScore(ScoreZone)
local ZoneName=ScoreZone:GetName()
self.ScoringZones[ZoneName]=nil
return self
end
function SCORING:SetMessagesHit(OnOff)
self.MessagesHit=OnOff
return self
end
function SCORING:IfMessagesHit()
return self.MessagesHit
end
function SCORING:SetMessagesDestroy(OnOff)
self.MessagesDestroy=OnOff
return self
end
function SCORING:IfMessagesDestroy()
return self.MessagesDestroy
end
function SCORING:SetMessagesScore(OnOff)
self.MessagesScore=OnOff
return self
end
function SCORING:IfMessagesScore()
return self.MessagesScore
end
function SCORING:SetMessagesZone(OnOff)
self.MessagesZone=OnOff
return self
end
function SCORING:IfMessagesZone()
return self.MessagesZone
end
function SCORING:SetMessagesToAll()
self.MessagesAudience=1
return self
end
function SCORING:IfMessagesToAll()
return self.MessagesAudience==1
end
function SCORING:SetMessagesToCoalition()
self.MessagesAudience=2
return self
end
function SCORING:IfMessagesToCoalition()
return self.MessagesAudience==2
end
function SCORING:SetFratricide(Fratricide)
self.Fratricide=Fratricide
return self
end
function SCORING:SetCoalitionChangePenalty(CoalitionChangePenalty)
self.CoalitionChangePenalty=CoalitionChangePenalty
return self
end
function SCORING:_AddPlayerFromUnit(UnitData)
self:F(UnitData)
if UnitData:IsAlive()then
local UnitName=UnitData:GetName()
local PlayerName=UnitData:GetPlayerName()
local UnitDesc=UnitData:GetDesc()
local UnitCategory=UnitDesc.category
local UnitCoalition=UnitData:GetCoalition()
local UnitTypeName=UnitData:GetTypeName()
local UnitThreatLevel,UnitThreatType=UnitData:GetThreatLevel()
self:T({PlayerName,UnitName,UnitCategory,UnitCoalition,UnitTypeName})
if self.Players[PlayerName]==nil then
self.Players[PlayerName]={}
self.Players[PlayerName].Hit={}
self.Players[PlayerName].Destroy={}
self.Players[PlayerName].Goals={}
self.Players[PlayerName].Mission={}
self.Players[PlayerName].HitPlayers={}
self.Players[PlayerName].Score=0
self.Players[PlayerName].Penalty=0
self.Players[PlayerName].PenaltyCoalition=0
self.Players[PlayerName].PenaltyWarning=0
end
if not self.Players[PlayerName].UnitCoalition then
self.Players[PlayerName].UnitCoalition=UnitCoalition
else
if self.Players[PlayerName].UnitCoalition~=UnitCoalition then
self.Players[PlayerName].Penalty=self.Players[PlayerName].Penalty+50
self.Players[PlayerName].PenaltyCoalition=self.Players[PlayerName].PenaltyCoalition+1
MESSAGE:NewType(self.DisplayMessagePrefix.."Player '"..PlayerName.."' changed coalition from ".._SCORINGCoalition[self.Players[PlayerName].UnitCoalition].." to ".._SCORINGCoalition[UnitCoalition]..
"(changed "..self.Players[PlayerName].PenaltyCoalition.." times the coalition). 50 Penalty points added.",
MESSAGE.Type.Information
):ToAll()
self:ScoreCSV(PlayerName,"","COALITION_PENALTY",1,-50,self.Players[PlayerName].UnitName,_SCORINGCoalition[self.Players[PlayerName].UnitCoalition],_SCORINGCategory[self.Players[PlayerName].UnitCategory],self.Players[PlayerName].UnitType,
UnitName,_SCORINGCoalition[UnitCoalition],_SCORINGCategory[UnitCategory],UnitData:GetTypeName())
end
end
self.Players[PlayerName].UnitName=UnitName
self.Players[PlayerName].UnitCoalition=UnitCoalition
self.Players[PlayerName].UnitCategory=UnitCategory
self.Players[PlayerName].UnitType=UnitTypeName
self.Players[PlayerName].UNIT=UnitData
self.Players[PlayerName].ThreatLevel=UnitThreatLevel
self.Players[PlayerName].ThreatType=UnitThreatType
end
end
function SCORING:AddGoalScore(PlayerUnit,GoalTag,Text,Score)
local PlayerName=PlayerUnit:GetPlayerName()
self:E({PlayerUnit.UnitName,PlayerName,GoalTag,Text,Score})
if PlayerName then
local PlayerData=self.Players[PlayerName]
PlayerData.Goals[GoalTag]=PlayerData.Goals[GoalTag]or{Score=0}
PlayerData.Goals[GoalTag].Score=PlayerData.Goals[GoalTag].Score+Score
PlayerData.Score=PlayerData.Score+Score
MESSAGE:NewType(self.DisplayMessagePrefix..Text,MESSAGE.Type.Information):ToAll()
self:ScoreCSV(PlayerName,"","GOAL_"..string.upper(GoalTag),1,Score,PlayerUnit:GetName())
end
end
function SCORING:_AddMissionTaskScore(Mission,PlayerUnit,Text,Score)
local PlayerName=PlayerUnit:GetPlayerName()
local MissionName=Mission:GetName()
self:E({Mission:GetName(),PlayerUnit.UnitName,PlayerName,Text,Score})
if PlayerName then
local PlayerData=self.Players[PlayerName]
if not PlayerData.Mission[MissionName]then
PlayerData.Mission[MissionName]={}
PlayerData.Mission[MissionName].ScoreTask=0
PlayerData.Mission[MissionName].ScoreMission=0
end
self:T(PlayerName)
self:T(PlayerData.Mission[MissionName])
PlayerData.Score=self.Players[PlayerName].Score+Score
PlayerData.Mission[MissionName].ScoreTask=self.Players[PlayerName].Mission[MissionName].ScoreTask+Score
MESSAGE:NewType(self.DisplayMessagePrefix..MissionName.." : "..Text.." Score: "..Score,MESSAGE.Type.Information):ToAll()
self:ScoreCSV(PlayerName,"","TASK_"..MissionName:gsub(' ','_'),1,Score,PlayerUnit:GetName())
end
end
function SCORING:_AddMissionScore(Mission,Text,Score)
local MissionName=Mission:GetName()
self:E({Mission,Text,Score})
self:E(self.Players)
for PlayerName,PlayerData in pairs(self.Players)do
self:E(PlayerData)
if PlayerData.Mission[MissionName]then
PlayerData.Score=PlayerData.Score+Score
PlayerData.Mission[MissionName].ScoreMission=PlayerData.Mission[MissionName].ScoreMission+Score
MESSAGE:NewType(self.DisplayMessagePrefix.."Player '"..PlayerName.."' has "..Text.." in Mission '"..MissionName.."'. "..
Score.." mission score!",
MESSAGE.Type.Information):ToAll()
self:ScoreCSV(PlayerName,"","MISSION_"..MissionName:gsub(' ','_'),1,Score)
end
end
end
function SCORING:OnEventPlayerEnterUnit(Event)
if Event.IniUnit then
self:_AddPlayerFromUnit(Event.IniUnit)
local Menu=MENU_GROUP:New(Event.IniGroup,'Scoring')
local ReportGroupSummary=MENU_GROUP_COMMAND:New(Event.IniGroup,'Summary report players in group',Menu,SCORING.ReportScoreGroupSummary,self,Event.IniGroup)
local ReportGroupDetailed=MENU_GROUP_COMMAND:New(Event.IniGroup,'Detailed report players in group',Menu,SCORING.ReportScoreGroupDetailed,self,Event.IniGroup)
local ReportToAllSummary=MENU_GROUP_COMMAND:New(Event.IniGroup,'Summary report all players',Menu,SCORING.ReportScoreAllSummary,self,Event.IniGroup)
self:SetState(Event.IniUnit,"ScoringMenu",Menu)
end
end
function SCORING:OnEventPlayerLeaveUnit(Event)
if Event.IniUnit then
local Menu=self:GetState(Event.IniUnit,"ScoringMenu")
if Menu then
end
end
end
function SCORING:_EventOnHit(Event)
self:F({Event})
local InitUnit=nil
local InitUNIT=nil
local InitUnitName=""
local InitGroup=nil
local InitGroupName=""
local InitPlayerName=nil
local InitCoalition=nil
local InitCategory=nil
local InitType=nil
local InitUnitCoalition=nil
local InitUnitCategory=nil
local InitUnitType=nil
local TargetUnit=nil
local TargetUNIT=nil
local TargetUnitName=""
local TargetGroup=nil
local TargetGroupName=""
local TargetPlayerName=nil
local TargetCoalition=nil
local TargetCategory=nil
local TargetType=nil
local TargetUnitCoalition=nil
local TargetUnitCategory=nil
local TargetUnitType=nil
if Event.IniDCSUnit then
InitUnit=Event.IniDCSUnit
InitUNIT=Event.IniUnit
InitUnitName=Event.IniDCSUnitName
InitGroup=Event.IniDCSGroup
InitGroupName=Event.IniDCSGroupName
InitPlayerName=Event.IniPlayerName
InitCoalition=Event.IniCoalition
InitCategory=Event.IniCategory
InitType=Event.IniTypeName
InitUnitCoalition=_SCORINGCoalition[InitCoalition]
InitUnitCategory=_SCORINGCategory[InitCategory]
InitUnitType=InitType
self:T({InitUnitName,InitGroupName,InitPlayerName,InitCoalition,InitCategory,InitType,InitUnitCoalition,InitUnitCategory,InitUnitType})
end
if Event.TgtDCSUnit then
TargetUnit=Event.TgtDCSUnit
TargetUNIT=Event.TgtUnit
TargetUnitName=Event.TgtDCSUnitName
TargetGroup=Event.TgtDCSGroup
TargetGroupName=Event.TgtDCSGroupName
TargetPlayerName=Event.TgtPlayerName
TargetCoalition=Event.TgtCoalition
TargetCategory=Event.TgtCategory
TargetType=Event.TgtTypeName
TargetUnitCoalition=_SCORINGCoalition[TargetCoalition]
TargetUnitCategory=_SCORINGCategory[TargetCategory]
TargetUnitType=TargetType
self:T({TargetUnitName,TargetGroupName,TargetPlayerName,TargetCoalition,TargetCategory,TargetType,TargetUnitCoalition,TargetUnitCategory,TargetUnitType})
end
if InitPlayerName~=nil then
self:_AddPlayerFromUnit(InitUNIT)
if self.Players[InitPlayerName]then
if TargetPlayerName~=nil then
self:_AddPlayerFromUnit(TargetUNIT)
end
self:T("Hitting Something")
if TargetCategory then
local Player=self.Players[InitPlayerName]
Player.Hit[TargetCategory]=Player.Hit[TargetCategory]or{}
Player.Hit[TargetCategory][TargetUnitName]=Player.Hit[TargetCategory][TargetUnitName]or{}
local PlayerHit=Player.Hit[TargetCategory][TargetUnitName]
PlayerHit.Score=PlayerHit.Score or 0
PlayerHit.Penalty=PlayerHit.Penalty or 0
PlayerHit.ScoreHit=PlayerHit.ScoreHit or 0
PlayerHit.PenaltyHit=PlayerHit.PenaltyHit or 0
PlayerHit.TimeStamp=PlayerHit.TimeStamp or 0
PlayerHit.UNIT=PlayerHit.UNIT or TargetUNIT
PlayerHit.ThreatLevel,PlayerHit.ThreatType=PlayerHit.UNIT:GetThreatLevel()
if timer.getTime()-PlayerHit.TimeStamp>1 then
PlayerHit.TimeStamp=timer.getTime()
if TargetPlayerName~=nil then
Player.HitPlayers[TargetPlayerName]=true
end
local Score=0
if InitCoalition then
if InitCoalition==TargetCoalition then
Player.Penalty=Player.Penalty+10
PlayerHit.Penalty=PlayerHit.Penalty+10
PlayerHit.PenaltyHit=PlayerHit.PenaltyHit+1
if TargetPlayerName~=nil then
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..InitPlayerName.."' hit friendly player '"..TargetPlayerName.."' "..
TargetUnitCategory.." ( "..TargetType.." ) "..PlayerHit.PenaltyHit.." times. "..
"Penalty: -"..PlayerHit.Penalty..".  Score Total:"..Player.Score-Player.Penalty,
MESSAGE.Type.Update
)
:ToAllIf(self:IfMessagesHit()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesHit()and self:IfMessagesToCoalition())
else
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..InitPlayerName.."' hit friendly target "..
TargetUnitCategory.." ( "..TargetType.." ) "..PlayerHit.PenaltyHit.." times. "..
"Penalty: -"..PlayerHit.Penalty..".  Score Total:"..Player.Score-Player.Penalty,
MESSAGE.Type.Update
)
:ToAllIf(self:IfMessagesHit()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesHit()and self:IfMessagesToCoalition())
end
self:ScoreCSV(InitPlayerName,TargetPlayerName,"HIT_PENALTY",1,-10,InitUnitName,InitUnitCoalition,InitUnitCategory,InitUnitType,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
else
Player.Score=Player.Score+1
PlayerHit.Score=PlayerHit.Score+1
PlayerHit.ScoreHit=PlayerHit.ScoreHit+1
if TargetPlayerName~=nil then
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..InitPlayerName.."' hit enemy player '"..TargetPlayerName.."' "..
TargetUnitCategory.." ( "..TargetType.." ) "..PlayerHit.ScoreHit.." times. "..
"Score: "..PlayerHit.Score..".  Score Total:"..Player.Score-Player.Penalty,
MESSAGE.Type.Update
)
:ToAllIf(self:IfMessagesHit()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesHit()and self:IfMessagesToCoalition())
else
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..InitPlayerName.."' hit enemy target "..
TargetUnitCategory.." ( "..TargetType.." ) "..PlayerHit.ScoreHit.." times. "..
"Score: "..PlayerHit.Score..".  Score Total:"..Player.Score-Player.Penalty,
MESSAGE.Type.Update
)
:ToAllIf(self:IfMessagesHit()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesHit()and self:IfMessagesToCoalition())
end
self:ScoreCSV(InitPlayerName,TargetPlayerName,"HIT_SCORE",1,1,InitUnitName,InitUnitCoalition,InitUnitCategory,InitUnitType,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
end
else
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..InitPlayerName.."' hit scenery object.",
MESSAGE.Type.Update
)
:ToAllIf(self:IfMessagesHit()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesHit()and self:IfMessagesToCoalition())
self:ScoreCSV(InitPlayerName,"","HIT_SCORE",1,0,InitUnitName,InitUnitCoalition,InitUnitCategory,InitUnitType,TargetUnitName,"","Scenery",TargetUnitType)
end
end
end
end
elseif InitPlayerName==nil then
end
if Event.WeaponPlayerName~=nil then
self:_AddPlayerFromUnit(Event.WeaponUNIT)
if self.Players[Event.WeaponPlayerName]then
if TargetPlayerName~=nil then
self:_AddPlayerFromUnit(TargetUNIT)
end
self:T("Hitting Scenery")
if TargetCategory then
local Player=self.Players[Event.WeaponPlayerName]
Player.Hit[TargetCategory]=Player.Hit[TargetCategory]or{}
Player.Hit[TargetCategory][TargetUnitName]=Player.Hit[TargetCategory][TargetUnitName]or{}
local PlayerHit=Player.Hit[TargetCategory][TargetUnitName]
PlayerHit.Score=PlayerHit.Score or 0
PlayerHit.Penalty=PlayerHit.Penalty or 0
PlayerHit.ScoreHit=PlayerHit.ScoreHit or 0
PlayerHit.PenaltyHit=PlayerHit.PenaltyHit or 0
PlayerHit.TimeStamp=PlayerHit.TimeStamp or 0
PlayerHit.UNIT=PlayerHit.UNIT or TargetUNIT
PlayerHit.ThreatLevel,PlayerHit.ThreatType=PlayerHit.UNIT:GetThreatLevel()
if timer.getTime()-PlayerHit.TimeStamp>1 then
PlayerHit.TimeStamp=timer.getTime()
local Score=0
if InitCoalition then
if InitCoalition==TargetCoalition then
Player.Penalty=Player.Penalty+10
PlayerHit.Penalty=PlayerHit.Penalty+10
PlayerHit.PenaltyHit=PlayerHit.PenaltyHit+1
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..Event.WeaponPlayerName.."' hit friendly target "..
TargetUnitCategory.." ( "..TargetType.." ) "..
"Penalty: -"..PlayerHit.Penalty.." = "..Player.Score-Player.Penalty,
MESSAGE.Type.Update
)
:ToAllIf(self:IfMessagesHit()and self:IfMessagesToAll())
:ToCoalitionIf(Event.WeaponCoalition,self:IfMessagesHit()and self:IfMessagesToCoalition())
self:ScoreCSV(Event.WeaponPlayerName,TargetPlayerName,"HIT_PENALTY",1,-10,Event.WeaponName,Event.WeaponCoalition,Event.WeaponCategory,Event.WeaponTypeName,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
else
Player.Score=Player.Score+1
PlayerHit.Score=PlayerHit.Score+1
PlayerHit.ScoreHit=PlayerHit.ScoreHit+1
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..Event.WeaponPlayerName.."' hit enemy target "..
TargetUnitCategory.." ( "..TargetType.." ) "..
"Score: +"..PlayerHit.Score.." = "..Player.Score-Player.Penalty,
MESSAGE.Type.Update
)
:ToAllIf(self:IfMessagesHit()and self:IfMessagesToAll())
:ToCoalitionIf(Event.WeaponCoalition,self:IfMessagesHit()and self:IfMessagesToCoalition())
self:ScoreCSV(Event.WeaponPlayerName,TargetPlayerName,"HIT_SCORE",1,1,Event.WeaponName,Event.WeaponCoalition,Event.WeaponCategory,Event.WeaponTypeName,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
end
else
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..Event.WeaponPlayerName.."' hit scenery object.",
MESSAGE.Type.Update
)
:ToAllIf(self:IfMessagesHit()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesHit()and self:IfMessagesToCoalition())
self:ScoreCSV(Event.WeaponPlayerName,"","HIT_SCORE",1,0,Event.WeaponName,Event.WeaponCoalition,Event.WeaponCategory,Event.WeaponTypeName,TargetUnitName,"","Scenery",TargetUnitType)
end
end
end
end
end
end
function SCORING:_EventOnDeadOrCrash(Event)
self:F({Event})
local TargetUnit=nil
local TargetGroup=nil
local TargetUnitName=""
local TargetGroupName=""
local TargetPlayerName=""
local TargetCoalition=nil
local TargetCategory=nil
local TargetType=nil
local TargetUnitCoalition=nil
local TargetUnitCategory=nil
local TargetUnitType=nil
if Event.IniDCSUnit then
TargetUnit=Event.IniUnit
TargetUnitName=Event.IniDCSUnitName
TargetGroup=Event.IniDCSGroup
TargetGroupName=Event.IniDCSGroupName
TargetPlayerName=Event.IniPlayerName
TargetCoalition=Event.IniCoalition
TargetCategory=Event.IniCategory
TargetType=Event.IniTypeName
TargetUnitCoalition=_SCORINGCoalition[TargetCoalition]
TargetUnitCategory=_SCORINGCategory[TargetCategory]
TargetUnitType=TargetType
self:T({TargetUnitName,TargetGroupName,TargetPlayerName,TargetCoalition,TargetCategory,TargetType})
end
for PlayerName,Player in pairs(self.Players)do
if Player then
self:T("Something got destroyed")
local InitUnitName=Player.UnitName
local InitUnitType=Player.UnitType
local InitCoalition=Player.UnitCoalition
local InitCategory=Player.UnitCategory
local InitUnitCoalition=_SCORINGCoalition[InitCoalition]
local InitUnitCategory=_SCORINGCategory[InitCategory]
self:T({InitUnitName,InitUnitType,InitUnitCoalition,InitCoalition,InitUnitCategory,InitCategory})
local Destroyed=false
if Player and Player.Hit and Player.Hit[TargetCategory]and Player.Hit[TargetCategory][TargetUnitName]and Player.Hit[TargetCategory][TargetUnitName].TimeStamp~=0 then
local TargetThreatLevel=Player.Hit[TargetCategory][TargetUnitName].ThreatLevel
local TargetThreatType=Player.Hit[TargetCategory][TargetUnitName].ThreatType
Player.Destroy[TargetCategory]=Player.Destroy[TargetCategory]or{}
Player.Destroy[TargetCategory][TargetType]=Player.Destroy[TargetCategory][TargetType]or{}
local TargetDestroy=Player.Destroy[TargetCategory][TargetType]
TargetDestroy.Score=TargetDestroy.Score or 0
TargetDestroy.ScoreDestroy=TargetDestroy.ScoreDestroy or 0
TargetDestroy.Penalty=TargetDestroy.Penalty or 0
TargetDestroy.PenaltyDestroy=TargetDestroy.PenaltyDestroy or 0
if TargetCoalition then
if InitCoalition==TargetCoalition then
local ThreatLevelTarget=TargetThreatLevel
local ThreatTypeTarget=TargetThreatType
local ThreatLevelPlayer=Player.ThreatLevel/10+1
local ThreatPenalty=math.ceil((ThreatLevelTarget/ThreatLevelPlayer)*self.ScaleDestroyPenalty/10)
self:E({ThreatLevel=ThreatPenalty,ThreatLevelTarget=ThreatLevelTarget,ThreatTypeTarget=ThreatTypeTarget,ThreatLevelPlayer=ThreatLevelPlayer})
Player.Penalty=Player.Penalty+ThreatPenalty
TargetDestroy.Penalty=TargetDestroy.Penalty+ThreatPenalty
TargetDestroy.PenaltyDestroy=TargetDestroy.PenaltyDestroy+1
if Player.HitPlayers[TargetPlayerName]then
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..PlayerName.."' destroyed friendly player '"..TargetPlayerName.."' "..
TargetUnitCategory.." ( "..ThreatTypeTarget.." ) "..
"Penalty: -"..TargetDestroy.Penalty.." = "..Player.Score-Player.Penalty,
MESSAGE.Type.Information
)
:ToAllIf(self:IfMessagesDestroy()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesDestroy()and self:IfMessagesToCoalition())
else
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..PlayerName.."' destroyed friendly target "..
TargetUnitCategory.." ( "..ThreatTypeTarget.." ) "..
"Penalty: -"..TargetDestroy.Penalty.." = "..Player.Score-Player.Penalty,
MESSAGE.Type.Information
)
:ToAllIf(self:IfMessagesDestroy()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesDestroy()and self:IfMessagesToCoalition())
end
Destroyed=true
self:ScoreCSV(PlayerName,TargetPlayerName,"DESTROY_PENALTY",1,ThreatPenalty,InitUnitName,InitUnitCoalition,InitUnitCategory,InitUnitType,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
else
local ThreatLevelTarget=TargetThreatLevel
local ThreatTypeTarget=TargetThreatType
local ThreatLevelPlayer=Player.ThreatLevel/10+1
local ThreatScore=math.ceil((ThreatLevelTarget/ThreatLevelPlayer)*self.ScaleDestroyScore/10)
self:E({ThreatLevel=ThreatScore,ThreatLevelTarget=ThreatLevelTarget,ThreatTypeTarget=ThreatTypeTarget,ThreatLevelPlayer=ThreatLevelPlayer})
Player.Score=Player.Score+ThreatScore
TargetDestroy.Score=TargetDestroy.Score+ThreatScore
TargetDestroy.ScoreDestroy=TargetDestroy.ScoreDestroy+1
if Player.HitPlayers[TargetPlayerName]then
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..PlayerName.."' destroyed enemy player '"..TargetPlayerName.."' "..
TargetUnitCategory.." ( "..ThreatTypeTarget.." ) "..
"Score: +"..TargetDestroy.Score.." = "..Player.Score-Player.Penalty,
MESSAGE.Type.Information
)
:ToAllIf(self:IfMessagesDestroy()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesDestroy()and self:IfMessagesToCoalition())
else
MESSAGE
:NewType(self.DisplayMessagePrefix.."Player '"..PlayerName.."' destroyed enemy "..
TargetUnitCategory.." ( "..ThreatTypeTarget.." ) "..
"Score: +"..TargetDestroy.Score.." = "..Player.Score-Player.Penalty,
MESSAGE.Type.Information
)
:ToAllIf(self:IfMessagesDestroy()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesDestroy()and self:IfMessagesToCoalition())
end
Destroyed=true
self:ScoreCSV(PlayerName,TargetPlayerName,"DESTROY_SCORE",1,ThreatScore,InitUnitName,InitUnitCoalition,InitUnitCategory,InitUnitType,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
local UnitName=TargetUnit:GetName()
local Score=self.ScoringObjects[UnitName]
if Score then
Player.Score=Player.Score+Score
TargetDestroy.Score=TargetDestroy.Score+Score
MESSAGE
:NewType(self.DisplayMessagePrefix.."Special target '"..TargetUnitCategory.." ( "..ThreatTypeTarget.." ) ".." destroyed! "..
"Player '"..PlayerName.."' receives an extra "..Score.." points! Total: "..Player.Score-Player.Penalty,
MESSAGE.Type.Information
)
:ToAllIf(self:IfMessagesScore()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesScore()and self:IfMessagesToCoalition())
self:ScoreCSV(PlayerName,TargetPlayerName,"DESTROY_SCORE",1,Score,InitUnitName,InitUnitCoalition,InitUnitCategory,InitUnitType,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
Destroyed=true
end
for ZoneName,ScoreZoneData in pairs(self.ScoringZones)do
self:E({ScoringZone=ScoreZoneData})
local ScoreZone=ScoreZoneData.ScoreZone
local Score=ScoreZoneData.Score
if ScoreZone:IsVec2InZone(TargetUnit:GetVec2())then
Player.Score=Player.Score+Score
TargetDestroy.Score=TargetDestroy.Score+Score
MESSAGE
:NewType(self.DisplayMessagePrefix.."Target destroyed in zone '"..ScoreZone:GetName().."'."..
"Player '"..PlayerName.."' receives an extra "..Score.." points! "..
"Total: "..Player.Score-Player.Penalty,
MESSAGE.Type.Information)
:ToAllIf(self:IfMessagesZone()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesZone()and self:IfMessagesToCoalition())
self:ScoreCSV(PlayerName,TargetPlayerName,"DESTROY_SCORE",1,Score,InitUnitName,InitUnitCoalition,InitUnitCategory,InitUnitType,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
Destroyed=true
end
end
end
else
for ZoneName,ScoreZoneData in pairs(self.ScoringZones)do
self:E({ScoringZone=ScoreZoneData})
local ScoreZone=ScoreZoneData.ScoreZone
local Score=ScoreZoneData.Score
if ScoreZone:IsVec2InZone(TargetUnit:GetVec2())then
Player.Score=Player.Score+Score
TargetDestroy.Score=TargetDestroy.Score+Score
MESSAGE
:NewType(self.DisplayMessagePrefix.."Scenery destroyed in zone '"..ScoreZone:GetName().."'."..
"Player '"..PlayerName.."' receives an extra "..Score.." points! "..
"Total: "..Player.Score-Player.Penalty,
MESSAGE.Type.Information
)
:ToAllIf(self:IfMessagesZone()and self:IfMessagesToAll())
:ToCoalitionIf(InitCoalition,self:IfMessagesZone()and self:IfMessagesToCoalition())
Destroyed=true
self:ScoreCSV(PlayerName,"","DESTROY_SCORE",1,Score,InitUnitName,InitUnitCoalition,InitUnitCategory,InitUnitType,TargetUnitName,"","Scenery",TargetUnitType)
end
end
end
if Destroyed then
Player.Hit[TargetCategory][TargetUnitName].TimeStamp=0
end
end
end
end
end
function SCORING:ReportDetailedPlayerHits(PlayerName)
local ScoreMessage=""
local PlayerScore=0
local PlayerPenalty=0
local PlayerData=self.Players[PlayerName]
if PlayerData then
self:T("Score Player: "..PlayerName)
local InitUnitCoalition=_SCORINGCoalition[PlayerData.UnitCoalition]
local InitUnitCategory=_SCORINGCategory[PlayerData.UnitCategory]
local InitUnitType=PlayerData.UnitType
local InitUnitName=PlayerData.UnitName
local ScoreMessageHits=""
for CategoryID,CategoryName in pairs(_SCORINGCategory)do
self:T(CategoryName)
if PlayerData.Hit[CategoryID]then
self:T("Hit scores exist for player "..PlayerName)
local Score=0
local ScoreHit=0
local Penalty=0
local PenaltyHit=0
for UnitName,UnitData in pairs(PlayerData.Hit[CategoryID])do
Score=Score+UnitData.Score
ScoreHit=ScoreHit+UnitData.ScoreHit
Penalty=Penalty+UnitData.Penalty
PenaltyHit=UnitData.PenaltyHit
end
local ScoreMessageHit=string.format("%s:%d  ",CategoryName,Score-Penalty)
self:T(ScoreMessageHit)
ScoreMessageHits=ScoreMessageHits..ScoreMessageHit
PlayerScore=PlayerScore+Score
PlayerPenalty=PlayerPenalty+Penalty
else
end
end
if ScoreMessageHits~=""then
ScoreMessage="Hits: "..ScoreMessageHits
end
end
return ScoreMessage,PlayerScore,PlayerPenalty
end
function SCORING:ReportDetailedPlayerDestroys(PlayerName)
local ScoreMessage=""
local PlayerScore=0
local PlayerPenalty=0
local PlayerData=self.Players[PlayerName]
if PlayerData then
self:T("Score Player: "..PlayerName)
local InitUnitCoalition=_SCORINGCoalition[PlayerData.UnitCoalition]
local InitUnitCategory=_SCORINGCategory[PlayerData.UnitCategory]
local InitUnitType=PlayerData.UnitType
local InitUnitName=PlayerData.UnitName
local ScoreMessageDestroys=""
for CategoryID,CategoryName in pairs(_SCORINGCategory)do
if PlayerData.Destroy[CategoryID]then
self:T("Destroy scores exist for player "..PlayerName)
local Score=0
local ScoreDestroy=0
local Penalty=0
local PenaltyDestroy=0
for UnitName,UnitData in pairs(PlayerData.Destroy[CategoryID])do
self:E({UnitData=UnitData})
if UnitData~={}then
Score=Score+UnitData.Score
ScoreDestroy=ScoreDestroy+UnitData.ScoreDestroy
Penalty=Penalty+UnitData.Penalty
PenaltyDestroy=PenaltyDestroy+UnitData.PenaltyDestroy
end
end
local ScoreMessageDestroy=string.format("  %s:%d  ",CategoryName,Score-Penalty)
self:T(ScoreMessageDestroy)
ScoreMessageDestroys=ScoreMessageDestroys..ScoreMessageDestroy
PlayerScore=PlayerScore+Score
PlayerPenalty=PlayerPenalty+Penalty
else
end
end
if ScoreMessageDestroys~=""then
ScoreMessage="Destroys: "..ScoreMessageDestroys
end
end
return ScoreMessage,PlayerScore,PlayerPenalty
end
function SCORING:ReportDetailedPlayerCoalitionChanges(PlayerName)
local ScoreMessage=""
local PlayerScore=0
local PlayerPenalty=0
local PlayerData=self.Players[PlayerName]
if PlayerData then
self:T("Score Player: "..PlayerName)
local InitUnitCoalition=_SCORINGCoalition[PlayerData.UnitCoalition]
local InitUnitCategory=_SCORINGCategory[PlayerData.UnitCategory]
local InitUnitType=PlayerData.UnitType
local InitUnitName=PlayerData.UnitName
local ScoreMessageCoalitionChangePenalties=""
if PlayerData.PenaltyCoalition~=0 then
ScoreMessageCoalitionChangePenalties=ScoreMessageCoalitionChangePenalties..string.format(" -%d (%d changed)",PlayerData.Penalty,PlayerData.PenaltyCoalition)
PlayerPenalty=PlayerPenalty+PlayerData.Penalty
end
if ScoreMessageCoalitionChangePenalties~=""then
ScoreMessage=ScoreMessage.."Coalition Penalties: "..ScoreMessageCoalitionChangePenalties
end
end
return ScoreMessage,PlayerScore,PlayerPenalty
end
function SCORING:ReportDetailedPlayerGoals(PlayerName)
local ScoreMessage=""
local PlayerScore=0
local PlayerPenalty=0
local PlayerData=self.Players[PlayerName]
if PlayerData then
self:T("Score Player: "..PlayerName)
local InitUnitCoalition=_SCORINGCoalition[PlayerData.UnitCoalition]
local InitUnitCategory=_SCORINGCategory[PlayerData.UnitCategory]
local InitUnitType=PlayerData.UnitType
local InitUnitName=PlayerData.UnitName
local ScoreMessageGoal=""
local ScoreGoal=0
local ScoreTask=0
for GoalName,GoalData in pairs(PlayerData.Goals)do
ScoreGoal=ScoreGoal+GoalData.Score
ScoreMessageGoal=ScoreMessageGoal.."'"..GoalName.."':"..GoalData.Score.."; "
end
PlayerScore=PlayerScore+ScoreGoal
if ScoreMessageGoal~=""then
ScoreMessage="Goals: "..ScoreMessageGoal
end
end
return ScoreMessage,PlayerScore,PlayerPenalty
end
function SCORING:ReportDetailedPlayerMissions(PlayerName)
local ScoreMessage=""
local PlayerScore=0
local PlayerPenalty=0
local PlayerData=self.Players[PlayerName]
if PlayerData then
self:T("Score Player: "..PlayerName)
local InitUnitCoalition=_SCORINGCoalition[PlayerData.UnitCoalition]
local InitUnitCategory=_SCORINGCategory[PlayerData.UnitCategory]
local InitUnitType=PlayerData.UnitType
local InitUnitName=PlayerData.UnitName
local ScoreMessageMission=""
local ScoreMission=0
local ScoreTask=0
for MissionName,MissionData in pairs(PlayerData.Mission)do
ScoreMission=ScoreMission+MissionData.ScoreMission
ScoreTask=ScoreTask+MissionData.ScoreTask
ScoreMessageMission=ScoreMessageMission.."'"..MissionName.."'; "
end
PlayerScore=PlayerScore+ScoreMission+ScoreTask
if ScoreMessageMission~=""then
ScoreMessage="Tasks: "..ScoreTask.." Mission: "..ScoreMission.." ( "..ScoreMessageMission..")"
end
end
return ScoreMessage,PlayerScore,PlayerPenalty
end
function SCORING:ReportScoreGroupSummary(PlayerGroup)
local PlayerMessage=""
self:T("Report Score Group Summary")
local PlayerUnits=PlayerGroup:GetUnits()
for UnitID,PlayerUnit in pairs(PlayerUnits)do
local PlayerUnit=PlayerUnit
local PlayerName=PlayerUnit:GetPlayerName()
if PlayerName then
local ReportHits,ScoreHits,PenaltyHits=self:ReportDetailedPlayerHits(PlayerName)
ReportHits=ReportHits~=""and"\n- "..ReportHits or ReportHits
self:E({ReportHits,ScoreHits,PenaltyHits})
local ReportDestroys,ScoreDestroys,PenaltyDestroys=self:ReportDetailedPlayerDestroys(PlayerName)
ReportDestroys=ReportDestroys~=""and"\n- "..ReportDestroys or ReportDestroys
self:E({ReportDestroys,ScoreDestroys,PenaltyDestroys})
local ReportCoalitionChanges,ScoreCoalitionChanges,PenaltyCoalitionChanges=self:ReportDetailedPlayerCoalitionChanges(PlayerName)
ReportCoalitionChanges=ReportCoalitionChanges~=""and"\n- "..ReportCoalitionChanges or ReportCoalitionChanges
self:E({ReportCoalitionChanges,ScoreCoalitionChanges,PenaltyCoalitionChanges})
local ReportGoals,ScoreGoals,PenaltyGoals=self:ReportDetailedPlayerGoals(PlayerName)
ReportGoals=ReportGoals~=""and"\n- "..ReportGoals or ReportGoals
self:E({ReportGoals,ScoreGoals,PenaltyGoals})
local ReportMissions,ScoreMissions,PenaltyMissions=self:ReportDetailedPlayerMissions(PlayerName)
ReportMissions=ReportMissions~=""and"\n- "..ReportMissions or ReportMissions
self:E({ReportMissions,ScoreMissions,PenaltyMissions})
local PlayerScore=ScoreHits+ScoreDestroys+ScoreCoalitionChanges+ScoreGoals+ScoreMissions
local PlayerPenalty=PenaltyHits+PenaltyDestroys+PenaltyCoalitionChanges+ScoreGoals+PenaltyMissions
PlayerMessage=
string.format("Player '%s' Score = %d ( %d Score, -%d Penalties )",
PlayerName,
PlayerScore-PlayerPenalty,
PlayerScore,
PlayerPenalty
)
MESSAGE:NewType(PlayerMessage,MESSAGE.Type.Detailed):ToGroup(PlayerGroup)
end
end
end
function SCORING:ReportScoreGroupDetailed(PlayerGroup)
local PlayerMessage=""
self:T("Report Score Group Detailed")
local PlayerUnits=PlayerGroup:GetUnits()
for UnitID,PlayerUnit in pairs(PlayerUnits)do
local PlayerUnit=PlayerUnit
local PlayerName=PlayerUnit:GetPlayerName()
if PlayerName then
local ReportHits,ScoreHits,PenaltyHits=self:ReportDetailedPlayerHits(PlayerName)
ReportHits=ReportHits~=""and"\n- "..ReportHits or ReportHits
self:E({ReportHits,ScoreHits,PenaltyHits})
local ReportDestroys,ScoreDestroys,PenaltyDestroys=self:ReportDetailedPlayerDestroys(PlayerName)
ReportDestroys=ReportDestroys~=""and"\n- "..ReportDestroys or ReportDestroys
self:E({ReportDestroys,ScoreDestroys,PenaltyDestroys})
local ReportCoalitionChanges,ScoreCoalitionChanges,PenaltyCoalitionChanges=self:ReportDetailedPlayerCoalitionChanges(PlayerName)
ReportCoalitionChanges=ReportCoalitionChanges~=""and"\n- "..ReportCoalitionChanges or ReportCoalitionChanges
self:E({ReportCoalitionChanges,ScoreCoalitionChanges,PenaltyCoalitionChanges})
local ReportGoals,ScoreGoals,PenaltyGoals=self:ReportDetailedPlayerGoals(PlayerName)
ReportGoals=ReportGoals~=""and"\n- "..ReportGoals or ReportGoals
self:E({ReportGoals,ScoreGoals,PenaltyGoals})
local ReportMissions,ScoreMissions,PenaltyMissions=self:ReportDetailedPlayerMissions(PlayerName)
ReportMissions=ReportMissions~=""and"\n- "..ReportMissions or ReportMissions
self:E({ReportMissions,ScoreMissions,PenaltyMissions})
local PlayerScore=ScoreHits+ScoreDestroys+ScoreCoalitionChanges+ScoreGoals+ScoreMissions
local PlayerPenalty=PenaltyHits+PenaltyDestroys+PenaltyCoalitionChanges+ScoreGoals+PenaltyMissions
PlayerMessage=
string.format("Player '%s' Score = %d ( %d Score, -%d Penalties )%s%s%s%s%s",
PlayerName,
PlayerScore-PlayerPenalty,
PlayerScore,
PlayerPenalty,
ReportHits,
ReportDestroys,
ReportCoalitionChanges,
ReportGoals,
ReportMissions
)
MESSAGE:NewType(PlayerMessage,MESSAGE.Type.Detailed):ToGroup(PlayerGroup)
end
end
end
function SCORING:ReportScoreAllSummary(PlayerGroup)
local PlayerMessage=""
self:T("Report Score All Players")
for PlayerName,PlayerData in pairs(self.Players)do
if PlayerName then
local ReportHits,ScoreHits,PenaltyHits=self:ReportDetailedPlayerHits(PlayerName)
ReportHits=ReportHits~=""and"\n- "..ReportHits or ReportHits
self:E({ReportHits,ScoreHits,PenaltyHits})
local ReportDestroys,ScoreDestroys,PenaltyDestroys=self:ReportDetailedPlayerDestroys(PlayerName)
ReportDestroys=ReportDestroys~=""and"\n- "..ReportDestroys or ReportDestroys
self:E({ReportDestroys,ScoreDestroys,PenaltyDestroys})
local ReportCoalitionChanges,ScoreCoalitionChanges,PenaltyCoalitionChanges=self:ReportDetailedPlayerCoalitionChanges(PlayerName)
ReportCoalitionChanges=ReportCoalitionChanges~=""and"\n- "..ReportCoalitionChanges or ReportCoalitionChanges
self:E({ReportCoalitionChanges,ScoreCoalitionChanges,PenaltyCoalitionChanges})
local ReportGoals,ScoreGoals,PenaltyGoals=self:ReportDetailedPlayerGoals(PlayerName)
ReportGoals=ReportGoals~=""and"\n- "..ReportGoals or ReportGoals
self:E({ReportGoals,ScoreGoals,PenaltyGoals})
local ReportMissions,ScoreMissions,PenaltyMissions=self:ReportDetailedPlayerMissions(PlayerName)
ReportMissions=ReportMissions~=""and"\n- "..ReportMissions or ReportMissions
self:E({ReportMissions,ScoreMissions,PenaltyMissions})
local PlayerScore=ScoreHits+ScoreDestroys+ScoreCoalitionChanges+ScoreGoals+ScoreMissions
local PlayerPenalty=PenaltyHits+PenaltyDestroys+PenaltyCoalitionChanges+ScoreGoals+PenaltyMissions
PlayerMessage=
string.format("Player '%s' Score = %d ( %d Score, -%d Penalties )",
PlayerName,
PlayerScore-PlayerPenalty,
PlayerScore,
PlayerPenalty
)
MESSAGE:NewType(PlayerMessage,MESSAGE.Type.Overview):ToGroup(PlayerGroup)
end
end
end
function SCORING:SecondsToClock(sSeconds)
local nSeconds=sSeconds
if nSeconds==0 then
return"00:00:00";
else
nHours=string.format("%02.f",math.floor(nSeconds/3600));
nMins=string.format("%02.f",math.floor(nSeconds/60-(nHours*60)));
nSecs=string.format("%02.f",math.floor(nSeconds-nHours*3600-nMins*60));
return nHours..":"..nMins..":"..nSecs
end
end
function SCORING:OpenCSV(ScoringCSV)
self:F(ScoringCSV)
if lfs and io and os then
if ScoringCSV then
self.ScoringCSV=ScoringCSV
local fdir=lfs.writedir()..[[Logs\]]..self.ScoringCSV.." "..os.date("%Y-%m-%d %H-%M-%S")..".csv"
self.CSVFile,self.err=io.open(fdir,"w+")
if not self.CSVFile then
error("Error: Cannot open CSV file in "..lfs.writedir())
end
self.CSVFile:write('"GameName","RunTime","Time","PlayerName","TargetPlayerName","ScoreType","PlayerUnitCoaltion","PlayerUnitCategory","PlayerUnitType","PlayerUnitName","TargetUnitCoalition","TargetUnitCategory","TargetUnitType","TargetUnitName","Times","Score"\n')
self.RunTime=os.date("%y-%m-%d_%H-%M-%S")
else
error("A string containing the CSV file name must be given.")
end
else
self:E("The MissionScripting.lua file has not been changed to allow lfs, io and os modules to be used...")
end
return self
end
function SCORING:ScoreCSV(PlayerName,TargetPlayerName,ScoreType,ScoreTimes,ScoreAmount,PlayerUnitName,PlayerUnitCoalition,PlayerUnitCategory,PlayerUnitType,TargetUnitName,TargetUnitCoalition,TargetUnitCategory,TargetUnitType)
local ScoreTime=self:SecondsToClock(timer.getTime())
PlayerName=PlayerName:gsub('"','_')
TargetPlayerName=TargetPlayerName or""
TargetPlayerName=TargetPlayerName:gsub('"','_')
if PlayerUnitName and PlayerUnitName~=''then
local PlayerUnit=Unit.getByName(PlayerUnitName)
if PlayerUnit then
if not PlayerUnitCategory then
PlayerUnitCategory=_SCORINGCategory[PlayerUnit:getDesc().category]
end
if not PlayerUnitCoalition then
PlayerUnitCoalition=_SCORINGCoalition[PlayerUnit:getCoalition()]
end
if not PlayerUnitType then
PlayerUnitType=PlayerUnit:getTypeName()
end
else
PlayerUnitName=''
PlayerUnitCategory=''
PlayerUnitCoalition=''
PlayerUnitType=''
end
else
PlayerUnitName=''
PlayerUnitCategory=''
PlayerUnitCoalition=''
PlayerUnitType=''
end
TargetUnitCoalition=TargetUnitCoalition or""
TargetUnitCategory=TargetUnitCategory or""
TargetUnitType=TargetUnitType or""
TargetUnitName=TargetUnitName or""
if lfs and io and os then
self.CSVFile:write(
'"'..self.GameName..'"'..','..
'"'..self.RunTime..'"'..','..
''..ScoreTime..''..','..
'"'..PlayerName..'"'..','..
'"'..TargetPlayerName..'"'..','..
'"'..ScoreType..'"'..','..
'"'..PlayerUnitCoalition..'"'..','..
'"'..PlayerUnitCategory..'"'..','..
'"'..PlayerUnitType..'"'..','..
'"'..PlayerUnitName..'"'..','..
'"'..TargetUnitCoalition..'"'..','..
'"'..TargetUnitCategory..'"'..','..
'"'..TargetUnitType..'"'..','..
'"'..TargetUnitName..'"'..','..
''..ScoreTimes..''..','..
''..ScoreAmount
)
self.CSVFile:write("\n")
end
end
function SCORING:CloseCSV()
if lfs and io and os then
self.CSVFile:close()
end
end
CLEANUP_AIRBASE={
ClassName="CLEANUP_AIRBASE",
TimeInterval=0.2,
CleanUpList={},
}
CLEANUP_AIRBASE.__={}
CLEANUP_AIRBASE.__.Airbases={}
function CLEANUP_AIRBASE:New(AirbaseNames)
local self=BASE:Inherit(self,BASE:New())
self:F({AirbaseNames})
if type(AirbaseNames)=='table'then
for AirbaseID,AirbaseName in pairs(AirbaseNames)do
self:AddAirbase(AirbaseName)
end
else
local AirbaseName=AirbaseNames
self:AddAirbase(AirbaseName)
end
self:HandleEvent(EVENTS.Birth,self.__.OnEventBirth)
self.__.CleanUpScheduler=SCHEDULER:New(self,self.__.CleanUpSchedule,{},1,self.TimeInterval)
self:HandleEvent(EVENTS.EngineShutdown,self.__.EventAddForCleanUp)
self:HandleEvent(EVENTS.EngineStartup,self.__.EventAddForCleanUp)
self:HandleEvent(EVENTS.Hit,self.__.EventAddForCleanUp)
self:HandleEvent(EVENTS.PilotDead,self.__.OnEventCrash)
self:HandleEvent(EVENTS.Dead,self.__.OnEventCrash)
self:HandleEvent(EVENTS.Crash,self.__.OnEventCrash)
return self
end
function CLEANUP_AIRBASE:AddAirbase(AirbaseName)
self.__.Airbases[AirbaseName]=AIRBASE:FindByName(AirbaseName)
self:F({"Airbase:",AirbaseName,self.__.Airbases[AirbaseName]:GetDesc()})
return self
end
function CLEANUP_AIRBASE:RemoveAirbase(AirbaseName)
self.__.Airbases[AirbaseName]=nil
return self
end
function CLEANUP_AIRBASE:SetCleanMissiles(CleanMissiles)
if CleanMissiles then
self:HandleEvent(EVENTS.Shot,self.__.OnEventShot)
else
self:UnHandleEvent(EVENTS.Shot)
end
end
function CLEANUP_AIRBASE.__:IsInAirbase(Vec2)
local InAirbase=false
for AirbaseName,Airbase in pairs(self.__.Airbases)do
local Airbase=Airbase
if Airbase:GetZone():IsVec2InZone(Vec2)then
InAirbase=true
break;
end
end
return InAirbase
end
function CLEANUP_AIRBASE.__:DestroyUnit(CleanUpUnit)
self:F({CleanUpUnit})
if CleanUpUnit then
local CleanUpUnitName=CleanUpUnit:GetName()
local CleanUpGroup=CleanUpUnit:GetGroup()
if CleanUpGroup:IsAlive()then
local CleanUpGroupUnits=CleanUpGroup:GetUnits()
if#CleanUpGroupUnits==1 then
local CleanUpGroupName=CleanUpGroup:GetName()
CleanUpGroup:Destroy()
else
CleanUpUnit:Destroy()
end
self.CleanUpList[CleanUpUnitName]=nil
end
end
end
function CLEANUP_AIRBASE.__:DestroyMissile(MissileObject)
self:F({MissileObject})
if MissileObject and MissileObject:isExist()then
MissileObject:destroy()
self:T("MissileObject Destroyed")
end
end
function CLEANUP_AIRBASE.__:OnEventBirth(EventData)
self:F({EventData})
self.CleanUpList[EventData.IniDCSUnitName]={}
self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnit=EventData.IniUnit
self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroup=EventData.IniGroup
self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroupName=EventData.IniDCSGroupName
self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnitName=EventData.IniDCSUnitName
end
function CLEANUP_AIRBASE.__:OnEventCrash(Event)
self:F({Event})
if Event.IniDCSUnitName and Event.IniCategory==Object.Category.UNIT then
self.CleanUpList[Event.IniDCSUnitName]={}
self.CleanUpList[Event.IniDCSUnitName].CleanUpUnit=Event.IniUnit
self.CleanUpList[Event.IniDCSUnitName].CleanUpGroup=Event.IniGroup
self.CleanUpList[Event.IniDCSUnitName].CleanUpGroupName=Event.IniDCSGroupName
self.CleanUpList[Event.IniDCSUnitName].CleanUpUnitName=Event.IniDCSUnitName
end
end
function CLEANUP_AIRBASE.__:OnEventShot(Event)
self:F({Event})
if self:IsInAirbase(Event.IniUnit:GetVec2())then
self:DestroyMissile(Event.Weapon)
end
end
function CLEANUP_AIRBASE.__:OnEventHit(Event)
self:F({Event})
if Event.IniUnit then
if self:IsInAirbase(Event.IniUnit:GetVec2())then
self:T({"Life: ",Event.IniDCSUnitName,' = ',Event.IniUnit:GetLife(),"/",Event.IniUnit:GetLife0()})
if Event.IniUnit:GetLife()<Event.IniUnit:GetLife0()then
self:T("CleanUp: Destroy: "..Event.IniDCSUnitName)
CLEANUP_AIRBASE.__:DestroyUnit(Event.IniUnit)
end
end
end
if Event.TgtUnit then
if self:IsInAirbase(Event.TgtUnit:GetVec2())then
self:T({"Life: ",Event.TgtDCSUnitName,' = ',Event.TgtUnit:GetLife(),"/",Event.TgtUnit:GetLife0()})
if Event.TgtUnit:GetLife()<Event.TgtUnit:GetLife0()then
self:T("CleanUp: Destroy: "..Event.TgtDCSUnitName)
CLEANUP_AIRBASE.__:DestroyUnit(Event.TgtUnit)
end
end
end
end
function CLEANUP_AIRBASE.__:AddForCleanUp(CleanUpUnit,CleanUpUnitName)
self:F({CleanUpUnit,CleanUpUnitName})
self.CleanUpList[CleanUpUnitName]={}
self.CleanUpList[CleanUpUnitName].CleanUpUnit=CleanUpUnit
self.CleanUpList[CleanUpUnitName].CleanUpUnitName=CleanUpUnitName
local CleanUpGroup=CleanUpUnit:GetGroup()
self.CleanUpList[CleanUpUnitName].CleanUpGroup=CleanUpGroup
self.CleanUpList[CleanUpUnitName].CleanUpGroupName=CleanUpGroup:GetName()
self.CleanUpList[CleanUpUnitName].CleanUpTime=timer.getTime()
self.CleanUpList[CleanUpUnitName].CleanUpMoved=false
self:T({"CleanUp: Add to CleanUpList: ",CleanUpGroup:GetName(),CleanUpUnitName})
end
function CLEANUP_AIRBASE.__:EventAddForCleanUp(Event)
self:F({Event})
if Event.IniDCSUnit and Event.IniCategory==Object.Category.UNIT then
if self.CleanUpList[Event.IniDCSUnitName]==nil then
if self:IsInAirbase(Event.IniUnit:GetVec2())then
self:AddForCleanUp(Event.IniUnit,Event.IniDCSUnitName)
end
end
end
if Event.TgtDCSUnit and Event.TgtCategory==Object.Category.UNIT then
if self.CleanUpList[Event.TgtDCSUnitName]==nil then
if self:IsInAirbase(Event.TgtUnit:GetVec2())then
self:AddForCleanUp(Event.TgtUnit,Event.TgtDCSUnitName)
end
end
end
end
function CLEANUP_AIRBASE.__:CleanUpSchedule()
local CleanUpCount=0
for CleanUpUnitName,CleanUpListData in pairs(self.CleanUpList)do
CleanUpCount=CleanUpCount+1
local CleanUpUnit=CleanUpListData.CleanUpUnit
local CleanUpGroupName=CleanUpListData.CleanUpGroupName
if CleanUpUnit:IsAlive()~=nil then
if _DATABASE:GetStatusGroup(CleanUpGroupName)~="ReSpawn"then
local CleanUpCoordinate=CleanUpUnit:GetCoordinate()
self:T({"CleanUp Scheduler",CleanUpUnitName})
if CleanUpUnit:GetLife()<=CleanUpUnit:GetLife0()*0.95 then
if CleanUpUnit:IsAboveRunway()then
if CleanUpUnit:InAir()then
local CleanUpLandHeight=CleanUpCoordinate:GetLandHeight()
local CleanUpUnitHeight=CleanUpCoordinate.y-CleanUpLandHeight
if CleanUpUnitHeight<100 then
self:T({"CleanUp Scheduler","Destroy "..CleanUpUnitName.." because below safe height and damaged."})
self:DestroyUnit(CleanUpUnit)
end
else
self:T({"CleanUp Scheduler","Destroy "..CleanUpUnitName.." because on runway and damaged."})
self:DestroyUnit(CleanUpUnit)
end
end
end
if CleanUpUnit then
local CleanUpUnitVelocity=CleanUpUnit:GetVelocityKMH()
if CleanUpUnitVelocity<1 then
if CleanUpListData.CleanUpMoved then
if CleanUpListData.CleanUpTime+180<=timer.getTime()then
self:T({"CleanUp Scheduler","Destroy due to not moving anymore "..CleanUpUnitName})
self:DestroyUnit(CleanUpUnit)
end
end
else
CleanUpListData.CleanUpTime=timer.getTime()
CleanUpListData.CleanUpMoved=true
end
end
else
self.CleanUpList[CleanUpUnitName]=nil
end
else
self:T("CleanUp: Group "..CleanUpUnitName.." cannot be found in DCS RTE, removing ...")
self.CleanUpList[CleanUpUnitName]=nil
end
end
self:T(CleanUpCount)
return true
end
SPAWN={
ClassName="SPAWN",
SpawnTemplatePrefix=nil,
SpawnAliasPrefix=nil,
}
SPAWN.Takeoff=GROUP.Takeoff
function SPAWN:New(SpawnTemplatePrefix)
local self=BASE:Inherit(self,BASE:New())
self:F({SpawnTemplatePrefix})
local TemplateGroup=Group.getByName(SpawnTemplatePrefix)
if TemplateGroup then
self.SpawnTemplatePrefix=SpawnTemplatePrefix
self.SpawnIndex=0
self.SpawnCount=0
self.AliveUnits=0
self.SpawnIsScheduled=false
self.SpawnTemplate=self._GetTemplate(self,SpawnTemplatePrefix)
self.Repeat=false
self.UnControlled=false
self.SpawnInitLimit=false
self.SpawnMaxUnitsAlive=0
self.SpawnMaxGroups=0
self.SpawnRandomize=false
self.SpawnVisible=false
self.AIOnOff=true
self.SpawnUnControlled=false
self.SpawnInitKeepUnitNames=false
self.DelayOnOff=false
self.Grouping=nil
self.SpawnGroups={}
else
error("SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '"..SpawnTemplatePrefix.."'")
end
self:SetEventPriority(5)
return self
end
function SPAWN:NewWithAlias(SpawnTemplatePrefix,SpawnAliasPrefix)
local self=BASE:Inherit(self,BASE:New())
self:F({SpawnTemplatePrefix,SpawnAliasPrefix})
local TemplateGroup=Group.getByName(SpawnTemplatePrefix)
if TemplateGroup then
self.SpawnTemplatePrefix=SpawnTemplatePrefix
self.SpawnAliasPrefix=SpawnAliasPrefix
self.SpawnIndex=0
self.SpawnCount=0
self.AliveUnits=0
self.SpawnIsScheduled=false
self.SpawnTemplate=self._GetTemplate(self,SpawnTemplatePrefix)
self.Repeat=false
self.UnControlled=false
self.SpawnInitLimit=false
self.SpawnMaxUnitsAlive=0
self.SpawnMaxGroups=0
self.SpawnRandomize=false
self.SpawnVisible=false
self.AIOnOff=true
self.SpawnUnControlled=false
self.SpawnInitKeepUnitNames=false
self.DelayOnOff=false
self.Grouping=nil
self.SpawnGroups={}
else
error("SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '"..SpawnTemplatePrefix.."'")
end
self:SetEventPriority(5)
return self
end
function SPAWN:InitLimit(SpawnMaxUnitsAlive,SpawnMaxGroups)
self:F({self.SpawnTemplatePrefix,SpawnMaxUnitsAlive,SpawnMaxGroups})
self.SpawnInitLimit=true
self.SpawnMaxUnitsAlive=SpawnMaxUnitsAlive
self.SpawnMaxGroups=SpawnMaxGroups
for SpawnGroupID=1,self.SpawnMaxGroups do
self:_InitializeSpawnGroups(SpawnGroupID)
end
return self
end
function SPAWN:InitKeepUnitNames()
self:F()
self.SpawnInitKeepUnitNames=true
return self
end
function SPAWN:InitRandomizeRoute(SpawnStartPoint,SpawnEndPoint,SpawnRadius,SpawnHeight)
self:F({self.SpawnTemplatePrefix,SpawnStartPoint,SpawnEndPoint,SpawnRadius,SpawnHeight})
self.SpawnRandomizeRoute=true
self.SpawnRandomizeRouteStartPoint=SpawnStartPoint
self.SpawnRandomizeRouteEndPoint=SpawnEndPoint
self.SpawnRandomizeRouteRadius=SpawnRadius
self.SpawnRandomizeRouteHeight=SpawnHeight
for GroupID=1,self.SpawnMaxGroups do
self:_RandomizeRoute(GroupID)
end
return self
end
function SPAWN:InitRandomizePosition(RandomizePosition,OuterRadius,InnerRadius)
self:F({self.SpawnTemplatePrefix,RandomizePosition,OuterRadius,InnerRadius})
self.SpawnRandomizePosition=RandomizePosition or false
self.SpawnRandomizePositionOuterRadius=OuterRadius or 0
self.SpawnRandomizePositionInnerRadius=InnerRadius or 0
for GroupID=1,self.SpawnMaxGroups do
self:_RandomizeRoute(GroupID)
end
return self
end
function SPAWN:InitRandomizeUnits(RandomizeUnits,OuterRadius,InnerRadius)
self:F({self.SpawnTemplatePrefix,RandomizeUnits,OuterRadius,InnerRadius})
self.SpawnRandomizeUnits=RandomizeUnits or false
self.SpawnOuterRadius=OuterRadius or 0
self.SpawnInnerRadius=InnerRadius or 0
for GroupID=1,self.SpawnMaxGroups do
self:_RandomizeRoute(GroupID)
end
return self
end
function SPAWN:InitRandomizeTemplate(SpawnTemplatePrefixTable)
self:F({self.SpawnTemplatePrefix,SpawnTemplatePrefixTable})
self.SpawnTemplatePrefixTable=SpawnTemplatePrefixTable
self.SpawnRandomizeTemplate=true
for SpawnGroupID=1,self.SpawnMaxGroups do
self:_RandomizeTemplate(SpawnGroupID)
end
return self
end
function SPAWN:InitGrouping(Grouping)
self:F({self.SpawnTemplatePrefix,Grouping})
self.SpawnGrouping=Grouping
return self
end
function SPAWN:InitRandomizeZones(SpawnZoneTable)
self:F({self.SpawnTemplatePrefix,SpawnZoneTable})
self.SpawnZoneTable=SpawnZoneTable
self.SpawnRandomizeZones=true
for SpawnGroupID=1,self.SpawnMaxGroups do
self:_RandomizeZones(SpawnGroupID)
end
return self
end
function SPAWN:InitRepeat()
self:F({self.SpawnTemplatePrefix,self.SpawnIndex})
self.Repeat=true
self.RepeatOnEngineShutDown=false
self.RepeatOnLanding=true
return self
end
function SPAWN:InitRepeatOnLanding()
self:F({self.SpawnTemplatePrefix})
self:InitRepeat()
self.RepeatOnEngineShutDown=false
self.RepeatOnLanding=true
return self
end
function SPAWN:InitRepeatOnEngineShutDown()
self:F({self.SpawnTemplatePrefix})
self:InitRepeat()
self.RepeatOnEngineShutDown=true
self.RepeatOnLanding=false
return self
end
function SPAWN:InitCleanUp(SpawnCleanUpInterval)
self:F({self.SpawnTemplatePrefix,SpawnCleanUpInterval})
self.SpawnCleanUpInterval=SpawnCleanUpInterval
self.SpawnCleanUpTimeStamps={}
local SpawnGroup,SpawnCursor=self:GetFirstAliveGroup()
self:T({"CleanUp Scheduler:",SpawnGroup})
self.CleanUpScheduler=SCHEDULER:New(self,self._SpawnCleanUpScheduler,{},1,SpawnCleanUpInterval,0.2)
return self
end
function SPAWN:InitArray(SpawnAngle,SpawnWidth,SpawnDeltaX,SpawnDeltaY)
self:F({self.SpawnTemplatePrefix,SpawnAngle,SpawnWidth,SpawnDeltaX,SpawnDeltaY})
self.SpawnVisible=true
local SpawnX=0
local SpawnY=0
local SpawnXIndex=0
local SpawnYIndex=0
for SpawnGroupID=1,self.SpawnMaxGroups do
self:T({SpawnX,SpawnY,SpawnXIndex,SpawnYIndex})
self.SpawnGroups[SpawnGroupID].Visible=true
self.SpawnGroups[SpawnGroupID].Spawned=false
SpawnXIndex=SpawnXIndex+1
if SpawnWidth and SpawnWidth~=0 then
if SpawnXIndex>=SpawnWidth then
SpawnXIndex=0
SpawnYIndex=SpawnYIndex+1
end
end
local SpawnRootX=self.SpawnGroups[SpawnGroupID].SpawnTemplate.x
local SpawnRootY=self.SpawnGroups[SpawnGroupID].SpawnTemplate.y
self:_TranslateRotate(SpawnGroupID,SpawnRootX,SpawnRootY,SpawnX,SpawnY,SpawnAngle)
self.SpawnGroups[SpawnGroupID].SpawnTemplate.lateActivation=true
self.SpawnGroups[SpawnGroupID].SpawnTemplate.visible=true
self.SpawnGroups[SpawnGroupID].Visible=true
self:HandleEvent(EVENTS.Birth,self._OnBirth)
self:HandleEvent(EVENTS.Dead,self._OnDeadOrCrash)
self:HandleEvent(EVENTS.Crash,self._OnDeadOrCrash)
if self.Repeat then
self:HandleEvent(EVENTS.Takeoff,self._OnTakeOff)
self:HandleEvent(EVENTS.Land,self._OnLand)
end
if self.RepeatOnEngineShutDown then
self:HandleEvent(EVENTS.EngineShutdown,self._OnEngineShutDown)
end
self.SpawnGroups[SpawnGroupID].Group=_DATABASE:Spawn(self.SpawnGroups[SpawnGroupID].SpawnTemplate)
SpawnX=SpawnXIndex*SpawnDeltaX
SpawnY=SpawnYIndex*SpawnDeltaY
end
return self
end
do
function SPAWN:InitAIOnOff(AIOnOff)
self.AIOnOff=AIOnOff
return self
end
function SPAWN:InitAIOn()
return self:InitAIOnOff(true)
end
function SPAWN:InitAIOff()
return self:InitAIOnOff(false)
end
end
do
function SPAWN:InitDelayOnOff(DelayOnOff)
self.DelayOnOff=DelayOnOff
return self
end
function SPAWN:InitDelayOn()
return self:InitDelayOnOff(true)
end
function SPAWN:InitDelayOff()
return self:InitDelayOnOff(false)
end
end
function SPAWN:Spawn()
self:F({self.SpawnTemplatePrefix,self.SpawnIndex,self.AliveUnits})
return self:SpawnWithIndex(self.SpawnIndex+1)
end
function SPAWN:ReSpawn(SpawnIndex)
self:F({self.SpawnTemplatePrefix,SpawnIndex})
if not SpawnIndex then
SpawnIndex=1
end
local SpawnGroup=self:GetGroupFromIndex(SpawnIndex)
local WayPoints=SpawnGroup and SpawnGroup.WayPoints or nil
if SpawnGroup then
local SpawnDCSGroup=SpawnGroup:GetDCSObject()
if SpawnDCSGroup then
SpawnGroup:Destroy()
end
end
local SpawnGroup=self:SpawnWithIndex(SpawnIndex)
if SpawnGroup and WayPoints then
SpawnGroup:WayPointInitialize(WayPoints)
SpawnGroup:WayPointExecute(1,5)
end
if SpawnGroup.ReSpawnFunction then
SpawnGroup:ReSpawnFunction()
end
SpawnGroup:ResetEvents()
return SpawnGroup
end
function SPAWN:SpawnWithIndex(SpawnIndex)
self:F2({SpawnTemplatePrefix=self.SpawnTemplatePrefix,SpawnIndex=SpawnIndex,AliveUnits=self.AliveUnits,SpawnMaxGroups=self.SpawnMaxGroups})
if self:_GetSpawnIndex(SpawnIndex)then
if self.SpawnGroups[self.SpawnIndex].Visible then
self.SpawnGroups[self.SpawnIndex].Group:Activate()
else
local SpawnTemplate=self.SpawnGroups[self.SpawnIndex].SpawnTemplate
self:T(SpawnTemplate.name)
if SpawnTemplate then
local PointVec3=POINT_VEC3:New(SpawnTemplate.route.points[1].x,SpawnTemplate.route.points[1].alt,SpawnTemplate.route.points[1].y)
self:T({"Current point of ",self.SpawnTemplatePrefix,PointVec3})
if self.SpawnRandomizePosition then
local RandomVec2=PointVec3:GetRandomVec2InRadius(self.SpawnRandomizePositionOuterRadius,self.SpawnRandomizePositionInnerRadius)
local CurrentX=SpawnTemplate.units[1].x
local CurrentY=SpawnTemplate.units[1].y
SpawnTemplate.x=RandomVec2.x
SpawnTemplate.y=RandomVec2.y
for UnitID=1,#SpawnTemplate.units do
SpawnTemplate.units[UnitID].x=SpawnTemplate.units[UnitID].x+(RandomVec2.x-CurrentX)
SpawnTemplate.units[UnitID].y=SpawnTemplate.units[UnitID].y+(RandomVec2.y-CurrentY)
self:T('SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
end
end
if self.SpawnRandomizeUnits then
for UnitID=1,#SpawnTemplate.units do
local RandomVec2=PointVec3:GetRandomVec2InRadius(self.SpawnOuterRadius,self.SpawnInnerRadius)
SpawnTemplate.units[UnitID].x=RandomVec2.x
SpawnTemplate.units[UnitID].y=RandomVec2.y
self:T('SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
end
end
if SpawnTemplate.CategoryID==Group.Category.HELICOPTER or SpawnTemplate.CategoryID==Group.Category.AIRPLANE then
if SpawnTemplate.route.points[1].type=="TakeOffParking"then
SpawnTemplate.uncontrolled=self.SpawnUnControlled
end
end
end
self:HandleEvent(EVENTS.Birth,self._OnBirth)
self:HandleEvent(EVENTS.Dead,self._OnDeadOrCrash)
self:HandleEvent(EVENTS.Crash,self._OnDeadOrCrash)
if self.Repeat then
self:HandleEvent(EVENTS.Takeoff,self._OnTakeOff)
self:HandleEvent(EVENTS.Land,self._OnLand)
end
if self.RepeatOnEngineShutDown then
self:HandleEvent(EVENTS.EngineShutdown,self._OnEngineShutDown)
end
self.SpawnGroups[self.SpawnIndex].Group=_DATABASE:Spawn(SpawnTemplate)
local SpawnGroup=self.SpawnGroups[self.SpawnIndex].Group
if SpawnGroup then
SpawnGroup:SetAIOnOff(self.AIOnOff)
end
self:T3(SpawnTemplate.name)
if self.SpawnFunctionHook then
self.SpawnHookScheduler=SCHEDULER:New()
self.SpawnHookScheduler:Schedule(nil,self.SpawnFunctionHook,{self.SpawnGroups[self.SpawnIndex].Group,unpack(self.SpawnFunctionArguments)},0.1)
end
end
self.SpawnGroups[self.SpawnIndex].Spawned=true
return self.SpawnGroups[self.SpawnIndex].Group
else
end
return nil
end
function SPAWN:SpawnScheduled(SpawnTime,SpawnTimeVariation)
self:F({SpawnTime,SpawnTimeVariation})
if SpawnTime~=nil and SpawnTimeVariation~=nil then
local InitialDelay=0
if self.DelayOnOff==true then
InitialDelay=math.random(SpawnTime-SpawnTime*SpawnTimeVariation,SpawnTime+SpawnTime*SpawnTimeVariation)
end
self.SpawnScheduler=SCHEDULER:New(self,self._Scheduler,{},InitialDelay,SpawnTime,SpawnTimeVariation)
end
return self
end
function SPAWN:SpawnScheduleStart()
self:F({self.SpawnTemplatePrefix})
self.SpawnScheduler:Start()
return self
end
function SPAWN:SpawnScheduleStop()
self:F({self.SpawnTemplatePrefix})
self.SpawnScheduler:Stop()
return self
end
function SPAWN:OnSpawnGroup(SpawnCallBackFunction,...)
self:F("OnSpawnGroup")
self.SpawnFunctionHook=SpawnCallBackFunction
self.SpawnFunctionArguments={}
if arg then
self.SpawnFunctionArguments=arg
end
return self
end
function SPAWN:SpawnAtAirbase(SpawnAirbase,Takeoff,TakeoffAltitude)
self:E({self.SpawnTemplatePrefix,SpawnAirbase,Takeoff,TakeoffAltitude})
local PointVec3=SpawnAirbase:GetPointVec3()
self:T2(PointVec3)
Takeoff=Takeoff or SPAWN.Takeoff.Hot
if self:_GetSpawnIndex(self.SpawnIndex+1)then
local SpawnTemplate=self.SpawnGroups[self.SpawnIndex].SpawnTemplate
if SpawnTemplate then
self:T({"Current point of ",self.SpawnTemplatePrefix,SpawnAirbase})
local SpawnPoint=SpawnTemplate.route.points[1]
SpawnPoint.linkUnit=nil
SpawnPoint.helipadId=nil
SpawnPoint.airdromeId=nil
local AirbaseID=SpawnAirbase:GetID()
local AirbaseCategory=SpawnAirbase:GetDesc().category
self:F({AirbaseCategory=AirbaseCategory})
if AirbaseCategory==Airbase.Category.SHIP then
SpawnPoint.linkUnit=AirbaseID
SpawnPoint.helipadId=AirbaseID
elseif AirbaseCategory==Airbase.Category.HELIPAD then
SpawnPoint.linkUnit=AirbaseID
SpawnPoint.helipadId=AirbaseID
elseif AirbaseCategory==Airbase.Category.AIRDROME then
SpawnPoint.airdromeId=AirbaseID
end
SpawnPoint.alt=0
SpawnPoint.type=GROUPTEMPLATE.Takeoff[Takeoff][1]
SpawnPoint.action=GROUPTEMPLATE.Takeoff[Takeoff][2]
for UnitID=1,#SpawnTemplate.units do
self:T('Before Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
local UnitTemplate=SpawnTemplate.units[UnitID]
UnitTemplate.parking=nil
UnitTemplate.parking_id=nil
UnitTemplate.alt=0
local SX=UnitTemplate.x
local SY=UnitTemplate.y
local BX=SpawnPoint.x
local BY=SpawnPoint.y
local TX=PointVec3.x+(SX-BX)
local TY=PointVec3.z+(SY-BY)
UnitTemplate.x=TX
UnitTemplate.y=TY
if Takeoff==GROUP.Takeoff.Air then
UnitTemplate.alt=PointVec3.y+(TakeoffAltitude or 200)
end
self:T('After Translation SpawnTemplate.units['..UnitID..'].x = '..UnitTemplate.x..', SpawnTemplate.units['..UnitID..'].y = '..UnitTemplate.y)
end
SpawnPoint.x=PointVec3.x
SpawnPoint.y=PointVec3.z
if Takeoff==GROUP.Takeoff.Air then
SpawnPoint.alt=PointVec3.y+(TakeoffAltitude or 200)
end
SpawnTemplate.x=PointVec3.x
SpawnTemplate.y=PointVec3.z
local GroupSpawned=self:SpawnWithIndex(self.SpawnIndex)
if Takeoff==GROUP.Takeoff.Air then
for UnitID,UnitSpawned in pairs(GroupSpawned:GetUnits())do
SCHEDULER:New(nil,BASE.CreateEventTakeoff,{GroupSpawned,timer.getTime(),UnitSpawned:GetDCSObject()},1)
end
end
return GroupSpawned
end
end
return nil
end
function SPAWN:SpawnFromVec3(Vec3,SpawnIndex)
self:F({self.SpawnTemplatePrefix,Vec3,SpawnIndex})
local PointVec3=POINT_VEC3:NewFromVec3(Vec3)
self:T2(PointVec3)
if SpawnIndex then
else
SpawnIndex=self.SpawnIndex+1
end
if self:_GetSpawnIndex(SpawnIndex)then
local SpawnTemplate=self.SpawnGroups[self.SpawnIndex].SpawnTemplate
if SpawnTemplate then
self:T({"Current point of ",self.SpawnTemplatePrefix,Vec3})
local TemplateHeight=SpawnTemplate.route.points[1].alt
for UnitID=1,#SpawnTemplate.units do
self:T('Before Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
local UnitTemplate=SpawnTemplate.units[UnitID]
local SX=UnitTemplate.x
local SY=UnitTemplate.y
local BX=SpawnTemplate.route.points[1].x
local BY=SpawnTemplate.route.points[1].y
local TX=Vec3.x+(SX-BX)
local TY=Vec3.z+(SY-BY)
SpawnTemplate.units[UnitID].x=TX
SpawnTemplate.units[UnitID].y=TY
SpawnTemplate.units[UnitID].alt=Vec3.y or TemplateHeight
self:T('After Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
end
SpawnTemplate.route.points[1].x=Vec3.x
SpawnTemplate.route.points[1].y=Vec3.z
SpawnTemplate.route.points[1].alt=Vec3.y or TemplateHeight
SpawnTemplate.x=Vec3.x
SpawnTemplate.y=Vec3.z
SpawnTemplate.alt=Vec3.y or TemplateHeight
return self:SpawnWithIndex(self.SpawnIndex)
end
end
return nil
end
function SPAWN:SpawnFromVec2(Vec2,MinHeight,MaxHeight,SpawnIndex)
self:F({self.SpawnTemplatePrefix,self.SpawnIndex,Vec2,MinHeight,MaxHeight,SpawnIndex})
local Height=nil
if MinHeight and MaxHeight then
Height=math.random(MinHeight,MaxHeight)
end
return self:SpawnFromVec3({x=Vec2.x,y=Height,z=Vec2.y},SpawnIndex)
end
function SPAWN:SpawnFromUnit(HostUnit,MinHeight,MaxHeight,SpawnIndex)
self:F({self.SpawnTemplatePrefix,HostUnit,MinHeight,MaxHeight,SpawnIndex})
if HostUnit and HostUnit:IsAlive()~=nil then
return self:SpawnFromVec2(HostUnit:GetVec2(),MinHeight,MaxHeight,SpawnIndex)
end
return nil
end
function SPAWN:SpawnFromStatic(HostStatic,MinHeight,MaxHeight,SpawnIndex)
self:F({self.SpawnTemplatePrefix,HostStatic,MinHeight,MaxHeight,SpawnIndex})
if HostStatic and HostStatic:IsAlive()then
return self:SpawnFromVec2(HostStatic:GetVec2(),MinHeight,MaxHeight,SpawnIndex)
end
return nil
end
function SPAWN:SpawnInZone(Zone,RandomizeGroup,MinHeight,MaxHeight,SpawnIndex)
self:F({self.SpawnTemplatePrefix,Zone,RandomizeGroup,MinHeight,MaxHeight,SpawnIndex})
if Zone then
if RandomizeGroup then
return self:SpawnFromVec2(Zone:GetRandomVec2(),MinHeight,MaxHeight,SpawnIndex)
else
return self:SpawnFromVec2(Zone:GetVec2(),MinHeight,MaxHeight,SpawnIndex)
end
end
return nil
end
function SPAWN:InitUnControlled(UnControlled)
self:F2({self.SpawnTemplatePrefix,UnControlled})
self.SpawnUnControlled=UnControlled
for SpawnGroupID=1,self.SpawnMaxGroups do
self.SpawnGroups[SpawnGroupID].UnControlled=UnControlled
end
return self
end
function SPAWN:GetCoordinate()
local LateGroup=GROUP:FindByName(self.SpawnTemplatePrefix)
if LateGroup then
return LateGroup:GetCoordinate()
end
return nil
end
function SPAWN:SpawnGroupName(SpawnIndex)
self:F({self.SpawnTemplatePrefix,SpawnIndex})
local SpawnPrefix=self.SpawnTemplatePrefix
if self.SpawnAliasPrefix then
SpawnPrefix=self.SpawnAliasPrefix
end
if SpawnIndex then
local SpawnName=string.format('%s#%03d',SpawnPrefix,SpawnIndex)
self:T(SpawnName)
return SpawnName
else
self:T(SpawnPrefix)
return SpawnPrefix
end
end
function SPAWN:GetFirstAliveGroup()
self:F({self.SpawnTemplatePrefix,self.SpawnAliasPrefix})
for SpawnIndex=1,self.SpawnCount do
local SpawnGroup=self:GetGroupFromIndex(SpawnIndex)
if SpawnGroup and SpawnGroup:IsAlive()then
return SpawnGroup,SpawnIndex
end
end
return nil,nil
end
function SPAWN:GetNextAliveGroup(SpawnIndexStart)
self:F({self.SpawnTemplatePrefix,self.SpawnAliasPrefix,SpawnIndexStart})
SpawnIndexStart=SpawnIndexStart+1
for SpawnIndex=SpawnIndexStart,self.SpawnCount do
local SpawnGroup=self:GetGroupFromIndex(SpawnIndex)
if SpawnGroup and SpawnGroup:IsAlive()then
return SpawnGroup,SpawnIndex
end
end
return nil,nil
end
function SPAWN:GetLastAliveGroup()
self:F({self.SpawnTemplatePrefixself.SpawnAliasPrefix})
self.SpawnIndex=self:_GetLastIndex()
for SpawnIndex=self.SpawnIndex,1,-1 do
local SpawnGroup=self:GetGroupFromIndex(SpawnIndex)
if SpawnGroup and SpawnGroup:IsAlive()then
self.SpawnIndex=SpawnIndex
return SpawnGroup
end
end
self.SpawnIndex=nil
return nil
end
function SPAWN:GetGroupFromIndex(SpawnIndex)
self:F({self.SpawnTemplatePrefix,self.SpawnAliasPrefix,SpawnIndex})
if not SpawnIndex then
SpawnIndex=1
end
if self.SpawnGroups and self.SpawnGroups[SpawnIndex]then
local SpawnGroup=self.SpawnGroups[SpawnIndex].Group
return SpawnGroup
else
return nil
end
end
function SPAWN:_GetPrefixFromGroup(SpawnGroup)
self:F3({self.SpawnTemplatePrefix,self.SpawnAliasPrefix,SpawnGroup})
local GroupName=SpawnGroup:GetName()
if GroupName then
local SpawnPrefix=string.match(GroupName,".*#")
if SpawnPrefix then
SpawnPrefix=SpawnPrefix:sub(1,-2)
end
return SpawnPrefix
end
return nil
end
function SPAWN:GetSpawnIndexFromGroup(SpawnGroup)
self:F({self.SpawnTemplatePrefix,self.SpawnAliasPrefix,SpawnGroup})
local IndexString=string.match(SpawnGroup:GetName(),"#(%d*)$"):sub(2)
local Index=tonumber(IndexString)
self:T3(IndexString,Index)
return Index
end
function SPAWN:_GetLastIndex()
self:F({self.SpawnTemplatePrefix,self.SpawnAliasPrefix})
return self.SpawnMaxGroups
end
function SPAWN:_InitializeSpawnGroups(SpawnIndex)
self:F3({self.SpawnTemplatePrefix,self.SpawnAliasPrefix,SpawnIndex})
if not self.SpawnGroups[SpawnIndex]then
self.SpawnGroups[SpawnIndex]={}
self.SpawnGroups[SpawnIndex].Visible=false
self.SpawnGroups[SpawnIndex].Spawned=false
self.SpawnGroups[SpawnIndex].UnControlled=false
self.SpawnGroups[SpawnIndex].SpawnTime=0
self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix=self.SpawnTemplatePrefix
self.SpawnGroups[SpawnIndex].SpawnTemplate=self:_Prepare(self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix,SpawnIndex)
end
self:_RandomizeTemplate(SpawnIndex)
self:_RandomizeRoute(SpawnIndex)
return self.SpawnGroups[SpawnIndex]
end
function SPAWN:_GetGroupCategoryID(SpawnPrefix)
local TemplateGroup=Group.getByName(SpawnPrefix)
if TemplateGroup then
return TemplateGroup:getCategory()
else
return nil
end
end
function SPAWN:_GetGroupCoalitionID(SpawnPrefix)
local TemplateGroup=Group.getByName(SpawnPrefix)
if TemplateGroup then
return TemplateGroup:getCoalition()
else
return nil
end
end
function SPAWN:_GetGroupCountryID(SpawnPrefix)
self:F({self.SpawnTemplatePrefix,self.SpawnAliasPrefix,SpawnPrefix})
local TemplateGroup=Group.getByName(SpawnPrefix)
if TemplateGroup then
local TemplateUnits=TemplateGroup:getUnits()
return TemplateUnits[1]:getCountry()
else
return nil
end
end
function SPAWN:_GetTemplate(SpawnTemplatePrefix)
self:F({self.SpawnTemplatePrefix,self.SpawnAliasPrefix,SpawnTemplatePrefix})
local SpawnTemplate=nil
SpawnTemplate=routines.utils.deepCopy(_DATABASE.Templates.Groups[SpawnTemplatePrefix].Template)
if SpawnTemplate==nil then
error('No Template returned for SpawnTemplatePrefix = '..SpawnTemplatePrefix)
end
self:T3({SpawnTemplate})
return SpawnTemplate
end
function SPAWN:_Prepare(SpawnTemplatePrefix,SpawnIndex)
self:F({self.SpawnTemplatePrefix,self.SpawnAliasPrefix})
local SpawnTemplate=self:_GetTemplate(SpawnTemplatePrefix)
SpawnTemplate.name=self:SpawnGroupName(SpawnIndex)
SpawnTemplate.groupId=nil
SpawnTemplate.lateActivation=false
if SpawnTemplate.CategoryID==Group.Category.GROUND then
self:T3("For ground units, visible needs to be false...")
SpawnTemplate.visible=false
end
if self.SpawnGrouping then
local UnitAmount=#SpawnTemplate.units
self:F({UnitAmount=UnitAmount,SpawnGrouping=self.SpawnGrouping})
if UnitAmount>self.SpawnGrouping then
for UnitID=self.SpawnGrouping+1,UnitAmount do
SpawnTemplate.units[UnitID]=nil
end
else
if UnitAmount<self.SpawnGrouping then
for UnitID=UnitAmount+1,self.SpawnGrouping do
SpawnTemplate.units[UnitID]=UTILS.DeepCopy(SpawnTemplate.units[1])
SpawnTemplate.units[UnitID].unitId=nil
end
end
end
end
if self.SpawnInitKeepUnitNames==false then
for UnitID=1,#SpawnTemplate.units do
SpawnTemplate.units[UnitID].name=string.format(SpawnTemplate.name..'-%02d',UnitID)
SpawnTemplate.units[UnitID].unitId=nil
end
else
for UnitID=1,#SpawnTemplate.units do
local UnitPrefix,Rest=string.match(SpawnTemplate.units[UnitID].name,"^([^#]+)#?"):gsub("^%s*(.-)%s*$","%1")
self:T({UnitPrefix,Rest})
SpawnTemplate.units[UnitID].name=string.format('%s#%03d-%02d',UnitPrefix,SpawnIndex,UnitID)
SpawnTemplate.units[UnitID].unitId=nil
end
end
self:T3({"Template:",SpawnTemplate})
return SpawnTemplate
end
function SPAWN:_RandomizeRoute(SpawnIndex)
self:F({self.SpawnTemplatePrefix,SpawnIndex,self.SpawnRandomizeRoute,self.SpawnRandomizeRouteStartPoint,self.SpawnRandomizeRouteEndPoint,self.SpawnRandomizeRouteRadius})
if self.SpawnRandomizeRoute then
local SpawnTemplate=self.SpawnGroups[SpawnIndex].SpawnTemplate
local RouteCount=#SpawnTemplate.route.points
for t=self.SpawnRandomizeRouteStartPoint+1,(RouteCount-self.SpawnRandomizeRouteEndPoint)do
SpawnTemplate.route.points[t].x=SpawnTemplate.route.points[t].x+math.random(self.SpawnRandomizeRouteRadius*-1,self.SpawnRandomizeRouteRadius)
SpawnTemplate.route.points[t].y=SpawnTemplate.route.points[t].y+math.random(self.SpawnRandomizeRouteRadius*-1,self.SpawnRandomizeRouteRadius)
if SpawnTemplate.CategoryID==Group.Category.AIRPLANE or SpawnTemplate.CategoryID==Group.Category.HELICOPTER then
if SpawnTemplate.route.points[t].alt and self.SpawnRandomizeRouteHeight then
SpawnTemplate.route.points[t].alt=SpawnTemplate.route.points[t].alt+math.random(1,self.SpawnRandomizeRouteHeight)
end
else
SpawnTemplate.route.points[t].alt=nil
end
self:T('SpawnTemplate.route.points['..t..'].x = '..SpawnTemplate.route.points[t].x..', SpawnTemplate.route.points['..t..'].y = '..SpawnTemplate.route.points[t].y)
end
end
self:_RandomizeZones(SpawnIndex)
return self
end
function SPAWN:_RandomizeTemplate(SpawnIndex)
self:F({self.SpawnTemplatePrefix,SpawnIndex,self.SpawnRandomizeTemplate})
if self.SpawnRandomizeTemplate then
self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix=self.SpawnTemplatePrefixTable[math.random(1,#self.SpawnTemplatePrefixTable)]
self.SpawnGroups[SpawnIndex].SpawnTemplate=self:_Prepare(self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix,SpawnIndex)
self.SpawnGroups[SpawnIndex].SpawnTemplate.route=routines.utils.deepCopy(self.SpawnTemplate.route)
self.SpawnGroups[SpawnIndex].SpawnTemplate.x=self.SpawnTemplate.x
self.SpawnGroups[SpawnIndex].SpawnTemplate.y=self.SpawnTemplate.y
self.SpawnGroups[SpawnIndex].SpawnTemplate.start_time=self.SpawnTemplate.start_time
local OldX=self.SpawnGroups[SpawnIndex].SpawnTemplate.units[1].x
local OldY=self.SpawnGroups[SpawnIndex].SpawnTemplate.units[1].y
for UnitID=1,#self.SpawnGroups[SpawnIndex].SpawnTemplate.units do
self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].heading=self.SpawnTemplate.units[1].heading
self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].x=self.SpawnTemplate.units[1].x+(self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].x-OldX)
self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].y=self.SpawnTemplate.units[1].y+(self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].y-OldY)
self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].alt=self.SpawnTemplate.units[1].alt
end
end
self:_RandomizeRoute(SpawnIndex)
return self
end
function SPAWN:_RandomizeZones(SpawnIndex)
self:F({self.SpawnTemplatePrefix,SpawnIndex,self.SpawnRandomizeZones})
if self.SpawnRandomizeZones then
local SpawnZone=nil
while not SpawnZone do
self:T({SpawnZoneTableCount=#self.SpawnZoneTable,self.SpawnZoneTable})
local ZoneID=math.random(#self.SpawnZoneTable)
self:T(ZoneID)
SpawnZone=self.SpawnZoneTable[ZoneID]:GetZoneMaybe()
end
self:T("Preparing Spawn in Zone",SpawnZone:GetName())
local SpawnVec2=SpawnZone:GetRandomVec2()
self:T({SpawnVec2=SpawnVec2})
local SpawnTemplate=self.SpawnGroups[SpawnIndex].SpawnTemplate
self:T({Route=SpawnTemplate.route})
for UnitID=1,#SpawnTemplate.units do
local UnitTemplate=SpawnTemplate.units[UnitID]
self:T('Before Translation SpawnTemplate.units['..UnitID..'].x = '..UnitTemplate.x..', SpawnTemplate.units['..UnitID..'].y = '..UnitTemplate.y)
local SX=UnitTemplate.x
local SY=UnitTemplate.y
local BX=SpawnTemplate.route.points[1].x
local BY=SpawnTemplate.route.points[1].y
local TX=SpawnVec2.x+(SX-BX)
local TY=SpawnVec2.y+(SY-BY)
UnitTemplate.x=TX
UnitTemplate.y=TY
self:T('After Translation SpawnTemplate.units['..UnitID..'].x = '..UnitTemplate.x..', SpawnTemplate.units['..UnitID..'].y = '..UnitTemplate.y)
end
SpawnTemplate.x=SpawnVec2.x
SpawnTemplate.y=SpawnVec2.y
SpawnTemplate.route.points[1].x=SpawnVec2.x
SpawnTemplate.route.points[1].y=SpawnVec2.y
end
return self
end
function SPAWN:_TranslateRotate(SpawnIndex,SpawnRootX,SpawnRootY,SpawnX,SpawnY,SpawnAngle)
self:F({self.SpawnTemplatePrefix,SpawnIndex,SpawnRootX,SpawnRootY,SpawnX,SpawnY,SpawnAngle})
local TranslatedX=SpawnX
local TranslatedY=SpawnY
local RotatedX=-TranslatedX*math.cos(math.rad(SpawnAngle))
+TranslatedY*math.sin(math.rad(SpawnAngle))
local RotatedY=TranslatedX*math.sin(math.rad(SpawnAngle))
+TranslatedY*math.cos(math.rad(SpawnAngle))
self.SpawnGroups[SpawnIndex].SpawnTemplate.x=SpawnRootX-RotatedX
self.SpawnGroups[SpawnIndex].SpawnTemplate.y=SpawnRootY+RotatedY
local SpawnUnitCount=table.getn(self.SpawnGroups[SpawnIndex].SpawnTemplate.units)
for u=1,SpawnUnitCount do
local TranslatedX=SpawnX
local TranslatedY=SpawnY-10*(u-1)
local RotatedX=-TranslatedX*math.cos(math.rad(SpawnAngle))
+TranslatedY*math.sin(math.rad(SpawnAngle))
local RotatedY=TranslatedX*math.sin(math.rad(SpawnAngle))
+TranslatedY*math.cos(math.rad(SpawnAngle))
self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].x=SpawnRootX-RotatedX
self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].y=SpawnRootY+RotatedY
self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading=self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading+math.rad(SpawnAngle)
end
return self
end
function SPAWN:_GetSpawnIndex(SpawnIndex)
self:F2({self.SpawnTemplatePrefix,SpawnIndex,self.SpawnMaxGroups,self.SpawnMaxUnitsAlive,self.AliveUnits,#self.SpawnTemplate.units})
if(self.SpawnMaxGroups==0)or(SpawnIndex<=self.SpawnMaxGroups)then
if(self.SpawnMaxUnitsAlive==0)or(self.AliveUnits+#self.SpawnTemplate.units<=self.SpawnMaxUnitsAlive)or self.UnControlled==true then
if SpawnIndex and SpawnIndex>=self.SpawnCount+1 then
self.SpawnCount=self.SpawnCount+1
SpawnIndex=self.SpawnCount
end
self.SpawnIndex=SpawnIndex
if not self.SpawnGroups[self.SpawnIndex]then
self:_InitializeSpawnGroups(self.SpawnIndex)
end
else
return nil
end
else
return nil
end
return self.SpawnIndex
end
function SPAWN:_OnBirth(EventData)
self:F(self.SpawnTemplatePrefix)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
self:T({"Birth Event:",EventPrefix,self.SpawnTemplatePrefix})
if EventPrefix==self.SpawnTemplatePrefix or(self.SpawnAliasPrefix and EventPrefix==self.SpawnAliasPrefix)then
self.AliveUnits=self.AliveUnits+1
self:T("Alive Units: "..self.AliveUnits)
end
end
end
end
function SPAWN:_OnDeadOrCrash(EventData)
self:F(self.SpawnTemplatePrefix)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
self:T({"Dead event: "..EventPrefix})
if EventPrefix==self.SpawnTemplatePrefix or(self.SpawnAliasPrefix and EventPrefix==self.SpawnAliasPrefix)then
self.AliveUnits=self.AliveUnits-1
self:T("Alive Units: "..self.AliveUnits)
end
end
end
end
function SPAWN:_OnTakeOff(EventData)
self:F(self.SpawnTemplatePrefix)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
self:T({"TakeOff event: "..EventPrefix})
if EventPrefix==self.SpawnTemplatePrefix or(self.SpawnAliasPrefix and EventPrefix==self.SpawnAliasPrefix)then
self:T("self.Landed = false")
SpawnGroup:SetState(SpawnGroup,"Spawn_Landed",false)
end
end
end
end
function SPAWN:_OnLand(EventData)
self:F(self.SpawnTemplatePrefix)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
self:T({"Land event: "..EventPrefix})
if EventPrefix==self.SpawnTemplatePrefix or(self.SpawnAliasPrefix and EventPrefix==self.SpawnAliasPrefix)then
SpawnGroup:SetState(SpawnGroup,"Spawn_Landed",true)
if self.RepeatOnLanding then
local SpawnGroupIndex=self:GetSpawnIndexFromGroup(SpawnGroup)
self:T({"Landed:","ReSpawn:",SpawnGroup:GetName(),SpawnGroupIndex})
self:ReSpawn(SpawnGroupIndex)
end
end
end
end
end
function SPAWN:_OnEngineShutDown(EventData)
self:F(self.SpawnTemplatePrefix)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
self:T({"EngineShutdown event: "..EventPrefix})
if EventPrefix==self.SpawnTemplatePrefix or(self.SpawnAliasPrefix and EventPrefix==self.SpawnAliasPrefix)then
local Landed=SpawnGroup:GetState(SpawnGroup,"Spawn_Landed")
if Landed and self.RepeatOnEngineShutDown then
local SpawnGroupIndex=self:GetSpawnIndexFromGroup(SpawnGroup)
self:T({"EngineShutDown: ","ReSpawn:",SpawnGroup:GetName(),SpawnGroupIndex})
self:ReSpawn(SpawnGroupIndex)
end
end
end
end
end
function SPAWN:_Scheduler()
self:F2({"_Scheduler",self.SpawnTemplatePrefix,self.SpawnAliasPrefix,self.SpawnIndex,self.SpawnMaxGroups,self.SpawnMaxUnitsAlive})
self:Spawn()
return true
end
function SPAWN:_SpawnCleanUpScheduler()
self:F({"CleanUp Scheduler:",self.SpawnTemplatePrefix})
local SpawnGroup,SpawnCursor=self:GetFirstAliveGroup()
self:T({"CleanUp Scheduler:",SpawnGroup,SpawnCursor})
while SpawnGroup do
local SpawnUnits=SpawnGroup:GetUnits()
for UnitID,UnitData in pairs(SpawnUnits)do
local SpawnUnit=UnitData
local SpawnUnitName=SpawnUnit:GetName()
self.SpawnCleanUpTimeStamps[SpawnUnitName]=self.SpawnCleanUpTimeStamps[SpawnUnitName]or{}
local Stamp=self.SpawnCleanUpTimeStamps[SpawnUnitName]
self:T({SpawnUnitName,Stamp})
if Stamp.Vec2 then
if SpawnUnit:InAir()==false and SpawnUnit:GetVelocityKMH()<1 then
local NewVec2=SpawnUnit:GetVec2()
if Stamp.Vec2.x==NewVec2.x and Stamp.Vec2.y==NewVec2.y then
if Stamp.Time+self.SpawnCleanUpInterval<timer.getTime()then
self:T({"CleanUp Scheduler:","ReSpawning:",SpawnGroup:GetName()})
self:ReSpawn(SpawnCursor)
Stamp.Vec2=nil
Stamp.Time=nil
end
else
Stamp.Time=timer.getTime()
Stamp.Vec2=SpawnUnit:GetVec2()
end
else
Stamp.Vec2=nil
Stamp.Time=nil
end
else
if SpawnUnit:InAir()==false then
Stamp.Vec2=SpawnUnit:GetVec2()
if SpawnUnit:GetVelocityKMH()<1 then
Stamp.Time=timer.getTime()
end
else
Stamp.Time=nil
Stamp.Vec2=nil
end
end
end
SpawnGroup,SpawnCursor=self:GetNextAliveGroup(SpawnCursor)
self:T({"CleanUp Scheduler:",SpawnGroup,SpawnCursor})
end
return true
end
MOVEMENT={
ClassName="MOVEMENT",
}
function MOVEMENT:New(MovePrefixes,MoveMaximum)
local self=BASE:Inherit(self,BASE:New())
self:F({MovePrefixes,MoveMaximum})
if type(MovePrefixes)=='table'then
self.MovePrefixes=MovePrefixes
else
self.MovePrefixes={MovePrefixes}
end
self.MoveCount=0
self.MoveMaximum=MoveMaximum
self.AliveUnits=0
self.MoveUnits={}
self:HandleEvent(EVENTS.Birth)
self:ScheduleStart()
return self
end
function MOVEMENT:ScheduleStart()
self:F()
self.MoveFunction=SCHEDULER:New(self,self._Scheduler,{},1,120)
end
function MOVEMENT:ScheduleStop()
self:F()
end
function MOVEMENT:OnEventBirth(EventData)
self:F({EventData})
if timer.getTime0()<timer.getAbsTime()then
if EventData.IniDCSUnit then
self:T("Birth object : "..EventData.IniDCSUnitName)
if EventData.IniDCSGroup and EventData.IniDCSGroup:isExist()then
for MovePrefixID,MovePrefix in pairs(self.MovePrefixes)do
if string.find(EventData.IniDCSUnitName,MovePrefix,1,true)then
self.AliveUnits=self.AliveUnits+1
self.MoveUnits[EventData.IniDCSUnitName]=EventData.IniDCSGroupName
self:T(self.AliveUnits)
end
end
end
end
EventData.IniUnit:HandleEvent(EVENTS.DEAD,self.OnDeadOrCrash)
end
end
function MOVEMENT:OnDeadOrCrash(Event)
self:F({Event})
if Event.IniDCSUnit then
self:T("Dead object : "..Event.IniDCSUnitName)
for MovePrefixID,MovePrefix in pairs(self.MovePrefixes)do
if string.find(Event.IniDCSUnitName,MovePrefix,1,true)then
self.AliveUnits=self.AliveUnits-1
self.MoveUnits[Event.IniDCSUnitName]=nil
self:T(self.AliveUnits)
end
end
end
end
function MOVEMENT:_Scheduler()
self:F({self.MovePrefixes,self.MoveMaximum,self.AliveUnits,self.MovementGroups})
if self.AliveUnits>0 then
local MoveProbability=(self.MoveMaximum*100)/self.AliveUnits
self:T('Move Probability = '..MoveProbability)
for MovementUnitName,MovementGroupName in pairs(self.MoveUnits)do
local MovementGroup=Group.getByName(MovementGroupName)
if MovementGroup and MovementGroup:isExist()then
local MoveOrStop=math.random(1,100)
self:T('MoveOrStop = '..MoveOrStop)
if MoveOrStop<=MoveProbability then
self:T('Group continues moving = '..MovementGroupName)
trigger.action.groupContinueMoving(MovementGroup)
else
self:T('Group stops moving = '..MovementGroupName)
trigger.action.groupStopMoving(MovementGroup)
end
else
self.MoveUnits[MovementUnitName]=nil
end
end
end
return true
end
SEAD={
ClassName="SEAD",
TargetSkill={
Average={Evade=50,DelayOff={10,25},DelayOn={10,30}},
Good={Evade=30,DelayOff={8,20},DelayOn={20,40}},
High={Evade=15,DelayOff={5,17},DelayOn={30,50}},
Excellent={Evade=10,DelayOff={3,10},DelayOn={30,60}}
},
SEADGroupPrefixes={}
}
function SEAD:New(SEADGroupPrefixes)
local self=BASE:Inherit(self,BASE:New())
self:F(SEADGroupPrefixes)
if type(SEADGroupPrefixes)=='table'then
for SEADGroupPrefixID,SEADGroupPrefix in pairs(SEADGroupPrefixes)do
self.SEADGroupPrefixes[SEADGroupPrefix]=SEADGroupPrefix
end
else
self.SEADGroupNames[SEADGroupPrefixes]=SEADGroupPrefixes
end
self:HandleEvent(EVENTS.Shot)
return self
end
function SEAD:OnEventShot(EventData)
self:F({EventData})
local SEADUnit=EventData.IniDCSUnit
local SEADUnitName=EventData.IniDCSUnitName
local SEADWeapon=EventData.Weapon
local SEADWeaponName=EventData.WeaponName
self:T("Missile Launched = "..SEADWeaponName)
if SEADWeaponName=="KH-58"or SEADWeaponName=="KH-25MPU"or SEADWeaponName=="AGM-88"or SEADWeaponName=="KH-31A"or SEADWeaponName=="KH-31P"then
local _evade=math.random(1,100)
local _targetMim=EventData.Weapon:getTarget()
local _targetMimname=Unit.getName(_targetMim)
local _targetMimgroup=Unit.getGroup(Weapon.getTarget(SEADWeapon))
local _targetMimgroupName=_targetMimgroup:getName()
local _targetMimcont=_targetMimgroup:getController()
local _targetskill=_DATABASE.Templates.Units[_targetMimname].Template.skill
self:T(self.SEADGroupPrefixes)
self:T(_targetMimgroupName)
local SEADGroupFound=false
for SEADGroupPrefixID,SEADGroupPrefix in pairs(self.SEADGroupPrefixes)do
if string.find(_targetMimgroupName,SEADGroupPrefix,1,true)then
SEADGroupFound=true
self:T('Group Found')
break
end
end
if SEADGroupFound==true then
if _targetskill=="Random"then
local Skills={"Average","Good","High","Excellent"}
_targetskill=Skills[math.random(1,4)]
end
self:T(_targetskill)
if self.TargetSkill[_targetskill]then
if(_evade>self.TargetSkill[_targetskill].Evade)then
self:T(string.format("Evading, target skill  "..string.format(_targetskill)))
local _targetMim=Weapon.getTarget(SEADWeapon)
local _targetMimname=Unit.getName(_targetMim)
local _targetMimgroup=Unit.getGroup(Weapon.getTarget(SEADWeapon))
local _targetMimcont=_targetMimgroup:getController()
routines.groupRandomDistSelf(_targetMimgroup,300,'Diamond',250,20)
local SuppressedGroups1={}
local function SuppressionEnd1(id)
id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
SuppressedGroups1[id.groupName]=nil
end
local id={
groupName=_targetMimgroup,
ctrl=_targetMimcont
}
local delay1=math.random(self.TargetSkill[_targetskill].DelayOff[1],self.TargetSkill[_targetskill].DelayOff[2])
if SuppressedGroups1[id.groupName]==nil then
SuppressedGroups1[id.groupName]={
SuppressionEndTime1=timer.getTime()+delay1,
SuppressionEndN1=SuppressionEndCounter1
}
Controller.setOption(_targetMimcont,AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
timer.scheduleFunction(SuppressionEnd1,id,SuppressedGroups1[id.groupName].SuppressionEndTime1)
end
local SuppressedGroups={}
local function SuppressionEnd(id)
id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.RED)
SuppressedGroups[id.groupName]=nil
end
local id={
groupName=_targetMimgroup,
ctrl=_targetMimcont
}
local delay=math.random(self.TargetSkill[_targetskill].DelayOn[1],self.TargetSkill[_targetskill].DelayOn[2])
if SuppressedGroups[id.groupName]==nil then
SuppressedGroups[id.groupName]={
SuppressionEndTime=timer.getTime()+delay,
SuppressionEndN=SuppressionEndCounter
}
timer.scheduleFunction(SuppressionEnd,id,SuppressedGroups[id.groupName].SuppressionEndTime)
end
end
end
end
end
end
ESCORT={
ClassName="ESCORT",
EscortName=nil,
EscortClient=nil,
EscortGroup=nil,
EscortMode=1,
MODE={
FOLLOW=1,
MISSION=2,
},
Targets={},
FollowScheduler=nil,
ReportTargets=true,
OptionROE=AI.Option.Air.val.ROE.OPEN_FIRE,
OptionReactionOnThreat=AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
SmokeDirectionVector=false,
TaskPoints={}
}
function ESCORT:New(EscortClient,EscortGroup,EscortName,EscortBriefing)
local self=BASE:Inherit(self,BASE:New())
self:F({EscortClient,EscortGroup,EscortName})
self.EscortClient=EscortClient
self.EscortGroup=EscortGroup
self.EscortName=EscortName
self.EscortBriefing=EscortBriefing
self.EscortSetGroup=SET_GROUP:New()
self.EscortSetGroup:AddObject(self.EscortGroup)
self.EscortSetGroup:Flush()
self.Detection=DETECTION_UNITS:New(self.EscortSetGroup,15000)
self.EscortGroup.Detection=self.Detection
if not self.EscortClient._EscortGroups then
self.EscortClient._EscortGroups={}
end
if not self.EscortClient._EscortGroups[EscortGroup:GetName()]then
self.EscortClient._EscortGroups[EscortGroup:GetName()]={}
self.EscortClient._EscortGroups[EscortGroup:GetName()].EscortGroup=self.EscortGroup
self.EscortClient._EscortGroups[EscortGroup:GetName()].EscortName=self.EscortName
self.EscortClient._EscortGroups[EscortGroup:GetName()].Detection=self.EscortGroup.Detection
end
self.EscortMenu=MENU_CLIENT:New(self.EscortClient,self.EscortName)
self.EscortGroup:WayPointInitialize(1)
self.EscortGroup:OptionROTVertical()
self.EscortGroup:OptionROEOpenFire()
if not EscortBriefing then
EscortGroup:MessageToClient(EscortGroup:GetCategoryName().." '"..EscortName.."' ("..EscortGroup:GetCallsign()..") reporting! "..
"We're escorting your flight. "..
"Use the Radio Menu and F10 and use the options under + "..EscortName.."\n",
60,EscortClient
)
else
EscortGroup:MessageToClient(EscortGroup:GetCategoryName().." '"..EscortName.."' ("..EscortGroup:GetCallsign()..") "..EscortBriefing,
60,EscortClient
)
end
self.FollowDistance=100
self.CT1=0
self.GT1=0
self.FollowScheduler,self.FollowSchedule=SCHEDULER:New(self,self._FollowScheduler,{},1,.5,.01)
self.FollowScheduler:Stop(self.FollowSchedule)
self.EscortMode=ESCORT.MODE.MISSION
return self
end
function ESCORT:SetDetection(Detection)
self.Detection=Detection
self.EscortGroup.Detection=self.Detection
self.EscortClient._EscortGroups[self.EscortGroup:GetName()].Detection=self.EscortGroup.Detection
Detection:__Start(1)
end
function ESCORT:TestSmokeDirectionVector(SmokeDirection)
self.SmokeDirectionVector=(SmokeDirection==true)and true or false
end
function ESCORT:Menus()
self:F()
self:MenuFollowAt(100)
self:MenuFollowAt(200)
self:MenuFollowAt(300)
self:MenuFollowAt(400)
self:MenuScanForTargets(100,60)
self:MenuHoldAtEscortPosition(30)
self:MenuHoldAtLeaderPosition(30)
self:MenuFlare()
self:MenuSmoke()
self:MenuReportTargets(60)
self:MenuAssistedAttack()
self:MenuROE()
self:MenuEvasion()
self:MenuResumeMission()
return self
end
function ESCORT:MenuFollowAt(Distance)
self:F(Distance)
if self.EscortGroup:IsAir()then
if not self.EscortMenuReportNavigation then
self.EscortMenuReportNavigation=MENU_CLIENT:New(self.EscortClient,"Navigation",self.EscortMenu)
end
if not self.EscortMenuJoinUpAndFollow then
self.EscortMenuJoinUpAndFollow={}
end
self.EscortMenuJoinUpAndFollow[#self.EscortMenuJoinUpAndFollow+1]=MENU_CLIENT_COMMAND:New(self.EscortClient,"Join-Up and Follow at "..Distance,self.EscortMenuReportNavigation,ESCORT._JoinUpAndFollow,self,Distance)
self.EscortMode=ESCORT.MODE.FOLLOW
end
return self
end
function ESCORT:MenuHoldAtEscortPosition(Height,Seconds,MenuTextFormat)
self:F({Height,Seconds,MenuTextFormat})
if self.EscortGroup:IsAir()then
if not self.EscortMenuHold then
self.EscortMenuHold=MENU_CLIENT:New(self.EscortClient,"Hold position",self.EscortMenu)
end
if not Height then
Height=30
end
if not Seconds then
Seconds=0
end
local MenuText=""
if not MenuTextFormat then
if Seconds==0 then
MenuText=string.format("Hold at %d meter",Height)
else
MenuText=string.format("Hold at %d meter for %d seconds",Height,Seconds)
end
else
if Seconds==0 then
MenuText=string.format(MenuTextFormat,Height)
else
MenuText=string.format(MenuTextFormat,Height,Seconds)
end
end
if not self.EscortMenuHoldPosition then
self.EscortMenuHoldPosition={}
end
self.EscortMenuHoldPosition[#self.EscortMenuHoldPosition+1]=MENU_CLIENT_COMMAND
:New(
self.EscortClient,
MenuText,
self.EscortMenuHold,
ESCORT._HoldPosition,
self,
self.EscortGroup,
Height,
Seconds
)
end
return self
end
function ESCORT:MenuHoldAtLeaderPosition(Height,Seconds,MenuTextFormat)
self:F({Height,Seconds,MenuTextFormat})
if self.EscortGroup:IsAir()then
if not self.EscortMenuHold then
self.EscortMenuHold=MENU_CLIENT:New(self.EscortClient,"Hold position",self.EscortMenu)
end
if not Height then
Height=30
end
if not Seconds then
Seconds=0
end
local MenuText=""
if not MenuTextFormat then
if Seconds==0 then
MenuText=string.format("Rejoin and hold at %d meter",Height)
else
MenuText=string.format("Rejoin and hold at %d meter for %d seconds",Height,Seconds)
end
else
if Seconds==0 then
MenuText=string.format(MenuTextFormat,Height)
else
MenuText=string.format(MenuTextFormat,Height,Seconds)
end
end
if not self.EscortMenuHoldAtLeaderPosition then
self.EscortMenuHoldAtLeaderPosition={}
end
self.EscortMenuHoldAtLeaderPosition[#self.EscortMenuHoldAtLeaderPosition+1]=MENU_CLIENT_COMMAND
:New(
self.EscortClient,
MenuText,
self.EscortMenuHold,
ESCORT._HoldPosition,
{ParamSelf=self,
ParamOrbitGroup=self.EscortClient,
ParamHeight=Height,
ParamSeconds=Seconds
}
)
end
return self
end
function ESCORT:MenuScanForTargets(Height,Seconds,MenuTextFormat)
self:F({Height,Seconds,MenuTextFormat})
if self.EscortGroup:IsAir()then
if not self.EscortMenuScan then
self.EscortMenuScan=MENU_CLIENT:New(self.EscortClient,"Scan for targets",self.EscortMenu)
end
if not Height then
Height=100
end
if not Seconds then
Seconds=30
end
local MenuText=""
if not MenuTextFormat then
if Seconds==0 then
MenuText=string.format("At %d meter",Height)
else
MenuText=string.format("At %d meter for %d seconds",Height,Seconds)
end
else
if Seconds==0 then
MenuText=string.format(MenuTextFormat,Height)
else
MenuText=string.format(MenuTextFormat,Height,Seconds)
end
end
if not self.EscortMenuScanForTargets then
self.EscortMenuScanForTargets={}
end
self.EscortMenuScanForTargets[#self.EscortMenuScanForTargets+1]=MENU_CLIENT_COMMAND
:New(
self.EscortClient,
MenuText,
self.EscortMenuScan,
ESCORT._ScanTargets,
self,
30
)
end
return self
end
function ESCORT:MenuFlare(MenuTextFormat)
self:F()
if not self.EscortMenuReportNavigation then
self.EscortMenuReportNavigation=MENU_CLIENT:New(self.EscortClient,"Navigation",self.EscortMenu)
end
local MenuText=""
if not MenuTextFormat then
MenuText="Flare"
else
MenuText=MenuTextFormat
end
if not self.EscortMenuFlare then
self.EscortMenuFlare=MENU_CLIENT:New(self.EscortClient,MenuText,self.EscortMenuReportNavigation,ESCORT._Flare,self)
self.EscortMenuFlareGreen=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release green flare",self.EscortMenuFlare,ESCORT._Flare,self,FLARECOLOR.Green,"Released a green flare!")
self.EscortMenuFlareRed=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release red flare",self.EscortMenuFlare,ESCORT._Flare,self,FLARECOLOR.Red,"Released a red flare!")
self.EscortMenuFlareWhite=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release white flare",self.EscortMenuFlare,ESCORT._Flare,self,FLARECOLOR.White,"Released a white flare!")
self.EscortMenuFlareYellow=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release yellow flare",self.EscortMenuFlare,ESCORT._Flare,self,FLARECOLOR.Yellow,"Released a yellow flare!")
end
return self
end
function ESCORT:MenuSmoke(MenuTextFormat)
self:F()
if not self.EscortGroup:IsAir()then
if not self.EscortMenuReportNavigation then
self.EscortMenuReportNavigation=MENU_CLIENT:New(self.EscortClient,"Navigation",self.EscortMenu)
end
local MenuText=""
if not MenuTextFormat then
MenuText="Smoke"
else
MenuText=MenuTextFormat
end
if not self.EscortMenuSmoke then
self.EscortMenuSmoke=MENU_CLIENT:New(self.EscortClient,"Smoke",self.EscortMenuReportNavigation,ESCORT._Smoke,self)
self.EscortMenuSmokeGreen=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release green smoke",self.EscortMenuSmoke,ESCORT._Smoke,self,SMOKECOLOR.Green,"Releasing green smoke!")
self.EscortMenuSmokeRed=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release red smoke",self.EscortMenuSmoke,ESCORT._Smoke,self,SMOKECOLOR.Red,"Releasing red smoke!")
self.EscortMenuSmokeWhite=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release white smoke",self.EscortMenuSmoke,ESCORT._Smoke,self,SMOKECOLOR.White,"Releasing white smoke!")
self.EscortMenuSmokeOrange=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release orange smoke",self.EscortMenuSmoke,ESCORT._Smoke,self,SMOKECOLOR.Orange,"Releasing orange smoke!")
self.EscortMenuSmokeBlue=MENU_CLIENT_COMMAND:New(self.EscortClient,"Release blue smoke",self.EscortMenuSmoke,ESCORT._Smoke,self,SMOKECOLOR.Blue,"Releasing blue smoke!")
end
end
return self
end
function ESCORT:MenuReportTargets(Seconds)
self:F({Seconds})
if not self.EscortMenuReportNearbyTargets then
self.EscortMenuReportNearbyTargets=MENU_CLIENT:New(self.EscortClient,"Report targets",self.EscortMenu)
end
if not Seconds then
Seconds=30
end
self.EscortMenuReportNearbyTargetsNow=MENU_CLIENT_COMMAND:New(self.EscortClient,"Report targets now!",self.EscortMenuReportNearbyTargets,ESCORT._ReportNearbyTargetsNow,self)
self.EscortMenuReportNearbyTargetsOn=MENU_CLIENT_COMMAND:New(self.EscortClient,"Report targets on",self.EscortMenuReportNearbyTargets,ESCORT._SwitchReportNearbyTargets,self,true)
self.EscortMenuReportNearbyTargetsOff=MENU_CLIENT_COMMAND:New(self.EscortClient,"Report targets off",self.EscortMenuReportNearbyTargets,ESCORT._SwitchReportNearbyTargets,self,false)
self.EscortMenuAttackNearbyTargets=MENU_CLIENT:New(self.EscortClient,"Attack targets",self.EscortMenu)
self.ReportTargetsScheduler=SCHEDULER:New(self,self._ReportTargetsScheduler,{},1,Seconds)
return self
end
function ESCORT:MenuAssistedAttack()
self:F()
self.EscortMenuTargetAssistance=MENU_CLIENT:New(self.EscortClient,"Request assistance from",self.EscortMenu)
return self
end
function ESCORT:MenuROE(MenuTextFormat)
self:F(MenuTextFormat)
if not self.EscortMenuROE then
self.EscortMenuROE=MENU_CLIENT:New(self.EscortClient,"ROE",self.EscortMenu)
if self.EscortGroup:OptionROEHoldFirePossible()then
self.EscortMenuROEHoldFire=MENU_CLIENT_COMMAND:New(self.EscortClient,"Hold Fire",self.EscortMenuROE,ESCORT._ROE,self,self.EscortGroup:OptionROEHoldFire(),"Holding weapons!")
end
if self.EscortGroup:OptionROEReturnFirePossible()then
self.EscortMenuROEReturnFire=MENU_CLIENT_COMMAND:New(self.EscortClient,"Return Fire",self.EscortMenuROE,ESCORT._ROE,self,self.EscortGroup:OptionROEReturnFire(),"Returning fire!")
end
if self.EscortGroup:OptionROEOpenFirePossible()then
self.EscortMenuROEOpenFire=MENU_CLIENT_COMMAND:New(self.EscortClient,"Open Fire",self.EscortMenuROE,ESCORT._ROE,self,self.EscortGroup:OptionROEOpenFire(),"Opening fire on designated targets!!")
end
if self.EscortGroup:OptionROEWeaponFreePossible()then
self.EscortMenuROEWeaponFree=MENU_CLIENT_COMMAND:New(self.EscortClient,"Weapon Free",self.EscortMenuROE,ESCORT._ROE,self,self.EscortGroup:OptionROEWeaponFree(),"Opening fire on targets of opportunity!")
end
end
return self
end
function ESCORT:MenuEvasion(MenuTextFormat)
self:F(MenuTextFormat)
if self.EscortGroup:IsAir()then
if not self.EscortMenuEvasion then
self.EscortMenuEvasion=MENU_CLIENT:New(self.EscortClient,"Evasion",self.EscortMenu)
if self.EscortGroup:OptionROTNoReactionPossible()then
self.EscortMenuEvasionNoReaction=MENU_CLIENT_COMMAND:New(self.EscortClient,"Fight until death",self.EscortMenuEvasion,ESCORT._ROT,self,self.EscortGroup:OptionROTNoReaction(),"Fighting until death!")
end
if self.EscortGroup:OptionROTPassiveDefensePossible()then
self.EscortMenuEvasionPassiveDefense=MENU_CLIENT_COMMAND:New(self.EscortClient,"Use flares, chaff and jammers",self.EscortMenuEvasion,ESCORT._ROT,self,self.EscortGroup:OptionROTPassiveDefense(),"Defending using jammers, chaff and flares!")
end
if self.EscortGroup:OptionROTEvadeFirePossible()then
self.EscortMenuEvasionEvadeFire=MENU_CLIENT_COMMAND:New(self.EscortClient,"Evade enemy fire",self.EscortMenuEvasion,ESCORT._ROT,self,self.EscortGroup:OptionROTEvadeFire(),"Evading on enemy fire!")
end
if self.EscortGroup:OptionROTVerticalPossible()then
self.EscortMenuOptionEvasionVertical=MENU_CLIENT_COMMAND:New(self.EscortClient,"Go below radar and evade fire",self.EscortMenuEvasion,ESCORT._ROT,self,self.EscortGroup:OptionROTVertical(),"Evading on enemy fire with vertical manoeuvres!")
end
end
end
return self
end
function ESCORT:MenuResumeMission()
self:F()
if not self.EscortMenuResumeMission then
self.EscortMenuResumeMission=MENU_CLIENT:New(self.EscortClient,"Resume mission from",self.EscortMenu)
end
return self
end
function ESCORT:_HoldPosition(OrbitGroup,OrbitHeight,OrbitSeconds)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
local OrbitUnit=OrbitGroup:GetUnit(1)
self.FollowScheduler:Stop(self.FollowSchedule)
local PointFrom={}
local GroupVec3=EscortGroup:GetUnit(1):GetVec3()
PointFrom={}
PointFrom.x=GroupVec3.x
PointFrom.y=GroupVec3.z
PointFrom.speed=250
PointFrom.type=AI.Task.WaypointType.TURNING_POINT
PointFrom.alt=GroupVec3.y
PointFrom.alt_type=AI.Task.AltitudeType.BARO
local OrbitPoint=OrbitUnit:GetVec2()
local PointTo={}
PointTo.x=OrbitPoint.x
PointTo.y=OrbitPoint.y
PointTo.speed=250
PointTo.type=AI.Task.WaypointType.TURNING_POINT
PointTo.alt=OrbitHeight
PointTo.alt_type=AI.Task.AltitudeType.BARO
PointTo.task=EscortGroup:TaskOrbitCircleAtVec2(OrbitPoint,OrbitHeight,0)
local Points={PointFrom,PointTo}
EscortGroup:OptionROEHoldFire()
EscortGroup:OptionROTPassiveDefense()
EscortGroup:SetTask(EscortGroup:TaskRoute(Points))
EscortGroup:MessageToClient("Orbiting at location.",10,EscortClient)
end
function ESCORT:_JoinUpAndFollow(Distance)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
self.Distance=Distance
self:JoinUpAndFollow(EscortGroup,EscortClient,self.Distance)
end
function ESCORT:JoinUpAndFollow(EscortGroup,EscortClient,Distance)
self:F({EscortGroup,EscortClient,Distance})
self.FollowScheduler:Stop(self.FollowSchedule)
EscortGroup:OptionROEHoldFire()
EscortGroup:OptionROTPassiveDefense()
self.EscortMode=ESCORT.MODE.FOLLOW
self.CT1=0
self.GT1=0
self.FollowScheduler:Start(self.FollowSchedule)
EscortGroup:MessageToClient("Rejoining and Following at "..Distance.."!",30,EscortClient)
end
function ESCORT:_Flare(Color,Message)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
EscortGroup:GetUnit(1):Flare(Color)
EscortGroup:MessageToClient(Message,10,EscortClient)
end
function ESCORT:_Smoke(Color,Message)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
EscortGroup:GetUnit(1):Smoke(Color)
EscortGroup:MessageToClient(Message,10,EscortClient)
end
function ESCORT:_ReportNearbyTargetsNow()
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
self:_ReportTargetsScheduler()
end
function ESCORT:_SwitchReportNearbyTargets(ReportTargets)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
self.ReportTargets=ReportTargets
if self.ReportTargets then
if not self.ReportTargetsScheduler then
self.ReportTargetsScheduler:Schedule(self,self._ReportTargetsScheduler,{},1,30)
end
else
routines.removeFunction(self.ReportTargetsScheduler)
self.ReportTargetsScheduler=nil
end
end
function ESCORT:_ScanTargets(ScanDuration)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
self.FollowScheduler:Stop(self.FollowSchedule)
if EscortGroup:IsHelicopter()then
EscortGroup:PushTask(
EscortGroup:TaskControlled(
EscortGroup:TaskOrbitCircle(200,20),
EscortGroup:TaskCondition(nil,nil,nil,nil,ScanDuration,nil)
),1)
elseif EscortGroup:IsAirPlane()then
EscortGroup:PushTask(
EscortGroup:TaskControlled(
EscortGroup:TaskOrbitCircle(1000,500),
EscortGroup:TaskCondition(nil,nil,nil,nil,ScanDuration,nil)
),1)
end
EscortGroup:MessageToClient("Scanning targets for "..ScanDuration.." seconds.",ScanDuration,EscortClient)
if self.EscortMode==ESCORT.MODE.FOLLOW then
self.FollowScheduler:Start(self.FollowSchedule)
end
end
function _Resume(EscortGroup)
env.info('_Resume')
local Escort=EscortGroup:GetState(EscortGroup,"Escort")
env.info("EscortMode = "..Escort.EscortMode)
if Escort.EscortMode==ESCORT.MODE.FOLLOW then
Escort:JoinUpAndFollow(EscortGroup,Escort.EscortClient,Escort.Distance)
end
end
function ESCORT:_AttackTarget(DetectedItemID)
local EscortGroup=self.EscortGroup
self:E(EscortGroup)
local EscortClient=self.EscortClient
self.FollowScheduler:Stop(self.FollowSchedule)
if EscortGroup:IsAir()then
EscortGroup:OptionROEOpenFire()
EscortGroup:OptionROTPassiveDefense()
EscortGroup:SetState(EscortGroup,"Escort",self)
local DetectedSet=self.Detection:GetDetectedSet(DetectedItemID)
local Tasks={}
DetectedSet:ForEachUnit(
function(DetectedUnit,Tasks)
if DetectedUnit:IsAlive()then
Tasks[#Tasks+1]=EscortGroup:TaskAttackUnit(DetectedUnit)
end
end,Tasks
)
Tasks[#Tasks+1]=EscortGroup:TaskFunction("_Resume",{"''"})
EscortGroup:SetTask(
EscortGroup:TaskCombo(
Tasks
),1
)
else
local DetectedSet=self.Detection:GetDetectedSet(DetectedItemID)
local Tasks={}
DetectedSet:ForEachUnit(
function(DetectedUnit,Tasks)
if DetectedUnit:IsAlive()then
Tasks[#Tasks+1]=EscortGroup:TaskFireAtPoint(DetectedUnit:GetVec2(),50)
end
end,Tasks
)
EscortGroup:SetTask(
EscortGroup:TaskCombo(
Tasks
),1
)
end
EscortGroup:MessageToClient("Engaging Designated Unit!",10,EscortClient)
end
function ESCORT:_AssistTarget(EscortGroupAttack,DetectedItemID)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
self.FollowScheduler:Stop(self.FollowSchedule)
if EscortGroupAttack:IsAir()then
EscortGroupAttack:OptionROEOpenFire()
EscortGroupAttack:OptionROTVertical()
local DetectedSet=self.Detection:GetDetectedSet(DetectedItemID)
local Tasks={}
DetectedSet:ForEachUnit(
function(DetectedUnit,Tasks)
if DetectedUnit:IsAlive()then
Tasks[#Tasks+1]=EscortGroupAttack:TaskAttackUnit(DetectedUnit)
end
end,Tasks
)
Tasks[#Tasks+1]=EscortGroupAttack:TaskOrbitCircle(500,350)
EscortGroupAttack:SetTask(
EscortGroupAttack:TaskCombo(
Tasks
),1
)
else
local DetectedSet=self.Detection:GetDetectedSet(DetectedItemID)
local Tasks={}
DetectedSet:ForEachUnit(
function(DetectedUnit,Tasks)
if DetectedUnit:IsAlive()then
Tasks[#Tasks+1]=EscortGroupAttack:TaskFireAtPoint(DetectedUnit:GetVec2(),50)
end
end,Tasks
)
EscortGroupAttack:SetTask(
EscortGroupAttack:TaskCombo(
Tasks
),1
)
end
EscortGroupAttack:MessageToClient("Assisting with the destroying the enemy unit!",10,EscortClient)
end
function ESCORT:_ROE(EscortROEFunction,EscortROEMessage)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
pcall(function()EscortROEFunction()end)
EscortGroup:MessageToClient(EscortROEMessage,10,EscortClient)
end
function ESCORT:_ROT(EscortROTFunction,EscortROTMessage)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
pcall(function()EscortROTFunction()end)
EscortGroup:MessageToClient(EscortROTMessage,10,EscortClient)
end
function ESCORT:_ResumeMission(WayPoint)
local EscortGroup=self.EscortGroup
local EscortClient=self.EscortClient
self.FollowScheduler:Stop(self.FollowSchedule)
local WayPoints=EscortGroup:GetTaskRoute()
self:T(WayPoint,WayPoints)
for WayPointIgnore=1,WayPoint do
table.remove(WayPoints,1)
end
SCHEDULER:New(EscortGroup,EscortGroup.SetTask,{EscortGroup:TaskRoute(WayPoints)},1)
EscortGroup:MessageToClient("Resuming mission from waypoint "..WayPoint..".",10,EscortClient)
end
function ESCORT:RegisterRoute()
self:F()
local EscortGroup=self.EscortGroup
local TaskPoints=EscortGroup:GetTaskRoute()
self:T(TaskPoints)
return TaskPoints
end
function ESCORT:_FollowScheduler()
self:F({self.FollowDistance})
self:T({self.EscortClient.UnitName,self.EscortGroup.GroupName})
if self.EscortGroup:IsAlive()and self.EscortClient:IsAlive()then
local ClientUnit=self.EscortClient:GetClientGroupUnit()
local GroupUnit=self.EscortGroup:GetUnit(1)
local FollowDistance=self.FollowDistance
self:T({ClientUnit.UnitName,GroupUnit.UnitName})
if self.CT1==0 and self.GT1==0 then
self.CV1=ClientUnit:GetVec3()
self:T({"self.CV1",self.CV1})
self.CT1=timer.getTime()
self.GV1=GroupUnit:GetVec3()
self.GT1=timer.getTime()
else
local CT1=self.CT1
local CT2=timer.getTime()
local CV1=self.CV1
local CV2=ClientUnit:GetVec3()
self.CT1=CT2
self.CV1=CV2
local CD=((CV2.x-CV1.x)^2+(CV2.y-CV1.y)^2+(CV2.z-CV1.z)^2)^0.5
local CT=CT2-CT1
local CS=(3600/CT)*(CD/1000)
self:T2({"Client:",CS,CD,CT,CV2,CV1,CT2,CT1})
local GT1=self.GT1
local GT2=timer.getTime()
local GV1=self.GV1
local GV2=GroupUnit:GetVec3()
self.GT1=GT2
self.GV1=GV2
local GD=((GV2.x-GV1.x)^2+(GV2.y-GV1.y)^2+(GV2.z-GV1.z)^2)^0.5
local GT=GT2-GT1
local GS=(3600/GT)*(GD/1000)
self:T2({"Group:",GS,GD,GT,GV2,GV1,GT2,GT1})
local GV={x=GV2.x-CV2.x,y=GV2.y-CV2.y,z=GV2.z-CV2.z}
local GH2={x=GV2.x,y=CV2.y,z=GV2.z}
local alpha=math.atan2(GV.z,GV.x)
local CVI={x=CV2.x+FollowDistance*math.cos(alpha),
y=GH2.y,
z=CV2.z+FollowDistance*math.sin(alpha),
}
local DV={x=CV2.x-CVI.x,y=CV2.y-CVI.y,z=CV2.z-CVI.z}
local DVu={x=DV.x/FollowDistance,y=DV.y/FollowDistance,z=DV.z/FollowDistance}
local GDV={x=DVu.x*CS*8+CVI.x,y=CVI.y,z=DVu.z*CS*8+CVI.z}
if self.SmokeDirectionVector==true then
trigger.action.smoke(GDV,trigger.smokeColor.Red)
end
self:T2({"CV2:",CV2})
self:T2({"CVI:",CVI})
self:T2({"GDV:",GDV})
local CatchUpDistance=((GDV.x-GV2.x)^2+(GDV.y-GV2.y)^2+(GDV.z-GV2.z)^2)^0.5
local Time=10
local CatchUpSpeed=(CatchUpDistance-(CS*8.4))/Time
local Speed=CS+CatchUpSpeed
if Speed<0 then
Speed=0
end
self:T({"Client Speed, Escort Speed, Speed, FollowDistance, Time:",CS,GS,Speed,FollowDistance,Time})
self.EscortGroup:RouteToVec3(GDV,Speed/3.6)
end
return true
end
return false
end
function ESCORT:_ReportTargetsScheduler()
self:F(self.EscortGroup:GetName())
if self.EscortGroup:IsAlive()and self.EscortClient:IsAlive()then
if true then
local EscortGroupName=self.EscortGroup:GetName()
self.EscortMenuAttackNearbyTargets:RemoveSubMenus()
if self.EscortMenuTargetAssistance then
self.EscortMenuTargetAssistance:RemoveSubMenus()
end
local DetectedItems=self.Detection:GetDetectedItems()
self:E(DetectedItems)
local DetectedTargets=false
local DetectedMsgs={}
for ClientEscortGroupName,EscortGroupData in pairs(self.EscortClient._EscortGroups)do
local ClientEscortTargets=EscortGroupData.Detection
for DetectedItemID,DetectedItem in pairs(DetectedItems)do
self:E({DetectedItemID,DetectedItem})
local DetectedItemReportSummary=self.Detection:DetectedItemReportSummary(DetectedItemID,EscortGroupData.EscortGroup,_DATABASE:GetPlayerSettings(self.EscortClient:GetPlayerName()))
if ClientEscortGroupName==EscortGroupName then
local DetectedMsg=DetectedItemReportSummary:Text("\n")
DetectedMsgs[#DetectedMsgs+1]=DetectedMsg
self:T(DetectedMsg)
MENU_CLIENT_COMMAND:New(self.EscortClient,
DetectedMsg,
self.EscortMenuAttackNearbyTargets,
ESCORT._AttackTarget,
self,
DetectedItemID
)
else
if self.EscortMenuTargetAssistance then
local DetectedMsg=DetectedItemReportSummary:Text("\n")
self:T(DetectedMsg)
local MenuTargetAssistance=MENU_CLIENT:New(self.EscortClient,EscortGroupData.EscortName,self.EscortMenuTargetAssistance)
MENU_CLIENT_COMMAND:New(self.EscortClient,
DetectedMsg,
MenuTargetAssistance,
ESCORT._AssistTarget,
self,
EscortGroupData.EscortGroup,
DetectedItemID
)
end
end
DetectedTargets=true
end
end
self:E(DetectedMsgs)
if DetectedTargets then
self.EscortGroup:MessageToClient("Reporting detected targets:\n"..table.concat(DetectedMsgs,"\n"),20,self.EscortClient)
else
self.EscortGroup:MessageToClient("No targets detected.",10,self.EscortClient)
end
return true
else
end
end
return false
end
MISSILETRAINER={
ClassName="MISSILETRAINER",
TrackingMissiles={},
}
function MISSILETRAINER._Alive(Client,self)
if self.Briefing then
Client:Message(self.Briefing,15,"Trainer")
end
if self.MenusOnOff==true then
Client:Message("Use the 'Radio Menu' -> 'Other (F10)' -> 'Missile Trainer' menu options to change the Missile Trainer settings (for all players).",15,"Trainer")
Client.MainMenu=MENU_CLIENT:New(Client,"Missile Trainer",nil)
Client.MenuMessages=MENU_CLIENT:New(Client,"Messages",Client.MainMenu)
Client.MenuOn=MENU_CLIENT_COMMAND:New(Client,"Messages On",Client.MenuMessages,self._MenuMessages,{MenuSelf=self,MessagesOnOff=true})
Client.MenuOff=MENU_CLIENT_COMMAND:New(Client,"Messages Off",Client.MenuMessages,self._MenuMessages,{MenuSelf=self,MessagesOnOff=false})
Client.MenuTracking=MENU_CLIENT:New(Client,"Tracking",Client.MainMenu)
Client.MenuTrackingToAll=MENU_CLIENT_COMMAND:New(Client,"To All",Client.MenuTracking,self._MenuMessages,{MenuSelf=self,TrackingToAll=true})
Client.MenuTrackingToTarget=MENU_CLIENT_COMMAND:New(Client,"To Target",Client.MenuTracking,self._MenuMessages,{MenuSelf=self,TrackingToAll=false})
Client.MenuTrackOn=MENU_CLIENT_COMMAND:New(Client,"Tracking On",Client.MenuTracking,self._MenuMessages,{MenuSelf=self,TrackingOnOff=true})
Client.MenuTrackOff=MENU_CLIENT_COMMAND:New(Client,"Tracking Off",Client.MenuTracking,self._MenuMessages,{MenuSelf=self,TrackingOnOff=false})
Client.MenuTrackIncrease=MENU_CLIENT_COMMAND:New(Client,"Frequency Increase",Client.MenuTracking,self._MenuMessages,{MenuSelf=self,TrackingFrequency=-1})
Client.MenuTrackDecrease=MENU_CLIENT_COMMAND:New(Client,"Frequency Decrease",Client.MenuTracking,self._MenuMessages,{MenuSelf=self,TrackingFrequency=1})
Client.MenuAlerts=MENU_CLIENT:New(Client,"Alerts",Client.MainMenu)
Client.MenuAlertsToAll=MENU_CLIENT_COMMAND:New(Client,"To All",Client.MenuAlerts,self._MenuMessages,{MenuSelf=self,AlertsToAll=true})
Client.MenuAlertsToTarget=MENU_CLIENT_COMMAND:New(Client,"To Target",Client.MenuAlerts,self._MenuMessages,{MenuSelf=self,AlertsToAll=false})
Client.MenuHitsOn=MENU_CLIENT_COMMAND:New(Client,"Hits On",Client.MenuAlerts,self._MenuMessages,{MenuSelf=self,AlertsHitsOnOff=true})
Client.MenuHitsOff=MENU_CLIENT_COMMAND:New(Client,"Hits Off",Client.MenuAlerts,self._MenuMessages,{MenuSelf=self,AlertsHitsOnOff=false})
Client.MenuLaunchesOn=MENU_CLIENT_COMMAND:New(Client,"Launches On",Client.MenuAlerts,self._MenuMessages,{MenuSelf=self,AlertsLaunchesOnOff=true})
Client.MenuLaunchesOff=MENU_CLIENT_COMMAND:New(Client,"Launches Off",Client.MenuAlerts,self._MenuMessages,{MenuSelf=self,AlertsLaunchesOnOff=false})
Client.MenuDetails=MENU_CLIENT:New(Client,"Details",Client.MainMenu)
Client.MenuDetailsDistanceOn=MENU_CLIENT_COMMAND:New(Client,"Range On",Client.MenuDetails,self._MenuMessages,{MenuSelf=self,DetailsRangeOnOff=true})
Client.MenuDetailsDistanceOff=MENU_CLIENT_COMMAND:New(Client,"Range Off",Client.MenuDetails,self._MenuMessages,{MenuSelf=self,DetailsRangeOnOff=false})
Client.MenuDetailsBearingOn=MENU_CLIENT_COMMAND:New(Client,"Bearing On",Client.MenuDetails,self._MenuMessages,{MenuSelf=self,DetailsBearingOnOff=true})
Client.MenuDetailsBearingOff=MENU_CLIENT_COMMAND:New(Client,"Bearing Off",Client.MenuDetails,self._MenuMessages,{MenuSelf=self,DetailsBearingOnOff=false})
Client.MenuDistance=MENU_CLIENT:New(Client,"Set distance to plane",Client.MainMenu)
Client.MenuDistance50=MENU_CLIENT_COMMAND:New(Client,"50 meter",Client.MenuDistance,self._MenuMessages,{MenuSelf=self,Distance=50/1000})
Client.MenuDistance100=MENU_CLIENT_COMMAND:New(Client,"100 meter",Client.MenuDistance,self._MenuMessages,{MenuSelf=self,Distance=100/1000})
Client.MenuDistance150=MENU_CLIENT_COMMAND:New(Client,"150 meter",Client.MenuDistance,self._MenuMessages,{MenuSelf=self,Distance=150/1000})
Client.MenuDistance200=MENU_CLIENT_COMMAND:New(Client,"200 meter",Client.MenuDistance,self._MenuMessages,{MenuSelf=self,Distance=200/1000})
else
if Client.MainMenu then
Client.MainMenu:Remove()
end
end
local ClientID=Client:GetID()
self:T(ClientID)
if not self.TrackingMissiles[ClientID]then
self.TrackingMissiles[ClientID]={}
end
self.TrackingMissiles[ClientID].Client=Client
if not self.TrackingMissiles[ClientID].MissileData then
self.TrackingMissiles[ClientID].MissileData={}
end
end
function MISSILETRAINER:New(Distance,Briefing)
local self=BASE:Inherit(self,BASE:New())
self:F(Distance)
if Briefing then
self.Briefing=Briefing
end
self.Schedulers={}
self.SchedulerID=0
self.MessageInterval=2
self.MessageLastTime=timer.getTime()
self.Distance=Distance/1000
self:HandleEvent(EVENTS.Shot)
self.DBClients=SET_CLIENT:New():FilterStart()
self.DBClients:ForEachClient(
function(Client)
self:E("ForEach:"..Client.UnitName)
Client:Alive(self._Alive,self)
end
)
self.MessagesOnOff=true
self.TrackingToAll=false
self.TrackingOnOff=true
self.TrackingFrequency=3
self.AlertsToAll=true
self.AlertsHitsOnOff=true
self.AlertsLaunchesOnOff=true
self.DetailsRangeOnOff=true
self.DetailsBearingOnOff=true
self.MenusOnOff=true
self.TrackingMissiles={}
self.TrackingScheduler=SCHEDULER:New(self,self._TrackMissiles,{},0.5,0.05,0)
return self
end
function MISSILETRAINER:InitMessagesOnOff(MessagesOnOff)
self:F(MessagesOnOff)
self.MessagesOnOff=MessagesOnOff
if self.MessagesOnOff==true then
MESSAGE:New("Messages ON",15,"Menu"):ToAll()
else
MESSAGE:New("Messages OFF",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitTrackingToAll(TrackingToAll)
self:F(TrackingToAll)
self.TrackingToAll=TrackingToAll
if self.TrackingToAll==true then
MESSAGE:New("Missile tracking to all players ON",15,"Menu"):ToAll()
else
MESSAGE:New("Missile tracking to all players OFF",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitTrackingOnOff(TrackingOnOff)
self:F(TrackingOnOff)
self.TrackingOnOff=TrackingOnOff
if self.TrackingOnOff==true then
MESSAGE:New("Missile tracking ON",15,"Menu"):ToAll()
else
MESSAGE:New("Missile tracking OFF",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitTrackingFrequency(TrackingFrequency)
self:F(TrackingFrequency)
self.TrackingFrequency=self.TrackingFrequency+TrackingFrequency
if self.TrackingFrequency<0.5 then
self.TrackingFrequency=0.5
end
if self.TrackingFrequency then
MESSAGE:New("Missile tracking frequency is "..self.TrackingFrequency.." seconds.",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitAlertsToAll(AlertsToAll)
self:F(AlertsToAll)
self.AlertsToAll=AlertsToAll
if self.AlertsToAll==true then
MESSAGE:New("Alerts to all players ON",15,"Menu"):ToAll()
else
MESSAGE:New("Alerts to all players OFF",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitAlertsHitsOnOff(AlertsHitsOnOff)
self:F(AlertsHitsOnOff)
self.AlertsHitsOnOff=AlertsHitsOnOff
if self.AlertsHitsOnOff==true then
MESSAGE:New("Alerts Hits ON",15,"Menu"):ToAll()
else
MESSAGE:New("Alerts Hits OFF",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitAlertsLaunchesOnOff(AlertsLaunchesOnOff)
self:F(AlertsLaunchesOnOff)
self.AlertsLaunchesOnOff=AlertsLaunchesOnOff
if self.AlertsLaunchesOnOff==true then
MESSAGE:New("Alerts Launches ON",15,"Menu"):ToAll()
else
MESSAGE:New("Alerts Launches OFF",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitRangeOnOff(DetailsRangeOnOff)
self:F(DetailsRangeOnOff)
self.DetailsRangeOnOff=DetailsRangeOnOff
if self.DetailsRangeOnOff==true then
MESSAGE:New("Range display ON",15,"Menu"):ToAll()
else
MESSAGE:New("Range display OFF",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitBearingOnOff(DetailsBearingOnOff)
self:F(DetailsBearingOnOff)
self.DetailsBearingOnOff=DetailsBearingOnOff
if self.DetailsBearingOnOff==true then
MESSAGE:New("Bearing display OFF",15,"Menu"):ToAll()
else
MESSAGE:New("Bearing display OFF",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER:InitMenusOnOff(MenusOnOff)
self:F(MenusOnOff)
self.MenusOnOff=MenusOnOff
if self.MenusOnOff==true then
MESSAGE:New("Menus are ENABLED (only when a player rejoins a slot)",15,"Menu"):ToAll()
else
MESSAGE:New("Menus are DISABLED",15,"Menu"):ToAll()
end
return self
end
function MISSILETRAINER._MenuMessages(MenuParameters)
local self=MenuParameters.MenuSelf
if MenuParameters.MessagesOnOff~=nil then
self:InitMessagesOnOff(MenuParameters.MessagesOnOff)
end
if MenuParameters.TrackingToAll~=nil then
self:InitTrackingToAll(MenuParameters.TrackingToAll)
end
if MenuParameters.TrackingOnOff~=nil then
self:InitTrackingOnOff(MenuParameters.TrackingOnOff)
end
if MenuParameters.TrackingFrequency~=nil then
self:InitTrackingFrequency(MenuParameters.TrackingFrequency)
end
if MenuParameters.AlertsToAll~=nil then
self:InitAlertsToAll(MenuParameters.AlertsToAll)
end
if MenuParameters.AlertsHitsOnOff~=nil then
self:InitAlertsHitsOnOff(MenuParameters.AlertsHitsOnOff)
end
if MenuParameters.AlertsLaunchesOnOff~=nil then
self:InitAlertsLaunchesOnOff(MenuParameters.AlertsLaunchesOnOff)
end
if MenuParameters.DetailsRangeOnOff~=nil then
self:InitRangeOnOff(MenuParameters.DetailsRangeOnOff)
end
if MenuParameters.DetailsBearingOnOff~=nil then
self:InitBearingOnOff(MenuParameters.DetailsBearingOnOff)
end
if MenuParameters.Distance~=nil then
self.Distance=MenuParameters.Distance
MESSAGE:New("Hit detection distance set to "..(self.Distance*1000).." meters",15,"Menu"):ToAll()
end
end
function MISSILETRAINER:OnEventShot(EVentData)
self:F({EVentData})
local TrainerSourceDCSUnit=EVentData.IniDCSUnit
local TrainerSourceDCSUnitName=EVentData.IniDCSUnitName
local TrainerWeapon=EVentData.Weapon
local TrainerWeaponName=EVentData.WeaponName
self:T("Missile Launched = "..TrainerWeaponName)
local TrainerTargetDCSUnit=TrainerWeapon:getTarget()
if TrainerTargetDCSUnit then
local TrainerTargetDCSUnitName=Unit.getName(TrainerTargetDCSUnit)
local TrainerTargetSkill=_DATABASE.Templates.Units[TrainerTargetDCSUnitName].Template.skill
self:T(TrainerTargetDCSUnitName)
local Client=self.DBClients:FindClient(TrainerTargetDCSUnitName)
if Client then
local TrainerSourceUnit=UNIT:Find(TrainerSourceDCSUnit)
local TrainerTargetUnit=UNIT:Find(TrainerTargetDCSUnit)
if self.MessagesOnOff==true and self.AlertsLaunchesOnOff==true then
local Message=MESSAGE:New(
string.format("%s launched a %s",
TrainerSourceUnit:GetTypeName(),
TrainerWeaponName
)..self:_AddRange(Client,TrainerWeapon)..self:_AddBearing(Client,TrainerWeapon),5,"Launch Alert")
if self.AlertsToAll then
Message:ToAll()
else
Message:ToClient(Client)
end
end
local ClientID=Client:GetID()
self:T(ClientID)
local MissileData={}
MissileData.TrainerSourceUnit=TrainerSourceUnit
MissileData.TrainerWeapon=TrainerWeapon
MissileData.TrainerTargetUnit=TrainerTargetUnit
MissileData.TrainerWeaponTypeName=TrainerWeapon:getTypeName()
MissileData.TrainerWeaponLaunched=true
table.insert(self.TrackingMissiles[ClientID].MissileData,MissileData)
end
else
if(TrainerWeapon:getTypeName()=="9M311")then
SCHEDULER:New(TrainerWeapon,TrainerWeapon.destroy,{},1)
else
end
end
end
function MISSILETRAINER:_AddRange(Client,TrainerWeapon)
local RangeText=""
if self.DetailsRangeOnOff then
local PositionMissile=TrainerWeapon:getPoint()
local TargetVec3=Client:GetVec3()
local Range=((PositionMissile.x-TargetVec3.x)^2+
(PositionMissile.y-TargetVec3.y)^2+
(PositionMissile.z-TargetVec3.z)^2
)^0.5/1000
RangeText=string.format(", at %4.2fkm",Range)
end
return RangeText
end
function MISSILETRAINER:_AddBearing(Client,TrainerWeapon)
local BearingText=""
if self.DetailsBearingOnOff then
local PositionMissile=TrainerWeapon:getPoint()
local TargetVec3=Client:GetVec3()
self:T2({TargetVec3,PositionMissile})
local DirectionVector={x=PositionMissile.x-TargetVec3.x,y=PositionMissile.y-TargetVec3.y,z=PositionMissile.z-TargetVec3.z}
local DirectionRadians=math.atan2(DirectionVector.z,DirectionVector.x)
if DirectionRadians<0 then
DirectionRadians=DirectionRadians+2*math.pi
end
local DirectionDegrees=DirectionRadians*180/math.pi
BearingText=string.format(", %d degrees",DirectionDegrees)
end
return BearingText
end
function MISSILETRAINER:_TrackMissiles()
self:F2()
local ShowMessages=false
if self.MessagesOnOff and self.MessageLastTime+self.TrackingFrequency<=timer.getTime()then
self.MessageLastTime=timer.getTime()
ShowMessages=true
end
for ClientDataID,ClientData in pairs(self.TrackingMissiles)do
local Client=ClientData.Client
if Client and Client:IsAlive()then
for MissileDataID,MissileData in pairs(ClientData.MissileData)do
self:T3(MissileDataID)
local TrainerSourceUnit=MissileData.TrainerSourceUnit
local TrainerWeapon=MissileData.TrainerWeapon
local TrainerTargetUnit=MissileData.TrainerTargetUnit
local TrainerWeaponTypeName=MissileData.TrainerWeaponTypeName
local TrainerWeaponLaunched=MissileData.TrainerWeaponLaunched
if Client and Client:IsAlive()and TrainerSourceUnit and TrainerSourceUnit:IsAlive()and TrainerWeapon and TrainerWeapon:isExist()and TrainerTargetUnit and TrainerTargetUnit:IsAlive()then
local PositionMissile=TrainerWeapon:getPosition().p
local TargetVec3=Client:GetVec3()
local Distance=((PositionMissile.x-TargetVec3.x)^2+
(PositionMissile.y-TargetVec3.y)^2+
(PositionMissile.z-TargetVec3.z)^2
)^0.5/1000
if Distance<=self.Distance then
TrainerWeapon:destroy()
if self.MessagesOnOff==true and self.AlertsHitsOnOff==true then
self:T("killed")
local Message=MESSAGE:New(
string.format("%s launched by %s killed %s",
TrainerWeapon:getTypeName(),
TrainerSourceUnit:GetTypeName(),
TrainerTargetUnit:GetPlayerName()
),15,"Hit Alert")
if self.AlertsToAll==true then
Message:ToAll()
else
Message:ToClient(Client)
end
MissileData=nil
table.remove(ClientData.MissileData,MissileDataID)
self:T(ClientData.MissileData)
end
end
else
if not(TrainerWeapon and TrainerWeapon:isExist())then
if self.MessagesOnOff==true and self.AlertsLaunchesOnOff==true then
local Message=MESSAGE:New(
string.format("%s launched by %s self destructed!",
TrainerWeaponTypeName,
TrainerSourceUnit:GetTypeName()
),5,"Tracking")
if self.AlertsToAll==true then
Message:ToAll()
else
Message:ToClient(Client)
end
end
MissileData=nil
table.remove(ClientData.MissileData,MissileDataID)
self:T(ClientData.MissileData)
end
end
end
else
self.TrackingMissiles[ClientDataID]=nil
end
end
if ShowMessages==true and self.MessagesOnOff==true and self.TrackingOnOff==true then
for ClientDataID,ClientData in pairs(self.TrackingMissiles)do
local Client=ClientData.Client
ClientData.MessageToClient=""
ClientData.MessageToAll=""
for TrackingDataID,TrackingData in pairs(self.TrackingMissiles)do
for MissileDataID,MissileData in pairs(TrackingData.MissileData)do
local TrainerSourceUnit=MissileData.TrainerSourceUnit
local TrainerWeapon=MissileData.TrainerWeapon
local TrainerTargetUnit=MissileData.TrainerTargetUnit
local TrainerWeaponTypeName=MissileData.TrainerWeaponTypeName
local TrainerWeaponLaunched=MissileData.TrainerWeaponLaunched
if Client and Client:IsAlive()and TrainerSourceUnit and TrainerSourceUnit:IsAlive()and TrainerWeapon and TrainerWeapon:isExist()and TrainerTargetUnit and TrainerTargetUnit:IsAlive()then
if ShowMessages==true then
local TrackingTo
TrackingTo=string.format("  -> %s",
TrainerWeaponTypeName
)
if ClientDataID==TrackingDataID then
if ClientData.MessageToClient==""then
ClientData.MessageToClient="Missiles to You:\n"
end
ClientData.MessageToClient=ClientData.MessageToClient..TrackingTo..self:_AddRange(ClientData.Client,TrainerWeapon)..self:_AddBearing(ClientData.Client,TrainerWeapon).."\n"
else
if self.TrackingToAll==true then
if ClientData.MessageToAll==""then
ClientData.MessageToAll="Missiles to other Players:\n"
end
ClientData.MessageToAll=ClientData.MessageToAll..TrackingTo..self:_AddRange(ClientData.Client,TrainerWeapon)..self:_AddBearing(ClientData.Client,TrainerWeapon).." ( "..TrainerTargetUnit:GetPlayerName().." )\n"
end
end
end
end
end
end
if ClientData.MessageToClient~=""or ClientData.MessageToAll~=""then
local Message=MESSAGE:New(ClientData.MessageToClient..ClientData.MessageToAll,1,"Tracking"):ToClient(Client)
end
end
end
return true
end
AIRBASEPOLICE_BASE={
ClassName="AIRBASEPOLICE_BASE",
SetClient=nil,
Airbases=nil,
AirbaseNames=nil,
}
function AIRBASEPOLICE_BASE:New(SetClient,Airbases)
local self=BASE:Inherit(self,BASE:New())
self:E({self.ClassName,SetClient,Airbases})
self.SetClient=SetClient
self.Airbases=Airbases
for AirbaseID,Airbase in pairs(self.Airbases)do
Airbase.ZoneBoundary=ZONE_POLYGON_BASE:New("Boundary",Airbase.PointsBoundary):SmokeZone(SMOKECOLOR.White):Flush()
for PointsRunwayID,PointsRunway in pairs(Airbase.PointsRunways)do
Airbase.ZoneRunways[PointsRunwayID]=ZONE_POLYGON_BASE:New("Runway "..PointsRunwayID,PointsRunway):SmokeZone(SMOKECOLOR.Red):Flush()
end
end
self.SetClient:ForEachClient(
function(Client)
Client:SetState(self,"Speeding",false)
Client:SetState(self,"Warnings",0)
Client:SetState(self,"Taxi",false)
end
)
self.AirbaseMonitor=SCHEDULER:New(self,self._AirbaseMonitor,{},0,2,0.05)
return self
end
function AIRBASEPOLICE_BASE:Monitor(AirbaseNames)
if AirbaseNames then
if type(AirbaseNames)=="table"then
self.AirbaseNames=AirbaseNames
else
self.AirbaseNames={AirbaseNames}
end
end
end
function AIRBASEPOLICE_BASE:_AirbaseMonitor()
for AirbaseID,Airbase in pairs(self.Airbases)do
if not self.AirbaseNames or self.AirbaseNames[AirbaseID]then
self:E(AirbaseID)
self.SetClient:ForEachClientInZone(Airbase.ZoneBoundary,
function(Client)
self:E(Client.UnitName)
if Client:IsAlive()then
local NotInRunwayZone=true
for ZoneRunwayID,ZoneRunway in pairs(Airbase.ZoneRunways)do
NotInRunwayZone=(Client:IsNotInZone(ZoneRunway)==true)and NotInRunwayZone or false
end
if NotInRunwayZone then
local Taxi=self:GetState(self,"Taxi")
self:E(Taxi)
if Taxi==false then
Client:Message("Welcome at "..AirbaseID..". The maximum taxiing speed is "..Airbase.MaximumSpeed" km/h.",20,"ATC")
self:SetState(self,"Taxi",true)
end
local VelocityVec3=Client:GetVelocity()
local Velocity=(VelocityVec3.x^2+VelocityVec3.y^2+VelocityVec3.z^2)^0.5
local Velocity=Velocity*3.6
local IsAboveRunway=Client:IsAboveRunway()
local IsOnGround=Client:InAir()==false
self:T(IsAboveRunway,IsOnGround)
if IsAboveRunway and IsOnGround then
if Velocity>Airbase.MaximumSpeed then
local IsSpeeding=Client:GetState(self,"Speeding")
if IsSpeeding==true then
local SpeedingWarnings=Client:GetState(self,"Warnings")
self:T(SpeedingWarnings)
if SpeedingWarnings<=3 then
Client:Message("You are speeding on the taxiway! Slow down or you will be removed from this airbase! Your current velocity is "..string.format("%2.0f km/h",Velocity),5,"Warning "..SpeedingWarnings.." / 3")
Client:SetState(self,"Warnings",SpeedingWarnings+1)
else
MESSAGE:New("Player "..Client:GetPlayerName().." is being damaged at the airbase, due to a speeding violation ...",10,"Airbase Police"):ToAll()
local function DestroyUntilHeavilyDamaged(Client)
local ClientCoord=Client:GetCoordinate()
ClientCoord:Explosion(100)
local Damage=Client:GetLife()
local InitialLife=Client:GetLife0()
MESSAGE:New("Player "..Client:GetPlayerName().." Damage ... "..Damage,5,"Airbase Police"):ToAll()
if(Damage/InitialLife)*100<80 then
Client:ScheduleStop(DestroyUntilHeavilyDamaged)
end
end
Client:ScheduleOnce(1,DestroyUntilHeavilyDamaged,Client)
trigger.action.setUserFlag("AIRCRAFT_"..Client:GetID(),100)
Client:SetState(self,"Speeding",false)
Client:SetState(self,"Warnings",0)
end
else
Client:Message("You are speeding on the taxiway, slow down now! Your current velocity is "..string.format("%2.0f km/h",Velocity),5,"Attention! ")
Client:SetState(self,"Speeding",true)
Client:SetState(self,"Warnings",1)
end
else
Client:SetState(self,"Speeding",false)
Client:SetState(self,"Warnings",0)
end
end
else
Client:SetState(self,"Speeding",false)
Client:SetState(self,"Warnings",0)
local Taxi=self:GetState(self,"Taxi")
if Taxi==true then
Client:Message("You have progressed to the runway ... Await take-off clearance ...",20,"ATC")
self:SetState(self,"Taxi",false)
end
end
end
end
)
end
end
return true
end
AIRBASEPOLICE_CAUCASUS={
ClassName="AIRBASEPOLICE_CAUCASUS",
Airbases={
AnapaVityazevo={
PointsBoundary={
[1]={["y"]=242234.85714287,["x"]=-6616.5714285726,},
[2]={["y"]=241060.57142858,["x"]=-5585.142857144,},
[3]={["y"]=243806.2857143,["x"]=-3962.2857142868,},
[4]={["y"]=245240.57142858,["x"]=-4816.5714285726,},
[5]={["y"]=244783.42857144,["x"]=-5630.8571428583,},
[6]={["y"]=243800.57142858,["x"]=-5065.142857144,},
[7]={["y"]=242232.00000001,["x"]=-6622.2857142868,},
},
PointsRunways={
[1]={
[1]={["y"]=242140.57142858,["x"]=-6478.8571428583,},
[2]={["y"]=242188.57142858,["x"]=-6522.0000000011,},
[3]={["y"]=244124.2857143,["x"]=-4344.0000000011,},
[4]={["y"]=244068.2857143,["x"]=-4296.5714285726,},
[5]={["y"]=242140.57142858,["x"]=-6480.0000000011,}
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Batumi={
PointsBoundary={
[1]={["y"]=617567.14285714,["x"]=-355313.14285715,},
[2]={["y"]=616181.42857142,["x"]=-354800.28571429,},
[3]={["y"]=616007.14285714,["x"]=-355128.85714286,},
[4]={["y"]=618230,["x"]=-356914.57142858,},
[5]={["y"]=618727.14285714,["x"]=-356166,},
[6]={["y"]=617572.85714285,["x"]=-355308.85714286,},
},
PointsRunways={
[1]={
[1]={["y"]=616442.28571429,["x"]=-355090.28571429,},
[2]={["y"]=618450.57142857,["x"]=-356522,},
[3]={["y"]=618407.71428571,["x"]=-356584.85714286,},
[4]={["y"]=618361.99999999,["x"]=-356554.85714286,},
[5]={["y"]=618324.85714285,["x"]=-356599.14285715,},
[6]={["y"]=618250.57142856,["x"]=-356543.42857143,},
[7]={["y"]=618257.7142857,["x"]=-356496.28571429,},
[8]={["y"]=618237.7142857,["x"]=-356459.14285715,},
[9]={["y"]=616555.71428571,["x"]=-355258.85714286,},
[10]={["y"]=616486.28571428,["x"]=-355280.57142858,},
[11]={["y"]=616410.57142856,["x"]=-355227.71428572,},
[12]={["y"]=616441.99999999,["x"]=-355179.14285715,},
[13]={["y"]=616401.99999999,["x"]=-355147.71428572,},
[14]={["y"]=616441.42857142,["x"]=-355092.57142858,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Beslan={
PointsBoundary={
[1]={["y"]=842082.57142857,["x"]=-148445.14285715,},
[2]={["y"]=845237.71428572,["x"]=-148639.71428572,},
[3]={["y"]=845232,["x"]=-148765.42857143,},
[4]={["y"]=844220.57142857,["x"]=-149168.28571429,},
[5]={["y"]=843274.85714286,["x"]=-149125.42857143,},
[6]={["y"]=842077.71428572,["x"]=-148554,},
[7]={["y"]=842083.42857143,["x"]=-148445.42857143,},
},
PointsRunways={
[1]={
[1]={["y"]=842104.57142857,["x"]=-148460.57142857,},
[2]={["y"]=845225.71428572,["x"]=-148656,},
[3]={["y"]=845220.57142858,["x"]=-148750,},
[4]={["y"]=842098.85714286,["x"]=-148556.28571429,},
[5]={["y"]=842104,["x"]=-148460.28571429,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Gelendzhik={
PointsBoundary={
[1]={["y"]=297856.00000001,["x"]=-51151.428571429,},
[2]={["y"]=299044.57142858,["x"]=-49720.000000001,},
[3]={["y"]=298861.71428572,["x"]=-49580.000000001,},
[4]={["y"]=298198.85714286,["x"]=-49842.857142858,},
[5]={["y"]=297990.28571429,["x"]=-50151.428571429,},
[6]={["y"]=297696.00000001,["x"]=-51054.285714286,},
[7]={["y"]=297850.28571429,["x"]=-51160.000000001,},
},
PointsRunways={
[1]={
[1]={["y"]=297834.00000001,["x"]=-51107.428571429,},
[2]={["y"]=297786.57142858,["x"]=-51068.857142858,},
[3]={["y"]=298946.57142858,["x"]=-49686.000000001,},
[4]={["y"]=298993.14285715,["x"]=-49725.714285715,},
[5]={["y"]=297835.14285715,["x"]=-51107.714285715,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Gudauta={
PointsBoundary={
[1]={["y"]=517246.57142857,["x"]=-197850.28571429,},
[2]={["y"]=516749.42857142,["x"]=-198070.28571429,},
[3]={["y"]=515755.14285714,["x"]=-197598.85714286,},
[4]={["y"]=515369.42857142,["x"]=-196538.85714286,},
[5]={["y"]=515623.71428571,["x"]=-195618.85714286,},
[6]={["y"]=515946.57142857,["x"]=-195510.28571429,},
[7]={["y"]=517243.71428571,["x"]=-197858.85714286,},
},
PointsRunways={
[1]={
[1]={["y"]=517096.57142857,["x"]=-197804.57142857,},
[2]={["y"]=515880.85714285,["x"]=-195590.28571429,},
[3]={["y"]=515812.28571428,["x"]=-195628.85714286,},
[4]={["y"]=517036.57142857,["x"]=-197834.57142857,},
[5]={["y"]=517097.99999999,["x"]=-197807.42857143,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Kobuleti={
PointsBoundary={
[1]={["y"]=634427.71428571,["x"]=-318290.28571429,},
[2]={["y"]=635033.42857143,["x"]=-317550.2857143,},
[3]={["y"]=635864.85714286,["x"]=-317333.14285715,},
[4]={["y"]=636967.71428571,["x"]=-317261.71428572,},
[5]={["y"]=637144.85714286,["x"]=-317913.14285715,},
[6]={["y"]=634630.57142857,["x"]=-318687.42857144,},
[7]={["y"]=634424.85714286,["x"]=-318290.2857143,},
},
PointsRunways={
[1]={
[1]={["y"]=634509.71428571,["x"]=-318339.42857144,},
[2]={["y"]=636767.42857143,["x"]=-317516.57142858,},
[3]={["y"]=636790,["x"]=-317575.71428572,},
[4]={["y"]=634531.42857143,["x"]=-318398.00000001,},
[5]={["y"]=634510.28571429,["x"]=-318339.71428572,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
KrasnodarCenter={
PointsBoundary={
[1]={["y"]=366680.28571429,["x"]=11699.142857142,},
[2]={["y"]=366654.28571429,["x"]=11225.142857142,},
[3]={["y"]=367497.14285715,["x"]=11082.285714285,},
[4]={["y"]=368025.71428572,["x"]=10396.57142857,},
[5]={["y"]=369854.28571429,["x"]=11367.999999999,},
[6]={["y"]=369840.00000001,["x"]=11910.857142856,},
[7]={["y"]=366682.57142858,["x"]=11697.999999999,},
},
PointsRunways={
[1]={
[1]={["y"]=369205.42857144,["x"]=11789.142857142,},
[2]={["y"]=369209.71428572,["x"]=11714.857142856,},
[3]={["y"]=366699.71428572,["x"]=11581.714285713,},
[4]={["y"]=366698.28571429,["x"]=11659.142857142,},
[5]={["y"]=369208.85714286,["x"]=11788.57142857,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
KrasnodarPashkovsky={
PointsBoundary={
[1]={["y"]=386754,["x"]=6476.5714285703,},
[2]={["y"]=389182.57142858,["x"]=8722.2857142846,},
[3]={["y"]=388832.57142858,["x"]=9086.5714285703,},
[4]={["y"]=386961.14285715,["x"]=7707.9999999989,},
[5]={["y"]=385404,["x"]=9179.4285714274,},
[6]={["y"]=383239.71428572,["x"]=7386.5714285703,},
[7]={["y"]=383954,["x"]=6486.5714285703,},
[8]={["y"]=385775.42857143,["x"]=8097.9999999989,},
[9]={["y"]=386804,["x"]=7319.4285714274,},
[10]={["y"]=386375.42857143,["x"]=6797.9999999989,},
[11]={["y"]=386746.85714286,["x"]=6472.2857142846,},
},
PointsRunways={
[1]={
[1]={["y"]=385891.14285715,["x"]=8416.5714285703,},
[2]={["y"]=385842.28571429,["x"]=8467.9999999989,},
[3]={["y"]=384180.85714286,["x"]=6917.1428571417,},
[4]={["y"]=384228.57142858,["x"]=6867.7142857132,},
[5]={["y"]=385891.14285715,["x"]=8416.5714285703,},
},
[2]={
[1]={["y"]=386714.85714286,["x"]=6674.857142856,},
[2]={["y"]=386757.71428572,["x"]=6627.7142857132,},
[3]={["y"]=389028.57142858,["x"]=8741.4285714275,},
[4]={["y"]=388981.71428572,["x"]=8790.5714285703,},
[5]={["y"]=386714.57142858,["x"]=6674.5714285703,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Krymsk={
PointsBoundary={
[1]={["y"]=293338.00000001,["x"]=-7575.4285714297,},
[2]={["y"]=295199.42857144,["x"]=-5434.0000000011,},
[3]={["y"]=295595.14285715,["x"]=-6239.7142857154,},
[4]={["y"]=294152.2857143,["x"]=-8325.4285714297,},
[5]={["y"]=293345.14285715,["x"]=-7596.8571428582,},
},
PointsRunways={
[1]={
[1]={["y"]=293522.00000001,["x"]=-7567.4285714297,},
[2]={["y"]=293578.57142858,["x"]=-7616.0000000011,},
[3]={["y"]=295246.00000001,["x"]=-5591.142857144,},
[4]={["y"]=295187.71428573,["x"]=-5546.0000000011,},
[5]={["y"]=293523.14285715,["x"]=-7568.2857142868,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Kutaisi={
PointsBoundary={
[1]={["y"]=682087.42857143,["x"]=-284512.85714286,},
[2]={["y"]=685387.42857143,["x"]=-283662.85714286,},
[3]={["y"]=685294.57142857,["x"]=-284977.14285715,},
[4]={["y"]=682744.57142857,["x"]=-286505.71428572,},
[5]={["y"]=682094.57142857,["x"]=-284527.14285715,},
},
PointsRunways={
[1]={
[1]={["y"]=682638,["x"]=-285202.28571429,},
[2]={["y"]=685050.28571429,["x"]=-284507.42857144,},
[3]={["y"]=685068.85714286,["x"]=-284578.85714286,},
[4]={["y"]=682657.42857143,["x"]=-285264.28571429,},
[5]={["y"]=682638.28571429,["x"]=-285202.85714286,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
MaykopKhanskaya={
PointsBoundary={
[1]={["y"]=456876.28571429,["x"]=-27665.42857143,},
[2]={["y"]=457800,["x"]=-28392.857142858,},
[3]={["y"]=459368.57142857,["x"]=-26378.571428573,},
[4]={["y"]=459425.71428572,["x"]=-25242.857142858,},
[5]={["y"]=458961.42857143,["x"]=-24964.285714287,},
[6]={["y"]=456878.57142857,["x"]=-27667.714285715,},
},
PointsRunways={
[1]={
[1]={["y"]=457005.42857143,["x"]=-27668.000000001,},
[2]={["y"]=459028.85714286,["x"]=-25168.857142858,},
[3]={["y"]=459082.57142857,["x"]=-25216.857142858,},
[4]={["y"]=457060,["x"]=-27714.285714287,},
[5]={["y"]=457004.57142857,["x"]=-27669.714285715,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
MineralnyeVody={
PointsBoundary={
[1]={["y"]=703857.14285714,["x"]=-50226.000000002,},
[2]={["y"]=707385.71428571,["x"]=-51911.714285716,},
[3]={["y"]=707595.71428571,["x"]=-51434.857142859,},
[4]={["y"]=707900,["x"]=-51568.857142859,},
[5]={["y"]=707542.85714286,["x"]=-52326.000000002,},
[6]={["y"]=706628.57142857,["x"]=-52568.857142859,},
[7]={["y"]=705142.85714286,["x"]=-51790.285714288,},
[8]={["y"]=703678.57142857,["x"]=-50611.714285716,},
[9]={["y"]=703857.42857143,["x"]=-50226.857142859,},
},
PointsRunways={
[1]={
[1]={["y"]=703904,["x"]=-50352.571428573,},
[2]={["y"]=707596.28571429,["x"]=-52094.571428573,},
[3]={["y"]=707560.57142858,["x"]=-52161.714285716,},
[4]={["y"]=703871.71428572,["x"]=-50420.571428573,},
[5]={["y"]=703902,["x"]=-50352.000000002,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Mozdok={
PointsBoundary={
[1]={["y"]=832123.42857143,["x"]=-83608.571428573,},
[2]={["y"]=835916.28571429,["x"]=-83144.285714288,},
[3]={["y"]=835474.28571429,["x"]=-84170.571428573,},
[4]={["y"]=832911.42857143,["x"]=-84470.571428573,},
[5]={["y"]=832487.71428572,["x"]=-85565.714285716,},
[6]={["y"]=831573.42857143,["x"]=-85351.42857143,},
[7]={["y"]=832123.71428572,["x"]=-83610.285714288,},
},
PointsRunways={
[1]={
[1]={["y"]=832201.14285715,["x"]=-83699.428571431,},
[2]={["y"]=832212.57142857,["x"]=-83780.571428574,},
[3]={["y"]=835730.28571429,["x"]=-83335.714285717,},
[4]={["y"]=835718.85714286,["x"]=-83246.571428574,},
[5]={["y"]=832200.57142857,["x"]=-83700.000000002,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Nalchik={
PointsBoundary={
[1]={["y"]=759370,["x"]=-125502.85714286,},
[2]={["y"]=761384.28571429,["x"]=-124177.14285714,},
[3]={["y"]=761472.85714286,["x"]=-124325.71428572,},
[4]={["y"]=761092.85714286,["x"]=-125048.57142857,},
[5]={["y"]=760295.71428572,["x"]=-125685.71428572,},
[6]={["y"]=759444.28571429,["x"]=-125734.28571429,},
[7]={["y"]=759375.71428572,["x"]=-125511.42857143,},
},
PointsRunways={
[1]={
[1]={["y"]=759454.28571429,["x"]=-125551.42857143,},
[2]={["y"]=759492.85714286,["x"]=-125610.85714286,},
[3]={["y"]=761406.28571429,["x"]=-124304.28571429,},
[4]={["y"]=761361.14285714,["x"]=-124239.71428572,},
[5]={["y"]=759456,["x"]=-125552.57142857,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Novorossiysk={
PointsBoundary={
[1]={["y"]=278677.71428573,["x"]=-41656.571428572,},
[2]={["y"]=278446.2857143,["x"]=-41453.714285715,},
[3]={["y"]=278989.14285716,["x"]=-40188.000000001,},
[4]={["y"]=279717.71428573,["x"]=-39968.000000001,},
[5]={["y"]=280020.57142859,["x"]=-40208.000000001,},
[6]={["y"]=278674.85714287,["x"]=-41660.857142858,},
},
PointsRunways={
[1]={
[1]={["y"]=278673.14285716,["x"]=-41615.142857144,},
[2]={["y"]=278625.42857144,["x"]=-41570.571428572,},
[3]={["y"]=279835.42857144,["x"]=-40226.000000001,},
[4]={["y"]=279882.2857143,["x"]=-40270.000000001,},
[5]={["y"]=278672.00000001,["x"]=-41614.857142858,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
SenakiKolkhi={
PointsBoundary={
[1]={["y"]=646036.57142857,["x"]=-281778.85714286,},
[2]={["y"]=646045.14285714,["x"]=-281191.71428571,},
[3]={["y"]=647032.28571429,["x"]=-280598.85714285,},
[4]={["y"]=647669.42857143,["x"]=-281273.14285714,},
[5]={["y"]=648323.71428571,["x"]=-281370.28571428,},
[6]={["y"]=648520.85714286,["x"]=-281978.85714285,},
[7]={["y"]=646039.42857143,["x"]=-281783.14285714,},
},
PointsRunways={
[1]={
[1]={["y"]=646060.85714285,["x"]=-281736,},
[2]={["y"]=646056.57142857,["x"]=-281631.71428571,},
[3]={["y"]=648442.28571428,["x"]=-281840.28571428,},
[4]={["y"]=648432.28571428,["x"]=-281918.85714286,},
[5]={["y"]=646063.71428571,["x"]=-281738.85714286,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
SochiAdler={
PointsBoundary={
[1]={["y"]=460642.28571428,["x"]=-164861.71428571,},
[2]={["y"]=462820.85714285,["x"]=-163368.85714286,},
[3]={["y"]=463649.42857142,["x"]=-163340.28571429,},
[4]={["y"]=463835.14285714,["x"]=-164040.28571429,},
[5]={["y"]=462535.14285714,["x"]=-165654.57142857,},
[6]={["y"]=460678,["x"]=-165247.42857143,},
[7]={["y"]=460635.14285714,["x"]=-164876,},
},
PointsRunways={
[1]={
[1]={["y"]=460831.42857143,["x"]=-165180,},
[2]={["y"]=460878.57142857,["x"]=-165257.14285714,},
[3]={["y"]=463663.71428571,["x"]=-163793.14285714,},
[4]={["y"]=463612.28571428,["x"]=-163697.42857143,},
[5]={["y"]=460831.42857143,["x"]=-165177.14285714,},
},
[2]={
[1]={["y"]=460831.42857143,["x"]=-165180,},
[2]={["y"]=460878.57142857,["x"]=-165257.14285714,},
[3]={["y"]=463663.71428571,["x"]=-163793.14285714,},
[4]={["y"]=463612.28571428,["x"]=-163697.42857143,},
[5]={["y"]=460831.42857143,["x"]=-165177.14285714,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Soganlug={
PointsBoundary={
[1]={["y"]=894530.85714286,["x"]=-316928.28571428,},
[2]={["y"]=896422.28571428,["x"]=-318622.57142857,},
[3]={["y"]=896090.85714286,["x"]=-318934,},
[4]={["y"]=894019.42857143,["x"]=-317119.71428571,},
[5]={["y"]=894533.71428571,["x"]=-316925.42857143,},
},
PointsRunways={
[1]={
[1]={["y"]=894525.71428571,["x"]=-316964,},
[2]={["y"]=896363.14285714,["x"]=-318634.28571428,},
[3]={["y"]=896299.14285714,["x"]=-318702.85714286,},
[4]={["y"]=894464,["x"]=-317031.71428571,},
[5]={["y"]=894524.57142857,["x"]=-316963.71428571,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
SukhumiBabushara={
PointsBoundary={
[1]={["y"]=562541.14285714,["x"]=-219852.28571429,},
[2]={["y"]=562691.14285714,["x"]=-219395.14285714,},
[3]={["y"]=564326.85714286,["x"]=-219523.71428571,},
[4]={["y"]=566262.57142857,["x"]=-221166.57142857,},
[5]={["y"]=566069.71428571,["x"]=-221580.85714286,},
[6]={["y"]=562534,["x"]=-219873.71428571,},
},
PointsRunways={
[1]={
[1]={["y"]=562684,["x"]=-219779.71428571,},
[2]={["y"]=562717.71428571,["x"]=-219718,},
[3]={["y"]=566046.85714286,["x"]=-221376.57142857,},
[4]={["y"]=566012.28571428,["x"]=-221446.57142857,},
[5]={["y"]=562684.57142857,["x"]=-219782.57142857,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
TbilisiLochini={
PointsBoundary={
[1]={["y"]=895172.85714286,["x"]=-314667.42857143,},
[2]={["y"]=895337.42857143,["x"]=-314143.14285714,},
[3]={["y"]=895990.28571429,["x"]=-314036,},
[4]={["y"]=897730.28571429,["x"]=-315284.57142857,},
[5]={["y"]=897901.71428571,["x"]=-316284.57142857,},
[6]={["y"]=897684.57142857,["x"]=-316618.85714286,},
[7]={["y"]=895173.14285714,["x"]=-314667.42857143,},
},
PointsRunways={
[1]={
[1]={["y"]=895261.14285715,["x"]=-314652.28571428,},
[2]={["y"]=897654.57142857,["x"]=-316523.14285714,},
[3]={["y"]=897711.71428571,["x"]=-316450.28571429,},
[4]={["y"]=895327.42857143,["x"]=-314568.85714286,},
[5]={["y"]=895261.71428572,["x"]=-314656,},
},
[2]={
[1]={["y"]=895605.71428572,["x"]=-314724.57142857,},
[2]={["y"]=897639.71428572,["x"]=-316148,},
[3]={["y"]=897683.42857143,["x"]=-316087.14285714,},
[4]={["y"]=895650,["x"]=-314660,},
[5]={["y"]=895606,["x"]=-314724.85714286,}
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Vaziani={
PointsBoundary={
[1]={["y"]=902122,["x"]=-318163.71428572,},
[2]={["y"]=902678.57142857,["x"]=-317594,},
[3]={["y"]=903275.71428571,["x"]=-317405.42857143,},
[4]={["y"]=903418.57142857,["x"]=-317891.14285714,},
[5]={["y"]=904292.85714286,["x"]=-318748.28571429,},
[6]={["y"]=904542,["x"]=-319740.85714286,},
[7]={["y"]=904042,["x"]=-320166.57142857,},
[8]={["y"]=902121.42857143,["x"]=-318164.85714286,},
},
PointsRunways={
[1]={
[1]={["y"]=902239.14285714,["x"]=-318190.85714286,},
[2]={["y"]=904014.28571428,["x"]=-319994.57142857,},
[3]={["y"]=904064.85714285,["x"]=-319945.14285715,},
[4]={["y"]=902294.57142857,["x"]=-318146,},
[5]={["y"]=902247.71428571,["x"]=-318190.85714286,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
},
}
function AIRBASEPOLICE_CAUCASUS:New(SetClient)
local self=BASE:Inherit(self,AIRBASEPOLICE_BASE:New(SetClient,self.Airbases))
return self
end
AIRBASEPOLICE_NEVADA={
ClassName="AIRBASEPOLICE_NEVADA",
Airbases={
Nellis={
PointsBoundary={
[1]={["y"]=-17814.714285714,["x"]=-399823.14285714,},
[2]={["y"]=-16875.857142857,["x"]=-398763.14285714,},
[3]={["y"]=-16251.571428571,["x"]=-398988.85714286,},
[4]={["y"]=-16163,["x"]=-398693.14285714,},
[5]={["y"]=-16328.714285714,["x"]=-398034.57142857,},
[6]={["y"]=-15943,["x"]=-397571.71428571,},
[7]={["y"]=-15711.571428571,["x"]=-397551.71428571,},
[8]={["y"]=-15748.714285714,["x"]=-396806,},
[9]={["y"]=-16288.714285714,["x"]=-396517.42857143,},
[10]={["y"]=-16751.571428571,["x"]=-396308.85714286,},
[11]={["y"]=-17263,["x"]=-396234.57142857,},
[12]={["y"]=-17577.285714286,["x"]=-396640.28571429,},
[13]={["y"]=-17614.428571429,["x"]=-397400.28571429,},
[14]={["y"]=-19405.857142857,["x"]=-399428.85714286,},
[15]={["y"]=-19234.428571429,["x"]=-399683.14285714,},
[16]={["y"]=-18708.714285714,["x"]=-399408.85714286,},
[17]={["y"]=-18397.285714286,["x"]=-399657.42857143,},
[18]={["y"]=-17814.428571429,["x"]=-399823.42857143,},
},
PointsRunways={
[1]={
[1]={["y"]=-18687,["x"]=-399380.28571429,},
[2]={["y"]=-18620.714285714,["x"]=-399436.85714286,},
[3]={["y"]=-16217.857142857,["x"]=-396596.85714286,},
[4]={["y"]=-16300.142857143,["x"]=-396530,},
[5]={["y"]=-18687,["x"]=-399380.85714286,},
},
[2]={
[1]={["y"]=-18451.571428572,["x"]=-399580.57142857,},
[2]={["y"]=-18392.142857143,["x"]=-399628.57142857,},
[3]={["y"]=-16011,["x"]=-396806.85714286,},
[4]={["y"]=-16074.714285714,["x"]=-396751.71428572,},
[5]={["y"]=-18451.571428572,["x"]=-399580.85714285,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
McCarran={
PointsBoundary={
[1]={["y"]=-29455.285714286,["x"]=-416277.42857142,},
[2]={["y"]=-28860.142857143,["x"]=-416492,},
[3]={["y"]=-25044.428571429,["x"]=-416344.85714285,},
[4]={["y"]=-24580.142857143,["x"]=-415959.14285714,},
[5]={["y"]=-25073,["x"]=-415630.57142857,},
[6]={["y"]=-25087.285714286,["x"]=-415130.57142857,},
[7]={["y"]=-25830.142857143,["x"]=-414866.28571428,},
[8]={["y"]=-26658.714285715,["x"]=-414880.57142857,},
[9]={["y"]=-26973,["x"]=-415273.42857142,},
[10]={["y"]=-27380.142857143,["x"]=-415187.71428571,},
[11]={["y"]=-27715.857142857,["x"]=-414144.85714285,},
[12]={["y"]=-27551.571428572,["x"]=-413473.42857142,},
[13]={["y"]=-28630.142857143,["x"]=-413201.99999999,},
[14]={["y"]=-29494.428571429,["x"]=-415437.71428571,},
[15]={["y"]=-29455.571428572,["x"]=-416277.71428571,},
},
PointsRunways={
[1]={
[1]={["y"]=-29408.428571429,["x"]=-416016.28571428,},
[2]={["y"]=-29408.142857144,["x"]=-416105.42857142,},
[3]={["y"]=-24680.714285715,["x"]=-416003.14285713,},
[4]={["y"]=-24681.857142858,["x"]=-415926.57142856,},
[5]={["y"]=-29408.42857143,["x"]=-416016.57142856,},
},
[2]={
[1]={["y"]=-28575.571428572,["x"]=-416303.14285713,},
[2]={["y"]=-28575.571428572,["x"]=-416382.57142856,},
[3]={["y"]=-25111.000000001,["x"]=-416309.7142857,},
[4]={["y"]=-25111.000000001,["x"]=-416249.14285713,},
[5]={["y"]=-28575.571428572,["x"]=-416303.7142857,},
},
[3]={
[1]={["y"]=-29331.000000001,["x"]=-416275.42857141,},
[2]={["y"]=-29259.000000001,["x"]=-416306.85714284,},
[3]={["y"]=-28005.571428572,["x"]=-413449.7142857,},
[4]={["y"]=-28068.714285715,["x"]=-413422.85714284,},
[5]={["y"]=-29331.000000001,["x"]=-416275.7142857,},
},
[4]={
[1]={["y"]=-29073.285714286,["x"]=-416386.57142856,},
[2]={["y"]=-28997.285714286,["x"]=-416417.42857141,},
[3]={["y"]=-27697.571428572,["x"]=-413464.57142856,},
[4]={["y"]=-27767.857142858,["x"]=-413434.28571427,},
[5]={["y"]=-29073.000000001,["x"]=-416386.85714284,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
Creech={
PointsBoundary={
[1]={["y"]=-74522.714285715,["x"]=-360887.99999998,},
[2]={["y"]=-74197,["x"]=-360556.57142855,},
[3]={["y"]=-74402.714285715,["x"]=-359639.42857141,},
[4]={["y"]=-74637,["x"]=-359279.42857141,},
[5]={["y"]=-75759.857142857,["x"]=-359005.14285712,},
[6]={["y"]=-75834.142857143,["x"]=-359045.14285712,},
[7]={["y"]=-75902.714285714,["x"]=-359782.28571427,},
[8]={["y"]=-76099.857142857,["x"]=-360399.42857141,},
[9]={["y"]=-77314.142857143,["x"]=-360219.42857141,},
[10]={["y"]=-77728.428571429,["x"]=-360445.14285713,},
[11]={["y"]=-77585.571428571,["x"]=-360585.14285713,},
[12]={["y"]=-76471.285714286,["x"]=-360819.42857141,},
[13]={["y"]=-76325.571428571,["x"]=-360942.28571427,},
[14]={["y"]=-74671.857142857,["x"]=-360927.7142857,},
[15]={["y"]=-74522.714285714,["x"]=-360888.85714284,},
},
PointsRunways={
[1]={
[1]={["y"]=-74237.571428571,["x"]=-360591.7142857,},
[2]={["y"]=-74234.428571429,["x"]=-360493.71428571,},
[3]={["y"]=-77605.285714286,["x"]=-360399.14285713,},
[4]={["y"]=-77608.714285715,["x"]=-360498.85714285,},
[5]={["y"]=-74237.857142857,["x"]=-360591.7142857,},
},
[2]={
[1]={["y"]=-75807.571428572,["x"]=-359073.42857142,},
[2]={["y"]=-74770.142857144,["x"]=-360581.71428571,},
[3]={["y"]=-74641.285714287,["x"]=-360585.42857142,},
[4]={["y"]=-75734.142857144,["x"]=-359023.14285714,},
[5]={["y"]=-75807.285714287,["x"]=-359073.42857142,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
GroomLake={
PointsBoundary={
[1]={["y"]=-88916.714285714,["x"]=-289102.28571425,},
[2]={["y"]=-87023.571428572,["x"]=-290388.57142857,},
[3]={["y"]=-85916.428571429,["x"]=-290674.28571428,},
[4]={["y"]=-87645.000000001,["x"]=-286567.14285714,},
[5]={["y"]=-88380.714285715,["x"]=-286388.57142857,},
[6]={["y"]=-89670.714285715,["x"]=-283524.28571428,},
[7]={["y"]=-89797.857142858,["x"]=-283567.14285714,},
[8]={["y"]=-88635.000000001,["x"]=-286749.99999999,},
[9]={["y"]=-89177.857142858,["x"]=-287207.14285714,},
[10]={["y"]=-89092.142857144,["x"]=-288892.85714285,},
[11]={["y"]=-88917.000000001,["x"]=-289102.85714285,},
},
PointsRunways={
[1]={
[1]={["y"]=-86039.000000001,["x"]=-290606.28571428,},
[2]={["y"]=-85965.285714287,["x"]=-290573.99999999,},
[3]={["y"]=-87692.714285715,["x"]=-286634.85714285,},
[4]={["y"]=-87756.714285715,["x"]=-286663.99999999,},
[5]={["y"]=-86038.714285715,["x"]=-290606.85714285,},
},
[2]={
[1]={["y"]=-86808.428571429,["x"]=-290375.7142857,},
[2]={["y"]=-86732.714285715,["x"]=-290344.28571427,},
[3]={["y"]=-89672.714285714,["x"]=-283546.57142855,},
[4]={["y"]=-89772.142857143,["x"]=-283587.71428569,},
[5]={["y"]=-86808.142857143,["x"]=-290375.7142857,},
},
},
ZoneBoundary={},
ZoneRunways={},
MaximumSpeed=50,
},
},
}
function AIRBASEPOLICE_NEVADA:New(SetClient)
local self=BASE:Inherit(self,AIRBASEPOLICE_BASE:New(SetClient,self.Airbases))
end
do
DETECTION_BASE={
ClassName="DETECTION_BASE",
DetectionSetGroup=nil,
DetectionRange=nil,
DetectedObjects={},
DetectionRun=0,
DetectedObjectsIdentified={},
DetectedItems={},
}
function DETECTION_BASE:New(DetectionSetGroup)
local self=BASE:Inherit(self,FSM:New())
self.DetectedItemCount=0
self.DetectedItemMax=0
self.DetectedItems={}
self.DetectionSetGroup=DetectionSetGroup
self.RefreshTimeInterval=30
self:InitDetectVisual(nil)
self:InitDetectOptical(nil)
self:InitDetectRadar(nil)
self:InitDetectRWR(nil)
self:InitDetectIRST(nil)
self:InitDetectDLINK(nil)
self:FilterCategories({
Unit.Category.AIRPLANE,
Unit.Category.GROUND_UNIT,
Unit.Category.HELICOPTER,
Unit.Category.SHIP,
Unit.Category.STRUCTURE
})
self:SetFriendliesRange(6000)
self:SetStartState("Stopped")
self:AddTransition("Stopped","Start","Detecting")
self:AddTransition("Detecting","Detect","Detecting")
self:AddTransition("Detecting","DetectionGroup","Detecting")
self:AddTransition("Detecting","Detected","Detecting")
self:AddTransition("*","Stop","Stopped")
return self
end
do
function DETECTION_BASE:onafterStart(From,Event,To)
self:__Detect(1)
end
function DETECTION_BASE:onafterDetect(From,Event,To)
self:E({From,Event,To})
local DetectDelay=0.1
self.DetectionCount=0
self.DetectionRun=0
self:UnIdentifyAllDetectedObjects()
local DetectionTimeStamp=timer.getTime()
for DetectionGroupID,DetectionGroupData in pairs(self.DetectionSetGroup:GetSet())do
self:__DetectionGroup(DetectDelay,DetectionGroupData,DetectionTimeStamp)
self.DetectionCount=self.DetectionCount+1
DetectDelay=DetectDelay+1
end
end
function DETECTION_BASE:onafterDetectionGroup(From,Event,To,DetectionGroup,DetectionTimeStamp)
self:E({From,Event,To})
self.DetectionRun=self.DetectionRun+1
local HasDetectedObjects=false
if DetectionGroup:IsAlive()then
self:T({"DetectionGroup is Alive",DetectionGroup:GetName()})
local DetectionGroupName=DetectionGroup:GetName()
local DetectionUnit=DetectionGroup:GetUnit(1)
local DetectedUnits={}
local DetectedTargets=DetectionGroup:GetDetectedTargets(
self.DetectVisual,
self.DetectOptical,
self.DetectRadar,
self.DetectIRST,
self.DetectRWR,
self.DetectDLINK
)
self:F(DetectedTargets)
for DetectionObjectID,Detection in pairs(DetectedTargets)do
local DetectedObject=Detection.object
if DetectedObject and DetectedObject:isExist()and DetectedObject.id_<50000000 then
local TargetIsDetected,TargetIsVisible,TargetLastTime,TargetKnowType,TargetKnowDistance,TargetLastPos,TargetLastVelocity=DetectionUnit:IsTargetDetected(
DetectedObject,
self.DetectVisual,
self.DetectOptical,
self.DetectRadar,
self.DetectIRST,
self.DetectRWR,
self.DetectDLINK
)
self:T2({TargetIsDetected=TargetIsDetected,TargetIsVisible=TargetIsVisible,TargetLastTime=TargetLastTime,TargetKnowType=TargetKnowType,TargetKnowDistance=TargetKnowDistance,TargetLastPos=TargetLastPos,TargetLastVelocity=TargetLastVelocity})
local DetectionAccepted=true
local DetectedObjectName=DetectedObject:getName()
local DetectedObjectType=DetectedObject:getTypeName()
local DetectedObjectVec3=DetectedObject:getPoint()
local DetectedObjectVec2={x=DetectedObjectVec3.x,y=DetectedObjectVec3.z}
local DetectionGroupVec3=DetectionGroup:GetVec3()
local DetectionGroupVec2={x=DetectionGroupVec3.x,y=DetectionGroupVec3.z}
local Distance=((DetectedObjectVec3.x-DetectionGroupVec3.x)^2+
(DetectedObjectVec3.y-DetectionGroupVec3.y)^2+
(DetectedObjectVec3.z-DetectionGroupVec3.z)^2
)^0.5/1000
local DetectedUnitCategory=DetectedObject:getDesc().category
self:F({"Detected Target:",DetectionGroupName,DetectedObjectName,DetectedObjectType,Distance,DetectedUnitCategory})
DetectionAccepted=self._.FilterCategories[DetectedUnitCategory]~=nil and DetectionAccepted or false
if self.AcceptRange and Distance>self.AcceptRange then
DetectionAccepted=false
end
if self.AcceptZones then
for AcceptZoneID,AcceptZone in pairs(self.AcceptZones)do
local AcceptZone=AcceptZone
if AcceptZone:IsVec2InZone(DetectedObjectVec2)==false then
DetectionAccepted=false
end
end
end
if self.RejectZones then
for RejectZoneID,RejectZone in pairs(self.RejectZones)do
local RejectZone=RejectZone
if RejectZone:IsPointVec2InZone(DetectedObjectVec2)==true then
DetectionAccepted=false
end
end
end
if not self.DetectedObjects[DetectedObjectName]and Detection.visible and self.DistanceProbability then
local DistanceFactor=Distance/4
local DistanceProbabilityReversed=(1-self.DistanceProbability)*DistanceFactor
local DistanceProbability=1-DistanceProbabilityReversed
DistanceProbability=DistanceProbability*30/300
local Probability=math.random()
self:T({Probability,DistanceProbability})
if Probability>DistanceProbability then
DetectionAccepted=false
end
end
if not self.DetectedObjects[DetectedObjectName]and Detection.visible and self.AlphaAngleProbability then
local NormalVec2={x=DetectedObjectVec2.x-DetectionGroupVec2.x,y=DetectedObjectVec2.y-DetectionGroupVec2.y}
local AlphaAngle=math.atan2(NormalVec2.y,NormalVec2.x)
local Sinus=math.sin(AlphaAngle)
local AlphaAngleProbabilityReversed=(1-self.AlphaAngleProbability)*(1-Sinus)
local AlphaAngleProbability=1-AlphaAngleProbabilityReversed
AlphaAngleProbability=AlphaAngleProbability*30/300
local Probability=math.random()
self:T({Probability,AlphaAngleProbability})
if Probability>AlphaAngleProbability then
DetectionAccepted=false
end
end
if not self.DetectedObjects[DetectedObjectName]and Detection.visible and self.ZoneProbability then
for ZoneDataID,ZoneData in pairs(self.ZoneProbability)do
self:E({ZoneData})
local ZoneObject=ZoneData[1]
local ZoneProbability=ZoneData[2]
ZoneProbability=ZoneProbability*30/300
if ZoneObject:IsPointVec2InZone(DetectedObjectVec2)==true then
local Probability=math.random()
self:T({Probability,ZoneProbability})
if Probability>ZoneProbability then
DetectionAccepted=false
break
end
end
end
end
if DetectionAccepted then
HasDetectedObjects=true
self.DetectedObjects[DetectedObjectName]=self.DetectedObjects[DetectedObjectName]or{}
self.DetectedObjects[DetectedObjectName].Name=DetectedObjectName
self.DetectedObjects[DetectedObjectName].IsDetected=TargetIsDetected
self.DetectedObjects[DetectedObjectName].IsVisible=TargetIsVisible
self.DetectedObjects[DetectedObjectName].LastTime=TargetLastTime
self.DetectedObjects[DetectedObjectName].LastPos=TargetLastPos
self.DetectedObjects[DetectedObjectName].LastVelocity=TargetLastVelocity
self.DetectedObjects[DetectedObjectName].KnowType=TargetKnowType
self.DetectedObjects[DetectedObjectName].KnowDistance=Detection.distance
self.DetectedObjects[DetectedObjectName].Distance=Distance
self.DetectedObjects[DetectedObjectName].DetectionTimeStamp=DetectionTimeStamp
self:F({DetectedObject=self.DetectedObjects[DetectedObjectName]})
local DetectedUnit=UNIT:FindByName(DetectedObjectName)
DetectedUnits[DetectedObjectName]=DetectedUnit
else
if self.DetectedObjects[DetectedObjectName]then
self.DetectedObjects[DetectedObjectName]=nil
end
end
end
self:T2(self.DetectedObjects)
end
if HasDetectedObjects then
self:__Detected(0.1,DetectedUnits)
end
end
if self.DetectionCount>0 and self.DetectionRun==self.DetectionCount then
self:T("--> Create Detection Sets")
for DetectedObjectName,DetectedObject in pairs(self.DetectedObjects)do
if self.DetectedObjects[DetectedObjectName].IsDetected==true and self.DetectedObjects[DetectedObjectName].DetectionTimeStamp+60<=DetectionTimeStamp then
self.DetectedObjects[DetectedObjectName].IsDetected=false
end
end
self:CreateDetectionItems()
for DetectedItemID,DetectedItem in pairs(self.DetectedItems)do
self:UpdateDetectedItemDetection(DetectedItem)
self:CleanDetectionItem(DetectedItem,DetectedItemID)
end
self:__Detect(self.RefreshTimeInterval)
end
end
end
do
function DETECTION_BASE:CleanDetectionItem(DetectedItem,DetectedItemID)
self:F2()
local DetectedSet=DetectedItem.Set
if DetectedSet:Count()==0 then
self:RemoveDetectedItem(DetectedItemID)
end
return self
end
function DETECTION_BASE:ForgetDetectedUnit(UnitName)
self:F2()
local DetectedItems=self:GetDetectedItems()
for DetectedItemIndex,DetectedItem in pairs(DetectedItems)do
local DetectedSet=self:GetDetectedSet(DetectedItemIndex)
if DetectedSet then
DetectedSet:RemoveUnitsByName(UnitName)
end
end
return self
end
function DETECTION_BASE:CreateDetectionItems()
self:F2()
self:E("Error, in DETECTION_BASE class...")
return self
end
end
do
function DETECTION_BASE:InitDetectVisual(DetectVisual)
self.DetectVisual=DetectVisual
return self
end
function DETECTION_BASE:InitDetectOptical(DetectOptical)
self:F2()
self.DetectOptical=DetectOptical
return self
end
function DETECTION_BASE:InitDetectRadar(DetectRadar)
self:F2()
self.DetectRadar=DetectRadar
return self
end
function DETECTION_BASE:InitDetectIRST(DetectIRST)
self:F2()
self.DetectIRST=DetectIRST
return self
end
function DETECTION_BASE:InitDetectRWR(DetectRWR)
self:F2()
self.DetectRWR=DetectRWR
return self
end
function DETECTION_BASE:InitDetectDLINK(DetectDLINK)
self:F2()
self.DetectDLINK=DetectDLINK
return self
end
end
do
function DETECTION_BASE:FilterCategories(FilterCategories)
self:F2()
self._.FilterCategories={}
if type(FilterCategories)=="table"then
for CategoryID,Category in pairs(FilterCategories)do
self._.FilterCategories[Category]=Category
end
else
self._.FilterCategories[FilterCategories]=FilterCategories
end
return self
end
end
do
function DETECTION_BASE:SetRefreshTimeInterval(RefreshTimeInterval)
self:F2()
self.RefreshTimeInterval=RefreshTimeInterval
return self
end
end
do
function DETECTION_BASE:SetFriendliesRange(FriendliesRange)
self:F2()
self.FriendliesRange=FriendliesRange
return self
end
end
do
function DETECTION_BASE:SetIntercept(Intercept,InterceptDelay)
self:F2()
self.Intercept=Intercept
self.InterceptDelay=InterceptDelay
return self
end
end
do
function DETECTION_BASE:SetAcceptRange(AcceptRange)
self:F2()
self.AcceptRange=AcceptRange
return self
end
function DETECTION_BASE:SetAcceptZones(AcceptZones)
self:F2()
if type(AcceptZones)=="table"then
if AcceptZones.ClassName and AcceptZones:IsInstanceOf(ZONE_BASE)then
self.AcceptZones={AcceptZones}
else
self.AcceptZones=AcceptZones
end
else
self:E({"AcceptZones must be a list of ZONE_BASE derived objects or one ZONE_BASE derived object",AcceptZones})
error()
end
return self
end
function DETECTION_BASE:SetRejectZones(RejectZones)
self:F2()
if type(RejectZones)=="table"then
if RejectZones.ClassName and RejectZones:IsInstanceOf(ZONE_BASE)then
self.RejectZones={RejectZones}
else
self.RejectZones=RejectZones
end
else
self:E({"RejectZones must be a list of ZONE_BASE derived objects or one ZONE_BASE derived object",RejectZones})
error()
end
return self
end
end
do
function DETECTION_BASE:SetDistanceProbability(DistanceProbability)
self:F2()
self.DistanceProbability=DistanceProbability
return self
end
function DETECTION_BASE:SetAlphaAngleProbability(AlphaAngleProbability)
self:F2()
self.AlphaAngleProbability=AlphaAngleProbability
return self
end
function DETECTION_BASE:SetZoneProbability(ZoneArray)
self:F2()
self.ZoneProbability=ZoneArray
return self
end
end
do
function DETECTION_BASE:AcceptChanges(DetectedItem)
DetectedItem.Changed=false
DetectedItem.Changes={}
return self
end
function DETECTION_BASE:AddChangeItem(DetectedItem,ChangeCode,ItemUnitType)
DetectedItem.Changed=true
local ID=DetectedItem.ID
DetectedItem.Changes=DetectedItem.Changes or{}
DetectedItem.Changes[ChangeCode]=DetectedItem.Changes[ChangeCode]or{}
DetectedItem.Changes[ChangeCode].ID=ID
DetectedItem.Changes[ChangeCode].ItemUnitType=ItemUnitType
self:E({"Change on Detection Item:",DetectedItem.ID,ChangeCode,ItemUnitType})
return self
end
function DETECTION_BASE:AddChangeUnit(DetectedItem,ChangeCode,ChangeUnitType)
DetectedItem.Changed=true
local ID=DetectedItem.ID
DetectedItem.Changes=DetectedItem.Changes or{}
DetectedItem.Changes[ChangeCode]=DetectedItem.Changes[ChangeCode]or{}
DetectedItem.Changes[ChangeCode][ChangeUnitType]=DetectedItem.Changes[ChangeCode][ChangeUnitType]or 0
DetectedItem.Changes[ChangeCode][ChangeUnitType]=DetectedItem.Changes[ChangeCode][ChangeUnitType]+1
DetectedItem.Changes[ChangeCode].ID=ID
self:E({"Change on Detection Item:",DetectedItem.ID,ChangeCode,ChangeUnitType})
return self
end
end
do
function DETECTION_BASE:SetFriendlyPrefixes(FriendlyPrefixes)
self.FriendlyPrefixes=self.FriendlyPrefixes or{}
if type(FriendlyPrefixes)~="table"then
FriendlyPrefixes={FriendlyPrefixes}
end
for PrefixID,Prefix in pairs(FriendlyPrefixes)do
self:F({FriendlyPrefix=Prefix})
self.FriendlyPrefixes[Prefix]=Prefix
end
return self
end
function DETECTION_BASE:IsFriendliesNearBy(DetectedItem)
return DetectedItem.FriendliesNearBy~=nil or false
end
function DETECTION_BASE:GetFriendliesNearBy(DetectedItem)
return DetectedItem.FriendliesNearBy
end
function DETECTION_BASE:FilterFriendliesCategory(FriendliesCategory)
self.FriendliesCategory=FriendliesCategory
return self
end
function DETECTION_BASE:IsFriendliesNearIntercept(DetectedItem)
return DetectedItem.FriendliesNearIntercept~=nil or false
end
function DETECTION_BASE:GetFriendliesNearIntercept(DetectedItem)
return DetectedItem.FriendliesNearIntercept
end
function DETECTION_BASE:GetFriendliesDistance(DetectedItem)
return DetectedItem.FriendliesDistance
end
function DETECTION_BASE:IsPlayersNearBy(DetectedItem)
return DetectedItem.PlayersNearBy~=nil
end
function DETECTION_BASE:GetPlayersNearBy(DetectedItem)
return DetectedItem.PlayersNearBy
end
function DETECTION_BASE:ReportFriendliesNearBy(ReportGroupData)
self:F2()
local DetectedItem=ReportGroupData.DetectedItem
local DetectedSet=ReportGroupData.DetectedItem.Set
local DetectedUnit=DetectedSet:GetFirst()
DetectedItem.FriendliesNearBy=nil
if DetectedUnit and DetectedUnit:IsAlive()then
local DetectedUnitCoord=DetectedUnit:GetCoordinate()
local InterceptCoord=ReportGroupData.InterceptCoord or DetectedUnitCoord
local SphereSearch={
id=world.VolumeType.SPHERE,
params={
point=InterceptCoord:GetVec3(),
radius=self.FriendliesRange,
}
}
local FindNearByFriendlies=function(FoundDCSUnit,ReportGroupData)
local DetectedItem=ReportGroupData.DetectedItem
local DetectedSet=ReportGroupData.DetectedItem.Set
local DetectedUnit=DetectedSet:GetFirst()
local DetectedUnitCoord=DetectedUnit:GetCoordinate()
local InterceptCoord=ReportGroupData.InterceptCoord or DetectedUnitCoord
local ReportSetGroup=ReportGroupData.ReportSetGroup
local EnemyCoalition=DetectedUnit:GetCoalition()
local FoundUnitCoalition=FoundDCSUnit:getCoalition()
local FoundUnitName=FoundDCSUnit:getName()
local FoundUnitGroupName=FoundDCSUnit:getGroup():getName()
local EnemyUnitName=DetectedUnit:GetName()
local FoundUnitInReportSetGroup=ReportSetGroup:FindGroup(FoundUnitGroupName)~=nil
self:T({"Friendlies search:",FoundUnitName,FoundUnitCoalition,EnemyUnitName,EnemyCoalition,FoundUnitInReportSetGroup})
if FoundUnitInReportSetGroup==true then
for PrefixID,Prefix in pairs(self.FriendlyPrefixes or{})do
self:F({"FriendlyPrefix:",Prefix})
if string.find(FoundUnitName,Prefix:gsub("-","%%-"),1)then
FoundUnitInReportSetGroup=false
break
end
end
end
self:F({"Friendlies search:",FoundUnitName,FoundUnitCoalition,EnemyUnitName,EnemyCoalition,FoundUnitInReportSetGroup})
if FoundUnitCoalition~=EnemyCoalition and FoundUnitInReportSetGroup==false then
local FriendlyUnit=UNIT:Find(FoundDCSUnit)
local FriendlyUnitName=FriendlyUnit:GetName()
local FriendlyUnitCategory=FriendlyUnit:GetDesc().category
self:T({FriendlyUnitCategory=FriendlyUnitCategory,FriendliesCategory=self.FriendliesCategory})
DetectedItem.FriendliesNearBy=DetectedItem.FriendliesNearBy or{}
DetectedItem.FriendliesNearBy[FriendlyUnitName]=FriendlyUnit
local Distance=DetectedUnitCoord:Get2DDistance(FriendlyUnit:GetCoordinate())
DetectedItem.FriendliesDistance=DetectedItem.FriendliesDistance or{}
DetectedItem.FriendliesDistance[Distance]=FriendlyUnit
self:T({FriendlyUnitName=FriendlyUnitName,Distance=Distance})
return true
end
return true
end
world.searchObjects(Object.Category.UNIT,SphereSearch,FindNearByFriendlies,ReportGroupData)
DetectedItem.PlayersNearBy=nil
local DetectionZone=ZONE_UNIT:New("DetectionPlayers",DetectedUnit,self.FriendliesRange)
_DATABASE:ForEachPlayer(
function(PlayerUnitName)
local PlayerUnit=UNIT:FindByName(PlayerUnitName)
if PlayerUnit and PlayerUnit:IsInZone(DetectionZone)then
local PlayerUnitCategory=PlayerUnit:GetDesc().category
if(not self.FriendliesCategory)or(self.FriendliesCategory and(self.FriendliesCategory==PlayerUnitCategory))then
DetectedItem.FriendliesNearBy=DetectedItem.FriendliesNearBy or{}
local PlayerUnitName=PlayerUnit:GetName()
DetectedItem.PlayersNearBy=DetectedItem.PlayersNearBy or{}
DetectedItem.PlayersNearBy[PlayerUnitName]=PlayerUnit
DetectedItem.FriendliesNearBy=DetectedItem.FriendliesNearBy or{}
DetectedItem.FriendliesNearBy[PlayerUnitName]=PlayerUnit
local Distance=DetectedUnitCoord:Get2DDistance(PlayerUnit:GetCoordinate())
DetectedItem.FriendliesDistance=DetectedItem.FriendliesDistance or{}
DetectedItem.FriendliesDistance[Distance]=PlayerUnit
end
end
end
)
end
end
end
function DETECTION_BASE:IsDetectedObjectIdentified(DetectedObject)
local DetectedObjectName=DetectedObject.Name
if DetectedObjectName then
local DetectedObjectIdentified=self.DetectedObjectsIdentified[DetectedObjectName]==true
self:T3(DetectedObjectIdentified)
return DetectedObjectIdentified
else
return nil
end
end
function DETECTION_BASE:IdentifyDetectedObject(DetectedObject)
local DetectedObjectName=DetectedObject.Name
self.DetectedObjectsIdentified[DetectedObjectName]=true
end
function DETECTION_BASE:UnIdentifyDetectedObject(DetectedObject)
local DetectedObjectName=DetectedObject.Name
self.DetectedObjectsIdentified[DetectedObjectName]=false
end
function DETECTION_BASE:UnIdentifyAllDetectedObjects()
self.DetectedObjectsIdentified={}
end
function DETECTION_BASE:GetDetectedObject(ObjectName)
if ObjectName then
local DetectedObject=self.DetectedObjects[ObjectName]
if DetectedObject then
local DetectedUnit=UNIT:FindByName(ObjectName)
if DetectedUnit and DetectedUnit:IsAlive()then
if self:IsDetectedObjectIdentified(DetectedObject)==false then
return DetectedObject
end
end
end
end
return nil
end
function DETECTION_BASE:GetDetectedUnitTypeName(DetectedUnit)
if DetectedUnit and DetectedUnit:IsAlive()then
local DetectedUnitName=DetectedUnit:GetName()
local DetectedObject=self.DetectedObjects[DetectedUnitName]
if DetectedObject then
if DetectedObject.KnowType then
return DetectedUnit:GetTypeName()
else
return"Unknown"
end
else
return"Unknown"
end
else
return"Dead:"..DetectedUnit:GetName()
end
return"Undetected:"..DetectedUnit:GetName()
end
function DETECTION_BASE:AddDetectedItem(ItemPrefix,DetectedItemIndex,Set)
local DetectedItem={}
self.DetectedItemCount=self.DetectedItemCount+1
self.DetectedItemMax=self.DetectedItemMax+1
if DetectedItemIndex then
self.DetectedItems[DetectedItemIndex]=DetectedItem
else
self.DetectedItems[self.DetectedItemCount]=DetectedItem
end
DetectedItem.Set=Set or SET_UNIT:New():FilterDeads():FilterCrashes()
DetectedItem.Index=DetectedItemIndex or self.DetectedItemCount
DetectedItem.ItemID=ItemPrefix.."."..self.DetectedItemMax
DetectedItem.ID=self.DetectedItemMax
DetectedItem.Removed=false
return DetectedItem
end
function DETECTION_BASE:AddDetectedItemZone(DetectedItemIndex,Set,Zone)
local DetectedItem=self:AddDetectedItem("AREA",DetectedItemIndex,Set)
DetectedItem.Zone=Zone
return DetectedItem
end
function DETECTION_BASE:RemoveDetectedItem(DetectedItemIndex)
if self.DetectedItems[DetectedItemIndex]then
self.DetectedItemCount=self.DetectedItemCount-1
self.DetectedItems[DetectedItemIndex]=nil
end
end
function DETECTION_BASE:GetDetectedItems()
return self.DetectedItems
end
function DETECTION_BASE:GetDetectedItemsCount()
local DetectedCount=self.DetectedItemCount
return DetectedCount
end
function DETECTION_BASE:GetDetectedItem(Index)
local DetectedItem=self.DetectedItems[Index]
if DetectedItem then
return DetectedItem
end
return nil
end
function DETECTION_BASE:GetDetectedItemID(Index)
local DetectedItem=self.DetectedItems[Index]
if DetectedItem then
return DetectedItem.ItemID
end
return""
end
function DETECTION_BASE:GetDetectedID(Index)
local DetectedItem=self.DetectedItems[Index]
if DetectedItem then
return DetectedItem.ID
end
return""
end
function DETECTION_BASE:GetDetectedSet(Index)
local DetectedItem=self:GetDetectedItem(Index)
local DetectedSetUnit=DetectedItem.Set
if DetectedSetUnit then
return DetectedSetUnit
end
return nil
end
function DETECTION_BASE:UpdateDetectedItemDetection(DetectedItem)
local IsDetected=false
for UnitName,UnitData in pairs(DetectedItem.Set:GetSet())do
local DetectedObject=self.DetectedObjects[UnitName]
self:F({UnitName=UnitName,IsDetected=DetectedObject.IsDetected})
if DetectedObject.IsDetected then
IsDetected=true
break
end
end
self:F({IsDetected=DetectedItem.IsDetected})
DetectedItem.IsDetected=IsDetected
return IsDetected
end
function DETECTION_BASE:IsDetectedItemDetected(DetectedItem)
return DetectedItem.IsDetected
end
do
function DETECTION_BASE:GetDetectedItemZone(Index)
local DetectedZone=self.DetectedItems[Index].Zone
if DetectedZone then
return DetectedZone
end
local Detected
return nil
end
end
function DETECTION_BASE:SetDetectedItemCoordinate(DetectedItem,Coordinate,DetectedItemUnit)
self:F({Coordinate=Coordinate})
if DetectedItem then
if DetectedItemUnit then
DetectedItem.Coordinate=Coordinate
DetectedItem.Coordinate:SetHeading(DetectedItemUnit:GetHeading())
DetectedItem.Coordinate.y=DetectedItemUnit:GetAltitude()
DetectedItem.Coordinate:SetVelocity(DetectedItemUnit:GetVelocityMPS())
end
end
end
function DETECTION_BASE:GetDetectedItemCoordinate(Index)
self:F({Index=Index})
local DetectedItem=self:GetDetectedItem(Index)
if DetectedItem then
return DetectedItem.Coordinate
end
return nil
end
function DETECTION_BASE:SetDetectedItemThreatLevel(DetectedItem)
local DetectedSet=DetectedItem.Set
if DetectedItem then
DetectedItem.ThreatLevel,DetectedItem.ThreatText=DetectedSet:CalculateThreatLevelA2G()
end
end
function DETECTION_BASE:GetDetectedItemThreatLevel(Index)
self:F({Index=Index})
local DetectedItem=self:GetDetectedItem(Index)
if DetectedItem then
return DetectedItem.ThreatLevel or 0,DetectedItem.ThreatText or""
end
return nil,""
end
function DETECTION_BASE:DetectedItemMenu(Index,AttackGroup)
self:F(Index)
return nil
end
function DETECTION_BASE:DetectedItemReportSummary(Index,AttackGroup,Settings)
self:F(Index)
return nil
end
function DETECTION_BASE:DetectedReportDetailed(AttackGroup)
self:F()
return nil
end
function DETECTION_BASE:GetDetectionSetGroup()
local DetectionSetGroup=self.DetectionSetGroup
return DetectionSetGroup
end
function DETECTION_BASE:Schedule(DelayTime,RepeatInterval)
self:F2()
self.ScheduleDelayTime=DelayTime
self.ScheduleRepeatInterval=RepeatInterval
self.DetectionScheduler=SCHEDULER:New(self,self._DetectionScheduler,{self,"Detection"},DelayTime,RepeatInterval)
return self
end
end
do
DETECTION_UNITS={
ClassName="DETECTION_UNITS",
DetectionRange=nil,
}
function DETECTION_UNITS:New(DetectionSetGroup)
local self=BASE:Inherit(self,DETECTION_BASE:New(DetectionSetGroup))
self._SmokeDetectedUnits=false
self._FlareDetectedUnits=false
self._SmokeDetectedZones=false
self._FlareDetectedZones=false
self._BoundDetectedZones=false
return self
end
function DETECTION_UNITS:GetChangeText(DetectedItem)
self:F(DetectedItem)
local MT={}
for ChangeCode,ChangeData in pairs(DetectedItem.Changes)do
if ChangeCode=="AU"then
local MTUT={}
for ChangeUnitType,ChangeUnitCount in pairs(ChangeData)do
if ChangeUnitType~="ID"then
MTUT[#MTUT+1]=ChangeUnitCount.." of "..ChangeUnitType
end
end
MT[#MT+1]="   New target(s) detected: "..table.concat(MTUT,", ").."."
end
if ChangeCode=="RU"then
local MTUT={}
for ChangeUnitType,ChangeUnitCount in pairs(ChangeData)do
if ChangeUnitType~="ID"then
MTUT[#MTUT+1]=ChangeUnitCount.." of "..ChangeUnitType
end
end
MT[#MT+1]="   Invisible or destroyed target(s): "..table.concat(MTUT,", ").."."
end
end
return table.concat(MT,"\n")
end
function DETECTION_UNITS:CreateDetectionItems()
self:F2(#self.DetectedObjects)
for DetectedItemID,DetectedItem in pairs(self.DetectedItems)do
local DetectedItemSet=DetectedItem.Set
for DetectedUnitName,DetectedUnitData in pairs(DetectedItemSet:GetSet())do
local DetectedUnit=DetectedUnitData
local DetectedObject=nil
if DetectedUnit:IsAlive()then
DetectedObject=self:GetDetectedObject(DetectedUnit:GetName())
end
if DetectedObject then
self:IdentifyDetectedObject(DetectedObject)
DetectedItem.TypeName=DetectedUnit:GetTypeName()
DetectedItem.CategoryName=DetectedUnit:GetCategoryName()
DetectedItem.Name=DetectedObject.Name
DetectedItem.IsVisible=DetectedObject.IsVisible
DetectedItem.LastTime=DetectedObject.LastTime
DetectedItem.LastPos=DetectedObject.LastPos
DetectedItem.LastVelocity=DetectedObject.LastVelocity
DetectedItem.KnowType=DetectedObject.KnowType
DetectedItem.KnowDistance=DetectedObject.KnowDistance
DetectedItem.Distance=DetectedObject.Distance
else
self:AddChangeUnit(DetectedItem,"RU",DetectedUnitName)
DetectedItemSet:Remove(DetectedUnitName)
end
end
end
for DetectedUnitName,DetectedObjectData in pairs(self.DetectedObjects)do
local DetectedObject=self:GetDetectedObject(DetectedUnitName)
if DetectedObject then
self:T({"Detected Unit #",DetectedUnitName})
local DetectedUnit=UNIT:FindByName(DetectedUnitName)
if DetectedUnit then
local DetectedTypeName=DetectedUnit:GetTypeName()
local DetectedItem=self:GetDetectedItem(DetectedUnitName)
if not DetectedItem then
self:T("Added new DetectedItem")
DetectedItem=self:AddDetectedItem("UNIT",DetectedUnitName)
DetectedItem.TypeName=DetectedUnit:GetTypeName()
DetectedItem.Name=DetectedObject.Name
DetectedItem.IsVisible=DetectedObject.IsVisible
DetectedItem.LastTime=DetectedObject.LastTime
DetectedItem.LastPos=DetectedObject.LastPos
DetectedItem.LastVelocity=DetectedObject.LastVelocity
DetectedItem.KnowType=DetectedObject.KnowType
DetectedItem.KnowDistance=DetectedObject.KnowDistance
DetectedItem.Distance=DetectedObject.Distance
end
DetectedItem.Set:AddUnit(DetectedUnit)
self:AddChangeUnit(DetectedItem,"AU",DetectedTypeName)
end
end
end
for DetectedItemID,DetectedItemData in pairs(self.DetectedItems)do
local DetectedItem=DetectedItemData
local DetectedSet=DetectedItem.Set
local DetectedFirstUnit=DetectedSet:GetFirst()
local DetectedFirstUnitCoord=DetectedFirstUnit:GetCoordinate()
self:SetDetectedItemCoordinate(DetectedItem,DetectedFirstUnitCoord,DetectedFirstUnit)
self:ReportFriendliesNearBy({DetectedItem=DetectedItem,ReportSetGroup=self.DetectionSetGroup})
end
end
function DETECTION_UNITS:DetectedItemMenu(Index,AttackGroup)
self:F(Index)
local DetectedItem=self:GetDetectedItem(Index)
local DetectedSet=self:GetDetectedSet(Index)
local DetectedItemID=self:GetDetectedItemID(Index)
self:T(DetectedSet)
if DetectedSet then
local ReportSummary=""
local UnitDistanceText=""
local UnitCategoryText=""
local DetectedItemCoordinate=self:GetDetectedItemCoordinate(Index)
local DetectedItemCoordText=DetectedItemCoordinate:ToString(AttackGroup)
ReportSummary=string.format(
"%s - %s",
DetectedItemID,
DetectedItemCoordText
)
self:T(ReportSummary)
return ReportSummary
end
end
function DETECTION_UNITS:DetectedItemReportSummary(Index,AttackGroup,Settings)
self:F({Index,self.DetectedItems})
local DetectedItem=self:GetDetectedItem(Index)
local DetectedItemID=self:GetDetectedItemID(Index)
if DetectedItem then
local ReportSummary=""
local UnitDistanceText=""
local UnitCategoryText=""
if DetectedItem.KnowType then
local UnitCategoryName=DetectedItem.CategoryName
if UnitCategoryName then
UnitCategoryText=UnitCategoryName
end
if DetectedItem.TypeName then
UnitCategoryText=UnitCategoryText.." ("..DetectedItem.TypeName..")"
end
else
UnitCategoryText="Unknown"
end
if DetectedItem.KnowDistance then
if DetectedItem.IsVisible then
UnitDistanceText=" at "..string.format("%.2f",DetectedItem.Distance).." km"
end
else
if DetectedItem.IsVisible then
UnitDistanceText=" at +/- "..string.format("%.0f",DetectedItem.Distance).." km"
end
end
local DetectedItemCoordinate=self:GetDetectedItemCoordinate(Index)
local DetectedItemCoordText=DetectedItemCoordinate:ToString(AttackGroup,Settings)
local ThreatLevelA2G=self:GetDetectedItemThreatLevel(Index)
local Report=REPORT:New()
Report:Add(DetectedItemID..", "..DetectedItemCoordText)
Report:Add(string.format("Threat: [%s]",string.rep("■",ThreatLevelA2G)))
Report:Add(string.format("Type: %s%s",UnitCategoryText,UnitDistanceText))
return Report
end
return nil
end
function DETECTION_UNITS:DetectedReportDetailed(AttackGroup)
self:F()
local Report=REPORT:New()
for DetectedItemID,DetectedItem in pairs(self.DetectedItems)do
local DetectedItem=DetectedItem
local ReportSummary=self:DetectedItemReportSummary(DetectedItemID,AttackGroup)
Report:SetTitle("Detected units:")
Report:Add(ReportSummary:Text())
end
local ReportText=Report:Text()
return ReportText
end
end
do
DETECTION_TYPES={
ClassName="DETECTION_TYPES",
DetectionRange=nil,
}
function DETECTION_TYPES:New(DetectionSetGroup)
local self=BASE:Inherit(self,DETECTION_BASE:New(DetectionSetGroup))
self._SmokeDetectedUnits=false
self._FlareDetectedUnits=false
self._SmokeDetectedZones=false
self._FlareDetectedZones=false
self._BoundDetectedZones=false
return self
end
function DETECTION_TYPES:GetChangeText(DetectedItem)
self:F(DetectedItem)
local MT={}
for ChangeCode,ChangeData in pairs(DetectedItem.Changes)do
if ChangeCode=="AU"then
local MTUT={}
for ChangeUnitType,ChangeUnitCount in pairs(ChangeData)do
if ChangeUnitType~="ID"then
MTUT[#MTUT+1]=ChangeUnitCount.." of "..ChangeUnitType
end
end
MT[#MT+1]="   New target(s) detected: "..table.concat(MTUT,", ").."."
end
if ChangeCode=="RU"then
local MTUT={}
for ChangeUnitType,ChangeUnitCount in pairs(ChangeData)do
if ChangeUnitType~="ID"then
MTUT[#MTUT+1]=ChangeUnitCount.." of "..ChangeUnitType
end
end
MT[#MT+1]="   Invisible or destroyed target(s): "..table.concat(MTUT,", ").."."
end
end
return table.concat(MT,"\n")
end
function DETECTION_TYPES:CreateDetectionItems()
self:F2(#self.DetectedObjects)
for DetectedItemID,DetectedItem in pairs(self.DetectedItems)do
local DetectedItemSet=DetectedItem.Set
local DetectedTypeName=DetectedItem.TypeName
for DetectedUnitName,DetectedUnitData in pairs(DetectedItemSet:GetSet())do
local DetectedUnit=DetectedUnitData
local DetectedObject=nil
if DetectedUnit:IsAlive()then
DetectedObject=self:GetDetectedObject(DetectedUnit:GetName())
end
if DetectedObject then
self:IdentifyDetectedObject(DetectedObject)
else
self:AddChangeUnit(DetectedItem,"RU",DetectedUnitName)
DetectedItemSet:Remove(DetectedUnitName)
end
end
end
for DetectedUnitName,DetectedObjectData in pairs(self.DetectedObjects)do
local DetectedObject=self:GetDetectedObject(DetectedUnitName)
if DetectedObject then
self:T({"Detected Unit #",DetectedUnitName})
local DetectedUnit=UNIT:FindByName(DetectedUnitName)
if DetectedUnit then
local DetectedTypeName=DetectedUnit:GetTypeName()
local DetectedItem=self:GetDetectedItem(DetectedTypeName)
if not DetectedItem then
DetectedItem=self:AddDetectedItem("TYPE",DetectedTypeName)
DetectedItem.TypeName=DetectedUnit:GetTypeName()
end
DetectedItem.Set:AddUnit(DetectedUnit)
self:AddChangeUnit(DetectedItem,"AU",DetectedTypeName)
end
end
end
for DetectedItemID,DetectedItemData in pairs(self.DetectedItems)do
local DetectedItem=DetectedItemData
local DetectedSet=DetectedItem.Set
local DetectedFirstUnit=DetectedSet:GetFirst()
local DetectedUnitCoord=DetectedFirstUnit:GetCoordinate()
self:SetDetectedItemCoordinate(DetectedItem,DetectedUnitCoord,DetectedFirstUnit)
self:ReportFriendliesNearBy({DetectedItem=DetectedItem,ReportSetGroup=self.DetectionSetGroup})
end
end
function DETECTION_TYPES:DetectedItemMenu(DetectedTypeName,AttackGroup)
self:F(DetectedTypeName)
local DetectedItem=self:GetDetectedItem(DetectedTypeName)
local DetectedItemID=self:GetDetectedItemID(DetectedTypeName)
if DetectedItem then
local DetectedItemCoordinate=self:GetDetectedItemCoordinate(DetectedTypeName)
local DetectedItemCoordText=DetectedItemCoordinate:ToString(AttackGroup)
local ReportSummary=string.format(
"%s - %s",
DetectedItemID,
DetectedItemCoordText
)
self:T(ReportSummary)
return ReportSummary
end
end
function DETECTION_TYPES:DetectedItemReportSummary(DetectedTypeName,AttackGroup,Settings)
self:F(DetectedTypeName)
local DetectedItem=self:GetDetectedItem(DetectedTypeName)
local DetectedSet=self:GetDetectedSet(DetectedTypeName)
local DetectedItemID=self:GetDetectedItemID(DetectedTypeName)
self:T(DetectedItem)
if DetectedItem then
local ThreatLevelA2G=self:GetDetectedItemThreatLevel(DetectedTypeName)
local DetectedItemsCount=DetectedSet:Count()
local DetectedItemType=DetectedItem.TypeName
local DetectedItemCoordinate=self:GetDetectedItemCoordinate(DetectedTypeName)
local DetectedItemCoordText=DetectedItemCoordinate:ToString(AttackGroup,Settings)
local Report=REPORT:New()
Report:Add(DetectedItemID..", "..DetectedItemCoordText)
Report:Add(string.format("Threat: [%s]",string.rep("■",ThreatLevelA2G)))
Report:Add(string.format("Type: %2d of %s",DetectedItemsCount,DetectedItemType))
return Report
end
end
function DETECTION_TYPES:DetectedReportDetailed(AttackGroup)
self:F()
local Report=REPORT:New()
for DetectedItemTypeName,DetectedItem in pairs(self.DetectedItems)do
local DetectedItem=DetectedItem
local ReportSummary=self:DetectedItemReportSummary(DetectedItemTypeName,AttackGroup)
Report:SetTitle("Detected types:")
Report:Add(ReportSummary:Text())
end
local ReportText=Report:Text()
return ReportText
end
end
do
DETECTION_AREAS={
ClassName="DETECTION_AREAS",
DetectionZoneRange=nil,
}
function DETECTION_AREAS:New(DetectionSetGroup,DetectionZoneRange)
local self=BASE:Inherit(self,DETECTION_BASE:New(DetectionSetGroup))
self.DetectionZoneRange=DetectionZoneRange
self._SmokeDetectedUnits=false
self._FlareDetectedUnits=false
self._SmokeDetectedZones=false
self._FlareDetectedZones=false
self._BoundDetectedZones=false
return self
end
function DETECTION_AREAS:DetectedItemMenu(Index,AttackGroup)
self:F(Index)
local DetectedItem=self:GetDetectedItem(Index)
local DetectedItemID=self:GetDetectedItemID(Index)
if DetectedItem then
local DetectedSet=self:GetDetectedSet(Index)
local ReportSummaryItem
local DetectedZone=self:GetDetectedItemZone(Index)
local DetectedItemCoordinate=DetectedZone:GetCoordinate()
local DetectedItemCoordText=DetectedItemCoordinate:ToString(AttackGroup)
local ReportSummary=string.format(
"%s - %s",
DetectedItemID,
DetectedItemCoordText
)
return ReportSummary
end
return nil
end
function DETECTION_AREAS:DetectedItemReportSummary(Index,AttackGroup,Settings)
self:F(Index)
local DetectedItem=self:GetDetectedItem(Index)
local DetectedItemID=self:GetDetectedItemID(Index)
if DetectedItem then
local DetectedSet=self:GetDetectedSet(Index)
local ReportSummaryItem
local DetectedZone=self:GetDetectedItemZone(Index)
local DetectedItemCoordinate=DetectedZone:GetCoordinate()
local DetectedItemCoordText=DetectedItemCoordinate:ToString(AttackGroup,Settings)
local ThreatLevelA2G=self:GetDetectedItemThreatLevel(Index)
local DetectedItemsCount=DetectedSet:Count()
local DetectedItemsTypes=DetectedSet:GetTypeNames()
local Report=REPORT:New()
Report:Add(DetectedItemID..", "..DetectedItemCoordText)
Report:Add(string.format("Threat: [%s]",string.rep("■",ThreatLevelA2G)))
Report:Add(string.format("Type: %2d of %s",DetectedItemsCount,DetectedItemsTypes))
return Report
end
return nil
end
function DETECTION_AREAS:DetectedReportDetailed(AttackGroup)
self:F()
local Report=REPORT:New()
for DetectedItemIndex,DetectedItem in pairs(self.DetectedItems)do
local DetectedItem=DetectedItem
local ReportSummary=self:DetectedItemReportSummary(DetectedItemIndex,AttackGroup)
Report:SetTitle("Detected areas:")
Report:Add(ReportSummary:Text())
end
local ReportText=Report:Text()
return ReportText
end
function DETECTION_AREAS:CalculateIntercept(DetectedItem)
local DetectedCoord=DetectedItem.Coordinate
local DetectedSpeed=DetectedCoord:GetVelocity()
local DetectedHeading=DetectedCoord:GetHeading()
if self.Intercept then
local DetectedSet=DetectedItem.Set
local TranslateDistance=DetectedSpeed*self.InterceptDelay
local InterceptCoord=DetectedCoord:Translate(TranslateDistance,DetectedHeading)
DetectedItem.InterceptCoord=InterceptCoord
else
DetectedItem.InterceptCoord=DetectedCoord
end
end
function DETECTION_AREAS:NearestFAC(DetectedItem)
local NearestRecce=nil
local DistanceRecce=1000000000
for RecceGroupName,RecceGroup in pairs(self.DetectionSetGroup:GetSet())do
if RecceGroup and RecceGroup:IsAlive()then
for RecceUnit,RecceUnit in pairs(RecceGroup:GetUnits())do
if RecceUnit:IsActive()then
local RecceUnitCoord=RecceUnit:GetCoordinate()
local Distance=RecceUnitCoord:Get2DDistance(self:GetDetectedItemCoordinate(DetectedItem.Index))
if Distance<DistanceRecce then
DistanceRecce=Distance
NearestRecce=RecceUnit
end
end
end
end
end
DetectedItem.NearestFAC=NearestRecce
DetectedItem.DistanceRecce=DistanceRecce
end
function DETECTION_AREAS:SmokeDetectedUnits()
self:F2()
self._SmokeDetectedUnits=true
return self
end
function DETECTION_AREAS:FlareDetectedUnits()
self:F2()
self._FlareDetectedUnits=true
return self
end
function DETECTION_AREAS:SmokeDetectedZones()
self:F2()
self._SmokeDetectedZones=true
return self
end
function DETECTION_AREAS:FlareDetectedZones()
self:F2()
self._FlareDetectedZones=true
return self
end
function DETECTION_AREAS:BoundDetectedZones()
self:F2()
self._BoundDetectedZones=true
return self
end
function DETECTION_AREAS:GetChangeText(DetectedItem)
self:F(DetectedItem)
local MT={}
for ChangeCode,ChangeData in pairs(DetectedItem.Changes)do
if ChangeCode=="AA"then
MT[#MT+1]="Detected new area "..ChangeData.ID..". The center target is a "..ChangeData.ItemUnitType.."."
end
if ChangeCode=="RAU"then
MT[#MT+1]="Changed area "..ChangeData.ID..". Removed the center target."
end
if ChangeCode=="AAU"then
MT[#MT+1]="Changed area "..ChangeData.ID..". The new center target is a "..ChangeData.ItemUnitType.."."
end
if ChangeCode=="RA"then
MT[#MT+1]="Removed old area "..ChangeData.ID..". No more targets in this area."
end
if ChangeCode=="AU"then
local MTUT={}
for ChangeUnitType,ChangeUnitCount in pairs(ChangeData)do
if ChangeUnitType~="ID"then
MTUT[#MTUT+1]=ChangeUnitCount.." of "..ChangeUnitType
end
end
MT[#MT+1]="Detected for area "..ChangeData.ID.." new target(s) "..table.concat(MTUT,", ").."."
end
if ChangeCode=="RU"then
local MTUT={}
for ChangeUnitType,ChangeUnitCount in pairs(ChangeData)do
if ChangeUnitType~="ID"then
MTUT[#MTUT+1]=ChangeUnitCount.." of "..ChangeUnitType
end
end
MT[#MT+1]="Removed for area "..ChangeData.ID.." invisible or destroyed target(s) "..table.concat(MTUT,", ").."."
end
end
return table.concat(MT,"\n")
end
function DETECTION_AREAS:CreateDetectionItems()
self:F2()
self:T("Checking Detected Items for new Detected Units ...")
for DetectedItemID,DetectedItemData in pairs(self.DetectedItems)do
local DetectedItem=DetectedItemData
if DetectedItem then
self:T({"Detected Item ID:",DetectedItemID})
local DetectedSet=DetectedItem.Set
local AreaExists=false
self:T3({"Zone Center Unit:",DetectedItem.Zone.ZoneUNIT.UnitName})
local DetectedZoneObject=self:GetDetectedObject(DetectedItem.Zone.ZoneUNIT.UnitName)
self:T3({"Detected Zone Object:",DetectedItem.Zone:GetName(),DetectedZoneObject})
if DetectedZoneObject then
AreaExists=true
else
DetectedSet:RemoveUnitsByName(DetectedItem.Zone.ZoneUNIT.UnitName)
self:AddChangeItem(DetectedItem,'RAU',self:GetDetectedUnitTypeName(DetectedItem.Zone.ZoneUNIT))
for DetectedUnitName,DetectedUnitData in pairs(DetectedSet:GetSet())do
local DetectedUnit=DetectedUnitData
local DetectedObject=self:GetDetectedObject(DetectedUnit.UnitName)
local DetectedUnitTypeName=self:GetDetectedUnitTypeName(DetectedUnit)
if DetectedObject then
self:IdentifyDetectedObject(DetectedObject)
AreaExists=true
DetectedItem.Zone=ZONE_UNIT:New(DetectedUnit:GetName(),DetectedUnit,self.DetectionZoneRange)
self:AddChangeItem(DetectedItem,"AAU",DetectedUnitTypeName)
break
else
DetectedSet:Remove(DetectedUnitName)
self:AddChangeUnit(DetectedItem,"RU",DetectedUnitTypeName)
end
end
end
if AreaExists then
for DetectedUnitName,DetectedUnitData in pairs(DetectedSet:GetSet())do
local DetectedUnit=DetectedUnitData
local DetectedUnitTypeName=self:GetDetectedUnitTypeName(DetectedUnit)
local DetectedObject=nil
if DetectedUnit:IsAlive()then
DetectedObject=self:GetDetectedObject(DetectedUnit:GetName())
end
if DetectedObject then
if DetectedUnit:IsInZone(DetectedItem.Zone)then
self:IdentifyDetectedObject(DetectedObject)
else
DetectedSet:Remove(DetectedUnitName)
self:AddChangeUnit(DetectedItem,"RU",DetectedUnitTypeName)
end
else
self:AddChangeUnit(DetectedItem,"RU","destroyed target")
DetectedSet:Remove(DetectedUnitName)
end
end
else
self:RemoveDetectedItem(DetectedItemID)
self:AddChangeItem(DetectedItem,"RA")
end
end
end
for DetectedUnitName,DetectedObjectData in pairs(self.DetectedObjects)do
local DetectedObject=self:GetDetectedObject(DetectedUnitName)
if DetectedObject then
local DetectedUnit=UNIT:FindByName(DetectedUnitName)
local DetectedUnitTypeName=self:GetDetectedUnitTypeName(DetectedUnit)
local AddedToDetectionArea=false
for DetectedItemID,DetectedItemData in pairs(self.DetectedItems)do
local DetectedItem=DetectedItemData
if DetectedItem then
self:T("Detection Area #"..DetectedItem.ID)
local DetectedSet=DetectedItem.Set
if not self:IsDetectedObjectIdentified(DetectedObject)and DetectedUnit:IsInZone(DetectedItem.Zone)then
self:IdentifyDetectedObject(DetectedObject)
DetectedSet:AddUnit(DetectedUnit)
AddedToDetectionArea=true
self:AddChangeUnit(DetectedItem,"AU",DetectedUnitTypeName)
end
end
end
if AddedToDetectionArea==false then
local DetectedItem=self:AddDetectedItemZone(nil,
SET_UNIT:New():FilterDeads():FilterCrashes(),
ZONE_UNIT:New(DetectedUnitName,DetectedUnit,self.DetectionZoneRange)
)
DetectedItem.Set:AddUnit(DetectedUnit)
self:AddChangeItem(DetectedItem,"AA",DetectedUnitTypeName)
end
end
end
for DetectedItemID,DetectedItemData in pairs(self.DetectedItems)do
local DetectedItem=DetectedItemData
local DetectedSet=DetectedItem.Set
local DetectedFirstUnit=DetectedSet:GetFirst()
local DetectedZone=DetectedItem.Zone
local DetectedZoneCoord=DetectedZone:GetCoordinate()
self:SetDetectedItemCoordinate(DetectedItem,DetectedZoneCoord,DetectedFirstUnit)
self:CalculateIntercept(DetectedItem)
self:ReportFriendliesNearBy({DetectedItem=DetectedItem,ReportSetGroup=self.DetectionSetGroup})
self:SetDetectedItemThreatLevel(DetectedItem)
self:NearestFAC(DetectedItem)
if DETECTION_AREAS._SmokeDetectedUnits or self._SmokeDetectedUnits then
DetectedZone.ZoneUNIT:SmokeRed()
end
DetectedSet:ForEachUnit(
function(DetectedUnit)
if DetectedUnit:IsAlive()then
if DETECTION_AREAS._FlareDetectedUnits or self._FlareDetectedUnits then
DetectedUnit:FlareGreen()
end
if DETECTION_AREAS._SmokeDetectedUnits or self._SmokeDetectedUnits then
DetectedUnit:SmokeGreen()
end
end
end
)
if DETECTION_AREAS._FlareDetectedZones or self._FlareDetectedZones then
DetectedZone:FlareZone(SMOKECOLOR.White,30,math.random(0,90))
end
if DETECTION_AREAS._SmokeDetectedZones or self._SmokeDetectedZones then
DetectedZone:SmokeZone(SMOKECOLOR.White,30)
end
if DETECTION_AREAS._BoundDetectedZones or self._BoundDetectedZones then
self.CountryID=DetectedSet:GetFirst():GetCountry()
DetectedZone:BoundZone(12,self.CountryID)
end
end
end
end
do
DESIGNATE={
ClassName="DESIGNATE",
}
function DESIGNATE:New(CC,Detection,AttackSet,Mission)
local self=BASE:Inherit(self,FSM:New())
self:F({Detection})
self:SetStartState("Designating")
self:AddTransition("*","Detect","*")
self:AddTransition("*","LaseOn","Lasing")
self:AddTransition("Lasing","Lasing","Lasing")
self:AddTransition("*","LaseOff","Designate")
self:AddTransition("*","Smoke","*")
self:AddTransition("*","Illuminate","*")
self:AddTransition("*","Done","*")
self:AddTransition("*","Status","*")
self.CC=CC
self.Detection=Detection
self.AttackSet=AttackSet
self.RecceSet=Detection:GetDetectionSetGroup()
self.Recces={}
self.Designating={}
self:SetDesignateName()
self.LaseDuration=60
self:SetFlashStatusMenu(false)
self:SetMission(Mission)
self:SetLaserCodes({1688,1130,4785,6547,1465,4578})
self:SetAutoLase(false,false)
self:SetThreatLevelPrioritization(false)
self:SetMaximumDesignations(5)
self:SetMaximumDistanceDesignations(12000)
self:SetMaximumMarkings(2)
self:SetDesignateMenu()
self.LaserCodesUsed={}
self.MenuLaserCodes={}
self.Detection:__Start(2)
self:__Detect(-15)
self.MarkScheduler=SCHEDULER:New(self)
return self
end
function DESIGNATE:SetFlashStatusMenu(FlashMenu)
self.FlashStatusMenu={}
self.AttackSet:ForEachGroup(
function(AttackGroup)
self.FlashStatusMenu[AttackGroup]=FlashMenu
end
)
return self
end
function DESIGNATE:SetMaximumDesignations(MaximumDesignations)
self.MaximumDesignations=MaximumDesignations
return self
end
function DESIGNATE:SetMaximumDistanceGroundDesignation(MaximumDistanceGroundDesignation)
self.MaximumDistanceGroundDesignation=MaximumDistanceGroundDesignation
return self
end
function DESIGNATE:SetMaximumDistanceAirDesignation(MaximumDistanceAirDesignation)
self.MaximumDistanceAirDesignation=MaximumDistanceAirDesignation
return self
end
function DESIGNATE:SetMaximumDistanceDesignations(MaximumDistanceDesignations)
self.MaximumDistanceDesignations=MaximumDistanceDesignations
return self
end
function DESIGNATE:SetMaximumMarkings(MaximumMarkings)
self.MaximumMarkings=MaximumMarkings
return self
end
function DESIGNATE:SetLaserCodes(LaserCodes)
self.LaserCodes=(type(LaserCodes)=="table")and LaserCodes or{LaserCodes}
self:E({LaserCodes=self.LaserCodes})
self.LaserCodesUsed={}
return self
end
function DESIGNATE:AddMenuLaserCode(LaserCode,MenuText)
self.MenuLaserCodes[LaserCode]=MenuText
self:SetDesignateMenu()
return self
end
function DESIGNATE:RemoveMenuLaserCode(LaserCode)
self.MenuLaserCodes[LaserCode]=nil
self:SetDesignateMenu()
return self
end
function DESIGNATE:SetDesignateName(DesignateName)
self.DesignateName="Designation"..(DesignateName and(" for "..DesignateName)or"")
return self
end
function DESIGNATE:GenerateLaserCodes()
self.LaserCodes={}
local function containsDigit(_number,_numberToFind)
local _thisNumber=_number
local _thisDigit=0
while _thisNumber~=0 do
_thisDigit=_thisNumber%10
_thisNumber=math.floor(_thisNumber/10)
if _thisDigit==_numberToFind then
return true
end
end
return false
end
local _code=1111
local _count=1
while _code<1777 and _count<30 do
while true do
_code=_code+1
if not containsDigit(_code,8)
and not containsDigit(_code,9)
and not containsDigit(_code,0)then
self:T(_code)
table.insert(self.LaserCodes,_code)
break
end
end
_count=_count+1
end
self.LaserCodesUsed={}
return self
end
function DESIGNATE:SetAutoLase(AutoLase,Message)
self.AutoLase=AutoLase or false
if Message then
local AutoLaseOnOff=(self.AutoLase==true)and"On"or"Off"
local CC=self.CC:GetPositionable()
if CC then
CC:MessageToSetGroup(self.DesignateName..": Auto Lase "..AutoLaseOnOff..".",15,self.AttackSet)
end
end
self:CoordinateLase()
self:SetDesignateMenu()
return self
end
function DESIGNATE:SetThreatLevelPrioritization(Prioritize)
self.ThreatLevelPrioritization=Prioritize
return self
end
function DESIGNATE:SetMission(Mission)
self.Mission=Mission
return self
end
function DESIGNATE:onafterDetect()
self:__Detect(-math.random(60))
self:DesignationScope()
self:CoordinateLase()
self:SendStatus()
self:SetDesignateMenu()
return self
end
function DESIGNATE:DesignationScope()
local DetectedItems=self.Detection:GetDetectedItems()
local DetectedItemCount=0
for DesignateIndex,Designating in pairs(self.Designating)do
local DetectedItem=DetectedItems[DesignateIndex]
if DetectedItem then
local IsDetected=self.Detection:IsDetectedItemDetected(DetectedItem)
self:F({IsDetected=IsDetected,DetectedItem})
if IsDetected==false then
self:F("Removing")
self.Designating[DesignateIndex]=nil
self.AttackSet:ForEachGroup(
function(AttackGroup)
local DetectionText=self.Detection:DetectedItemReportSummary(DesignateIndex,AttackGroup):Text(", ")
self.CC:GetPositionable():MessageToGroup("Targets out of LOS\n"..DetectionText,10,AttackGroup,self.DesignateName)
end
)
else
DetectedItemCount=DetectedItemCount+1
end
else
self.Designating[DesignateIndex]=nil
end
end
if DetectedItemCount<5 then
for DesignateIndex,DetectedItem in pairs(DetectedItems)do
local IsDetected=self.Detection:IsDetectedItemDetected(DetectedItem)
if IsDetected==true then
self:F({DistanceRecce=DetectedItem.DistanceRecce})
if DetectedItem.DistanceRecce<=self.MaximumDistanceDesignations then
if self.Designating[DesignateIndex]==nil then
self.AttackSet:ForEachGroup(
function(AttackGroup)
local DetectionText=self.Detection:DetectedItemReportSummary(DesignateIndex,AttackGroup):Text(", ")
self.CC:GetPositionable():MessageToGroup("Targets detected at \n"..DetectionText,10,AttackGroup,self.DesignateName)
end
)
self.Designating[DesignateIndex]=""
break
end
end
end
end
end
return self
end
function DESIGNATE:CoordinateLase()
local DetectedItems=self.Detection:GetDetectedItems()
for DesignateIndex,Designating in pairs(self.Designating)do
local DetectedItem=DetectedItems[DesignateIndex]
if DetectedItem then
if self.AutoLase then
self:LaseOn(DesignateIndex,self.LaseDuration)
end
end
end
return self
end
function DESIGNATE:SendStatus(MenuAttackGroup,Duration)
Duration=Duration or 10
self.AttackSet:ForEachGroup(
function(AttackGroup)
if self.FlashStatusMenu[AttackGroup]or(MenuAttackGroup and(AttackGroup:GetName()==MenuAttackGroup:GetName()))then
local DetectedReport=REPORT:New("Targets ready for Designation:")
local DetectedItems=self.Detection:GetDetectedItems()
for DesignateIndex,Designating in pairs(self.Designating)do
local DetectedItem=DetectedItems[DesignateIndex]
if DetectedItem then
local Report=self.Detection:DetectedItemReportSummary(DesignateIndex,AttackGroup):Text(", ")
DetectedReport:Add(string.rep("-",140))
DetectedReport:Add(" - "..Report)
end
end
local CC=self.CC:GetPositionable()
CC:MessageToGroup(DetectedReport:Text("\n"),Duration,AttackGroup,self.DesignateName)
local DesignationReport=REPORT:New("Marking Targets:\n")
self.RecceSet:ForEachGroup(
function(RecceGroup)
local RecceUnits=RecceGroup:GetUnits()
for UnitID,RecceData in pairs(RecceUnits)do
local Recce=RecceData
if Recce:IsLasing()then
DesignationReport:Add(" - "..Recce:GetMessageText("Marking "..Recce:GetSpot().Target:GetTypeName().." with laser "..Recce:GetSpot().LaserCode.."."))
end
end
end
)
CC:MessageToGroup(DesignationReport:Text(),Duration,AttackGroup,self.DesignateName)
end
end
)
return self
end
function DESIGNATE:SetDesignateMenu()
self.AttackSet:Flush()
self.AttackSet:ForEachGroup(
function(AttackGroup)
self.MenuDesignate=self.MenuDesignate or{}
local MissionMenu=nil
if self.Mission then
MissionMenu=self.Mission:GetRootMenu(AttackGroup)
end
local MenuTime=timer.getTime()
self.MenuDesignate[AttackGroup]=MENU_GROUP:New(AttackGroup,self.DesignateName,MissionMenu):SetTime(MenuTime):SetTag(self.DesignateName)
local MenuDesignate=self.MenuDesignate[AttackGroup]
if self.AutoLase then
MENU_GROUP_COMMAND:New(AttackGroup,"Auto Lase Off",MenuDesignate,self.MenuAutoLase,self,false):SetTime(MenuTime):SetTag(self.DesignateName)
else
MENU_GROUP_COMMAND:New(AttackGroup,"Auto Lase On",MenuDesignate,self.MenuAutoLase,self,true):SetTime(MenuTime):SetTag(self.DesignateName)
end
local StatusMenu=MENU_GROUP:New(AttackGroup,"Status",MenuDesignate):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Report Status 15s",StatusMenu,self.MenuStatus,self,AttackGroup,15):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Report Status 30s",StatusMenu,self.MenuStatus,self,AttackGroup,30):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Report Status 60s",StatusMenu,self.MenuStatus,self,AttackGroup,60):SetTime(MenuTime):SetTag(self.DesignateName)
if self.FlashStatusMenu[AttackGroup]then
MENU_GROUP_COMMAND:New(AttackGroup,"Flash Status Report Off",StatusMenu,self.MenuFlashStatus,self,AttackGroup,false):SetTime(MenuTime):SetTag(self.DesignateName)
else
MENU_GROUP_COMMAND:New(AttackGroup,"Flash Status Report On",StatusMenu,self.MenuFlashStatus,self,AttackGroup,true):SetTime(MenuTime):SetTag(self.DesignateName)
end
for DesignateIndex,Designating in pairs(self.Designating)do
local DetectedItem=self.Detection:GetDetectedItem(DesignateIndex)
if DetectedItem then
local Coord=self.Detection:GetDetectedItemCoordinate(DesignateIndex)
local ID=self.Detection:GetDetectedItemID(DesignateIndex)
local MenuText=ID..", "..Coord:ToStringA2G(AttackGroup)
if Designating==""then
MenuText="(-) "..MenuText
local DetectedMenu=MENU_GROUP:New(AttackGroup,MenuText,MenuDesignate):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Search other target",DetectedMenu,self.MenuForget,self,DesignateIndex):SetTime(MenuTime):SetTag(self.DesignateName)
for LaserCode,MenuText in pairs(self.MenuLaserCodes)do
MENU_GROUP_COMMAND:New(AttackGroup,string.format(MenuText,LaserCode),DetectedMenu,self.MenuLaseCode,self,DesignateIndex,60,LaserCode):SetTime(MenuTime):SetTag(self.DesignateName)
end
MENU_GROUP_COMMAND:New(AttackGroup,"Lase with random laser code(s)",DetectedMenu,self.MenuLaseOn,self,DesignateIndex,60):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Smoke red",DetectedMenu,self.MenuSmoke,self,DesignateIndex,SMOKECOLOR.Red):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Smoke blue",DetectedMenu,self.MenuSmoke,self,DesignateIndex,SMOKECOLOR.Blue):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Smoke green",DetectedMenu,self.MenuSmoke,self,DesignateIndex,SMOKECOLOR.Green):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Smoke white",DetectedMenu,self.MenuSmoke,self,DesignateIndex,SMOKECOLOR.White):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Smoke orange",DetectedMenu,self.MenuSmoke,self,DesignateIndex,SMOKECOLOR.Orange):SetTime(MenuTime):SetTag(self.DesignateName)
MENU_GROUP_COMMAND:New(AttackGroup,"Illuminate",DetectedMenu,self.MenuIlluminate,self,DesignateIndex):SetTime(MenuTime):SetTag(self.DesignateName)
else
if Designating=="Laser"then
MenuText="(L) "..MenuText
elseif Designating=="Smoke"then
MenuText="(S) "..MenuText
elseif Designating=="Illuminate"then
MenuText="(I) "..MenuText
end
local DetectedMenu=MENU_GROUP:New(AttackGroup,MenuText,MenuDesignate):SetTime(MenuTime):SetTag(self.DesignateName)
if Designating=="Laser"then
MENU_GROUP_COMMAND:New(AttackGroup,"Stop lasing",DetectedMenu,self.MenuLaseOff,self,DesignateIndex):SetTime(MenuTime):SetTag(self.DesignateName)
else
end
end
end
end
MenuDesignate:Remove(MenuTime,self.DesignateName)
end
)
return self
end
function DESIGNATE:MenuStatus(AttackGroup,Duration)
self:E("Status")
self:SendStatus(AttackGroup,Duration)
end
function DESIGNATE:MenuFlashStatus(AttackGroup,Flash)
self:E("Flash Status")
self.FlashStatusMenu[AttackGroup]=Flash
self:SetDesignateMenu()
end
function DESIGNATE:MenuForget(Index)
self:E("Forget")
self.Designating[Index]=nil
self:SetDesignateMenu()
end
function DESIGNATE:MenuAutoLase(AutoLase)
self:E("AutoLase")
self:SetAutoLase(AutoLase,true)
end
function DESIGNATE:MenuSmoke(Index,Color)
self:E("Designate through Smoke")
self.Designating[Index]="Smoke"
self:Smoke(Index,Color)
end
function DESIGNATE:MenuIlluminate(Index)
self:E("Designate through Illumination")
self.Designating[Index]="Illuminate"
self:__Illuminate(1,Index)
end
function DESIGNATE:MenuLaseOn(Index,Duration)
self:E("Designate through Lase")
self:__LaseOn(1,Index,Duration)
self:SetDesignateMenu()
end
function DESIGNATE:MenuLaseCode(Index,Duration,LaserCode)
self:E("Designate through Lase using "..LaserCode)
self:__LaseOn(1,Index,Duration,LaserCode)
self:SetDesignateMenu()
end
function DESIGNATE:MenuLaseOff(Index,Duration)
self:E("Lasing off")
self.Designating[Index]=""
self:__LaseOff(1,Index)
self:SetDesignateMenu()
end
function DESIGNATE:onafterLaseOn(From,Event,To,Index,Duration,LaserCode)
self.Designating[Index]="Laser"
self.LaseStart=timer.getTime()
self.LaseDuration=Duration
self:__Lasing(-1,Index,Duration,LaserCode)
end
function DESIGNATE:onafterLasing(From,Event,To,Index,Duration,LaserCodeRequested)
local TargetSetUnit=self.Detection:GetDetectedSet(Index)
local MarkingCount=0
local MarkedTypes={}
local ReportTypes=REPORT:New()
local ReportLaserCodes=REPORT:New()
TargetSetUnit:Flush()
for TargetUnit,RecceData in pairs(self.Recces)do
local Recce=RecceData
self:F({TargetUnit=TargetUnit,Recce=Recce:GetName()})
if not Recce:IsLasing()then
local LaserCode=Recce:GetLaserCode()
self:F({ClearingLaserCode=LaserCode})
self.LaserCodesUsed[LaserCode]=nil
self.Recces[TargetUnit]=nil
end
end
if LaserCodeRequested then
for TargetUnit,RecceData in pairs(self.Recces)do
local Recce=RecceData
self:F({TargetUnit=TargetUnit,Recce=Recce:GetName()})
if Recce:IsLasing()then
Recce:LaseOff()
local LaserCode=Recce:GetLaserCode()
self:F({ClearingLaserCode=LaserCode})
self.LaserCodesUsed[LaserCode]=nil
self.Recces[TargetUnit]=nil
break
end
end
end
if self.AutoLase or(not self.AutoLase and(self.LaseStart+Duration>=timer.getTime()))then
TargetSetUnit:ForEachUnitPerThreatLevel(10,0,
function(TargetUnit)
self:F({TargetUnit=TargetUnit:GetName()})
if MarkingCount<self.MaximumMarkings then
if TargetUnit:IsAlive()then
local Recce=self.Recces[TargetUnit]
if not Recce then
self:E("Lasing...")
self.RecceSet:Flush()
for RecceGroupID,RecceGroup in pairs(self.RecceSet:GetSet())do
for UnitID,UnitData in pairs(RecceGroup:GetUnits()or{})do
local RecceUnit=UnitData
local RecceUnitDesc=RecceUnit:GetDesc()
if RecceUnit:IsLasing()==false then
if RecceUnit:IsDetected(TargetUnit)and RecceUnit:IsLOS(TargetUnit)then
local LaserCodeIndex=math.random(1,#self.LaserCodes)
local LaserCode=self.LaserCodes[LaserCodeIndex]
if LaserCodeRequested and LaserCodeRequested~=LaserCode then
LaserCode=LaserCodeRequested
LaserCodeRequested=nil
end
if not self.LaserCodesUsed[LaserCode]then
self.LaserCodesUsed[LaserCode]=LaserCodeIndex
local Spot=RecceUnit:LaseUnit(TargetUnit,LaserCode,Duration)
local AttackSet=self.AttackSet
function Spot:OnAfterDestroyed(From,Event,To)
self:E("Destroyed Message")
self.Recce:ToSetGroup("Target "..TargetUnit:GetTypeName().." destroyed. "..TargetSetUnit:Count().." targets left.",5,AttackSet,self.DesignateName)
end
self.Recces[TargetUnit]=RecceUnit
RecceUnit:MessageToSetGroup("Marking "..TargetUnit:GetTypeName().." with laser "..RecceUnit:GetSpot().LaserCode.." for "..Duration.."s.",5,self.AttackSet,self.DesignateName)
MarkingCount=MarkingCount+1
local TargetUnitType=TargetUnit:GetTypeName()
if not MarkedTypes[TargetUnitType]then
MarkedTypes[TargetUnitType]=true
ReportTypes:Add(TargetUnitType)
end
ReportLaserCodes:Add(RecceUnit.LaserCode)
return
end
else
end
else
if not RecceUnit:IsDetected(TargetUnit)or not RecceUnit:IsLOS(TargetUnit)then
local Recce=self.Recces[TargetUnit]
if Recce then
Recce:LaseOff()
Recce:MessageToSetGroup("Target "..TargetUnit:GetTypeName()"out of LOS. Cancelling lase!",5,self.AttackSet,self.DesignateName)
end
else
MarkingCount=MarkingCount+1
local TargetUnitType=TargetUnit:GetTypeName()
if not MarkedTypes[TargetUnitType]then
MarkedTypes[TargetUnitType]=true
ReportTypes:Add(TargetUnitType)
end
ReportLaserCodes:Add(RecceUnit.LaserCode)
end
end
end
end
else
MarkingCount=MarkingCount+1
local TargetUnitType=TargetUnit:GetTypeName()
if not MarkedTypes[TargetUnitType]then
MarkedTypes[TargetUnitType]=true
ReportTypes:Add(TargetUnitType)
end
ReportLaserCodes:Add(Recce.LaserCode)
end
end
end
end
)
local MarkedTypesText=ReportTypes:Text(', ')
local MarkedLaserCodesText=ReportLaserCodes:Text(', ')
for MarkedType,MarketCount in pairs(MarkedTypes)do
self.CC:GetPositionable():MessageToSetGroup("Marking "..MarkingCount.." x "..MarkedTypesText.." with lasers "..MarkedLaserCodesText..".",5,self.AttackSet,self.DesignateName)
end
self:__Lasing(-30,Index,Duration,LaserCodeRequested)
self:SetDesignateMenu()
else
self:__LaseOff(1)
end
end
function DESIGNATE:onafterLaseOff(From,Event,To,Index)
local CC=self.CC:GetPositionable()
if CC then
CC:MessageToSetGroup("Stopped lasing.",5,self.AttackSet,self.DesignateName)
end
local TargetSetUnit=self.Detection:GetDetectedSet(Index)
local Recces=self.Recces
for TargetID,RecceData in pairs(Recces)do
local Recce=RecceData
Recce:MessageToSetGroup("Stopped lasing "..Recce:GetSpot().Target:GetTypeName()..".",5,self.AttackSet,self.DesignateName)
Recce:LaseOff()
end
Recces=nil
self.Recces={}
self.LaserCodesUsed={}
self:SetDesignateMenu()
end
function DESIGNATE:onafterSmoke(From,Event,To,Index,Color)
local TargetSetUnit=self.Detection:GetDetectedSet(Index)
local TargetSetUnitCount=TargetSetUnit:Count()
local MarkedCount=0
TargetSetUnit:ForEachUnitPerThreatLevel(10,0,
function(SmokeUnit)
if MarkedCount<self.MaximumMarkings then
MarkedCount=MarkedCount+1
self:E("Smoking ...")
local RecceGroup=self.RecceSet:FindNearestGroupFromPointVec2(SmokeUnit:GetPointVec2())
local RecceUnit=RecceGroup:GetUnit(1)
if RecceUnit then
RecceUnit:MessageToSetGroup("Smoking "..SmokeUnit:GetTypeName()..".",5,self.AttackSet,self.DesignateName)
self.MarkScheduler:Schedule(self,
function()
if SmokeUnit:IsAlive()then
SmokeUnit:Smoke(Color,50,2)
end
self:Done(Index)
end,{},math.random(5,20)
)
end
end
end
)
end
function DESIGNATE:onafterIlluminate(From,Event,To,Index)
local TargetSetUnit=self.Detection:GetDetectedSet(Index)
local TargetUnit=TargetSetUnit:GetFirst()
if TargetUnit then
local RecceGroup=self.RecceSet:FindNearestGroupFromPointVec2(TargetUnit:GetPointVec2())
local RecceUnit=RecceGroup:GetUnit(1)
if RecceUnit then
RecceUnit:MessageToSetGroup("Illuminating "..TargetUnit:GetTypeName()..".",5,self.AttackSet,self.DesignateName)
self.MarkScheduler:Schedule(self,
function()
if TargetUnit:IsAlive()then
TargetUnit:GetPointVec3():AddY(300):IlluminationBomb()
end
self:Done(Index)
end,{},math.random(5,20)
)
end
end
end
function DESIGNATE:onafterDone(From,Event,To,Index)
self.Designating[Index]=nil
self:SetDesignateMenu()
end
end
RAT={
ClassName="RAT",
debug=false,
templategroup=nil,
alias=nil,
spawninitialized=false,
spawndelay=5,
spawninterval=5,
coalition=nil,
country=nil,
category=nil,
friendly="same",
ctable={},
aircraft={},
Vcruisemax=nil,
Vclimb=1500,
AlphaDescent=3.6,
roe="hold",
rot="noreaction",
takeoff=0,
landing=9,
mindist=5000,
maxdist=5000000,
airports_map={},
airports={},
random_departure=true,
random_destination=true,
departure_ports={},
destination_ports={},
Ndestination_Airports=0,
Ndestination_Zones=0,
Ndeparture_Airports=0,
Ndeparture_Zones=0,
destinationzone=false,
return_zones={},
returnzone=false,
excluded_ports={},
departure_Azone=nil,
destination_Azone=nil,
addfriendlydepartures=false,
addfriendlydestinations=false,
ratcraft={},
Tinactive=600,
reportstatus=false,
statusinterval=30,
placemarkers=false,
FLcruise=nil,
FLminuser=nil,
FLmaxuser=nil,
FLuser=nil,
commute=false,
continuejourney=false,
alive=0,
ngroups=nil,
f10menu=true,
Menu={},
SubMenuName=nil,
respawn_at_landing=false,
norespawn=false,
respawn_after_takeoff=false,
respawn_delay=nil,
markerids={},
waypointdescriptions={},
waypointstatus={},
livery=nil,
skill="High",
ATCswitch=true,
parking_id=nil,
radio=nil,
frequency=nil,
modulation=nil,
actype=nil,
uncontrolled=false,
}
RAT.cat={
plane="plane",
heli="heli",
}
RAT.wp={
coldorhot=0,
air=1,
runway=2,
hot=3,
cold=4,
climb=5,
cruise=6,
descent=7,
holding=8,
landing=9,
finalwp=10,
}
RAT.status={
Departure="At departure point",
Climb="Climbing",
Cruise="Cruising",
Uturn="Flying back home",
Descent="Descending",
DescentHolding="Descend to holding point",
Holding="Holding",
Destination="Arrived at destination",
EventBirthAir="Born in air",
EventBirth="Ready and starting engines",
EventEngineStartAir="On journey",
EventEngineStart="Started engines and taxiing",
EventTakeoff="Airborne after take-off",
EventLand="Landed and taxiing",
EventEngineShutdown="Engines off",
EventDead="Dead",
EventCrash="Crashed",
}
RAT.coal={
same="same",
sameonly="sameonly",
neutral="neutral",
}
RAT.unit={
ft2meter=0.305,
kmh2ms=0.278,
FL2m=30.48,
nm2km=1.852,
nm2m=1852,
}
RAT.ROE={
weaponhold="hold",
weaponfree="free",
returnfire="return",
}
RAT.ROT={
evade="evade",
passive="passive",
noreaction="noreaction",
}
RAT.ATC={
init=false,
flight={},
airport={},
unregistered=-1,
onfinal=-100,
Nclearance=2,
delay=240,
}
RAT.markerid=0
RAT.MenuF10=nil
RAT.id="RAT | "
RAT.version="2.0.1"
function RAT:New(groupname,alias)
env.info(RAT.id.."Version "..RAT.version)
env.info(RAT.id.."Creating new RAT object from template: "..groupname)
alias=alias or groupname
local self=BASE:Inherit(self,SPAWN:NewWithAlias(groupname,alias))
self.alias=alias
local DCSgroup=Group.getByName(groupname)
if DCSgroup==nil then
env.error(RAT.id.."Group with name "..groupname.." does not exist in the mission editor!")
return nil
end
self.templategroup=GROUP:FindByName(groupname)
self.coalition=DCSgroup:getCoalition()
self:_InitAircraft(DCSgroup)
self:_GetAirportsOfMap()
return self
end
function RAT:Spawn(naircraft)
if self.spawninitialized==true then
env.error("Spawn function should only be called once per RAT object! Exiting and returning nil.")
return nil
else
self.spawninitialized=true
end
self.ngroups=naircraft or 1
if self.ATCswitch and not RAT.ATC.init then
RAT:_ATCInit(self.airports_map)
end
if self.f10menu and not RAT.MenuF10 then
RAT.MenuF10=MENU_MISSION:New("RAT")
end
self:_SetCoalitionTable()
self:_GetAirportsOfCoalition()
if not self.SubMenuName then
self.SubMenuName=self.alias
end
if self.departure_Azone~=nil then
self.departure_ports=self:_GetAirportsInZone(self.departure_Azone)
end
if self.destination_Azone~=nil then
self.destination_ports=self:_GetAirportsInZone(self.destination_Azone)
end
if self.addfriendlydepartures then
self:_AddFriendlyAirports(self.departure_ports)
end
if self.addfriendlydestinations then
self:_AddFriendlyAirports(self.destination_ports)
end
if self.FLcruise==nil then
if self.category==RAT.cat.plane then
self.FLcruise=200*RAT.unit.FL2m
else
self.FLcruise=005*RAT.unit.FL2m
end
end
self:_CheckConsistency()
local text=string.format("\n******************************************************\n")
text=text..string.format("Spawning %i aircraft from template %s of type %s.\n",self.ngroups,self.SpawnTemplatePrefix,self.aircraft.type)
text=text..string.format("Alias: %s\n",self.alias)
text=text..string.format("Category: %s\n",self.category)
text=text..string.format("Friendly coalitions: %s\n",self.friendly)
text=text..string.format("Number of airports on map  : %i\n",#self.airports_map)
text=text..string.format("Number of friendly airports: %i\n",#self.airports)
text=text..string.format("Totally random departure: %s\n",tostring(self.random_departure))
if not self.random_departure then
text=text..string.format("Number of departure airports: %d\n",self.Ndeparture_Airports)
text=text..string.format("Number of departure zones   : %d\n",self.Ndeparture_Zones)
end
text=text..string.format("Totally random destination: %s\n",tostring(self.random_destination))
if not self.random_destination then
text=text..string.format("Number of destination airports: %d\n",self.Ndestination_Airports)
text=text..string.format("Number of destination zones   : %d\n",self.Ndestination_Zones)
end
text=text..string.format("Min dist to destination: %4.1f\n",self.mindist)
text=text..string.format("Max dist to destination: %4.1f\n",self.maxdist)
text=text..string.format("Takeoff type: %i\n",self.takeoff)
text=text..string.format("Landing type: %i\n",self.landing)
text=text..string.format("Commute: %s\n",tostring(self.commute))
text=text..string.format("Journey: %s\n",tostring(self.continuejourney))
text=text..string.format("Destination Zone: %s\n",tostring(self.destinationzone))
text=text..string.format("Return Zone: %s\n",tostring(self.returnzone))
text=text..string.format("Uncontrolled: %s\n",tostring(self.uncontrolled))
text=text..string.format("Spawn delay: %4.1f\n",self.spawndelay)
text=text..string.format("Spawn interval: %4.1f\n",self.spawninterval)
text=text..string.format("Respawn after landing: %s\n",tostring(self.respawn_at_landing))
text=text..string.format("Respawning off: %s\n",tostring(self.norespawn))
text=text..string.format("Respawn after take-off: %s\n",tostring(self.respawn_after_takeoff))
text=text..string.format("Respawn delay: %s\n",tostring(self.respawn_delay))
text=text..string.format("ROE: %s\n",tostring(self.roe))
text=text..string.format("ROT: %s\n",tostring(self.rot))
text=text..string.format("Vclimb: %4.1f\n",self.Vclimb)
text=text..string.format("AlphaDescent: %4.2f\n",self.AlphaDescent)
text=text..string.format("Vcruisemax: %s\n",tostring(self.Vcruisemax))
text=text..string.format("FLcruise =  %6.1f km = FL%3.0f\n",self.FLcruise/1000,self.FLcruise/RAT.unit.FL2m)
text=text..string.format("FLuser: %s\n",tostring(self.Fluser))
text=text..string.format("FLminuser: %s\n",tostring(self.FLminuser))
text=text..string.format("FLmaxuser: %s\n",tostring(self.FLmaxuser))
text=text..string.format("Place markers: %s\n",tostring(self.placemarkers))
text=text..string.format("Report status: %s\n",tostring(self.reportstatus))
text=text..string.format("Status interval: %4.1f\n",self.statusinterval)
text=text..string.format("Time inactive: %4.1f\n",self.Tinactive)
text=text..string.format("Create F10 menu : %s\n",tostring(self.f10menu))
text=text..string.format("F10 submenu name: %s\n",self.SubMenuName)
text=text..string.format("ATC enabled : %s\n",tostring(self.ATCswitch))
text=text..string.format("Radio comms      : %s\n",tostring(self.radio))
text=text..string.format("Radio frequency  : %s\n",tostring(self.frequency))
text=text..string.format("Radio modulation : %s\n",tostring(self.frequency))
if self.livery then
text=text..string.format("Available liveries:\n")
for _,livery in pairs(self.livery)do
text=text..string.format("- %s\n",livery)
end
end
text=text..string.format("******************************************************\n")
env.info(RAT.id..text)
if self.f10menu then
self.Menu[self.SubMenuName]=MENU_MISSION:New(self.SubMenuName,RAT.MenuF10)
self.Menu[self.SubMenuName]["groups"]=MENU_MISSION:New("Groups",self.Menu[self.SubMenuName])
MENU_MISSION_COMMAND:New("Spawn new group",self.Menu[self.SubMenuName],self._SpawnWithRoute,self)
MENU_MISSION_COMMAND:New("Delete markers",self.Menu[self.SubMenuName],self._DeleteMarkers,self)
MENU_MISSION_COMMAND:New("Status report",self.Menu[self.SubMenuName],self.Status,self,true)
end
local Tstart=self.spawndelay
local dt=self.spawninterval
if self.takeoff==RAT.wp.runway and not self.random_departure then
dt=math.max(dt,180)
end
local Tstop=Tstart+dt*(self.ngroups-1)
SCHEDULER:New(nil,self._SpawnWithRoute,{self},Tstart,dt,0.0,Tstop)
SCHEDULER:New(nil,self.Status,{self},Tstart+1,self.statusinterval)
self:HandleEvent(EVENTS.Birth,self._OnBirth)
self:HandleEvent(EVENTS.EngineStartup,self._EngineStartup)
self:HandleEvent(EVENTS.Takeoff,self._OnTakeoff)
self:HandleEvent(EVENTS.Land,self._OnLand)
self:HandleEvent(EVENTS.EngineShutdown,self._OnEngineShutdown)
self:HandleEvent(EVENTS.Dead,self._OnDead)
self:HandleEvent(EVENTS.Crash,self._OnCrash)
end
function RAT:_CheckConsistency()
if not self.random_departure then
for _,name in pairs(self.departure_ports)do
if self:_AirportExists(name)then
self.Ndeparture_Airports=self.Ndeparture_Airports+1
elseif self:_ZoneExists(name)then
self.Ndeparture_Zones=self.Ndeparture_Zones+1
end
end
if self.Ndeparture_Zones>0 and self.takeoff~=RAT.wp.air then
self.takeoff=RAT.wp.air
env.error(RAT.id.."At least one zone defined as departure and takeoff is NOT set to air. Enabling air start!")
end
if self.Ndeparture_Airports==0 and self.Ndeparture_Zone==0 then
self.random_departure=true
local text="No airports or zones found given in SetDeparture(). Enabling random departure airports!"
env.error(RAT.id..text)
MESSAGE:New(text,30):ToAll()
end
end
if not self.random_destination then
for _,name in pairs(self.destination_ports)do
if self:_AirportExists(name)then
self.Ndestination_Airports=self.Ndestination_Airports+1
elseif self:_ZoneExists(name)then
self.Ndestination_Zones=self.Ndestination_Zones+1
end
end
if self.Ndestination_Zones>0 and self.landing~=RAT.wp.air and not self.returnzone then
self.landing=RAT.wp.air
self.destinationzone=true
env.error(RAT.id.."At least one zone defined as destination and landing is NOT set to air. Enabling destination zone!")
end
if self.Ndestination_Airports==0 and self.Ndestination_Zones==0 then
self.random_destination=true
local text="No airports or zones found given in SetDestination(). Enabling random destination airports!"
env.error(RAT.id..text)
MESSAGE:New(text,30):ToAll()
end
end
if self.destinationzone and self.returnzone then
env.error(RAT.id.."Destination zone _and_ return to zone not possible! Disabling return to zone.")
self.returnzone=false
end
if self.returnzone and self.takeoff==RAT.wp.air then
self.landing=RAT.wp.air
end
if self.FLminuser then
self.FLminuser=math.min(self.FLminuser,self.aircraft.ceiling)
end
if self.FLmaxuser then
self.FLmaxuser=math.min(self.FLmaxuser,self.aircraft.ceiling)
end
if self.FLcruise then
self.FLcruise=math.min(self.FLcruise,self.aircraft.ceiling)
end
if self.FLminuser and self.FLmaxuser then
if self.FLminuser>self.FLmaxuser then
local min=self.FLminuser
local max=self.FLmaxuser
self.FLminuser=max
self.FLmaxuser=min
end
end
if self.FLminuser and self.FLcruise<self.FLminuser then
self.FLcruise=self.FLminuser
end
if self.FLmaxuser and self.FLcruise>self.FLmaxuser then
self.FLcruise=self.FLmaxuser
end
if self.uncontrolled then
self.takeoff=RAT.wp.hot
end
end
function RAT:SetCoalition(friendly)
if friendly:lower()=="sameonly"then
self.friendly=RAT.coal.sameonly
elseif friendly:lower()=="neutral"then
self.friendly=RAT.coal.neutral
else
self.friendly=RAT.coal.same
end
end
function RAT:SetCoalitionAircraft(color)
if color:lower()=="blue"then
self.coalition=coalition.side.BLUE
if not self.country then
self.country=country.id.USA
end
elseif color:lower()=="red"then
self.coalition=coalition.side.RED
if not self.country then
self.country=country.id.RUSSIA
end
elseif color:lower()=="neutral"then
self.coalition=coalition.side.NEUTRAL
end
end
function RAT:SetCountry(id)
self.country=id
end
function RAT:SetTakeoff(type)
local _Type
if type:lower()=="takeoff-cold"or type:lower()=="cold"then
_Type=RAT.wp.cold
elseif type:lower()=="takeoff-hot"or type:lower()=="hot"then
_Type=RAT.wp.hot
elseif type:lower()=="takeoff-runway"or type:lower()=="runway"then
_Type=RAT.wp.runway
elseif type:lower()=="air"then
_Type=RAT.wp.air
else
_Type=RAT.wp.coldorhot
end
self.takeoff=_Type
end
function RAT:SetDeparture(departurenames)
self.random_departure=false
local names
if type(departurenames)=="table"then
names=departurenames
elseif type(departurenames)=="string"then
names={departurenames}
else
env.error(RAT.id.."Input parameter must be a string or a table in SetDeparture()!")
end
for _,name in pairs(names)do
if self:_AirportExists(name)then
table.insert(self.departure_ports,name)
elseif self:_ZoneExists(name)then
table.insert(self.departure_ports,name)
else
env.error(RAT.id.."ERROR! No departure airport or zone found with name "..name)
end
end
end
function RAT:SetDestination(destinationnames)
self.random_destination=false
local names
if type(destinationnames)=="table"then
names=destinationnames
elseif type(destinationnames)=="string"then
names={destinationnames}
else
env.error(RAT.id.."Input parameter must be a string or a table in SetDestination()!")
end
for _,name in pairs(names)do
if self:_AirportExists(name)then
table.insert(self.destination_ports,name)
elseif self:_ZoneExists(name)then
table.insert(self.destination_ports,name)
else
env.error(RAT.id.."ERROR! No destination airport or zone found with name "..name)
end
end
end
function RAT:DestinationZone()
self.destinationzone=true
self.landing=RAT.wp.air
end
function RAT:ReturnZone()
self.returnzone=true
end
function RAT:SetDestinationsFromZone(zone)
self.random_destination=false
self.destination_Azone=zone
end
function RAT:SetDeparturesFromZone(zone)
self.random_departure=false
self.departure_Azone=zone
end
function RAT:AddFriendlyAirportsToDepartures()
self.addfriendlydepartures=true
end
function RAT:AddFriendlyAirportsToDestinations()
self.addfriendlydestinations=true
end
function RAT:ExcludedAirports(ports)
if type(ports)=="string"then
self.excluded_ports={ports}
else
self.excluded_ports=ports
end
end
function RAT:SetAISkill(skill)
if skill:lower()=="average"then
self.skill="Average"
elseif skill:lower()=="good"then
self.skill="Good"
elseif skill:lower()=="excellent"then
self.skill="Excellent"
elseif skill:lower()=="random"then
self.skill="Random"
else
self.skill="High"
end
end
function RAT:Livery(skins)
if type(skins)=="string"then
self.livery={skins}
else
self.livery=skins
end
end
function RAT:ChangeAircraft(actype)
self.actype=actype
end
function RAT:ContinueJourney()
self.continuejourney=true
self.commute=false
end
function RAT:Commute()
self.commute=true
self.continuejourney=false
end
function RAT:SetSpawnDelay(delay)
delay=delay or 5
self.spawndelay=math.max(0.5,delay)
end
function RAT:SetSpawnInterval(interval)
interval=interval or 5
self.spawninterval=math.max(0.5,interval)
end
function RAT:RespawnAfterLanding(delay)
delay=delay or 180
self.respawn_at_landing=true
delay=math.max(0.5,delay)
self.respawn_delay=delay
end
function RAT:NoRespawn()
self.norespawn=true
end
function RAT:RespawnAfterTakeoff()
self.respawn_after_takeoff=true
end
function RAT:SetParkingID(id)
self.parking_id=id
env.info(RAT.id.."Setting parking ID to "..self.parking_id)
end
function RAT:RadioON()
self.radio=true
end
function RAT:RadioOFF()
self.radio=false
end
function RAT:RadioFrequency(frequency)
self.frequency=frequency
end
function RAT:Uncontrolled()
self.uncontrolled=true
end
function RAT:RadioModulation(modulation)
if modulation=="AM"then
self.modulation=radio.modulation.AM
elseif modulation=="FM"then
self.modulation=radio.modulation.FM
else
self.modulation=radio.modulation.AM
end
end
function RAT:TimeDestroyInactive(time)
time=time or self.Tinactive
time=math.max(time,60)
self.Tinactive=time
end
function RAT:SetMaxCruiseSpeed(speed)
self.Vcruisemax=speed/3.6
end
function RAT:SetClimbRate(rate)
rate=rate or self.Vclimb
rate=math.max(rate,100)
rate=math.min(rate,15000)
self.Vclimb=rate
end
function RAT:SetDescentAngle(angle)
angle=angle or self.AlphaDescent
angle=math.max(angle,0.5)
angle=math.min(angle,50)
self.AlphaDescent=angle
end
function RAT:SetROE(roe)
if roe=="return"then
self.roe=RAT.ROE.returnfire
elseif roe=="free"then
self.roe=RAT.ROE.weaponfree
else
self.roe=RAT.ROE.weaponhold
end
end
function RAT:SetROT(rot)
if rot=="passive"then
self.rot=RAT.ROT.passive
elseif rot=="evade"then
self.rot=RAT.ROT.evade
else
self.rot=RAT.ROT.noreaction
end
end
function RAT:MenuName(name)
self.SubMenuName=tostring(name)
end
function RAT:EnableATC(switch)
if switch==nil then
switch=true
end
self.ATCswitch=switch
end
function RAT:ATC_Clearance(n)
RAT.ATC.Nclearance=n or 2
end
function RAT:ATC_Delay(time)
RAT.ATC.delay=time or 240
end
function RAT:SetMinDistance(dist)
self.mindist=math.max(500,dist*1000)
end
function RAT:SetMaxDistance(dist)
self.maxdist=dist*1000
end
function RAT:_Debug(switch)
if switch==nil then
switch=true
end
self.debug=switch
end
function RAT:StatusReports(switch)
if switch==nil then
switch=true
end
self.reportstatus=switch
end
function RAT:PlaceMarkers(switch)
if switch==nil then
switch=true
end
self.placemarkers=switch
end
function RAT:SetFL(FL)
FL=FL or self.FLcruise
FL=math.max(FL,0)
self.FLuser=FL*RAT.unit.FL2m
end
function RAT:SetFLmax(FL)
self.FLmaxuser=FL*RAT.unit.FL2m
end
function RAT:SetMaxCruiseAltitude(alt)
self.FLmaxuser=alt
end
function RAT:SetFLmin(FL)
self.FLminuser=FL*RAT.unit.FL2m
end
function RAT:SetMinCruiseAltitude(alt)
self.FLminuser=alt
end
function RAT:SetFLcruise(FL)
self.FLcruise=FL*RAT.unit.FL2m
end
function RAT:SetCruiseAltitude(alt)
self.FLcruise=alt
end
function RAT:_InitAircraft(DCSgroup)
local DCSunit=DCSgroup:getUnit(1)
local DCSdesc=DCSunit:getDesc()
local DCScategory=DCSgroup:getCategory()
local DCStype=DCSunit:getTypeName()
if self.debug then
self:E({"DCSdesc",DCSdesc})
end
if DCScategory==Group.Category.AIRPLANE then
self.category=RAT.cat.plane
elseif DCScategory==Group.Category.HELICOPTER then
self.category=RAT.cat.heli
else
self.category="other"
env.error(RAT.id.."Group of RAT is neither airplane nor helicopter!")
end
self.aircraft.type=DCStype
self.aircraft.fuel=DCSunit:getFuel()
self.aircraft.Rmax=DCSdesc.range*RAT.unit.nm2m
self.aircraft.Reff=self.aircraft.Rmax*self.aircraft.fuel*0.95
self.aircraft.Vmax=DCSdesc.speedMax
self.aircraft.Vymax=DCSdesc.VyMax
self.aircraft.ceiling=DCSdesc.Hmax
local text=string.format("\n******************************************************\n")
text=text..string.format("Aircraft parameters:\n")
text=text..string.format("Template group  =  %s\n",self.SpawnTemplatePrefix)
text=text..string.format("Alias           =  %s\n",self.alias)
text=text..string.format("Category        =  %s\n",self.category)
text=text..string.format("Type            =  %s\n",self.aircraft.type)
text=text..string.format("Max air speed   = %6.1f m/s\n",self.aircraft.Vmax)
text=text..string.format("Max climb speed = %6.1f m/s\n",self.aircraft.Vymax)
text=text..string.format("Initial Fuel    = %6.1f\n",self.aircraft.fuel*100)
text=text..string.format("Max range       = %6.1f km\n",self.aircraft.Rmax/1000)
text=text..string.format("Eff range       = %6.1f km (with 95 percent initial fuel amount)\n",self.aircraft.Reff/1000)
text=text..string.format("Ceiling         = %6.1f km = FL%3.0f\n",self.aircraft.ceiling/1000,self.aircraft.ceiling/RAT.unit.FL2m)
text=text..string.format("******************************************************\n")
env.info(RAT.id..text)
end
function RAT:_SpawnWithRoute(_departure,_destination,_takeoff,_landing,_livery,_waypoint)
local takeoff=self.takeoff
local landing=self.landing
if _takeoff then
takeoff=_takeoff
end
if _landing then
landing=_landing
end
if takeoff==RAT.wp.coldorhot then
local temp={RAT.wp.cold,RAT.wp.hot}
takeoff=temp[math.random(2)]
end
local departure,destination,waypoints,WPholding,WPfinal=self:_SetRoute(takeoff,landing,_departure,_destination,_waypoint)
if not(departure and destination and waypoints)then
return nil
end
local livery
if _livery then
livery=_livery
elseif self.livery then
livery=self.livery[math.random(#self.livery)]
local text=string.format("Chosen livery for group %s: %s",self:_AnticipatedGroupName(),livery)
env.info(RAT.id..text)
else
livery=nil
end
self:_ModifySpawnTemplate(waypoints,livery)
local group=self:SpawnWithIndex(self.SpawnIndex)
self.alive=self.alive+1
if self.ATCswitch and landing==RAT.wp.landing then
if self.returnzone then
RAT:_ATCAddFlight(group:GetName(),departure:GetName())
else
RAT:_ATCAddFlight(group:GetName(),destination:GetName())
end
end
if self.placemarkers then
self:_PlaceMarkers(waypoints,self.SpawnIndex)
end
self:_SetROE(group,self.roe)
self:_SetROT(group,self.rot)
self.ratcraft[self.SpawnIndex]={}
self.ratcraft[self.SpawnIndex]["group"]=group
self.ratcraft[self.SpawnIndex]["destination"]=destination
self.ratcraft[self.SpawnIndex]["departure"]=departure
self.ratcraft[self.SpawnIndex]["waypoints"]=waypoints
self.ratcraft[self.SpawnIndex]["status"]="spawned"
self.ratcraft[self.SpawnIndex]["airborne"]=group:InAir()
if group:InAir()then
self.ratcraft[self.SpawnIndex]["Tground"]=nil
self.ratcraft[self.SpawnIndex]["Pground"]=nil
self.ratcraft[self.SpawnIndex]["Tlastcheck"]=nil
else
self.ratcraft[self.SpawnIndex]["Tground"]=timer.getTime()
self.ratcraft[self.SpawnIndex]["Pground"]=group:GetCoordinate()
self.ratcraft[self.SpawnIndex]["Tlastcheck"]=timer.getTime()
end
self.ratcraft[self.SpawnIndex]["P0"]=group:GetCoordinate()
self.ratcraft[self.SpawnIndex]["Pnow"]=group:GetCoordinate()
self.ratcraft[self.SpawnIndex]["Distance"]=0
self.ratcraft[self.SpawnIndex].takeoff=takeoff
self.ratcraft[self.SpawnIndex].landing=landing
self.ratcraft[self.SpawnIndex].wpholding=WPholding
self.ratcraft[self.SpawnIndex].wpfinal=WPfinal
self.ratcraft[self.SpawnIndex].livery=livery
self.ratcraft[self.SpawnIndex].despawnme=false
if self.f10menu then
local name=self.aircraft.type.." ID "..tostring(self.SpawnIndex)
self.Menu[self.SubMenuName].groups[self.SpawnIndex]=MENU_MISSION:New(name,self.Menu[self.SubMenuName].groups)
self.Menu[self.SubMenuName].groups[self.SpawnIndex]["roe"]=MENU_MISSION:New("Set ROE",self.Menu[self.SubMenuName].groups[self.SpawnIndex])
MENU_MISSION_COMMAND:New("Weapons hold",self.Menu[self.SubMenuName].groups[self.SpawnIndex]["roe"],self._SetROE,self,group,RAT.ROE.weaponhold)
MENU_MISSION_COMMAND:New("Weapons free",self.Menu[self.SubMenuName].groups[self.SpawnIndex]["roe"],self._SetROE,self,group,RAT.ROE.weaponfree)
MENU_MISSION_COMMAND:New("Return fire",self.Menu[self.SubMenuName].groups[self.SpawnIndex]["roe"],self._SetROE,self,group,RAT.ROE.returnfire)
self.Menu[self.SubMenuName].groups[self.SpawnIndex]["rot"]=MENU_MISSION:New("Set ROT",self.Menu[self.SubMenuName].groups[self.SpawnIndex])
MENU_MISSION_COMMAND:New("No reaction",self.Menu[self.SubMenuName].groups[self.SpawnIndex]["rot"],self._SetROT,self,group,RAT.ROT.noreaction)
MENU_MISSION_COMMAND:New("Passive defense",self.Menu[self.SubMenuName].groups[self.SpawnIndex]["rot"],self._SetROT,self,group,RAT.ROT.passive)
MENU_MISSION_COMMAND:New("Evade on fire",self.Menu[self.SubMenuName].groups[self.SpawnIndex]["rot"],self._SetROT,self,group,RAT.ROT.evade)
MENU_MISSION_COMMAND:New("Despawn group",self.Menu[self.SubMenuName].groups[self.SpawnIndex],self._Despawn,self,group)
MENU_MISSION_COMMAND:New("Place markers",self.Menu[self.SubMenuName].groups[self.SpawnIndex],self._PlaceMarkers,self,waypoints,self.SpawnIndex)
MENU_MISSION_COMMAND:New("Status report",self.Menu[self.SubMenuName].groups[self.SpawnIndex],self.Status,self,true,self.SpawnIndex)
end
return self.SpawnIndex
end
function RAT:ClearForLanding(name)
trigger.action.setUserFlag(name,1)
local flagvalue=trigger.misc.getUserFlag(name)
env.info(RAT.id.."ATC: User flag value (landing) for "..name.." set to "..flagvalue)
end
function RAT:_Respawn(group)
local index=self:GetSpawnIndexFromGroup(group)
local departure=self.ratcraft[index].departure
local destination=self.ratcraft[index].destination
local takeoff=self.ratcraft[index].takeoff
local landing=self.ratcraft[index].landing
local livery=self.ratcraft[index].livery
local lastwp=self.ratcraft[index].waypoints[#self.ratcraft[index].waypoints]
local _departure=nil
local _destination=nil
local _takeoff=nil
local _landing=nil
local _livery=nil
local _lastwp=nil
if self.continuejourney then
_departure=destination:GetName()
_livery=livery
if self.destinationzone then
_takeoff=RAT.wp.air
_landing=RAT.wp.air
elseif self.returnzone then
_takeoff=self.takeoff
if self.takeoff==RAT.wp.air then
_landing=RAT.wp.air
else
_landing=RAT.wp.landing
end
_departure=departure:GetName()
else
_takeoff=self.takeoff
_landing=self.landing
end
elseif self.commute then
_departure=destination:GetName()
_destination=departure:GetName()
_livery=livery
if self.destinationzone then
if self.takeoff==RAT.wp.air then
_takeoff=RAT.wp.air
_landing=RAT.wp.air
else
if takeoff==RAT.wp.air then
_takeoff=self.takeoff
_landing=RAT.wp.air
else
_takeoff=RAT.wp.air
_landing=RAT.wp.landing
end
end
elseif self.returnzone then
_departure=departure:GetName()
_destination=destination:GetName()
_takeoff=self.takeoff
_landing=self.landing
end
end
if _takeoff==RAT.wp.air and(self.continuejourney or self.commute)then
_lastwp=lastwp
end
if self.debug then
env.info(RAT.id..string.format("self.takeoff, takeoff, _takeoff = %s, %s, %s",tostring(self.takeoff),tostring(takeoff),tostring(_takeoff)))
env.info(RAT.id..string.format("self.landing, landing, _landing = %s, %s, %s",tostring(self.landing),tostring(landing),tostring(_landing)))
end
if self.respawn_delay then
SCHEDULER:New(nil,self._SpawnWithRoute,{self,_departure,_destination,_takeoff,_landing,_livery,_lastwp},self.respawn_delay)
else
self:_SpawnWithRoute(_departure,_destination,_takeoff,_landing,_livery,_lastwp)
end
end
function RAT:_SetRoute(takeoff,landing,_departure,_destination,_waypoint)
local VxCruiseMax
if self.Vcruisemax then
VxCruiseMax=min(self.Vcruisemax,self.aircraft.Vmax)
else
VxCruiseMax=math.min(self.aircraft.Vmax*0.90,250)
end
local VxCruiseMin=math.min(VxCruiseMax*0.70,166)
local VxCruise=self:_Random_Gaussian((VxCruiseMax-VxCruiseMin)/2+VxCruiseMin,(VxCruiseMax-VxCruiseMax)/4,VxCruiseMin,VxCruiseMax)
local VxClimb=math.min(self.aircraft.Vmax*0.90,200)
local VxDescent=math.min(self.aircraft.Vmax*0.60,140)
local VxHolding=VxDescent*0.9
local VxFinal=VxHolding*0.9
local VyClimb=math.min(self.Vclimb*RAT.unit.ft2meter/60,self.aircraft.Vymax)
local AlphaClimb=math.asin(VyClimb/VxClimb)
local AlphaDescent=math.rad(self.AlphaDescent)
local FLcruise_expect=self.FLcruise
local departure=nil
if _departure then
if self:_AirportExists(_departure)then
departure=AIRBASE:FindByName(_departure)
if takeoff==RAT.wp.air then
departure=departure:GetZone()
end
elseif self:_ZoneExists(_departure)then
departure=ZONE:New(_departure)
else
local text=string.format("ERROR: Specified departure airport %s does not exist for %s!",_departure,self.alias)
env.error(RAT.id..text)
end
else
departure=self:_PickDeparture(takeoff)
end
if not departure then
local text=string.format("No valid departure airport could be found for %s.",self.alias)
MESSAGE:New(text,60):ToAll()
env.error(RAT.id..text)
return nil
end
local Pdeparture
if takeoff==RAT.wp.air then
if _waypoint then
Pdeparture=COORDINATE:New(_waypoint.x,_waypoint.alt,_waypoint.y)
else
local vec2=departure:GetRandomVec2()
Pdeparture=COORDINATE:NewFromVec2(vec2)
end
else
Pdeparture=departure:GetCoordinate()
end
local H_departure
if takeoff==RAT.wp.air then
local Hmin
if self.category==RAT.cat.plane then
Hmin=1000
else
Hmin=50
end
H_departure=self:_Randomize(FLcruise_expect*0.7,0.3,Pdeparture.y+Hmin,FLcruise_expect)
if self.FLminuser then
H_departure=math.max(H_departure,self.FLminuser)
end
if _waypoint then
H_departure=_waypoint.alt
end
else
H_departure=Pdeparture.y
end
local mindist=self.mindist
if self.FLminuser then
local hclimb=self.FLminuser-H_departure
local hdescent=self.FLminuser-H_departure
local Dclimb,Ddescent,Dtot=self:_MinDistance(AlphaClimb,AlphaDescent,hclimb,hdescent)
if takeoff==RAT.wp.air and landing==RAT.wpair then
mindist=0
elseif takeoff==RAT.wp.air then
mindist=Ddescent
elseif landing==RAT.wp.air then
mindist=Dclimb
else
mindist=Dtot
end
mindist=math.max(self.mindist,mindist)
local text=string.format("Adjusting min distance to %d km (for given min FL%03d)",mindist/1000,self.FLminuser/RAT.unit.FL2m)
env.info(RAT.id..text)
end
local destination=nil
if _destination then
if self:_AirportExists(_destination)then
destination=AIRBASE:FindByName(_destination)
if landing==RAT.wp.air or self.returnzone then
destination=destination:GetZone()
end
elseif self:_ZoneExists(_destination)then
destination=ZONE:New(_destination)
else
local text=string.format("ERROR: Specified destination airport/zone %s does not exist for %s!",_destination,self.alias)
env.error(RAT.id..text)
end
else
local random=self.random_destination
if self.continuejourney and _departure and#self.destination_ports<3 then
random=true
end
local mylanding=landing
local acrange=self.aircraft.Reff
if self.returnzone then
mylanding=RAT.wp.air
acrange=self.aircraft.Reff/2
end
destination=self:_PickDestination(departure,Pdeparture,mindist,math.min(acrange,self.maxdist),random,mylanding)
end
if not destination then
local text=string.format("No valid destination airport could be found for %s!",self.alias)
MESSAGE:New(text,60):ToAll()
env.error(RAT.id..text)
return nil
end
if destination:GetName()==departure:GetName()then
local text=string.format("%s: Destination and departure are identical. Airport/zone %s.",self.alias,destination:GetName())
MESSAGE:New(text,30):ToAll()
env.error(RAT.id..text)
end
local Preturn
local destination_returnzone
if self.returnzone then
local vec2=destination:GetRandomVec2()
Preturn=COORDINATE:NewFromVec2(vec2)
destination_returnzone=destination
destination=departure
end
local Pdestination
if landing==RAT.wp.air then
local vec2=destination:GetRandomVec2()
Pdestination=COORDINATE:NewFromVec2(vec2)
else
Pdestination=destination:GetCoordinate()
end
local H_destination=Pdestination.y
local Rhmin=8000
local Rhmax=20000
if self.category==RAT.cat.heli then
Rhmin=500
Rhmax=1000
end
local Vholding=Pdestination:GetRandomVec2InRadius(Rhmax,Rhmin)
local Pholding=COORDINATE:NewFromVec2(Vholding)
local H_holding=Pholding.y
local h_holding
if self.category==RAT.cat.plane then
h_holding=1200
else
h_holding=150
end
h_holding=self:_Randomize(h_holding,0.2)
local Hh_holding=H_holding+h_holding
if landing==RAT.wp.air then
Hh_holding=H_departure
end
local d_holding=Pholding:Get2DDistance(Pdestination)
local heading
local d_total
if self.returnzone then
heading=self:_Course(Pdeparture,Preturn)
d_total=Pdeparture:Get2DDistance(Preturn)+Preturn:Get2DDistance(Pholding)
else
heading=self:_Course(Pdeparture,Pholding)
d_total=Pdeparture:Get2DDistance(Pholding)
end
if takeoff==RAT.wp.air then
local H_departure_max
if landing==RAT.wp.air then
H_departure_max=H_departure
else
H_departure_max=d_total*math.tan(AlphaDescent)+Hh_holding
end
H_departure=math.min(H_departure,H_departure_max)
end
local deltaH=math.abs(H_departure-Hh_holding)
local phi=math.atan(deltaH/d_total)
local phi_climb
local phi_descent
if(H_departure>Hh_holding)then
phi_climb=AlphaClimb+phi
phi_descent=AlphaDescent-phi
else
phi_climb=AlphaClimb-phi
phi_descent=AlphaDescent+phi
end
local D_total
if self.returnzone then
D_total=math.sqrt(deltaH*deltaH+d_total/2*d_total/2)
else
D_total=math.sqrt(deltaH*deltaH+d_total*d_total)
end
local gamma=math.rad(180)-phi_climb-phi_descent
local a=D_total*math.sin(phi_climb)/math.sin(gamma)
local b=D_total*math.sin(phi_descent)/math.sin(gamma)
local hphi_max=b*math.sin(phi_climb)
local hphi_max2=a*math.sin(phi_descent)
local h_max1=b*math.sin(AlphaClimb)
local h_max2=a*math.sin(AlphaDescent)
local h_max
if(H_departure>Hh_holding)then
h_max=math.min(h_max1,h_max2)
else
h_max=math.max(h_max1,h_max2)
end
local FLmax=h_max+H_departure
local FLmin=math.max(H_departure,Hh_holding)
if self.category==RAT.cat.heli then
FLmin=math.max(H_departure,H_destination)+50
FLmax=math.max(H_departure,H_destination)+1000
end
FLmax=math.min(FLmax,self.aircraft.ceiling)
if self.FLminuser then
FLmin=math.max(self.FLminuser,FLmin)
end
if self.FLmaxuser then
FLmax=math.min(self.FLmaxuser,FLmax)
end
if FLmin>FLmax then
FLmin=FLmax
end
if FLcruise_expect<FLmin then
FLcruise_expect=FLmin
end
if FLcruise_expect>FLmax then
FLcruise_expect=FLmax
end
local FLcruise=self:_Random_Gaussian(FLcruise_expect,math.abs(FLmax-FLmin)/4,FLmin,FLmax)
if self.FLuser then
FLcruise=self.FLuser
FLcruise=math.max(FLcruise,FLmin)
FLcruise=math.min(FLcruise,FLmax)
end
local h_climb=FLcruise-H_departure
local h_descent=FLcruise-Hh_holding
local d_climb=h_climb/math.tan(AlphaClimb)
local d_descent=h_descent/math.tan(AlphaDescent)
local d_cruise=d_total-d_climb-d_descent
local text=string.format("\n******************************************************\n")
text=text..string.format("Template      =  %s\n",self.SpawnTemplatePrefix)
text=text..string.format("Alias         =  %s\n",self.alias)
text=text..string.format("Group name    =  %s\n\n",self:_AnticipatedGroupName())
text=text..string.format("Speeds:\n")
text=text..string.format("VxCruiseMin   = %6.1f m/s = %5.1f km/h\n",VxCruiseMin,VxCruiseMin*3.6)
text=text..string.format("VxCruiseMax   = %6.1f m/s = %5.1f km/h\n",VxCruiseMax,VxCruiseMax*3.6)
text=text..string.format("VxCruise      = %6.1f m/s = %5.1f km/h\n",VxCruise,VxCruise*3.6)
text=text..string.format("VxClimb       = %6.1f m/s = %5.1f km/h\n",VxClimb,VxClimb*3.6)
text=text..string.format("VxDescent     = %6.1f m/s = %5.1f km/h\n",VxDescent,VxDescent*3.6)
text=text..string.format("VxHolding     = %6.1f m/s = %5.1f km/h\n",VxHolding,VxHolding*3.6)
text=text..string.format("VxFinal       = %6.1f m/s = %5.1f km/h\n",VxFinal,VxFinal*3.6)
text=text..string.format("VyClimb       = %6.1f m/s\n",VyClimb)
text=text..string.format("\nDistances:\n")
text=text..string.format("d_climb       = %6.1f km\n",d_climb/1000)
text=text..string.format("d_cruise      = %6.1f km\n",d_cruise/1000)
text=text..string.format("d_descent     = %6.1f km\n",d_descent/1000)
text=text..string.format("d_holding     = %6.1f km\n",d_holding/1000)
text=text..string.format("d_total       = %6.1f km\n",d_total/1000)
text=text..string.format("\nHeights:\n")
text=text..string.format("H_departure   = %6.1f m ASL\n",H_departure)
text=text..string.format("H_destination = %6.1f m ASL\n",H_destination)
text=text..string.format("H_holding     = %6.1f m ASL\n",H_holding)
text=text..string.format("h_climb       = %6.1f m\n",h_climb)
text=text..string.format("h_descent     = %6.1f m\n",h_descent)
text=text..string.format("h_holding     = %6.1f m\n",h_holding)
text=text..string.format("delta H       = %6.1f m\n",deltaH)
text=text..string.format("FLmin         = %6.1f m ASL = FL%03d\n",FLmin,FLmin/RAT.unit.FL2m)
text=text..string.format("FLcruise      = %6.1f m ASL = FL%03d\n",FLcruise,FLcruise/RAT.unit.FL2m)
text=text..string.format("FLmax         = %6.1f m ASL = FL%03d\n",FLmax,FLmax/RAT.unit.FL2m)
text=text..string.format("\nAngles:\n")
text=text..string.format("Alpha climb   = %6.2f Deg\n",math.deg(AlphaClimb))
text=text..string.format("Alpha descent = %6.2f Deg\n",math.deg(AlphaDescent))
text=text..string.format("Phi (slope)   = %6.2f Deg\n",math.deg(phi))
text=text..string.format("Phi climb     = %6.2f Deg\n",math.deg(phi_climb))
text=text..string.format("Phi descent   = %6.2f Deg\n",math.deg(phi_descent))
if self.debug then
local h_climb_max=FLmax-H_departure
local h_descent_max=FLmax-Hh_holding
local d_climb_max=h_climb_max/math.tan(AlphaClimb)
local d_descent_max=h_descent_max/math.tan(AlphaDescent)
local d_cruise_max=d_total-d_climb_max-d_descent_max
text=text..string.format("Heading       = %6.1f Deg\n",heading)
text=text..string.format("\nSSA triangle:\n")
text=text..string.format("D_total       = %6.1f km\n",D_total/1000)
text=text..string.format("gamma         = %6.1f Deg\n",math.deg(gamma))
text=text..string.format("a             = %6.1f m\n",a)
text=text..string.format("b             = %6.1f m\n",b)
text=text..string.format("hphi_max      = %6.1f m\n",hphi_max)
text=text..string.format("hphi_max2     = %6.1f m\n",hphi_max2)
text=text..string.format("h_max1        = %6.1f m\n",h_max1)
text=text..string.format("h_max2        = %6.1f m\n",h_max2)
text=text..string.format("h_max         = %6.1f m\n",h_max)
text=text..string.format("\nMax heights and distances:\n")
text=text..string.format("d_climb_max   = %6.1f km\n",d_climb_max/1000)
text=text..string.format("d_cruise_max  = %6.1f km\n",d_cruise_max/1000)
text=text..string.format("d_descent_max = %6.1f km\n",d_descent_max/1000)
text=text..string.format("h_climb_max   = %6.1f m\n",h_climb_max)
text=text..string.format("h_descent_max = %6.1f m\n",h_descent_max)
end
text=text..string.format("******************************************************\n")
env.info(RAT.id..text)
if d_cruise<0 then
d_cruise=100
end
local wp={}
local c={}
local wpholding=nil
local wpfinal=nil
c[#c+1]=Pdeparture
wp[#wp+1]=self:_Waypoint(#wp+1,takeoff,c[#wp+1],VxClimb,H_departure,departure)
self.waypointdescriptions[#wp]="Departure"
self.waypointstatus[#wp]=RAT.status.Departure
if takeoff==RAT.wp.air then
if d_climb<5000 or d_cruise<5000 then
d_cruise=d_cruise+d_climb
else
c[#c+1]=c[#c]:Translate(d_climb,heading)
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.cruise,c[#wp+1],VxCruise,FLcruise)
self.waypointdescriptions[#wp]="Begin of Cruise"
self.waypointstatus[#wp]=RAT.status.Cruise
end
else
c[#c+1]=c[#c]:Translate(d_climb/2,heading)
c[#c+1]=c[#c]:Translate(d_climb/2,heading)
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.climb,c[#wp+1],VxClimb,H_departure+(FLcruise-H_departure)/2)
self.waypointdescriptions[#wp]="Climb"
self.waypointstatus[#wp]=RAT.status.Climb
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.cruise,c[#wp+1],VxCruise,FLcruise)
self.waypointdescriptions[#wp]="Begin of Cruise"
self.waypointstatus[#wp]=RAT.status.Cruise
end
if self.returnzone then
c[#c+1]=Preturn
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.cruise,c[#wp+1],VxCruise,FLcruise)
self.waypointdescriptions[#wp]="Return Zone"
self.waypointstatus[#wp]=RAT.status.Uturn
end
if landing==RAT.wp.air then
c[#c+1]=Pdestination
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.finalwp,c[#wp+1],VxCruise,FLcruise)
self.waypointdescriptions[#wp]="Final Destination"
self.waypointstatus[#wp]=RAT.status.Destination
elseif self.returnzone then
c[#c+1]=c[#c]:Translate(d_cruise/2,heading-180)
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.cruise,c[#wp+1],VxCruise,FLcruise)
self.waypointdescriptions[#wp]="End of Cruise"
self.waypointstatus[#wp]=RAT.status.Descent
else
c[#c+1]=c[#c]:Translate(d_cruise,heading)
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.cruise,c[#wp+1],VxCruise,FLcruise)
self.waypointdescriptions[#wp]="End of Cruise"
self.waypointstatus[#wp]=RAT.status.Descent
end
if landing==RAT.wp.landing then
if self.returnzone then
c[#c+1]=c[#c]:Translate(d_descent/2,heading-180)
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.descent,c[#wp+1],VxDescent,FLcruise-(FLcruise-(h_holding+H_holding))/2)
self.waypointdescriptions[#wp]="Descent"
self.waypointstatus[#wp]=RAT.status.DescentHolding
else
c[#c+1]=c[#c]:Translate(d_descent/2,heading)
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.descent,c[#wp+1],VxDescent,FLcruise-(FLcruise-(h_holding+H_holding))/2)
self.waypointdescriptions[#wp]="Descent"
self.waypointstatus[#wp]=RAT.status.DescentHolding
end
end
if landing==RAT.wp.landing then
c[#c+1]=Pholding
wp[#wp+1]=self:_Waypoint(#wp+1,RAT.wp.holding,c[#wp+1],VxHolding,H_holding+h_holding)
self.waypointdescriptions[#wp]="Holding Point"
self.waypointstatus[#wp]=RAT.status.Holding
wpholding=#wp
c[#c+1]=Pdestination
wp[#wp+1]=self:_Waypoint(#wp+1,landing,c[#wp+1],VxFinal,H_destination,destination)
self.waypointdescriptions[#wp]="Destination"
self.waypointstatus[#wp]=RAT.status.Destination
end
wpfinal=#wp
local waypoints={}
for _,p in ipairs(wp)do
table.insert(waypoints,p)
end
self:_Routeinfo(waypoints,"Waypoint info in set_route:")
if self.returnzone then
return departure,destination_returnzone,waypoints,wpholding,wpfinal
else
return departure,destination,waypoints,wpholding,wpfinal
end
end
function RAT:_PickDeparture(takeoff)
local departures={}
if self.random_departure then
for _,airport in pairs(self.airports)do
local name=airport:GetName()
if not self:_Excluded(name)then
if takeoff==RAT.wp.air then
table.insert(departures,airport:GetZone())
else
table.insert(departures,airport)
end
end
end
else
for _,name in pairs(self.departure_ports)do
local dep=nil
if self:_AirportExists(name)then
if takeoff==RAT.wp.air then
dep=AIRBASE:FindByName(name):GetZone()
else
dep=AIRBASE:FindByName(name)
end
elseif self:_ZoneExists(name)then
if takeoff==RAT.wp.air then
dep=ZONE:New(name)
else
env.error(RAT.id.."Takeoff is not in air. Cannot use "..name.." as departure!")
end
else
env.error(RAT.id.."No airport or zone found with name "..name)
end
if dep then
table.insert(departures,dep)
end
end
end
env.info(RAT.id.."Number of possible departures = "..#departures)
local departure=departures[math.random(#departures)]
local text
if departure and departure:GetName()then
if takeoff==RAT.wp.air then
text="Chosen departure zone: "..departure:GetName()
else
text="Chosen departure airport: "..departure:GetName().." (ID "..departure:GetID()..")"
end
env.info(RAT.id..text)
if self.debug then
MESSAGE:New(text,30):ToAll()
end
else
env.error(RAT.id.."No departure airport or zone found.")
departure=nil
end
return departure
end
function RAT:_PickDestination(departure,q,minrange,maxrange,random,landing)
minrange=minrange or self.mindist
maxrange=maxrange or self.maxdist
local destinations={}
if random then
for _,airport in pairs(self.airports)do
local name=airport:GetName()
if self:_IsFriendly(name)and not self:_Excluded(name)and name~=departure:GetName()then
local distance=q:Get2DDistance(airport:GetCoordinate())
if distance>=minrange and distance<=maxrange then
if landing==RAT.wp.air then
table.insert(destinations,airport:GetZone())
else
table.insert(destinations,airport)
end
end
end
end
else
for _,name in pairs(self.destination_ports)do
if name~=departure:GetName()then
local dest=nil
if self:_AirportExists(name)then
if landing==RAT.wp.air then
dest=AIRBASE:FindByName(name):GetZone()
else
dest=AIRBASE:FindByName(name)
end
elseif self:_ZoneExists(name)then
if landing==RAT.wp.air then
dest=ZONE:New(name)
else
env.error(RAT.id.."Landing is not in air. Cannot use zone "..name.." as destination!")
end
else
env.error(RAT.id.."No airport or zone found with name "..name)
end
if dest then
local distance=q:Get2DDistance(dest:GetCoordinate())
if distance>=minrange and distance<=maxrange then
table.insert(destinations,dest)
else
local text=string.format("Destination %s is ouside range. Distance = %5.1f km, min = %5.1f km, max = %5.1f km.",name,distance,minrange,maxrange)
env.info(RAT.id..text)
end
end
end
end
end
env.info(RAT.id.."Number of possible destinations = "..#destinations)
if#destinations>0 then
local function compare(a,b)
local qa=q:Get2DDistance(a:GetCoordinate())
local qb=q:Get2DDistance(b:GetCoordinate())
return qa<qb
end
table.sort(destinations,compare)
else
destinations=nil
end
local destination
if destinations and#destinations>0 then
destination=destinations[math.random(#destinations)]
local text
if landing==RAT.wp.air then
text=string.format("Chosen destination zone: %s.",destination:GetName())
else
text=string.format("Chosen destination airport: %s (ID %d).",destination:GetName(),destination:GetID())
end
env.info(RAT.id..text)
if self.debug then
MESSAGE:New(text,30):ToAll()
end
else
env.error(RAT.id.."No destination airport or zone found.")
destination=nil
end
return destination
end
function RAT:_GetAirportsInZone(zone)
local airports={}
for _,airport in pairs(self.airports)do
local name=airport:GetName()
local coord=airport:GetCoordinate()
if zone:IsPointVec3InZone(coord)then
table.insert(airports,name)
end
end
return airports
end
function RAT:_Excluded(port)
for _,name in pairs(self.excluded_ports)do
if name==port then
return true
end
end
return false
end
function RAT:_IsFriendly(port)
for _,airport in pairs(self.airports)do
local name=airport:GetName()
if name==port then
return true
end
end
return false
end
function RAT:_GetAirportsOfMap()
local _coalition
for i=0,2 do
if i==0 then
_coalition=coalition.side.NEUTRAL
elseif i==1 then
_coalition=coalition.side.RED
elseif i==2 then
_coalition=coalition.side.BLUE
end
local ab=coalition.getAirbases(i)
for _,airbase in pairs(ab)do
local _id=airbase:getID()
local _p=airbase:getPosition().p
local _name=airbase:getName()
local _myab=AIRBASE:FindByName(_name)
table.insert(self.airports_map,_myab)
if self.debug then
local text1="MOOSE: Airport ID = ".._myab:GetID().." and Name = ".._myab:GetName()..", Category = ".._myab:GetCategory()..", TypeName = ".._myab:GetTypeName()
env.info(RAT.id..text1)
end
end
end
end
function RAT:_GetAirportsOfCoalition()
for _,coalition in pairs(self.ctable)do
for _,airport in pairs(self.airports_map)do
if airport:GetCoalition()==coalition then
local condition1=self.category==RAT.cat.plane and airport:GetTypeName()=="FARP"
local condition2=self.category==RAT.cat.plane and airport:GetCategory()==1
if not(condition1 or condition2)then
table.insert(self.airports,airport)
end
end
end
end
if#self.airports==0 then
local text="No possible departure/destination airports found!"
MESSAGE:New(text,60):ToAll()
env.error(RAT.id..text)
end
end
function RAT:Status(message,forID)
message=message or false
forID=forID or false
local ngroups=#self.ratcraft
local Tnow=timer.getTime()
for i=1,ngroups do
if self.ratcraft[i].group then
if self.ratcraft[i].group:IsAlive()then
local group=self.ratcraft[i].group
local prefix=self:_GetPrefixFromGroup(group)
local life=self:_GetLife(group)
local fuel=group:GetFuel()*100.0
local airborne=group:InAir()
local coords=group:GetCoordinate()
local alt=coords.y
local departure=self.ratcraft[i].departure:GetName()
local destination=self.ratcraft[i].destination:GetName()
local type=self.aircraft.type
local Tg=0
local Dg=0
local dTlast=0
local stationary=false
if airborne then
self.ratcraft[i]["Tground"]=nil
self.ratcraft[i]["Pground"]=nil
self.ratcraft[i]["Tlastcheck"]=nil
else
if self.ratcraft[i]["Tground"]then
Tg=Tnow-self.ratcraft[i]["Tground"]
Dg=coords:Get2DDistance(self.ratcraft[i]["Pground"])
dTlast=Tnow-self.ratcraft[i]["Tlastcheck"]
if dTlast>self.Tinactive then
if Dg<50 and not self.uncontrolled then
stationary=true
end
self.ratcraft[i]["Tlastcheck"]=Tnow
self.ratcraft[i]["Pground"]=coords
end
else
self.ratcraft[i]["Tground"]=Tnow
self.ratcraft[i]["Tlastcheck"]=Tnow
self.ratcraft[i]["Pground"]=coords
end
end
local Pn=coords
local Dtravel=Pn:Get2DDistance(self.ratcraft[i]["Pnow"])
self.ratcraft[i]["Pnow"]=Pn
self.ratcraft[i]["Distance"]=self.ratcraft[i]["Distance"]+Dtravel
local Ddestination=Pn:Get2DDistance(self.ratcraft[i].destination:GetCoordinate())
local status=self.ratcraft[i].status
if self.uncontrolled then
status="Uncontrolled"
end
if(forID and i==forID)or(not forID)then
local text=string.format("ID %i of group %s\n",i,prefix)
if self.commute then
text=text..string.format("%s commuting between %s and %s\n",type,departure,destination)
elseif self.continuejourney then
text=text..string.format("%s travelling from %s to %s (and continueing form there)\n",type,departure,destination)
else
text=text..string.format("%s travelling from %s to %s\n",type,departure,destination)
end
text=text..string.format("Status: %s",status)
if airborne then
text=text.." [airborne]\n"
else
text=text.." [on ground]\n"
end
text=text..string.format("Fuel = %3.0f %%\n",fuel)
text=text..string.format("Life  = %3.0f %%\n",life)
text=text..string.format("FL%03d = %i m ASL\n",alt/RAT.unit.FL2m,alt)
text=text..string.format("Distance travelled        = %6.1f km\n",self.ratcraft[i]["Distance"]/1000)
text=text..string.format("Distance to destination = %6.1f km",Ddestination/1000)
if not airborne then
text=text..string.format("\nTime on ground  = %6.0f seconds\n",Tg)
text=text..string.format("Position change = %8.1f m since %3.0f seconds.",Dg,dTlast)
end
if self.debug then
env.info(RAT.id..text)
end
if message then
MESSAGE:New(text,20):ToAll()
end
end
if not airborne then
if stationary then
local text=string.format("Group %s is despawned after being %4.0f seconds inaktive on ground.",self.alias,dTlast)
env.info(RAT.id..text)
self:_Despawn(group)
end
if life<10 and Dtravel<100 then
local text=string.format("Damaged group %s is despawned. Life = %3.0f",self.alias,life)
self:_Despawn(group)
end
end
if self.ratcraft[i].despawnme then
local text=string.format("Flight %s will be despawned NOW!",self.alias)
env.info(RAT.id..text)
self:_Respawn(self.ratcraft[i].group)
self:_Despawn(self.ratcraft[i].group)
end
end
else
if self.debug then
local text=string.format("Group %i does not exist.",i)
env.info(RAT.id..text)
end
end
end
if(message and not forID)then
local text=string.format("Alive groups of %s: %d",self.alias,self.alive)
env.info(RAT.id..text)
MESSAGE:New(text,20):ToAll()
end
end
function RAT:_GetLife(group)
local life=0.0
if group and group:IsAlive()then
local unit=group:GetUnit(1)
if unit then
life=unit:GetLife()/unit:GetLife0()*100
else
if self.debug then
env.error(RAT.id.."Unit does not exist in RAT_Getlife(). Returning zero.")
end
end
else
if self.debug then
env.error(RAT.id.."Group does not exist in RAT_Getlife(). Returning zero.")
end
end
return life
end
function RAT:_SetStatus(group,status)
local index=self:GetSpawnIndexFromGroup(group)
self.ratcraft[index].status=status
local no1=status==RAT.status.Departure
local no2=status==RAT.status.EventBirthAir
local no3=status==RAT.status.Holding
local text=string.format("Flight %s: %s.",group:GetName(),status)
env.info(RAT.id..text)
if(not(no1 or no2 or no3))then
MESSAGE:New(text,10):ToAllIf(self.reportstatus)
end
end
function RAT:_OnBirth(EventData)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
if EventPrefix==self.alias then
local text="Event: Group "..SpawnGroup:GetName().." was born."
env.info(RAT.id..text)
local status
if SpawnGroup:InAir()then
status="Just born (after air start)"
status=RAT.status.EventBirthAir
else
status="Starting engines (after birth)"
status=RAT.status.EventBirth
end
self:_SetStatus(SpawnGroup,status)
end
end
else
if self.debug then
env.error("Group does not exist in RAT:_OnBirthDay().")
end
end
end
function RAT:_EngineStartup(EventData)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
if EventPrefix==self.alias then
local text="Event: Group "..SpawnGroup:GetName().." started engines."
env.info(RAT.id..text)
local status
if SpawnGroup:InAir()then
status="On journey (after air start)"
status=RAT.status.EventEngineStartAir
else
status="Taxiing (after engines started)"
status=RAT.status.EventEngineStart
end
self:_SetStatus(SpawnGroup,status)
end
end
else
if self.debug then
env.error("Group does not exist in RAT:_EngineStartup().")
end
end
end
function RAT:_OnTakeoff(EventData)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
if EventPrefix==self.alias then
local text="Event: Group "..SpawnGroup:GetName().." is airborne."
env.info(RAT.id..text)
local status=RAT.status.EventTakeoff
self:_SetStatus(SpawnGroup,status)
if self.respawn_after_takeoff then
text="Event: Group "..SpawnGroup:GetName().." will be respawned."
env.info(RAT.id..text)
self:_Respawn(SpawnGroup)
end
end
end
else
if self.debug then
env.error("Group does not exist in RAT:_OnTakeoff().")
end
end
end
function RAT:_OnLand(EventData)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
if EventPrefix==self.alias then
local text="Event: Group "..SpawnGroup:GetName().." landed."
env.info(RAT.id..text)
local status=RAT.status.EventLand
self:_SetStatus(SpawnGroup,status)
if self.ATCswitch then
RAT:_ATCFlightLanded(SpawnGroup:GetName())
end
if self.respawn_at_landing and not self.norespawn then
text="Event: Group "..SpawnGroup:GetName().." will be respawned."
env.info(RAT.id..text)
self:_Respawn(SpawnGroup)
end
end
end
else
if self.debug then
env.error("Group does not exist in RAT:_OnLand().")
end
end
end
function RAT:_OnEngineShutdown(EventData)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
if EventPrefix==self.alias then
local text="Event: Group "..SpawnGroup:GetName().." shut down its engines."
env.info(RAT.id..text)
local status=RAT.status.EventEngineShutdown
self:_SetStatus(SpawnGroup,status)
if not self.respawn_at_landing and not self.norespawn then
text="Event: Group "..SpawnGroup:GetName().." will be respawned."
env.info(RAT.id..text)
self:_Respawn(SpawnGroup)
end
text="Event: Group "..SpawnGroup:GetName().." will be destroyed now."
env.info(RAT.id..text)
self:_Despawn(SpawnGroup)
end
end
else
if self.debug then
env.error("Group does not exist in RAT:_OnEngineShutdown().")
end
end
end
function RAT:_OnDead(EventData)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
if EventPrefix==self.alias then
local text="Event: Group "..SpawnGroup:GetName().." died."
env.info(RAT.id..text)
local status=RAT.status.EventDead
self:_SetStatus(SpawnGroup,status)
end
end
else
if self.debug then
env.error("Group does not exist in RAT:_OnDead().")
end
end
end
function RAT:_OnCrash(EventData)
local SpawnGroup=EventData.IniGroup
if SpawnGroup then
env.info(string.format("%sGroup %s crashed!",RAT.id,SpawnGroup:GetName()))
local EventPrefix=self:_GetPrefixFromGroup(SpawnGroup)
if EventPrefix then
if EventPrefix==self.alias then
local text="Event: Group "..SpawnGroup:GetName().." crashed."
env.info(RAT.id..text)
local status=RAT.status.EventCrash
self:_SetStatus(SpawnGroup,status)
end
end
else
if self.debug then
env.error("Group does not exist in RAT:_OnCrash().")
end
end
end
function RAT:_Despawn(group)
local index=self:GetSpawnIndexFromGroup(group)
self.ratcraft[index].group=nil
group:Destroy()
self.alive=self.alive-1
if self.f10menu then
self.Menu[self.SubMenuName]["groups"][index]:Remove()
end
end
function RAT:_Waypoint(index,Type,Coord,Speed,Altitude,Airport)
local _Altitude=Altitude or Coord.y
local Hland=Coord:GetLandHeight()
local _Type=nil
local _Action=nil
local _alttype="RADIO"
if Type==RAT.wp.cold then
_Type="TakeOffParking"
_Action="From Parking Area"
_Altitude=0
_alttype="RADIO"
elseif Type==RAT.wp.hot then
_Type="TakeOffParkingHot"
_Action="From Parking Area Hot"
_Altitude=0
_alttype="RADIO"
elseif Type==RAT.wp.runway then
_Type="TakeOff"
_Action="From Parking Area"
_Altitude=0
_alttype="RADIO"
elseif Type==RAT.wp.air then
_Type="Turning Point"
_Action="Turning Point"
_alttype="BARO"
elseif Type==RAT.wp.climb then
_Type="Turning Point"
_Action="Turning Point"
_alttype="BARO"
elseif Type==RAT.wp.cruise then
_Type="Turning Point"
_Action="Turning Point"
_alttype="BARO"
elseif Type==RAT.wp.descent then
_Type="Turning Point"
_Action="Turning Point"
_alttype="BARO"
elseif Type==RAT.wp.holding then
_Type="Turning Point"
_Action="Turning Point"
_alttype="BARO"
elseif Type==RAT.wp.landing then
_Type="Land"
_Action="Landing"
_Altitude=0
_alttype="RADIO"
elseif Type==RAT.wp.finalwp then
_Type="Turning Point"
_Action="Turning Point"
_alttype="BARO"
else
env.error("Unknown waypoint type in RAT:Waypoint() function!")
_Type="Turning Point"
_Action="Turning Point"
_alttype="RADIO"
end
local text=string.format("\n******************************************************\n")
text=text..string.format("Waypoint =  %d\n",index)
text=text..string.format("Template =  %s\n",self.SpawnTemplatePrefix)
text=text..string.format("Alias    =  %s\n",self.alias)
text=text..string.format("Type: %i - %s\n",Type,_Type)
text=text..string.format("Action: %s\n",_Action)
text=text..string.format("Coord: x = %6.1f km, y = %6.1f km, alt = %6.1f m\n",Coord.x/1000,Coord.z/1000,Coord.y)
text=text..string.format("Speed = %6.1f m/s = %6.1f km/h = %6.1f knots\n",Speed,Speed*3.6,Speed*1.94384)
text=text..string.format("Land     = %6.1f m ASL\n",Hland)
text=text..string.format("Altitude = %6.1f m (%s)\n",_Altitude,_alttype)
if Airport then
if Type==RAT.wp.air then
text=text..string.format("Zone = %s\n",Airport:GetName())
else
text=text..string.format("Airport = %s\n",Airport:GetName())
end
else
text=text..string.format("No airport/zone specified\n")
end
text=text.."******************************************************\n"
if self.debug then
env.info(RAT.id..text)
end
local RoutePoint={}
RoutePoint.x=Coord.x
RoutePoint.y=Coord.z
RoutePoint.alt=_Altitude
RoutePoint.alt_type=_alttype
RoutePoint.type=_Type
RoutePoint.action=_Action
RoutePoint.speed=Speed
RoutePoint.speed_locked=true
RoutePoint.ETA=nil
RoutePoint.ETA_locked=false
RoutePoint.name="RAT waypoint"
if(Airport~=nil)and(Type~=RAT.wp.air)then
local AirbaseID=Airport:GetID()
local AirbaseCategory=Airport:GetDesc().category
if AirbaseCategory==Airbase.Category.SHIP then
RoutePoint.linkUnit=AirbaseID
RoutePoint.helipadId=AirbaseID
elseif AirbaseCategory==Airbase.Category.HELIPAD then
RoutePoint.linkUnit=AirbaseID
RoutePoint.helipadId=AirbaseID
elseif AirbaseCategory==Airbase.Category.AIRDROME then
RoutePoint.airdromeId=AirbaseID
else
end
end
RoutePoint.properties={
["vnav"]=1,
["scale"]=0,
["angle"]=0,
["vangle"]=0,
["steer"]=2,
}
local TaskCombo={}
local TaskHolding=self:_TaskHolding({x=Coord.x,y=Coord.z},Altitude,Speed,self:_Randomize(90,0.9))
local TaskWaypoint=self:_TaskFunction("RAT._WaypointFunction",self,index)
RoutePoint.task={}
RoutePoint.task.id="ComboTask"
RoutePoint.task.params={}
TaskCombo[#TaskCombo+1]=TaskWaypoint
if Type==RAT.wp.holding then
TaskCombo[#TaskCombo+1]=TaskHolding
end
RoutePoint.task.params.tasks=TaskCombo
return RoutePoint
end
function RAT:_Routeinfo(waypoints,comment)
local text=string.format("\n******************************************************\n")
text=text..string.format("Template =  %s\n",self.SpawnTemplatePrefix)
if comment then
text=text..comment.."\n"
end
text=text..string.format("Number of waypoints = %i\n",#waypoints)
for i=1,#waypoints do
local p=waypoints[i]
text=text..string.format("WP #%i: x = %6.1f km, y = %6.1f km, alt = %6.1f m  %s\n",i-1,p.x/1000,p.y/1000,p.alt,self.waypointdescriptions[i])
end
local total=0.0
for i=1,#waypoints-1 do
local point1=waypoints[i]
local point2=waypoints[i+1]
local x1=point1.x
local y1=point1.y
local x2=point2.x
local y2=point2.y
local d=math.sqrt((x1-x2)^2+(y1-y2)^2)
local heading=self:_Course(point1,point2)
total=total+d
text=text..string.format("Distance from WP %i-->%i = %6.1f km. Heading = %03d :  %s - %s\n",i-1,i,d/1000,heading,self.waypointdescriptions[i],self.waypointdescriptions[i+1])
end
text=text..string.format("Total distance = %6.1f km\n",total/1000)
text=text..string.format("******************************************************\n")
if self.debug then
end
env.info(RAT.id..text)
return total
end
function RAT:_TaskHolding(P1,Altitude,Speed,Duration)
local dx=3000
local dy=0
if self.category==RAT.cat.heli then
dx=200
dy=0
end
local P2={}
P2.x=P1.x+dx
P2.y=P1.y+dy
local Task={
id='Orbit',
params={
pattern=AI.Task.OrbitPattern.RACE_TRACK,
point=P1,
point2=P2,
speed=Speed,
altitude=Altitude
}
}
local DCSTask={}
DCSTask.id="ControlledTask"
DCSTask.params={}
DCSTask.params.task=Task
if self.ATCswitch then
local userflagname=string.format("%s#%03d",self.alias,self.SpawnIndex+1)
local maxholdingduration=60*120
DCSTask.params.stopCondition={userFlag=userflagname,userFlagValue=1,duration=maxholdingduration}
else
DCSTask.params.stopCondition={duration=Duration}
end
return DCSTask
end
function RAT._WaypointFunction(group,rat,wp)
local Tnow=timer.getTime()
local sdx=rat:GetSpawnIndexFromGroup(group)
local departure=rat.ratcraft[sdx].departure:GetName()
local destination=rat.ratcraft[sdx].destination:GetName()
local landing=rat.ratcraft[sdx].landing
local WPholding=rat.ratcraft[sdx].wpholding
local WPfinal=rat.ratcraft[sdx].wpfinal
local text
text=string.format("Flight %s passing waypoint #%d %s.",group:GetName(),wp,rat.waypointdescriptions[wp])
env.info(RAT.id..text)
local status=rat.waypointstatus[wp]
rat:_SetStatus(group,status)
if wp==WPholding then
text=string.format("Flight %s to %s ATC: Holding and awaiting landing clearance.",group:GetName(),destination)
MESSAGE:New(text,10):ToAllIf(rat.reportstatus)
if rat.ATCswitch then
MENU_MISSION_COMMAND:New("Clear for landing",rat.Menu[rat.SubMenuName].groups[sdx],rat.ClearForLanding,rat,group:GetName())
rat:_ATCRegisterFlight(group:GetName(),Tnow)
end
end
if wp==WPfinal then
text=string.format("Flight %s arrived at final destination %s.",group:GetName(),destination)
MESSAGE:New(text,10):ToAllIf(rat.reportstatus)
env.info(RAT.id..text)
if landing==RAT.wp.air then
text=string.format("Activating despawn switch for flight %s! Group will be detroyed soon.",group:GetName())
MESSAGE:New(text,30):ToAllIf(rat.debug)
env.info(RAT.id..text)
rat.ratcraft[sdx].despawnme=true
end
end
end
function RAT:_TaskFunction(FunctionString,...)
self:F2({FunctionString,arg})
local DCSTask
local ArgumentKey
local templatename=self.templategroup:GetName()
local groupname=self:_AnticipatedGroupName()
local DCSScript={}
DCSScript[#DCSScript+1]="local MissionControllable = GROUP:FindByName(\""..groupname.."\") "
DCSScript[#DCSScript+1]="local RATtemplateControllable = GROUP:FindByName(\""..templatename.."\") "
if arg and arg.n>0 then
ArgumentKey='_'..tostring(arg):match("table: (.*)")
self.templategroup:SetState(self.templategroup,ArgumentKey,arg)
DCSScript[#DCSScript+1]="local Arguments = RATtemplateControllable:GetState(RATtemplateControllable, '"..ArgumentKey.."' ) "
DCSScript[#DCSScript+1]=FunctionString.."( MissionControllable, unpack( Arguments ) )"
else
DCSScript[#DCSScript+1]=FunctionString.."( MissionControllable )"
end
DCSTask=self.templategroup:TaskWrappedAction(self.templategroup:CommandDoScript(table.concat(DCSScript)))
return DCSTask
end
function RAT:_AnticipatedGroupName(index)
local index=index or self.SpawnIndex+1
return string.format("%s#%03d",self.alias,index)
end
function RAT:_FLmax(alpha,beta,d,phi,h0)
local gamma=math.rad(180)-alpha-beta
local a=d*math.sin(alpha)/math.sin(gamma)
local b=d*math.sin(beta)/math.sin(gamma)
local h1=b*math.sin(alpha)
local h2=a*math.sin(beta)
local h3=b*math.cos(math.pi/2-(alpha+phi))
local text=string.format("\nFLmax = FL%3.0f = %6.1f m.\n",h1/RAT.unit.FL2m,h1)
text=text..string.format("FLmax = FL%3.0f = %6.1f m.\n",h2/RAT.unit.FL2m,h2)
text=text..string.format("FLmax = FL%3.0f = %6.1f m.",h3/RAT.unit.FL2m,h3)
if self.debug then
env.info(RAT.id..text)
end
return h3+h0
end
function RAT:_MinDistance(alpha,beta,ha,hb)
local d1=ha/math.tan(alpha)
local d2=hb/math.tan(beta)
return d1,d2,d1+d2
end
function RAT:_AddFriendlyAirports(ports)
for _,airport in pairs(self.airports)do
if not self:_NameInList(ports,airport:GetName())then
table.insert(ports,airport:GetName())
end
end
end
function RAT:_NameInList(liste,name)
for _,item in pairs(liste)do
if item==name then
return true
end
end
return false
end
function RAT:_AirportExists(name)
for _,airport in pairs(self.airports_map)do
if airport:GetName()==name then
return true
end
end
return false
end
function RAT:_ZoneExists(name)
local z=trigger.misc.getZone(name)
if z then
return true
end
return false
end
function RAT:_SetROE(group,roe)
env.info(RAT.id.."Setting ROE to "..roe.." for group "..group:GetName())
if self.roe==RAT.ROE.returnfire then
group:OptionROEReturnFire()
elseif self.roe==RAT.ROE.weaponfree then
group:OptionROEWeaponFree()
else
group:OptionROEHoldFire()
end
end
function RAT:_SetROT(group,rot)
env.info(RAT.id.."Setting ROT to "..rot.." for group "..group:GetName())
if self.rot==RAT.ROT.passive then
group:OptionROTPassiveDefense()
elseif self.rot==RAT.ROT.evade then
group:OptionROTEvadeFire()
else
group:OptionROTNoReaction()
end
end
function RAT:_SetCoalitionTable()
if self.friendly==RAT.coal.neutral then
self.ctable={coalition.side.NEUTRAL}
elseif self.friendly==RAT.coal.same then
self.ctable={self.coalition,coalition.side.NEUTRAL}
elseif self.friendly==RAT.coal.sameonly then
self.ctable={self.coalition}
else
env.error("Unknown friendly coalition in _SetCoalitionTable(). Defaulting to NEUTRAL.")
self.ctable={self.coalition,coalition.side.NEUTRAL}
end
end
function RAT:_Course(a,b)
local dx=b.x-a.x
local ay
if a.alt then
ay=a.y
else
ay=a.z
end
local by
if b.alt then
by=b.y
else
by=b.z
end
local dy=by-ay
local angle=math.deg(math.atan2(dy,dx))
if angle<0 then
angle=360+angle
end
return angle
end
function RAT:_Heading(course)
local h
if course<=180 then
h=math.rad(course)
else
h=-math.rad(360-course)
end
return h
end
function RAT:_Randomize(value,fac,lower,upper)
local min
if lower then
min=math.max(value-value*fac,lower)
else
min=value-value*fac
end
local max
if upper then
max=math.min(value+value*fac,upper)
else
max=value+value*fac
end
local r=math.random(min,max)
if self.debug then
local text=string.format("Random: value = %6.2f, fac = %4.2f, min = %6.2f, max = %6.2f, r = %6.2f",value,fac,min,max,r)
env.info(RAT.id..text)
end
return r
end
function RAT:_Random_Gaussian(x0,sigma,xmin,xmax)
sigma=sigma or 10
local r
local gotit=false
local i=0
while not gotit do
local x1=math.random()
local x2=math.random()
r=math.sqrt(-2*sigma*sigma*math.log(x1))*math.cos(2*math.pi*x2)+x0
i=i+1
if(r>=xmin and r<=xmax)or i>100 then
gotit=true
end
end
return r
end
function RAT:_PlaceMarkers(waypoints,index)
for i=1,#waypoints do
self:_SetMarker(self.waypointdescriptions[i],waypoints[i],index)
if self.debug then
local text=string.format("Marker at waypoint #%d: %s for flight #%d",i,self.waypointdescriptions[i],index)
env.info(RAT.id..text)
end
end
end
function RAT:_SetMarker(text,wp,index)
RAT.markerid=RAT.markerid+1
self.markerids[#self.markerids+1]=RAT.markerid
if self.debug then
env.info(RAT.id..self.SpawnTemplatePrefix..": placing marker with ID "..RAT.markerid..": "..text)
end
local vec={x=wp.x,y=wp.alt,z=wp.y}
local flight=self:GetGroupFromIndex(index):GetName()
local text1=string.format("%s:\n%s",flight,text)
trigger.action.markToAll(RAT.markerid,text1,vec)
end
function RAT:_DeleteMarkers()
for k,v in ipairs(self.markerids)do
trigger.action.removeMark(v)
end
for k,v in ipairs(self.markerids)do
self.markerids[k]=nil
end
end
function RAT:_ModifySpawnTemplate(waypoints,livery)
local PointVec3={x=waypoints[1].x,y=waypoints[1].alt,z=waypoints[1].y}
local course=self:_Course(waypoints[1],waypoints[2])
local heading=self:_Heading(course)
if self:_GetSpawnIndex(self.SpawnIndex+1)then
local SpawnTemplate=self.SpawnGroups[self.SpawnIndex].SpawnTemplate
if SpawnTemplate then
self:T(SpawnTemplate)
if self.uncontrolled then
SpawnTemplate.uncontrolled=true
end
for UnitID=1,#SpawnTemplate.units do
self:T('Before Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
local UnitTemplate=SpawnTemplate.units[UnitID]
local SX=UnitTemplate.x
local SY=UnitTemplate.y
local BX=SpawnTemplate.route.points[1].x
local BY=SpawnTemplate.route.points[1].y
local TX=PointVec3.x+(SX-BX)
local TY=PointVec3.z+(SY-BY)
SpawnTemplate.units[UnitID].x=TX
SpawnTemplate.units[UnitID].y=TY
SpawnTemplate.units[UnitID].alt=PointVec3.y
SpawnTemplate.units[UnitID].heading=heading
SpawnTemplate.units[UnitID].psi=-heading
if livery then
SpawnTemplate.units[UnitID].livery_id=livery
end
if self.actype then
SpawnTemplate.units[UnitID]["type"]=self.actype
end
SpawnTemplate.units[UnitID]["skill"]=self.skill
SpawnTemplate.units[UnitID]["onboard_num"]=self.SpawnIndex
SpawnTemplate.CoalitionID=self.coalition
if self.country then
SpawnTemplate.CountryID=self.country
end
UnitTemplate.parking=nil
UnitTemplate.parking_id=self.parking_id
UnitTemplate.alt=PointVec3.y
self:T('After Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
end
for i,wp in ipairs(waypoints)do
SpawnTemplate.route.points[i]=wp
end
SpawnTemplate.x=PointVec3.x
SpawnTemplate.y=PointVec3.z
if self.radio then
SpawnTemplate.communication=self.radio
end
if self.frequency then
SpawnTemplate.frequency=self.frequency
end
if self.modulation then
SpawnTemplate.modulation=self.modulation
end
self:T(SpawnTemplate)
end
end
end
function RAT:_ATCInit(airports_map)
if not RAT.ATC.init then
env.info(RAT.id.."Starting RAT ATC.")
env.info(RAT.id.."Simultanious = "..RAT.ATC.Nclearance)
env.info(RAT.id.."Delay        = "..RAT.ATC.delay)
RAT.ATC.init=true
for _,ap in pairs(airports_map)do
local name=ap:GetName()
RAT.ATC.airport[name]={}
RAT.ATC.airport[name].queue={}
RAT.ATC.airport[name].busy=false
RAT.ATC.airport[name].onfinal={}
RAT.ATC.airport[name].Nonfinal=0
RAT.ATC.airport[name].traffic=0
RAT.ATC.airport[name].Tlastclearance=nil
end
SCHEDULER:New(nil,RAT._ATCCheck,{self},5,15)
SCHEDULER:New(nil,RAT._ATCStatus,{self},5,60)
RAT.ATC.T0=timer.getTime()
end
end
function RAT:_ATCAddFlight(name,dest)
env.info(string.format("%sATC %s: Adding flight %s with destination %s.",RAT.id,dest,name,dest))
RAT.ATC.flight[name]={}
RAT.ATC.flight[name].destination=dest
RAT.ATC.flight[name].Tarrive=-1
RAT.ATC.flight[name].holding=-1
RAT.ATC.flight[name].Tonfinal=-1
end
function RAT:_ATCDelFlight(t,entry)
for k,_ in pairs(t)do
if k==entry then
t[entry]=nil
end
end
end
function RAT:_ATCRegisterFlight(name,time)
env.info(RAT.id.."Flight "..name.." registered at ATC for landing clearance.")
RAT.ATC.flight[name].Tarrive=time
RAT.ATC.flight[name].holding=0
end
function RAT:_ATCStatus()
local Tnow=timer.getTime()
for name,_ in pairs(RAT.ATC.flight)do
local hold=RAT.ATC.flight[name].holding
local dest=RAT.ATC.flight[name].destination
if hold>=0 then
local busy="Runway state is unknown"
if RAT.ATC.airport[dest].Nonfinal>0 then
busy="Runway is occupied by "..RAT.ATC.airport[dest].Nonfinal
else
busy="Runway is currently clear"
end
local text=string.format("ATC %s: Flight %s is holding for %i:%02d. %s.",dest,name,hold/60,hold%60,busy)
env.info(RAT.id..text)
elseif hold==RAT.ATC.onfinal then
local Tfinal=Tnow-RAT.ATC.flight[name].Tonfinal
local text=string.format("ATC %s: Flight %s is on final. Waiting %i:%02d for landing event.",dest,name,Tfinal/60,Tfinal%60)
env.info(RAT.id..text)
elseif hold==RAT.ATC.unregistered then
else
env.error(RAT.id.."Unknown holding time in RAT:_ATCStatus().")
end
end
end
function RAT:_ATCCheck()
RAT:_ATCQueue()
local Tnow=timer.getTime()
for name,_ in pairs(RAT.ATC.airport)do
for qID,flight in ipairs(RAT.ATC.airport[name].queue)do
local nqueue=#RAT.ATC.airport[name].queue
local landing1
if RAT.ATC.airport[name].Tlastclearance then
landing1=(Tnow-RAT.ATC.airport[name].Tlastclearance>RAT.ATC.delay)and RAT.ATC.airport[name].Nonfinal<RAT.ATC.Nclearance
else
landing1=false
end
local landing2=RAT.ATC.airport[name].Nonfinal==0
if not landing1 and not landing2 then
RAT.ATC.flight[flight].holding=Tnow-RAT.ATC.flight[flight].Tarrive
local text=string.format("ATC %s: Flight %s runway is busy. You are #%d of %d in landing queue. Your holding time is %i:%02d.",name,flight,qID,nqueue,RAT.ATC.flight[flight].holding/60,RAT.ATC.flight[flight].holding%60)
env.info(RAT.id..text)
else
local text=string.format("ATC %s: Flight %s was cleared for landing. Your holding time was %i:%02d.",name,flight,RAT.ATC.flight[flight].holding/60,RAT.ATC.flight[flight].holding%60)
env.info(RAT.id..text)
RAT:_ATCClearForLanding(name,flight)
end
end
end
RAT:_ATCQueue()
end
function RAT:_ATCClearForLanding(airport,flight)
RAT.ATC.flight[flight].holding=RAT.ATC.onfinal
RAT.ATC.airport[airport].busy=true
RAT.ATC.airport[airport].onfinal[flight]=flight
RAT.ATC.airport[airport].Nonfinal=RAT.ATC.airport[airport].Nonfinal+1
RAT.ATC.airport[airport].Tlastclearance=timer.getTime()
RAT.ATC.flight[flight].Tonfinal=timer.getTime()
trigger.action.setUserFlag(flight,1)
local flagvalue=trigger.misc.getUserFlag(flight)
local text1=string.format("ATC %s: Flight %s cleared for landing (flag=%d).",airport,flight,flagvalue)
local text2=string.format("ATC %s: Flight %s you are cleared for landing.",airport,flight)
env.info(RAT.id..text1)
MESSAGE:New(text2,10):ToAll()
end
function RAT:_ATCFlightLanded(name)
if RAT.ATC.flight[name]then
local dest=RAT.ATC.flight[name].destination
local Tnow=timer.getTime()
local Tfinal=Tnow-RAT.ATC.flight[name].Tonfinal
local Thold=RAT.ATC.flight[name].Tonfinal-RAT.ATC.flight[name].Tarrive
RAT.ATC.airport[dest].busy=false
RAT.ATC.airport[dest].onfinal[name]=nil
RAT.ATC.airport[dest].Nonfinal=RAT.ATC.airport[dest].Nonfinal-1
RAT:_ATCDelFlight(RAT.ATC.flight,name)
RAT.ATC.airport[dest].traffic=RAT.ATC.airport[dest].traffic+1
local TrafficPerHour=RAT.ATC.airport[dest].traffic/(timer.getTime()-RAT.ATC.T0)*3600
local text1=string.format("ATC %s: Flight %s landed. Tholding = %i:%02d, Tfinal = %i:%02d.",dest,name,Thold/60,Thold%60,Tfinal/60,Tfinal%60)
local text2=string.format("ATC %s: Number of flights still on final %d.",dest,RAT.ATC.airport[dest].Nonfinal)
local text3=string.format("ATC %s: Traffic report: Number of planes landed in total %d. Flights/hour = %3.2f.",dest,RAT.ATC.airport[dest].traffic,TrafficPerHour)
local text4=string.format("ATC %s: Flight %s landed. Welcome to %s.",dest,name,dest)
env.info(RAT.id..text1)
env.info(RAT.id..text2)
env.info(RAT.id..text3)
MESSAGE:New(text4,10):ToAll()
end
end
function RAT:_ATCQueue()
for airport,_ in pairs(RAT.ATC.airport)do
local _queue={}
for name,_ in pairs(RAT.ATC.flight)do
local Tnow=timer.getTime()
if RAT.ATC.flight[name].holding>=0 then
RAT.ATC.flight[name].holding=Tnow-RAT.ATC.flight[name].Tarrive
end
local hold=RAT.ATC.flight[name].holding
local dest=RAT.ATC.flight[name].destination
if hold>=0 and airport==dest then
_queue[#_queue+1]={name,hold}
end
end
local function compare(a,b)
return a[2]>b[2]
end
table.sort(_queue,compare)
RAT.ATC.airport[airport].queue={}
for k,v in ipairs(_queue)do
table.insert(RAT.ATC.airport[airport].queue,v[1])
end
end
end
AI_BALANCER={
ClassName="AI_BALANCER",
PatrolZones={},
AIGroups={},
Earliest=5,
Latest=60,
}
function AI_BALANCER:New(SetClient,SpawnAI)
local self=BASE:Inherit(self,FSM_SET:New(SET_GROUP:New()))
self:SetStartState("None")
self:AddTransition("*","Monitor","Monitoring")
self:AddTransition("*","Spawn","Spawning")
self:AddTransition("Spawning","Spawned","Spawned")
self:AddTransition("*","Destroy","Destroying")
self:AddTransition("*","Return","Returning")
self.SetClient=SetClient
self.SetClient:FilterOnce()
self.SpawnAI=SpawnAI
self.SpawnQueue={}
self.ToNearestAirbase=false
self.ToHomeAirbase=false
self:__Monitor(1)
return self
end
function AI_BALANCER:InitSpawnInterval(Earliest,Latest)
self.Earliest=Earliest
self.Latest=Latest
return self
end
function AI_BALANCER:ReturnToNearestAirbases(ReturnThresholdRange,ReturnAirbaseSet)
self.ToNearestAirbase=true
self.ReturnThresholdRange=ReturnThresholdRange
self.ReturnAirbaseSet=ReturnAirbaseSet
end
function AI_BALANCER:ReturnToHomeAirbase(ReturnThresholdRange)
self.ToHomeAirbase=true
self.ReturnThresholdRange=ReturnThresholdRange
end
function AI_BALANCER:onenterSpawning(SetGroup,From,Event,To,ClientName)
local AIGroup=self.SpawnAI:Spawn()
if AIGroup then
AIGroup:E("Spawning new AIGroup")
SetGroup:Add(ClientName,AIGroup)
self.SpawnQueue[ClientName]=nil
self:Spawned(AIGroup)
end
end
function AI_BALANCER:onenterDestroying(SetGroup,From,Event,To,ClientName,AIGroup)
AIGroup:Destroy()
SetGroup:Flush()
SetGroup:Remove(ClientName)
SetGroup:Flush()
end
function AI_BALANCER:onenterReturning(SetGroup,From,Event,To,AIGroup)
local AIGroupTemplate=AIGroup:GetTemplate()
if self.ToHomeAirbase==true then
local WayPointCount=#AIGroupTemplate.route.points
local SwitchWayPointCommand=AIGroup:CommandSwitchWayPoint(1,WayPointCount,1)
AIGroup:SetCommand(SwitchWayPointCommand)
AIGroup:MessageToRed("Returning to home base ...",30)
else
local PointVec2=POINT_VEC2:New(AIGroup:GetVec2().x,AIGroup:GetVec2().y)
local ClosestAirbase=self.ReturnAirbaseSet:FindNearestAirbaseFromPointVec2(PointVec2)
self:T(ClosestAirbase.AirbaseName)
AIGroup:MessageToRed("Returning to "..ClosestAirbase:GetName().." ...",30)
local RTBRoute=AIGroup:RouteReturnToAirbase(ClosestAirbase)
AIGroupTemplate.route=RTBRoute
AIGroup:Respawn(AIGroupTemplate)
end
end
function AI_BALANCER:onenterMonitoring(SetGroup)
self:T2({self.SetClient:Count()})
self.SetClient:ForEachClient(
function(Client)
self:T3(Client.ClientName)
local AIGroup=self.Set:Get(Client.UnitName)
if Client:IsAlive()then
if AIGroup and AIGroup:IsAlive()==true then
if self.ToNearestAirbase==false and self.ToHomeAirbase==false then
self:Destroy(Client.UnitName,AIGroup)
else
local PlayerInRange={Value=false}
local RangeZone=ZONE_RADIUS:New('RangeZone',AIGroup:GetVec2(),self.ReturnThresholdRange)
self:T2(RangeZone)
_DATABASE:ForEachPlayer(
function(RangeTestUnit,RangeZone,AIGroup,PlayerInRange)
self:T2({PlayerInRange,RangeTestUnit.UnitName,RangeZone.ZoneName})
if RangeTestUnit:IsInZone(RangeZone)==true then
self:T2("in zone")
if RangeTestUnit:GetCoalition()~=AIGroup:GetCoalition()then
self:T2("in range")
PlayerInRange.Value=true
end
end
end,
function(RangeZone,AIGroup,PlayerInRange)
if PlayerInRange.Value==false then
self:Return(AIGroup)
end
end
,RangeZone,AIGroup,PlayerInRange
)
end
self.Set:Remove(Client.UnitName)
end
else
if not AIGroup or not AIGroup:IsAlive()==true then
self:T("Client "..Client.UnitName.." not alive.")
if not self.SpawnQueue[Client.UnitName]then
self:__Spawn(math.random(self.Earliest,self.Latest),Client.UnitName)
self.SpawnQueue[Client.UnitName]=true
self:E("New AI Spawned for Client "..Client.UnitName)
end
end
end
return true
end
)
self:__Monitor(10)
end
AI_A2A={
ClassName="AI_A2A",
}
function AI_A2A:New(AIGroup)
local self=BASE:Inherit(self,FSM_CONTROLLABLE:New())
self:SetControllable(AIGroup)
self:SetFuelThreshold(.2,60)
self:SetDamageThreshold(0.4)
self:SetDisengageRadius(70000)
self:SetStartState("Stopped")
self:AddTransition("*","Start","Started")
self:AddTransition("*","Stop","Stopped")
self:AddTransition("*","Status","*")
self:AddTransition("*","RTB","*")
self:AddTransition("Patrolling","Refuel","Refuelling")
self:AddTransition("*","Takeoff","Airborne")
self:AddTransition("*","Return","Returning")
self:AddTransition("*","Hold","Holding")
self:AddTransition("*","Home","Home")
self:AddTransition("*","LostControl","LostControl")
self:AddTransition("*","Fuel","Fuel")
self:AddTransition("*","Damaged","Damaged")
self:AddTransition("*","Eject","*")
self:AddTransition("*","Crash","Crashed")
self:AddTransition("*","PilotDead","*")
self.IdleCount=0
return self
end
function GROUP:OnEventTakeoff(EventData,Fsm)
Fsm:Takeoff()
self:UnHandleEvent(EVENTS.Takeoff)
end
function AI_A2A:SetDispatcher(Dispatcher)
self.Dispatcher=Dispatcher
end
function AI_A2A:GetDispatcher()
return self.Dispatcher
end
function AI_A2A:SetTargetDistance(Coordinate)
local CurrentCoord=self.Controllable:GetCoordinate()
self.TargetDistance=CurrentCoord:Get2DDistance(Coordinate)
self.ClosestTargetDistance=(not self.ClosestTargetDistance or self.ClosestTargetDistance>self.TargetDistance)and self.TargetDistance or self.ClosestTargetDistance
end
function AI_A2A:ClearTargetDistance()
self.TargetDistance=nil
self.ClosestTargetDistance=nil
end
function AI_A2A:SetSpeed(PatrolMinSpeed,PatrolMaxSpeed)
self:F2({PatrolMinSpeed,PatrolMaxSpeed})
self.PatrolMinSpeed=PatrolMinSpeed
self.PatrolMaxSpeed=PatrolMaxSpeed
end
function AI_A2A:SetAltitude(PatrolFloorAltitude,PatrolCeilingAltitude)
self:F2({PatrolFloorAltitude,PatrolCeilingAltitude})
self.PatrolFloorAltitude=PatrolFloorAltitude
self.PatrolCeilingAltitude=PatrolCeilingAltitude
end
function AI_A2A:SetHomeAirbase(HomeAirbase)
self:F2({HomeAirbase})
self.HomeAirbase=HomeAirbase
end
function AI_A2A:SetTanker(TankerName)
self:F2({TankerName})
self.TankerName=TankerName
end
function AI_A2A:SetDisengageRadius(DisengageRadius)
self:F2({DisengageRadius})
self.DisengageRadius=DisengageRadius
end
function AI_A2A:SetStatusOff()
self:F2()
self.CheckStatus=false
end
function AI_A2A:SetFuelThreshold(PatrolFuelThresholdPercentage,PatrolOutOfFuelOrbitTime)
self.PatrolManageFuel=true
self.PatrolFuelThresholdPercentage=PatrolFuelThresholdPercentage
self.PatrolOutOfFuelOrbitTime=PatrolOutOfFuelOrbitTime
self.Controllable:OptionRTBBingoFuel(false)
return self
end
function AI_A2A:SetDamageThreshold(PatrolDamageThreshold)
self.PatrolManageDamage=true
self.PatrolDamageThreshold=PatrolDamageThreshold
return self
end
function AI_A2A:onafterStart(Controllable,From,Event,To)
self:F2()
self:__Status(10)
self:HandleEvent(EVENTS.PilotDead,self.OnPilotDead)
self:HandleEvent(EVENTS.Crash,self.OnCrash)
self:HandleEvent(EVENTS.Ejection,self.OnEjection)
Controllable:OptionROEHoldFire()
Controllable:OptionROTVertical()
end
function AI_A2A:onbeforeStatus()
return self.CheckStatus
end
function AI_A2A:onafterStatus()
self:F(" Checking Status")
if self.Controllable and self.Controllable:IsAlive()then
local RTB=false
local DistanceFromHomeBase=self.HomeAirbase:GetCoordinate():Get2DDistance(self.Controllable:GetCoordinate())
if not self:Is("Holding")and not self:Is("Returning")then
local DistanceFromHomeBase=self.HomeAirbase:GetCoordinate():Get2DDistance(self.Controllable:GetCoordinate())
self:F({DistanceFromHomeBase=DistanceFromHomeBase})
if DistanceFromHomeBase>self.DisengageRadius then
self:E(self.Controllable:GetName().." is too far from home base, RTB!")
self:Hold(300)
RTB=false
end
end
if self:Is("Fuel")or self:Is("Damaged")or self:Is("LostControl")then
if DistanceFromHomeBase<5000 then
self:E(self.Controllable:GetName().." is too far from home base, RTB!")
self:Home("Destroy")
end
end
if not self:Is("Fuel")and not self:Is("Home")then
local Fuel=self.Controllable:GetFuel()
self:F({Fuel=Fuel})
if Fuel<self.PatrolFuelThresholdPercentage then
if self.TankerName then
self:E(self.Controllable:GetName().." is out of fuel: "..Fuel.." ... Refuelling at Tanker!")
self:Refuel()
else
self:E(self.Controllable:GetName().." is out of fuel: "..Fuel.." ... RTB!")
local OldAIControllable=self.Controllable
local OrbitTask=OldAIControllable:TaskOrbitCircle(math.random(self.PatrolFloorAltitude,self.PatrolCeilingAltitude),self.PatrolMinSpeed)
local TimedOrbitTask=OldAIControllable:TaskControlled(OrbitTask,OldAIControllable:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil))
OldAIControllable:SetTask(TimedOrbitTask,10)
self:Fuel()
RTB=true
end
else
end
end
local Damage=self.Controllable:GetLife()
local InitialLife=self.Controllable:GetLife0()
self:F({Damage=Damage,InitialLife=InitialLife,DamageThreshold=self.PatrolDamageThreshold})
if(Damage/InitialLife)<self.PatrolDamageThreshold then
self:E(self.Controllable:GetName().." is damaged: "..Damage.." ... RTB!")
self:Damaged()
RTB=true
self:SetStatusOff()
end
if self.Controllable:HasTask()==false then
if not self:Is("Started")and
not self:Is("Stopped")and
not self:Is("Home")then
if self.IdleCount>=2 then
if Damage~=InitialLife then
self:Damaged()
else
self:E(self.Controllable:GetName().." control lost! ")
self:LostControl()
end
else
self.IdleCount=self.IdleCount+1
end
end
else
self.IdleCount=0
end
if RTB==true then
self:__RTB(0.5)
end
self:__Status(10)
end
end
function AI_A2A.RTBRoute(AIGroup,Fsm)
AIGroup:F({"AI_A2A.RTBRoute:",AIGroup:GetName()})
if AIGroup:IsAlive()then
Fsm:__RTB(0.5)
end
end
function AI_A2A.RTBHold(AIGroup,Fsm)
AIGroup:F({"AI_A2A.RTBHold:",AIGroup:GetName()})
if AIGroup:IsAlive()then
Fsm:__RTB(0.5)
Fsm:Return()
local Task=AIGroup:TaskOrbitCircle(4000,400)
AIGroup:SetTask(Task)
end
end
function AI_A2A:onafterRTB(AIGroup,From,Event,To)
self:F({AIGroup,From,Event,To})
if AIGroup and AIGroup:IsAlive()then
self:E("Group "..AIGroup:GetName().." ... RTB! ( "..self:GetState().." )")
self:ClearTargetDistance()
AIGroup:ClearTasks()
local EngageRoute={}
local CurrentCoord=AIGroup:GetCoordinate()
local ToTargetCoord=self.HomeAirbase:GetCoordinate()
local ToTargetSpeed=math.random(self.PatrolMinSpeed,self.PatrolMaxSpeed)
local ToAirbaseAngle=CurrentCoord:GetAngleDegrees(CurrentCoord:GetDirectionVec3(ToTargetCoord))
local Distance=CurrentCoord:Get2DDistance(ToTargetCoord)
local ToAirbaseCoord=CurrentCoord:Translate(5000,ToAirbaseAngle)
if Distance<5000 then
self:E("RTB and near the airbase!")
self:Home()
return
end
local ToRTBRoutePoint=ToAirbaseCoord:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToTargetSpeed,
true
)
self:F({Angle=ToAirbaseAngle,ToTargetSpeed=ToTargetSpeed})
self:T2({self.MinSpeed,self.MaxSpeed,ToTargetSpeed})
EngageRoute[#EngageRoute+1]=ToRTBRoutePoint
EngageRoute[#EngageRoute+1]=ToRTBRoutePoint
AIGroup:OptionROEHoldFire()
AIGroup:OptionROTEvadeFire()
AIGroup:WayPointInitialize(EngageRoute)
local Tasks={}
Tasks[#Tasks+1]=AIGroup:TaskFunction("AI_A2A.RTBRoute",self)
EngageRoute[#EngageRoute].task=AIGroup:TaskCombo(Tasks)
AIGroup:Route(EngageRoute,0.5)
end
end
function AI_A2A:onafterHome(AIGroup,From,Event,To)
self:F({AIGroup,From,Event,To})
self:E("Group "..self.Controllable:GetName().." ... Home! ( "..self:GetState().." )")
if AIGroup and AIGroup:IsAlive()then
end
end
function AI_A2A:onafterHold(AIGroup,From,Event,To,HoldTime)
self:F({AIGroup,From,Event,To})
self:E("Group "..self.Controllable:GetName().." ... Holding! ( "..self:GetState().." )")
if AIGroup and AIGroup:IsAlive()then
local OrbitTask=AIGroup:TaskOrbitCircle(math.random(self.PatrolFloorAltitude,self.PatrolCeilingAltitude),self.PatrolMinSpeed)
local TimedOrbitTask=AIGroup:TaskControlled(OrbitTask,AIGroup:TaskCondition(nil,nil,nil,nil,HoldTime,nil))
local RTBTask=AIGroup:TaskFunction("AI_A2A.RTBHold",self)
local OrbitHoldTask=AIGroup:TaskOrbitCircle(4000,self.PatrolMinSpeed)
AIGroup:SetTask(AIGroup:TaskCombo({TimedOrbitTask,RTBTask,OrbitHoldTask}),1)
end
end
function AI_A2A.Resume(AIGroup,Fsm)
AIGroup:F({"AI_A2A.Resume:",AIGroup:GetName()})
if AIGroup:IsAlive()then
Fsm:__RTB(0.5)
end
end
function AI_A2A:onafterRefuel(AIGroup,From,Event,To)
self:F({AIGroup,From,Event,To})
self:E("Group "..self.Controllable:GetName().." ... Refuelling! ( "..self:GetState().." )")
if AIGroup and AIGroup:IsAlive()then
local Tanker=GROUP:FindByName(self.TankerName)
if Tanker:IsAlive()and Tanker:IsAirPlane()then
local RefuelRoute={}
local CurrentCoord=AIGroup:GetCoordinate()
local ToRefuelCoord=Tanker:GetCoordinate()
local ToRefuelSpeed=math.random(self.PatrolMinSpeed,self.PatrolMaxSpeed)
local ToRefuelRoutePoint=ToRefuelCoord:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToRefuelSpeed,
true
)
self:F({ToRefuelSpeed=ToRefuelSpeed})
RefuelRoute[#RefuelRoute+1]=ToRefuelRoutePoint
RefuelRoute[#RefuelRoute+1]=ToRefuelRoutePoint
AIGroup:OptionROEHoldFire()
AIGroup:OptionROTEvadeFire()
local Tasks={}
Tasks[#Tasks+1]=AIGroup:TaskRefueling()
Tasks[#Tasks+1]=AIGroup:TaskFunction(self:GetClassName()..".Resume",self)
RefuelRoute[#RefuelRoute].task=AIGroup:TaskCombo(Tasks)
AIGroup:Route(RefuelRoute,0.5)
else
self:RTB()
end
end
end
function AI_A2A:onafterDead()
self:SetStatusOff()
end
function AI_A2A:OnCrash(EventData)
if self.Controllable:IsAlive()and EventData.IniDCSGroupName==self.Controllable:GetName()then
self:E(self.Controllable:GetUnits())
if#self.Controllable:GetUnits()==1 then
self:__Crash(1,EventData)
end
end
end
function AI_A2A:OnEjection(EventData)
if self.Controllable:IsAlive()and EventData.IniDCSGroupName==self.Controllable:GetName()then
self:__Eject(1,EventData)
end
end
function AI_A2A:OnPilotDead(EventData)
if self.Controllable:IsAlive()and EventData.IniDCSGroupName==self.Controllable:GetName()then
self:__PilotDead(1,EventData)
end
end
AI_A2A_PATROL={
ClassName="AI_A2A_PATROL",
}
function AI_A2A_PATROL:New(AIPatrol,PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,PatrolAltType)
local self=BASE:Inherit(self,AI_A2A:New(AIPatrol))
self.PatrolZone=PatrolZone
self.PatrolFloorAltitude=PatrolFloorAltitude
self.PatrolCeilingAltitude=PatrolCeilingAltitude
self.PatrolMinSpeed=PatrolMinSpeed
self.PatrolMaxSpeed=PatrolMaxSpeed
self.PatrolAltType=PatrolAltType or"RADIO"
self:AddTransition({"Started","Airborne","Refuelling"},"Patrol","Patrolling")
self:AddTransition("Patrolling","Route","Patrolling")
self:AddTransition("*","Reset","Patrolling")
return self
end
function AI_A2A_PATROL:SetSpeed(PatrolMinSpeed,PatrolMaxSpeed)
self:F2({PatrolMinSpeed,PatrolMaxSpeed})
self.PatrolMinSpeed=PatrolMinSpeed
self.PatrolMaxSpeed=PatrolMaxSpeed
end
function AI_A2A_PATROL:SetAltitude(PatrolFloorAltitude,PatrolCeilingAltitude)
self:F2({PatrolFloorAltitude,PatrolCeilingAltitude})
self.PatrolFloorAltitude=PatrolFloorAltitude
self.PatrolCeilingAltitude=PatrolCeilingAltitude
end
function AI_A2A_PATROL:onafterPatrol(AIPatrol,From,Event,To)
self:F2()
self:ClearTargetDistance()
self:__Route(1)
AIPatrol:OnReSpawn(
function(PatrolGroup)
self:E("ReSpawn")
self:__Reset(1)
self:__Route(5)
end
)
end
function AI_A2A_PATROL.PatrolRoute(AIPatrol,Fsm)
AIPatrol:F({"AI_A2A_PATROL.PatrolRoute:",AIPatrol:GetName()})
if AIPatrol:IsAlive()then
Fsm:Route()
end
end
function AI_A2A_PATROL:onafterRoute(AIPatrol,From,Event,To)
self:F2()
if From=="RTB"then
return
end
if AIPatrol:IsAlive()then
local PatrolRoute={}
local CurrentCoord=AIPatrol:GetCoordinate()
local ToTargetCoord=self.PatrolZone:GetRandomPointVec2()
ToTargetCoord:SetAlt(math.random(self.PatrolFloorAltitude,self.PatrolCeilingAltitude))
self:SetTargetDistance(ToTargetCoord)
local ToTargetSpeed=math.random(self.PatrolMinSpeed,self.PatrolMaxSpeed)
local ToPatrolRoutePoint=ToTargetCoord:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToTargetSpeed,
true
)
PatrolRoute[#PatrolRoute+1]=ToPatrolRoutePoint
PatrolRoute[#PatrolRoute+1]=ToPatrolRoutePoint
local Tasks={}
Tasks[#Tasks+1]=AIPatrol:TaskFunction("AI_A2A_PATROL.PatrolRoute",self)
PatrolRoute[#PatrolRoute].task=AIPatrol:TaskCombo(Tasks)
AIPatrol:OptionROEReturnFire()
AIPatrol:OptionROTEvadeFire()
AIPatrol:Route(PatrolRoute,0.5)
end
end
function AI_A2A_PATROL.Resume(AIPatrol)
AIPatrol:F({"AI_A2A_PATROL.Resume:",AIPatrol:GetName()})
if AIPatrol:IsAlive()then
local _AI_A2A=AIPatrol:GetState(AIPatrol,"AI_A2A")
_AI_A2A:__Reset(1)
_AI_A2A:__Route(5)
end
end
AI_A2A_CAP={
ClassName="AI_A2A_CAP",
}
function AI_A2A_CAP:New(AICap,PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,EngageMinSpeed,EngageMaxSpeed,PatrolAltType)
local self=BASE:Inherit(self,AI_A2A_PATROL:New(AICap,PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,PatrolAltType))
self.Accomplished=false
self.Engaging=false
self.EngageMinSpeed=EngageMinSpeed
self.EngageMaxSpeed=EngageMaxSpeed
self:AddTransition({"Patrolling","Engaging","Returning","Airborne"},"Engage","Engaging")
self:AddTransition("Engaging","Fired","Engaging")
self:AddTransition("*","Destroy","*")
self:AddTransition("Engaging","Abort","Patrolling")
self:AddTransition("Engaging","Accomplish","Patrolling")
return self
end
function AI_A2A_CAP:onafterStart(AICap,From,Event,To)
AICap:HandleEvent(EVENTS.Takeoff,nil,self)
end
function AI_A2A_CAP:SetEngageZone(EngageZone)
self:F2()
if EngageZone then
self.EngageZone=EngageZone
else
self.EngageZone=nil
end
end
function AI_A2A_CAP:SetEngageRange(EngageRange)
self:F2()
if EngageRange then
self.EngageRange=EngageRange
else
self.EngageRange=nil
end
end
function AI_A2A_CAP:onafterPatrol(AICap,From,Event,To)
self:GetParent(self).onafterPatrol(self,AICap,From,Event,To)
self:HandleEvent(EVENTS.Dead)
end
function AI_A2A_CAP.AttackRoute(AICap,Fsm)
AICap:F({"AI_A2A_CAP.AttackRoute:",AICap:GetName()})
if AICap:IsAlive()then
Fsm:__Engage(0.5)
end
end
function AI_A2A_CAP:onbeforeEngage(AICap,From,Event,To)
if self.Accomplished==true then
return false
end
end
function AI_A2A_CAP:onafterAbort(AICap,From,Event,To)
AICap:ClearTasks()
self:__Route(0.5)
end
function AI_A2A_CAP:onafterEngage(AICap,From,Event,To,AttackSetUnit)
self:F({AICap,From,Event,To,AttackSetUnit})
self.AttackSetUnit=AttackSetUnit or self.AttackSetUnit
local FirstAttackUnit=self.AttackSetUnit:GetFirst()
if FirstAttackUnit and FirstAttackUnit:IsAlive()then
if AICap:IsAlive()then
local EngageRoute={}
local CurrentCoord=AICap:GetCoordinate()
local ToTargetCoord=self.AttackSetUnit:GetFirst():GetCoordinate()
local ToTargetSpeed=math.random(self.EngageMinSpeed,self.EngageMaxSpeed)
local ToInterceptAngle=CurrentCoord:GetAngleDegrees(CurrentCoord:GetDirectionVec3(ToTargetCoord))
local ToPatrolRoutePoint=CurrentCoord:Translate(5000,ToInterceptAngle):WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToTargetSpeed,
true
)
self:F({Angle=ToInterceptAngle,ToTargetSpeed=ToTargetSpeed})
self:T2({self.MinSpeed,self.MaxSpeed,ToTargetSpeed})
EngageRoute[#EngageRoute+1]=ToPatrolRoutePoint
EngageRoute[#EngageRoute+1]=ToPatrolRoutePoint
local AttackTasks={}
for AttackUnitID,AttackUnit in pairs(self.AttackSetUnit:GetSet())do
local AttackUnit=AttackUnit
self:T({"Attacking Unit:",AttackUnit:GetName(),AttackUnit:IsAlive(),AttackUnit:IsAir()})
if AttackUnit:IsAlive()and AttackUnit:IsAir()then
AttackTasks[#AttackTasks+1]=AICap:TaskAttackUnit(AttackUnit)
end
end
if#AttackTasks==0 then
self:E("No targets found -> Going back to Patrolling")
self:__Abort(0.5)
else
AICap:OptionROEOpenFire()
AICap:OptionROTEvadeFire()
AttackTasks[#AttackTasks+1]=AICap:TaskFunction("AI_A2A_CAP.AttackRoute",self)
EngageRoute[#EngageRoute].task=AICap:TaskCombo(AttackTasks)
end
AICap:Route(EngageRoute,0.5)
end
else
self:E("No targets found -> Going back to Patrolling")
self:__Abort(0.5)
end
end
function AI_A2A_CAP:onafterAccomplish(AICap,From,Event,To)
self.Accomplished=true
self:SetDetectionOff()
end
function AI_A2A_CAP:onafterDestroy(AICap,From,Event,To,EventData)
if EventData.IniUnit then
self.AttackUnits[EventData.IniUnit]=nil
end
end
function AI_A2A_CAP:OnEventDead(EventData)
self:F({"EventDead",EventData})
if EventData.IniDCSUnit then
if self.AttackUnits and self.AttackUnits[EventData.IniUnit]then
self:__Destroy(1,EventData)
end
end
end
function AI_A2A_CAP.Resume(AICap)
AICap:F({"AI_A2A_CAP.Resume:",AICap:GetName()})
if AICap:IsAlive()then
local _AI_A2A=AICap:GetState(AICap,"AI_A2A")
_AI_A2A:__Reset(1)
_AI_A2A:__Route(5)
end
end
AI_A2A_GCI={
ClassName="AI_A2A_GCI",
}
function AI_A2A_GCI:New(AIIntercept,EngageMinSpeed,EngageMaxSpeed)
local self=BASE:Inherit(self,AI_A2A:New(AIIntercept))
self.Accomplished=false
self.Engaging=false
self.EngageMinSpeed=EngageMinSpeed
self.EngageMaxSpeed=EngageMaxSpeed
self.PatrolMinSpeed=EngageMinSpeed
self.PatrolMaxSpeed=EngageMaxSpeed
self.PatrolAltType="RADIO"
self:AddTransition({"Started","Engaging","Returning","Airborne"},"Engage","Engaging")
self:AddTransition("Engaging","Fired","Engaging")
self:AddTransition("*","Destroy","*")
self:AddTransition("Engaging","Abort","Patrolling")
self:AddTransition("Engaging","Accomplish","Patrolling")
return self
end
function AI_A2A_GCI:onafterStart(AIIntercept,From,Event,To)
AIIntercept:HandleEvent(EVENTS.Takeoff,nil,self)
end
function AI_A2A_GCI:onafterEngage(AIIntercept,From,Event,To)
self:HandleEvent(EVENTS.Dead)
end
function AI_A2A_GCI.InterceptRoute(AIIntercept,Fsm)
AIIntercept:F({"AI_A2A_GCI.InterceptRoute:",AIIntercept:GetName()})
if AIIntercept:IsAlive()then
Fsm:__Engage(0.5)
end
end
function AI_A2A_GCI:onbeforeEngage(AIIntercept,From,Event,To)
if self.Accomplished==true then
return false
end
end
function AI_A2A_GCI:onafterAbort(AIIntercept,From,Event,To)
AIIntercept:ClearTasks()
self:Return()
self:__RTB(0.5)
end
function AI_A2A_GCI:onafterEngage(AIIntercept,From,Event,To,AttackSetUnit)
self:F({AIIntercept,From,Event,To,AttackSetUnit})
self.AttackSetUnit=AttackSetUnit or self.AttackSetUnit
local FirstAttackUnit=self.AttackSetUnit:GetFirst()
if FirstAttackUnit and FirstAttackUnit:IsAlive()then
if AIIntercept:IsAlive()then
local EngageRoute={}
local CurrentCoord=AIIntercept:GetCoordinate()
local CurrentCoord=AIIntercept:GetCoordinate()
local ToTargetCoord=self.AttackSetUnit:GetFirst():GetCoordinate()
self:SetTargetDistance(ToTargetCoord)
local ToTargetSpeed=math.random(self.EngageMinSpeed,self.EngageMaxSpeed)
local ToInterceptAngle=CurrentCoord:GetAngleDegrees(CurrentCoord:GetDirectionVec3(ToTargetCoord))
local ToPatrolRoutePoint=CurrentCoord:Translate(15000,ToInterceptAngle):WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToTargetSpeed,
true
)
self:F({Angle=ToInterceptAngle,ToTargetSpeed=ToTargetSpeed})
self:F({self.EngageMinSpeed,self.EngageMaxSpeed,ToTargetSpeed})
EngageRoute[#EngageRoute+1]=ToPatrolRoutePoint
EngageRoute[#EngageRoute+1]=ToPatrolRoutePoint
local AttackTasks={}
for AttackUnitID,AttackUnit in pairs(self.AttackSetUnit:GetSet())do
local AttackUnit=AttackUnit
if AttackUnit:IsAlive()and AttackUnit:IsAir()then
self:T({"Intercepting Unit:",AttackUnit:GetName(),AttackUnit:IsAlive(),AttackUnit:IsAir()})
AttackTasks[#AttackTasks+1]=AIIntercept:TaskAttackUnit(AttackUnit)
end
end
if#AttackTasks==0 then
self:E("No targets found -> Going RTB")
self:Return()
self:__RTB(0.5)
else
AIIntercept:OptionROEOpenFire()
AIIntercept:OptionROTEvadeFire()
AttackTasks[#AttackTasks+1]=AIIntercept:TaskFunction("AI_A2A_GCI.InterceptRoute",self)
EngageRoute[#EngageRoute].task=AIIntercept:TaskCombo(AttackTasks)
end
AIIntercept:Route(EngageRoute,0.5)
end
else
self:E("No targets found -> Going RTB")
self:Return()
self:__RTB(0.5)
end
end
function AI_A2A_GCI:onafterAccomplish(AIIntercept,From,Event,To)
self.Accomplished=true
self:SetDetectionOff()
end
function AI_A2A_GCI:onafterDestroy(AIIntercept,From,Event,To,EventData)
if EventData.IniUnit then
self.AttackUnits[EventData.IniUnit]=nil
end
end
function AI_A2A_GCI:OnEventDead(EventData)
self:F({"EventDead",EventData})
if EventData.IniDCSUnit then
if self.AttackUnits and self.AttackUnits[EventData.IniUnit]then
self:__Destroy(1,EventData)
end
end
end
do
AI_A2A_DISPATCHER={
ClassName="AI_A2A_DISPATCHER",
Detection=nil,
}
AI_A2A_DISPATCHER.Takeoff=GROUP.Takeoff
AI_A2A_DISPATCHER.Landing={
NearAirbase=1,
AtRunway=2,
AtEngineShutdown=3,
}
function AI_A2A_DISPATCHER:New(Detection)
local self=BASE:Inherit(self,DETECTION_MANAGER:New(nil,Detection))
self.Detection=Detection
self.DefenderSquadrons={}
self.DefenderSpawns={}
self.DefenderTasks={}
self.DefenderDefault={}
self.Detection:FilterCategories({Unit.Category.AIRPLANE,Unit.Category.HELICOPTER})
self.Detection:SetRefreshTimeInterval(30)
self:SetEngageRadius()
self:SetGciRadius()
self:SetIntercept(300)
self:SetDisengageRadius(300000)
self:SetDefaultTakeoff(AI_A2A_DISPATCHER.Takeoff.Air)
self:SetDefaultTakeoffInAirAltitude(500)
self:SetDefaultLanding(AI_A2A_DISPATCHER.Landing.NearAirbase)
self:SetDefaultOverhead(1)
self:SetDefaultGrouping(1)
self:SetDefaultFuelThreshold(0.15,0)
self:SetDefaultDamageThreshold(0.4)
self:SetDefaultCapTimeInterval(180,600)
self:SetDefaultCapLimit(1)
self:AddTransition("Started","Assign","Started")
self:AddTransition("*","CAP","*")
self:AddTransition("*","GCI","*")
self:AddTransition("*","ENGAGE","*")
self:HandleEvent(EVENTS.Crash,self.OnEventCrashOrDead)
self:HandleEvent(EVENTS.Dead,self.OnEventCrashOrDead)
self:HandleEvent(EVENTS.Land)
self:HandleEvent(EVENTS.EngineShutdown)
self:SetTacticalDisplay(false)
self:__Start(5)
return self
end
function AI_A2A_DISPATCHER:OnEventCrashOrDead(EventData)
self.Detection:ForgetDetectedUnit(EventData.IniUnitName)
end
function AI_A2A_DISPATCHER:OnEventLand(EventData)
self:E("Landed")
local DefenderUnit=EventData.IniUnit
local Defender=EventData.IniGroup
local Squadron=self:GetSquadronFromDefender(Defender)
if Squadron then
self:F({SquadronName=Squadron.Name})
local LandingMethod=self:GetSquadronLanding(Squadron.Name)
if LandingMethod==AI_A2A_DISPATCHER.Landing.AtRunway then
local DefenderSize=Defender:GetSize()
if DefenderSize==1 then
self:RemoveDefenderFromSquadron(Squadron,Defender)
end
DefenderUnit:Destroy()
return
end
if DefenderUnit:GetLife()~=DefenderUnit:GetLife0()then
DefenderUnit:Destroy()
return
end
if DefenderUnit:GetFuel()<=self.DefenderDefault.FuelThreshold then
DefenderUnit:Destroy()
return
end
end
end
function AI_A2A_DISPATCHER:OnEventEngineShutdown(EventData)
local DefenderUnit=EventData.IniUnit
local Defender=EventData.IniGroup
local Squadron=self:GetSquadronFromDefender(Defender)
if Squadron then
self:F({SquadronName=Squadron.Name})
local LandingMethod=self:GetSquadronLanding(Squadron.Name)
if LandingMethod==AI_A2A_DISPATCHER.Landing.AtEngineShutdown then
local DefenderSize=Defender:GetSize()
if DefenderSize==1 then
self:RemoveDefenderFromSquadron(Squadron,Defender)
end
DefenderUnit:Destroy()
end
end
end
function AI_A2A_DISPATCHER:SetEngageRadius(EngageRadius)
self.Detection:SetFriendliesRange(EngageRadius or 100000)
return self
end
function AI_A2A_DISPATCHER:SetDisengageRadius(DisengageRadius)
self.DisengageRadius=DisengageRadius or 300000
return self
end
function AI_A2A_DISPATCHER:SetGciRadius(GciRadius)
self.GciRadius=GciRadius or 200000
return self
end
function AI_A2A_DISPATCHER:SetBorderZone(BorderZone)
self.Detection:SetAcceptZones(BorderZone)
return self
end
function AI_A2A_DISPATCHER:SetTacticalDisplay(TacticalDisplay)
self.TacticalDisplay=TacticalDisplay
return self
end
function AI_A2A_DISPATCHER:SetDefaultDamageThreshold(DamageThreshold)
self.DefenderDefault.DamageThreshold=DamageThreshold
return self
end
function AI_A2A_DISPATCHER:SetDefaultCapTimeInterval(CapMinSeconds,CapMaxSeconds)
self.DefenderDefault.CapMinSeconds=CapMinSeconds
self.DefenderDefault.CapMaxSeconds=CapMaxSeconds
return self
end
function AI_A2A_DISPATCHER:SetDefaultCapLimit(CapLimit)
self.DefenderDefault.CapLimit=CapLimit
return self
end
function AI_A2A_DISPATCHER:SetIntercept(InterceptDelay)
self.DefenderDefault.InterceptDelay=InterceptDelay
local Detection=self.Detection
Detection:SetIntercept(true,InterceptDelay)
return self
end
function AI_A2A_DISPATCHER:GetAIFriendliesNearBy(DetectedItem)
local FriendliesNearBy=self.Detection:GetFriendliesDistance(DetectedItem)
return FriendliesNearBy
end
function AI_A2A_DISPATCHER:GetDefenderTasks()
return self.DefenderTasks or{}
end
function AI_A2A_DISPATCHER:GetDefenderTask(Defender)
return self.DefenderTasks[Defender]
end
function AI_A2A_DISPATCHER:GetDefenderTaskFsm(Defender)
return self:GetDefenderTask(Defender).Fsm
end
function AI_A2A_DISPATCHER:GetDefenderTaskTarget(Defender)
return self:GetDefenderTask(Defender).Target
end
function AI_A2A_DISPATCHER:GetDefenderTaskSquadronName(Defender)
return self:GetDefenderTask(Defender).SquadronName
end
function AI_A2A_DISPATCHER:ClearDefenderTask(Defender)
if Defender:IsAlive()and self.DefenderTasks[Defender]then
local Target=self.DefenderTasks[Defender].Target
local Message="Clearing ("..self.DefenderTasks[Defender].Type..") "
Message=Message..Defender:GetName()
if Target then
Message=Message..(Target and(" from "..Target.Index.." ["..Target.Set:Count().."]"))or""
end
self:F({Target=Message})
end
self.DefenderTasks[Defender]=nil
return self
end
function AI_A2A_DISPATCHER:ClearDefenderTaskTarget(Defender)
local DefenderTask=self:GetDefenderTask(Defender)
if Defender:IsAlive()and DefenderTask then
local Target=DefenderTask.Target
local Message="Clearing ("..DefenderTask.Type..") "
Message=Message..Defender:GetName()
if Target then
Message=Message..(Target and(" from "..Target.Index.." ["..Target.Set:Count().."]"))or""
end
self:F({Target=Message})
end
if Defender and DefenderTask and DefenderTask.Target then
DefenderTask.Target=nil
end
return self
end
function AI_A2A_DISPATCHER:SetDefenderTask(SquadronName,Defender,Type,Fsm,Target)
self:F({SquadronName=SquadronName,Defender=Defender:GetName()})
self.DefenderTasks[Defender]=self.DefenderTasks[Defender]or{}
self.DefenderTasks[Defender].Type=Type
self.DefenderTasks[Defender].Fsm=Fsm
self.DefenderTasks[Defender].SquadronName=SquadronName
if Target then
self:SetDefenderTaskTarget(Defender,Target)
end
return self
end
function AI_A2A_DISPATCHER:SetDefenderTaskTarget(Defender,AttackerDetection)
local Message="("..self.DefenderTasks[Defender].Type..") "
Message=Message..Defender:GetName()
Message=Message..(AttackerDetection and(" target "..AttackerDetection.Index.." ["..AttackerDetection.Set:Count().."]"))or""
self:F({AttackerDetection=Message})
if AttackerDetection then
self.DefenderTasks[Defender].Target=AttackerDetection
end
return self
end
function AI_A2A_DISPATCHER:SetSquadron(SquadronName,AirbaseName,TemplatePrefixes,Resources)
self.DefenderSquadrons[SquadronName]=self.DefenderSquadrons[SquadronName]or{}
local DefenderSquadron=self.DefenderSquadrons[SquadronName]
DefenderSquadron.Name=SquadronName
DefenderSquadron.Airbase=AIRBASE:FindByName(AirbaseName)
if not DefenderSquadron.Airbase then
error("Cannot find airbase with name:"..AirbaseName)
end
DefenderSquadron.Spawn={}
if type(TemplatePrefixes)=="string"then
local SpawnTemplate=TemplatePrefixes
self.DefenderSpawns[SpawnTemplate]=self.DefenderSpawns[SpawnTemplate]or SPAWN:New(SpawnTemplate)
DefenderSquadron.Spawn[1]=self.DefenderSpawns[SpawnTemplate]
else
for TemplateID,SpawnTemplate in pairs(TemplatePrefixes)do
self.DefenderSpawns[SpawnTemplate]=self.DefenderSpawns[SpawnTemplate]or SPAWN:New(SpawnTemplate)
DefenderSquadron.Spawn[#DefenderSquadron.Spawn+1]=self.DefenderSpawns[SpawnTemplate]
end
end
DefenderSquadron.Resources=Resources
DefenderSquadron.TemplatePrefixes=TemplatePrefixes
self:E({Squadron={SquadronName,AirbaseName,TemplatePrefixes,Resources}})
return self
end
function AI_A2A_DISPATCHER:GetSquadron(SquadronName)
local DefenderSquadron=self.DefenderSquadrons[SquadronName]
if not DefenderSquadron then
error("Unknown Squadron:"..SquadronName)
end
return DefenderSquadron
end
function AI_A2A_DISPATCHER:SetSquadronCap(SquadronName,Zone,FloorAltitude,CeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,EngageMinSpeed,EngageMaxSpeed,AltType)
self.DefenderSquadrons[SquadronName]=self.DefenderSquadrons[SquadronName]or{}
self.DefenderSquadrons[SquadronName].Cap=self.DefenderSquadrons[SquadronName].Cap or{}
local DefenderSquadron=self:GetSquadron(SquadronName)
local Cap=self.DefenderSquadrons[SquadronName].Cap
Cap.Name=SquadronName
Cap.Zone=Zone
Cap.FloorAltitude=FloorAltitude
Cap.CeilingAltitude=CeilingAltitude
Cap.PatrolMinSpeed=PatrolMinSpeed
Cap.PatrolMaxSpeed=PatrolMaxSpeed
Cap.EngageMinSpeed=EngageMinSpeed
Cap.EngageMaxSpeed=EngageMaxSpeed
Cap.AltType=AltType
self:SetSquadronCapInterval(SquadronName,self.DefenderDefault.CapLimit,self.DefenderDefault.CapMinSeconds,self.DefenderDefault.CapMaxSeconds,1)
self:E({CAP={SquadronName,Zone,FloorAltitude,CeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,EngageMinSpeed,EngageMaxSpeed,AltType}})
local RecceSet=self.Detection:GetDetectionSetGroup()
RecceSet:FilterPrefixes(DefenderSquadron.TemplatePrefixes)
RecceSet:FilterStart()
self.Detection:SetFriendlyPrefixes(DefenderSquadron.TemplatePrefixes)
return self
end
function AI_A2A_DISPATCHER:SetSquadronCapInterval(SquadronName,CapLimit,LowInterval,HighInterval,Probability)
self.DefenderSquadrons[SquadronName]=self.DefenderSquadrons[SquadronName]or{}
self.DefenderSquadrons[SquadronName].Cap=self.DefenderSquadrons[SquadronName].Cap or{}
local DefenderSquadron=self:GetSquadron(SquadronName)
local Cap=self.DefenderSquadrons[SquadronName].Cap
if Cap then
Cap.LowInterval=LowInterval or 180
Cap.HighInterval=HighInterval or 600
Cap.Probability=Probability or 1
Cap.CapLimit=CapLimit or 1
Cap.Scheduler=Cap.Scheduler or SCHEDULER:New(self)
local Scheduler=Cap.Scheduler
local ScheduleID=Cap.ScheduleID
local Variance=(Cap.HighInterval-Cap.LowInterval)/2
local Repeat=Cap.LowInterval+Variance
local Randomization=Variance/Repeat
local Start=math.random(1,Cap.HighInterval)
if ScheduleID then
Scheduler:Stop(ScheduleID)
end
Cap.ScheduleID=Scheduler:Schedule(self,self.SchedulerCAP,{SquadronName},Start,Repeat,Randomization)
else
error("This squadron does not exist:"..SquadronName)
end
end
function AI_A2A_DISPATCHER:GetCAPDelay(SquadronName)
self.DefenderSquadrons[SquadronName]=self.DefenderSquadrons[SquadronName]or{}
self.DefenderSquadrons[SquadronName].Cap=self.DefenderSquadrons[SquadronName].Cap or{}
local DefenderSquadron=self:GetSquadron(SquadronName)
local Cap=self.DefenderSquadrons[SquadronName].Cap
if Cap then
return math.random(Cap.LowInterval,Cap.HighInterval)
else
error("This squadron does not exist:"..SquadronName)
end
end
function AI_A2A_DISPATCHER:CanCAP(SquadronName)
self:F({SquadronName=SquadronName})
self.DefenderSquadrons[SquadronName]=self.DefenderSquadrons[SquadronName]or{}
self.DefenderSquadrons[SquadronName].Cap=self.DefenderSquadrons[SquadronName].Cap or{}
local DefenderSquadron=self:GetSquadron(SquadronName)
if(not DefenderSquadron.Resources)or(DefenderSquadron.Resources and DefenderSquadron.Resources>0)then
local Cap=DefenderSquadron.Cap
if Cap then
local CapCount=self:CountCapAirborne(SquadronName)
self:E({CapCount=CapCount})
if CapCount<Cap.CapLimit then
local Probability=math.random()
if Probability<=Cap.Probability then
return DefenderSquadron
end
end
end
end
return nil
end
function AI_A2A_DISPATCHER:CanGCI(SquadronName)
self:F({SquadronName=SquadronName})
self.DefenderSquadrons[SquadronName]=self.DefenderSquadrons[SquadronName]or{}
self.DefenderSquadrons[SquadronName].Gci=self.DefenderSquadrons[SquadronName].Gci or{}
local DefenderSquadron=self:GetSquadron(SquadronName)
if(not DefenderSquadron.Resources)or(DefenderSquadron.Resources and DefenderSquadron.Resources>0)then
local Gci=DefenderSquadron.Gci
if Gci then
return DefenderSquadron
end
end
return nil
end
function AI_A2A_DISPATCHER:SetSquadronGci(SquadronName,EngageMinSpeed,EngageMaxSpeed)
self.DefenderSquadrons[SquadronName]=self.DefenderSquadrons[SquadronName]or{}
self.DefenderSquadrons[SquadronName].Gci=self.DefenderSquadrons[SquadronName].Gci or{}
local Intercept=self.DefenderSquadrons[SquadronName].Gci
Intercept.Name=SquadronName
Intercept.EngageMinSpeed=EngageMinSpeed
Intercept.EngageMaxSpeed=EngageMaxSpeed
self:E({GCI={SquadronName,EngageMinSpeed,EngageMaxSpeed}})
end
function AI_A2A_DISPATCHER:SetDefaultOverhead(Overhead)
self.DefenderDefault.Overhead=Overhead
return self
end
function AI_A2A_DISPATCHER:SetSquadronOverhead(SquadronName,Overhead)
local DefenderSquadron=self:GetSquadron(SquadronName)
DefenderSquadron.Overhead=Overhead
return self
end
function AI_A2A_DISPATCHER:SetDefaultGrouping(Grouping)
self.DefenderDefault.Grouping=Grouping
return self
end
function AI_A2A_DISPATCHER:SetSquadronGrouping(SquadronName,Grouping)
local DefenderSquadron=self:GetSquadron(SquadronName)
DefenderSquadron.Grouping=Grouping
return self
end
function AI_A2A_DISPATCHER:SetDefaultTakeoff(Takeoff)
self.DefenderDefault.Takeoff=Takeoff
return self
end
function AI_A2A_DISPATCHER:SetSquadronTakeoff(SquadronName,Takeoff)
local DefenderSquadron=self:GetSquadron(SquadronName)
DefenderSquadron.Takeoff=Takeoff
return self
end
function AI_A2A_DISPATCHER:GetDefaultTakeoff()
return self.DefenderDefault.Takeoff
end
function AI_A2A_DISPATCHER:GetSquadronTakeoff(SquadronName)
local DefenderSquadron=self:GetSquadron(SquadronName)
return DefenderSquadron.Takeoff or self.DefenderDefault.Takeoff
end
function AI_A2A_DISPATCHER:SetDefaultTakeoffInAir()
self:SetDefaultTakeoff(AI_A2A_DISPATCHER.Takeoff.Air)
return self
end
function AI_A2A_DISPATCHER:SetSquadronTakeoffInAir(SquadronName,TakeoffAltitude)
self:SetSquadronTakeoff(SquadronName,AI_A2A_DISPATCHER.Takeoff.Air)
if TakeoffAltitude then
self:SetSquadronTakeoffInAirAltitude(SquadronName,TakeoffAltitude)
end
return self
end
function AI_A2A_DISPATCHER:SetDefaultTakeoffFromRunway()
self:SetDefaultTakeoff(AI_A2A_DISPATCHER.Takeoff.Runway)
return self
end
function AI_A2A_DISPATCHER:SetSquadronTakeoffFromRunway(SquadronName)
self:SetSquadronTakeoff(SquadronName,AI_A2A_DISPATCHER.Takeoff.Runway)
return self
end
function AI_A2A_DISPATCHER:SetDefaultTakeoffFromParkingHot()
self:SetDefaultTakeoff(AI_A2A_DISPATCHER.Takeoff.Hot)
return self
end
function AI_A2A_DISPATCHER:SetSquadronTakeoffFromParkingHot(SquadronName)
self:SetSquadronTakeoff(SquadronName,AI_A2A_DISPATCHER.Takeoff.Hot)
return self
end
function AI_A2A_DISPATCHER:SetDefaultTakeoffFromParkingCold()
self:SetDefaultTakeoff(AI_A2A_DISPATCHER.Takeoff.Cold)
return self
end
function AI_A2A_DISPATCHER:SetSquadronTakeoffFromParkingCold(SquadronName)
self:SetSquadronTakeoff(SquadronName,AI_A2A_DISPATCHER.Takeoff.Cold)
return self
end
function AI_A2A_DISPATCHER:SetDefaultTakeoffInAirAltitude(TakeoffAltitude)
self.DefenderDefault.TakeoffAltitude=TakeoffAltitude
return self
end
function AI_A2A_DISPATCHER:SetSquadronTakeoffInAirAltitude(SquadronName,TakeoffAltitude)
local DefenderSquadron=self:GetSquadron(SquadronName)
DefenderSquadron.TakeoffAltitude=TakeoffAltitude
return self
end
function AI_A2A_DISPATCHER:SetDefaultLanding(Landing)
self.DefenderDefault.Landing=Landing
return self
end
function AI_A2A_DISPATCHER:SetSquadronLanding(SquadronName,Landing)
local DefenderSquadron=self:GetSquadron(SquadronName)
DefenderSquadron.Landing=Landing
return self
end
function AI_A2A_DISPATCHER:GetDefaultLanding()
return self.DefenderDefault.Landing
end
function AI_A2A_DISPATCHER:GetSquadronLanding(SquadronName)
local DefenderSquadron=self:GetSquadron(SquadronName)
return DefenderSquadron.Landing or self.DefenderDefault.Landing
end
function AI_A2A_DISPATCHER:SetDefaultLandingNearAirbase()
self:SetDefaultLanding(AI_A2A_DISPATCHER.Landing.NearAirbase)
return self
end
function AI_A2A_DISPATCHER:SetSquadronLandingNearAirbase(SquadronName)
self:SetSquadronLanding(SquadronName,AI_A2A_DISPATCHER.Landing.NearAirbase)
return self
end
function AI_A2A_DISPATCHER:SetDefaultLandingAtRunway()
self:SetDefaultLanding(AI_A2A_DISPATCHER.Landing.AtRunway)
return self
end
function AI_A2A_DISPATCHER:SetSquadronLandingAtRunway(SquadronName)
self:SetSquadronLanding(SquadronName,AI_A2A_DISPATCHER.Landing.AtRunway)
return self
end
function AI_A2A_DISPATCHER:SetDefaultLandingAtEngineShutdown()
self:SetDefaultLanding(AI_A2A_DISPATCHER.Landing.AtEngineShutdown)
return self
end
function AI_A2A_DISPATCHER:SetSquadronLandingAtEngineShutdown(SquadronName)
self:SetSquadronLanding(SquadronName,AI_A2A_DISPATCHER.Landing.AtEngineShutdown)
return self
end
function AI_A2A_DISPATCHER:SetDefaultFuelThreshold(FuelThreshold)
self.DefenderDefault.FuelThreshold=FuelThreshold
return self
end
function AI_A2A_DISPATCHER:SetSquadronFuelThreshold(SquadronName,FuelThreshold)
local DefenderSquadron=self:GetSquadron(SquadronName)
DefenderSquadron.FuelThreshold=FuelThreshold
return self
end
function AI_A2A_DISPATCHER:SetDefaultTanker(TankerName)
self.DefenderDefault.TankerName=TankerName
return self
end
function AI_A2A_DISPATCHER:SetSquadronTanker(SquadronName,TankerName)
local DefenderSquadron=self:GetSquadron(SquadronName)
DefenderSquadron.TankerName=TankerName
return self
end
function AI_A2A_DISPATCHER:AddDefenderToSquadron(Squadron,Defender,Size)
self.Defenders=self.Defenders or{}
local DefenderName=Defender:GetName()
self.Defenders[DefenderName]=Squadron
if Squadron.Resources then
Squadron.Resources=Squadron.Resources-Size
end
self:E({DefenderName=DefenderName,SquadronResources=Squadron.Resources})
end
function AI_A2A_DISPATCHER:RemoveDefenderFromSquadron(Squadron,Defender)
self.Defenders=self.Defenders or{}
local DefenderName=Defender:GetName()
if Squadron.Resources then
Squadron.Resources=Squadron.Resources+Defender:GetSize()
end
self.Defenders[DefenderName]=nil
self:F({DefenderName=DefenderName,SquadronResources=Squadron.Resources})
end
function AI_A2A_DISPATCHER:GetSquadronFromDefender(Defender)
self.Defenders=self.Defenders or{}
local DefenderName=Defender:GetName()
self:F({DefenderName=DefenderName})
return self.Defenders[DefenderName]
end
function AI_A2A_DISPATCHER:EvaluateSWEEP(DetectedItem)
self:F({DetectedItem.ItemID})
local DetectedSet=DetectedItem.Set
local DetectedZone=DetectedItem.Zone
if DetectedItem.IsDetected==false then
local TargetSetUnit=SET_UNIT:New()
TargetSetUnit:SetDatabase(DetectedSet)
TargetSetUnit:FilterOnce()
return TargetSetUnit
end
return nil
end
function AI_A2A_DISPATCHER:CountCapAirborne(SquadronName)
local CapCount=0
local DefenderSquadron=self.DefenderSquadrons[SquadronName]
if DefenderSquadron then
for AIGroup,DefenderTask in pairs(self:GetDefenderTasks())do
if DefenderTask.SquadronName==SquadronName then
if DefenderTask.Type=="CAP"then
if AIGroup:IsAlive()then
if DefenderTask.Fsm:Is("Patrolling")or DefenderTask.Fsm:Is("Engaging")or DefenderTask.Fsm:Is("Refuelling")then
CapCount=CapCount+1
end
end
end
end
end
end
return CapCount
end
function AI_A2A_DISPATCHER:CountDefendersEngaged(AttackerDetection)
local DefenderCount=0
self:E("Counting Defenders Engaged for Attacker:")
local DetectedSet=AttackerDetection.Set
DetectedSet:Flush()
local DefenderTasks=self:GetDefenderTasks()
for DefenderGroup,DefenderTask in pairs(DefenderTasks)do
local Defender=DefenderGroup
local DefenderTaskTarget=DefenderTask.Target
local DefenderSquadronName=DefenderTask.SquadronName
if DefenderTaskTarget and DefenderTaskTarget.Index==AttackerDetection.Index then
local Squadron=self:GetSquadron(DefenderSquadronName)
local SquadronOverhead=Squadron.Overhead or self.DefenderDefault.Overhead
local DefenderSize=Defender:GetInitialSize()
DefenderCount=DefenderCount+DefenderSize/SquadronOverhead
self:F("Defender Group Name: "..Defender:GetName()..", Size: "..DefenderSize)
end
end
self:F({DefenderCount=DefenderCount})
return DefenderCount
end
function AI_A2A_DISPATCHER:CountDefendersToBeEngaged(AttackerDetection,DefenderCount)
local Friendlies=nil
local AttackerSet=AttackerDetection.Set
local AttackerCount=AttackerSet:Count()
local DefenderFriendlies=self:GetAIFriendliesNearBy(AttackerDetection)
for FriendlyDistance,AIFriendly in UTILS.spairs(DefenderFriendlies or{})do
if AttackerCount>DefenderCount then
local Friendly=AIFriendly:GetGroup()
if Friendly and Friendly:IsAlive()then
local DefenderTask=self:GetDefenderTask(Friendly)
if DefenderTask then
if DefenderTask.Type=="CAP"or DefenderTask.Type=="GCI"then
if DefenderTask.Target==nil then
if DefenderTask.Fsm:Is("Returning")
or DefenderTask.Fsm:Is("Patrolling")then
Friendlies=Friendlies or{}
Friendlies[Friendly]=Friendly
DefenderCount=DefenderCount+Friendly:GetSize()
self:F({Friendly=Friendly:GetName(),FriendlyDistance=FriendlyDistance})
end
end
end
end
end
else
break
end
end
return Friendlies
end
function AI_A2A_DISPATCHER:onafterCAP(From,Event,To,SquadronName)
self:F({SquadronName=SquadronName})
self.DefenderSquadrons[SquadronName]=self.DefenderSquadrons[SquadronName]or{}
self.DefenderSquadrons[SquadronName].Cap=self.DefenderSquadrons[SquadronName].Cap or{}
local DefenderSquadron=self:CanCAP(SquadronName)
if DefenderSquadron then
local Cap=DefenderSquadron.Cap
if Cap then
local Spawn=DefenderSquadron.Spawn[math.random(1,#DefenderSquadron.Spawn)]
local DefenderGrouping=DefenderSquadron.Grouping or self.DefenderDefault.Grouping
Spawn:InitGrouping(DefenderGrouping)
local TakeoffMethod=self:GetSquadronTakeoff(SquadronName)
local DefenderCAP=Spawn:SpawnAtAirbase(DefenderSquadron.Airbase,TakeoffMethod,DefenderSquadron.TakeoffAltitude or self.DefenderDefault.TakeoffAltitude)
self:AddDefenderToSquadron(DefenderSquadron,DefenderCAP,DefenderGrouping)
if DefenderCAP then
local Fsm=AI_A2A_CAP:New(DefenderCAP,Cap.Zone,Cap.FloorAltitude,Cap.CeilingAltitude,Cap.PatrolMinSpeed,Cap.PatrolMaxSpeed,Cap.EngageMinSpeed,Cap.EngageMaxSpeed,Cap.AltType)
Fsm:SetDispatcher(self)
Fsm:SetHomeAirbase(DefenderSquadron.Airbase)
Fsm:SetFuelThreshold(DefenderSquadron.FuelThreshold or self.DefenderDefault.FuelThreshold,60)
Fsm:SetDamageThreshold(self.DefenderDefault.DamageThreshold)
Fsm:SetDisengageRadius(self.DisengageRadius)
Fsm:SetTanker(DefenderSquadron.TankerName or self.DefenderDefault.TankerName)
Fsm:Start()
self:SetDefenderTask(SquadronName,DefenderCAP,"CAP",Fsm)
function Fsm:onafterTakeoff(Defender,From,Event,To)
self:F({"GCI Birth",Defender:GetName()})
local Dispatcher=Fsm:GetDispatcher()
local Squadron=Dispatcher:GetSquadronFromDefender(Defender)
if Squadron then
Fsm:__Patrol(2)
end
end
function Fsm:onafterRTB(Defender,From,Event,To)
self:F({"CAP RTB",Defender:GetName()})
self:GetParent(self).onafterRTB(self,Defender,From,Event,To)
local Dispatcher=self:GetDispatcher()
Dispatcher:ClearDefenderTaskTarget(Defender)
end
function Fsm:onafterHome(Defender,From,Event,To,Action)
self:E({"CAP Home",Defender:GetName()})
self:GetParent(self).onafterHome(self,Defender,From,Event,To)
local Dispatcher=self:GetDispatcher()
local Squadron=Dispatcher:GetSquadronFromDefender(Defender)
if Action and Action=="Destroy"then
Dispatcher:RemoveDefenderFromSquadron(Squadron,Defender)
Defender:Destroy()
end
if Dispatcher:GetSquadronLanding(Squadron.Name)==AI_A2A_DISPATCHER.Landing.NearAirbase then
Dispatcher:RemoveDefenderFromSquadron(Squadron,Defender)
Defender:Destroy()
end
end
end
end
end
end
function AI_A2A_DISPATCHER:onafterENGAGE(From,Event,To,AttackerDetection,Defenders)
if Defenders then
for DefenderID,Defender in pairs(Defenders)do
local Fsm=self:GetDefenderTaskFsm(Defender)
Fsm:__Engage(1,AttackerDetection.Set)
self:SetDefenderTaskTarget(Defender,AttackerDetection)
end
end
end
function AI_A2A_DISPATCHER:onafterGCI(From,Event,To,AttackerDetection,DefendersMissing,DefenderFriendlies)
self:F({From,Event,To,AttackerDetection.Index,DefendersMissing,DefenderFriendlies})
local AttackerSet=AttackerDetection.Set
local AttackerUnit=AttackerSet:GetFirst()
if AttackerUnit and AttackerUnit:IsAlive()then
local AttackerCount=AttackerSet:Count()
local DefenderCount=0
for DefenderID,DefenderGroup in pairs(DefenderFriendlies or{})do
local Fsm=self:GetDefenderTaskFsm(DefenderGroup)
Fsm:__Engage(1,AttackerSet)
self:SetDefenderTaskTarget(DefenderGroup,AttackerDetection)
DefenderCount=DefenderCount+DefenderGroup:GetSize()
end
self:F({DefenderCount=DefenderCount,DefendersMissing=DefendersMissing})
DefenderCount=DefendersMissing
local ClosestDistance=0
local ClosestDefenderSquadronName=nil
local BreakLoop=false
while(DefenderCount>0 and not BreakLoop)do
self:F({DefenderSquadrons=self.DefenderSquadrons})
for SquadronName,DefenderSquadron in pairs(self.DefenderSquadrons or{})do
self:F({GCI=DefenderSquadron.Gci})
for InterceptID,Intercept in pairs(DefenderSquadron.Gci or{})do
self:F({DefenderSquadron})
local SpawnCoord=DefenderSquadron.Airbase:GetCoordinate()
local AttackerCoord=AttackerUnit:GetCoordinate()
local InterceptCoord=AttackerDetection.InterceptCoord
self:F({InterceptCoord=InterceptCoord})
if InterceptCoord then
local InterceptDistance=SpawnCoord:Get2DDistance(InterceptCoord)
local AirbaseDistance=SpawnCoord:Get2DDistance(AttackerCoord)
self:F({InterceptDistance=InterceptDistance,AirbaseDistance=AirbaseDistance,InterceptCoord=InterceptCoord})
if ClosestDistance==0 or InterceptDistance<ClosestDistance then
if AirbaseDistance<=self.GciRadius then
ClosestDistance=InterceptDistance
ClosestDefenderSquadronName=SquadronName
end
end
end
end
end
if ClosestDefenderSquadronName then
local DefenderSquadron=self:CanGCI(ClosestDefenderSquadronName)
if DefenderSquadron then
local Gci=self.DefenderSquadrons[ClosestDefenderSquadronName].Gci
if Gci then
local DefenderOverhead=DefenderSquadron.Overhead or self.DefenderDefault.Overhead
local DefenderGrouping=DefenderSquadron.Grouping or self.DefenderDefault.Grouping
local DefendersNeeded=math.ceil(DefenderCount*DefenderOverhead)
self:F({Overhead=DefenderOverhead,SquadronOverhead=DefenderSquadron.Overhead,DefaultOverhead=self.DefenderDefault.Overhead})
self:F({Grouping=DefenderGrouping,SquadronGrouping=DefenderSquadron.Grouping,DefaultGrouping=self.DefenderDefault.Grouping})
self:F({DefendersCount=DefenderCount,DefendersNeeded=DefendersNeeded})
if DefenderSquadron.Resources and DefendersNeeded>DefenderSquadron.Resources then
DefendersNeeded=DefenderSquadron.Resources
BreakLoop=true
end
while(DefendersNeeded>0)do
local Spawn=DefenderSquadron.Spawn[math.random(1,#DefenderSquadron.Spawn)]
local DefenderGrouping=(DefenderGrouping<DefendersNeeded)and DefenderGrouping or DefendersNeeded
if DefenderGrouping then
Spawn:InitGrouping(DefenderGrouping)
else
Spawn:InitGrouping()
end
local TakeoffMethod=self:GetSquadronTakeoff(ClosestDefenderSquadronName)
local DefenderGCI=Spawn:SpawnAtAirbase(DefenderSquadron.Airbase,TakeoffMethod,DefenderSquadron.TakeoffAltitude or self.DefenderDefault.TakeoffAltitude)
self:E({GCIDefender=DefenderGCI:GetName()})
DefendersNeeded=DefendersNeeded-DefenderGrouping
self:AddDefenderToSquadron(DefenderSquadron,DefenderGCI,DefenderGrouping)
if DefenderGCI then
DefenderCount=DefenderCount-DefenderGrouping/DefenderOverhead
local Fsm=AI_A2A_GCI:New(DefenderGCI,Gci.EngageMinSpeed,Gci.EngageMaxSpeed)
Fsm:SetDispatcher(self)
Fsm:SetHomeAirbase(DefenderSquadron.Airbase)
Fsm:SetFuelThreshold(DefenderSquadron.FuelThreshold or self.DefenderDefault.FuelThreshold,60)
Fsm:SetDamageThreshold(self.DefenderDefault.DamageThreshold)
Fsm:SetDisengageRadius(self.DisengageRadius)
Fsm:Start()
self:SetDefenderTask(ClosestDefenderSquadronName,DefenderGCI,"GCI",Fsm,AttackerDetection)
function Fsm:onafterTakeoff(Defender,From,Event,To)
self:F({"GCI Birth",Defender:GetName()})
local Dispatcher=Fsm:GetDispatcher()
local Squadron=Dispatcher:GetSquadronFromDefender(Defender)
local DefenderTarget=Dispatcher:GetDefenderTaskTarget(Defender)
if DefenderTarget then
Fsm:__Engage(2,DefenderTarget.Set)
end
end
function Fsm:onafterRTB(Defender,From,Event,To)
self:F({"GCI RTB",Defender:GetName()})
self:GetParent(self).onafterRTB(self,Defender,From,Event,To)
local Dispatcher=self:GetDispatcher()
Dispatcher:ClearDefenderTaskTarget(Defender)
end
function Fsm:onafterLostControl(Defender,From,Event,To)
self:F({"GCI LostControl",Defender:GetName()})
self:GetParent(self).onafterHome(self,Defender,From,Event,To)
local Dispatcher=Fsm:GetDispatcher()
local Squadron=Dispatcher:GetSquadronFromDefender(Defender)
if Defender:IsAboveRunway()then
Dispatcher:RemoveDefenderFromSquadron(Squadron,Defender)
Defender:Destroy()
end
end
function Fsm:onafterHome(Defender,From,Event,To,Action)
self:F({"GCI Home",Defender:GetName()})
self:GetParent(self).onafterHome(self,Defender,From,Event,To)
local Dispatcher=self:GetDispatcher()
local Squadron=Dispatcher:GetSquadronFromDefender(Defender)
if Action and Action=="Destroy"then
Dispatcher:RemoveDefenderFromSquadron(Squadron,Defender)
Defender:Destroy()
end
if Dispatcher:GetSquadronLanding(Squadron.Name)==AI_A2A_DISPATCHER.Landing.NearAirbase then
Dispatcher:RemoveDefenderFromSquadron(Squadron,Defender)
Defender:Destroy()
end
end
end
end
end
else
BreakLoop=true
break
end
else
break
end
end
end
end
function AI_A2A_DISPATCHER:EvaluateENGAGE(DetectedItem)
self:F({DetectedItem.ItemID})
local DefenderCount=self:CountDefendersEngaged(DetectedItem)
local DefenderGroups=self:CountDefendersToBeEngaged(DetectedItem,DefenderCount)
self:F({DefenderCount=DefenderCount})
if DefenderGroups and DetectedItem.IsDetected==true then
return DefenderGroups
end
return nil,nil
end
function AI_A2A_DISPATCHER:EvaluateGCI(DetectedItem)
self:F({DetectedItem.ItemID})
local AttackerSet=DetectedItem.Set
local AttackerCount=AttackerSet:Count()
local DefenderCount=self:CountDefendersEngaged(DetectedItem)
local DefendersMissing=AttackerCount-DefenderCount
self:F({AttackerCount=AttackerCount,DefenderCount=DefenderCount,DefendersMissing=DefendersMissing})
local Friendlies=self:CountDefendersToBeEngaged(DetectedItem,DefenderCount)
if DetectedItem.IsDetected==true then
return DefendersMissing,Friendlies
end
return nil,nil
end
function AI_A2A_DISPATCHER:ProcessDetected(Detection)
local AreaMsg={}
local TaskMsg={}
local ChangeMsg={}
local TaskReport=REPORT:New()
for AIGroup,DefenderTask in pairs(self:GetDefenderTasks())do
local AIGroup=AIGroup
if not AIGroup:IsAlive()then
local DefenderTaskFsm=self:GetDefenderTaskFsm(AIGroup)
self:E({Defender=AIGroup:GetName(),DefenderState=DefenderTaskFsm:GetState()})
if not DefenderTaskFsm:Is("Started")then
self:ClearDefenderTask(AIGroup)
end
else
if DefenderTask.Target then
local AttackerItem=Detection:GetDetectedItem(DefenderTask.Target.Index)
if not AttackerItem then
self:F({"Removing obsolete Target:",DefenderTask.Target.Index})
self:ClearDefenderTaskTarget(AIGroup)
else
if DefenderTask.Target.Set then
local AttackerCount=DefenderTask.Target.Set:Count()
if AttackerCount==0 then
self:F({"All Targets destroyed in Target, removing:",DefenderTask.Target.Index})
self:ClearDefenderTaskTarget(AIGroup)
end
end
end
end
end
end
local Report=REPORT:New("\nTactical Overview")
for DetectedItemID,DetectedItem in pairs(Detection:GetDetectedItems())do
local DetectedItem=DetectedItem
local DetectedSet=DetectedItem.Set
local DetectedCount=DetectedSet:Count()
local DetectedZone=DetectedItem.Zone
self:F({"Target ID",DetectedItem.ItemID})
DetectedSet:Flush()
local DetectedID=DetectedItem.ID
local DetectionIndex=DetectedItem.Index
local DetectedItemChanged=DetectedItem.Changed
do
local Friendlies=self:EvaluateENGAGE(DetectedItem)
if Friendlies then
self:F({AIGroups=Friendlies})
self:ENGAGE(DetectedItem,Friendlies)
end
end
do
local DefendersMissing,Friendlies=self:EvaluateGCI(DetectedItem)
if DefendersMissing then
self:F({DefendersMissing=DefendersMissing})
self:GCI(DetectedItem,DefendersMissing,Friendlies)
end
end
if self.TacticalDisplay then
Report:Add(string.format("\n - Target %s ( %s ): ( #%d ) %s",DetectedItem.ItemID,DetectedItem.Index,DetectedItem.Set:Count(),DetectedItem.Set:GetObjectNames()))
for Defender,DefenderTask in pairs(self:GetDefenderTasks())do
local Defender=Defender
if DefenderTask.Target and DefenderTask.Target.Index==DetectedItem.Index then
local Fuel=Defender:GetFuel()*100
local Damage=Defender:GetLife()/Defender:GetLife0()*100
Report:Add(string.format("   - %s ( %s - %s ): ( #%d ) F: %3d, D:%3d - %s",
Defender:GetName(),
DefenderTask.Type,
DefenderTask.Fsm:GetState(),
Defender:GetSize(),
Fuel,
Damage,
Defender:HasTask()==true and"Executing"or"Idle"))
end
end
end
end
if self.TacticalDisplay then
Report:Add("\n - No Targets:")
local TaskCount=0
for Defender,DefenderTask in pairs(self:GetDefenderTasks())do
TaskCount=TaskCount+1
local Defender=Defender
if not DefenderTask.Target then
local DefenderHasTask=Defender:HasTask()
local Fuel=Defender:GetFuel()*100
local Damage=Defender:GetLife()/Defender:GetLife0()*100
Report:Add(string.format("   - %s ( %s - %s ): ( #%d ) F: %3d, D:%3d - %s",
Defender:GetName(),
DefenderTask.Type,
DefenderTask.Fsm:GetState(),
Defender:GetSize(),
Fuel,
Damage,
Defender:HasTask()==true and"Executing"or"Idle"))
end
end
Report:Add(string.format("\n - %d Tasks",TaskCount))
self:E(Report:Text("\n"))
trigger.action.outText(Report:Text("\n"),25)
end
return true
end
end
do
function AI_A2A_DISPATCHER:GetPlayerFriendliesNearBy(DetectedItem)
local DetectedSet=DetectedItem.Set
local PlayersNearBy=self.Detection:GetPlayersNearBy(DetectedItem)
local PlayerTypes={}
local PlayersCount=0
if PlayersNearBy then
local DetectedTreatLevel=DetectedSet:CalculateThreatLevelA2G()
for PlayerUnitName,PlayerUnitData in pairs(PlayersNearBy)do
local PlayerUnit=PlayerUnitData
local PlayerName=PlayerUnit:GetPlayerName()
if PlayerUnit:IsAirPlane()and PlayerName~=nil then
local FriendlyUnitThreatLevel=PlayerUnit:GetThreatLevel()
PlayersCount=PlayersCount+1
local PlayerType=PlayerUnit:GetTypeName()
PlayerTypes[PlayerName]=PlayerType
if DetectedTreatLevel<FriendlyUnitThreatLevel+2 then
end
end
end
end
local PlayerTypesReport=REPORT:New()
if PlayersCount>0 then
for PlayerName,PlayerType in pairs(PlayerTypes)do
PlayerTypesReport:Add(string.format('"%s" in %s',PlayerName,PlayerType))
end
else
PlayerTypesReport:Add("-")
end
return PlayersCount,PlayerTypesReport
end
function AI_A2A_DISPATCHER:GetFriendliesNearBy(Target)
local DetectedSet=Target.Set
local FriendlyUnitsNearBy=self.Detection:GetFriendliesNearBy(Target)
local FriendlyTypes={}
local FriendliesCount=0
if FriendlyUnitsNearBy then
local DetectedTreatLevel=DetectedSet:CalculateThreatLevelA2G()
for FriendlyUnitName,FriendlyUnitData in pairs(FriendlyUnitsNearBy)do
local FriendlyUnit=FriendlyUnitData
if FriendlyUnit:IsAirPlane()then
local FriendlyUnitThreatLevel=FriendlyUnit:GetThreatLevel()
FriendliesCount=FriendliesCount+1
local FriendlyType=FriendlyUnit:GetTypeName()
FriendlyTypes[FriendlyType]=FriendlyTypes[FriendlyType]and(FriendlyTypes[FriendlyType]+1)or 1
if DetectedTreatLevel<FriendlyUnitThreatLevel+2 then
end
end
end
end
local FriendlyTypesReport=REPORT:New()
if FriendliesCount>0 then
for FriendlyType,FriendlyTypeCount in pairs(FriendlyTypes)do
FriendlyTypesReport:Add(string.format("%d of %s",FriendlyTypeCount,FriendlyType))
end
else
FriendlyTypesReport:Add("-")
end
return FriendliesCount,FriendlyTypesReport
end
function AI_A2A_DISPATCHER:SchedulerCAP(SquadronName)
self:CAP(SquadronName)
end
end
do
AI_A2A_GCICAP={
ClassName="AI_A2A_GCICAP",
Detection=nil,
}
function AI_A2A_GCICAP:New(EWRPrefixes,TemplatePrefixes,CapPrefixes,CapLimit,GroupingRadius,EngageRadius,GciRadius,Resources)
local EWRSetGroup=SET_GROUP:New()
EWRSetGroup:FilterPrefixes(EWRPrefixes)
EWRSetGroup:FilterStart()
local Detection=DETECTION_AREAS:New(EWRSetGroup,GroupingRadius or 30000)
local self=BASE:Inherit(self,AI_A2A_DISPATCHER:New(Detection))
self:SetEngageRadius(EngageRadius)
self:SetGciRadius(GciRadius)
local EWRFirst=EWRSetGroup:GetFirst()
local EWRCoalition=EWRFirst:GetCoalition()
local AirbaseNames={}
for AirbaseID,AirbaseData in pairs(_DATABASE.AIRBASES)do
local Airbase=AirbaseData
local AirbaseName=Airbase:GetName()
if Airbase:GetCoalition()==EWRCoalition then
table.insert(AirbaseNames,AirbaseName)
end
end
self.Templates=SET_GROUP
:New()
:FilterPrefixes(TemplatePrefixes)
:FilterOnce()
self:F({Airbases=AirbaseNames})
self.Templates:Flush()
for AirbaseID,AirbaseName in pairs(AirbaseNames)do
local Airbase=_DATABASE:FindAirbase(AirbaseName)
local AirbaseName=Airbase:GetName()
local AirbaseCoord=Airbase:GetCoordinate()
local AirbaseZone=ZONE_RADIUS:New("Airbase",AirbaseCoord:GetVec2(),3000)
local Templates=nil
for TemplateID,Template in pairs(self.Templates:GetSet())do
local Template=Template
self:F({Template=Template:GetName()})
local TemplateCoord=Template:GetCoordinate()
if AirbaseZone:IsVec2InZone(TemplateCoord:GetVec2())then
Templates=Templates or{}
table.insert(Templates,Template:GetName())
end
end
if Templates then
self:SetSquadron(AirbaseName,AirbaseName,Templates,Resources)
end
end
self.CAPTemplates=SET_GROUP:New()
self.CAPTemplates:FilterPrefixes(CapPrefixes)
self.CAPTemplates:FilterOnce()
for CAPID,CAPTemplate in pairs(self.CAPTemplates:GetSet())do
local CAPZone=ZONE_POLYGON:New(CAPTemplate:GetName(),CAPTemplate)
local AirbaseDistance=99999999
local AirbaseClosest=nil
for AirbaseID,AirbaseName in pairs(AirbaseNames)do
local Airbase=_DATABASE:FindAirbase(AirbaseName)
local AirbaseName=Airbase:GetName()
local AirbaseCoord=Airbase:GetCoordinate()
local Squadron=self.DefenderSquadrons[AirbaseName]
if Squadron then
local Distance=AirbaseCoord:Get2DDistance(CAPZone:GetCoordinate())
if Distance<AirbaseDistance then
AirbaseDistance=Distance
AirbaseClosest=Airbase
end
end
end
if AirbaseClosest then
self:SetSquadronCap(AirbaseClosest:GetName(),CAPZone,6000,10000,500,800,800,1200,"RADIO")
self:SetSquadronCapInterval(AirbaseClosest:GetName(),CapLimit,300,600,1)
end
end
for AirbaseID,AirbaseName in pairs(AirbaseNames)do
local Airbase=_DATABASE:FindAirbase(AirbaseName)
local AirbaseName=Airbase:GetName()
local Squadron=self.DefenderSquadrons[AirbaseName]
if Squadron then
self:SetSquadronGci(AirbaseName,800,1200)
end
end
self:__Start(5)
self:HandleEvent(EVENTS.Crash,self.OnEventCrashOrDead)
self:HandleEvent(EVENTS.Dead,self.OnEventCrashOrDead)
self:HandleEvent(EVENTS.Land)
self:HandleEvent(EVENTS.EngineShutdown)
return self
end
function AI_A2A_GCICAP:NewWithBorder(EWRPrefixes,TemplatePrefixes,BorderPrefix,CapPrefixes,CapLimit,GroupingRadius,EngageRadius,GciRadius,Resources)
local self=AI_A2A_GCICAP:New(EWRPrefixes,TemplatePrefixes,CapPrefixes,CapLimit,GroupingRadius,EngageRadius,GciRadius,Resources)
if BorderPrefix then
self:SetBorderZone(ZONE_POLYGON:New(BorderPrefix,GROUP:FindByName(BorderPrefix)))
end
return self
end
end
AI_PATROL_ZONE={
ClassName="AI_PATROL_ZONE",
}
function AI_PATROL_ZONE:New(PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,PatrolAltType)
local self=BASE:Inherit(self,FSM_CONTROLLABLE:New())
self.PatrolZone=PatrolZone
self.PatrolFloorAltitude=PatrolFloorAltitude
self.PatrolCeilingAltitude=PatrolCeilingAltitude
self.PatrolMinSpeed=PatrolMinSpeed
self.PatrolMaxSpeed=PatrolMaxSpeed
self.PatrolAltType=PatrolAltType or"RADIO"
self:SetRefreshTimeInterval(30)
self.CheckStatus=true
self:ManageFuel(.2,60)
self:ManageDamage(1)
self.DetectedUnits={}
self:SetStartState("None")
self:AddTransition("*","Stop","Stopped")
self:AddTransition("None","Start","Patrolling")
self:AddTransition("Patrolling","Route","Patrolling")
self:AddTransition("*","Status","*")
self:AddTransition("*","Detect","*")
self:AddTransition("*","Detected","*")
self:AddTransition("*","RTB","Returning")
self:AddTransition("*","Reset","Patrolling")
self:AddTransition("*","Eject","*")
self:AddTransition("*","Crash","Crashed")
self:AddTransition("*","PilotDead","*")
return self
end
function AI_PATROL_ZONE:SetSpeed(PatrolMinSpeed,PatrolMaxSpeed)
self:F2({PatrolMinSpeed,PatrolMaxSpeed})
self.PatrolMinSpeed=PatrolMinSpeed
self.PatrolMaxSpeed=PatrolMaxSpeed
end
function AI_PATROL_ZONE:SetAltitude(PatrolFloorAltitude,PatrolCeilingAltitude)
self:F2({PatrolFloorAltitude,PatrolCeilingAltitude})
self.PatrolFloorAltitude=PatrolFloorAltitude
self.PatrolCeilingAltitude=PatrolCeilingAltitude
end
function AI_PATROL_ZONE:SetDetectionOn()
self:F2()
self.DetectOn=true
end
function AI_PATROL_ZONE:SetDetectionOff()
self:F2()
self.DetectOn=false
end
function AI_PATROL_ZONE:SetStatusOff()
self:F2()
self.CheckStatus=false
end
function AI_PATROL_ZONE:SetDetectionActivated()
self:F2()
self:ClearDetectedUnits()
self.DetectActivated=true
self:__Detect(-self.DetectInterval)
end
function AI_PATROL_ZONE:SetDetectionDeactivated()
self:F2()
self:ClearDetectedUnits()
self.DetectActivated=false
end
function AI_PATROL_ZONE:SetRefreshTimeInterval(Seconds)
self:F2()
if Seconds then
self.DetectInterval=Seconds
else
self.DetectInterval=30
end
end
function AI_PATROL_ZONE:SetDetectionZone(DetectionZone)
self:F2()
if DetectionZone then
self.DetectZone=DetectionZone
else
self.DetectZone=nil
end
end
function AI_PATROL_ZONE:GetDetectedUnits()
self:F2()
return self.DetectedUnits
end
function AI_PATROL_ZONE:ClearDetectedUnits()
self:F2()
self.DetectedUnits={}
end
function AI_PATROL_ZONE:ManageFuel(PatrolFuelThresholdPercentage,PatrolOutOfFuelOrbitTime)
self.PatrolManageFuel=true
self.PatrolFuelThresholdPercentage=PatrolFuelThresholdPercentage
self.PatrolOutOfFuelOrbitTime=PatrolOutOfFuelOrbitTime
return self
end
function AI_PATROL_ZONE:ManageDamage(PatrolDamageThreshold)
self.PatrolManageDamage=true
self.PatrolDamageThreshold=PatrolDamageThreshold
return self
end
function AI_PATROL_ZONE:onafterStart(Controllable,From,Event,To)
self:F2()
self:__Route(1)
self:__Status(60)
self:SetDetectionActivated()
self:HandleEvent(EVENTS.PilotDead,self.OnPilotDead)
self:HandleEvent(EVENTS.Crash,self.OnCrash)
self:HandleEvent(EVENTS.Ejection,self.OnEjection)
Controllable:OptionROEHoldFire()
Controllable:OptionROTVertical()
self.Controllable:OnReSpawn(
function(PatrolGroup)
self:E("ReSpawn")
self:__Reset(1)
self:__Route(5)
end
)
self:SetDetectionOn()
end
function AI_PATROL_ZONE:onbeforeDetect(Controllable,From,Event,To)
return self.DetectOn and self.DetectActivated
end
function AI_PATROL_ZONE:onafterDetect(Controllable,From,Event,To)
local Detected=false
local DetectedTargets=Controllable:GetDetectedTargets()
for TargetID,Target in pairs(DetectedTargets or{})do
local TargetObject=Target.object
if TargetObject and TargetObject:isExist()and TargetObject.id_<50000000 then
local TargetUnit=UNIT:Find(TargetObject)
local TargetUnitName=TargetUnit:GetName()
if self.DetectionZone then
if TargetUnit:IsInZone(self.DetectionZone)then
self:T({"Detected ",TargetUnit})
if self.DetectedUnits[TargetUnit]==nil then
self.DetectedUnits[TargetUnit]=true
end
Detected=true
end
else
if self.DetectedUnits[TargetUnit]==nil then
self.DetectedUnits[TargetUnit]=true
end
Detected=true
end
end
end
self:__Detect(-self.DetectInterval)
if Detected==true then
self:__Detected(1.5)
end
end
function AI_PATROL_ZONE:_NewPatrolRoute(AIControllable)
local PatrolZone=AIControllable:GetState(AIControllable,"PatrolZone")
PatrolZone:__Route(1)
end
function AI_PATROL_ZONE:onafterRoute(Controllable,From,Event,To)
self:F2()
if From=="RTB"then
return
end
if self.Controllable:IsAlive()then
local PatrolRoute={}
if self.Controllable:InAir()==false then
self:E("Not in the air, finding route path within PatrolZone")
local CurrentVec2=self.Controllable:GetVec2()
local CurrentAltitude=self.Controllable:GetUnit(1):GetAltitude()
local CurrentPointVec3=POINT_VEC3:New(CurrentVec2.x,CurrentAltitude,CurrentVec2.y)
local ToPatrolZoneSpeed=self.PatrolMaxSpeed
local CurrentRoutePoint=CurrentPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TakeOffParking,
POINT_VEC3.RoutePointAction.FromParkingArea,
ToPatrolZoneSpeed,
true
)
PatrolRoute[#PatrolRoute+1]=CurrentRoutePoint
else
self:E("In the air, finding route path within PatrolZone")
local CurrentVec2=self.Controllable:GetVec2()
local CurrentAltitude=self.Controllable:GetUnit(1):GetAltitude()
local CurrentPointVec3=POINT_VEC3:New(CurrentVec2.x,CurrentAltitude,CurrentVec2.y)
local ToPatrolZoneSpeed=self.PatrolMaxSpeed
local CurrentRoutePoint=CurrentPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToPatrolZoneSpeed,
true
)
PatrolRoute[#PatrolRoute+1]=CurrentRoutePoint
end
local ToTargetVec2=self.PatrolZone:GetRandomVec2()
self:T2(ToTargetVec2)
local ToTargetAltitude=math.random(self.PatrolFloorAltitude,self.PatrolCeilingAltitude)
local ToTargetSpeed=math.random(self.PatrolMinSpeed,self.PatrolMaxSpeed)
self:T2({self.PatrolMinSpeed,self.PatrolMaxSpeed,ToTargetSpeed})
local ToTargetPointVec3=POINT_VEC3:New(ToTargetVec2.x,ToTargetAltitude,ToTargetVec2.y)
local ToTargetRoutePoint=ToTargetPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToTargetSpeed,
true
)
PatrolRoute[#PatrolRoute+1]=ToTargetRoutePoint
self.Controllable:WayPointInitialize(PatrolRoute)
self.Controllable:SetState(self.Controllable,"PatrolZone",self)
self.Controllable:WayPointFunction(#PatrolRoute,1,"AI_PATROL_ZONE:_NewPatrolRoute")
self.Controllable:WayPointExecute(1,2)
end
end
function AI_PATROL_ZONE:onbeforeStatus()
return self.CheckStatus
end
function AI_PATROL_ZONE:onafterStatus()
self:F2()
if self.Controllable and self.Controllable:IsAlive()then
local RTB=false
local Fuel=self.Controllable:GetUnit(1):GetFuel()
if Fuel<self.PatrolFuelThresholdPercentage then
self:E(self.Controllable:GetName().." is out of fuel:"..Fuel..", RTB!")
local OldAIControllable=self.Controllable
local OrbitTask=OldAIControllable:TaskOrbitCircle(math.random(self.PatrolFloorAltitude,self.PatrolCeilingAltitude),self.PatrolMinSpeed)
local TimedOrbitTask=OldAIControllable:TaskControlled(OrbitTask,OldAIControllable:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil))
OldAIControllable:SetTask(TimedOrbitTask,10)
RTB=true
else
end
local Damage=self.Controllable:GetLife()
if Damage<=self.PatrolDamageThreshold then
self:E(self.Controllable:GetName().." is damaged:"..Damage..", RTB!")
RTB=true
end
if RTB==true then
self:RTB()
else
self:__Status(60)
end
end
end
function AI_PATROL_ZONE:onafterRTB()
self:F2()
if self.Controllable and self.Controllable:IsAlive()then
self:SetDetectionOff()
self.CheckStatus=false
local PatrolRoute={}
local CurrentVec2=self.Controllable:GetVec2()
local CurrentAltitude=self.Controllable:GetUnit(1):GetAltitude()
local CurrentPointVec3=POINT_VEC3:New(CurrentVec2.x,CurrentAltitude,CurrentVec2.y)
local ToPatrolZoneSpeed=self.PatrolMaxSpeed
local CurrentRoutePoint=CurrentPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToPatrolZoneSpeed,
true
)
PatrolRoute[#PatrolRoute+1]=CurrentRoutePoint
self.Controllable:WayPointInitialize(PatrolRoute)
self.Controllable:WayPointExecute(1,1)
end
end
function AI_PATROL_ZONE:onafterDead()
self:SetDetectionOff()
self:SetStatusOff()
end
function AI_PATROL_ZONE:OnCrash(EventData)
if self.Controllable:IsAlive()and EventData.IniDCSGroupName==self.Controllable:GetName()then
self:E(self.Controllable:GetUnits())
if#self.Controllable:GetUnits()==1 then
self:__Crash(1,EventData)
end
end
end
function AI_PATROL_ZONE:OnEjection(EventData)
if self.Controllable:IsAlive()and EventData.IniDCSGroupName==self.Controllable:GetName()then
self:__Eject(1,EventData)
end
end
function AI_PATROL_ZONE:OnPilotDead(EventData)
if self.Controllable:IsAlive()and EventData.IniDCSGroupName==self.Controllable:GetName()then
self:__PilotDead(1,EventData)
end
end
AI_CAP_ZONE={
ClassName="AI_CAP_ZONE",
}
function AI_CAP_ZONE:New(PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,PatrolAltType)
local self=BASE:Inherit(self,AI_PATROL_ZONE:New(PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,PatrolAltType))
self.Accomplished=false
self.Engaging=false
self:AddTransition({"Patrolling","Engaging"},"Engage","Engaging")
self:AddTransition("Engaging","Fired","Engaging")
self:AddTransition("*","Destroy","*")
self:AddTransition("Engaging","Abort","Patrolling")
self:AddTransition("Engaging","Accomplish","Patrolling")
return self
end
function AI_CAP_ZONE:SetEngageZone(EngageZone)
self:F2()
if EngageZone then
self.EngageZone=EngageZone
else
self.EngageZone=nil
end
end
function AI_CAP_ZONE:SetEngageRange(EngageRange)
self:F2()
if EngageRange then
self.EngageRange=EngageRange
else
self.EngageRange=nil
end
end
function AI_CAP_ZONE:onafterStart(Controllable,From,Event,To)
self:GetParent(self).onafterStart(self,Controllable,From,Event,To)
self:HandleEvent(EVENTS.Dead)
end
function AI_CAP_ZONE.EngageRoute(EngageGroup,Fsm)
EngageGroup:F({"AI_CAP_ZONE.EngageRoute:",EngageGroup:GetName()})
if EngageGroup:IsAlive()then
Fsm:__Engage(1)
end
end
function AI_CAP_ZONE:onbeforeEngage(Controllable,From,Event,To)
if self.Accomplished==true then
return false
end
end
function AI_CAP_ZONE:onafterDetected(Controllable,From,Event,To)
if From~="Engaging"then
local Engage=false
for DetectedUnit,Detected in pairs(self.DetectedUnits)do
local DetectedUnit=DetectedUnit
self:T(DetectedUnit)
if DetectedUnit:IsAlive()and DetectedUnit:IsAir()then
Engage=true
break
end
end
if Engage==true then
self:F('Detected -> Engaging')
self:__Engage(1)
end
end
end
function AI_CAP_ZONE:onafterAbort(Controllable,From,Event,To)
Controllable:ClearTasks()
self:__Route(1)
end
function AI_CAP_ZONE:onafterEngage(Controllable,From,Event,To)
if Controllable:IsAlive()then
local EngageRoute={}
local CurrentVec2=self.Controllable:GetVec2()
local CurrentAltitude=self.Controllable:GetUnit(1):GetAltitude()
local CurrentPointVec3=POINT_VEC3:New(CurrentVec2.x,CurrentAltitude,CurrentVec2.y)
local ToEngageZoneSpeed=self.PatrolMaxSpeed
local CurrentRoutePoint=CurrentPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToEngageZoneSpeed,
true
)
EngageRoute[#EngageRoute+1]=CurrentRoutePoint
local ToTargetVec2=self.PatrolZone:GetRandomVec2()
self:T2(ToTargetVec2)
local ToTargetAltitude=math.random(self.EngageFloorAltitude,self.EngageCeilingAltitude)
local ToTargetSpeed=math.random(self.PatrolMinSpeed,self.PatrolMaxSpeed)
self:T2({self.PatrolMinSpeed,self.PatrolMaxSpeed,ToTargetSpeed})
local ToTargetPointVec3=POINT_VEC3:New(ToTargetVec2.x,ToTargetAltitude,ToTargetVec2.y)
local ToPatrolRoutePoint=ToTargetPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
ToTargetSpeed,
true
)
EngageRoute[#EngageRoute+1]=ToPatrolRoutePoint
Controllable:OptionROEOpenFire()
Controllable:OptionROTEvadeFire()
local AttackTasks={}
for DetectedUnit,Detected in pairs(self.DetectedUnits)do
local DetectedUnit=DetectedUnit
self:T({DetectedUnit,DetectedUnit:IsAlive(),DetectedUnit:IsAir()})
if DetectedUnit:IsAlive()and DetectedUnit:IsAir()then
if self.EngageZone then
if DetectedUnit:IsInZone(self.EngageZone)then
self:F({"Within Zone and Engaging ",DetectedUnit})
AttackTasks[#AttackTasks+1]=Controllable:TaskAttackUnit(DetectedUnit)
end
else
if self.EngageRange then
if DetectedUnit:GetPointVec3():Get2DDistance(Controllable:GetPointVec3())<=self.EngageRange then
self:F({"Within Range and Engaging",DetectedUnit})
AttackTasks[#AttackTasks+1]=Controllable:TaskAttackUnit(DetectedUnit)
end
else
AttackTasks[#AttackTasks+1]=Controllable:TaskAttackUnit(DetectedUnit)
end
end
else
self.DetectedUnits[DetectedUnit]=nil
end
end
if#AttackTasks==0 then
self:F("No targets found -> Going back to Patrolling")
self:__Abort(1)
self:__Route(1)
self:SetDetectionActivated()
else
AttackTasks[#AttackTasks+1]=Controllable:TaskFunction("AI_CAP_ZONE.EngageRoute",self)
EngageRoute[1].task=Controllable:TaskCombo(AttackTasks)
self:SetDetectionDeactivated()
end
Controllable:Route(EngageRoute,0.5)
end
end
function AI_CAP_ZONE:onafterAccomplish(Controllable,From,Event,To)
self.Accomplished=true
self:SetDetectionOff()
end
function AI_CAP_ZONE:onafterDestroy(Controllable,From,Event,To,EventData)
if EventData.IniUnit then
self.DetectedUnits[EventData.IniUnit]=nil
end
end
function AI_CAP_ZONE:OnEventDead(EventData)
self:F({"EventDead",EventData})
if EventData.IniDCSUnit then
if self.DetectedUnits and self.DetectedUnits[EventData.IniUnit]then
self:__Destroy(1,EventData)
end
end
end
AI_CAS_ZONE={
ClassName="AI_CAS_ZONE",
}
function AI_CAS_ZONE:New(PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,EngageZone,PatrolAltType)
local self=BASE:Inherit(self,AI_PATROL_ZONE:New(PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,PatrolAltType))
self.EngageZone=EngageZone
self.Accomplished=false
self:SetDetectionZone(self.EngageZone)
self:AddTransition({"Patrolling","Engaging"},"Engage","Engaging")
self:AddTransition("Engaging","Target","Engaging")
self:AddTransition("Engaging","Fired","Engaging")
self:AddTransition("*","Destroy","*")
self:AddTransition("Engaging","Abort","Patrolling")
self:AddTransition("Engaging","Accomplish","Patrolling")
return self
end
function AI_CAS_ZONE:SetEngageZone(EngageZone)
self:F2()
if EngageZone then
self.EngageZone=EngageZone
else
self.EngageZone=nil
end
end
function AI_CAS_ZONE:onafterStart(Controllable,From,Event,To)
self:GetParent(self).onafterStart(self,Controllable,From,Event,To)
self:HandleEvent(EVENTS.Dead)
self:SetDetectionDeactivated()
end
function AI_CAS_ZONE.EngageRoute(EngageGroup,Fsm)
EngageGroup:F({"AI_CAS_ZONE.EngageRoute:",EngageGroup:GetName()})
if EngageGroup:IsAlive()then
Fsm:__Engage(1,Fsm.EngageSpeed,Fsm.EngageAltitude,Fsm.EngageWeaponExpend,Fsm.EngageAttackQty,Fsm.EngageDirection)
end
end
function AI_CAS_ZONE:onbeforeEngage(Controllable,From,Event,To)
if self.Accomplished==true then
return false
end
end
function AI_CAS_ZONE:onafterTarget(Controllable,From,Event,To)
self:E("onafterTarget")
if Controllable:IsAlive()then
local AttackTasks={}
for DetectedUnit,Detected in pairs(self.DetectedUnits)do
local DetectedUnit=DetectedUnit
if DetectedUnit:IsAlive()then
if DetectedUnit:IsInZone(self.EngageZone)then
if Detected==true then
self:E({"Target: ",DetectedUnit})
self.DetectedUnits[DetectedUnit]=false
local AttackTask=Controllable:TaskAttackUnit(DetectedUnit,false,self.EngageWeaponExpend,self.EngageAttackQty,self.EngageDirection,self.EngageAltitude,nil)
self.Controllable:PushTask(AttackTask,1)
end
end
else
self.DetectedUnits[DetectedUnit]=nil
end
end
self:__Target(-10)
end
end
function AI_CAS_ZONE:onafterAbort(Controllable,From,Event,To)
Controllable:ClearTasks()
self:__Route(1)
end
function AI_CAS_ZONE:onafterEngage(Controllable,From,Event,To,
EngageSpeed,
EngageAltitude,
EngageWeaponExpend,
EngageAttackQty,
EngageDirection)
self:F("onafterEngage")
self.EngageSpeed=EngageSpeed or 400
self.EngageAltitude=EngageAltitude or 2000
self.EngageWeaponExpend=EngageWeaponExpend
self.EngageAttackQty=EngageAttackQty
self.EngageDirection=EngageDirection
if Controllable:IsAlive()then
Controllable:OptionROEOpenFire()
Controllable:OptionROTVertical()
local EngageRoute={}
local CurrentVec2=self.Controllable:GetVec2()
local CurrentAltitude=self.Controllable:GetUnit(1):GetAltitude()
local CurrentPointVec3=POINT_VEC3:New(CurrentVec2.x,CurrentAltitude,CurrentVec2.y)
local ToEngageZoneSpeed=self.PatrolMaxSpeed
local CurrentRoutePoint=CurrentPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
self.EngageSpeed,
true
)
EngageRoute[#EngageRoute+1]=CurrentRoutePoint
local AttackTasks={}
for DetectedUnit,Detected in pairs(self.DetectedUnits)do
local DetectedUnit=DetectedUnit
self:T(DetectedUnit)
if DetectedUnit:IsAlive()then
if DetectedUnit:IsInZone(self.EngageZone)then
self:E({"Engaging ",DetectedUnit})
AttackTasks[#AttackTasks+1]=Controllable:TaskAttackUnit(DetectedUnit,
true,
EngageWeaponExpend,
EngageAttackQty,
EngageDirection
)
end
else
self.DetectedUnits[DetectedUnit]=nil
end
end
AttackTasks[#AttackTasks+1]=Controllable:TaskFunction("AI_CAS_ZONE.EngageRoute",self)
EngageRoute[#EngageRoute].task=Controllable:TaskCombo(AttackTasks)
local ToTargetVec2=self.EngageZone:GetRandomVec2()
self:T2(ToTargetVec2)
local ToTargetPointVec3=POINT_VEC3:New(ToTargetVec2.x,self.EngageAltitude,ToTargetVec2.y)
local ToTargetRoutePoint=ToTargetPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
self.EngageSpeed,
true
)
EngageRoute[#EngageRoute+1]=ToTargetRoutePoint
Controllable:Route(EngageRoute,0.5)
self:SetRefreshTimeInterval(2)
self:SetDetectionActivated()
self:__Target(-2)
end
end
function AI_CAS_ZONE:onafterAccomplish(Controllable,From,Event,To)
self.Accomplished=true
self:SetDetectionDeactivated()
end
function AI_CAS_ZONE:onafterDestroy(Controllable,From,Event,To,EventData)
if EventData.IniUnit then
self.DetectedUnits[EventData.IniUnit]=nil
end
end
function AI_CAS_ZONE:OnEventDead(EventData)
self:F({"EventDead",EventData})
if EventData.IniDCSUnit then
if self.DetectedUnits and self.DetectedUnits[EventData.IniUnit]then
self:__Destroy(1,EventData)
end
end
end
AI_BAI_ZONE={
ClassName="AI_BAI_ZONE",
}
function AI_BAI_ZONE:New(PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,EngageZone,PatrolAltType)
local self=BASE:Inherit(self,AI_PATROL_ZONE:New(PatrolZone,PatrolFloorAltitude,PatrolCeilingAltitude,PatrolMinSpeed,PatrolMaxSpeed,PatrolAltType))
self.EngageZone=EngageZone
self.Accomplished=false
self:SetDetectionZone(self.EngageZone)
self:SearchOn()
self:AddTransition({"Patrolling","Engaging"},"Engage","Engaging")
self:AddTransition("Engaging","Target","Engaging")
self:AddTransition("Engaging","Fired","Engaging")
self:AddTransition("*","Destroy","*")
self:AddTransition("Engaging","Abort","Patrolling")
self:AddTransition("Engaging","Accomplish","Patrolling")
return self
end
function AI_BAI_ZONE:SetEngageZone(EngageZone)
self:F2()
if EngageZone then
self.EngageZone=EngageZone
else
self.EngageZone=nil
end
end
function AI_BAI_ZONE:SearchOnOff(Search)
self.Search=Search
return self
end
function AI_BAI_ZONE:SearchOff()
self:SearchOnOff(false)
return self
end
function AI_BAI_ZONE:SearchOn()
self:SearchOnOff(true)
return self
end
function AI_BAI_ZONE:onafterStart(Controllable,From,Event,To)
self:GetParent(self).onafterStart(self,Controllable,From,Event,To)
self:HandleEvent(EVENTS.Dead)
self:SetDetectionDeactivated()
end
function _NewEngageRoute(AIControllable)
AIControllable:T("NewEngageRoute")
local EngageZone=AIControllable:GetState(AIControllable,"EngageZone")
EngageZone:__Engage(1,EngageZone.EngageSpeed,EngageZone.EngageAltitude,EngageZone.EngageWeaponExpend,EngageZone.EngageAttackQty,EngageZone.EngageDirection)
end
function AI_BAI_ZONE:onbeforeEngage(Controllable,From,Event,To)
if self.Accomplished==true then
return false
end
end
function AI_BAI_ZONE:onafterTarget(Controllable,From,Event,To)
self:F({"onafterTarget",self.Search,Controllable:IsAlive()})
if Controllable:IsAlive()then
local AttackTasks={}
if self.Search==true then
for DetectedUnit,Detected in pairs(self.DetectedUnits)do
local DetectedUnit=DetectedUnit
if DetectedUnit:IsAlive()then
if DetectedUnit:IsInZone(self.EngageZone)then
if Detected==true then
self:F({"Target: ",DetectedUnit})
self.DetectedUnits[DetectedUnit]=false
local AttackTask=Controllable:TaskAttackUnit(DetectedUnit,false,self.EngageWeaponExpend,self.EngageAttackQty,self.EngageDirection,self.EngageAltitude,nil)
self.Controllable:PushTask(AttackTask,1)
end
end
else
self.DetectedUnits[DetectedUnit]=nil
end
end
else
self:F("Attack zone")
local AttackTask=Controllable:TaskAttackMapObject(
self.EngageZone:GetPointVec2():GetVec2(),
true,
self.EngageWeaponExpend,
self.EngageAttackQty,
self.EngageDirection,
self.EngageAltitude
)
self.Controllable:PushTask(AttackTask,1)
end
self:__Target(-10)
end
end
function AI_BAI_ZONE:onafterAbort(Controllable,From,Event,To)
Controllable:ClearTasks()
self:__Route(1)
end
function AI_BAI_ZONE:onafterEngage(Controllable,From,Event,To,
EngageSpeed,
EngageAltitude,
EngageWeaponExpend,
EngageAttackQty,
EngageDirection)
self:F("onafterEngage")
self.EngageSpeed=EngageSpeed or 400
self.EngageAltitude=EngageAltitude or 2000
self.EngageWeaponExpend=EngageWeaponExpend
self.EngageAttackQty=EngageAttackQty
self.EngageDirection=EngageDirection
if Controllable:IsAlive()then
local EngageRoute={}
local CurrentVec2=self.Controllable:GetVec2()
local CurrentAltitude=self.Controllable:GetUnit(1):GetAltitude()
local CurrentPointVec3=POINT_VEC3:New(CurrentVec2.x,CurrentAltitude,CurrentVec2.y)
local ToEngageZoneSpeed=self.PatrolMaxSpeed
local CurrentRoutePoint=CurrentPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
self.EngageSpeed,
true
)
EngageRoute[#EngageRoute+1]=CurrentRoutePoint
local AttackTasks={}
if self.Search==true then
for DetectedUnitID,DetectedUnitData in pairs(self.DetectedUnits)do
local DetectedUnit=DetectedUnitData
self:T(DetectedUnit)
if DetectedUnit:IsAlive()then
if DetectedUnit:IsInZone(self.EngageZone)then
self:F({"Engaging ",DetectedUnit})
AttackTasks[#AttackTasks+1]=Controllable:TaskBombing(
DetectedUnit:GetPointVec2():GetVec2(),
true,
EngageWeaponExpend,
EngageAttackQty,
EngageDirection,
EngageAltitude
)
end
else
self.DetectedUnits[DetectedUnit]=nil
end
end
else
self:F("Attack zone")
AttackTasks[#AttackTasks+1]=Controllable:TaskAttackMapObject(
self.EngageZone:GetPointVec2():GetVec2(),
true,
EngageWeaponExpend,
EngageAttackQty,
EngageDirection,
EngageAltitude
)
end
EngageRoute[#EngageRoute].task=Controllable:TaskCombo(AttackTasks)
local ToTargetVec2=self.EngageZone:GetRandomVec2()
self:T2(ToTargetVec2)
local ToTargetPointVec3=POINT_VEC3:New(ToTargetVec2.x,self.EngageAltitude,ToTargetVec2.y)
local ToTargetRoutePoint=ToTargetPointVec3:WaypointAir(
self.PatrolAltType,
POINT_VEC3.RoutePointType.TurningPoint,
POINT_VEC3.RoutePointAction.TurningPoint,
self.EngageSpeed,
true
)
EngageRoute[#EngageRoute+1]=ToTargetRoutePoint
Controllable:OptionROEOpenFire()
Controllable:OptionROTVertical()
Controllable:WayPointInitialize(EngageRoute)
Controllable:SetState(Controllable,"EngageZone",self)
Controllable:WayPointFunction(#EngageRoute,1,"_NewEngageRoute")
Controllable:WayPointExecute(1)
self:SetRefreshTimeInterval(2)
self:SetDetectionActivated()
self:__Target(-2)
end
end
function AI_BAI_ZONE:onafterAccomplish(Controllable,From,Event,To)
self.Accomplished=true
self:SetDetectionDeactivated()
end
function AI_BAI_ZONE:onafterDestroy(Controllable,From,Event,To,EventData)
if EventData.IniUnit then
self.DetectedUnits[EventData.IniUnit]=nil
end
end
function AI_BAI_ZONE:OnEventDead(EventData)
self:F({"EventDead",EventData})
if EventData.IniDCSUnit then
if self.DetectedUnits and self.DetectedUnits[EventData.IniUnit]then
self:__Destroy(1,EventData)
end
end
end
AI_FORMATION={
ClassName="AI_FORMATION",
FollowName=nil,
FollowUnit=nil,
FollowGroupSet=nil,
FollowMode=1,
MODE={
FOLLOW=1,
MISSION=2,
},
FollowScheduler=nil,
OptionROE=AI.Option.Air.val.ROE.OPEN_FIRE,
OptionReactionOnThreat=AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
}
function AI_FORMATION:New(FollowUnit,FollowGroupSet,FollowName,FollowBriefing)
local self=BASE:Inherit(self,FSM_SET:New(FollowGroupSet))
self:F({FollowUnit,FollowGroupSet,FollowName})
self.FollowUnit=FollowUnit
self.FollowGroupSet=FollowGroupSet
self:SetFlightRandomization(2)
self:SetStartState("None")
self:AddTransition("*","Stop","Stopped")
self:AddTransition("None","Start","Following")
self:AddTransition("*","FormationLine","*")
self:AddTransition("*","FormationTrail","*")
self:AddTransition("*","FormationStack","*")
self:AddTransition("*","FormationLeftLine","*")
self:AddTransition("*","FormationRightLine","*")
self:AddTransition("*","FormationLeftWing","*")
self:AddTransition("*","FormationRightWing","*")
self:AddTransition("*","FormationCenterWing","*")
self:AddTransition("*","FormationVic","*")
self:AddTransition("*","FormationBox","*")
self:AddTransition("*","Follow","Following")
self:FormationLeftLine(500,0,250,250)
self.FollowName=FollowName
self.FollowBriefing=FollowBriefing
self.CT1=0
self.GT1=0
self.FollowMode=AI_FORMATION.MODE.MISSION
return self
end
function AI_FORMATION:TestSmokeDirectionVector(SmokeDirection)
self.SmokeDirectionVector=(SmokeDirection==true)and true or false
return self
end
function AI_FORMATION:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,ZStart,ZSpace)
self:F({FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,ZStart,ZSpace})
FollowGroupSet:Flush()
local FollowSet=FollowGroupSet:GetSet()
local i=0
for FollowID,FollowGroup in pairs(FollowSet)do
local PointVec3=POINT_VEC3:New()
PointVec3:SetX(XStart+i*XSpace)
PointVec3:SetY(YStart+i*YSpace)
PointVec3:SetZ(ZStart+i*ZSpace)
local Vec3=PointVec3:GetVec3()
FollowGroup:SetState(self,"FormationVec3",Vec3)
i=i+1
end
return self
end
function AI_FORMATION:onafterFormationTrail(FollowGroupSet,From,Event,To,XStart,XSpace,YStart)
self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,0,0,0)
return self
end
function AI_FORMATION:onafterFormationStack(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace)
self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,0,0)
return self
end
function AI_FORMATION:onafterFormationLeftLine(FollowGroupSet,From,Event,To,XStart,YStart,ZStart,ZSpace)
self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,0,YStart,0,ZStart,ZSpace)
return self
end
function AI_FORMATION:onafterFormationRightLine(FollowGroupSet,From,Event,To,XStart,YStart,ZStart,ZSpace)
self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,0,YStart,0,-ZStart,-ZSpace)
return self
end
function AI_FORMATION:onafterFormationLeftWing(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,ZStart,ZSpace)
self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,0,ZStart,ZSpace)
return self
end
function AI_FORMATION:onafterFormationRightWing(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,ZStart,ZSpace)
self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,0,-ZStart,-ZSpace)
return self
end
function AI_FORMATION:onafterFormationCenterWing(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,ZStart,ZSpace)
local FollowSet=FollowGroupSet:GetSet()
local i=0
for FollowID,FollowGroup in pairs(FollowSet)do
local PointVec3=POINT_VEC3:New()
local Side=(i%2==0)and 1 or-1
local Row=i/2+1
PointVec3:SetX(XStart+Row*XSpace)
PointVec3:SetY(YStart)
PointVec3:SetZ(Side*(ZStart+i*ZSpace))
local Vec3=PointVec3:GetVec3()
FollowGroup:SetState(self,"FormationVec3",Vec3)
i=i+1
end
return self
end
function AI_FORMATION:onafterFormationVic(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,ZStart,ZSpace)
self:onafterFormationCenterWing(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,ZStart,ZSpace)
return self
end
function AI_FORMATION:onafterFormationBox(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,ZStart,ZSpace,ZLevels)
local FollowSet=FollowGroupSet:GetSet()
local i=0
for FollowID,FollowGroup in pairs(FollowSet)do
local PointVec3=POINT_VEC3:New()
local ZIndex=i%ZLevels
local XIndex=math.floor(i/ZLevels)
local YIndex=math.floor(i/ZLevels)
PointVec3:SetX(XStart+XIndex*XSpace)
PointVec3:SetY(YStart+YIndex*YSpace)
PointVec3:SetZ(-ZStart-(ZSpace*ZLevels/2)+ZSpace*ZIndex)
local Vec3=PointVec3:GetVec3()
FollowGroup:SetState(self,"FormationVec3",Vec3)
i=i+1
end
return self
end
function AI_FORMATION:SetFlightRandomization(FlightRandomization)
self.FlightRandomization=FlightRandomization
return self
end
function AI_FORMATION:onenterFollowing(FollowGroupSet)
self:F()
self:T({self.FollowUnit.UnitName,self.FollowUnit:IsAlive()})
if self.FollowUnit:IsAlive()then
local ClientUnit=self.FollowUnit
self:T({ClientUnit.UnitName})
local CT1,CT2,CV1,CV2
CT1=ClientUnit:GetState(self,"CT1")
if CT1==nil or CT1==0 then
ClientUnit:SetState(self,"CV1",ClientUnit:GetPointVec3())
ClientUnit:SetState(self,"CT1",timer.getTime())
else
CT1=ClientUnit:GetState(self,"CT1")
CT2=timer.getTime()
CV1=ClientUnit:GetState(self,"CV1")
CV2=ClientUnit:GetPointVec3()
ClientUnit:SetState(self,"CT1",CT2)
ClientUnit:SetState(self,"CV1",CV2)
end
FollowGroupSet:ForEachGroup(
function(FollowGroup,Formation,ClientUnit,CT1,CV1,CT2,CV2)
FollowGroup:OptionROTEvadeFire()
FollowGroup:OptionROEReturnFire()
local GroupUnit=FollowGroup:GetUnit(1)
local FollowFormation=FollowGroup:GetState(self,"FormationVec3")
if FollowFormation then
local FollowDistance=FollowFormation.x
local GT1=GroupUnit:GetState(self,"GT1")
if CT1==nil or CT1==0 or GT1==nil or GT1==0 then
GroupUnit:SetState(self,"GV1",GroupUnit:GetPointVec3())
GroupUnit:SetState(self,"GT1",timer.getTime())
else
local CD=((CV2.x-CV1.x)^2+(CV2.y-CV1.y)^2+(CV2.z-CV1.z)^2)^0.5
local CT=CT2-CT1
local CS=(3600/CT)*(CD/1000)/3.6
local CDv={x=CV2.x-CV1.x,y=CV2.y-CV1.y,z=CV2.z-CV1.z}
local Ca=math.atan2(CDv.x,CDv.z)
local GT1=GroupUnit:GetState(self,"GT1")
local GT2=timer.getTime()
local GV1=GroupUnit:GetState(self,"GV1")
local GV2=GroupUnit:GetPointVec3()
GV2:AddX(math.random(-Formation.FlightRandomization/2,Formation.FlightRandomization/2))
GV2:AddY(math.random(-Formation.FlightRandomization/2,Formation.FlightRandomization/2))
GV2:AddZ(math.random(-Formation.FlightRandomization/2,Formation.FlightRandomization/2))
GroupUnit:SetState(self,"GT1",GT2)
GroupUnit:SetState(self,"GV1",GV2)
local GD=((GV2.x-GV1.x)^2+(GV2.y-GV1.y)^2+(GV2.z-GV1.z)^2)^0.5
local GT=GT2-GT1
local GDv={x=GV2.x-CV1.x,y=GV2.y-CV1.y,z=GV2.z-CV1.z}
local Alpha_T=math.atan2(GDv.x,GDv.z)-math.atan2(CDv.x,CDv.z)
local Alpha_R=(Alpha_T<0)and Alpha_T+2*math.pi or Alpha_T
local Position=math.cos(Alpha_R)
local GD=((GDv.x)^2+(GDv.z)^2)^0.5
local Distance=GD*Position+-CS*0,5
local GV={x=GV2.x-CV2.x,y=GV2.y-CV2.y,z=GV2.z-CV2.z}
local GH2={x=GV2.x,y=CV2.y+FollowFormation.y,z=GV2.z}
local alpha=math.atan2(GV.x,GV.z)
local GVx=FollowFormation.z*math.cos(Ca)+FollowFormation.x*math.sin(Ca)
local GVz=FollowFormation.x*math.cos(Ca)-FollowFormation.z*math.sin(Ca)
local CVI={x=CV2.x+CS*10*math.sin(Ca),
y=GH2.y-(Distance+FollowFormation.x)/5,
z=CV2.z+CS*10*math.cos(Ca),
}
local DV={x=CV2.x-CVI.x,y=CV2.y-CVI.y,z=CV2.z-CVI.z}
local DVu={x=DV.x/FollowDistance,y=DV.y,z=DV.z/FollowDistance}
local GDV={x=CVI.x,y=CVI.y,z=CVI.z}
local ADDx=FollowFormation.x*math.cos(alpha)-FollowFormation.z*math.sin(alpha)
local ADDz=FollowFormation.z*math.cos(alpha)+FollowFormation.x*math.sin(alpha)
local GDV_Formation={
x=GDV.x-GVx,
y=GDV.y,
z=GDV.z-GVz
}
if self.SmokeDirectionVector==true then
trigger.action.smoke(GDV,trigger.smokeColor.Green)
trigger.action.smoke(GDV_Formation,trigger.smokeColor.White)
end
local Time=60
local Speed=-(Distance+FollowFormation.x)/Time
local GS=Speed+CS
if Speed<0 then
Speed=0
end
FollowGroup:RouteToVec3(GDV_Formation,GS)
end
end
end,
self,ClientUnit,CT1,CV1,CT2,CV2
)
self:__Follow(-0.5)
end
end
do
ACT_ASSIGN={
ClassName="ACT_ASSIGN",
}
function ACT_ASSIGN:New()
local self=BASE:Inherit(self,FSM_PROCESS:New("ACT_ASSIGN"))
self:AddTransition("UnAssigned","Start","Waiting")
self:AddTransition("Waiting","Assign","Assigned")
self:AddTransition("Waiting","Reject","Rejected")
self:AddTransition("*","Fail","Failed")
self:AddEndState("Assigned")
self:AddEndState("Rejected")
self:AddEndState("Failed")
self:SetStartState("UnAssigned")
return self
end
end
do
ACT_ASSIGN_ACCEPT={
ClassName="ACT_ASSIGN_ACCEPT",
}
function ACT_ASSIGN_ACCEPT:New(TaskBriefing)
local self=BASE:Inherit(self,ACT_ASSIGN:New())
self.TaskBriefing=TaskBriefing
return self
end
function ACT_ASSIGN_ACCEPT:Init(FsmAssign)
self.TaskBriefing=FsmAssign.TaskBriefing
end
function ACT_ASSIGN_ACCEPT:onafterStart(ProcessUnit,From,Event,To)
self:E({ProcessUnit,From,Event,To})
self:__Assign(1)
end
function ACT_ASSIGN_ACCEPT:onenterAssigned(ProcessUnit,From,Event,To)
env.info("in here")
self:E({ProcessUnit,From,Event,To})
local ProcessGroup=ProcessUnit:GetGroup()
self.Task:Assign(ProcessUnit,ProcessUnit:GetPlayerName())
end
end
do
ACT_ASSIGN_MENU_ACCEPT={
ClassName="ACT_ASSIGN_MENU_ACCEPT",
}
function ACT_ASSIGN_MENU_ACCEPT:New(TaskName,TaskBriefing)
local self=BASE:Inherit(self,ACT_ASSIGN:New())
self.TaskName=TaskName
self.TaskBriefing=TaskBriefing
return self
end
function ACT_ASSIGN_MENU_ACCEPT:Init(FsmAssign)
self.TaskName=FsmAssign.TaskName
self.TaskBriefing=FsmAssign.TaskBriefing
end
function ACT_ASSIGN_MENU_ACCEPT:Init(TaskName,TaskBriefing)
self.TaskBriefing=TaskBriefing
self.TaskName=TaskName
return self
end
function ACT_ASSIGN_MENU_ACCEPT:onafterStart(ProcessUnit,From,Event,To)
self:E({ProcessUnit,From,Event,To})
self:GetCommandCenter():MessageTypeToGroup("Access the radio menu to accept the task. You have 30 seconds or the assignment will be cancelled.",ProcessUnit:GetGroup(),MESSAGE.Type.Information)
local ProcessGroup=ProcessUnit:GetGroup()
self.Menu=MENU_GROUP:New(ProcessGroup,"Task "..self.TaskName.." acceptance")
self.MenuAcceptTask=MENU_GROUP_COMMAND:New(ProcessGroup,"Accept task "..self.TaskName,self.Menu,self.MenuAssign,self)
self.MenuRejectTask=MENU_GROUP_COMMAND:New(ProcessGroup,"Reject task "..self.TaskName,self.Menu,self.MenuReject,self)
end
function ACT_ASSIGN_MENU_ACCEPT:MenuAssign()
self:E()
self:__Assign(1)
end
function ACT_ASSIGN_MENU_ACCEPT:MenuReject()
self:E()
self:__Reject(1)
end
function ACT_ASSIGN_MENU_ACCEPT:onafterAssign(ProcessUnit,From,Event,To)
self:E({ProcessUnit.UnitNameFrom,Event,To})
self.Menu:Remove()
end
function ACT_ASSIGN_MENU_ACCEPT:onafterReject(ProcessUnit,From,Event,To)
self:E({ProcessUnit.UnitName,From,Event,To})
self.Menu:Remove()
ProcessUnit:Destroy()
end
end
do
ACT_ROUTE={
ClassName="ACT_ROUTE",
}
function ACT_ROUTE:New()
local self=BASE:Inherit(self,FSM_PROCESS:New("ACT_ROUTE"))
self:AddTransition("*","Reset","None")
self:AddTransition("None","Start","Routing")
self:AddTransition("*","Report","*")
self:AddTransition("Routing","Route","Routing")
self:AddTransition("Routing","Pause","Pausing")
self:AddTransition("Routing","Arrive","Arrived")
self:AddTransition("*","Cancel","Cancelled")
self:AddTransition("Arrived","Success","Success")
self:AddTransition("*","Fail","Failed")
self:AddTransition("","","")
self:AddTransition("","","")
self:AddEndState("Arrived")
self:AddEndState("Failed")
self:AddEndState("Cancelled")
self:SetStartState("None")
self:SetRouteMode("C")
return self
end
function ACT_ROUTE:SetMenuCancel(MenuGroup,MenuText,ParentMenu,MenuTime)
MENU_GROUP_COMMAND:New(
MenuGroup,
MenuText,
ParentMenu,
self.MenuCancel,
self
):SetTime(MenuTime)
return self
end
function ACT_ROUTE:SetRouteMode(RouteMode)
self.RouteMode=RouteMode
return self
end
function ACT_ROUTE:GetRouteText(Controllable)
self:E()
local RouteText=""
local Coordinate=nil
if self.Coordinate then
Coordinate=self.Coordinate
end
if self.Zone then
Coordinate=self.Zone:GetPointVec3(self.Altitude)
Coordinate:SetHeading(self.Heading)
end
local Task=self:GetTask()
local CC=self:GetTask():GetMission():GetCommandCenter()
if CC then
if CC:IsModeWWII()then
local ShortestDistance=0
local ShortestReferencePoint=nil
local ShortestReferenceName=""
self:E({CC.ReferencePoints})
for ZoneName,Zone in pairs(CC.ReferencePoints)do
self:E({ZoneName=ZoneName})
local Zone=Zone
local ZoneCoord=Zone:GetCoordinate()
local ZoneDistance=ZoneCoord:Get2DDistance(self.Coordinate)
self:E({ShortestDistance,ShortestReferenceName})
if ShortestDistance==0 or ZoneDistance<ShortestDistance then
ShortestDistance=ZoneDistance
ShortestReferencePoint=ZoneCoord
ShortestReferenceName=CC.ReferenceNames[ZoneName]
end
end
if ShortestReferencePoint then
RouteText=Coordinate:ToStringFromRP(ShortestReferencePoint,ShortestReferenceName,Controllable)
end
else
RouteText=Coordinate:ToString(Controllable,nil,Task)
end
end
return RouteText
end
function ACT_ROUTE:MenuCancel()
self:Cancel()
end
function ACT_ROUTE:onafterStart(ProcessUnit,From,Event,To)
self:__Route(1)
end
function ACT_ROUTE:onfuncHasArrived(ProcessUnit)
return false
end
function ACT_ROUTE:onbeforeRoute(ProcessUnit,From,Event,To)
self:F({"BeforeRoute 1",self.DisplayCount,self.DisplayInterval})
if ProcessUnit:IsAlive()then
self:F("BeforeRoute 2")
local HasArrived=self:onfuncHasArrived(ProcessUnit)
if self.DisplayCount>=self.DisplayInterval then
self:T({HasArrived=HasArrived})
if not HasArrived then
self:Report()
end
self.DisplayCount=1
else
self.DisplayCount=self.DisplayCount+1
end
self:T({DisplayCount=self.DisplayCount})
if HasArrived then
self:__Arrive(1)
else
self:__Route(1)
end
return HasArrived
end
return false
end
end
do
ACT_ROUTE_POINT={
ClassName="ACT_ROUTE_POINT",
}
function ACT_ROUTE_POINT:New(Coordinate,Range)
local self=BASE:Inherit(self,ACT_ROUTE:New())
self.Coordinate=Coordinate
self.Range=Range or 0
self.DisplayInterval=30
self.DisplayCount=30
self.DisplayMessage=true
self.DisplayTime=10
return self
end
function ACT_ROUTE_POINT:Init(FsmRoute)
self.Coordinate=FsmRoute.Coordinate
self.Range=FsmRoute.Range or 0
self.DisplayInterval=30
self.DisplayCount=30
self.DisplayMessage=true
self.DisplayTime=10
self:SetStartState("None")
end
function ACT_ROUTE_POINT:SetCoordinate(Coordinate)
self:F2({Coordinate})
self.Coordinate=Coordinate
end
function ACT_ROUTE_POINT:GetCoordinate()
self:F2({self.Coordinate})
return self.Coordinate
end
function ACT_ROUTE_POINT:SetRange(Range)
self:F2({self.Range})
self.Range=Range or 10000
end
function ACT_ROUTE_POINT:GetRange()
return self.Range
end
function ACT_ROUTE_POINT:onfuncHasArrived(ProcessUnit)
if ProcessUnit:IsAlive()then
local Distance=self.Coordinate:Get2DDistance(ProcessUnit:GetCoordinate())
if Distance<=self.Range then
local RouteText="You have arrived."
self:GetCommandCenter():MessageTypeToGroup(RouteText,ProcessUnit:GetGroup(),MESSAGE.Type.Information)
return true
end
end
return false
end
function ACT_ROUTE_POINT:onafterReport(ProcessUnit,From,Event,To)
local RouteText=self:GetRouteText(ProcessUnit)
self:GetCommandCenter():MessageTypeToGroup(RouteText,ProcessUnit:GetGroup(),MESSAGE.Type.Update)
end
end
do
ACT_ROUTE_ZONE={
ClassName="ACT_ROUTE_ZONE",
}
function ACT_ROUTE_ZONE:New(Zone)
local self=BASE:Inherit(self,ACT_ROUTE:New())
self.Zone=Zone
self.DisplayInterval=30
self.DisplayCount=30
self.DisplayMessage=true
self.DisplayTime=10
return self
end
function ACT_ROUTE_ZONE:Init(FsmRoute)
self.Zone=FsmRoute.Zone
self.DisplayInterval=30
self.DisplayCount=30
self.DisplayMessage=true
self.DisplayTime=10
end
function ACT_ROUTE_ZONE:SetZone(Zone,Altitude,Heading)
self.Zone=Zone
self.Altitude=Altitude
self.Heading=Heading
end
function ACT_ROUTE_ZONE:GetZone()
return self.Zone
end
function ACT_ROUTE_ZONE:onfuncHasArrived(ProcessUnit)
if ProcessUnit:IsInZone(self.Zone)then
local RouteText="You have arrived within the zone."
self:GetCommandCenter():MessageTypeToGroup(RouteText,ProcessUnit:GetGroup(),MESSAGE.Type.Information)
end
return ProcessUnit:IsInZone(self.Zone)
end
function ACT_ROUTE_ZONE:onafterReport(ProcessUnit,From,Event,To)
self:E({ProcessUnit=ProcessUnit})
local RouteText=self:GetRouteText(ProcessUnit)
self:GetCommandCenter():MessageTypeToGroup(RouteText,ProcessUnit:GetGroup(),MESSAGE.Type.Update)
end
end
do
ACT_ACCOUNT={
ClassName="ACT_ACCOUNT",
TargetSetUnit=nil,
}
function ACT_ACCOUNT:New()
local self=BASE:Inherit(self,FSM_PROCESS:New())
self:AddTransition("Assigned","Start","Waiting")
self:AddTransition("*","Wait","Waiting")
self:AddTransition("*","Report","Report")
self:AddTransition("*","Event","Account")
self:AddTransition("Account","Player","AccountForPlayer")
self:AddTransition("Account","Other","AccountForOther")
self:AddTransition({"Account","AccountForPlayer","AccountForOther"},"More","Wait")
self:AddTransition({"Account","AccountForPlayer","AccountForOther"},"NoMore","Accounted")
self:AddTransition("*","Fail","Failed")
self:AddEndState("Failed")
self:SetStartState("Assigned")
return self
end
function ACT_ACCOUNT:onafterStart(ProcessUnit,From,Event,To)
self:HandleEvent(EVENTS.Dead,self.onfuncEventDead)
self:HandleEvent(EVENTS.Crash,self.onfuncEventCrash)
self:HandleEvent(EVENTS.Hit)
self:__Wait(1)
end
function ACT_ACCOUNT:onenterWaiting(ProcessUnit,From,Event,To)
if self.DisplayCount>=self.DisplayInterval then
self:Report()
self.DisplayCount=1
else
self.DisplayCount=self.DisplayCount+1
end
return true
end
function ACT_ACCOUNT:onafterEvent(ProcessUnit,From,Event,To,Event)
self:__NoMore(1)
end
end
do
ACT_ACCOUNT_DEADS={
ClassName="ACT_ACCOUNT_DEADS",
}
function ACT_ACCOUNT_DEADS:New()
local self=BASE:Inherit(self,ACT_ACCOUNT:New())
self.DisplayInterval=30
self.DisplayCount=30
self.DisplayMessage=true
self.DisplayTime=10
self.DisplayCategory="HQ"
return self
end
function ACT_ACCOUNT_DEADS:Init(FsmAccount)
self.Task=self:GetTask()
self.TaskName=self.Task:GetName()
end
function ACT_ACCOUNT_DEADS:onenterReport(ProcessUnit,Task,From,Event,To)
self:E({ProcessUnit,From,Event,To})
local MessageText="Your group with assigned "..self.TaskName.." task has "..Task.TargetSetUnit:GetUnitTypesText().." targets left to be destroyed."
self:GetCommandCenter():MessageTypeToGroup(MessageText,ProcessUnit:GetGroup(),MESSAGE.Type.Information)
end
function ACT_ACCOUNT_DEADS:onafterEvent(ProcessUnit,Task,From,Event,To,EventData)
self:T({ProcessUnit:GetName(),Task:GetName(),From,Event,To,EventData})
if Task.TargetSetUnit:FindUnit(EventData.IniUnitName)then
local PlayerName=ProcessUnit:GetPlayerName()
local PlayerHit=self.PlayerHits and self.PlayerHits[EventData.IniUnitName]
if PlayerHit==PlayerName then
self:Player(EventData)
else
self:Other(EventData)
end
end
end
function ACT_ACCOUNT_DEADS:onenterAccountForPlayer(ProcessUnit,Task,From,Event,To,EventData)
self:T({ProcessUnit:GetName(),Task:GetName(),From,Event,To,EventData})
local TaskGroup=ProcessUnit:GetGroup()
Task.TargetSetUnit:Remove(EventData.IniUnitName)
local MessageText="You have destroyed a target.\nYour group assigned with task "..self.TaskName.." has\n"..Task.TargetSetUnit:Count().." targets ( "..Task.TargetSetUnit:GetUnitTypesText().." ) left to be destroyed."
self:GetCommandCenter():MessageTypeToGroup(MessageText,ProcessUnit:GetGroup(),MESSAGE.Type.Information)
local PlayerName=ProcessUnit:GetPlayerName()
Task:AddProgress(PlayerName,"Destroyed "..EventData.IniTypeName,timer.getTime(),1)
if Task.TargetSetUnit:Count()>0 then
self:__More(1)
else
self:__NoMore(1)
end
end
function ACT_ACCOUNT_DEADS:onenterAccountForOther(ProcessUnit,Task,From,Event,To,EventData)
self:T({ProcessUnit:GetName(),Task:GetName(),From,Event,To,EventData})
local TaskGroup=ProcessUnit:GetGroup()
Task.TargetSetUnit:Remove(EventData.IniUnitName)
local MessageText="One of the task targets has been destroyed.\nYour group assigned with task "..self.TaskName.." has\n"..Task.TargetSetUnit:Count().." targets ( "..Task.TargetSetUnit:GetUnitTypesText().." ) left to be destroyed."
self:GetCommandCenter():MessageTypeToGroup(MessageText,ProcessUnit:GetGroup(),MESSAGE.Type.Information)
if Task.TargetSetUnit:Count()>0 then
self:__More(1)
else
self:__NoMore(1)
end
end
function ACT_ACCOUNT_DEADS:OnEventHit(EventData)
self:T({"EventDead",EventData})
if EventData.IniPlayerName and EventData.TgtDCSUnitName then
self.PlayerHits=self.PlayerHits or{}
self.PlayerHits[EventData.TgtDCSUnitName]=EventData.IniPlayerName
end
end
function ACT_ACCOUNT_DEADS:onfuncEventDead(EventData)
self:T({"EventDead",EventData})
if EventData.IniDCSUnit then
self:Event(EventData)
end
end
function ACT_ACCOUNT_DEADS:onfuncEventCrash(EventData)
self:T({"EventDead",EventData})
if EventData.IniDCSUnit then
self:Event(EventData)
end
end
end
do
ACT_ASSIST={
ClassName="ACT_ASSIST",
}
function ACT_ASSIST:New()
local self=BASE:Inherit(self,FSM_PROCESS:New("ACT_ASSIST"))
self:AddTransition("None","Start","AwaitSmoke")
self:AddTransition("AwaitSmoke","Next","Smoking")
self:AddTransition("Smoking","Next","AwaitSmoke")
self:AddTransition("*","Stop","Success")
self:AddTransition("*","Fail","Failed")
self:AddEndState("Failed")
self:AddEndState("Success")
self:SetStartState("None")
return self
end
function ACT_ASSIST:onafterStart(ProcessUnit,From,Event,To)
local ProcessGroup=ProcessUnit:GetGroup()
local MissionMenu=self:GetMission():GetMenu(ProcessGroup)
local function MenuSmoke(MenuParam)
self:E(MenuParam)
local self=MenuParam.self
local SmokeColor=MenuParam.SmokeColor
self.SmokeColor=SmokeColor
self:__Next(1)
end
self.Menu=MENU_GROUP:New(ProcessGroup,"Target acquisition",MissionMenu)
self.MenuSmokeBlue=MENU_GROUP_COMMAND:New(ProcessGroup,"Drop blue smoke on targets",self.Menu,MenuSmoke,{self=self,SmokeColor=SMOKECOLOR.Blue})
self.MenuSmokeGreen=MENU_GROUP_COMMAND:New(ProcessGroup,"Drop green smoke on targets",self.Menu,MenuSmoke,{self=self,SmokeColor=SMOKECOLOR.Green})
self.MenuSmokeOrange=MENU_GROUP_COMMAND:New(ProcessGroup,"Drop Orange smoke on targets",self.Menu,MenuSmoke,{self=self,SmokeColor=SMOKECOLOR.Orange})
self.MenuSmokeRed=MENU_GROUP_COMMAND:New(ProcessGroup,"Drop Red smoke on targets",self.Menu,MenuSmoke,{self=self,SmokeColor=SMOKECOLOR.Red})
self.MenuSmokeWhite=MENU_GROUP_COMMAND:New(ProcessGroup,"Drop White smoke on targets",self.Menu,MenuSmoke,{self=self,SmokeColor=SMOKECOLOR.White})
end
function ACT_ASSIST:onafterStop(ProcessUnit,From,Event,To)
self.Menu:Remove()
end
end
do
ACT_ASSIST_SMOKE_TARGETS_ZONE={
ClassName="ACT_ASSIST_SMOKE_TARGETS_ZONE",
}
function ACT_ASSIST_SMOKE_TARGETS_ZONE:New(TargetSetUnit,TargetZone)
local self=BASE:Inherit(self,ACT_ASSIST:New())
self.TargetSetUnit=TargetSetUnit
self.TargetZone=TargetZone
return self
end
function ACT_ASSIST_SMOKE_TARGETS_ZONE:Init(FsmSmoke)
self.TargetSetUnit=FsmSmoke.TargetSetUnit
self.TargetZone=FsmSmoke.TargetZone
end
function ACT_ASSIST_SMOKE_TARGETS_ZONE:Init(TargetSetUnit,TargetZone)
self.TargetSetUnit=TargetSetUnit
self.TargetZone=TargetZone
return self
end
function ACT_ASSIST_SMOKE_TARGETS_ZONE:onenterSmoking(ProcessUnit,From,Event,To)
self.TargetSetUnit:ForEachUnit(
function(SmokeUnit)
if math.random(1,(100*self.TargetSetUnit:Count())/4)<=100 then
SCHEDULER:New(self,
function()
if SmokeUnit:IsAlive()then
SmokeUnit:Smoke(self.SmokeColor,150)
end
end,{},math.random(10,60)
)
end
end
)
end
end
COMMANDCENTER={
ClassName="COMMANDCENTER",
CommandCenterName="",
CommandCenterCoalition=nil,
CommandCenterPositionable=nil,
Name="",
ReferencePoints={},
ReferenceNames={},
CommunicationMode="80",
}
function COMMANDCENTER:New(CommandCenterPositionable,CommandCenterName)
local self=BASE:Inherit(self,BASE:New())
self.CommandCenterPositionable=CommandCenterPositionable
self.CommandCenterName=CommandCenterName or CommandCenterPositionable:GetName()
self.CommandCenterCoalition=CommandCenterPositionable:GetCoalition()
self.Missions={}
self:HandleEvent(EVENTS.Birth,
function(self,EventData)
if EventData.IniObjectCategory==1 then
local EventGroup=GROUP:Find(EventData.IniDCSGroup)
if EventGroup and self:HasGroup(EventGroup)then
local MenuReporting=MENU_GROUP:New(EventGroup,"Missions Reports",self.CommandCenterMenu)
local MenuMissionsSummary=MENU_GROUP_COMMAND:New(EventGroup,"Missions Status Report",MenuReporting,self.ReportMissionsStatus,self,EventGroup)
local MenuMissionsDetails=MENU_GROUP_COMMAND:New(EventGroup,"Missions Players Report",MenuReporting,self.ReportMissionsPlayers,self,EventGroup)
self:ReportSummary(EventGroup)
local PlayerUnit=EventData.IniUnit
for MissionID,Mission in pairs(self:GetMissions())do
local Mission=Mission
local PlayerGroup=EventData.IniGroup
Mission:JoinUnit(PlayerUnit,PlayerGroup)
end
self:SetMenu()
_DATABASE:PlayerSettingsMenu(PlayerUnit)
end
end
end
)
self:HandleEvent(EVENTS.PlayerEnterUnit,
function(self,EventData)
local PlayerUnit=EventData.IniUnit
for MissionID,Mission in pairs(self:GetMissions())do
local Mission=Mission
local PlayerGroup=EventData.IniGroup
Mission:JoinUnit(PlayerUnit,PlayerGroup)
end
self:SetMenu()
end
)
self:HandleEvent(EVENTS.MissionEnd,
function(self,EventData)
local PlayerUnit=EventData.IniUnit
for MissionID,Mission in pairs(self:GetMissions())do
local Mission=Mission
Mission:Stop()
end
end
)
self:HandleEvent(EVENTS.PlayerLeaveUnit,
function(self,EventData)
local PlayerUnit=EventData.IniUnit
for MissionID,Mission in pairs(self:GetMissions())do
local Mission=Mission
if Mission:IsENGAGED()then
Mission:AbortUnit(PlayerUnit)
end
end
end
)
self:HandleEvent(EVENTS.Crash,
function(self,EventData)
local PlayerUnit=EventData.IniUnit
for MissionID,Mission in pairs(self:GetMissions())do
local Mission=Mission
if Mission:IsENGAGED()then
Mission:CrashUnit(PlayerUnit)
end
end
end
)
self:SetMenu()
_SETTINGS:SetSystemMenu(CommandCenterPositionable)
return self
end
function COMMANDCENTER:GetName()
return self.CommandCenterName
end
function COMMANDCENTER:GetPositionable()
return self.CommandCenterPositionable
end
function COMMANDCENTER:GetMissions()
return self.Missions
end
function COMMANDCENTER:AddMission(Mission)
self.Missions[Mission]=Mission
return Mission
end
function COMMANDCENTER:RemoveMission(Mission)
self.Missions[Mission]=nil
return Mission
end
function COMMANDCENTER:SetReferenceZones(ReferenceZonePrefix)
local MatchPattern="(.*)#(.*)"
self:F({MatchPattern=MatchPattern})
for ReferenceZoneName in pairs(_DATABASE.ZONENAMES)do
local ZoneName,ReferenceName=string.match(ReferenceZoneName,MatchPattern)
self:F({ZoneName=ZoneName,ReferenceName=ReferenceName})
if ZoneName and ReferenceName and ZoneName==ReferenceZonePrefix then
self.ReferencePoints[ReferenceZoneName]=ZONE:New(ReferenceZoneName)
self.ReferenceNames[ReferenceZoneName]=ReferenceName
end
end
return self
end
function COMMANDCENTER:SetModeWWII()
self.CommunicationMode="WWII"
return self
end
function COMMANDCENTER:IsModeWWII()
return self.CommunicationMode=="WWII"
end
function COMMANDCENTER:SetMenu()
self:F()
self.CommandCenterMenu=self.CommandCenterMenu or MENU_COALITION:New(self.CommandCenterCoalition,"Command Center ("..self:GetName()..")")
local MenuTime=timer.getTime()
for MissionID,Mission in pairs(self:GetMissions()or{})do
local Mission=Mission
Mission:SetMenu(MenuTime)
end
for MissionID,Mission in pairs(self:GetMissions()or{})do
local Mission=Mission
Mission:RemoveMenu(MenuTime)
end
end
function COMMANDCENTER:GetMenu()
return self.CommandCenterMenu
end
function COMMANDCENTER:HasGroup(MissionGroup)
local Has=false
for MissionID,Mission in pairs(self.Missions)do
local Mission=Mission
if Mission:HasGroup(MissionGroup)then
Has=true
break
end
end
return Has
end
function COMMANDCENTER:MessageToAll(Message)
self:GetPositionable():MessageToAll(Message,20,self:GetName())
end
function COMMANDCENTER:MessageToGroup(Message,TaskGroup)
self:GetPositionable():MessageToGroup(Message,15,TaskGroup,self:GetName())
end
function COMMANDCENTER:MessageTypeToGroup(Message,TaskGroup,MessageType)
self:GetPositionable():MessageTypeToGroup(Message,MessageType,TaskGroup,self:GetName())
end
function COMMANDCENTER:MessageToCoalition(Message)
local CCCoalition=self:GetPositionable():GetCoalition()
self:GetPositionable():MessageToCoalition(Message,15,CCCoalition)
end
function COMMANDCENTER:MessageTypeToCoalition(Message,MessageType)
local CCCoalition=self:GetPositionable():GetCoalition()
self:GetPositionable():MessageTypeToCoalition(Message,MessageType,CCCoalition)
end
function COMMANDCENTER:ReportMissionsStatus(ReportGroup)
self:E(ReportGroup)
local Report=REPORT:New()
Report:Add("Status report of all missions.")
for MissionID,Mission in pairs(self.Missions)do
local Mission=Mission
Report:Add(" - "..Mission:ReportStatus())
end
self:MessageToGroup(Report:Text(),ReportGroup)
end
function COMMANDCENTER:ReportMissionsPlayers(ReportGroup)
self:E(ReportGroup)
local Report=REPORT:New()
Report:Add("Players active in all missions.")
for MissionID,Mission in pairs(self.Missions)do
local Mission=Mission
Report:Add(" - "..Mission:ReportPlayers())
end
self:MessageToGroup(Report:Text(),ReportGroup)
end
function COMMANDCENTER:ReportDetails(ReportGroup,Task)
self:E(ReportGroup)
local Report=REPORT:New()
for MissionID,Mission in pairs(self.Missions)do
local Mission=Mission
Report:Add(" - "..Mission:ReportDetails())
end
self:MessageToGroup(Report:Text(),ReportGroup)
end
MISSION={
ClassName="MISSION",
Name="",
MissionStatus="PENDING",
AssignedGroups={},
}
function MISSION:New(CommandCenter,MissionName,MissionPriority,MissionBriefing,MissionCoalition)
local self=BASE:Inherit(self,FSM:New())
self:T({MissionName,MissionPriority,MissionBriefing,MissionCoalition})
self.CommandCenter=CommandCenter
CommandCenter:AddMission(self)
self.Name=MissionName
self.MissionPriority=MissionPriority
self.MissionBriefing=MissionBriefing
self.MissionCoalition=MissionCoalition
self.Tasks={}
self.PlayerNames={}
self:SetStartState("IDLE")
self:AddTransition("IDLE","Start","ENGAGED")
self:AddTransition("ENGAGED","Stop","IDLE")
self:AddTransition("ENGAGED","Complete","COMPLETED")
self:AddTransition("*","Fail","FAILED")
self:AddTransition("*","MissionGoals","*")
CommandCenter:SetMenu()
return self
end
function MISSION:onenterCOMPLETED(From,Event,To)
self:GetCommandCenter():MessageTypeToCoalition(self:GetName().." has been completed! Good job guys!",MESSAGE.Type.Information)
end
function MISSION:GetName()
return string.format('Mission "%s (%s)"',self.Name,self.MissionPriority)
end
function MISSION:JoinUnit(PlayerUnit,PlayerGroup)
self:F({PlayerUnit=PlayerUnit,PlayerGroup=PlayerGroup})
local PlayerUnitAdded=false
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
if Task:JoinUnit(PlayerUnit,PlayerGroup)then
PlayerUnitAdded=true
end
end
return PlayerUnitAdded
end
function MISSION:AbortUnit(PlayerUnit)
self:F({PlayerUnit=PlayerUnit})
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
local PlayerGroup=PlayerUnit:GetGroup()
Task:AbortGroup(PlayerGroup)
end
return self
end
function MISSION:CrashUnit(PlayerUnit)
self:F({PlayerUnit=PlayerUnit})
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
local PlayerGroup=PlayerUnit:GetGroup()
Task:CrashGroup(PlayerGroup)
end
return self
end
function MISSION:AddScoring(Scoring)
self.Scoring=Scoring
return self
end
function MISSION:GetScoring()
return self.Scoring
end
function MISSION:GetGroups()
local SetGroup=SET_GROUP:New()
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
local GroupSet=Task:GetGroups()
GroupSet:ForEachGroup(
function(TaskGroup)
SetGroup:Add(TaskGroup,TaskGroup)
end
)
end
return SetGroup
end
function MISSION:SetMenu(MenuTime)
self:F({self:GetName(),MenuTime})
for _,TaskData in pairs(self:GetTasks())do
local Task=TaskData
Task:SetMenu(MenuTime)
end
end
function MISSION:RemoveMenu(MenuTime)
self:F({self:GetName(),MenuTime})
for _,Task in pairs(self:GetTasks())do
local Task=Task
Task:RemoveMenu(MenuTime)
end
end
do
function MISSION:IsGroupAssigned(MissionGroup)
local MissionGroupName=MissionGroup:GetName()
if self.AssignedGroups[MissionGroupName]==MissionGroup then
self:T({"Mission is assigned to:",MissionGroup:GetName()})
return true
end
self:T({"Mission is not assigned to:",MissionGroup:GetName()})
return false
end
function MISSION:SetGroupAssigned(MissionGroup)
local MissionName=self:GetName()
local MissionGroupName=MissionGroup:GetName()
self.AssignedGroups[MissionGroupName]=MissionGroup
self:E(string.format("Mission %s is assigned to %s",MissionName,MissionGroupName))
return self
end
function MISSION:ClearGroupAssignment(MissionGroup)
local MissionName=self:GetName()
local MissionGroupName=MissionGroup:GetName()
self.AssignedGroups[MissionGroupName]=nil
return self
end
end
function MISSION:GetCommandCenter()
return self.CommandCenter
end
function MISSION:RemoveTaskMenu(Task)
Task:RemoveMenu()
end
function MISSION:GetRootMenu(TaskGroup)
local CommandCenter=self:GetCommandCenter()
local CommandCenterMenu=CommandCenter:GetMenu()
local MissionName=self:GetName()
self.MissionMenu=self.MissionMenu or MENU_COALITION:New(self.MissionCoalition,self:GetName(),CommandCenterMenu)
return self.MissionMenu
end
function MISSION:GetMenu(TaskGroup)
local CommandCenter=self:GetCommandCenter()
local CommandCenterMenu=CommandCenter:GetMenu()
local MissionName=self:GetName()
self.MissionGroupMenu=self.MissionGroupMenu or{}
self.MissionGroupMenu[TaskGroup]=self.MissionGroupMenu[TaskGroup]or{}
local GroupMenu=self.MissionGroupMenu[TaskGroup]
self.MissionMenu=self.MissionMenu or MENU_COALITION:New(self.MissionCoalition,self:GetName(),CommandCenterMenu)
GroupMenu.BriefingMenu=GroupMenu.BriefingMenu or MENU_GROUP_COMMAND:New(TaskGroup,"Mission Briefing",self.MissionMenu,self.MenuReportBriefing,self,TaskGroup)
GroupMenu.TaskReportsMenu=GroupMenu.TaskReportsMenu or MENU_GROUP:New(TaskGroup,"Task Reports",self.MissionMenu)
GroupMenu.ReportTasksMenu=GroupMenu.ReportTasksMenu or MENU_GROUP_COMMAND:New(TaskGroup,"Report Tasks",GroupMenu.TaskReportsMenu,self.MenuReportTasksSummary,self,TaskGroup)
GroupMenu.ReportPlannedTasksMenu=GroupMenu.ReportPlannedTasksMenu or MENU_GROUP_COMMAND:New(TaskGroup,"Report Planned Tasks",GroupMenu.TaskReportsMenu,self.MenuReportTasksPerStatus,self,TaskGroup,"Planned")
GroupMenu.ReportAssignedTasksMenu=GroupMenu.ReportAssignedTasksMenu or MENU_GROUP_COMMAND:New(TaskGroup,"Report Assigned Tasks",GroupMenu.TaskReportsMenu,self.MenuReportTasksPerStatus,self,TaskGroup,"Assigned")
GroupMenu.ReportSuccessTasksMenu=GroupMenu.ReportSuccessTasksMenu or MENU_GROUP_COMMAND:New(TaskGroup,"Report Successful Tasks",GroupMenu.TaskReportsMenu,self.MenuReportTasksPerStatus,self,TaskGroup,"Success")
GroupMenu.ReportFailedTasksMenu=GroupMenu.ReportFailedTasksMenu or MENU_GROUP_COMMAND:New(TaskGroup,"Report Failed Tasks",GroupMenu.TaskReportsMenu,self.MenuReportTasksPerStatus,self,TaskGroup,"Failed")
GroupMenu.ReportHeldTasksMenu=GroupMenu.ReportHeldTasksMenu or MENU_GROUP_COMMAND:New(TaskGroup,"Report Held Tasks",GroupMenu.TaskReportsMenu,self.MenuReportTasksPerStatus,self,TaskGroup,"Hold")
GroupMenu.PlayerReportsMenu=GroupMenu.PlayerReportsMenu or MENU_GROUP:New(TaskGroup,"Statistics Reports",self.MissionMenu)
GroupMenu.ReportMissionHistory=GroupMenu.ReportPlayersHistory or MENU_GROUP_COMMAND:New(TaskGroup,"Report Mission Progress",GroupMenu.PlayerReportsMenu,self.MenuReportPlayersProgress,self,TaskGroup)
GroupMenu.ReportPlayersPerTaskMenu=GroupMenu.ReportPlayersPerTaskMenu or MENU_GROUP_COMMAND:New(TaskGroup,"Report Players per Task",GroupMenu.PlayerReportsMenu,self.MenuReportPlayersPerTask,self,TaskGroup)
return self.MissionMenu
end
function MISSION:GetTask(TaskName)
self:F({TaskName})
return self.Tasks[TaskName]
end
function MISSION:AddTask(Task)
local TaskName=Task:GetTaskName()
self:F(TaskName)
self.Tasks[TaskName]=self.Tasks[TaskName]or{n=0}
self.Tasks[TaskName]=Task
self:GetCommandCenter():SetMenu()
return Task
end
function MISSION:RemoveTask(Task)
local TaskName=Task:GetTaskName()
self:F(TaskName)
self.Tasks[TaskName]=self.Tasks[TaskName]or{n=0}
self.Tasks[TaskName]=nil
Task=nil
collectgarbage()
self:GetCommandCenter():SetMenu()
return nil
end
function MISSION:GetNextTaskID(Task)
local TaskName=Task:GetTaskName()
self:F(TaskName)
self.Tasks[TaskName]=self.Tasks[TaskName]or{n=0}
self.Tasks[TaskName].n=self.Tasks[TaskName].n+1
return self.Tasks[TaskName].n
end
function MISSION:IsCOMPLETED()
return self:Is("COMPLETED")
end
function MISSION:IsIDLE()
return self:Is("IDLE")
end
function MISSION:IsENGAGED()
return self:Is("ENGAGED")
end
function MISSION:IsFAILED()
return self:Is("FAILED")
end
function MISSION:IsHOLD()
return self:Is("HOLD")
end
function MISSION:HasGroup(TaskGroup)
local Has=false
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
if Task:HasGroup(TaskGroup)then
Has=true
break
end
end
return Has
end
function MISSION:GetTasksRemaining()
local TasksRemaining=0
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
if Task:IsStateSuccess()or Task:IsStateFailed()then
else
TasksRemaining=TasksRemaining+1
end
end
return TasksRemaining
end
function MISSION:GetTaskTypes()
local TaskTypeList={}
local TasksRemaining=0
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
local TaskType=Task:GetType()
TaskTypeList[TaskType]=TaskType
end
return TaskTypeList
end
function MISSION:AddPlayerName(PlayerName)
self.PlayerNames=self.PlayerNames or{}
self.PlayerNames[PlayerName]=PlayerName
return self
end
function MISSION:GetPlayerNames()
return self.PlayerNames
end
function MISSION:ReportBriefing()
local Report=REPORT:New()
local Name=self:GetName()
local Status="<"..self:GetState()..">"
Report:Add(string.format('%s - %s - Mission Briefing Report',Name,Status))
Report:Add(self.MissionBriefing)
return Report:Text()
end
function MISSION:ReportStatus()
local Report=REPORT:New()
local Name=self:GetName()
local Status="<"..self:GetState()..">"
Report:Add(string.format('%s - Status "%s"',Name,Status))
local TaskTypes=self:GetTaskTypes()
Report:Add(string.format(" - Task Types: %s",table.concat(TaskTypes,", ")))
local TaskStatusList={"Planned","Assigned","Success","Hold","Cancelled","Aborted","Failed"}
for TaskStatusID,TaskStatus in pairs(TaskStatusList)do
local TaskCount=0
local TaskPlayerCount=0
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
if Task:Is(TaskStatus)then
TaskCount=TaskCount+1
TaskPlayerCount=TaskPlayerCount+Task:GetPlayerCount()
end
end
if TaskCount>0 then
Report:Add(string.format(" - %02d %s Tasks (%dp)",TaskCount,TaskStatus,TaskPlayerCount))
end
end
return Report:Text()
end
function MISSION:ReportPlayersPerTask(ReportGroup)
local Report=REPORT:New()
local Name=self:GetName()
local Status="<"..self:GetState()..">"
Report:Add(string.format('%s - %s - Players per Task Report',Name,Status))
local PlayerList={}
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
local PlayerNames=Task:GetPlayerNames()
for PlayerName,PlayerGroup in pairs(PlayerNames)do
PlayerList[PlayerName]=Task:GetName()
end
end
for PlayerName,TaskName in pairs(PlayerList)do
Report:Add(string.format(' - Player (%s): Task "%s"',PlayerName,TaskName))
end
return Report:Text()
end
function MISSION:ReportPlayersProgress(ReportGroup)
local Report=REPORT:New()
local Name=self:GetName()
local Status="<"..self:GetState()..">"
Report:Add(string.format('%s - %s - Players per Task Progress Report',Name,Status))
local PlayerList={}
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
local TaskGoalTotal=Task:GetGoalTotal()or 0
local TaskName=Task:GetName()
PlayerList[TaskName]=PlayerList[TaskName]or{}
if TaskGoalTotal~=0 then
local PlayerNames=self:GetPlayerNames()
for PlayerName,PlayerData in pairs(PlayerNames)do
PlayerList[TaskName][PlayerName]=string.format('Player (%s): Task "%s": %d%%',PlayerName,TaskName,Task:GetPlayerProgress(PlayerName)*100/TaskGoalTotal)
end
else
PlayerList[TaskName]["_"]=string.format('Player (---): Task "%s": %d%%',TaskName,0)
end
end
for TaskName,TaskData in pairs(PlayerList)do
for PlayerName,TaskText in pairs(TaskData)do
Report:Add(string.format(' - %s',TaskText))
end
end
return Report:Text()
end
function MISSION:ReportSummary(ReportGroup)
local Report=REPORT:New()
local Name=self:GetName()
local Status="<"..self:GetState()..">"
Report:Add(string.format('%s - %s - Task Overview Report',Name,Status))
for TaskID,Task in UTILS.spairs(self:GetTasks(),function(t,a,b)return t[a]:ReportOrder(ReportGroup)<t[b]:ReportOrder(ReportGroup)end)do
local Task=Task
Report:Add("- "..Task:ReportSummary(ReportGroup))
end
return Report:Text()
end
function MISSION:ReportOverview(ReportGroup,TaskStatus)
self:F({TaskStatus=TaskStatus})
local Report=REPORT:New()
local Name=self:GetName()
local Status="<"..self:GetState()..">"
Report:Add(string.format('%s - %s - %s Tasks Report',Name,Status,TaskStatus))
local Tasks=0
for TaskID,Task in UTILS.spairs(self:GetTasks(),function(t,a,b)return t[a]:ReportOrder(ReportGroup)<t[b]:ReportOrder(ReportGroup)end)do
local Task=Task
if Task:Is(TaskStatus)then
Report:Add(string.rep("-",140))
Report:Add(" - "..Task:ReportOverview(ReportGroup))
end
Tasks=Tasks+1
if Tasks>=8 then
break
end
end
return Report:Text()
end
function MISSION:ReportDetails(ReportGroup)
local Report=REPORT:New()
local Name=self:GetName()
local Status="<"..self:GetState()..">"
Report:Add(string.format('%s - %s - Task Detailed Report',Name,Status))
local TasksRemaining=0
for TaskID,Task in pairs(self:GetTasks())do
local Task=Task
Report:Add(Task:ReportDetails(ReportGroup))
end
return Report:Text()
end
function MISSION:GetTasks()
return self.Tasks
end
function MISSION:MenuReportBriefing(ReportGroup)
local Report=self:ReportBriefing()
self:GetCommandCenter():MessageTypeToGroup(Report,ReportGroup,MESSAGE.Type.Briefing)
end
function MISSION:MenuReportTasksSummary(ReportGroup)
local Report=self:ReportSummary(ReportGroup)
self:GetCommandCenter():MessageTypeToGroup(Report,ReportGroup,MESSAGE.Type.Overview)
end
function MISSION:MenuReportTasksPerStatus(ReportGroup,TaskStatus)
local Report=self:ReportOverview(ReportGroup,TaskStatus)
self:GetCommandCenter():MessageTypeToGroup(Report,ReportGroup,MESSAGE.Type.Overview)
end
function MISSION:MenuReportPlayersPerTask(ReportGroup)
local Report=self:ReportPlayersPerTask()
self:GetCommandCenter():MessageTypeToGroup(Report,ReportGroup,MESSAGE.Type.Overview)
end
function MISSION:MenuReportPlayersProgress(ReportGroup)
local Report=self:ReportPlayersProgress()
self:GetCommandCenter():MessageTypeToGroup(Report,ReportGroup,MESSAGE.Type.Overview)
end
TASK={
ClassName="TASK",
TaskScheduler=nil,
ProcessClasses={},
Processes={},
Players=nil,
Scores={},
Menu={},
SetGroup=nil,
FsmTemplate=nil,
Mission=nil,
CommandCenter=nil,
TimeOut=0,
AssignedGroups={},
}
function TASK:New(Mission,SetGroupAssign,TaskName,TaskType,TaskBriefing)
local self=BASE:Inherit(self,FSM_TASK:New())
self:SetStartState("Planned")
self:AddTransition("Planned","Assign","Assigned")
self:AddTransition("Assigned","AssignUnit","Assigned")
self:AddTransition("Assigned","Success","Success")
self:AddTransition("Assigned","Hold","Hold")
self:AddTransition("Assigned","Fail","Failed")
self:AddTransition("Assigned","Abort","Aborted")
self:AddTransition("Assigned","Cancel","Cancelled")
self:AddTransition("Assigned","Goal","*")
self:AddTransition("*","PlayerCrashed","*")
self:AddTransition("*","PlayerAborted","*")
self:AddTransition("*","PlayerDead","*")
self:AddTransition({"Failed","Aborted","Cancelled"},"Replan","Planned")
self:AddTransition("*","TimeOut","Cancelled")
self:E("New TASK "..TaskName)
self.Processes={}
self.Fsm={}
self.Mission=Mission
self.CommandCenter=Mission:GetCommandCenter()
self.SetGroup=SetGroupAssign
self:SetType(TaskType)
self:SetName(TaskName)
self:SetID(Mission:GetNextTaskID(self))
self:SetBriefing(TaskBriefing)
self.FsmTemplate=self.FsmTemplate or FSM_PROCESS:New()
self.TaskInfo={}
self.TaskProgress={}
return self
end
function TASK:GetUnitProcess(TaskUnit)
if TaskUnit then
return self:GetStateMachine(TaskUnit)
else
return self.FsmTemplate
end
end
function TASK:SetUnitProcess(FsmTemplate)
self.FsmTemplate=FsmTemplate
end
function TASK:JoinUnit(PlayerUnit,PlayerGroup)
self:F({PlayerUnit=PlayerUnit,PlayerGroup=PlayerGroup})
local PlayerUnitAdded=false
local PlayerGroups=self:GetGroups()
if PlayerGroups:IsIncludeObject(PlayerGroup)then
if self:IsStatePlanned()or self:IsStateReplanned()then
end
if self:IsStateAssigned()then
local IsGroupAssigned=self:IsGroupAssigned(PlayerGroup)
self:E({IsGroupAssigned=IsGroupAssigned})
if IsGroupAssigned then
self:AssignToUnit(PlayerUnit)
self:MessageToGroups(PlayerUnit:GetPlayerName().." joined Task "..self:GetName())
end
end
end
return PlayerUnitAdded
end
function TASK:AbortGroup(PlayerGroup)
self:F({PlayerGroup=PlayerGroup})
local PlayerGroups=self:GetGroups()
if PlayerGroups:IsIncludeObject(PlayerGroup)then
if self:IsStateAssigned()then
local IsGroupAssigned=self:IsGroupAssigned(PlayerGroup)
self:E({IsGroupAssigned=IsGroupAssigned})
if IsGroupAssigned then
local PlayerName=PlayerGroup:GetUnit(1):GetPlayerName()
self:UnAssignFromGroup(PlayerGroup)
PlayerGroups:Flush()
local IsRemaining=false
for GroupName,AssignedGroup in pairs(PlayerGroups:GetSet()or{})do
if self:IsGroupAssigned(AssignedGroup)==true then
IsRemaining=true
self:F({Task=self:GetName(),IsRemaining=IsRemaining})
break
end
end
self:F({Task=self:GetName(),IsRemaining=IsRemaining})
if IsRemaining==false then
self:Abort()
end
self:PlayerAborted(PlayerGroup:GetUnit(1))
end
end
end
return self
end
function TASK:CrashGroup(PlayerGroup)
self:F({PlayerGroup=PlayerGroup})
local PlayerGroups=self:GetGroups()
if PlayerGroups:IsIncludeObject(PlayerGroup)then
if self:IsStateAssigned()then
local IsGroupAssigned=self:IsGroupAssigned(PlayerGroup)
self:E({IsGroupAssigned=IsGroupAssigned})
if IsGroupAssigned then
local PlayerName=PlayerGroup:GetUnit(1):GetPlayerName()
self:MessageToGroups(PlayerName.." crashed! ")
self:UnAssignFromGroup(PlayerGroup)
PlayerGroups:Flush()
local IsRemaining=false
for GroupName,AssignedGroup in pairs(PlayerGroups:GetSet()or{})do
if self:IsGroupAssigned(AssignedGroup)==true then
IsRemaining=true
self:F({Task=self:GetName(),IsRemaining=IsRemaining})
break
end
end
self:F({Task=self:GetName(),IsRemaining=IsRemaining})
if IsRemaining==false then
self:Abort()
end
self:PlayerCrashed(PlayerGroup:GetUnit(1))
end
end
end
return self
end
function TASK:GetMission()
return self.Mission
end
function TASK:GetGroups()
return self.SetGroup
end
do
function TASK:IsGroupAssigned(TaskGroup)
local TaskGroupName=TaskGroup:GetName()
if self.AssignedGroups[TaskGroupName]then
self:T({"Task is assigned to:",TaskGroup:GetName()})
return true
end
self:T({"Task is not assigned to:",TaskGroup:GetName()})
return false
end
function TASK:SetGroupAssigned(TaskGroup)
local TaskName=self:GetName()
local TaskGroupName=TaskGroup:GetName()
self.AssignedGroups[TaskGroupName]=TaskGroup
self:E(string.format("Task %s is assigned to %s",TaskName,TaskGroupName))
self:GetMission():SetGroupAssigned(TaskGroup)
local SetAssignedGroups=self:GetGroups()
return self
end
function TASK:ClearGroupAssignment(TaskGroup)
local TaskName=self:GetName()
local TaskGroupName=TaskGroup:GetName()
self.AssignedGroups[TaskGroupName]=nil
self:GetMission():ClearGroupAssignment(TaskGroup)
local SetAssignedGroups=self:GetGroups()
SetAssignedGroups:ForEachGroup(
function(AssignedGroup)
if self:IsGroupAssigned(AssignedGroup)then
else
end
end
)
return self
end
end
do
function TASK:AssignToGroup(TaskGroup)
self:F(TaskGroup:GetName())
local TaskGroupName=TaskGroup:GetName()
local Mission=self:GetMission()
local CommandCenter=Mission:GetCommandCenter()
self:SetGroupAssigned(TaskGroup)
local TaskUnits=TaskGroup:GetUnits()
for UnitID,UnitData in pairs(TaskUnits)do
local TaskUnit=UnitData
local PlayerName=TaskUnit:GetPlayerName()
self:E(PlayerName)
if PlayerName~=nil and PlayerName~=""then
self:AssignToUnit(TaskUnit)
CommandCenter:MessageToGroup(
string.format('Task "%s": Briefing for player (%s):\n%s',
self:GetName(),
PlayerName,
self:GetBriefing()
),TaskGroup
)
end
end
CommandCenter:SetMenu()
return self
end
function TASK:UnAssignFromGroup(TaskGroup)
self:F2({TaskGroup=TaskGroup:GetName()})
self:ClearGroupAssignment(TaskGroup)
local TaskUnits=TaskGroup:GetUnits()
for UnitID,UnitData in pairs(TaskUnits)do
local TaskUnit=UnitData
local PlayerName=TaskUnit:GetPlayerName()
if PlayerName~=nil and PlayerName~=""then
self:UnAssignFromUnit(TaskUnit)
end
end
local Mission=self:GetMission()
local CommandCenter=Mission:GetCommandCenter()
CommandCenter:SetMenu()
end
end
function TASK:HasGroup(FindGroup)
local SetAttackGroup=self:GetGroups()
return SetAttackGroup:FindGroup(FindGroup)
end
function TASK:AssignToUnit(TaskUnit)
self:F(TaskUnit:GetName())
local FsmTemplate=self:GetUnitProcess()
local FsmUnit=self:SetStateMachine(TaskUnit,FsmTemplate:Copy(TaskUnit,self))
FsmUnit:SetStartState("Planned")
FsmUnit:Accept()
return self
end
function TASK:UnAssignFromUnit(TaskUnit)
self:F(TaskUnit:GetName())
self:RemoveStateMachine(TaskUnit)
return self
end
function TASK:SetTimeOut(Timer)
self:F(Timer)
self.TimeOut=Timer
self:__TimeOut(self.TimeOut)
return self
end
function TASK:MessageToGroups(Message)
self:F({Message=Message})
local Mission=self:GetMission()
local CC=Mission:GetCommandCenter()
for TaskGroupName,TaskGroup in pairs(self.SetGroup:GetSet())do
local TaskGroup=TaskGroup
CC:MessageToGroup(Message,TaskGroup,TaskGroup:GetName())
end
end
function TASK:SendBriefingToAssignedGroups()
self:F2()
for TaskGroupName,TaskGroup in pairs(self.SetGroup:GetSet())do
if self:IsGroupAssigned(TaskGroup)then
TaskGroup:Message(self.TaskBriefing,60)
end
end
end
function TASK:UnAssignFromGroups()
self:F2()
for TaskGroupName,TaskGroup in pairs(self.SetGroup:GetSet())do
if self:IsGroupAssigned(TaskGroup)then
self:UnAssignFromGroup(TaskGroup)
end
end
end
function TASK:HasAliveUnits()
self:F()
for TaskGroupID,TaskGroup in pairs(self.SetGroup:GetSet())do
if self:IsStateAssigned()then
if self:IsGroupAssigned(TaskGroup)then
for TaskUnitID,TaskUnit in pairs(TaskGroup:GetUnits())do
if TaskUnit:IsAlive()then
self:T({HasAliveUnits=true})
return true
end
end
end
end
end
self:T({HasAliveUnits=false})
return false
end
function TASK:SetMenu(MenuTime)
self:F({self:GetName(),MenuTime})
for TaskGroupID,TaskGroupData in pairs(self.SetGroup:GetSet())do
local TaskGroup=TaskGroupData
if TaskGroup:IsAlive()and TaskGroup:GetPlayerNames()then
local Mission=self:GetMission()
local MissionMenu=Mission:GetMenu(TaskGroup)
if MissionMenu then
self:SetMenuForGroup(TaskGroup,MenuTime)
end
end
end
end
function TASK:SetMenuForGroup(TaskGroup,MenuTime)
if self:IsStatePlanned()or self:IsStateAssigned()then
self:SetPlannedMenuForGroup(TaskGroup,MenuTime)
if self:IsGroupAssigned(TaskGroup)then
self:SetAssignedMenuForGroup(TaskGroup,MenuTime)
end
end
end
function TASK:SetPlannedMenuForGroup(TaskGroup,MenuTime)
self:F(TaskGroup:GetName())
local Mission=self:GetMission()
local MissionName=Mission:GetName()
local CommandCenter=Mission:GetCommandCenter()
local CommandCenterMenu=CommandCenter:GetMenu()
local TaskType=self:GetType()
local TaskPlayerCount=self:GetPlayerCount()
local TaskPlayerString=string.format(" (%dp)",TaskPlayerCount)
local TaskText=string.format("%s%s",self:GetName(),TaskPlayerString)
local TaskName=string.format("%s",self:GetName())
local MissionMenu=Mission:GetMenu(TaskGroup)
self.MenuPlanned=self.MenuPlanned or{}
self.MenuPlanned[TaskGroup]=MENU_GROUP:New(TaskGroup,"Join Planned Task",MissionMenu,Mission.MenuReportTasksPerStatus,Mission,TaskGroup,"Planned"):SetTime(MenuTime):SetTag("Tasking")
local TaskTypeMenu=MENU_GROUP:New(TaskGroup,TaskType,self.MenuPlanned[TaskGroup]):SetTime(MenuTime):SetTag("Tasking"):SetRemoveParent(true)
local TaskTypeMenu=MENU_GROUP:New(TaskGroup,TaskText,TaskTypeMenu):SetTime(MenuTime):SetTag("Tasking"):SetRemoveParent(true)
local ReportTaskMenu=MENU_GROUP_COMMAND:New(TaskGroup,string.format("Report Task Status"),TaskTypeMenu,self.MenuTaskStatus,self,TaskGroup):SetTime(MenuTime):SetTag("Tasking"):SetRemoveParent(true)
if not Mission:IsGroupAssigned(TaskGroup)then
self:F({"Replacing Join Task menu"})
local JoinTaskMenu=MENU_GROUP_COMMAND:New(TaskGroup,string.format("Join Task"),TaskTypeMenu,self.MenuAssignToGroup,self,TaskGroup):SetTime(MenuTime):SetTag("Tasking"):SetRemoveParent(true)
local MarkTaskMenu=MENU_GROUP_COMMAND:New(TaskGroup,string.format("Mark Task on Map"),TaskTypeMenu,self.MenuMarkToGroup,self,TaskGroup):SetTime(MenuTime):SetTag("Tasking"):SetRemoveParent(true)
end
return self
end
function TASK:SetAssignedMenuForGroup(TaskGroup,MenuTime)
self:F({TaskGroup:GetName(),MenuTime})
local Mission=self:GetMission()
local MissionName=Mission:GetName()
local CommandCenter=Mission:GetCommandCenter()
local CommandCenterMenu=CommandCenter:GetMenu()
local TaskType=self:GetType()
local TaskPlayerCount=self:GetPlayerCount()
local TaskPlayerString=string.format(" (%dp)",TaskPlayerCount)
local TaskText=string.format("%s%s",self:GetName(),TaskPlayerString)
local TaskName=string.format("%s",self:GetName())
local MissionMenu=Mission:GetMenu(TaskGroup)
self.MenuAssigned=self.MenuAssigned or{}
self.MenuAssigned[TaskGroup]=MENU_GROUP:New(TaskGroup,string.format("Assigned Task %s",TaskName),MissionMenu):SetTime(MenuTime):SetTag("Tasking")
local TaskTypeMenu=MENU_GROUP_COMMAND:New(TaskGroup,string.format("Report Task Status"),self.MenuAssigned[TaskGroup],self.MenuTaskStatus,self,TaskGroup):SetTime(MenuTime):SetTag("Tasking"):SetRemoveParent(true)
local TaskMenu=MENU_GROUP_COMMAND:New(TaskGroup,string.format("Abort Group from Task"),self.MenuAssigned[TaskGroup],self.MenuTaskAbort,self,TaskGroup):SetTime(MenuTime):SetTag("Tasking"):SetRemoveParent(true)
return self
end
function TASK:RemoveMenu(MenuTime)
self:F({self:GetName(),MenuTime})
for TaskGroupID,TaskGroup in pairs(self.SetGroup:GetSet())do
local TaskGroup=TaskGroup
self:RefreshMenus(TaskGroup,MenuTime)
end
end
function TASK:RefreshMenus(TaskGroup,MenuTime)
self:F({TaskGroup:GetName(),MenuTime})
local Mission=self:GetMission()
local MissionName=Mission:GetName()
local CommandCenter=Mission:GetCommandCenter()
local CommandCenterMenu=CommandCenter:GetMenu()
local MissionMenu=Mission:GetMenu(TaskGroup)
local TaskName=self:GetName()
self.MenuPlanned=self.MenuPlanned or{}
local PlannedMenu=self.MenuPlanned[TaskGroup]
self.MenuAssigned=self.MenuAssigned or{}
local AssignedMenu=self.MenuAssigned[TaskGroup]
if PlannedMenu then
PlannedMenu:Remove(MenuTime,"Tasking")
end
if AssignedMenu then
AssignedMenu:Remove(MenuTime,"Tasking")
end
end
function TASK:RemoveAssignedMenuForGroup(TaskGroup)
self:F()
local Mission=self:GetMission()
local MissionName=Mission:GetName()
local MissionMenu=Mission:GetMenu(TaskGroup)
if MissionMenu then
MissionMenu:RemoveSubMenus()
end
end
function TASK:MenuAssignToGroup(TaskGroup)
self:E("Join Task menu selected")
self:AssignToGroup(TaskGroup)
end
function TASK:MenuMarkToGroup(TaskGroup)
self:E("Mark Task menu selected")
self:UpdateTaskInfo()
local Report=REPORT:New():SetIndent(0)
local Name=self:GetName()
Report:Add(Name..": "..self:GetTaskBriefing())
for TaskInfoID,TaskInfo in pairs(self.TaskInfo,function(t,a,b)return t[a].TaskInfoOrder<t[b].TaskInfoOrder end)do
local TaskInfoIDText=""
if type(TaskInfo.TaskInfoText)=="string"then
if TaskInfoID=="Targets"then
else
Report:Add(TaskInfoIDText..TaskInfo.TaskInfoText)
end
elseif type(TaskInfo)=="table"then
if TaskInfoID=="Coordinates"then
else
end
end
end
local Coordinate=self:GetInfo("Coordinates")
local Velocity=self.TargetSetUnit:GetVelocity()
local Heading=self.TargetSetUnit:GetHeading()
Coordinate:SetHeading(Heading)
Coordinate:SetVelocity(Velocity)
Report:Add("Targets are"..Coordinate:GetMovingText()..".")
local MarkText=Report:Text(", ")
self:F({Coordinate=Coordinate,MarkText=MarkText})
Coordinate:MarkToGroup(MarkText,TaskGroup)
end
function TASK:MenuTaskStatus(TaskGroup)
local ReportText=self:ReportDetails(TaskGroup)
self:T(ReportText)
self:GetMission():GetCommandCenter():MessageTypeToGroup(ReportText,TaskGroup,MESSAGE.Type.Detailed)
end
function TASK:MenuTaskAbort(TaskGroup)
self:AbortGroup(TaskGroup)
end
function TASK:GetTaskName()
return self.TaskName
end
function TASK:GetTaskBriefing()
return self.TaskBriefing
end
function TASK:GetProcessTemplate(ProcessName)
local ProcessTemplate=self.ProcessClasses[ProcessName]
return ProcessTemplate
end
function TASK:FailProcesses(TaskUnitName)
for ProcessID,ProcessData in pairs(self.Processes[TaskUnitName])do
local Process=ProcessData
Process.Fsm:Fail()
end
end
function TASK:SetStateMachine(TaskUnit,Fsm)
self:F2({TaskUnit,self.Fsm[TaskUnit]~=nil,Fsm:GetClassNameAndID()})
self.Fsm[TaskUnit]=Fsm
return Fsm
end
function TASK:GetStateMachine(TaskUnit)
self:F2({TaskUnit,self.Fsm[TaskUnit]~=nil})
return self.Fsm[TaskUnit]
end
function TASK:RemoveStateMachine(TaskUnit)
self:F({TaskUnit=TaskUnit:GetName(),HasFsm=(self.Fsm[TaskUnit]~=nil)})
if self.Fsm[TaskUnit]then
self.Fsm[TaskUnit]:Remove()
self.Fsm[TaskUnit]=nil
end
collectgarbage()
self:E("Garbage Collected, Processes should be finalized now ...")
end
function TASK:HasStateMachine(TaskUnit)
self:F({TaskUnit,self.Fsm[TaskUnit]~=nil})
return(self.Fsm[TaskUnit]~=nil)
end
function TASK:GetScoring()
return self.Mission:GetScoring()
end
function TASK:GetTaskIndex()
local TaskType=self:GetType()
local TaskName=self:GetName()
return TaskType.."."..TaskName
end
function TASK:SetName(TaskName)
self.TaskName=TaskName
end
function TASK:GetName()
return self.TaskName
end
function TASK:SetType(TaskType)
self.TaskType=TaskType
end
function TASK:SetInfo(TaskInfo,TaskInfoText,TaskInfoOrder)
self.TaskInfo=self.TaskInfo or{}
self.TaskInfo[TaskInfo]=self.TaskInfo[TaskInfo]or{}
self.TaskInfo[TaskInfo].TaskInfoText=TaskInfoText
self.TaskInfo[TaskInfo].TaskInfoOrder=TaskInfoOrder
end
function TASK:GetInfo(TaskInfo)
self.TaskInfo=self.TaskInfo or{}
self.TaskInfo[TaskInfo]=self.TaskInfo[TaskInfo]or{}
return self.TaskInfo[TaskInfo].TaskInfoText
end
function TASK:GetType()
return self.TaskType
end
function TASK:SetID(TaskID)
self.TaskID=TaskID
end
function TASK:GetID()
return self.TaskID
end
function TASK:StateSuccess()
self:SetState(self,"State","Success")
return self
end
function TASK:IsStateSuccess()
return self:Is("Success")
end
function TASK:StateFailed()
self:SetState(self,"State","Failed")
return self
end
function TASK:IsStateFailed()
return self:Is("Failed")
end
function TASK:StatePlanned()
self:SetState(self,"State","Planned")
return self
end
function TASK:IsStatePlanned()
return self:Is("Planned")
end
function TASK:StateAborted()
self:SetState(self,"State","Aborted")
return self
end
function TASK:IsStateAborted()
return self:Is("Aborted")
end
function TASK:StateCancelled()
self:SetState(self,"State","Cancelled")
return self
end
function TASK:IsStateCancelled()
return self:Is("Cancelled")
end
function TASK:StateAssigned()
self:SetState(self,"State","Assigned")
return self
end
function TASK:IsStateAssigned()
return self:Is("Assigned")
end
function TASK:StateHold()
self:SetState(self,"State","Hold")
return self
end
function TASK:IsStateHold()
return self:Is("Hold")
end
function TASK:StateReplanned()
self:SetState(self,"State","Replanned")
return self
end
function TASK:IsStateReplanned()
return self:Is("Replanned")
end
function TASK:GetStateString()
return self:GetState(self,"State")
end
function TASK:SetBriefing(TaskBriefing)
self:E(TaskBriefing)
self.TaskBriefing=TaskBriefing
return self
end
function TASK:GetBriefing()
return self.TaskBriefing
end
function TASK:onenterAssigned(From,Event,To,PlayerUnit,PlayerName)
if From~="Assigned"then
self:E({From,Event,To,PlayerUnit:GetName(),PlayerName})
self:GetMission():GetCommandCenter():MessageToCoalition("Task "..self:GetName().." is assigned.")
self:SetGoalTotal()
if self.Dispatcher then
self:E("Firing Assign event ")
self.Dispatcher:Assign(self,PlayerUnit,PlayerName)
end
self:GetMission():__Start(1)
self:__Goal(-10)
self:SetMenu()
end
end
function TASK:onenterSuccess(From,Event,To)
self:E("Task Success")
self:GetMission():GetCommandCenter():MessageToCoalition("Task "..self:GetName().." is successful! Good job!")
self:UnAssignFromGroups()
self:GetMission():__MissionGoals(1)
end
function TASK:onenterAborted(From,Event,To)
self:E("Task Aborted")
if From~="Aborted"then
self:GetMission():GetCommandCenter():MessageToCoalition("Task "..self:GetName().." has been aborted! Task may be replanned.")
self:__Replan(5)
self:SetMenu()
end
end
function TASK:onenterCancelled(From,Event,To)
self:E("Task Cancelled")
if From~="Cancelled"then
self:GetMission():GetCommandCenter():MessageToCoalition("Task "..self:GetName().." has been cancelled! The tactical situation has changed.")
self:UnAssignFromGroups()
self:SetMenu()
end
end
function TASK:onafterReplan(From,Event,To)
self:E("Task Replanned")
self:GetMission():GetCommandCenter():MessageToCoalition("Replanning Task "..self:GetName()..".")
self:SetMenu()
end
function TASK:onenterFailed(From,Event,To)
self:E("Task Failed")
self:GetMission():GetCommandCenter():MessageToCoalition("Task "..self:GetName().." has failed!")
self:UnAssignFromGroups()
end
function TASK:onstatechange(From,Event,To)
if self:IsTrace()then
end
if self.Scores[To]then
local Scoring=self:GetScoring()
if Scoring then
self:E({self.Scores[To].ScoreText,self.Scores[To].Score})
Scoring:_AddMissionScore(self.Mission,self.Scores[To].ScoreText,self.Scores[To].Score)
end
end
end
function TASK:onenterPlanned(From,Event,To)
if not self.TimeOut==0 then
self.__TimeOut(self.TimeOut)
end
end
function TASK:onbeforeTimeOut(From,Event,To)
if From=="Planned"then
self:RemoveMenu()
return true
end
return false
end
do
function TASK:SetDispatcher(Dispatcher)
self.Dispatcher=Dispatcher
end
function TASK:SetDetection(Detection,DetectedItemIndex)
self:E({DetectedItemIndex,Detection})
self.Detection=Detection
self.DetectedItemIndex=DetectedItemIndex
end
end
do
function TASK:ReportSummary(ReportGroup)
local Report=REPORT:New()
Report:Add(self:GetName())
Report:Add("State: <"..self:GetState()..">")
if self.TaskInfo["Coordinates"]then
local TaskInfoIDText=string.format("%s: ","Coordinate")
local TaskCoord=self.TaskInfo["Coordinates"].TaskInfoText
Report:Add(TaskInfoIDText..TaskCoord:ToString(ReportGroup,nil,self))
end
return Report:Text(', ')
end
function TASK:ReportOverview(ReportGroup)
self:UpdateTaskInfo()
local TaskName=self:GetName()
local Report=REPORT:New()
local Line=0
local LineReport=REPORT:New()
for TaskInfoID,TaskInfo in UTILS.spairs(self.TaskInfo,function(t,a,b)return t[a].TaskInfoOrder<t[b].TaskInfoOrder end)do
self:F({TaskInfo=TaskInfo})
if Line<math.floor(TaskInfo.TaskInfoOrder/10)then
if Line~=0 then
Report:AddIndent(LineReport:Text(", "))
else
Report:Add(TaskName..", "..LineReport:Text(", "))
end
LineReport=REPORT:New()
Line=math.floor(TaskInfo.TaskInfoOrder/10)
end
local TaskInfoIDText=string.format("%s: ",TaskInfoID)
if type(TaskInfo.TaskInfoText)=="string"then
LineReport:Add(TaskInfoIDText..TaskInfo.TaskInfoText)
elseif type(TaskInfo)=="table"then
if TaskInfoID=="Coordinates"then
local ToCoordinate=TaskInfo.TaskInfoText
LineReport:Add(TaskInfoIDText..ToCoordinate:ToString(ReportGroup,nil,self))
else
end
end
end
Report:AddIndent(LineReport:Text(", "))
return Report:Text()
end
function TASK:GetPlayerCount()
local PlayerCount=0
for TaskGroupID,PlayerGroup in pairs(self:GetGroups():GetSet())do
local PlayerGroup=PlayerGroup
if self:IsGroupAssigned(PlayerGroup)then
local PlayerNames=PlayerGroup:GetPlayerNames()
PlayerCount=PlayerCount+#PlayerNames
end
end
return PlayerCount
end
function TASK:GetPlayerNames()
local PlayerNameMap={}
for TaskGroupID,PlayerGroup in pairs(self:GetGroups():GetSet())do
local PlayerGroup=PlayerGroup
if self:IsGroupAssigned(PlayerGroup)then
local PlayerNames=PlayerGroup:GetPlayerNames()
for PlayerNameID,PlayerName in pairs(PlayerNames)do
PlayerNameMap[PlayerName]=PlayerGroup
end
end
end
return PlayerNameMap
end
function TASK:ReportDetails(ReportGroup)
self:UpdateTaskInfo()
local Report=REPORT:New():SetIndent(3)
local Name=self:GetName()
local Status="<"..self:GetState()..">"
Report:Add("Task: "..Name.." - "..Status.." - Detailed Report")
local PlayerNames=self:GetPlayerNames()
local PlayerReport=REPORT:New()
for PlayerName,PlayerGroup in pairs(PlayerNames)do
PlayerReport:Add("Group "..PlayerGroup:GetCallsign()..": "..PlayerName)
end
local Players=PlayerReport:Text()
if Players~=""then
Report:Add(" - Players assigned:")
Report:AddIndent(Players)
end
for TaskInfoID,TaskInfo in pairs(self.TaskInfo,function(t,a,b)return t[a].TaskInfoOrder<t[b].TaskInfoOrder end)do
local TaskInfoIDText=string.format(" - %s: ",TaskInfoID)
if type(TaskInfo.TaskInfoText)=="string"then
Report:Add(TaskInfoIDText..TaskInfo.TaskInfoText)
elseif type(TaskInfo)=="table"then
if TaskInfoID=="Coordinates"then
local FromCoordinate=ReportGroup:GetUnit(1):GetCoordinate()
local ToCoordinate=TaskInfo.TaskInfoText
Report:Add(TaskInfoIDText..ToCoordinate:ToString(ReportGroup:GetUnit(1),nil,self))
else
end
end
end
local Coordinate=self:GetInfo("Coordinates")
local Velocity=self.TargetSetUnit:GetVelocity()
local Heading=self.TargetSetUnit:GetHeading()
Coordinate:SetHeading(Heading)
Coordinate:SetVelocity(Velocity)
Report:Add("Targets are"..Coordinate:GetMovingText()..".")
return Report:Text()
end
end
do
function TASK:AddProgress(PlayerName,ProgressText,ProgressTime,ProgressPoints)
self.TaskProgress=self.TaskProgress or{}
self.TaskProgress[ProgressTime]=self.TaskProgress[ProgressTime]or{}
self.TaskProgress[ProgressTime].PlayerName=PlayerName
self.TaskProgress[ProgressTime].ProgressText=ProgressText
self.TaskProgress[ProgressTime].ProgressPoints=ProgressPoints
self:GetMission():AddPlayerName(PlayerName)
return self
end
function TASK:GetPlayerProgress(PlayerName)
local ProgressPlayer=0
for ProgressTime,ProgressData in pairs(self.TaskProgress)do
if PlayerName==ProgressData.PlayerName then
ProgressPlayer=ProgressPlayer+ProgressData.ProgressPoints
end
end
return ProgressPlayer
end
function TASK:SetScoreOnProgress(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScoreProcess("Engaging","Account","AccountPlayer","Player "..PlayerName.." has achieved progress.",Score)
return self
end
function TASK:SetScoreOnSuccess(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Success","The task is a success!",Score)
return self
end
function TASK:SetScoreOnFail(PlayerName,Penalty,TaskUnit)
self:F({PlayerName,Penalty,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Failed","The task is a failure!",Penalty)
return self
end
end
do
DETECTION_MANAGER={
ClassName="DETECTION_MANAGER",
SetGroup=nil,
Detection=nil,
}
function DETECTION_MANAGER:New(SetGroup,Detection)
local self=BASE:Inherit(self,FSM:New())
self.SetGroup=SetGroup
self.Detection=Detection
self:SetStartState("Stopped")
self:AddTransition("Stopped","Start","Started")
self:AddTransition("Started","Stop","Stopped")
self:AddTransition("Started","Report","Started")
self:SetRefreshTimeInterval(30)
self:SetReportDisplayTime(25)
self:E({Detection=Detection})
Detection:__Start(3)
return self
end
function DETECTION_MANAGER:onafterStart(From,Event,To)
self:Report()
end
function DETECTION_MANAGER:onafterReport(From,Event,To)
self:E("onafterReport")
self:__Report(-self._RefreshTimeInterval)
self:ProcessDetected(self.Detection)
end
function DETECTION_MANAGER:SetRefreshTimeInterval(RefreshTimeInterval)
self:F2()
self._RefreshTimeInterval=RefreshTimeInterval
end
function DETECTION_MANAGER:SetReportDisplayTime(ReportDisplayTime)
self:F2()
self._ReportDisplayTime=ReportDisplayTime
end
function DETECTION_MANAGER:GetReportDisplayTime()
self:F2()
return self._ReportDisplayTime
end
function DETECTION_MANAGER:ProcessDetected(Detection)
self:E()
end
end
do
DETECTION_REPORTING={
ClassName="DETECTION_REPORTING",
}
function DETECTION_REPORTING:New(SetGroup,Detection)
local self=BASE:Inherit(self,DETECTION_MANAGER:New(SetGroup,Detection))
self:Schedule(1,30)
return self
end
function DETECTION_REPORTING:GetDetectedItemsText(DetectedSet)
self:F2()
local MT={}
local UnitTypes={}
for DetectedUnitID,DetectedUnitData in pairs(DetectedSet:GetSet())do
local DetectedUnit=DetectedUnitData
if DetectedUnit:IsAlive()then
local UnitType=DetectedUnit:GetTypeName()
if not UnitTypes[UnitType]then
UnitTypes[UnitType]=1
else
UnitTypes[UnitType]=UnitTypes[UnitType]+1
end
end
end
for UnitTypeID,UnitType in pairs(UnitTypes)do
MT[#MT+1]=UnitType.." of "..UnitTypeID
end
return table.concat(MT,", ")
end
function DETECTION_REPORTING:ProcessDetected(Group,Detection)
self:F2(Group)
self:E(Group)
local DetectedMsg={}
for DetectedAreaID,DetectedAreaData in pairs(Detection:GetDetectedAreas())do
local DetectedArea=DetectedAreaData
DetectedMsg[#DetectedMsg+1]=" - Group #"..DetectedAreaID..": "..self:GetDetectedItemsText(DetectedArea.Set)
end
local FACGroup=Detection:GetDetectionGroups()
FACGroup:MessageToGroup("Reporting detected target groups:\n"..table.concat(DetectedMsg,"\n"),self:GetReportDisplayTime(),Group)
return true
end
end
do
TASK_A2G_DISPATCHER={
ClassName="TASK_A2G_DISPATCHER",
Mission=nil,
Detection=nil,
Tasks={},
}
function TASK_A2G_DISPATCHER:New(Mission,SetGroup,Detection)
local self=BASE:Inherit(self,DETECTION_MANAGER:New(SetGroup,Detection))
self.Detection=Detection
self.Mission=Mission
self.Detection:FilterCategories(Unit.Category.GROUND_UNIT,Unit.Category.SHIP)
self.Detection:FilterFriendliesCategory(Unit.Category.GROUND_UNIT)
self:AddTransition("Started","Assign","Started")
self:__Start(5)
return self
end
function TASK_A2G_DISPATCHER:EvaluateSEAD(DetectedItem)
self:F({DetectedItem.ItemID})
local DetectedSet=DetectedItem.Set
local DetectedZone=DetectedItem.Zone
local RadarCount=DetectedSet:HasSEAD()
if RadarCount>0 then
local TargetSetUnit=SET_UNIT:New()
TargetSetUnit:SetDatabase(DetectedSet)
TargetSetUnit:FilterHasSEAD()
TargetSetUnit:FilterOnce()
return TargetSetUnit
end
return nil
end
function TASK_A2G_DISPATCHER:EvaluateCAS(DetectedItem)
self:F({DetectedItem.ItemID})
local DetectedSet=DetectedItem.Set
local DetectedZone=DetectedItem.Zone
local GroundUnitCount=DetectedSet:HasGroundUnits()
local FriendliesNearBy=self.Detection:IsFriendliesNearBy(DetectedItem)
local RadarCount=DetectedSet:HasSEAD()
if RadarCount==0 and GroundUnitCount>0 and FriendliesNearBy==true then
local TargetSetUnit=SET_UNIT:New()
TargetSetUnit:SetDatabase(DetectedSet)
TargetSetUnit:FilterOnce()
return TargetSetUnit
end
return nil
end
function TASK_A2G_DISPATCHER:EvaluateBAI(DetectedItem,FriendlyCoalition)
self:F({DetectedItem.ItemID})
local DetectedSet=DetectedItem.Set
local DetectedZone=DetectedItem.Zone
local GroundUnitCount=DetectedSet:HasGroundUnits()
local FriendliesNearBy=self.Detection:IsFriendliesNearBy(DetectedItem)
local RadarCount=DetectedSet:HasSEAD()
if RadarCount==0 and GroundUnitCount>0 and FriendliesNearBy==false then
local TargetSetUnit=SET_UNIT:New()
TargetSetUnit:SetDatabase(DetectedSet)
TargetSetUnit:FilterOnce()
return TargetSetUnit
end
return nil
end
function TASK_A2G_DISPATCHER:RemoveTask(TaskIndex)
self.Mission:RemoveTask(self.Tasks[TaskIndex])
self.Tasks[TaskIndex]=nil
end
function TASK_A2G_DISPATCHER:EvaluateRemoveTask(Mission,Task,TaskIndex,DetectedItemChanged)
if Task then
if(Task:IsStatePlanned()and DetectedItemChanged==true)or Task:IsStateCancelled()then
self:RemoveTask(TaskIndex)
end
end
return Task
end
function TASK_A2G_DISPATCHER:ProcessDetected(Detection)
self:E()
local AreaMsg={}
local TaskMsg={}
local ChangeMsg={}
local Mission=self.Mission
if Mission:IsIDLE()or Mission:IsENGAGED()then
local TaskReport=REPORT:New()
for TaskIndex,TaskData in pairs(self.Tasks)do
local Task=TaskData
if Task:IsStatePlanned()then
local DetectedItem=Detection:GetDetectedItem(TaskIndex)
if not DetectedItem then
local TaskText=Task:GetName()
for TaskGroupID,TaskGroup in pairs(self.SetGroup:GetSet())do
Mission:GetCommandCenter():MessageToGroup(string.format("Obsolete A2G task %s for %s removed.",TaskText,Mission:GetName()),TaskGroup)
end
Task=self:RemoveTask(TaskIndex)
Mission:RemoveTask(Task)
self.Tasks[TaskIndex]=nil
end
end
end
for DetectedItemID,DetectedItem in pairs(Detection:GetDetectedItems())do
local DetectedItem=DetectedItem
local DetectedSet=DetectedItem.Set
local DetectedZone=DetectedItem.Zone
local DetectedItemID=DetectedItem.ID
local TaskIndex=DetectedItem.Index
local DetectedItemChanged=DetectedItem.Changed
self:E({DetectedItemChanged=DetectedItemChanged,DetectedItemID=DetectedItemID,TaskIndex=TaskIndex})
local Task=self.Tasks[TaskIndex]
if Task then
if Task:IsStateAssigned()then
if DetectedItemChanged==true then
local TargetsReport=REPORT:New()
local TargetSetUnit=self:EvaluateSEAD(DetectedItem)
if TargetSetUnit then
if Task:IsInstanceOf(TASK_A2G_SEAD)then
Task:SetTargetSetUnit(TargetSetUnit)
Task:UpdateTaskInfo()
TargetsReport:Add(Detection:GetChangeText(DetectedItem))
else
Task:Cancel()
end
else
local TargetSetUnit=self:EvaluateCAS(DetectedItem)
if TargetSetUnit then
if Task:IsInstanceOf(TASK_A2G_CAS)then
Task:SetTargetSetUnit(TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
Task:UpdateTaskInfo()
TargetsReport:Add(Detection:GetChangeText(DetectedItem))
else
Task:Cancel()
Task=self:RemoveTask(TaskIndex)
end
else
local TargetSetUnit=self:EvaluateBAI(DetectedItem)
if TargetSetUnit then
if Task:IsInstanceOf(TASK_A2G_BAI)then
Task:SetTargetSetUnit(TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
Task:UpdateTaskInfo()
TargetsReport:Add(Detection:GetChangeText(DetectedItem))
else
Task:Cancel()
Task=self:RemoveTask(TaskIndex)
end
end
end
end
for TaskGroupID,TaskGroup in pairs(self.SetGroup:GetSet())do
local TargetsText=TargetsReport:Text(", ")
if(Mission:IsGroupAssigned(TaskGroup))and TargetsText~=""then
Mission:GetCommandCenter():MessageToGroup(string.format("Task %s has change of targets:\n %s",Task:GetName(),TargetsText),TaskGroup)
end
end
end
end
end
if Task then
if Task:IsStatePlanned()then
if DetectedItemChanged==true then
if Task:IsInstanceOf(TASK_A2G_SEAD)then
local TargetSetUnit=self:EvaluateSEAD(DetectedItem)
if TargetSetUnit then
Task:SetTargetSetUnit(TargetSetUnit)
Task:UpdateTaskInfo()
else
Task:Cancel()
Task=self:RemoveTask(TaskIndex)
end
else
if Task:IsInstanceOf(TASK_A2G_CAS)then
local TargetSetUnit=self:EvaluateCAS(DetectedItem)
if TargetSetUnit then
Task:SetTargetSetUnit(TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
Task:UpdateTaskInfo()
else
Task:Cancel()
Task=self:RemoveTask(TaskIndex)
end
else
if Task:IsInstanceOf(TASK_A2G_BAI)then
local TargetSetUnit=self:EvaluateBAI(DetectedItem)
if TargetSetUnit then
Task:SetTargetSetUnit(TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
Task:UpdateTaskInfo()
else
Task:Cancel()
Task=self:RemoveTask(TaskIndex)
end
else
Task:Cancel()
Task=self:RemoveTask(TaskIndex)
end
end
end
end
end
end
if not Task then
local TargetSetUnit=self:EvaluateSEAD(DetectedItem)
if TargetSetUnit then
Task=TASK_A2G_SEAD:New(Mission,self.SetGroup,string.format("SEAD.%03d",DetectedItemID),TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
end
if not Task then
local TargetSetUnit=self:EvaluateCAS(DetectedItem)
if TargetSetUnit then
Task=TASK_A2G_CAS:New(Mission,self.SetGroup,string.format("CAS.%03d",DetectedItemID),TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
end
if not Task then
local TargetSetUnit=self:EvaluateBAI(DetectedItem,self.Mission:GetCommandCenter():GetPositionable():GetCoalition())
if TargetSetUnit then
Task=TASK_A2G_BAI:New(Mission,self.SetGroup,string.format("BAI.%03d",DetectedItemID),TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
end
end
end
if Task then
self.Tasks[TaskIndex]=Task
Task:SetTargetZone(DetectedZone)
Task:SetDispatcher(self)
Task:UpdateTaskInfo()
Mission:AddTask(Task)
TaskReport:Add(Task:GetName())
else
self:E("This should not happen")
end
end
Detection:AcceptChanges(DetectedItem)
end
Mission:GetCommandCenter():SetMenu()
local TaskText=TaskReport:Text(", ")
for TaskGroupID,TaskGroup in pairs(self.SetGroup:GetSet())do
if(not Mission:IsGroupAssigned(TaskGroup))and TaskText~=""then
Mission:GetCommandCenter():MessageToGroup(string.format("%s has tasks %s. Subscribe to a task using the radio menu.",Mission:GetName(),TaskText),TaskGroup)
end
end
end
return true
end
end
do
TASK_A2G={
ClassName="TASK_A2G",
}
function TASK_A2G:New(Mission,SetGroup,TaskName,TargetSetUnit,TaskType,TaskBriefing)
local self=BASE:Inherit(self,TASK:New(Mission,SetGroup,TaskName,TaskType,TaskBriefing))
self:F()
self.TargetSetUnit=TargetSetUnit
self.TaskType=TaskType
local Fsm=self:GetUnitProcess()
Fsm:AddProcess("Planned","Accept",ACT_ASSIGN_ACCEPT:New(self.TaskBriefing),{Assigned="RouteToRendezVous",Rejected="Reject"})
Fsm:AddTransition("Assigned","RouteToRendezVous","RoutingToRendezVous")
Fsm:AddProcess("RoutingToRendezVous","RouteToRendezVousPoint",ACT_ROUTE_POINT:New(),{Arrived="ArriveAtRendezVous"})
Fsm:AddProcess("RoutingToRendezVous","RouteToRendezVousZone",ACT_ROUTE_ZONE:New(),{Arrived="ArriveAtRendezVous"})
Fsm:AddTransition({"Arrived","RoutingToRendezVous"},"ArriveAtRendezVous","ArrivedAtRendezVous")
Fsm:AddTransition({"ArrivedAtRendezVous","HoldingAtRendezVous"},"Engage","Engaging")
Fsm:AddTransition({"ArrivedAtRendezVous","HoldingAtRendezVous"},"HoldAtRendezVous","HoldingAtRendezVous")
Fsm:AddProcess("Engaging","Account",ACT_ACCOUNT_DEADS:New(),{})
Fsm:AddTransition("Engaging","RouteToTarget","Engaging")
Fsm:AddProcess("Engaging","RouteToTargetZone",ACT_ROUTE_ZONE:New(),{})
Fsm:AddProcess("Engaging","RouteToTargetPoint",ACT_ROUTE_POINT:New(),{})
Fsm:AddTransition("Engaging","RouteToTargets","Engaging")
Fsm:AddTransition("Rejected","Reject","Aborted")
Fsm:AddTransition("Failed","Fail","Failed")
function Fsm:onafterRouteToRendezVous(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if Task:GetRendezVousZone(TaskUnit)then
self:__RouteToRendezVousZone(0.1)
else
if Task:GetRendezVousCoordinate(TaskUnit)then
self:__RouteToRendezVousPoint(0.1)
else
self:__ArriveAtRendezVous(0.1)
end
end
end
function Fsm:OnAfterArriveAtRendezVous(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
self:__Engage(0.1)
end
function Fsm:onafterEngage(TaskUnit,Task)
self:E({self})
self:__Account(0.1)
self:__RouteToTarget(0.1)
self:__RouteToTargets(-10)
end
function Fsm:onafterRouteToTarget(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if Task:GetTargetZone(TaskUnit)then
self:__RouteToTargetZone(0.1)
else
local TargetUnit=Task.TargetSetUnit:GetFirst()
if TargetUnit then
local Coordinate=TargetUnit:GetPointVec3()
self:T({TargetCoordinate=Coordinate,Coordinate:GetX(),Coordinate:GetY(),Coordinate:GetZ()})
Task:SetTargetCoordinate(Coordinate,TaskUnit)
end
self:__RouteToTargetPoint(0.1)
end
end
function Fsm:onafterRouteToTargets(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
local TargetUnit=Task.TargetSetUnit:GetFirst()
if TargetUnit then
Task:SetTargetCoordinate(TargetUnit:GetCoordinate(),TaskUnit)
end
self:__RouteToTargets(-10)
end
return self
end
function TASK_A2G:SetTargetSetUnit(TargetSetUnit)
self.TargetSetUnit=TargetSetUnit
end
function TASK_A2G:GetPlannedMenuText()
return self:GetStateString().." - "..self:GetTaskName().." ( "..self.TargetSetUnit:GetUnitTypesText().." )"
end
function TASK_A2G:SetRendezVousCoordinate(RendezVousCoordinate,RendezVousRange,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteRendezVous=ProcessUnit:GetProcess("RoutingToRendezVous","RouteToRendezVousPoint")
ActRouteRendezVous:SetCoordinate(RendezVousCoordinate)
ActRouteRendezVous:SetRange(RendezVousRange)
end
function TASK_A2G:GetRendezVousCoordinate(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteRendezVous=ProcessUnit:GetProcess("RoutingToRendezVous","RouteToRendezVousPoint")
return ActRouteRendezVous:GetCoordinate(),ActRouteRendezVous:GetRange()
end
function TASK_A2G:SetRendezVousZone(RendezVousZone,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteRendezVous=ProcessUnit:GetProcess("RoutingToRendezVous","RouteToRendezVousZone")
ActRouteRendezVous:SetZone(RendezVousZone)
end
function TASK_A2G:GetRendezVousZone(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteRendezVous=ProcessUnit:GetProcess("RoutingToRendezVous","RouteToRendezVousZone")
return ActRouteRendezVous:GetZone()
end
function TASK_A2G:SetTargetCoordinate(TargetCoordinate,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetPoint")
ActRouteTarget:SetCoordinate(TargetCoordinate)
end
function TASK_A2G:GetTargetCoordinate(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetPoint")
return ActRouteTarget:GetCoordinate()
end
function TASK_A2G:SetTargetZone(TargetZone,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetZone")
ActRouteTarget:SetZone(TargetZone)
end
function TASK_A2G:GetTargetZone(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetZone")
return ActRouteTarget:GetZone()
end
function TASK_A2G:SetGoalTotal()
self.GoalTotal=self.TargetSetUnit:Count()
end
function TASK_A2G:GetGoalTotal()
return self.GoalTotal
end
end
do
TASK_A2G_SEAD={
ClassName="TASK_A2G_SEAD",
}
function TASK_A2G_SEAD:New(Mission,SetGroup,TaskName,TargetSetUnit,TaskBriefing)
local self=BASE:Inherit(self,TASK_A2G:New(Mission,SetGroup,TaskName,TargetSetUnit,"SEAD",TaskBriefing))
self:F()
Mission:AddTask(self)
self:SetBriefing(
TaskBriefing or
"Execute a Suppression of Enemy Air Defenses."
)
return self
end
function TASK_A2G_SEAD:UpdateTaskInfo()
local TargetCoordinate=self.Detection and self.Detection:GetDetectedItemCoordinate(self.DetectedItemIndex)or self.TargetSetUnit:GetFirst():GetCoordinate()
self:SetInfo("Coordinates",TargetCoordinate,0)
local ThreatLevel,ThreatText
if self.Detection then
ThreatLevel,ThreatText=self.Detection:GetDetectedItemThreatLevel(self.DetectedItemIndex)
else
ThreatLevel,ThreatText=self.TargetSetUnit:CalculateThreatLevelA2G()
end
self:SetInfo("Threat",ThreatText.." ["..string.rep("■",ThreatLevel).."]",11)
if self.Detection then
local DetectedItemsCount=self.TargetSetUnit:Count()
local ReportTypes=REPORT:New()
local TargetTypes={}
for TargetUnitName,TargetUnit in pairs(self.TargetSetUnit:GetSet())do
local TargetType=self.Detection:GetDetectedUnitTypeName(TargetUnit)
if not TargetTypes[TargetType]then
TargetTypes[TargetType]=TargetType
ReportTypes:Add(TargetType)
end
end
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,ReportTypes:Text(", ")),10)
else
local DetectedItemsCount=self.TargetSetUnit:Count()
local DetectedItemsTypes=self.TargetSetUnit:GetTypeNames()
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,DetectedItemsTypes),10)
end
end
function TASK_A2G_SEAD:ReportOrder(ReportGroup)
local Coordinate=self:GetInfo("Coordinates")
local Distance=ReportGroup:GetCoordinate():Get2DDistance(Coordinate)
return Distance
end
function TASK_A2G_SEAD:onafterGoal(TaskUnit,From,Event,To)
local TargetSetUnit=self.TargetSetUnit
if TargetSetUnit:Count()==0 then
self:Success()
end
self:__Goal(-10)
end
function TASK_A2G_SEAD:SetScoreOnProgress(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScoreProcess("Engaging","Account","AccountForPlayer","Player "..PlayerName.." has SEADed a target.",Score)
return self
end
function TASK_A2G_SEAD:SetScoreOnSuccess(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Success","All radar emitting targets have been successfully SEADed!",Score)
return self
end
function TASK_A2G_SEAD:SetScoreOnFail(PlayerName,Penalty,TaskUnit)
self:F({PlayerName,Penalty,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Failed","The SEADing has failed!",Penalty)
return self
end
end
do
TASK_A2G_BAI={
ClassName="TASK_A2G_BAI",
}
function TASK_A2G_BAI:New(Mission,SetGroup,TaskName,TargetSetUnit,TaskBriefing)
local self=BASE:Inherit(self,TASK_A2G:New(Mission,SetGroup,TaskName,TargetSetUnit,"BAI",TaskBriefing))
self:F()
Mission:AddTask(self)
self:SetBriefing(
TaskBriefing or
"Execute a Battlefield Air Interdiction of a group of enemy targets."
)
return self
end
function TASK_A2G_BAI:UpdateTaskInfo()
self:E({self.Detection,self.DetectedItemIndex})
local TargetCoordinate=self.Detection and self.Detection:GetDetectedItemCoordinate(self.DetectedItemIndex)or self.TargetSetUnit:GetFirst():GetCoordinate()
self:SetInfo("Coordinates",TargetCoordinate,0)
local ThreatLevel,ThreatText
if self.Detection then
ThreatLevel,ThreatText=self.Detection:GetDetectedItemThreatLevel(self.DetectedItemIndex)
else
ThreatLevel,ThreatText=self.TargetSetUnit:CalculateThreatLevelA2G()
end
self:SetInfo("Threat",ThreatText.." ["..string.rep("■",ThreatLevel).."]",11)
if self.Detection then
local DetectedItemsCount=self.TargetSetUnit:Count()
local ReportTypes=REPORT:New()
local TargetTypes={}
for TargetUnitName,TargetUnit in pairs(self.TargetSetUnit:GetSet())do
local TargetType=self.Detection:GetDetectedUnitTypeName(TargetUnit)
if not TargetTypes[TargetType]then
TargetTypes[TargetType]=TargetType
ReportTypes:Add(TargetType)
end
end
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,ReportTypes:Text(", ")),10)
else
local DetectedItemsCount=self.TargetSetUnit:Count()
local DetectedItemsTypes=self.TargetSetUnit:GetTypeNames()
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,DetectedItemsTypes),10)
end
end
function TASK_A2G_BAI:ReportOrder(ReportGroup)
local Coordinate=self:GetInfo("Coordinates")
local Distance=ReportGroup:GetCoordinate():Get2DDistance(Coordinate)
return Distance
end
function TASK_A2G_BAI:onafterGoal(TaskUnit,From,Event,To)
local TargetSetUnit=self.TargetSetUnit
if TargetSetUnit:Count()==0 then
self:Success()
end
self:__Goal(-10)
end
function TASK_A2G_BAI:SetScoreOnProgress(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScoreProcess("Engaging","Account","AccountForPlayer","Player "..PlayerName.." has destroyed a target in Battlefield Air Interdiction (BAI).",Score)
return self
end
function TASK_A2G_BAI:SetScoreOnSuccess(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Success","All targets have been successfully destroyed! The Battlefield Air Interdiction (BAI) is a success!",Score)
return self
end
function TASK_A2G_BAI:SetScoreOnFail(PlayerName,Penalty,TaskUnit)
self:F({PlayerName,Penalty,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Failed","The Battlefield Air Interdiction (BAI) has failed!",Penalty)
return self
end
end
do
TASK_A2G_CAS={
ClassName="TASK_A2G_CAS",
}
function TASK_A2G_CAS:New(Mission,SetGroup,TaskName,TargetSetUnit,TaskBriefing)
local self=BASE:Inherit(self,TASK_A2G:New(Mission,SetGroup,TaskName,TargetSetUnit,"CAS",TaskBriefing))
self:F()
Mission:AddTask(self)
self:SetBriefing(
TaskBriefing or
"Execute a Close Air Support for a group of enemy targets. "..
"Beware of friendlies at the vicinity! "
)
return self
end
function TASK_A2G_CAS:UpdateTaskInfo()
local TargetCoordinate=(self.Detection and self.Detection:GetDetectedItemCoordinate(self.DetectedItemIndex))or self.TargetSetUnit:GetFirst():GetCoordinate()
self:SetInfo("Coordinates",TargetCoordinate,0)
local ThreatLevel,ThreatText
if self.Detection then
ThreatLevel,ThreatText=self.Detection:GetDetectedItemThreatLevel(self.DetectedItemIndex)
else
ThreatLevel,ThreatText=self.TargetSetUnit:CalculateThreatLevelA2G()
end
self:SetInfo("Threat",ThreatText.." ["..string.rep("■",ThreatLevel).."]",11)
if self.Detection then
local DetectedItemsCount=self.TargetSetUnit:Count()
local ReportTypes=REPORT:New()
local TargetTypes={}
for TargetUnitName,TargetUnit in pairs(self.TargetSetUnit:GetSet())do
local TargetType=self.Detection:GetDetectedUnitTypeName(TargetUnit)
if not TargetTypes[TargetType]then
TargetTypes[TargetType]=TargetType
ReportTypes:Add(TargetType)
end
end
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,ReportTypes:Text(", ")),10)
else
local DetectedItemsCount=self.TargetSetUnit:Count()
local DetectedItemsTypes=self.TargetSetUnit:GetTypeNames()
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,DetectedItemsTypes),10)
end
end
function TASK_A2G_CAS:ReportOrder(ReportGroup)
local Coordinate=self:GetInfo("Coordinates")
local Distance=ReportGroup:GetCoordinate():Get2DDistance(Coordinate)
return Distance
end
function TASK_A2G_CAS:onafterGoal(TaskUnit,From,Event,To)
local TargetSetUnit=self.TargetSetUnit
if TargetSetUnit:Count()==0 then
self:Success()
end
self:__Goal(-10)
end
function TASK_A2G_CAS:SetScoreOnProgress(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScoreProcess("Engaging","Account","AccountForPlayer","Player "..PlayerName.." has destroyed a target in Close Air Support (CAS).",Score)
return self
end
function TASK_A2G_CAS:SetScoreOnSuccess(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Success","All targets have been successfully destroyed! The Close Air Support (CAS) was a success!",Score)
return self
end
function TASK_A2G_CAS:SetScoreOnFail(PlayerName,Penalty,TaskUnit)
self:F({PlayerName,Penalty,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Failed","The Close Air Support (CAS) has failed!",Penalty)
return self
end
end
do
TASK_A2A_DISPATCHER={
ClassName="TASK_A2A_DISPATCHER",
Mission=nil,
Detection=nil,
Tasks={},
SweepZones={},
}
function TASK_A2A_DISPATCHER:New(Mission,SetGroup,Detection)
local self=BASE:Inherit(self,DETECTION_MANAGER:New(SetGroup,Detection))
self.Detection=Detection
self.Mission=Mission
self.Detection:FilterCategories(Unit.Category.AIRPLANE,Unit.Category.HELICOPTER)
self.Detection:InitDetectRadar(true)
self.Detection:SetRefreshTimeInterval(30)
self:AddTransition("Started","Assign","Started")
self:__Start(5)
return self
end
function TASK_A2A_DISPATCHER:SetEngageRadius(EngageRadius)
self.Detection:SetFriendliesRange(EngageRadius or 100000)
return self
end
function TASK_A2A_DISPATCHER:EvaluateINTERCEPT(DetectedItem)
self:F({DetectedItem.ItemID})
local DetectedSet=DetectedItem.Set
local DetectedZone=DetectedItem.Zone
if DetectedItem.IsDetected==true then
local TargetSetUnit=SET_UNIT:New()
TargetSetUnit:SetDatabase(DetectedSet)
TargetSetUnit:FilterOnce()
return TargetSetUnit
end
return nil
end
function TASK_A2A_DISPATCHER:EvaluateSWEEP(DetectedItem)
self:F({DetectedItem.ItemID})
local DetectedSet=DetectedItem.Set
local DetectedZone=DetectedItem.Zone
if DetectedItem.IsDetected==false then
local TargetSetUnit=SET_UNIT:New()
TargetSetUnit:SetDatabase(DetectedSet)
TargetSetUnit:FilterOnce()
return TargetSetUnit
end
return nil
end
function TASK_A2A_DISPATCHER:EvaluateENGAGE(DetectedItem)
self:F({DetectedItem.ItemID})
local DetectedSet=DetectedItem.Set
local DetectedZone=DetectedItem.Zone
local PlayersCount,PlayersReport=self:GetPlayerFriendliesNearBy(DetectedItem)
if PlayersCount>0 and DetectedItem.IsDetected==true then
local TargetSetUnit=SET_UNIT:New()
TargetSetUnit:SetDatabase(DetectedSet)
TargetSetUnit:FilterOnce()
return TargetSetUnit
end
return nil
end
function TASK_A2A_DISPATCHER:EvaluateRemoveTask(Mission,Task,Detection,DetectedItem,DetectedItemIndex,DetectedItemChanged)
if Task then
if Task:IsStatePlanned()then
local TaskName=Task:GetName()
local TaskType=TaskName:match("(%u+)%.%d+")
self:T2({TaskType=TaskType})
local Remove=false
local IsPlayers=Detection:IsPlayersNearBy(DetectedItem)
if TaskType=="ENGAGE"then
if IsPlayers==false then
Remove=true
end
end
if TaskType=="INTERCEPT"then
if IsPlayers==true then
Remove=true
end
if DetectedItem.IsDetected==false then
Remove=true
end
end
if TaskType=="SWEEP"then
if DetectedItem.IsDetected==true then
Remove=true
end
end
local DetectedSet=DetectedItem.Set
if DetectedSet:Count()==0 then
Remove=true
end
if DetectedItemChanged==true or Remove then
Task=self:RemoveTask(DetectedItemIndex)
end
end
end
return Task
end
function TASK_A2A_DISPATCHER:GetFriendliesNearBy(DetectedItem)
local DetectedSet=DetectedItem.Set
local FriendlyUnitsNearBy=self.Detection:GetFriendliesNearBy(DetectedItem)
local FriendlyTypes={}
local FriendliesCount=0
if FriendlyUnitsNearBy then
local DetectedTreatLevel=DetectedSet:CalculateThreatLevelA2G()
for FriendlyUnitName,FriendlyUnitData in pairs(FriendlyUnitsNearBy)do
local FriendlyUnit=FriendlyUnitData
if FriendlyUnit:IsAirPlane()then
local FriendlyUnitThreatLevel=FriendlyUnit:GetThreatLevel()
FriendliesCount=FriendliesCount+1
local FriendlyType=FriendlyUnit:GetTypeName()
FriendlyTypes[FriendlyType]=FriendlyTypes[FriendlyType]and(FriendlyTypes[FriendlyType]+1)or 1
if DetectedTreatLevel<FriendlyUnitThreatLevel+2 then
end
end
end
end
local FriendlyTypesReport=REPORT:New()
if FriendliesCount>0 then
for FriendlyType,FriendlyTypeCount in pairs(FriendlyTypes)do
FriendlyTypesReport:Add(string.format("%d of %s",FriendlyTypeCount,FriendlyType))
end
else
FriendlyTypesReport:Add("-")
end
return FriendliesCount,FriendlyTypesReport
end
function TASK_A2A_DISPATCHER:GetPlayerFriendliesNearBy(DetectedItem)
local DetectedSet=DetectedItem.Set
local PlayersNearBy=self.Detection:GetPlayersNearBy(DetectedItem)
local PlayerTypes={}
local PlayersCount=0
if PlayersNearBy then
local DetectedTreatLevel=DetectedSet:CalculateThreatLevelA2G()
for PlayerUnitName,PlayerUnitData in pairs(PlayersNearBy)do
local PlayerUnit=PlayerUnitData
local PlayerName=PlayerUnit:GetPlayerName()
if PlayerUnit:IsAirPlane()and PlayerName~=nil then
local FriendlyUnitThreatLevel=PlayerUnit:GetThreatLevel()
PlayersCount=PlayersCount+1
local PlayerType=PlayerUnit:GetTypeName()
PlayerTypes[PlayerName]=PlayerType
if DetectedTreatLevel<FriendlyUnitThreatLevel+2 then
end
end
end
end
local PlayerTypesReport=REPORT:New()
if PlayersCount>0 then
for PlayerName,PlayerType in pairs(PlayerTypes)do
PlayerTypesReport:Add(string.format('"%s" in %s',PlayerName,PlayerType))
end
else
PlayerTypesReport:Add("-")
end
return PlayersCount,PlayerTypesReport
end
function TASK_A2A_DISPATCHER:RemoveTask(TaskIndex)
self.Mission:RemoveTask(self.Tasks[TaskIndex])
self.Tasks[TaskIndex]=nil
end
function TASK_A2A_DISPATCHER:ProcessDetected(Detection)
self:E()
local AreaMsg={}
local TaskMsg={}
local ChangeMsg={}
local Mission=self.Mission
if Mission:IsIDLE()or Mission:IsENGAGED()then
local TaskReport=REPORT:New()
for TaskIndex,TaskData in pairs(self.Tasks)do
local Task=TaskData
if Task:IsStatePlanned()then
local DetectedItem=Detection:GetDetectedItem(TaskIndex)
if not DetectedItem then
local TaskText=Task:GetName()
for TaskGroupID,TaskGroup in pairs(self.SetGroup:GetSet())do
Mission:GetCommandCenter():MessageToGroup(string.format("Obsolete A2A task %s for %s removed.",TaskText,Mission:GetName()),TaskGroup)
end
Task=self:RemoveTask(TaskIndex)
end
end
end
for DetectedItemID,DetectedItem in pairs(Detection:GetDetectedItems())do
local DetectedItem=DetectedItem
local DetectedSet=DetectedItem.Set
local DetectedCount=DetectedSet:Count()
local DetectedZone=DetectedItem.Zone
local DetectedID=DetectedItem.ID
local TaskIndex=DetectedItem.Index
local DetectedItemChanged=DetectedItem.Changed
local Task=self.Tasks[TaskIndex]
Task=self:EvaluateRemoveTask(Mission,Task,Detection,DetectedItem,TaskIndex,DetectedItemChanged)
if not Task and DetectedCount>0 then
local TargetSetUnit=self:EvaluateENGAGE(DetectedItem)
if TargetSetUnit then
Task=TASK_A2A_ENGAGE:New(Mission,self.SetGroup,string.format("ENGAGE.%03d",DetectedID),TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
else
local TargetSetUnit=self:EvaluateINTERCEPT(DetectedItem)
if TargetSetUnit then
Task=TASK_A2A_INTERCEPT:New(Mission,self.SetGroup,string.format("INTERCEPT.%03d",DetectedID),TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
else
local TargetSetUnit=self:EvaluateSWEEP(DetectedItem)
if TargetSetUnit then
Task=TASK_A2A_SWEEP:New(Mission,self.SetGroup,string.format("SWEEP.%03d",DetectedID),TargetSetUnit)
Task:SetDetection(Detection,TaskIndex)
end
end
end
if Task then
self.Tasks[TaskIndex]=Task
Task:SetTargetZone(DetectedZone,DetectedItem.Coordinate.y,DetectedItem.Coordinate.Heading)
Task:SetDispatcher(self)
Mission:AddTask(Task)
TaskReport:Add(Task:GetName())
else
self:E("This should not happen")
end
end
if Task then
local FriendliesCount,FriendliesReport=self:GetFriendliesNearBy(DetectedItem)
Task:SetInfo("Friendlies",string.format("%d ( %s )",FriendliesCount,FriendliesReport:Text(",")),30)
local PlayersCount,PlayersReport=self:GetPlayerFriendliesNearBy(DetectedItem)
Task:SetInfo("Players",string.format("%d ( %s )",PlayersCount,PlayersReport:Text(",")),31)
end
Detection:AcceptChanges(DetectedItem)
end
Mission:GetCommandCenter():SetMenu()
local TaskText=TaskReport:Text(", ")
for TaskGroupID,TaskGroup in pairs(self.SetGroup:GetSet())do
if(not Mission:IsGroupAssigned(TaskGroup))and TaskText~=""then
Mission:GetCommandCenter():MessageToGroup(string.format("%s has tasks %s. Subscribe to a task using the radio menu.",Mission:GetName(),TaskText),TaskGroup)
end
end
end
return true
end
end
do
TASK_A2A={
ClassName="TASK_A2A",
}
function TASK_A2A:New(Mission,SetAttack,TaskName,TargetSetUnit,TaskType,TaskBriefing)
local self=BASE:Inherit(self,TASK:New(Mission,SetAttack,TaskName,TaskType,TaskBriefing))
self:F()
self.TargetSetUnit=TargetSetUnit
self.TaskType=TaskType
local Fsm=self:GetUnitProcess()
Fsm:AddProcess("Planned","Accept",ACT_ASSIGN_ACCEPT:New(self.TaskBriefing),{Assigned="RouteToRendezVous",Rejected="Reject"})
Fsm:AddTransition("Assigned","RouteToRendezVous","RoutingToRendezVous")
Fsm:AddProcess("RoutingToRendezVous","RouteToRendezVousPoint",ACT_ROUTE_POINT:New(),{Arrived="ArriveAtRendezVous"})
Fsm:AddProcess("RoutingToRendezVous","RouteToRendezVousZone",ACT_ROUTE_ZONE:New(),{Arrived="ArriveAtRendezVous"})
Fsm:AddTransition({"Arrived","RoutingToRendezVous"},"ArriveAtRendezVous","ArrivedAtRendezVous")
Fsm:AddTransition({"ArrivedAtRendezVous","HoldingAtRendezVous"},"Engage","Engaging")
Fsm:AddTransition({"ArrivedAtRendezVous","HoldingAtRendezVous"},"HoldAtRendezVous","HoldingAtRendezVous")
Fsm:AddProcess("Engaging","Account",ACT_ACCOUNT_DEADS:New(),{})
Fsm:AddTransition("Engaging","RouteToTarget","Engaging")
Fsm:AddProcess("Engaging","RouteToTargetZone",ACT_ROUTE_ZONE:New(),{})
Fsm:AddProcess("Engaging","RouteToTargetPoint",ACT_ROUTE_POINT:New(),{})
Fsm:AddTransition("Engaging","RouteToTargets","Engaging")
Fsm:AddTransition("Rejected","Reject","Aborted")
Fsm:AddTransition("Failed","Fail","Failed")
function Fsm:onafterRouteToRendezVous(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if Task:GetRendezVousZone(TaskUnit)then
self:__RouteToRendezVousZone(0.1)
else
if Task:GetRendezVousCoordinate(TaskUnit)then
self:__RouteToRendezVousPoint(0.1)
else
self:__ArriveAtRendezVous(0.1)
end
end
end
function Fsm:OnAfterArriveAtRendezVous(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
self:__Engage(0.1)
end
function Fsm:onafterEngage(TaskUnit,Task)
self:E({self})
self:__Account(0.1)
self:__RouteToTarget(0.1)
self:__RouteToTargets(-10)
end
function Fsm:onafterRouteToTarget(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if Task:GetTargetZone(TaskUnit)then
self:__RouteToTargetZone(0.1)
else
local TargetUnit=Task.TargetSetUnit:GetFirst()
if TargetUnit then
local Coordinate=TargetUnit:GetCoordinate()
self:T({TargetCoordinate=Coordinate,Coordinate:GetX(),Coordinate:GetAlt(),Coordinate:GetZ()})
Task:SetTargetCoordinate(TargetUnit:GetCoordinate(),TaskUnit)
end
self:__RouteToTargetPoint(0.1)
end
end
function Fsm:onafterRouteToTargets(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
local TargetUnit=Task.TargetSetUnit:GetFirst()
if TargetUnit then
Task:SetTargetCoordinate(TargetUnit:GetCoordinate(),TaskUnit)
end
self:__RouteToTargets(-10)
end
return self
end
function TASK_A2A:GetPlannedMenuText()
return self:GetStateString().." - "..self:GetTaskName().." ( "..self.TargetSetUnit:GetUnitTypesText().." )"
end
function TASK_A2A:SetRendezVousCoordinate(RendezVousCoordinate,RendezVousRange,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteRendezVous=ProcessUnit:GetProcess("RoutingToRendezVous","RouteToRendezVousPoint")
ActRouteRendezVous:SetCoordinate(RendezVousCoordinate)
ActRouteRendezVous:SetRange(RendezVousRange)
end
function TASK_A2A:GetRendezVousCoordinate(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteRendezVous=ProcessUnit:GetProcess("RoutingToRendezVous","RouteToRendezVousPoint")
return ActRouteRendezVous:GetCoordinate(),ActRouteRendezVous:GetRange()
end
function TASK_A2A:SetRendezVousZone(RendezVousZone,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteRendezVous=ProcessUnit:GetProcess("RoutingToRendezVous","RouteToRendezVousZone")
ActRouteRendezVous:SetZone(RendezVousZone)
end
function TASK_A2A:GetRendezVousZone(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteRendezVous=ProcessUnit:GetProcess("RoutingToRendezVous","RouteToRendezVousZone")
return ActRouteRendezVous:GetZone()
end
function TASK_A2A:SetTargetCoordinate(TargetCoordinate,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetPoint")
ActRouteTarget:SetCoordinate(TargetCoordinate)
end
function TASK_A2A:GetTargetCoordinate(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetPoint")
return ActRouteTarget:GetCoordinate()
end
function TASK_A2A:SetTargetZone(TargetZone,Altitude,Heading,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetZone")
ActRouteTarget:SetZone(TargetZone,Altitude,Heading)
end
function TASK_A2A:GetTargetZone(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetZone")
return ActRouteTarget:GetZone()
end
function TASK_A2A:SetGoalTotal()
self.GoalTotal=self.TargetSetUnit:Count()
end
function TASK_A2A:GetGoalTotal()
return self.GoalTotal
end
end
do
TASK_A2A_INTERCEPT={
ClassName="TASK_A2A_INTERCEPT",
}
function TASK_A2A_INTERCEPT:New(Mission,SetGroup,TaskName,TargetSetUnit,TaskBriefing)
local self=BASE:Inherit(self,TASK_A2A:New(Mission,SetGroup,TaskName,TargetSetUnit,"INTERCEPT",TaskBriefing))
self:F()
Mission:AddTask(self)
self:SetBriefing(
TaskBriefing or
"Intercept incoming intruders.\n"
)
self:UpdateTaskInfo()
return self
end
function TASK_A2A_INTERCEPT:UpdateTaskInfo()
local TargetCoordinate=self.Detection and self.Detection:GetDetectedItemCoordinate(self.DetectedItemIndex)or self.TargetSetUnit:GetFirst():GetCoordinate()
self:SetInfo("Coordinates",TargetCoordinate,0)
self:SetInfo("Threat","["..string.rep("■",self.Detection and self.Detection:GetDetectedItemThreatLevel(self.DetectedItemIndex)or self.TargetSetUnit:CalculateThreatLevelA2G()).."]",11)
if self.Detection then
local DetectedItemsCount=self.TargetSetUnit:Count()
local ReportTypes=REPORT:New()
local TargetTypes={}
for TargetUnitName,TargetUnit in pairs(self.TargetSetUnit:GetSet())do
local TargetType=self.Detection:GetDetectedUnitTypeName(TargetUnit)
if not TargetTypes[TargetType]then
TargetTypes[TargetType]=TargetType
ReportTypes:Add(TargetType)
end
end
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,ReportTypes:Text(", ")),10)
else
local DetectedItemsCount=self.TargetSetUnit:Count()
local DetectedItemsTypes=self.TargetSetUnit:GetTypeNames()
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,DetectedItemsTypes),10)
end
end
function TASK_A2A_INTERCEPT:ReportOrder(ReportGroup)
self:F({TaskInfo=self.TaskInfo})
local Coordinate=self.TaskInfo.Coordinates.TaskInfoText
local Distance=ReportGroup:GetCoordinate():Get2DDistance(Coordinate)
return Distance
end
function TASK_A2A_INTERCEPT:onafterGoal(TaskUnit,From,Event,To)
local TargetSetUnit=self.TargetSetUnit
if TargetSetUnit:Count()==0 then
self:Success()
end
self:__Goal(-10)
end
function TASK_A2A_INTERCEPT:SetScoreOnProgress(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScoreProcess("Engaging","Account","AccountForPlayer","Player "..PlayerName.." has intercepted a target.",Score)
return self
end
function TASK_A2A_INTERCEPT:SetScoreOnSuccess(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Success","All targets have been successfully intercepted!",Score)
return self
end
function TASK_A2A_INTERCEPT:SetScoreOnFail(PlayerName,Penalty,TaskUnit)
self:F({PlayerName,Penalty,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Failed","The intercept has failed!",Penalty)
return self
end
end
do
TASK_A2A_SWEEP={
ClassName="TASK_A2A_SWEEP",
}
function TASK_A2A_SWEEP:New(Mission,SetGroup,TaskName,TargetSetUnit,TaskBriefing)
local self=BASE:Inherit(self,TASK_A2A:New(Mission,SetGroup,TaskName,TargetSetUnit,"SWEEP",TaskBriefing))
self:F()
Mission:AddTask(self)
self:SetBriefing(
TaskBriefing or
"Perform a fighter sweep. Incoming intruders were detected and could be hiding at the location.\n"
)
self:UpdateTaskInfo()
return self
end
function TASK_A2A_SWEEP:UpdateTaskInfo()
local TargetCoordinate=self.Detection and self.Detection:GetDetectedItemCoordinate(self.DetectedItemIndex)or self.TargetSetUnit:GetFirst():GetCoordinate()
self:SetInfo("Coordinates",TargetCoordinate,0)
self:SetInfo("Assumed Threat","["..string.rep("■",self.Detection and self.Detection:GetDetectedItemThreatLevel(self.DetectedItemIndex)or self.TargetSetUnit:CalculateThreatLevelA2G()).."]",11)
if self.Detection then
local DetectedItemsCount=self.TargetSetUnit:Count()
local ReportTypes=REPORT:New()
local TargetTypes={}
for TargetUnitName,TargetUnit in pairs(self.TargetSetUnit:GetSet())do
local TargetType=self.Detection:GetDetectedUnitTypeName(TargetUnit)
if not TargetTypes[TargetType]then
TargetTypes[TargetType]=TargetType
ReportTypes:Add(TargetType)
end
end
self:SetInfo("Lost Targets",string.format("%d of %s",DetectedItemsCount,ReportTypes:Text(", ")),10)
else
local DetectedItemsCount=self.TargetSetUnit:Count()
local DetectedItemsTypes=self.TargetSetUnit:GetTypeNames()
self:SetInfo("Lost Targets",string.format("%d of %s",DetectedItemsCount,DetectedItemsTypes),10)
end
end
function TASK_A2A_SWEEP:ReportOrder(ReportGroup)
local Coordinate=self.TaskInfo.Coordinates.TaskInfoText
local Distance=ReportGroup:GetCoordinate():Get2DDistance(Coordinate)
return Distance
end
function TASK_A2A_SWEEP:onafterGoal(TaskUnit,From,Event,To)
local TargetSetUnit=self.TargetSetUnit
if TargetSetUnit:Count()==0 then
self:Success()
end
self:__Goal(-10)
end
function TASK_A2A_SWEEP:SetScoreOnProgress(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScoreProcess("Engaging","Account","AccountForPlayer","Player "..PlayerName.." has sweeped a target.",Score)
return self
end
function TASK_A2A_SWEEP:SetScoreOnSuccess(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Success","All targets have been successfully sweeped!",Score)
return self
end
function TASK_A2A_SWEEP:SetScoreOnFail(PlayerName,Penalty,TaskUnit)
self:F({PlayerName,Penalty,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Failed","The sweep has failed!",Penalty)
return self
end
end
do
TASK_A2A_ENGAGE={
ClassName="TASK_A2A_ENGAGE",
}
function TASK_A2A_ENGAGE:New(Mission,SetGroup,TaskName,TargetSetUnit,TaskBriefing)
local self=BASE:Inherit(self,TASK_A2A:New(Mission,SetGroup,TaskName,TargetSetUnit,"ENGAGE",TaskBriefing))
self:F()
Mission:AddTask(self)
self:SetBriefing(
TaskBriefing or
"Bogeys are nearby! Players close by are ordered to ENGAGE the intruders!\n"
)
self:UpdateTaskInfo()
return self
end
function TASK_A2A_ENGAGE:UpdateTaskInfo()
local TargetCoordinate=self.Detection and self.Detection:GetDetectedItemCoordinate(self.DetectedItemIndex)or self.TargetSetUnit:GetFirst():GetCoordinate()
self:SetInfo("Coordinates",TargetCoordinate,0)
self:SetInfo("Threat","["..string.rep("■",self.Detection and self.Detection:GetDetectedItemThreatLevel(self.DetectedItemIndex)or self.TargetSetUnit:CalculateThreatLevelA2G()).."]",11)
if self.Detection then
local DetectedItemsCount=self.TargetSetUnit:Count()
local ReportTypes=REPORT:New()
local TargetTypes={}
for TargetUnitName,TargetUnit in pairs(self.TargetSetUnit:GetSet())do
local TargetType=self.Detection:GetDetectedUnitTypeName(TargetUnit)
if not TargetTypes[TargetType]then
TargetTypes[TargetType]=TargetType
ReportTypes:Add(TargetType)
end
end
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,ReportTypes:Text(", ")),10)
else
local DetectedItemsCount=self.TargetSetUnit:Count()
local DetectedItemsTypes=self.TargetSetUnit:GetTypeNames()
self:SetInfo("Targets",string.format("%d of %s",DetectedItemsCount,DetectedItemsTypes),10)
end
end
function TASK_A2A_ENGAGE:ReportOrder(ReportGroup)
local Coordinate=self.TaskInfo.Coordinates.TaskInfoText
local Distance=ReportGroup:GetCoordinate():Get2DDistance(Coordinate)
return Distance
end
function TASK_A2A_ENGAGE:onafterGoal(TaskUnit,From,Event,To)
local TargetSetUnit=self.TargetSetUnit
if TargetSetUnit:Count()==0 then
self:Success()
end
self:__Goal(-10)
end
function TASK_A2A_ENGAGE:SetScoreOnProgress(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScoreProcess("Engaging","Account","AccountForPlayer","Player "..PlayerName.." has engaged and destroyed a target.",Score)
return self
end
function TASK_A2A_ENGAGE:SetScoreOnSuccess(PlayerName,Score,TaskUnit)
self:F({PlayerName,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Success","All targets have been successfully engaged!",Score)
return self
end
function TASK_A2A_ENGAGE:SetScoreOnFail(PlayerName,Penalty,TaskUnit)
self:F({PlayerName,Penalty,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Failed","The target engagement has failed!",Penalty)
return self
end
end
do
TASK_CARGO={
ClassName="TASK_CARGO",
}
function TASK_CARGO:New(Mission,SetGroup,TaskName,SetCargo,TaskType,TaskBriefing)
local self=BASE:Inherit(self,TASK:New(Mission,SetGroup,TaskName,TaskType,TaskBriefing))
self:F({Mission,SetGroup,TaskName,SetCargo,TaskType})
self.SetCargo=SetCargo
self.TaskType=TaskType
self.SmokeColor=SMOKECOLOR.Red
self.CargoItemCount={}
self.CargoLimit=2
self.DeployZones={}
local Fsm=self:GetUnitProcess()
Fsm:SetStartState("Planned")
Fsm:AddProcess("Planned","Accept",ACT_ASSIGN_ACCEPT:New(self.TaskBriefing),{Assigned="SelectAction",Rejected="Reject"})
Fsm:AddTransition({"Assigned","WaitingForCommand","ArrivedAtPickup","ArrivedAtDeploy","Boarded","UnBoarded","Landed","Boarding"},"SelectAction","*")
Fsm:AddTransition("*","RouteToPickup","RoutingToPickup")
Fsm:AddProcess("RoutingToPickup","RouteToPickupPoint",ACT_ROUTE_POINT:New(),{Arrived="ArriveAtPickup",Cancelled="CancelRouteToPickup"})
Fsm:AddTransition("Arrived","ArriveAtPickup","ArrivedAtPickup")
Fsm:AddTransition("Cancelled","CancelRouteToPickup","WaitingForCommand")
Fsm:AddTransition("*","RouteToDeploy","RoutingToDeploy")
Fsm:AddProcess("RoutingToDeploy","RouteToDeployZone",ACT_ROUTE_ZONE:New(),{Arrived="ArriveAtDeploy",Cancelled="CancelRouteToDeploy"})
Fsm:AddTransition("Arrived","ArriveAtDeploy","ArrivedAtDeploy")
Fsm:AddTransition("Cancelled","CancelRouteToDeploy","WaitingForCommand")
Fsm:AddTransition({"ArrivedAtPickup","ArrivedAtDeploy","Landing"},"Land","Landing")
Fsm:AddTransition("Landing","Landed","Landed")
Fsm:AddTransition("*","PrepareBoarding","AwaitBoarding")
Fsm:AddTransition("AwaitBoarding","Board","Boarding")
Fsm:AddTransition("Boarding","Boarded","Boarded")
Fsm:AddTransition("*","PrepareUnBoarding","AwaitUnBoarding")
Fsm:AddTransition("AwaitUnBoarding","UnBoard","UnBoarding")
Fsm:AddTransition("UnBoarding","UnBoarded","UnBoarded")
Fsm:AddTransition("Deployed","Success","Success")
Fsm:AddTransition("Rejected","Reject","Aborted")
Fsm:AddTransition("Failed","Fail","Failed")
function Fsm:onafterSelectAction(TaskUnit,Task)
local TaskUnitName=TaskUnit:GetName()
self:E({TaskUnit=TaskUnitName,Task=Task and Task:GetClassNameAndID()})
local MenuTime=timer.getTime()
TaskUnit.Menu=MENU_GROUP:New(TaskUnit:GetGroup(),Task:GetName().." @ "..TaskUnit:GetName()):SetTime(MenuTime)
local CargoItemCount=TaskUnit:CargoItemCount()
Task.SetCargo:ForEachCargo(
function(Cargo)
if Cargo:IsAlive()then
if Cargo:IsUnLoaded()then
if CargoItemCount<Task.CargoLimit then
if Cargo:IsInRadius(TaskUnit:GetPointVec2())then
local NotInDeployZones=true
for DeployZoneName,DeployZone in pairs(Task.DeployZones)do
if Cargo:IsInZone(DeployZone)then
NotInDeployZones=false
end
end
if NotInDeployZones then
if not TaskUnit:InAir()then
MENU_GROUP_COMMAND:New(TaskUnit:GetGroup(),"Board cargo "..Cargo.Name,TaskUnit.Menu,self.MenuBoardCargo,self,Cargo):SetTime(MenuTime)
end
end
else
MENU_GROUP_COMMAND:New(TaskUnit:GetGroup(),"Route to Pickup cargo "..Cargo.Name,TaskUnit.Menu,self.MenuRouteToPickup,self,Cargo):SetTime(MenuTime)
end
end
end
if Cargo:IsLoaded()then
if not TaskUnit:InAir()then
MENU_GROUP_COMMAND:New(TaskUnit:GetGroup(),"Unboard cargo "..Cargo.Name,TaskUnit.Menu,self.MenuUnBoardCargo,self,Cargo):SetTime(MenuTime)
end
for DeployZoneName,DeployZone in pairs(Task.DeployZones)do
if not Cargo:IsInZone(DeployZone)then
MENU_GROUP_COMMAND:New(TaskUnit:GetGroup(),"Route to Deploy cargo at "..DeployZoneName,TaskUnit.Menu,self.MenuRouteToDeploy,self,DeployZone):SetTime(MenuTime)
end
end
end
end
end
)
TaskUnit.Menu:Remove(MenuTime)
self:__SelectAction(-15)
end
function Fsm:OnLeaveWaitingForCommand(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
TaskUnit.Menu:Remove()
end
function Fsm:MenuBoardCargo(Cargo)
self:__PrepareBoarding(1.0,Cargo)
end
function Fsm:MenuUnBoardCargo(Cargo,DeployZone)
self:__PrepareUnBoarding(1.0,Cargo,DeployZone)
end
function Fsm:MenuRouteToPickup(Cargo)
self:__RouteToPickup(1.0,Cargo)
end
function Fsm:MenuRouteToDeploy(DeployZone)
self:__RouteToDeploy(1.0,DeployZone)
end
function Fsm:onafterRouteToPickup(TaskUnit,Task,From,Event,To,Cargo)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if Cargo:IsAlive()then
self.Cargo=Cargo
Task:SetCargoPickup(self.Cargo,TaskUnit)
self:__RouteToPickupPoint(-0.1)
end
end
function Fsm:onafterArriveAtPickup(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if self.Cargo:IsAlive()then
self.Cargo:Smoke(Task:GetSmokeColor(),15)
if TaskUnit:IsAir()then
Task:GetMission():GetCommandCenter():MessageToGroup("Land",TaskUnit:GetGroup())
self:__Land(-0.1,"Pickup")
else
self:__SelectAction(-0.1)
end
end
end
function Fsm:onafterCancelRouteToPickup(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
self:__SelectAction(-0.1)
end
function Fsm:onafterRouteToDeploy(TaskUnit,Task,From,Event,To,DeployZone)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
self:E(DeployZone)
self.DeployZone=DeployZone
Task:SetDeployZone(self.DeployZone,TaskUnit)
self:__RouteToDeployZone(-0.1)
end
function Fsm:onafterArriveAtDeploy(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if TaskUnit:IsAir()then
Task:GetMission():GetCommandCenter():MessageToGroup("Land",TaskUnit:GetGroup())
self:__Land(-0.1,"Deploy")
else
self:__SelectAction(-0.1)
end
end
function Fsm:onafterCancelRouteToDeploy(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
self:__SelectAction(-0.1)
end
function Fsm:onafterLand(TaskUnit,Task,From,Event,To,Action)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if self.Cargo:IsAlive()then
if self.Cargo:IsInRadius(TaskUnit:GetPointVec2())then
if TaskUnit:InAir()then
self:__Land(-10,Action)
else
Task:GetMission():GetCommandCenter():MessageToGroup("Landed ...",TaskUnit:GetGroup())
self:__Landed(-0.1,Action)
end
else
if Action=="Pickup"then
self:__RouteToPickupZone(-0.1)
else
self:__RouteToDeployZone(-0.1)
end
end
end
end
function Fsm:onafterLanded(TaskUnit,Task,From,Event,To,Action)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if self.Cargo:IsAlive()then
if self.Cargo:IsInRadius(TaskUnit:GetPointVec2())then
if TaskUnit:InAir()then
self:__Land(-0.1,Action)
else
self:__SelectAction(-0.1)
end
else
if Action=="Pickup"then
self:__RouteToPickupZone(-0.1)
else
self:__RouteToDeployZone(-0.1)
end
end
end
end
function Fsm:onafterPrepareBoarding(TaskUnit,Task,From,Event,To,Cargo)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
if Cargo and Cargo:IsAlive()then
self.Cargo=Cargo
self:__Board(-0.1)
end
end
function Fsm:onafterBoard(TaskUnit,Task)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID()})
function self.Cargo:OnEnterLoaded(From,Event,To,TaskUnit,TaskProcess)
self:E({From,Event,To,TaskUnit,TaskProcess})
TaskProcess:__Boarded(0.1)
end
if self.Cargo:IsAlive()then
if self.Cargo:IsInRadius(TaskUnit:GetPointVec2())then
if TaskUnit:InAir()then
else
self.Cargo:MessageToGroup("Boarding ...",TaskUnit:GetGroup())
self.Cargo:Board(TaskUnit,20,self)
end
else
end
end
end
function Fsm:onafterBoarded(TaskUnit,Task)
local TaskUnitName=TaskUnit:GetName()
self:E({TaskUnit=TaskUnitName,Task=Task and Task:GetClassNameAndID()})
self.Cargo:MessageToGroup("Boarded ...",TaskUnit:GetGroup())
TaskUnit:AddCargo(self.Cargo)
self:__SelectAction(1)
Task:E({CargoPickedUp=Task.CargoPickedUp})
if self.Cargo:IsAlive()then
if Task.CargoPickedUp then
Task:CargoPickedUp(TaskUnit,self.Cargo)
end
end
end
function Fsm:onafterPrepareUnBoarding(TaskUnit,Task,From,Event,To,Cargo)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID(),From,Event,To,Cargo})
self.Cargo=Cargo
self.DeployZone=nil
if Cargo:IsAlive()then
for DeployZoneName,DeployZone in pairs(Task.DeployZones)do
if Cargo:IsInZone(DeployZone)then
self.DeployZone=DeployZone
break
end
end
self:__UnBoard(-0.1,Cargo,self.DeployZone)
end
end
function Fsm:onafterUnBoard(TaskUnit,Task,From,Event,To,Cargo,DeployZone)
self:E({TaskUnit=TaskUnit,Task=Task and Task:GetClassNameAndID(),From,Event,To,Cargo,DeployZone})
function self.Cargo:OnEnterUnLoaded(From,Event,To,DeployZone,TaskProcess)
self:E({From,Event,To,DeployZone,TaskProcess})
TaskProcess:__UnBoarded(-0.1)
end
if self.Cargo:IsAlive()then
self.Cargo:MessageToGroup("UnBoarding ...",TaskUnit:GetGroup())
if DeployZone then
self.Cargo:UnBoard(DeployZone:GetPointVec2(),400,self)
else
self.Cargo:UnBoard(TaskUnit:GetPointVec2():AddX(60),400,self)
end
end
end
function Fsm:onafterUnBoarded(TaskUnit,Task)
local TaskUnitName=TaskUnit:GetName()
self:E({TaskUnit=TaskUnitName,Task=Task and Task:GetClassNameAndID()})
self.Cargo:MessageToGroup("UnBoarded ...",TaskUnit:GetGroup())
TaskUnit:RemoveCargo(self.Cargo)
local NotInDeployZones=true
for DeployZoneName,DeployZone in pairs(Task.DeployZones)do
if self.Cargo:IsInZone(DeployZone)then
NotInDeployZones=false
end
end
if NotInDeployZones==false then
self.Cargo:SetDeployed(true)
end
Task:E({CargoDeployed=Task.CargoDeployed and"true"or"false"})
Task:E({CargoIsAlive=self.Cargo:IsAlive()and"true"or"false"})
if self.Cargo:IsAlive()then
if Task.CargoDeployed then
Task:CargoDeployed(TaskUnit,self.Cargo,self.DeployZone)
end
end
self:__SelectAction(1)
end
return self
end
function TASK_CARGO:SetCargoLimit(CargoLimit)
self.CargoLimit=CargoLimit
return self
end
function TASK_CARGO:SetSmokeColor(SmokeColor)
if SmokeColor==nil then
self.SmokeColor=SMOKECOLOR.Red
elseif type(SmokeColor)=="number"then
self:F2(SmokeColor)
if SmokeColor>0 and SmokeColor<=5 then
self.SmokeColor=SMOKECOLOR.SmokeColor
end
end
end
function TASK_CARGO:GetSmokeColor()
return self.SmokeColor
end
function TASK_CARGO:GetPlannedMenuText()
return self:GetStateString().." - "..self:GetTaskName().." ( "..self.TargetSetUnit:GetUnitTypesText().." )"
end
function TASK_CARGO:GetCargoSet()
return self.SetCargo
end
function TASK_CARGO:GetDeployZones()
return self.DeployZones
end
function TASK_CARGO:SetCargoPickup(Cargo,TaskUnit)
self:F({Cargo,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteCargo=ProcessUnit:GetProcess("RoutingToPickup","RouteToPickupPoint")
ActRouteCargo:Reset()
ActRouteCargo:SetCoordinate(Cargo:GetCoordinate())
ActRouteCargo:SetRange(Cargo:GetBoardingRange())
ActRouteCargo:SetMenuCancel(TaskUnit:GetGroup(),"Cancel Routing to Cargo "..Cargo:GetName(),TaskUnit.Menu)
ActRouteCargo:Start()
return self
end
function TASK_CARGO:SetDeployZone(DeployZone,TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteDeployZone=ProcessUnit:GetProcess("RoutingToDeploy","RouteToDeployZone")
ActRouteDeployZone:Reset()
ActRouteDeployZone:SetZone(DeployZone)
ActRouteDeployZone:SetMenuCancel(TaskUnit:GetGroup(),"Cancel Routing to Deploy Zone"..DeployZone:GetName(),TaskUnit.Menu)
ActRouteDeployZone:Start()
return self
end
function TASK_CARGO:AddDeployZone(DeployZone,TaskUnit)
self.DeployZones[DeployZone:GetName()]=DeployZone
return self
end
function TASK_CARGO:RemoveDeployZone(DeployZone,TaskUnit)
self.DeployZones[DeployZone:GetName()]=nil
return self
end
function TASK_CARGO:SetDeployZones(DeployZones,TaskUnit)
for DeployZoneID,DeployZone in pairs(DeployZones)do
self.DeployZones[DeployZone:GetName()]=DeployZone
end
return self
end
function TASK_CARGO:GetTargetZone(TaskUnit)
local ProcessUnit=self:GetUnitProcess(TaskUnit)
local ActRouteTarget=ProcessUnit:GetProcess("Engaging","RouteToTargetZone")
return ActRouteTarget:GetZone()
end
function TASK_CARGO:SetScoreOnProgress(Text,Score,TaskUnit)
self:F({Text,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScoreProcess("Engaging","Account","Account",Text,Score)
return self
end
function TASK_CARGO:SetScoreOnSuccess(Text,Score,TaskUnit)
self:F({Text,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Success",Text,Score)
return self
end
function TASK_CARGO:SetScoreOnFail(Text,Penalty,TaskUnit)
self:F({Text,Score,TaskUnit})
local ProcessUnit=self:GetUnitProcess(TaskUnit)
ProcessUnit:AddScore("Failed",Text,Penalty)
return self
end
function TASK_CARGO:SetGoalTotal()
self.GoalTotal=self.SetCargo:Count()
end
function TASK_CARGO:GetGoalTotal()
return self.GoalTotal
end
end
do
TASK_CARGO_TRANSPORT={
ClassName="TASK_CARGO_TRANSPORT",
}
function TASK_CARGO_TRANSPORT:New(Mission,SetGroup,TaskName,SetCargo,TaskBriefing)
local self=BASE:Inherit(self,TASK_CARGO:New(Mission,SetGroup,TaskName,SetCargo,"Transport",TaskBriefing))
self:F()
Mission:AddTask(self)
self:AddTransition("*","CargoPickedUp","*")
self:AddTransition("*","CargoDeployed","*")
self:E({CargoDeployed=self.CargoDeployed~=nil and"true"or"false"})
local Fsm=self:GetUnitProcess()
local CargoReport=REPORT:New("Transport Cargo. The following cargo needs to be transported including initial positions:")
SetCargo:ForEachCargo(
function(Cargo)
local CargoType=Cargo:GetType()
local CargoName=Cargo:GetName()
local CargoCoordinate=Cargo:GetCoordinate()
CargoReport:Add(string.format('- "%s" (%s) at %s',CargoName,CargoType,CargoCoordinate:ToStringMGRS()))
end
)
self:SetBriefing(
TaskBriefing or
CargoReport:Text()
)
return self
end
function TASK_CARGO_TRANSPORT:ReportOrder(ReportGroup)
return true
end
function TASK_CARGO_TRANSPORT:IsAllCargoTransported()
local CargoSet=self:GetCargoSet()
local Set=CargoSet:GetSet()
local DeployZones=self:GetDeployZones()
local CargoDeployed=true
for CargoID,CargoData in pairs(Set)do
local Cargo=CargoData
if Cargo:IsDeployed()then
for DeployZoneID,DeployZone in pairs(DeployZones)do
self:T({Cargo.CargoObject})
if Cargo:IsInZone(DeployZone)==false then
CargoDeployed=false
end
end
else
CargoDeployed=false
end
end
return CargoDeployed
end
function TASK_CARGO_TRANSPORT:onafterGoal(TaskUnit,From,Event,To)
local CargoSet=self.CargoSet
if self:IsAllCargoTransported()then
self:Success()
end
self:__Goal(-10)
end
end
_EVENTDISPATCHER=EVENT:New()
_SCHEDULEDISPATCHER=SCHEDULEDISPATCHER:New()
_DATABASE=DATABASE:New()
_SETTINGS=SETTINGS:Set()
BASE:TraceOnOff(false)
env.info('*** MOOSE INCLUDE END *** ')
