--- **Core** - Define any or all conditions to be evaluated.
--
-- **Main Features:**
--
--    * Add arbitrary numbers of conditon functions
--    * Evaluate *any* or *all* conditions
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Operation).
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ===
-- @module Core.Condition
-- @image MOOSE.JPG

--- CONDITON class.
-- @type CONDITION
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string name Name of the condition.
-- @field #boolean isAny General functions are evaluated as any condition.
-- @field #boolean negateResult Negate result of evaluation.
-- @field #boolean noneResult Boolean that is returned if no condition functions at all were specified.
-- @field #table functionsGen General condition functions.
-- @field #table functionsAny Any condition functions.
-- @field #table functionsAll All condition functions.
-- @field #number functionCounter Running number to determine the unique ID of condition functions.
-- @field #boolean defaultPersist Default persistence of condition functions.
-- 
-- @extends Core.Base#BASE

--- *Better three hours too soon than a minute too late.* - William Shakespeare
--
-- ===
--
-- # The CONDITION Concept
-- 
-- 
--
-- @field #CONDITION
CONDITION = {
  ClassName       = "CONDITION",
  lid             =   nil,
  functionsGen    =    {},
  functionsAny    =    {},
  functionsAll    =    {},
  functionCounter =     0, 
  defaultPersist  = false,
}

--- Condition function.
-- @type CONDITION.Function
-- @field #number uid Unique ID of the condition function.
-- @field #string type Type of the condition function: "gen", "any", "all".
-- @field #boolean persistence If `true`, this is persistent.
-- @field #function func Callback function to check for a condition. Must return a `#boolean`.
-- @field #table arg (Optional) Arguments passed to the condition callback function if any.

--- CONDITION class version.
-- @field #string version
CONDITION.version="0.3.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Make FSM. No sure if really necessary.
-- DONE: Option to remove condition functions.
-- DONE: Persistence option for condition functions.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new CONDITION object.
-- @param #CONDITION self
-- @param #string Name (Optional) Name used in the logs. 
-- @return #CONDITION self
function CONDITION:New(Name)

  -- Inherit BASE.
  local self=BASE:Inherit(self, BASE:New()) --#CONDITION
  
  self.name=Name or "Condition X"
  
  self:SetNoneResult(false)
  
  self.lid=string.format("%s | ", self.name)

  return self
end

--- Set that general condition functions return `true` if `any` function returns `true`. Default is that *all* functions must return `true`.
-- @param #CONDITION self
-- @param #boolean Any If `true`, *any* condition can be true. Else *all* conditions must result `true`.
-- @return #CONDITION self
function CONDITION:SetAny(Any)
  self.isAny=Any
  return self
end

--- Negate result.
-- @param #CONDITION self
-- @param #boolean Negate If `true`, result is negated else  not.
-- @return #CONDITION self
function CONDITION:SetNegateResult(Negate)
  self.negateResult=Negate
  return self
end

--- Set whether `true` or `false` is returned, if no conditions at all were specified. By default `false` is returned.
-- @param #CONDITION self
-- @param #boolean ReturnValue Returns this boolean.
-- @return #CONDITION self
function CONDITION:SetNoneResult(ReturnValue)
  if not ReturnValue then
    self.noneResult=false
  else
    self.noneResult=true
  end
  return self
end

--- Set whether condition functions are persistent, *i.e.* are removed.
-- @param #CONDITION self
-- @param #boolean IsPersistent If `true`, condition functions are persistent.
-- @return #CONDITION self
function CONDITION:SetDefaultPersistence(IsPersistent)
  self.defaultPersist=IsPersistent
  return self
end

--- Add a function that is evaluated. It must return a `#boolean` value, *i.e.* either `true` or `false` (or `nil`).
-- @param #CONDITION self
-- @param #function Function The function to call.
-- @param ... (Optional) Parameters passed to the function (if any).
-- 
-- @usage
-- local function isAequalB(a, b)
--   return a==b
-- end
-- 
-- myCondition:AddFunction(isAequalB, a, b)
-- 
-- @return #CONDITION.Function Condition function table.
function CONDITION:AddFunction(Function, ...)

  -- Condition function.
  local condition=self:_CreateCondition(0, Function, ...)

  -- Add to table.
  table.insert(self.functionsGen, condition)

  return condition
