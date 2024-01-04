--- **Functional** - Stratego.
--
-- **Main Features:**
--
--    * Helper class for mission designers to support classic capture-the-base scenarios.
--    * Creates a network of possible connections between bases (airbases, FARPs, Ships), Ports (defined as zones) and POIs (defined as zones).
--    * Assigns a strategic value to each of the resulting nodes.
--    * Can create a list of targets for your next mission move, both strategic and consolidation targets.
--    * Can be used with budgets to limit the target selection.
--    * Highly configureable.
--
-- ===
--
-- ### Author: **applevangelist**
-- 
-- @module Functional.Stratego
-- @image Stratego.png


---
--- **STRATEGO** class, extends Core.Base#BASE
-- @type STRATEGO
-- @field #string ClassName
-- @field #boolean debug
-- @field #string version
-- @field #number portweight
-- @field #number POIweight
-- @field #number maxrunways
-- @field #number coalition
-- @field #table colors
-- @field #table airbasetable
-- @field #table nonconnectedab
-- @field #table easynames
-- @field #number maxdist
-- @field #table disttable
-- @field #table routexists
-- @field #number routefactor
-- @field #table OpsZones
-- @field #number NeutralBenefit
-- @field #number Budget
-- @field #boolean usebudget
-- @field #number CaptureUnits
-- @field #number CaptureThreatlevel
-- @extends Core.Base#BASE


