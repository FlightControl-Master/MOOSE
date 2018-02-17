git clone https://github.com/FlightControl-Master/MOOSE_MISSIONS.git missions

appveyor DownloadFile https://github.com/FlightControl-Master/MOOSE_MISSIONS/archive/Release.zip

7z x Release.zip

dir

For /R MOOSE_MISSIONS-Release %%M IN (*.miz) do ( 
  echo "Mission: %%M"
  mkdir Temp
  cd Temp
  mkdir l10n
  mkdir l10n\DEFAULT
  copy "..\Moose Mission Setup\Moose.lua" l10n\DEFAULT
  copy "%%~pM%%~nM.lua" l10n\DEFAULT\*.*
  7z -bb0 u "%%M" "l10n\DEFAULT\*.lua"
  cd ..
  rmdir /S /Q Temp
)
