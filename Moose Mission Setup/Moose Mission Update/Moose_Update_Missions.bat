echo off

rem Update Missions with a new version of Moose.lua
rem Run this batch file with the following command arguments in Eclipse: "${resource_loc:/Moose/Moose Development/Moose}" "${current_date}"

echo Path to Mission Files: %1

For /R %1 %%G IN (*.miz) do 7z u "%%G" "l10n\DEFAULT\Moose.lua"