--- *If you see what is right and fail to act on it, you lack courage* --- Confucius
--
-- ===
--
-- # The STRATEGO Concept
--
-- STRATEGO is a helper class for mission designers. 
-- The basic idea is to create a network of nodes (bases) on the map, which each have a number of connections
-- to other nodes. The base value of each node is the number of runways of the base (the bigger the more important), or in the case of Ports and POIs, the assigned value points.
-- The strategic value of each base is determined by the number of routes going in and out of the node, where connections between more strategic nodes add a higher value to the
-- strategic value than connections to less valueable nodes.
-- 
-- ## Setup
-- 
-- Setup is map indepent and works automatically. All airbases, FARPS, and ships on the map are considered. **Note:** Later spawned objects are not considered at the moment.
--          
--          -- Setup and start STRATGEO for the blue side, maximal node distance is 100km
--          local Bluecher = STRATEGO:New("Bluecher",coalition.side.BLUE,100)
--          -- use budgets
--          Bluecher:SetUsingBudget(true,500)
--          -- draw on the map
--          Bluecher:SetDebug(true,true,true)
--          -- Start
--          Bluecher:Start()
-- 
-- ### Helper
-- 
-- @{#STRATEGO.SetWeights}(): Set weights for nodes and routes to determine their importance.
-- 
-- ### Hint
--          
-- Each node is its own @{Ops.OpsZone#OPSZONE} object to manage the coalition alignment of that node and how it can be conquered.
-- 
-- ### Distance
-- 
-- The node distance factor determines how many connections are there on the map. The smaller the lighter is the resulting net. The higher the thicker it gets, with more strategic options.
-- Play around with the distance to get an optimal map for your scenario.
-- 
-- One some maps, e.g. Syria, lower distance factors can create "islands" of unconnected network parts on the map. FARPs and POIs can bridge those gaps, or you can add routes manually.
-- 
-- @{#STRATEGO.AddRoutesManually}(): Add a route manually.
-- 
-- ## Ports and POIs
-- 
-- Ports and POIs are @{Core.Zone#ZONE} objects on the map with specfic values. Zones with the keywords "Port" or "POI" in the name are automatically considered at setup time.
--  
-- ## Get next possible targets
-- 
-- There are two types of possible target lists, strategic and consolidation. Targets closer to the start node are chosen as possible targets. 
-- 
-- 
--      * Strategic targets are of higher or equal base weight from a given start point. Can also be obtained for the whole net.
--      * Consoliation targets are of smaller or equal base weight from a given start point. Can also be obtained for the whole net.  
-- 
-- 
--  @{#STRATEGO.UpdateNodeCoalitions}(): Update alls node's coalition data before takign a decision.   
--  @{#STRATEGO.FindStrategicTargets}(): Find a list of possible strategic targets in the network of the enemy or neutral coalition.   
--  @{#STRATEGO.FindConsolidationTargets}(): Find a list of possible strategic targets in the network of the enemy or neutral coalition.     
--  @{#STRATEGO.FindAffordableStrategicTarget}(): When using budgets, find **one** strategic target you can afford.   
--  @{#STRATEGO.FindAffordableConsolidationTarget}(): When using budgets, find **one** consolidation target you can afford.   
--  @{#STRATEGO.FindClosestStrategicTarget}(): Find closest strategic target from a given start point.   
--  @{#STRATEGO.FindClosestConsolidationTarget}(): Find closest consolidation target from a given start point.   
--  @{#STRATEGO.GetHighestWeightNodes}(): Get a list of the nodes with the highest weight. Coalition independent.   
--  @{#STRATEGO.GetNextHighestWeightNodes}(): Get a list of the nodes a weight less than the give parameter. Coalition independent.   
-- 
--  
-- **How** you act on these suggestions is again totally up to your mission design.
--  
-- ## Using budgets
--  
--  Set up STRATEGO to use budgets to limit the target selection. **How** your side actually earns budgets is up to your mission design. However, when using budgets, a target will only be selected,
--  when you have more budget points available than the value points of the targeted base.
--  
--          -- use budgets
--          Bluecher:SetUsingBudget(true,500)
--  
-- ### Helpers:
-- 
--  
--  @{#STRATEGO.GetBudget}(): Get the current budget points.   
--  @{#STRATEGO.AddBudget}(): Add a number of budget points.   
--  @{#STRATEGO.SubtractBudget}(): Subtract a number of budget points.   
--  @{#STRATEGO.SetNeutralBenefit}(): Set neutral benefit, i.e. how many points it is cheaper to decide for a neutral vs an enemy node when taking decisions.   
-- 
--  
-- ## Functions to query a node's data
--  
--  
--  @{#STRATEGO.GetNodeBaseWeight}(): Get the base weight of a node by its name.   
--  @{#STRATEGO.GetNodeCoalition}(): Get the COALITION of a node by its name.   
--  @{#STRATEGO.GetNodeType}(): Get the TYPE of a node by its name.   
--  @{#STRATEGO.GetNodeZone}(): Get the ZONE of a node by its name.   
--  @{#STRATEGO.GetNodeOpsZone}(): Get the OPSZONE of a node by its name.   
--  @{#STRATEGO.GetNodeCoordinate}(): Get the COORDINATE of a node by its name.   
--  @{#STRATEGO.IsAirbase}(): Check if the TYPE of a node is AIRBASE.   
--  @{#STRATEGO.IsPort}(): Check if the TYPE of a node is PORT.   
--  @{#STRATEGO.IsPOI}(): Check if the TYPE of a node is POI.   
--  @{#STRATEGO.IsFARP}(): Check if the TYPE of a node is FARP.   
--  @{#STRATEGO.IsShip}(): Check if the TYPE of a node is SHIP.   
--  
--  
-- ## Various
--  
--  
--  @{#STRATEGO.FindNeighborNodes}(): Get neighbor nodes of a named node.   
--  @{#STRATEGO.FindRoute}(): Find a route between two nodes.   
--  @{#STRATEGO.SetCaptureOptions}(): Set how many units of which minimum threat level are needed to capture one node (i.e. the underlying OpsZone).   
--  @{#STRATEGO.SetDebug}(): Set debug and draw options.   
--
--
-- ## Visualisation example code for the Syria map:
-- 
--            local Bluecher = STRATEGO:New("Bluecher",coalition.side.BLUE,100)
--            Bluecher:SetDebug(true,true,true)
--            Bluecher:Start()
-- 
--            Bluecher:AddRoutesManually(AIRBASE.Syria.Beirut_Rafic_Hariri,AIRBASE.Syria.Larnaca)
--            Bluecher:AddRoutesManually(AIRBASE.Syria.Incirlik,AIRBASE.Syria.Hatay)
--            Bluecher:AddRoutesManually(AIRBASE.Syria.Incirlik,AIRBASE.Syria.Minakh)
--            Bluecher:AddRoutesManually(AIRBASE.Syria.King_Hussein_Air_College,AIRBASE.Syria.H4)
--            Bluecher:AddRoutesManually(AIRBASE.Syria.Sayqal,AIRBASE.Syria.At_Tanf)
-- 
--            local route = Bluecher:FindRoute(AIRBASE.Syria.Rosh_Pina,AIRBASE.Syria.Incirlik,5,true)
--            UTILS.PrintTableToLog(route,1)  
--          
-- @field #STRATEGO
STRATEGO = {
  ClassName = "STRATEGO",
  debug = false,
  drawzone = false,
  markzone = false,
  version = "0.2.1",
  portweight = 3,
  POIweight = 1,
  maxrunways = 3,
  coalition = nil,
  colors = nil,
  airbasetable = {},
  nonconnectedab = {},
  easynames = {},
  maxdist = 150, -- km
  disttable = {},
  routexists = {},
  routefactor = 5,
  OpsZones = {},
  NeutralBenefit = 100,
  Budget = 0,
  usebudget = false,
  CaptureUnits = 3,
  CaptureThreatlevel = 1,
}

---
-- @type STRATEGO.Data
-- @field #string name
-- @field #number baseweight
-- @field #number weight
-- @field #number coalition
-- @field #boolean port
-- @field Core.Zone#ZONE_RADIUS zone,
-- @field Core.Point#COORDINATRE coord
-- @field #string type
-- @field Ops.OpsZone#OPSZONE opszone

---
-- @type STRATEGO.DistData
-- @field #string start
-- @field #string target
-- @field #number dist 

---
-- @type STRATEGO.Target
-- @field #string name
-- @field #number dist
-- @field #number points
-- @field #number coalition
-- @field #string coalitionname  

---
-- @type STRATEGO.Type
-- @field #string AIRBASE
-- @field #string PORT
-- @field #string POI
-- @field #string FARP
-- @field #string SHIP
STRATEGO.Type = {
  AIRBASE = "AIRBASE",
  PORT = "PORT",
  POI = "POI",
  FARP = "FARP",
  SHIP = "SHIP",
}

--- [USER] Create a new STRATEGO object and start it up.
-- @param #STRATEGO self
-- @param #string Name Name of the Adviser.
-- @param #number Coalition Coalition, e.g. coalition.side.BLUE.
-- @param #number MaxDist Maximum distance of a single route in kilometers, defaults to 150.
-- @return #STRATEGO self 
function STRATEGO:New(Name,Coalition,MaxDist)
  -- Inherit everything from BASE class.
  local self = BASE:Inherit(self, BASE:New()) -- #STRATEGO
  
  self.coalition = Coalition
  self.coalitiontext = UTILS.GetCoalitionName(Coalition)
  self.name = Name or "Hannibal"
  
  self.maxdist = MaxDist or 150 -- km
  self.disttable = {}
  self.routexists = {}
  
  self.lid = string.format("STRATEGO %s %s | ",self.name,self.version) 
  
  self.bases = SET_AIRBASE:New():FilterOnce()
  self.ports = SET_ZONE:New():FilterPrefixes("Port"):FilterOnce()
  self.POIs = SET_ZONE:New():FilterPrefixes("POI"):FilterOnce()
  
  self.colors = {
      [1] = {0,1,0}, -- green
      [2] = {1,0,0}, -- red
      [3] = {0,0,1}, -- blue
      [4] = {1,0.65,0}, -- orange
    }
 
  return self
end

--- [USER] Do initial setup and get ready.
-- @param #STRATEGO self
-- @return #STRATEGO self
function STRATEGO:Start()
  self:T(self.lid.."Start")
  self:AnalyseBases()
  self:AnalysePOIs(self.ports,self.portweight,"PORT")
  self:AnalysePOIs(self.POIs,self.POIweight,"POI")
  
  for i=self.maxrunways,1,-1 do
  self:AnalyseRoutes(i,i*self.routefactor,self.colors[(i%3)+1],i)
  --self:AnalyseRoutes(2,2*self.routefactor,self.colors[2],2)
  --self:AnalyseRoutes(1,1*self.routefactor,self.colors[3],3)
  end
  self:AnalyseUnconnected(self.colors[4])
      
  self:I(self.lid.."Advisory ready.")
  return self
end

--- [USER] Set up usage of budget and set an initial budget in points.
-- @param #STRATEGO self
-- @param #boolean Usebudget If true, use budget for advisory calculations.
-- @param #number StartBudget Initial budget to be used, defaults to 500.
function STRATEGO:SetUsingBudget(Usebudget,StartBudget)
  self:T(self.lid.."SetUsingBudget")
  self.usebudget = Usebudget
  self.Budget = StartBudget
  return self
end

--- [USER] Set debugging.
-- @param #STRATEGO self
-- @param #boolean Debug If true, switch on debugging.
-- @param #boolean DrawZones If true, draw the OpsZones on the F10 map.
-- @param #boolean MarkZones if true, mark the OpsZones on the F10 map (with further information).
function STRATEGO:SetDebug(Debug,DrawZones,MarkZones)
  self.debug = Debug
  self.drawzone = DrawZones
  self.markzone = MarkZones
  return self
end

--- [USER] Set weights for nodes and routes to determine their importance.
-- @param #STRATEGO self
-- @param #number MaxRunways Set the maximum number of runways the big (equals strategic) airbases on the map have. Defaults to 3. The weight of an airbase node hence equals the number of runways.
-- @param #number PortWeight Set what weight a port node has. Defaults to 3.
-- @param #number POIWeight Set what weight a POI node has. Defaults to 1.
-- @param #number RouteFactor Defines which weight each route between two defined nodes gets: Weight * RouteFactor.
-- @return #STRATEGO self
function STRATEGO:SetWeights(MaxRunways,PortWeight,POIWeight,RouteFactor)
  self.portweight = PortWeight or 3
  self.POIweight = POIWeight or 1
  self.maxrunways = MaxRunways or 3
  self.routefactor = RouteFactor or 5
  return self
end

--- [USER] Set neutral benefit, i.e. how many points it is cheaper to decide for a neutral vs an enemy node when taking decisions.
-- @param #STRATEGO self
-- @param #number NeutralBenefit Pointsm defaults to 100.
-- @return #STRATEGO self
function STRATEGO:SetNeutralBenefit(NeutralBenefit)
  self.NeutralBenefit = NeutralBenefit or 100
  return self
end

--- [USER] Set how many units of which minimum threat level are needed to capture one node (i.e. the underlying OpsZone).
-- @param #STRATEGO self
-- @param #number CaptureUnits Number of units needed, defaults to three.
-- @param #number CaptureThreatlevel Threat level needed, can be 0..10, defaults to one.
-- @return #STRATEGO self
function STRATEGO:SetCaptureOptions(CaptureUnits,CaptureThreatlevel)
  self.CaptureUnits = CaptureUnits or 3
  self.CaptureThreatlevel = CaptureThreatlevel or 1
  return self
end

--- [INTERNAL] Analyse airbase setups
-- @param #STRATEGO self
-- @return #STRATEGO self
function STRATEGO:AnalyseBases()
  self:T(self.lid.."AnalyseBases")
  local colors = self.colors
  local debug = self.debug
  local airbasetable = self.airbasetable
  local nonconnectedab = self.nonconnectedab
  local easynames = self.easynames
  
  -- find bases with >= 1 runways
  self.bases:ForEach(
    function(afb)
      local ab = afb -- Wrapper.Airbase#AIRBASE
      local abname = ab:GetName()
      local runways = ab:GetRunways()
      local numrwys = #runways
      if numrwys >= 1 then numrwys = numrwys * 0.5 end    
      local abzone = ab:GetZone()
      local coa = ab:GetCoalition() + 1
      local abtype = "AIRBASE"
      if ab:IsShip() then
        numrwys = 1
        abtype = "SHIP"
      end
      if ab:IsHelipad() then 
        numrwys = 1
        abtype = "FARP"
      end
      local coord = abzone:GetCoordinate()
      if debug then
        abzone:DrawZone(-1,colors[coa],1,colors[coa],0.3,1)
        coord:TextToAll(tostring(numrwys),-1,{0,0,0},1,colors[coa],0.3,20)
      end
      local opszone = self:GetNewOpsZone(abname,coa-1)
      local tbl = {
        name = abname,
        baseweight = numrwys,
        weight = 0,
        coalition = coa-1,
        port = false,
        zone = abzone,
        coord = coord,
        type = abtype,
      }
      airbasetable[abname] = tbl
      nonconnectedab[abname] = true
      local name = string.gsub(abname,"[%p%s]",".")
      easynames[name]=abname
    end
  )
  return self
end

--- [INTERNAL] Update node coalitions
-- @param #STRATEGO self
-- @return #STRATEGO self
function STRATEGO:UpdateNodeCoalitions()
  self:T(self.lid.."UpdateNodeCoalitions")
  local newtable = {}
  for _id,_data in pairs(self.airbasetable) do
    local data = _data -- #STRATEGO.Data
    if data.type == "AIRBASE" or data.type == "FARP"  then
      data.coalition = AIRBASE:FindByName(data.name):GetCoalition()
    else
      data.coalition = data.opszone:GetOwner()
    end
    newtable[_id] = _data
  end
  self.airbasetable = nil
  self.airbasetable = newtable
  return self
end

--- [INTERNAL] Get an OpsZone from a Zone object.
-- @param #STRATEGO self
-- @param Core.Zone#ZONE Zone
-- @param #number Coalition
-- @return Ops.OpsZone#OPSZONE OpsZone
function STRATEGO:GetNewOpsZone(Zone,Coalition)
  self:T(self.lid.."GetNewOpsZone")
  local opszone = OPSZONE:New(Zone,Coalition or 0)
  opszone:SetCaptureNunits(self.CaptureUnits)
  opszone:SetCaptureThreatlevel(self.CaptureThreatlevel)
  opszone:SetDrawZone(self.drawzone)
  opszone:SetMarkZone(self.markzone)
  opszone:Start()
  return opszone
end

--- [INTERNAL] Analyse POI setups
-- @param #STRATEGO self
-- @return #STRATEGO self
function STRATEGO:AnalysePOIs(Set,Weight,Key)
  self:T(self.lid.."AnalysePOIs")
  local colors = self.colors
  local debug = self.debug
  local airbasetable = self.airbasetable
  local nonconnectedab = self.nonconnectedab
  local easynames = self.easynames
  Set:ForEach(
    function(port)
      local zone = port -- Core.Zone#ZONE_RADIUS
      local zname = zone:GetName()
      local coord = zone:GetCoordinate()
      if debug then
        zone:DrawZone(-1,colors[1],1,colors[1],0.3,1)
        coord:TextToAll(tostring(Weight),-1,{0,0,0},1,colors[1],0.3,20)
      end
      local opszone = self:GetNewOpsZone(zone)
      local tbl = { -- #STRATEGO.Data
        name = zname,
        baseweight = Weight,
        weight = 0,
        coalition = coalition.side.NEUTRAL,
        port = true,
        zone = zone,
        coord = coord,
        type = Key,
        opszone = opszone,
      }
      airbasetable[zone:GetName()] = tbl
      nonconnectedab[zone:GetName()] = true
      local name = string.gsub(zname,"[%p%s]",".")
      easynames[name]=zname
    end
  )
  return self
end

--- [INTERNAL] Get nice route text
-- @param #STRATEGO self
-- @return #STRATEGO self
function STRATEGO:GetToFrom(StartPoint,EndPoint)
  self:T(self.lid.."GetToFrom")
  local pstart = string.gsub(StartPoint,"[%p%s]",".")
  local pend = string.gsub(EndPoint,"[%p%s]",".")
  local fromto = pstart..";"..pend
  local tofrom = pend..";"..pstart
  return fromto, tofrom
end

--- [USER] Manually add a route, for e.g. Island hopping or to connect isolated networks. Use **after** STRATEGO has been started!
-- @param #STRATEGO self
-- @param #string Startpoint
-- @param #string Endpoint
-- @param #table Color (Optional) RGB color table {r, g, b}, e.g. {1,0,0} for red. Defaults to lila.
-- @param #number LineType (Optional) Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 5.
-- @param #boolean Draw (Optional) If true, draw route on the F10 map. Defaukt false.
-- @return #STRATEGO self
function STRATEGO:AddRoutesManually(Startpoint,Endpoint,Color,Linetype,Draw)
  local fromto,tofrom = self:GetToFrom(Startpoint,Endpoint)
  local startcoordinate = self.airbasetable[Startpoint].coord
  local targetcoordinate = self.airbasetable[Endpoint].coord
  local dist = UTILS.Round(targetcoordinate:Get2DDistance(startcoordinate),-2)/1000
  local color = Color or {136/255,0,1}
  local linetype = Linetype or 5
  local data = {
      start = Startpoint,
      target = Endpoint,
      dist = dist,
    }
  --table.insert(disttable,fromto,data)
  self.disttable[fromto] = data
  self.disttable[tofrom] = data
  --table.insert(disttable,tofrom,data)
  table.insert(self.routexists,fromto)
  table.insert(self.routexists,tofrom)
  self.nonconnectedab[Endpoint] = false
  self.nonconnectedab[Startpoint] = false
  local factor = self.airbasetable[Startpoint].baseweight*self.routefactor
  self.airbasetable[Startpoint].weight = self.airbasetable[Startpoint].weight+factor
  self.airbasetable[Endpoint].weight = self.airbasetable[Endpoint].weight+factor
  if self.debug or Draw then
    startcoordinate:LineToAll(targetcoordinate,-1,color,1,linetype,nil,string.format("%dkm",dist))
  end
  return self
end

--- [INTERNAL] Analyse routes
-- @param #STRATEGO self
-- @return #STRATEGO self
function STRATEGO:AnalyseRoutes(tgtrwys,factor,color,linetype)
  self:T(self.lid.."AnalyseRoutes")
  for _,_ab in pairs(self.airbasetable) do
    if _ab.baseweight >= 1 then
      local startpoint = _ab.name
      local startcoord = _ab.coord
      for _,_data in pairs(self.airbasetable) do
        local fromto,tofrom = self:GetToFrom(startpoint,_data.name) 
        if _data.name == startpoint then
          -- sam as we
        elseif _data.baseweight == tgtrwys and not (self.routexists[fromto] or self.routexists[tofrom]) then
          local tgtc = _data.coord
          local dist = UTILS.Round(tgtc:Get2DDistance(startcoord),-2)/1000
          if dist <= self.maxdist then
            --local text = string.format("Distance %s to %s is %dkm",startpoint,_data.name,dist)
            --MESSAGE:New(text,10):ToLog()
            local data = {
              start = startpoint,
              target = _data.name,
              dist = dist,
            }
            --table.insert(disttable,fromto,data)
            self.disttable[fromto] = data
            self.disttable[tofrom] = data
            --table.insert(disttable,tofrom,data)
            table.insert(self.routexists,fromto)
            table.insert(self.routexists,tofrom)
            self.nonconnectedab[_data.name] = false
            self.nonconnectedab[startpoint] = false
            self.airbasetable[startpoint].weight = self.airbasetable[startpoint].weight+factor
            self.airbasetable[_data.name].weight = self.airbasetable[_data.name].weight+factor
            if self.debug then
              startcoord:LineToAll(tgtc,-1,color,1,linetype,nil,string.format("%dkm",dist))
            end
          end
        end
      end
    end
  end
  return self
end

--- [INTERNAL] Analyse non-connected points.
-- @param #STRATEGO self
-- @param #table Color RGB color to be used.
-- @return #STRATEGO self
function STRATEGO:AnalyseUnconnected(Color)
  self:T(self.lid.."AnalyseUnconnected")
  -- Non connected ones
  for _name,_noconnect in pairs(self.nonconnectedab) do
    if _noconnect then
      -- Find closest connected airbase
      local startpoint = _name
      local startcoord = self.airbasetable[_name].coord
      local shortest = 1000*1000
      local closest = nil
      local closestcoord = nil
      for _,_data in pairs(self.airbasetable) do
        if _name ~= _data.name then
          --local tgt = AIRBASE:FindByName(_data.name)
          local tgtc = _data.coord
          local dist = UTILS.Round(tgtc:Get2DDistance(startcoord),-2)/1000
          if dist < shortest and self.nonconnectedab[_data.name] == false then
            --local text = string.format("Distance %s to %s is %dkm",startpoint,_data.name,dist)
            shortest = dist
            closest = _data.name
            closestcoord = tgtc
            --MESSAGE:New(text,10):ToLog():ToAll()
          end
        end
      end
      if closest then
       if self.debug then
        startcoord:LineToAll(closestcoord,-1,Color,1,3,nil,string.format("%dkm",shortest))
       end
       self.airbasetable[startpoint].weight = self.airbasetable[startpoint].weight+1
       self.airbasetable[closest].weight = self.airbasetable[closest].weight+1
       local data = {
          start = startpoint,
          target = closest,
          dist = shortest,
        }
        local fromto,tofrom = self:GetToFrom(startpoint,closest)    
        self.disttable[fromto] = data
        self.disttable[tofrom] = data
       table.insert(self.routexists,fromto)
       table.insert(self.routexists,tofrom)
      end
    end
  end
  return self
end

--- [USER] Get a list of the nodes with the highest weight.
-- @param #STRATEGO self
-- @return #table Table of nodes.
-- @return #number Weight The consolidated weight associated with the nodes.
function STRATEGO:GetHighestWeightNodes()
  self:T(self.lid.."GetHighestWeightBases")
  local weight = 0
  local airbases = {}
  for _name,_data in pairs(self.airbasetable) do
    if _data.weight >= weight then
      weight = _data.weight
      if not airbases[weight] then airbases[weight]={} end
      table.insert(airbases[weight],_name)
    end
  end
  return airbases[weight],weight
end

--- [USER] Get a list of the nodes a weight less than the give parameter.
-- @param #STRATEGO self
-- @return #table Table of nodes.
-- @return #number Weight The consolidated weight associated with the nodes.
function STRATEGO:GetNextHighestWeightNodes(Weight)
  self:T(self.lid.."GetNextHighestWeightBases")
  local weight = 0
  local airbases = {}
  for _name,_data in pairs(self.airbasetable) do
    if _data.weight >= weight and _data.weight < Weight then
      weight = _data.weight
      if not airbases[weight] then airbases[weight]={} end
      table.insert(airbases[weight],_name)
    end
  end
  return airbases[weight],weight
end

--- [USER] Get the aggregated weight of a node by its name.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #number Weight The weight or 0 if not found.
function STRATEGO:GetNodeWeight(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].weight or 0
  else
    return 0
  end
end

--- [USER] Get the base weight of a node by its name.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #number Weight The base weight or 0 if not found.
function STRATEGO:GetNodeBaseWeight(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].baseweight or 0
  else
    return 0
  end
end

--- [USER] Get the COALITION of a node by its name.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #number Coalition The coalition.
function STRATEGO:GetNodeCoalition(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].coalition or coalition.side.NEUTRAL
  else
    return coalition.side.NEUTRAL
  end
end

--- [USER] Get the TYPE of a node by its name.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #string Type Type of the node, e.g. STRATEGO.Type.AIRBASE or nil if not found.
function STRATEGO:GetNodeType(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].type
  else
    return nil
  end
end

--- [USER] Get the ZONE of a node by its name.
-- @param #STRATEGO self
-- @param #string Name.
-- @return Core.Zone#ZONE Zone The Zone of the node or nil if not found.
function STRATEGO:GetNodeZone(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].zone
  else
    return nil
  end
end

--- [USER] Get the OPSZONE of a node by its name.
-- @param #STRATEGO self
-- @param #string Name.
-- @return Ops.OpsZone#OPSZONE OpsZone The OpsZone of the node or nil if not found.
function STRATEGO:GetNodeOpsZone(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].opszone
  else
    return nil
  end
end

--- [USER] Get the COORDINATE of a node by its name.
-- @param #STRATEGO self
-- @param #string Name.
-- @return Core.Point#COORDINATE Coordinate The Coordinate of the node or nil if not found.
function STRATEGO:GetNodeCoordinate(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].coord
  else
    return nil
  end
end

--- [USER] Check if the TYPE of a node is AIRBASE.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #boolean Outcome
function STRATEGO:IsAirbase(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].type == STRATEGO.Type.AIRBASE
  else
    return false
  end
end

--- [USER] Check if the TYPE of a node is PORT.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #boolean Outcome
function STRATEGO:IsPort(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].type == STRATEGO.Type.PORT
  else
    return false
  end
end

--- [USER] Check if the TYPE of a node is POI.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #boolean Outcome
function STRATEGO:IsPOI(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].type == STRATEGO.Type.POI
  else
    return false
  end
end

--- [USER] Check if the TYPE of a node is FARP.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #boolean Outcome
function STRATEGO:IsFARP(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].type == STRATEGO.Type.FARP
  else
    return false
  end
end

--- [USER] Check if the TYPE of a node is SHIP.
-- @param #STRATEGO self
-- @param #string Name.
-- @return #boolean Outcome
function STRATEGO:IsShip(Name)
  if Name and self.airbasetable[Name] then
    return self.airbasetable[Name].type == STRATEGO.Type.SHIP
  else
    return false
  end
end

--- [USER] Get the next best consolidation target node with a lower BaseWeight.
-- @param #STRATEGO self
-- @param #string Startpoint Name of start point.
-- @param #number BaseWeight Base weight of the node, i.e. the number of runways of an airbase or the weight of ports or POIs.
-- @return #number ShortestDist Shortest distance found.
-- @return #string Name Name of the target node.
-- @return #number Weight Consolidated weight of the target node, zero if none found.
-- @return #number Coalition Coaltion of the target.
function STRATEGO:FindClosestConsolidationTarget(Startpoint,BaseWeight)
  self:T(self.lid.."FindClosestConsolidationTarget for "..Startpoint.." Weight "..BaseWeight or 0)
  -- find existing routes
  local shortest = 1000*1000
  local target = nil
  local weight = 0
  local coa = nil
  if not BaseWeight then BaseWeight = self.maxrunways-1 end
  local startpoint = string.gsub(Startpoint,"[%p%s]",".")
  for _,_route in pairs(self.routexists) do
    if string.find(_route,startpoint,1,true) then
      --BASE:I({_route,startpoint})
      local dist = self.disttable[_route].dist
      local tname = string.gsub(_route,startpoint,"")
      local tname = string.gsub(tname,";","")
      local cname = self.easynames[tname]
      local targetweight = self.airbasetable[cname].baseweight
      coa = self.airbasetable[cname].coalition
      if (dist < shortest) and  (coa ~= self.coalition) and (BaseWeight >= targetweight) then
        shortest = dist
        target = cname
        weight = self.airbasetable[cname].weight
        coa = self.airbasetable[cname].coalition
      end
    end
  end
  return shortest,target, weight, coa
end

--- [USER] Get the next best strategic target node with same or higher BaseWeight.
-- @param #STRATEGO self
-- @param #string Startpoint Name of start point.
-- @param #number BaseWeight Base weight of the node, e.g. the number of runways of an airbase or the weight of ports or POIs.
-- @return #number ShortestDist Shortest distance found.
-- @return #string Name Name of the target node.
-- @return #number Weight Consolidated weight of the target node, zero if none found.
-- @return #number Coalition Coaltion of the target.
function STRATEGO:FindClosestStrategicTarget(Startpoint,BaseWeight)
  self:T(self.lid.."FindClosestStrategicTarget")
  -- find existing routes
  local shortest = 1000*1000
  local target = nil
  local weight = 0
  local coa = nil
  if not BaseWeight then BaseWeight = self.maxrunways end
  local startpoint = string.gsub(Startpoint,"[%p%s]",".")
  for _,_route in pairs(self.routexists) do 
    if string.find(_route,startpoint,1,true) then
      local dist = self.disttable[_route].dist
      local tname = string.gsub(_route,startpoint,"")
      local tname = string.gsub(tname,";","")
      local cname = self.easynames[tname]
      if dist < shortest and self.airbasetable[cname].coalition ~= self.coalition and self.airbasetable[cname].baseweight >= BaseWeight then
        shortest = dist
        target = cname
        weight = self.airbasetable[cname].weight
        coa = self.airbasetable[cname].coalition
      end
    end
  end
  return shortest,target,weight, coa
end

--- [USER] Get the next best strategic target nodes in the network.
-- @param #STRATEGO self
-- @return #table of #STRATEGO.Target data points
function STRATEGO:FindStrategicTargets()
  local targets = {}
  for _,_data in pairs(self.airbasetable) do
    local data = _data -- #STRATEGO.Data
    if data.coalition == self.coalition then
      local dist, name, points, coa = self:FindClosestStrategicTarget(data.name,self.maxrunways)
      if coa == coalition.side.NEUTRAL and points ~= 0 then
        local fpoints = points + self.NeutralBenefit
        local tries = 1
        while targets[fpoints] or tries < 100 do
          fpoints = points + (self.NeutralBenefit+math.random(1,100))
          tries = tries + 1
        end
        targets[fpoints] = {
          name = name,
          dist = dist,
          points = fpoints,
          coalition = coa,  
          }
      end
      local enemycoa = self.coalition == coalition.side.BLUE and coalition.side.RED or coalition.side.BLUE
      if coa == enemycoa and points ~= 0 then
        local fpoints = points
        local tries = 1
        while targets[fpoints] or tries < 100 do
          fpoints = points + (math.random(1,100))
          tries = tries + 1
        end
        targets[fpoints] = {
          name = name,
          dist = dist,
          points = fpoints,
          coalition = coa,  
          }
      end
    end
  end
  return targets
end

--- [USER] Get the next best consolidation target nodes in the network.
-- @param #STRATEGO self
-- @return #table of #STRATEGO.Target data points
function STRATEGO:FindConsolidationTargets()
  local targets = {}
  for _,_data in pairs(self.airbasetable) do
    local data = _data -- #STRATEGO.Data
    if data.coalition == self.coalition then
      local dist, name, points, coa = self:FindClosestConsolidationTarget(data.name,self.maxrunways-1)
      if coa == coalition.side.NEUTRAL and points ~= 0 then
        local fpoints = points + self.NeutralBenefit
        local tries = 1
        while targets[fpoints] or tries < 100 do
          fpoints = points - (self.NeutralBenefit+math.random(1,100))
          tries = tries + 1
        end
        targets[fpoints] = {
          name = name,
          dist = dist,
          points = fpoints,
          coalition = coa,
          coalitionname = UTILS.GetCoalitionName(coa),
          }
      end
      local enemycoa = self.coalition == coalition.side.BLUE and coalition.side.RED or coalition.side.BLUE
      if coa == enemycoa and points ~= 0 then
        local fpoints = points
        local tries = 1
        while targets[fpoints] or tries < 100 do
          fpoints = points - (math.random(1,100))
          tries = tries + 1
        end
        targets[fpoints] = {
          name = name,
          dist = dist,
          points = fpoints,
          coalition = coa,
          coalitionname = UTILS.GetCoalitionName(coa),  
          }
      end
    end
  end
  return targets
end

--- [USER] Get neighbor nodes of a named node.
-- @param #STRATEGO self
-- @param #string Name The name to search the neighbors for.
-- @param #boolean Enemies (optional) If true, find only enemy neighbors.
-- @param #boolean Friends (optional) If true, find only friendly or neutral neighbors.
-- @return #table Neighbors Table of #STRATEGO.DistData entries indexed by neighbor node names.
function STRATEGO:FindNeighborNodes(Name,Enemies,Friends)
  local neighbors = {}
  local name = string.gsub(Name,"[%p%s]",".")
  for _route,_data in pairs(self.disttable) do
    if string.find(_route,name,1,true) then
      local dist = self.disttable[_route] -- #STRATEGO.DistData
      local tname = string.gsub(_route,name,"")
      local tname = string.gsub(tname,";","")
      local cname = self.easynames[tname] -- name of target
      local encoa = self.coalition == coalition.side.BLUE and coalition.side.RED or coalition.side.BLUE
      if Enemies == true then
        if self.airbasetable[cname].coalition == encoa then
         neighbors[cname] = dist
        end
      elseif Friends == true then
        if self.airbasetable[cname].coalition ~= encoa then
         neighbors[cname] = dist
        end
      else
        neighbors[cname] = dist
      end
    end
  end
  return neighbors
end

--- [USER] Find a route between two nodes.
-- @param #STRATEGO self
-- @param #string Start The name of the start node.
-- @param #string End The name of the end node.
-- @param #number Hops Max iterations to find a route.
-- @param #boolean Draw If true, draw the route on the map.
-- @return #table Route Table of #string name entries of the route
-- @return #boolean Complete If true, the route was found end-to-end.
function STRATEGO:FindRoute(Start,End,Hops,Draw)
  self:I({Start,End,Hops})
  --local bases = UTILS.DeepCopy(self.airbasetable)
  local Route = {}  
  local hops = Hops or 4
  local routecomplete = false
  
  local function Checker(neighbors)
    for _name,_data in pairs(neighbors) do
      if _name == End then
        -- found it
        return End
      end
    end
    return nil
  end
  
  local function NextClosest(Start,End)
    local ecoord = self.airbasetable[End].coord
    local nodes = self:FindNeighborNodes(Start)
    local closest = nil
    local closedist = 1000*1000
    for _name,_dist in pairs(nodes) do
      local kcoord = self.airbasetable[_name].coord
      local dist = math.floor((kcoord:Get2DDistance(ecoord)/1000)+0.5)
      if dist < closedist then
        closedist = dist
        closest = _name
      end
    end
    if closest then
      --MESSAGE:New(string.format("Start %s | End %s | Nextclosest %s",Start,End,closest),10,"STRATEGO"):ToLog():ToAll()
      return closest
    end
  end
  
  local function DrawRoute(Route)
    for i=1,#Route-1 do
      local p1=Route[i]
      local p2=Route[i+1]
      local c1 = self.airbasetable[p1].coord -- Core.Point#COORDINATE
      local c2 = self.airbasetable[p2].coord -- Core.Point#COORDINATE
      c1:LineToAll(c2,-1,{0,0,0},1,6)
    end
  end
  
  -- One hop
  Route[#Route+1] = Start
  local nodes = self:FindNeighborNodes(Start)
  local endpoint = Checker(nodes)
  
  if endpoint then
    Route[#Route+1] = endpoint
    routecomplete = true
  else
    local spoint = Start
    for i=1,hops do
      local Next = NextClosest(spoint,End)
      if Next then
        Route[#Route+1] = Next
        local nodes = self:FindNeighborNodes(Next)
        local endpoint = Checker(nodes)
        if endpoint then
          Route[#Route+1] = endpoint
          routecomplete = true
          break
        else
          spoint = Next
        end
      end
    end
  end
  if self.debug or Draw then DrawRoute(Route) end 
  return Route, routecomplete
end

--- [USER] Add budget points.
-- @param #STRATEGO self
-- @param #number Number of points to add.
-- @return #STRATEGO self
function STRATEGO:AddBudget(Number)
  self.Budget = self.Budget + Number
  return self
end

--- [USER] Subtract budget points.
-- @param #STRATEGO self
-- @param #number Number of points to subtract.
-- @return #STRATEGO self
function STRATEGO:SubtractBudget(Number)
  self.Budget = self.Budget - Number
  return self
end

--- [USER] Get budget points.
-- @param #STRATEGO self
-- @return #number budget
function STRATEGO:GetBudget()
  return self.Budget
end

--- [USER] Find **one** affordable strategic target.
-- @param #STRATEGO self
-- @return #table Target Table with #STRATEGO.Target data or nil if none found.
function STRATEGO:FindAffordableStrategicTarget()
  local targets = self:FindStrategicTargets() -- #table of #STRATEGO.Target
  local budget = self.Budget
  --local leftover = self.Budget
  local target = nil -- #STRATEGO.Target
  local Targets = {}
  for _,_data in pairs(targets) do
    local data = _data -- #STRATEGO.Target
    --if data.points <= budget and budget-data.points < leftover then
    if data.points <= budget then
      --leftover = budget-data.points
      table.insert(Targets,data)
      self:T(self.lid.."Affordable strategic target: "..data.name)
    end
  end
  if not targets then
    self:T(self.lid.."No suitable target found!")
    return nil
  end
  target = Targets[math.random(1,#Targets)]
  if target then
    self:T(self.lid.."Final affordable strategic target: "..target.name)
    return target
  else
   return nil
  end
end

--- [USER] Find **one** affordable consolidation target.
-- @param #STRATEGO self
-- @return #table Target Table with #STRATEGO.Target data or nil if none found.
function STRATEGO:FindAffordableConsolidationTarget()
  local targets = self:FindConsolidationTargets() -- #table of #STRATEGO.Target
  local budget = self.Budget
  --local leftover = self.Budget
  local target = nil -- #STRATEGO.Target
  local Targets = {}
  for _,_data in pairs(targets) do
    local data = _data -- #STRATEGO.Target
    --if data.points <= budget and budget-data.points < leftover then
    if data.points <= budget then
      --leftover = budget-data.points
      table.insert(Targets,data)
      self:T(self.lid.."Affordable consolidation target: "..data.name)
    end
  end
  if not targets then
    self:T(self.lid.."No suitable target found!")
    return nil
  end
  target = Targets[math.random(1,#Targets)]
  if target then
    self:T(self.lid.."Final affordable consolidation target: "..target.name)
    return target
  else
    return nil
  end
end

---------------------------------------------------------------------------------------------------------------
--
-- End
-- 
---------------------------------------------------------------------------------------------------------------
