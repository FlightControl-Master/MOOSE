; Takes an array and returns it in a markdown flavored list
; If the list is a retun, then, there is no variable name...
Func ArrayToList($Array, $Return)
	$String = ""
	$i = 0
	do
		$String &= "* "
		$String &= $Array[$i] & " "

		If $Return Then
			If $Array[$i + 2] == "" or $Array[$i + 2] == " " Then
				$String &= @CRLF
			Else
				$String &= " " & $Array[$i + 1] & " " & $Array[$i + 2] & @CRLF
			EndIf
		Else

			$String &= $Array[$i + 1]
			If $Array[$i + 2] == "" or $Array[$i + 2] == " " Then
				$String &= @CRLF
			Else
				$String &= " : " & $Array[$i + 2] & @CRLF
			EndIf
		EndIf
		$i += 3
	Until $i >= UBound($Array)
	Return $String
EndFunc


Func WriteModule($Block, $Group)
	Local $ModuleName = ParseForOneTag($Block, "@module")
	DirCreate(@ScriptDir & "\TEMP")
	Local $Output = FileOpen(@ScriptDir & "\TEMP\" & $Group & "." & $ModuleName & ".md", $FO_OVERWRITE)
	Local $Data = ""
	Local $DataPos = 1

	FileWrite($Log, @CRLF&@TAB&"Writing "&$Group & "." & $ModuleName & ".md" &@CRLF)
	FileWrite($Log, "Writing Module "&$ModuleName&@CRLF)

	; Add title of Module
	FileWrite($Output, "# " & $Group & "." & $ModuleName & " Module" & @CRLF)

	; Copy the short description
	While StringRight($Data, 1) <> @CRLF And StringRight($Data, 1) <> @CR
		If StringRight($Data, 7) == "@module" Then ; If there is no comment in the module block
			Return $Output
		EndIf
		$Data &= StringMid($Block, $DataPos, 1)
		$DataPos += 1
	WEnd
	$Data = StringTrimRight($Data, 1)
	$Block = StringTrimLeft($Block, $DataPos)
	FileWrite($Output, $Data & @CRLF)

	; copy the long description
	$DataPos = 1
	$Data = ""
	$Omit = False
	While StringRight($Data, 7) <> "@module"
		$Data &= StringMid($Block, $DataPos, 1)
		$DataPos += 1
	WEnd
	$Data = StringTrimRight($Data, 8)
	FileWrite($Output, $Data & @CRLF)
	Return $Output
EndFunc


Func WriteType($Block, $ModuleName, $Output)
	Local $TypeName = ParseForOneTag($Block, "@type")
	Local $ParentClass = GetData($TypeName, "parent")
	Local $Fields = ParseForTags($Block, "@field")

	FileWrite($Log, "Writing Type "&$TypeName&@CRLF)

	; Add title of Type
	FileWrite($Output, "## " & $TypeName & " Class" & @CRLF)

	; Add hierearchy info if necessary. Some cool ASCII drawing is going on !
	If $ParentClass <> "ROOT" Then
		FileWrite($Output, "<pre>" & @CRLF)
		FileWrite($Output, "Inheritance : The " & $TypeName & " Class inherits from the following parents :" & @CRLF)
		Local $Hierarchy = GetParents($TypeName)
		Local $String = ""
		Local $TabBuffer = @TAB
		$String &= $Hierarchy[0]&@CRLF
		For $i=1 to UBound($Hierarchy)-1
			$String &= $TabBuffer&"`-- "&$Hierarchy[$i]&@CRLF
			$TabBuffer &= @TAB
		Next
		FileWrite($Output, $String)
		FileWrite($Output, "</pre>" & @CRLF)
	Else
		FileWrite($Output, "<pre>" & @CRLF)
		FileWrite($Output, "The " & $TypeName & " class does not inherit" & @CRLF)
		FileWrite($Output, "</pre>" & @CRLF)
	EndIf

	; Copy the long description
	Local $DataPos = 1
	Local $Data = ""
	Local $Omit = False

	While StringRight($Data, 1) <> @CR ; We discard the first line
		$Data &= StringMid($Block, $DataPos, 1)
		$DataPos += 1
	WEnd
	; If there is a tag in the first line, there is no description
	if StringInStr($Data, "@type") == 0 and StringInStr($Data, "@extends") == 0 and StringInStr($Data, "@field") == 0 Then
		$Data = ""
		$DataPos += 1

		While StringRight($Data, 5) <> "@type"
			$Data &= StringMid($Block, $DataPos, 1)
			$DataPos += 1
		WEnd
		$Data = StringTrimRight($Data, 5)
		FileWrite($Output, $Data & @CRLF)
	EndIf

	; Add the Attributes
	If IsArray($Fields) Then
		FileWrite($Output, "<h4> Attributes </h4>" & @CRLF & @CRLF)
		FileWrite($Output, ArrayToList($Fields, False) & @CRLF)
	EndIf
	FileWrite($Output, @CRLF)
	Return $TypeName
EndFunc



Func WriteFunction($Block, $Declaration, $Output)
	Local $RegexResult = ParseFunctionName($Block, $Declaration)
	Local $FunctionName = $RegexResult[0]
	Local $TypeName = $RegexResult[1]
	Local $Parameters = ParseParams($Block, $Declaration)
	Local $Returns = ParseForTags($Block, "@return")
	Local $Usage = ParseForOneTag($Block, "@usage")
	Local $RegexResult

	FileWrite($Log, "Writing Function "&$FunctionName&@CRLF)

	If StringLeft($FunctionName, 1) == "_" Then
		_FileWriteLog($Log, @TAB&@Tab&"Function is private. Ignored." & @CRLF)
		Return $FunctionName
	EndIf
	; Add the class before the function name
	If IsArray($Parameters)  Then
		If $Parameters[1] == "self" Then
			$FunctionName = $TypeName & ":" & $FunctionName
		EndIf
	Else
		$FunctionName = $TypeName & "." & $FunctionName
	EndIf

	; add the parameters in parenthesis
	$FunctionName &= "("
	If IsArray($Parameters) Then
		For $i = 3 To UBound($Parameters) - 3 Step 3
			$FunctionName &= $Parameters[$i + 1] & ", "
		Next
		If UBound($Parameters) > 3 Then
			$FunctionName = StringTrimRight($FunctionName, 2)
		EndIf
	EndIf
	$FunctionName &= ")"

	;write the file name
	FileWrite($Output, "### " & $FunctionName & @CRLF)

	;Write the exemple if any
	If $Usage <> "" Then
		FileWrite($Output, "``` lua")
		FileWrite($Output, $Usage)
		FileWrite($Output, "```" & @CRLF)
	EndIf

	;Write the description
	FileWrite($Log, $Block)
	FileWrite($Log, StringTrimRight($Block, StringLen($Block) - StringInStr($Block, "@param") + 1) & @CRLF)
	FileWrite($Output, StringTrimRight($Block, StringLen($Block) - StringInStr($Block, "@param") + 1) & @CRLF)

	; Write the parameters
	FileWrite($Output, "<h4> Parameters </h4>" & @CRLF)
	If IsArray($Parameters) Then
		FileWrite($Output, ArrayToList($Parameters, False) & @CRLF)
	EndIf

	; Write the returns
	FileWrite($Output, "<h4> Returns </h4>" & @CRLF)
	If IsArray($Returns) Then
		FileWrite($Output, ArrayToList($Returns, True) & @CRLF)
	EndIf

	FileWrite($Output, @CRLF)

	; add to the list of function balises (useful for hyperlinks)
	$RegexResult = ParseFunctionName($Block, $Declaration)
	Local $URLBalise = $TypeName & "-" & $RegexResult[0] & "-"
	If IsArray($Parameters) Then
		For $i = 3 To UBound($Parameters) - 3 Step 3
			$URLBalise &= StringLower($Parameters[$i + 1]) & "-"
		Next
	EndIf
	$URLBalise = StringTrimRight($URLBalise, 1)
	FileWrite($FunctionList, $URLBalise & @CRLF)
	return $FunctionName
EndFunc