end

--- Add a function that is evaluated. It must return a `#boolean` value, *i.e.* either `true` or `false` (or `nil`).
-- @param #CONDITION self
-- @param #function Function The function to call.
-- @param ... (Optional) Parameters passed to the function (if any).
-- @return #CONDITION.Function Condition function table.
function CONDITION:AddFunctionAny(Function, ...)

  -- Condition function.
  local condition=self:_CreateCondition(1, Function, ...)

  -- Add to table.
  table.insert(self.functionsAny, condition)

  return condition
end

--- Add a function that is evaluated. It must return a `#boolean` value, *i.e.* either `true` or `false` (or `nil`).
-- @param #CONDITION self
-- @param #function Function The function to call.
-- @param ... (Optional) Parameters passed to the function (if any).
-- @return #CONDITION.Function Condition function table.
function CONDITION:AddFunctionAll(Function, ...)

  -- Condition function.
  local condition=self:_CreateCondition(2, Function, ...)

  -- Add to table.
  table.insert(self.functionsAll, condition)

  return condition
end

--- Remove a condition function.
-- @param #CONDITION self
-- @param #CONDITION.Function ConditionFunction The condition function to be removed.
-- @return #CONDITION self
function CONDITION:RemoveFunction(ConditionFunction)

  if ConditionFunction then
  
    local data=nil
    if ConditionFunction.type==0 then
      data=self.functionsGen
    elseif ConditionFunction.type==1 then
      data=self.functionsAny
    elseif ConditionFunction.type==2 then
      data=self.functionsAll
    end
    
    if data then
      for i=#data,1,-1 do
        local cf=data[i] --#CONDITION.Function
        if cf.uid==ConditionFunction.uid then
          self:T(self.lid..string.format("Removed ConditionFunction UID=%d", cf.uid))
          table.remove(data, i)
          return self
        end
      end
    end
  
  end

  return self
end

--- Remove all non-persistant condition functions.
-- @param #CONDITION self
-- @return #CONDITION self
function CONDITION:RemoveNonPersistant()

  for i=#self.functionsGen,1,-1 do
    local cf=self.functionsGen[i] --#CONDITION.Function
    if not cf.persistence then
      table.remove(self.functionsGen, i)
    end
  end 

  for i=#self.functionsAll,1,-1 do
    local cf=self.functionsAll[i] --#CONDITION.Function
    if not cf.persistence then
      table.remove(self.functionsAll, i)
    end
  end 

  for i=#self.functionsAny,1,-1 do
    local cf=self.functionsAny[i] --#CONDITION.Function
    if not cf.persistence then
      table.remove(self.functionsAny, i)
    end
  end 

  return self
end


--- Evaluate conditon functions.
-- @param #CONDITION self
-- @param #boolean AnyTrue If `true`, evaluation return `true` if *any* condition function returns `true`. By default, *all* condition functions must return true.
-- @return #boolean Result of condition functions.
function CONDITION:Evaluate(AnyTrue)

  -- Check if at least one function was given.
  if #self.functionsAll + #self.functionsAny + #self.functionsAll == 0 then
    return self.noneResult
  end

  -- Any condition for gen.
  local evalAny=self.isAny
  if AnyTrue~=nil then
    evalAny=AnyTrue
  end
  
  local isGen=nil
  if evalAny then
    isGen=self:_EvalConditionsAny(self.functionsGen)
  else
    isGen=self:_EvalConditionsAll(self.functionsGen)
  end
  
  -- Is any?
  local isAny=self:_EvalConditionsAny(self.functionsAny)
  
  -- Is all?
  local isAll=self:_EvalConditionsAll(self.functionsAll)
  
  -- Result.
  local result=isGen and isAny and isAll
  
  -- Negate result.
  if self.negateResult then
    result=not result
  end
  
  -- Debug message.
  self:T(self.lid..string.format("Evaluate: isGen=%s, isAny=%s, isAll=%s (negate=%s) ==> result=%s", tostring(isGen), tostring(isAny), tostring(isAll), tostring(self.negateResult), tostring(result)))

  return result
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if all given condition are true.
-- @param #CONDITION self
-- @param #table functions Functions to evaluate.
-- @return #boolean If true, all conditions were true (or functions was empty/nil). Returns false if at least one condition returned false.
function CONDITION:_EvalConditionsAll(functions)

  -- At least one condition?
  local gotone=false


  -- Any stop condition must be true.
  for _,_condition in pairs(functions or {}) do
    local condition=_condition --#CONDITION.Function

    -- At least one condition was defined.
    gotone=true

    -- Call function.
    local istrue=condition.func(unpack(condition.arg))

    -- Any false will return false.
    if not istrue then
      return false
    end

  end
  
  -- All conditions were true.
  return true
