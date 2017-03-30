; MooseDevelopmentEnvironmentSetup.exe
; ------------------------------------
; This program sets up the Moose Development Evironment for Testers and Developers.
; The goal is to make it easy to use the Dynamic Loading Moose.lua, which is more suitable for rapid development and regular changes
; than its static counterpart.
;
; Author : Hugues "GreyEcho" Bousquet

#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <EditConstants.au3>
#Include <GUIEdit.au3>
#Include <ScrollBarConstants.au3>
#include <File.au3>

Global $7zipPath
Global $DCSWorldPath
Global $RepoPath
Global $DCSWorldScriptsMoosePath
Global $MooseDevFolderPath
Global $Log
Global $ProgramFilesDir = @HomeDrive & '\Program Files\'


Func CleanExit()
	_FileWriteLog($Log, 'INFO:'&@TAB&'Program exited cleanly'&@CRLF)
	FileClose($Log)
	Exit
EndFunc

Func Welcome()
	#Region ### START Koda GUI section ### Form=
	$Form2 = GUICreate("Welcome", 532, 150, 620, 457)
	$Label1 = GUICtrlCreateLabel("Welcome to Moose ! ", 120, 16, 217, 33)
	GUICtrlSetFont(-1, 18, 800, 0, "Calibri")
	$Label2 = GUICtrlCreateLabel("This tool is designed to help you setup your Moose development environment.", 104, 56, 370, 17)
	$Button1 = GUICtrlCreateButton("&OK", 268, 115, 75, 25)
	$Button2 = GUICtrlCreateButton("&Cancel", 187, 116, 75, 25)
	$Label3 = GUICtrlCreateLabel("Before you proceed, please make sure that you correctly installed GitHub, as well as 7-zip.", 104, 80, 423, 17)
	$Pic1 = GUICtrlCreatePic("C:\Users\Hugues\Desktop\Moose\MOOSE_Logo_Primary_Color.jpg", 8, 8, 89, 89)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	_FileWriteLog($Log, 'INFO:'&@TAB&'In window "Welcome"'&@CRLF)

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			case $GUI_EVENT_CLOSE
				GUIDelete()
				CleanExit()
			case $Button2
				GUIDelete()
				CleanExit()
			case $Button1
				GUIDelete()
				ExitLoop
		EndSwitch
	WEnd

EndFunc

