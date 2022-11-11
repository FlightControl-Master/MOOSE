---  **UTILS** - Classic FiFo Stack.
--
-- ===
--
-- ## Main Features:
--
--    * Build a simple multi-purpose FiFo (First-In, First-Out) stack for generic data.
--    * [Wikipedia](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)
--
-- ===
--
-- ### Author: **applevangelist**
-- @module Utilities.FiFo
-- @image MOOSE.JPG

-- Date: April 2022

do
--- FIFO class.
-- @type FIFO
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string version Version of FiFo.
-- @field #number counter Counter.
-- @field #number pointer Pointer.
-- @field #table stackbypointer Stack by pointer.
-- @field #table stackbyid Stack by ID.
-- @extends Core.Base#BASE

---
-- @type FIFO.IDEntry
-- @field #number pointer
-- @field #table data
-- @field #table uniqueID

---
-- @field #FIFO
FIFO = {
  ClassName = "FIFO",
  lid = "",
  version = "0.0.5",
  counter = 0,
  pointer = 0,
  stackbypointer = {},
  stackbyid = {}
}

--- Instantiate a new FIFO Stack.
-- @param #FIFO self
-- @return #FIFO self
function FIFO:New()
  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) --#FIFO
  self.pointer = 0
  self.counter = 0
  self.stackbypointer = {}
  self.stackbyid = {}
  self.uniquecounter = 0
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", "FiFo", self.version)
  self:T(self.lid .."Created.") 
  return self
end

--- Empty FIFO Stack.
-- @param #FIFO self
-- @return #FIFO self
function FIFO:Clear()
  self:T(self.lid.."Clear")
  self.pointer = 0
  self.counter = 0
  self.stackbypointer = nil
  self.stackbyid = nil
  self.stackbypointer = {}
  self.stackbyid = {}
  self.uniquecounter = 0
  return self
end

--- FIFO Push Object to Stack.
-- @param #FIFO self
-- @param #table Object
-- @param #string UniqueID (optional) - will default to current pointer + 1. Note - if you intend to use `FIFO:GetIDStackSorted()` keep the UniqueID numerical!
-- @return #FIFO self
function FIFO:Push(Object,UniqueID)
  self:T(self.lid.."Push")
  self:T({Object,UniqueID})
  self.pointer = self.pointer + 1 
  self.counter = self.counter + 1
  local uniID = UniqueID
  if not UniqueID then
    self.uniquecounter = self.uniquecounter + 1
    uniID = self.uniquecounter
  end
  self.stackbyid[uniID] = { pointer = self.pointer, data = Object, uniqueID = uniID }
  self.stackbypointer[self.pointer] = { pointer = self.pointer, data = Object, uniqueID = uniID }
  return self
end

--- FIFO Pull Object from Stack.
-- @param #FIFO self
-- @return #table Object or nil if stack is empty
function FIFO:Pull()
  self:T(self.lid.."Pull")
  if self.counter == 0 then return nil end
  --local object = self.stackbypointer[self.pointer].data
  --self.stackbypointer[self.pointer] = nil
  local object = self.stackbypointer[1].data
  self.stackbypointer[1] = nil
  self.counter = self.counter - 1
  --self.pointer = self.pointer - 1
  self:Flatten()
  return object
end

--- FIFO Pull Object from Stack by Pointer
-- @param #FIFO self
-- @param #number Pointer
-- @return #table Object or nil if stack is empty
function FIFO:PullByPointer(Pointer)
  self:T(self.lid.."PullByPointer " .. tostring(Pointer))
  if self.counter == 0 then return nil end
  local object = self.stackbypointer[Pointer] -- #FIFO.IDEntry
  self.stackbypointer[Pointer] = nil
  if object then self.stackbyid[object.uniqueID] = nil end
  self.counter = self.counter - 1
  self:Flatten()
  if object then
    return object.data
  else
    return nil
  end
end


