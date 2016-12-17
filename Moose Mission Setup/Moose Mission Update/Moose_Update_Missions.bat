echo off

rem Update Missions with a new version of Moose.lua
rem Provide as the only parameter the path to the .miz files, which can be embedded in directories.

echo Path to Mission Files: %1

For /R %1 %%G IN (*.miz) do 7z u "%%G" "l10n\DEFAULT\Moose.lua"