end


--- Check if any of the given conditions is true.
-- @param #CONDITION self
-- @param #table functions Functions to evaluate.
-- @return #boolean If true, at least one condition is true (or functions was emtpy/nil).
function CONDITION:_EvalConditionsAny(functions)

  -- At least one condition?
  local gotone=false

  -- Any stop condition must be true.
  for _,_condition in pairs(functions or {}) do
    local condition=_condition --#CONDITION.Function
    
    -- At least one condition was defined.
    gotone=true

    -- Call function.
    local istrue=condition.func(unpack(condition.arg))

    -- Any true will return true.
    if istrue then
      return true
    end

  end
  
  -- No condition was true.
  if gotone then
    return false
  else
    -- No functions passed.
    return true
  end
end

--- Create conditon function object.
-- @param #CONDITION self
-- @param #number Ftype Function type: 0=Gen, 1=All, 2=Any.
-- @param #function Function The function to call.
-- @param ... (Optional) Parameters passed to the function (if any).
-- @return #CONDITION.Function Condition function.
function CONDITION:_CreateCondition(Ftype, Function, ...)

  -- Increase counter.
  self.functionCounter=self.functionCounter+1

  local condition={} --#CONDITION.Function

  condition.uid=self.functionCounter
  condition.type=Ftype or 0
  condition.persistence=self.defaultPersist
  condition.func=Function
  condition.arg={}
  if arg then
    condition.arg=arg
  end
  
  return condition
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global Condition Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Condition to check if time is greater than a given threshold time.
-- @param #number Time Time in seconds.
-- @param #boolean Absolute If `true`, abs. mission time from `timer.getAbsTime()` is checked. Default is relative mission time from `timer.getTime()`.
-- @return #boolean Returns `true` if time is greater than give the time.
function CONDITION.IsTimeGreater(Time, Absolute)

  local Tnow=nil 
  
  if Absolute then
    Tnow=timer.getAbsTime()
  else
    Tnow=timer.getTime()
  end
  
  if Tnow>Time then
    return true
  else
    return false      
  end    

  return nil
end

--- Function that returns `true` (success) with a certain probability. For example, if you specify `Probability=80` there is an 80% chance that `true` is returned.
-- Technically, a random number between 0 and 100 is created. If the given success probability is less then this number, `true` is returned.
-- @param #number Probability Success probability in percent. Default 50 %.
-- @return #boolean Returns `true` for success and `false` otherwise.
function CONDITION.IsRandomSuccess(Probability)

  Probability=Probability or 50
  
  -- Create some randomness.
  math.random()
  math.random()
  math.random()

  -- Number between 0 and 100.
  local N=math.random()*100
  
  if N<Probability then
    return true
  else
    return false
  end

end

--- Function that returns always `true`
-- @return #boolean Returns `true` unconditionally.
function CONDITION.ReturnTrue()
  return true
end

--- Function that returns always `false`
-- @return #boolean Returns `false` unconditionally.
function CONDITION.ReturnFalse()
  return false
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------