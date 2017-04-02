--------------------------------------------------------------------------------
--  Copyright (c) 2012-2014 Sierra Wireless.
--  All rights reserved. This program and the accompanying materials
--  are made available under the terms of the Eclipse Public License v1.0
--  which accompanies this distribution, and is available at
--  http://www.eclipse.org/legal/epl-v10.html
--
--  Contributors:
--       Kevin KIN-FOO <kkinfoo@sierrawireless.com>
--           - initial API and implementation and initial documentation
--------------------------------------------------------------------------------
require 'metalua.loader'
local compiler = require 'metalua.compiler'
local mlc = compiler.new()
local M = {}

--
-- Define default supported languages
--
M.supportedlanguages = {}
local extractors = require 'extractors'

-- Support Lua comment extracting
M.supportedlanguages['lua'] = extractors.lua

-- Support C comment extracting
for _,c in ipairs({'c', 'cpp', 'c++'}) do
  M.supportedlanguages[c] = extractors.c
end

-- Extract comment from code,
-- type of code is deduced from filename extension
function M.extract(filename, code)
  -- Check parameters
  if not code then return nil, 'No code provided' end
  if type(filename) ~= "string" then
    return nil, 'No string for file name provided'
  end

  -- Extract file extension
  local fileextension = filename:gmatch('.*%.(.*)')()
  if not fileextension then
    return nil, 'File '..filename..' has no extension, could not determine how to extract documentation.'
  end

  -- Check if it is possible to extract documentation from these files
  local extractor = M.supportedlanguages[ fileextension ]
  if not extractor then
    return nil, 'Unable to extract documentation from '.. fileextension .. ' file.'
  end
  return extractor( code )
end
-- Generate a file gathering only comments from given code
function M.generatecommentfile(filename, code)
  local comments, error = M.extract(filename, code)
  if not comments then
    return nil, 'Unable to generate comment file.\n'..error
  end
  local filecontent = {}
  for _, comment in ipairs( comments ) do
    table.insert(filecontent, "--[[")
    table.insert(filecontent, comment)
    table.insert(filecontent, "\n]]\n\n")
  end
  return table.concat(filecontent)..'return nil\n'
end
-- Create API Model module from a 'comment only' lua file
function M.generateapimodule(filename, code,noheuristic)
  if not filename then return nil, 'No file name given.' end
  if not code then return nil, 'No code provided.' end
  if type(filename) ~= "string" then return nil, 'No string for file name provided' end

  -- for non lua file get comment file
  if filename:gmatch('.*%.(.*)')() ~= 'lua' then
    local err
    code, err = M.generatecommentfile(filename, code)
    if not code then
      return nil, 'Unable to create api module for "'..filename..'".\n'..err
    end
  else

    -- manage shebang
    if code then code = code:gsub("^(#.-\n)", function (s) return string.rep(' ',string.len(s)) end) end

    -- check for errors
    local f, err = loadstring(code,'source_to_check')
    if not f then
      return nil, 'File'..filename..'contains syntax error.\n' .. err
    end
  end

  local status, ast = pcall(mlc.src_to_ast, mlc, code)
  if not status then
    return nil, 'Unable to compute ast for "'..filename..'".\n'..ast
  end

  -- Extract module name as the filename without extension
  local modulename
  local matcher = string.gmatch(filename,'.*/(.*)%..*$')
  if matcher then modulename = matcher() end

  -- Create api model
  local apimodelbuilder = require 'models.apimodelbuilder'
  local _file, comment2apiobj = apimodelbuilder.createmoduleapi(ast, modulename)

  -- Create internal model
  if not noheuristic then
    local internalmodelbuilder = require "models.internalmodelbuilder"
    local _internalcontent = internalmodelbuilder.createinternalcontent(ast,_file,comment2apiobj, modulename)
  end
  return _file
end
return M