--- FIFO Read, not Pull, Object from Stack by Pointer
-- @param #FIFO self
-- @param #number Pointer
-- @return #table Object or nil if stack is empty or pointer does not exist
function FIFO:ReadByPointer(Pointer)
  self:T(self.lid.."ReadByPointer " .. tostring(Pointer))
  if self.counter == 0 or not Pointer or not self.stackbypointer[Pointer]  then return nil end
  local object = self.stackbypointer[Pointer] -- #FIFO.IDEntry
  if object then
    return object.data
  else
    return nil
  end
end

--- FIFO Read, not Pull, Object from Stack by UniqueID
-- @param #FIFO self
-- @param #number UniqueID
-- @return #table Object data or nil if stack is empty or ID does not exist
function FIFO:ReadByID(UniqueID)
  self:T(self.lid.."ReadByID " .. tostring(UniqueID))
  if self.counter == 0 or not UniqueID or not self.stackbyid[UniqueID]  then return nil end
  local object = self.stackbyid[UniqueID] -- #FIFO.IDEntry
  if object then
    return object.data
  else
    return nil
  end
end

--- FIFO Pull Object from Stack by UniqueID
-- @param #FIFO self
-- @param #tableUniqueID
-- @return #table Object or nil if stack is empty
function FIFO:PullByID(UniqueID)
  self:T(self.lid.."PullByID " .. tostring(UniqueID))
  if self.counter == 0 then return nil end
  local object = self.stackbyid[UniqueID] -- #FIFO.IDEntry
  --self.stackbyid[UniqueID] = nil
  if object then
    return self:PullByPointer(object.pointer)
  else
    return nil
  end
end

--- FIFO Housekeeping
-- @param #FIFO self
-- @return #FIFO self
function FIFO:Flatten()
  self:T(self.lid.."Flatten")
  -- rebuild stacks
  local pointerstack = {}
  local idstack = {}
  local counter = 0
  for _ID,_entry in pairs(self.stackbypointer) do
    counter = counter + 1
    pointerstack[counter] = { pointer = counter, data = _entry.data, uniqueID = _entry.uniqueID}
  end
  for _ID,_entry in pairs(pointerstack) do
      idstack[_entry.uniqueID] = { pointer = _entry.pointer , data = _entry.data, uniqueID = _entry.uniqueID}
  end
  self.stackbypointer = nil
  self.stackbypointer = pointerstack
  self.stackbyid = nil
  self.stackbyid = idstack
  self.counter = counter
  self.pointer = counter
  return self
end

--- FIFO Check Stack is empty
-- @param #FIFO self
-- @return #boolean empty
function FIFO:IsEmpty()
  self:T(self.lid.."IsEmpty")
  return self.counter == 0 and true or false
end

--- FIFO Get stack size
-- @param #FIFO self
-- @return #number size
function FIFO:GetSize()
  self:T(self.lid.."GetSize")
  return self.counter
end

--- FIFO Get stack size
-- @param #FIFO self
-- @return #number size
function FIFO:Count()
  self:T(self.lid.."Count")
  return self.counter
end

--- FIFO Check Stack is NOT empty
-- @param #FIFO self
-- @return #boolean notempty
function FIFO:IsNotEmpty()
  self:T(self.lid.."IsNotEmpty")
  return not self:IsEmpty()
end

--- FIFO Get the data stack by pointer
-- @param #FIFO self
-- @return #table Table of #FIFO.IDEntry entries
function FIFO:GetPointerStack()
  self:T(self.lid.."GetPointerStack")
  return self.stackbypointer
end

--- FIFO Check if a certain UniqeID exists
-- @param #FIFO self
-- @return #boolean exists
function FIFO:HasUniqueID(UniqueID)
  self:T(self.lid.."HasUniqueID")
  if self.stackbyid[UniqueID] ~= nil then
    return true
  else
    return false
  end
end

