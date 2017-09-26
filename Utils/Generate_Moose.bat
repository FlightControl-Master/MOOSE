%~dp0luarocks\lua5.1.exe %1 %2 %3 %4 %5
call %~dp0LuaSrcDiet.bat --basic --opt-emptylines %5\Moose.lua
del %5\Moose.lua
copy %5\Moose_.lua %5\Moose.lua
del Moose_.lua
