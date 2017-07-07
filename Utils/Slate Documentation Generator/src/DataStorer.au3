; This file only constains function related to storing the hierarchy in a tree-like tructure

Func AddNode($Kind, $Module ,$Node, $Parent, $File, $CarretPos)
	FileSetPos($DataFile, 0, $FILE_END)

	If $Parent == "" And $Kind == "type" Then
		$Parent = "ROOT"
	ElseIf $Kind == "module" Then
		$Module = " "
		$Parent = " "
	EndIf
	FileWrite($DataFile, "@K="&$Kind&", @M="&$Module&", @N="&$Node&", @P="&$Parent&", @F="&$File&", @C="&$CarretPos&","&@CRLF)
EndFunc

; Search node by name and returns one data
Func GetData($Node, $Data)
	FileSetPos($DataFile, 0, $FILE_BEGIN)
	Local $CurrentLine = ""
	Local $CurrentData
	Local $RegexResult
	Local $Regex
	Switch $Data
		Case "kind"
			$Regex = "\@K=(.+?),"
		Case "parent"
			$Regex = "\@P=(.+?),"
		Case "file"
			$Regex = "\@F=(.+?),"
		Case "carretpos"
			$Regex = "\@C=(.+?),"
	EndSwitch
	FileSetPos($DataFile, 0, $FILE_BEGIN)
	Do
		$CurrentLine = FileReadLine($DataFile)
		If @error == -1 Then
			Return ""
			ExitLoop
		EndIf
		$CurrentData = StringRegExp($CurrentLine, "\@N=(.+?),", $STR_REGEXPARRAYMATCH)

	Until $Node == $CurrentData[0]
	$CurrentData = StringRegExp($CurrentLine, $Regex, $STR_REGEXPARRAYMATCH)
	Return $CurrentData[0]
EndFunc


; Returns an array of parent nodes, up to the root, starting with the root
Func GetParents($Node)
	Local $CurrentParent = $Node
	Local $ParentsArray[0]
	Local $NbOfParents = 1

	While $CurrentParent <> "ROOT"
		ReDim $ParentsArray[$NbOfParents]
		$ParentsArray[$NbOfParents-1] = $CurrentParent

		$CurrentParent = GetData($CurrentParent, "parent")
		If $CurrentParent == "" Then
			FileWrite($Log, "ERROR : Couldn't find "&$ParentsArray[$NbOfParents-1]&"'s parent !")
			$CurrentParent = "ERROR !"
			ReDim $ParentsArray[$NbOfParents]
			$ParentsArray[$NbOfParents-1] = $CurrentParent
			ExitLoop
		EndIf
		$NbOfParents += 1
	WEnd

	_ArrayReverse($ParentsArray)
	_ArrayDelete($ParentsArray, $NbOfParents)
	Return $ParentsArray
EndFunc



Func DataSort()
	Local $SortedDataFile = FileOpen(@ScriptDir & "\TreeHierarchySorted.csv", $FO_OVERWRITE)
	Local $Line = ""
	Local $LineNb = 1
	Local $RegexResults
	Local $CurrentModule
	Local $CurrentType

	FileSetPos($DataFile, 0, $FILE_BEGIN)

	While True
		$Line = FileReadLine($DataFile)
		If @error then ExitLoop

		$RegexResults = StringRegExp($Line, "\@K=(.+?),", $STR_REGEXPARRAYMATCH)
		If $RegexResults[0] == "module" Then
			ConsoleWrite(".")
			$RegexResults = StringRegExp($Line, "\@N=(.+?),", $STR_REGEXPARRAYMATCH)
			$CurrentModule = $RegexResults[0]
			FileWriteLine($SortedDataFile, $Line)
			FileClose($DataFile)
			_FileWriteToLine(@ScriptDir & "\TreeHierarchy.csv", $LineNb, "", True)
			$DataFile = FileOpen(@ScriptDir & "\TreeHierarchy.csv", 1)
			FileSetPos($DataFile, 0, $FILE_BEGIN)
			$LineNb = 1

			While True
				$Line = FileReadLine($DataFile)
				If @error then ExitLoop

				$RegexResults = StringRegExp($Line, "\@K=(.+?),", $STR_REGEXPARRAYMATCH)
				If $RegexResults[0] == "type" Then
					$RegexResults = StringRegExp($Line, "\@M=(.+?),", $STR_REGEXPARRAYMATCH)
					If $RegexResults[0] == $CurrentModule Then
						$RegexResults = StringRegExp($Line, "\@N=(.+?),", $STR_REGEXPARRAYMATCH)
						$CurrentType = $RegexResults[0]
						FileWriteLine($SortedDataFile, $Line)
						FileClose($DataFile)
						_FileWriteToLine(@ScriptDir & "\TreeHierarchy.csv", $LineNb, "", True)
						$DataFile = FileOpen(@ScriptDir & "\TreeHierarchy.csv", 1)
						FileSetPos($DataFile, 0, $FILE_BEGIN)
						$LineNb = 1

						While True
							$Line = FileReadLine($DataFile)
							If @error then ExitLoop

							$RegexResults = StringRegExp($Line, "\@K=(.+?),", $STR_REGEXPARRAYMATCH)
							If $RegexResults[0] == "function" Then
								$RegexResults = StringRegExp($Line, "\@P=(.+?),", $STR_REGEXPARRAYMATCH)
								If $RegexResults[0] == $CurrentType Then
									FileWriteLine($SortedDataFile, $Line)
									FileClose($DataFile)
									_FileWriteToLine(@ScriptDir & "\TreeHierarchy.csv", $LineNb, "", True)
									$DataFile = FileOpen(@ScriptDir & "\TreeHierarchy.csv", 1)
									FileSetPos($DataFile, 0, $FILE_BEGIN)
									$LineNb = 0
								EndIf
							EndIf
							$LineNb += 1
						WEnd
						FileSetPos($DataFile, 0, $FILE_BEGIN)
						$LineNb = 0
					EndIf
				EndIf
				$LineNb += 1
			WEnd
			FileSetPos($DataFile, 0, $FILE_BEGIN)
			$LineNb = 0
		EndIf
		$LineNb += 1
	Wend
	If FileGetSize(@ScriptDir & "\TreeHierarchy.csv") <> 0 Then
		FileWrite($Log, "ERROR : Some items couldn't be sorted. Verify them in the file TreeHierarchy.csv"&@CRLF)
		ConsoleWrite(@CRLF&"INFO : Some items couldn't be sorted. Verify them in the file TreeHierarchy.csv"&@CRLF)
	EndIf
	FileClose($DataFile)
	$DataFile = $SortedDataFile
EndFunc


Func FindInFunctionList($String)
	Local $Line = ""
	Local $TempStringArray
	FileSetPos($FunctionList, 0, $FILE_BEGIN)
	;FileWrite($Log, 'Trying to find the function prototype for : ' & $String & @CRLF)
	While 1
		$Line = FileReadLine($FunctionList)
		If @error = -1 Then
			SetError(0)
			FileWrite($Log, "ERROR : Couldn't find " & $String & " in file. Does this method exitsts ?" & @CRLF)
			Return $String
		EndIf
		If StringInStr($Line, $String) Then
			$TempStringArray = StringSplit($Line, "-")
			$Line = "[" & $TempStringArray[1] & ":" & $TempStringArray[2] & "()]" & '(#' & StringLower($Line) & ')'
			Return $Line
		EndIf
	WEnd
EndFunc