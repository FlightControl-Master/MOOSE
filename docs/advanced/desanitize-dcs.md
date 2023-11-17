---
title: De-Sanitize DCS
parent: Advanced
nav_order: 2
---
# De-Sanitize the DCS scripting environment
{: .no_toc }

1. Table of contents
{:toc}

De-Sanitize is the a modification performed by the user which disables some
security features of DCS. Without de-sanitizing not all functions of Moose
are available. Let's take a closer look and explain the details:

- In the File-Explorer, navigate to your DCS main [installation folder].
- Navigate to the folder `Scripts` and open the file `MissionScripting.lua` with
  a good editor like [Notepad++]{:target="_blank"}.

The original file should look like this:

```lua
--Initialization script for the Mission lua Environment (SSE)

dofile('Scripts/ScriptingSystem.lua')

-- Sanitize Mission Scripting environment
-- This makes unavailable some unsecure functions. 
-- Mission downloaded from server to client may contain potentialy harmful lua code
-- that may use these functions.
-- You can remove the code below and make availble these functions at your own risk.

local function sanitizeModule(name)
	_G[name] = nil
	package.loaded[name] = nil
end

do
	sanitizeModule('os')
	sanitizeModule('io')
	sanitizeModule('lfs')
	_G['require'] = nil
	_G['loadlib'] = nil
	_G['package'] = nil
end
```

In line 17, 18 and 19 the method `sanitizeModule` disables the modules `os`, `io` and `lfs`.

{: .warning }
> This is a security feature to avoid harmfull actions to be executed from
> inside a mission.
>
> ***Disable this on your own risk!***

If the lines will be disabled the lua code inside of missions can use the
following functionality again:

- `os` (at line 17):
  - Execution of commands from the operation system is allowed again.
    This is needed by some Classes when using [Text-To-Speech] with [SRS]{:target="_blank"}.
    But in theory it can also run harmful commands.

- `io` and `lfs` (at line 18 & 19):
  - Different libraries to access files on your hard disk or do other io
    operations. This is needed by some clases if you want to save and/or
    read data. Like persistance for CSAR.
    But it may be abused to access or modify sensitive files owned by the user.

If you put two dashes (`--`) in front of each of the lines 17 - 19 the
protection is disabled and the lower part of the file should look this:

```lua
do
	--sanitizeModule('os')
	--sanitizeModule('io')
	--sanitizeModule('lfs')
	_G['require'] = nil
	_G['loadlib'] = nil
	_G['package'] = nil
end
```

Save the file and it will enable the DCS Lua sandbox to access stuff on your computer.

{: .note }
> After each update of DCS you need to repeat this because each update will
> overwrite this file by default.

[installation folder]: ../beginner/tipps-and-tricks.md#find-the-installation-folder-of-dcs
[Notepad++]: https://notepad-plus-plus.org/downloads/
[Text-To-Speech]: text-to-speech.md
[SRS]: https://github.com/ciribob/DCS-SimpleRadioStandalone/releases/latest