Func FoldersLocation()
	#Region ### START Koda GUI section ### Form=
	$Form1 = GUICreate("Location of your Folders", 603, 237, 585, 425)
	$GroupBox1 = GUICtrlCreateGroup("Folder Locations ", 8, 9, 585, 185)
	$Input1 = GUICtrlCreateInput("C:\Program Files\7-Zip\", 24, 48, 505, 21)
	$Label1 = GUICtrlCreateLabel("7-Zip Location", 24, 32, 72, 17)
	$Input2 = GUICtrlCreateInput("C:\Program Files\Eagle Dynamics\DCS World\", 24, 104, 505, 21)
	$Label2 = GUICtrlCreateLabel("DCS World Install Location", 24, 88, 131, 17)
	$Input3 = GUICtrlCreateInput("C:\Users\Hugues\Documents\GitHub\MOOSE\", 24, 160, 505, 21)
	$Label3 = GUICtrlCreateLabel("MOOSE Local Repository Location", 24, 144, 169, 17)
	$Button3 = GUICtrlCreateButton("Browse", 528, 48, 57, 21)
	$Button4 = GUICtrlCreateButton("Browse", 528, 104, 57, 21)
	$Button5 = GUICtrlCreateButton("Browse", 528, 160, 57, 21)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$Button1 = GUICtrlCreateButton("&OK", 308, 203, 75, 25)
	$Button2 = GUICtrlCreateButton("&Cancel", 219, 204, 75, 25)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	_FileWriteLog($Log, 'INFO:'&@TAB&'In window "Folders Location"'&@CRLF)

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			case $GUI_EVENT_CLOSE
				GUIDelete()
				CleanExit()
			case $Button2
				GUIDelete()
				CleanExit()
			; Browse buttons
			case $Button3
				$7zipPath = FileSelectFolder("Select the 7-Zip Installation Folder", $ProgramFilesDir)
				If $7zipPath Then
					GUICtrlSetData($Input1, $7zipPath)
				EndIf
			case $Button4
				$DCSWorldPath = FileSelectFolder("Select the DCS World Installation Folder", $ProgramFilesDir)
				If $DCSWorldPath Then
					GUICtrlSetData($Input2, $DCSWorldPath)
				EndIf
			case $Button5
				$RepoPath = FileSelectFolder("Select the local MOOSE GitHub Repository Folder", @MyDocumentsDir)
				If $RepoPath Then
					GUICtrlSetData($Input3, $RepoPath)
				EndIf
			; ok !
			case $Button1
				If FileExists(GUICtrlRead($Input1)) and FileExists(GUICtrlRead($Input2)) and FileExists(GUICtrlRead($Input3)) Then
					$7zipPath = GUICtrlRead($Input1)
					$DCSWorldPath = GUICtrlRead($Input2)
					$RepoPath = GUICtrlRead($Input3)

					; add trailing '\' when necessary
					If StringRight($7zipPath, 1) <> "\" Then
						$7zipPath &= "\"
					EndIf
					If StringRight($DCSWorldPath, 1) <> "\" Then
						$DCSWorldPath &= "\"
					EndIf
					If StringRight($RepoPath, 1) <> "\" Then
						$RepoPath &= "\"
					EndIf

					DirCreate($DCSWorldPath&'Scripts\Moose\')
					$DCSWorldScriptsMoosePath = $DCSWorldPath & 'Scripts\Moose\'
					$MooseDevFolderPath = $RepoPath & 'Moose Development\Moose\'

					_FileWriteLog($Log, 'INFO:'&@TAB&'7Zip Path : '&$7zipPath&@CRLF)
					_FileWriteLog($Log, 'INFO:'&@TAB&'DCS World Path : '&$DCSWorldPath&@CRLF)
					_FileWriteLog($Log, 'INFO:'&@TAB&'Moose Repo Path : '&$RepoPath&@CRLF)
					_FileWriteLog($Log, 'INFO:'&@TAB&'DCS World Scripts Path : '&$DCSWorldScriptsMoosePath&@CRLF)
					_FileWriteLog($Log, 'INFO:'&@TAB&'Moose Development Folder Path : '&$MooseDevFolderPath&@CRLF)
					GUIDelete()
					ExitLoop
				Else
					MsgBox(16, "Error", "One of the file paths is invalid, please check again.") ; TODO : Which one is wrong ?
					_FileWriteLog($Log, 'ERROR:'&@TAB&'One of the paths is invalid'&@CRLF)
					_FileWriteLog($Log, 'INFO:'&@TAB&'7Zip Path : '&$7zipPath&@CRLF)
					_FileWriteLog($Log, 'INFO:'&@TAB&'DCS World Path : '&$DCSWorldPath&@CRLF)
					_FileWriteLog($Log, 'INFO:'&@TAB&'Moose Repo Path : '&$RepoPath&@CRLF)
				EndIf
		EndSwitch
	Wend
EndFunc

Func SetupInProgress()
	#Region ### START Koda GUI section ### Form=
	$Form3 = GUICreate("Setup In Progress", 522, 237, 638, 427)
	$Button1 = GUICtrlCreateButton("&OK", 223, 203, 75, 25)
	$Edit1 = GUICtrlCreateEdit("", 8, 8, 505, 185)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	GUICtrlSetState($Button1, $GUI_DISABLE)

	local $InstallSuccessfull = 1

	_FileWriteLog($Log, 'INFO:'&@TAB&'In window "SetupInProgress"'&@CRLF)

	local $TrimmedMooseDevFolderPath = StringTrimRight($MooseDevFolderPath, 1)

	; Create the Dynamic Link
	If FileCreateNTFSLink($TrimmedMooseDevFolderPath, $DCSWorldScriptsMoosePath, $FC_OVERWRITE) Then
		_FileWriteLog($Log, 'INFO:'&@TAB&"Hard Link created for "&$TrimmedMooseDevFolderPath&" in "&$DCSWorldScriptsMoosePath&@CRLF)
		_GUICtrlEdit_AppendText($Edit1, "Hard Link Ccreated... Ok!"&@CRLF)
	Else
		_FileWriteLog($Log, 'ERROR:'&@TAB&"Couldn't create a hard link for "&$TrimmedMooseDevFolderPath&" in "&$DCSWorldScriptsMoosePath&@CRLF)
		_GUICtrlEdit_AppendText($Edit1, "ERROR : Couldn't create a hard link for "&$TrimmedMooseDevFolderPath&" in "&$DCSWorldScriptsMoosePath&@CRLF)
		$InstallSuccessfull = 0
	EndIf

	; Get the current PATH and append 7Zip's path to it
	local $NewPathContent = EnvGet("PATH")
	If StringRight($NewPathContent, 1) <> ";" Then
		$NewPathContent &= ";"
	EndIf
	$NewPathContent &= $7zipPath

	; Add the 7zip folder path to %PATH%
	If Not StringInStr(EnvGet("PATH"), "7-Zip") Then
		If RegWrite("HKEY_CURRENT_USER\Environment", "Path", "REG_SZ", $NewPathContent) Then
			_FileWriteLog($Log, 'INFO:'&@TAB&$7zipPath&" added to %PATH%. PATH = "&EnvGet("PATH")&@CRLF)
			_GUICtrlEdit_AppendText($Edit1, "%PATH% Evrionment Variable updated... Ok!"&@CRLF)
		Else
			_FileWriteLog($Log, 'ERROR:'&@TAB&$7zipPath&" could not to %PATH%. Command :"&'"' & @ComSpec & '" /k ' & 'setx /M PATH "%PATH%;' & $7zipPath&@CRLF)
			_GUICtrlEdit_AppendText($Edit1, "ERROR : Couldn't add "&$7zipPath&" to %PATH%"&@CRLF)
			$InstallSuccessfull = 0
		EndIf
	Else
		_FileWriteLog($Log, 'INFO:'&@TAB&$7zipPath&" is already set in %PATH%. PATH = "&EnvGet("PATH")&@CRLF)
		_GUICtrlEdit_AppendText($Edit1, "INFO : %PATH% already stores the 7-Zip folder path, no need to modify"&@CRLF)
	EndIf

	; Copy lua folder to ProgramFiles
	local $TrimmedLuaPath = @ScriptDir&"\LuaFiles"
	local $TrimmedProgramFilesDir = StringTrimRight($ProgramFilesDir, 1)
	If DirCopy($TrimmedLuaPath, $TrimmedProgramFilesDir, $FC_OVERWRITE) Then
		_FileWriteLog($Log, 'INFO:'&@TAB&$TrimmedLuaPath&" successfully copied to "&$TrimmedProgramFilesDir&@CRLF)
		_GUICtrlEdit_AppendText($Edit1, "Lua 5.1 Installation... Ok!"&@CRLF)
	Else
		_FileWriteLog($Log, 'ERROR:'&@TAB&"Could not copy "&$TrimmedLuaPath&" to "&$TrimmedProgramFilesDir&@CRLF)
		_GUICtrlEdit_AppendText($Edit1, "ERROR : Could not install lua 5.1 in "&$ProgramFilesDir&" Please retry, running this program is admin"&@CRLF)
		$InstallSuccessfull = 0
	EndIf

	; Succesfull Message
	If $InstallSuccessfull Then
		_GUICtrlEdit_AppendText($Edit1, "Setup Complete !"&@CRLF)
		_FileWriteLog($Log, 'INFO:'&@TAB&'Setup Successful. Please reboot the computer.'&@CRLF)
	Else
		_GUICtrlEdit_AppendText($Edit1, "Setup finished, but some problem occured. Please fix them manually or retry the installation process."&@CRLF)
		_FileWriteLog($Log, 'INFO:'&@TAB&'Setup finished, but some error occured'&@CRLF)
	EndIf

	GUICtrlSetState($Button1, $GUI_ENABLE)

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			case $GUI_EVENT_CLOSE
				GUIDelete()
				CleanExit()
			case $Button1
				MsgBox(64, "Reboot", "You need to reboot your system to be able to use the automated .miz manipualtion tools") ; TODO : Automtically reboot ?
				GUIDelete()
				CleanExit()
		EndSwitch
	WEnd

EndFunc

While 1
	$Log = FileOpen(@ScriptDir & "\mdes.log", 1)
	FileWrite($Log, @CRLF&'New Session !'&@CRLF&'============='&@CRLF)
	Welcome()
	FoldersLocation()
	SetupInProgress()
WEnd
