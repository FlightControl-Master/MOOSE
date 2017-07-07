; This file include every function strictly related to the parsing of data in .lua files

; Get the first comment block after $CarretPos
; We will also grab function declaration if possible/applicable
; The return is a Array : CarretPosition|BlockContent|Declaration|CarretPositionStart
Func ReadNextBlock($File, $CarretPos)
	local $CommentBlock = "" ; This is where we'll store the comment block
	local $Declaration = "" ; This is the next line after the comment block : usually the declaration statement
	local $CurrentLine = ""
	local $CurrentCarretPos = 0

	local $IsCommentBlock = False

	local $RegExResult
	local $RegexPos

	; Start reading from $CarretPos
	FileSetPos($File, $CarretPos, $FILE_BEGIN)

	; Read till we find a comment block
	Do
		$CurrentLine = FileReadLine($File)
		If @error Then ; We probably reached the eof
			Local $ReturnArray[3] = [$CurrentCarretPos, "", ""]
			Return $ReturnArray
		ElseIf StringInStr($CurrentLine, "---") Then
			$IsCommentBlock = True
		EndIf
	Until $IsCommentBlock

	Local $CarretPosStart = FileGetPos($File) - StringLen($CurrentLine) - 2

	; Add the first line to our comment block
	$RegExResult = StringRegExp($CurrentLine, "---(.*)", $STR_REGEXPARRAYMATCH)
	If Not @error Then ; The first line of the comment could be empty !
		$CommentBlock &= $RegExResult[0]&@CRLF
	EndIf

	; Read the comment block
	Do
		$CurrentCarretPos = FileGetPos($File)
		$CurrentLine = FileReadLine($File)
		If StringInStr($CurrentLine, "--") Then ; If we can't find any "--" in the line, then it's not the comment block anymore
			$RegExResult = StringRegExp($CurrentLine, "--(.*)", $STR_REGEXPARRAYMATCH)
			If Not @error Then; The line of the comment could be empty !
				$CommentBlock &= $RegExResult[0]&@CRLF
			EndIf
		Else
			$IsCommentBlock = False
		EndIf
	Until Not $IsCommentBlock

	; Ok, so now this is strange. If the comment block is class', we're going to have to check the
	; next comment block. If this next comment block contains a field, that is the same name as the class, then this
	; new comment block contains the whole informtion for the class. This is very shitty, but it's a workaround to
	; make intellisense show classes info while programing
	If ParseForOneTag($CommentBlock, "@type") Then
		Local $CommentBlock2 = ""
		Do
			$CurrentLine = FileReadLine($File)
			If @error Then
				Local $ReturnArray[3] = [$CurrentCarretPos, "", ""]
				Return $ReturnArray
			ElseIf StringInStr($CurrentLine, "---") Then
				$IsCommentBlock = True
			EndIf
		Until $IsCommentBlock

		$RegExResult = StringRegExp($CurrentLine, "---(.*)", $STR_REGEXPARRAYMATCH)
		If Not @error Then
			$CommentBlock2 &= $RegExResult[0]&@CRLF
		EndIf

		; Yep, the next comment is the description of the class, let's read on !
		If StringInStr($CurrentLine, ParseForOneTag($CommentBlock, "@type")) And StringInStr($CurrentLine, "extend") Then

			Do
				$CurrentLine = FileReadLine($File)
				If StringInStr($CurrentLine, "--") Then
					$RegExResult = StringRegExp($CurrentLine, "--(.*)", $STR_REGEXPARRAYMATCH)
					If Not @error Then
						$CommentBlock2 &= $RegExResult[0]&@CRLF
					EndIf
				Else
					$IsCommentBlock = False
				EndIf
			Until Not $IsCommentBlock

			; remove the line(s) with "@field" in the comment block. They are only needed for the intellisense hack
			While 1
				$RegexResult = StringRegExp($CommentBlock2, "(.*)@field(.*)", $STR_REGEXPARRAYMATCH, $RegexPos)
				$RegexPos = @extended
				If @extended == 0 Then ExitLoop

				$CommentBlock2 = StringRegExpReplace($CommentBlock2, "(.*)@field(.*)", "", 1)
			WEnd

			; We also don't need the first line of the first comment block anymore...
			; $CommentBlock = StringRegExpReplace($CommentBlock, "(.*)", "", 1)

			; append the description at the start of the comment block
			$CommentBlock = $CommentBlock2&$CommentBlock
		EndIf


		; We also need to check if the type is a list or a map. If so, the comment block does not describe a class, but a simple list / map.
		; It will have the formatting of a class, though, because it's closer closer to the actual code, even though it is highly confusing.
		; But it will only have 1 field : the list or map.
		If StringInStr($CommentBlock, "@list") Then
			$RegExResult = StringRegExp($CommentBlock, "@list\h<(.*?)>\h(.*)", $STR_REGEXPARRAYMATCH)
			if not @error Then
				$CommentBlock &= "@field #table["&$RegExResult[0]&"] "&$RegExResult[1]
			EndIf
		EndIf
		; TODO : Add support for @map the same way...
	EndIf




	; We'll take the next line, as it might be the declaration statement
	$Declaration = $CurrentLine



	; let's do some cleanup
	$CommentBlock = StringRegExpReplace($CommentBlock, "(?m)^\h+", "") ;remove leading whitespaces
	$CommentBlock = StringRegExpReplace($CommentBlock, "(?m)\h+$", "") ;remove trailing whitespaces
	$CommentBlock = StringRegExpReplace($CommentBlock, "(?m)^[#]+", "##### ")
	$CommentBlock = StringRegExpReplace($CommentBlock, "(?m)^\h+", "") ;remove leading whitespaces again now that we removed the "#"s
	$CommentBlock = StringRegExpReplace($CommentBlock, "(?m)-{3,}", "") ;remove sequences of at least 3 "-" which will mess up markdown
	$CommentBlock = StringRegExpReplace($CommentBlock, "(?m)={3,}", "") ; remove sequences of at least 3 "=" which will mess up markdown

	Local $ReturnArray[4] = [$CurrentCarretPos, $CommentBlock, $Declaration, $CarretPosStart]
	Return $ReturnArray
