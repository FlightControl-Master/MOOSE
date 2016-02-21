
local base = _G

local MOOSE_Version = "0.1.1.1"

env.info("Loading MOOSE " .. base.timer.getAbsTime() )

function script_path()
   local str = debug.getinfo(2, "S").source
   return str:match("(.*/)"):sub(1,-2):gsub("\\","/")
end


Include = {}

Include.ProgramPath = "Scripts/Moose/Moose/"
Include.MissionPath = script_path()

env.info( "Include.ProgramPath = " .. Include.ProgramPath)
env.info( "Include.MissionPath = " .. Include.MissionPath)
Include.Files = {}

Include.FileIn = function(fileName, table)
--	env.info( fileName )
	local chunk, errMsg = base.loadfile(fileName)
	if chunk ~= nil then
		env.info( "chunk assigned " )
		env.info( Include.oneLineSerialize( chunk ) )
		base.setfenv(chunk, table)
		chunk()
		if table.MOOSE_Version then
			env.info( table.MOOSE_Version )
		end
		return chunk
	else
		return nil, errMsg
	end
end

Include.MisFiles = {}

Include.FileName = function( num )
    local hexstr = '0123456789ABCDEF'
    local s = ''
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == '' then s = '0' end
--	env.info( string.format( "~mis" .. "%8s", "00000000" .. s ) )
    return string.format( "~mis" .. "%s", string.sub( "00000000" .. s, -8 ) )
end

Include.ScanFiles = function()

	local i = 0
	while i <= 32767 do
		local FileName = Include.FileName( i )
		local FileChunk = {}
		local FileChunk = Include.FileIn( Include.MissionPath .. FileName, FileChunk )
		if FileChunk then
		end
		i = i + 1
	end
end


Include.File = function( IncludeFile )
	if not Include.Files[ IncludeFile ] then
		Include.Files[IncludeFile] = IncludeFile
		env.info( "Include:" .. IncludeFile .. " from " .. Include.ProgramPath )
		local f = base.loadfile( Include.ProgramPath .. IncludeFile .. ".lua" )
		if f == nil then
			env.info( "Include:" .. IncludeFile .. " from " .. Include.MissionPath )
			local f = base.loadfile( Include.MissionPath .. IncludeFile .. ".lua" )
			if f == nil then
				error ("Could not load MOOSE file " .. IncludeFile .. ".lua" )
			else
				env.info( "Include:" .. IncludeFile .. " loaded from " .. Include.MissionPath )
				return f()
			end
		else
			env.info( "Include:" .. IncludeFile .. " loaded from " .. Include.ProgramPath )
			return f()
		end
	end
end

--porting in Slmod's "safestring" basic serialize
Include.basicSerialize = function(s)
	if s == nil then
		return "\"\""
	else
		if ((type(s) == 'number') or (type(s) == 'boolean') or (type(s) == 'function') or (type(s) == 'table') or (type(s) == 'userdata') ) then
			return tostring(s)
		elseif type(s) == 'string' then
			s = string.format('%q', s)
			return s
		end
	end
end

-- porting in Slmod's serialize_slmod2
Include.oneLineSerialize = function(tbl)  -- serialization of a table all on a single line, no comments, made to replace old get_table_string function
	if type(tbl) == 'table' then --function only works for tables!

		local tbl_str = {}

		tbl_str[#tbl_str + 1] = '{'

		for ind,val in pairs(tbl) do -- serialize its fields
			if type(ind) == "number" then
				tbl_str[#tbl_str + 1] = '['
				tbl_str[#tbl_str + 1] = tostring(ind)
				tbl_str[#tbl_str + 1] = ']='
			else --must be a string
				tbl_str[#tbl_str + 1] = '['
				tbl_str[#tbl_str + 1] = Include.basicSerialize(ind)
				tbl_str[#tbl_str + 1] = ']='
			end

			if ((type(val) == 'number') or (type(val) == 'boolean')) then
				tbl_str[#tbl_str + 1] = tostring(val)
				tbl_str[#tbl_str + 1] = ','
			elseif type(val) == 'string' then
				tbl_str[#tbl_str + 1] = Include.basicSerialize(val)
				tbl_str[#tbl_str + 1] = ','
			elseif type(val) == 'nil' then -- won't ever happen, right?
				tbl_str[#tbl_str + 1] = 'nil,'
			elseif type(val) == 'table' then
				if ind == "__index" then
					tbl_str[#tbl_str + 1] = "__index"
					tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
				else
					tbl_str[#tbl_str + 1] = Include.oneLineSerialize(val)
					tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
				end
			elseif type(val) == 'function' then
				tbl_str[#tbl_str + 1] = "function " .. tostring(ind)
				tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
			else
				env.info('unable to serialize value type ' .. Include.basicSerialize(type(val)) .. ' at index ' .. tostring(ind))
				env.info( debug.traceback() )
			end

		end
		tbl_str[#tbl_str + 1] = '}'
		return table.concat(tbl_str)
	else
		return tostring(tbl)
	end
end

Include.ScanFiles( )

Include.File( "Database" )

env.info("Loaded MOOSE Include Engine")