--------------------------------------------------------------------------------
--  Copyright (c) 2011-2012 Sierra Wireless.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the Eclipse Public License v1.0
--  which accompanies this distribution, and is available at
--  http://www.eclipse.org/legal/epl-v10.html
--
--  Contributors:
--       Simon BERNARD <sbernard@sierrawireless.com>
--           - initial API and implementation and initial documentation
--------------------------------------------------------------------------------
local M = {}

--------------------------------------------------------------------------------
-- API MODEL
--------------------------------------------------------------------------------

function M._file()
  local file = {
    -- FIELDS
    tag              = "file",
    name             = nil,    -- string
    shortdescription = "",    -- string
    description      = "",    -- string
    types            = {},     -- map from typename to type
    globalvars       = {},     -- map from varname to item
    returns          = {},     -- list of return

    -- FUNCTIONS
    addtype =  function (self,type)
      self.types[type.name] = type
      type.parent = self
    end,

    mergetype =  function (self,newtype,erase,erasesourcerangefield)
      local currenttype = self.types[newtype.name]
      if currenttype then
        -- merge recordtypedef
        if currenttype.tag =="recordtypedef" and newtype.tag == "recordtypedef" then
          -- merge fields
          for fieldname ,field in pairs( newtype.fields) do
            local currentfield = currenttype.fields[fieldname]
            if erase or not currentfield then
              currenttype:addfield(field)
            elseif erasesourcerangefield then
              if field.sourcerange.min and field.sourcerange.max then
                currentfield.sourcerange.min = field.sourcerange.min
                currentfield.sourcerange.max = field.sourcerange.max
              end
            end
          end

          -- merge descriptions and source ranges
          if erase then
            if newtype.description or newtype.description == ""  then currenttype.description = newtype.description end
            if newtype.shortdescription or newtype.shortdescription == ""  then currenttype.shortdescription = newtype.shortdescription end
            if newtype.sourcerange.min and newtype.sourcerange.max then
              currenttype.sourcerange.min = newtype.sourcerange.min
              currenttype.sourcerange.max = newtype.sourcerange.max
            end
          end
          -- merge functiontypedef
        elseif currenttype.tag == "functiontypedef" and newtype.tag == "functiontypedef" then
          -- merge params
          for i, param1 in ipairs(newtype.params) do
            local missing = true
            for j, param2 in ipairs(currenttype.params) do
              if param1.name == param2.name then
                missing = false
                break
              end
            end
            if missing then
              table.insert(currenttype.params,param1)
            end
          end

          -- merge descriptions and source ranges
          if erase then
            if newtype.description or newtype.description == "" then currenttype.description = newtype.description end
            if newtype.shortdescription or newtype.shortdescription == ""  then currenttype.shortdescription = newtype.shortdescription end
            if newtype.sourcerange.min and newtype.sourcerange.max then
              currenttype.sourcerange.min = newtype.sourcerange.min
              currenttype.sourcerange.max = newtype.sourcerange.max
            end
          end
        end
      else
        self:addtype(newtype)
      end
    end,

    addglobalvar =  function (self,item)
      self.globalvars[item.name] = item
      item.parent = self
    end,

    moduletyperef = function (self)
      if self and self.returns[1] and self.returns[1].types[1] then
        local typeref = self.returns[1].types[1]
        return typeref
      end
    end
  }
  return file
end

function M._recordtypedef(name)
  local recordtype = {
    -- FIELDS
    tag              = "recordtypedef",
    name             = name,            -- string (mandatory)
    shortdescription = "",             -- string
    description      = "",             -- string
    fields           = {},              -- map from fieldname to field
    sourcerange      = {min=0,max=0},

    -- FUNCTIONS
    addfield = function (self,field)
      self.fields[field.name] = field
      field.parent = self
    end
  }
  return recordtype
end

function M._functiontypedef(name)
  return {
    tag              = "functiontypedef",
    name             = name,              -- string (mandatory)
    shortdescription = "",               -- string
    description      = "",               -- string
    params           = {},                -- list of parameter
    returns          = {}                 -- list of return
  }
end

function M._parameter(name)
  return {
    tag         = "parameter",
    name        = name, -- string (mandatory)
    description = "",   -- string
    type        = nil   -- typeref (external or internal or primitive typeref)
  }
end

function M._item(name)
  return {
    -- FIELDS
    tag              = "item",
    name             = name,   -- string (mandatory)
    shortdescription = "",     -- string
    description      = "",     -- string
    type             = nil,    -- typeref (external or internal or primitive typeref)
    occurrences      = {},     -- list of identifier (see internalmodel)
    sourcerange      = {min=0, max=0},

    -- This is A TRICK
    -- This value is ALWAYS nil, except for internal purposes (short references).
    external         = nil,

    -- FUNCTIONS
    addoccurence = function (self,occ)
      table.insert(self.occurrences,occ)
      occ.definition = self
    end,

    resolvetype = function (self,file)
      if self and self.type then
        if self.type.tag =="internaltyperef" then
          -- if file is not given try to retrieve it.
          if not file then
            if self.parent and self.parent.tag == 'recordtypedef' then
              file = self.parent.parent
            elseif self.parent.tag == 'file' then
              file = self.parent
            end
          end
          if file then return file.types[self.type.typename] end
        elseif self.type.tag =="inlinetyperef" then
          return self.type.def
        end
      end
    end
  }
end

function M._externaltypref(modulename, typename)
  return {
    tag        = "externaltyperef",
    modulename = modulename,        -- string
    typename   =  typename          -- string
  }
end

function M._internaltyperef(typename)
  return {
    tag      = "internaltyperef",
    typename =  typename          -- string
  }
end

function M._primitivetyperef(typename)
  return {
    tag      = "primitivetyperef",
    typename =  typename           -- string
  }
end

function M._moduletyperef(modulename,returnposition)
  return {
    tag            = "moduletyperef",
    modulename     = modulename,      -- string
    returnposition = returnposition   -- number
  }
end

function M._exprtyperef(expression,returnposition)
  return {
    tag            = "exprtyperef",
    expression     =  expression,   -- expression (see internal model)
    returnposition = returnposition -- number
  }
end

function M._inlinetyperef(definition)
  return {
    tag            = "inlinetyperef",
    def            =  definition,   -- expression (see internal model)

  }
end

function M._return(description)
  return {
    tag         = "return",
    description =  description or "", -- string
    types       = {}                  -- list of typref (external or internal or primitive typeref)
  }
end
return M