EndFunc

; Parses the block and returns the data for one tag
; don't use it to find the function tag !
Func ParseForOneTag($Block, $Tag)
	Local $i = 1
	Local $DataArray[1]
	Local $RegexResult[1]
	Local $RegexPos = 1
	Local $Regex

	; If we look for @usage, then it's a multiline data, the regex is different
	If $Tag == "@usage" Then
		$Regex = "(?s)@usage(.*)"
		$RegexResult = StringRegExp($Block, $Regex, $STR_REGEXPARRAYMATCH, $RegexPos)
	Else
		$Regex = $Tag&"\h(.*)\s"
		$RegexResult = StringRegExp($Block, $Regex, $STR_REGEXPARRAYMATCH, $RegexPos)
	Endif

	If @error Then
		Return ""
	Else
		Return $RegexResult[0]
	EndIf

EndFunc   ;==>ReadOneTag

; Parses the block and returns the data for multiple tags in an array
; Don't use it for @param !
Func ParseForTags($Block, $Tag)
	Local $i = 1
	Local $DataArray[1]
	Local $RegexResult[1]
	Local $RegexPos = 1

	Local $Regex = $Tag&"(?m)\h([^\s]*)(?:\h)?([^\s]*)?(?:\h)?(.*)?$"
	; For each tag
	While True
		$RegexResult = StringRegExp($Block, $Regex, $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If $RegexPos == 0 Then ; We couldn't find any tag
			If Not $DataArray[0] Then
				Return ""
			Else
				Return $DataArray
			EndIf
		EndIf

		; Add the tag to the array.The array looks like this : type1|param1|description1|type2...
		ReDim $DataArray[$i * 3]
		$DataArray[($i * 3) - 3] = $RegexResult[0]
		If $RegexResult[1] == "" Then
			$DataArray[($i * 3) - 2] = "self" ; if the first param doesn't have a name, then it's self
		Else
			$DataArray[($i * 3) - 2] = $RegexResult[1]
		EndIf
		$DataArray[($i * 3) - 1] = $RegexResult[2]
		$i += 1
	WEnd
EndFunc

; Parses both the comment block and the declaration to find the function name and it's type
; Compares both of them if possible, but will always return the one in the comment block if possible
Func ParseFunctionName($CommentBlock, $Declaration)
	local $RegExResult
	local $FunctionNameFromDec
	local $FunctionNameFromComment
	local $ReturnArray[2]

	; Parse for function name in both the comment block and the desclaration
	$RegExResult = StringRegExp($CommentBlock, "\@function\h(?:(\[.*\]\h))?(.*)", $STR_REGEXPARRAYMATCH)
	If Not @error Then
		$FunctionNameFromComment = $RegExResult[1]
	EndIf
	$RegExResult = StringRegExp($Declaration, "function\h(?:.*\:)?(.*)\(.*\)", $STR_REGEXPARRAYMATCH)
	If Not @error Then
		$FunctionNameFromDec = $RegExResult[0]
	EndIf

	; compare them to each other
	If $FunctionNameFromComment Then
		If $FunctionNameFromDec <> $FunctionNameFromComment Then
			FileWrite($Log,"CAUTION : The commented function doesn't match its declaration : "&$FunctionNameFromComment& " -> "&$Declaration&@CRLF)
		EndIf
		$ReturnArray[0] = $FunctionNameFromComment
	ElseIf $FunctionNameFromDec Then
		;FileWrite($Log, "CAUTION: No data matching @function found in block, inferring the function name from its declaration : "& $FunctionNameFromDec & @CRLF)
		$ReturnArray[0] = $FunctionNameFromDec
	Else
		$ReturnArray[0] = ""
		$ReturnArray[1] = ""
		return $ReturnArray
	EndIf

	;parses for function type in both the comment block and the desclaration
	local $TypeFromComment
	local $TypeFromDec

	$RegExResult = StringRegExp($Declaration, "function\h(.*):", $STR_REGEXPARRAYMATCH)
	If Not @error Then
		$TypeFromDec = $RegExResult[0]
	EndIf
	$RegExResult = StringRegExp($CommentBlock, "function\h\[parent=#(.*)\]", $STR_REGEXPARRAYMATCH)
	If Not @error Then
		$TypeFromComment = $RegExResult[0]
	EndIf

	; compare them to each other
	If $TypeFromComment Then
		If $TypeFromDec <> $TypeFromComment Then
			FileWrite($Log,"CAUTION : The commented function type doesn't match its declaration : "&$TypeFromComment& " -> "&$Declaration&@CRLF)
		EndIf
		$ReturnArray[1] = $TypeFromComment
	ElseIf $TypeFromDec Then
		;FileWrite($Log, "CAUTION: No function type found in block, inferring the function type from its declaration : "& $TypeFromDec & @CRLF)
		$ReturnArray[1] = $TypeFromDec
	Else
		$ReturnArray[0] = ""
		$ReturnArray[1] = ""
		return $ReturnArray
	EndIf

	Return $ReturnArray
EndFunc

; Specifically designed to parse for @param tags
; will verify the comment by matching with the declaration (theoretically, I'm pretty sure it's bugged)
Func ParseParams($CommentBlock, $Declaration)
	Local $ParamsFromComment = ParseForTags($CommentBlock, "@param")
	Local $RegExResult
	Local $RegexPos = StringInStr($Declaration, "(")
	Local $ParamsFromDec[0]
	Local $NbParam = 0

	If StringInStr($Declaration, ":") Then
		$NbParam = 1
		ReDim $ParamsFromDec[1]
		$ParamsFromDec[0] = "self"
	EndIf

	; extract params from function decaration
	While True
		$RegExResult = StringRegExp($Declaration, "([^,\(\)\h]+)", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NbParam += 1
		Redim $ParamsFromDec[$NbParam]
		$ParamsFromDec[$NbParam-1] = $RegExResult[0]
	WEnd

	; compare these parameters with those found in the comment block
	If UBound($ParamsFromComment) <> UBound($ParamsFromDec)*3 Then
		FileWrite($Log, "CAUTION: The number of parameters don't match between the comment block and declaration "& @CRLF)
	Else

		For $i=0 To $NbParam-1
			If $ParamsFromDec[$i] <> $ParamsFromComment[($i*3)+1] Then
				FileWrite($Log, "CAUTION: Parameters missmatch between the comment block and declaration "& @CRLF)
				FileWrite($Log, $ParamsFromComment[($i*3)+1]& " -> " & $ParamsFromDec[$i]&@CRLF)
				ExitLoop
			EndIf
		Next
	EndIf

	Return $ParamsFromComment
EndFunc

; This does 3 things :
; - Replace the hyperlinks with new ones
; - change the stuff starting with # (#nil -> <u>Nil</u>)
; - Replace pictures paths
Func ReplaceHyperlinks($TempFile)
	Local $StringFile = ""
	Local $RegexResult
	Local $RegexPos = 1
	Local $NewURL = ""
	Local $i = 0
	FileSetPos($TempFile, 0, $FILE_BEGIN)

	$StringFile = FileRead($TempFile)

	; Replace HyperLinks Using Regexs
	; ---------------------------------------------------------
	While 1 ; @{File.Module}
		$RegexResult = StringRegExp($StringFile, "\@{([A-Z][^\.#}]+)\.([^\.#}]+)}", $STR_REGEXPARRAYMATCH, $RegexPos) ;
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = "[" & $RegexResult[1] & "](#" & StringLower($RegexResult[1]) & "-module-)"
		;FileWrite($Log, "Module : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\@{([A-Z][^\.#}]+)\.([^\.#}]+)}", $NewURL, 1)
	WEnd
	While 1 ; @{Module}
		$RegexResult = StringRegExp($StringFile, "\@{([A-Z][^\.#}]+)}", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = "[" & $RegexResult[0] & "](#" & StringLower($RegexResult[0]) & "-module-)"
		;FileWrite($Log, "Module : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\@{([A-Z][^\.#}]+)}", $NewURL, 1)
	WEnd
	While 1 ; @{File.Module#TYPE}
		$RegexResult = StringRegExp($StringFile, "\@{([A-Z][^\.#}]+)\.([A-Z][^\.#}]+)#([A-Z,_]+)}", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = "[" & $RegexResult[2] & "](#" & StringLower($RegexResult[2]) & "-class-)"
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\@{([A-Z][^\.#}]+)\.([A-Z][^\.#}]+)#([A-Z,_]+)}", $NewURL, 1)
	WEnd
	While 1 ; @{Module#TYPE}
		$RegexResult = StringRegExp($StringFile, "\@{([A-Z][^\.#}]+)#([A-Z,_]+)}", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = "[" & $RegexResult[1] & "](#" & StringLower($RegexResult[1]) & "-class-)"
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\@{([A-Z][^\.#}]+)#([A-Z,_]+)}", $NewURL, 1)
	WEnd
	While 1 ; @{#TYPE}
		$RegexResult = StringRegExp($StringFile, "\@{#([A-Z,_]+)}", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = "[" & $RegexResult[0] & "](#" & StringLower($RegexResult[0]) & "-class-)"
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\@{#([A-Z,_]+)}", $NewURL, 1)
	WEnd
	While 1 ; #TYPE&@CR
		$RegexResult = StringRegExp($StringFile, "\h#([A-Z,_]+)\s", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = " [" & $RegexResult[0] & "](#" & StringLower($RegexResult[0]) & "-class-)"&@CRLF
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\h#([A-Z,_]+)\s", $NewURL, 1)
	WEnd
	While 1 ; @{File.Module#TYPE.Function}(), catches the parenthesis
		$RegexResult = StringRegExp($StringFile, "\@{([A-Z][^#}\.]+)\.([A-Z][^#}\.]+)#([A-Z,_]+)\.([^#\.]+)}[\(]?[\)]?", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = FindInFunctionList($RegexResult[2] & "-" & $RegexResult[3]&"-")
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\@{([A-Z][^#}\.]+)\.([A-Z][^#}\.]+)#([A-Z,_]+)\.([^#\.]+)}[\(]?[\)]?", $NewURL, 1)
	WEnd
	While 1 ; @{Module#TYPE.Function}(), catches the parenthesis
		$RegexResult = StringRegExp($StringFile, "\@{([A-Z][^#}\.]+)#([A-Z,_]+)\.([^#}\.]+)}[\(]?[\)]?", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = FindInFunctionList($RegexResult[1] & "-" & $RegexResult[2]&"-")
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\@{([A-Z][^#}\.]+)#([A-Z,_]+)\.([^#}\.]+)}[\(]?[\)]?", $NewURL, 1)
	WEnd
	While 1 ; @{#TYPE.Function}(), catches the parenthesis
		$RegexResult = StringRegExp($StringFile, "\@{#([A-Z,_]+)\.([^#}\.]+)}[\(]?[\)]?", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = FindInFunctionList($RegexResult[0] & "-" & $RegexResult[1]&"-")
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\@{#([A-Z,_]+)\.([^#}\.]+)}[\(]?[\)]?", $NewURL, 1)
	WEnd
	While 1 ; Module#TYPE
		$RegexResult = StringRegExp($StringFile, "\h(\w+[^\h\_])#(.*?)\h", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = " [" & $RegexResult[1] & "](#" & StringLower($RegexResult[1]) & "-class-) "
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\h(\w+[^\h\_])#(.*?)\h", $NewURL, 1)
	WEnd
	While 1 ; File.Module#TYPE
		$RegexResult = StringRegExp($StringFile, "\h(\w+)\.(\w+)#(.*?)\h", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = " [" & $RegexResult[2] & "](#" & StringLower($RegexResult[2]) & "-class-) "
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\h(\w+)\.(\w+)#(.*?)\h", $NewURL, 1)
	WEnd
	While 1 ; #TYPE.type (nested type... really annoying and confusing lua stuff)
		$RegexResult = StringRegExp($StringFile, "\h#([A-Z,_]+)\.(\w+)\h", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewURL = " [" & $RegexResult[1] & "](#" &StringLower($RegexResult[0])& "-"& StringLower($RegexResult[1]) & "-class-)"
		;FileWrite($Log, "Class : " & $RegexPos & " : " & _ArrayToString($RegexResult) & " -> " & $NewURL & @CRLF)
		$StringFile = StringRegExpReplace($StringFile, "\h#([A-Z,_]+)\.(\w+)\h", $NewURL, 1)
	WEnd

	; Clean stuff with #
	; ---------------------------------------------------------
	$StringFile = StringReplace($StringFile, "#nil", "<u>Nil</u>")
	$StringFile = StringReplace($StringFile, "#number", "<u>Number</u>")
	$StringFile = StringReplace($StringFile, "#boolean", "<u>Boolean</u>")
	$StringFile = StringReplace($StringFile, "#string", "<u>String</u>")
	$StringFile = StringReplace($StringFile, "#table", "<u>List[]</u>")
	$StringFile = StringReplace($StringFile, "#function", "<u>Function()</u>")

	; And replace the pictures Path if any
	; ---------------------------------------------------------
	While 1
		$RegexResult = StringRegExp($StringFile, "!\[(.*)\]\(.*\\(.*)\\(.*)\)", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		$NewPic = "![" & $RegexResult[0] & "](/includes/Pictures/" & $RegexResult[1] & "/"& $RegexResult[2]&")"
		$StringFile = StringRegExpReplace($StringFile, "!\[(.*)\]\(.*\\(.*)\\(.*)\)", $NewPic, 1)
	WEnd

	While 1
		$RegexResult = StringRegExp($StringFile, "(?m)^(\d(?:(\.\d))*\)(.*))$", $STR_REGEXPARRAYMATCH, $RegexPos)
		$RegexPos = @extended
		If @extended == 0 Then ExitLoop

		;$StringFile = StringRegExpReplace($StringFile, "(?m)^(\d(?:(\.\d))*\)(.*))$", "<h4>"&$RegExResult[0]&"</h4>", 1)
		$StringFile = StringRegExpReplace($StringFile, "(?m)^(\d(?:(\.\d))*\)(.*))$", "##### "&$RegExResult[0], 1)
	WEnd

	Return $StringFile
EndFunc