--- FIFO Get the data stack by UniqueID
-- @param #FIFO self
-- @return #table Table of #FIFO.IDEntry entries
function FIFO:GetIDStack()
  self:T(self.lid.."GetIDStack")
  return self.stackbyid
end

--- FIFO Get table of UniqueIDs sorted smallest to largest
-- @param #FIFO self
-- @return #table Table with index [1] to [n] of UniqueID entries
function FIFO:GetIDStackSorted()
  self:T(self.lid.."GetIDStackSorted")
  
  local stack = self:GetIDStack()
  local idstack = {}
  for _id,_entry in pairs(stack) do
    idstack[#idstack+1] = _id
    
    self:T({"pre",_id})
  end
  
  local function sortID(a, b)
      return a < b
  end
  
  table.sort(idstack)
 
  return idstack
end

--- FIFO Get table of data entries
-- @param #FIFO self
-- @return #table Raw table indexed [1] to [n] of object entries - might be empty!
function FIFO:GetDataTable()
  self:T(self.lid.."GetDataTable")
  local datatable = {}
  for _,_entry in pairs(self.stackbypointer) do
    datatable[#datatable+1] = _entry.data
  end
  return datatable
end

--- FIFO Get sorted table of data entries by UniqueIDs (must be numerical UniqueIDs only!)
-- @param #FIFO self
-- @return #table Table indexed [1] to [n] of sorted object entries - might be empty!
function FIFO:GetSortedDataTable()
  self:T(self.lid.."GetSortedDataTable")
  local datatable = {}
  local idtablesorted = self:GetIDStackSorted()
  for _,_entry in pairs(idtablesorted) do
    datatable[#datatable+1] = self:ReadByID(_entry)
  end
  return datatable
end

--- Iterate the FIFO and call an iterator function for the given FIFO data, providing the object for each element of the stack and optional parameters.
-- @param #FIFO self
-- @param #function IteratorFunction The function that will be called.
-- @param #table Arg (Optional) Further Arguments of the IteratorFunction.
-- @param #function Function (Optional) A function returning a #boolean true/false. Only if true, the IteratorFunction is called.
-- @param #table FunctionArguments (Optional) Function arguments.
-- @return #FIFO self
function FIFO:ForEach( IteratorFunction, Arg, Function, FunctionArguments )
  self:T(self.lid.."ForEach")

  local Set = self:GetPointerStack() or {}
  Arg = Arg or {}

  local function CoRoutine()
    local Count = 0
    for ObjectID, ObjectData in pairs( Set ) do
      local Object = ObjectData.data
        self:T( {Object} )
        if Function then
          if Function( unpack( FunctionArguments or {} ), Object ) == true then
            IteratorFunction( Object, unpack( Arg ) )
          end
        else
          IteratorFunction( Object, unpack( Arg ) )
        end
        Count = Count + 1
    end
    return true
  end

  local co = CoRoutine

  local function Schedule()

    local status, res = co()
    self:T( { status, res } )

    if status == false then
      error( res )
    end
    if res == false then
      return true -- resume next time the loop
    end

    return false
  end

  Schedule()

  return self
end
   
--- FIFO Print stacks to dcs.log
-- @param #FIFO self
-- @return #FIFO self
function FIFO:Flush()
  self:T(self.lid.."FiFo Flush")
  self:I("FIFO Flushing Stack by Pointer")
  for _id,_data in pairs (self.stackbypointer) do
    local data = _data -- #FIFO.IDEntry
    self:I(string.format("Pointer: %s | Entry: Number = %s Data = %s UniqueID = %s",tostring(_id),tostring(data.pointer),tostring(data.data),tostring(data.uniqueID)))
  end
  self:I("FIFO Flushing Stack by ID")
  for _id,_data in pairs (self.stackbyid) do
    local data = _data -- #FIFO.IDEntry
    self:I(string.format("ID: %s | Entry: Number = %s Data = %s UniqueID = %s",tostring(_id),tostring(data.pointer),tostring(data.data),tostring(data.uniqueID)))
  end
  self:I("Counter = " .. self.counter)
  self:I("Pointer = ".. self.pointer)
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- End FIFO
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIFO
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

do
--- **UTILS** - LiFo Stack.
--
-- **Main Features:**
--
--    * Build a simple multi-purpose LiFo (Last-In, First-Out) stack for generic data.
--
-- ===
--
-- ### Author: **applevangelist**

--- LIFO class.
-- @type LIFO
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string version Version of LiFo
-- @field #number counter
-- @field #number pointer
-- @field #table stackbypointer
-- @field #table stackbyid
-- @extends Core.Base#BASE

---
-- @type LIFO.IDEntry
-- @field #number pointer
-- @field #table data
-- @field #table uniqueID

---
-- @field #LIFO
LIFO = {
  ClassName = "LIFO",
  lid = "",
  version = "0.0.5",
  counter = 0,
  pointer = 0,
  stackbypointer = {},
  stackbyid = {}
}

--- Instantiate a new LIFO Stack
-- @param #LIFO self
-- @return #LIFO self
function LIFO:New()
  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New())
  self.pointer = 0
  self.counter = 0
  self.uniquecounter = 0
  self.stackbypointer = {}
  self.stackbyid = {}
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", "LiFo", self.version)
  self:T(self.lid .."Created.") 
  return self
end

--- Empty LIFO Stack
-- @param #LIFO self
-- @return #LIFO self
function LIFO:Clear()
  self:T(self.lid.."Clear")
  self.pointer = 0
  self.counter = 0
  self.stackbypointer = nil
  self.stackbyid = nil
  self.stackbypointer = {}
  self.stackbyid = {}
  self.uniquecounter = 0
  return self
end

--- LIFO Push Object to Stack
-- @param #LIFO self
-- @param #table Object
-- @param #string UniqueID (optional) - will default to current pointer + 1
-- @return #LIFO self
function LIFO:Push(Object,UniqueID)
  self:T(self.lid.."Push")
  self:T({Object,UniqueID})
  self.pointer = self.pointer + 1 
  self.counter = self.counter + 1
  local uniID = UniqueID
  if not UniqueID then
    self.uniquecounter = self.uniquecounter + 1
    uniID = self.uniquecounter
  end
  self.stackbyid[uniID] = { pointer = self.pointer, data = Object, uniqueID = uniID }
  self.stackbypointer[self.pointer] = { pointer = self.pointer, data = Object, uniqueID = uniID }
  return self
end

--- LIFO Pull Object from Stack
-- @param #LIFO self
-- @return #table Object or nil if stack is empty
function LIFO:Pull()
  self:T(self.lid.."Pull")
  if self.counter == 0 then return nil end
  local object = self.stackbypointer[self.pointer].data
  self.stackbypointer[self.pointer] = nil
  --local object = self.stackbypointer[1].data
  --self.stackbypointer[1] = nil
  self.counter = self.counter - 1
  self.pointer = self.pointer - 1
  self:Flatten()
  return object
end

--- LIFO Pull Object from Stack by Pointer
-- @param #LIFO self
-- @param #number Pointer
-- @return #table Object or nil if stack is empty
function LIFO:PullByPointer(Pointer)
  self:T(self.lid.."PullByPointer " .. tostring(Pointer))
  if self.counter == 0 then return nil end
  local object = self.stackbypointer[Pointer] -- #FIFO.IDEntry
  self.stackbypointer[Pointer] = nil
  if object then self.stackbyid[object.uniqueID] = nil end
  self.counter = self.counter - 1
  self:Flatten()
  if object then
    return object.data
  else
    return nil
  end
end

--- LIFO Read, not Pull, Object from Stack by Pointer
-- @param #LIFO self
-- @param #number Pointer
-- @return #table Object or nil if stack is empty or pointer does not exist
function LIFO:ReadByPointer(Pointer)
  self:T(self.lid.."ReadByPointer " .. tostring(Pointer))
  if self.counter == 0 or not Pointer or not self.stackbypointer[Pointer]  then return nil end
  local object = self.stackbypointer[Pointer] -- #LIFO.IDEntry
  if object then
    return object.data
  else
    return nil
  end
end

--- LIFO Read, not Pull, Object from Stack by UniqueID
-- @param #LIFO self
-- @param #number UniqueID
-- @return #table Object or nil if stack is empty or ID does not exist
function LIFO:ReadByID(UniqueID)
  self:T(self.lid.."ReadByID " .. tostring(UniqueID))
  if self.counter == 0 or not UniqueID or not self.stackbyid[UniqueID]  then return nil end
  local object = self.stackbyid[UniqueID] -- #LIFO.IDEntry
  if object then
    return object.data
  else
    return nil
  end
end

--- LIFO Pull Object from Stack by UniqueID
-- @param #LIFO self
-- @param #tableUniqueID
-- @return #table Object or nil if stack is empty
function LIFO:PullByID(UniqueID)
  self:T(self.lid.."PullByID " .. tostring(UniqueID))
  if self.counter == 0 then return nil end
  local object = self.stackbyid[UniqueID] -- #LIFO.IDEntry
  --self.stackbyid[UniqueID] = nil
  if object then
    return self:PullByPointer(object.pointer)
  else
    return nil
  end
end

--- LIFO Housekeeping
-- @param #LIFO self
-- @return #LIFO self
function LIFO:Flatten()
  self:T(self.lid.."Flatten")
  -- rebuild stacks
  local pointerstack = {}
  local idstack = {}
  local counter = 0
  for _ID,_entry in pairs(self.stackbypointer) do
    counter = counter + 1
    pointerstack[counter] = { pointer = counter, data = _entry.data, uniqueID = _entry.uniqueID}
  end
  for _ID,_entry in pairs(pointerstack) do
      idstack[_entry.uniqueID] = { pointer = _entry.pointer , data = _entry.data, uniqueID = _entry.uniqueID}
  end
  self.stackbypointer = nil
  self.stackbypointer = pointerstack
  self.stackbyid = nil
  self.stackbyid = idstack
  self.counter = counter
  self.pointer = counter
  return self
end

--- LIFO Check Stack is empty
-- @param #LIFO self
-- @return #boolean empty
function LIFO:IsEmpty()
  self:T(self.lid.."IsEmpty")
  return self.counter == 0 and true or false
end

--- LIFO Get stack size
-- @param #LIFO self
-- @return #number size
function LIFO:GetSize()
  self:T(self.lid.."GetSize")
  return self.counter
end

--- LIFO Get stack size
-- @param #LIFO self
-- @return #number size
function LIFO:Count()
  self:T(self.lid.."Count")
  return self.counter
end

--- LIFO Check Stack is NOT empty
-- @param #LIFO self
-- @return #boolean notempty
function LIFO:IsNotEmpty()
  self:T(self.lid.."IsNotEmpty")
  return not self:IsEmpty()
end

--- LIFO Get the data stack by pointer
-- @param #LIFO self
-- @return #table Table of #LIFO.IDEntry entries
function LIFO:GetPointerStack()
  self:T(self.lid.."GetPointerStack")
  return self.stackbypointer
end

--- LIFO Get the data stack by UniqueID
-- @param #LIFO self
-- @return #table Table of #LIFO.IDEntry entries
function LIFO:GetIDStack()
  self:T(self.lid.."GetIDStack")
  return self.stackbyid
end

--- LIFO Get table of UniqueIDs sorted smallest to largest
-- @param #LIFO self
-- @return #table Table of #LIFO.IDEntry entries
function LIFO:GetIDStackSorted()
  self:T(self.lid.."GetIDStackSorted")
  
  local stack = self:GetIDStack()
  local idstack = {}
  for _id,_entry in pairs(stack) do
    idstack[#idstack+1] = _id
    
    self:T({"pre",_id})
  end
  
  local function sortID(a, b)
      return a < b
  end
  
  table.sort(idstack)
 
  return idstack
end

--- LIFO Check if a certain UniqeID exists
-- @param #LIFO self
-- @return #boolean exists
function LIFO:HasUniqueID(UniqueID)
  self:T(self.lid.."HasUniqueID")
  return  self.stackbyid[UniqueID] and true or false
end

--- LIFO Print stacks to dcs.log
-- @param #LIFO self
-- @return #LIFO self
function LIFO:Flush()
  self:T(self.lid.."FiFo Flush")
  self:I("LIFO Flushing Stack by Pointer")
  for _id,_data in pairs (self.stackbypointer) do
    local data = _data -- #LIFO.IDEntry
    self:I(string.format("Pointer: %s | Entry: Number = %s Data = %s UniqueID = %s",tostring(_id),tostring(data.pointer),tostring(data.data),tostring(data.uniqueID)))
  end
  self:I("LIFO Flushing Stack by ID")
  for _id,_data in pairs (self.stackbyid) do
    local data = _data -- #LIFO.IDEntry
    self:I(string.format("ID: %s | Entry: Number = %s Data = %s UniqueID = %s",tostring(_id),tostring(data.pointer),tostring(data.data),tostring(data.uniqueID)))
  end
  self:I("Counter = " .. self.counter)
  self:I("Pointer = ".. self.pointer)
  return self
end

--- LIFO Get table of data entries
-- @param #LIFO self
-- @return #table Raw table indexed [1] to [n] of object entries - might be empty!
function LIFO:GetDataTable()
  self:T(self.lid.."GetDataTable")
  local datatable = {}
  for _,_entry in pairs(self.stackbypointer) do
    datatable[#datatable+1] = _entry.data
  end
  return datatable
end

--- LIFO Get sorted table of data entries by UniqueIDs (must be numerical UniqueIDs only!)
-- @param #LIFO self
-- @return #table Table indexed [1] to [n] of sorted object entries - might be empty!
function LIFO:GetSortedDataTable()
  self:T(self.lid.."GetSortedDataTable")
  local datatable = {}
  local idtablesorted = self:GetIDStackSorted()
  for _,_entry in pairs(idtablesorted) do
    datatable[#datatable+1] = self:ReadByID(_entry)
  end
  return datatable
end

--- Iterate the LIFO and call an iterator function for the given LIFO data, providing the object for each element of the stack and optional parameters.
-- @param #LIFO self
-- @param #function IteratorFunction The function that will be called.
-- @param #table Arg (Optional) Further Arguments of the IteratorFunction.
-- @param #function Function (Optional) A function returning a #boolean true/false. Only if true, the IteratorFunction is called.
-- @param #table FunctionArguments (Optional) Function arguments.
-- @return #LIFO self
function LIFO:ForEach( IteratorFunction, Arg, Function, FunctionArguments )
  self:T(self.lid.."ForEach")

  local Set = self:GetPointerStack() or {}
  Arg = Arg or {}

  local function CoRoutine()
    local Count = 0
    for ObjectID, ObjectData in pairs( Set ) do
      local Object = ObjectData.data
        self:T( {Object} )
        if Function then
          if Function( unpack( FunctionArguments or {} ), Object ) == true then
            IteratorFunction( Object, unpack( Arg ) )
          end
        else
          IteratorFunction( Object, unpack( Arg ) )
        end
        Count = Count + 1
    end
    return true
  end

  local co = CoRoutine

  local function Schedule()

    local status, res = co()
    self:T( { status, res } )

    if status == false then
      error( res )
    end
    if res == false then
      return true -- resume next time the loop
    end

    return false
  end

  Schedule()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- End LIFO
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
end