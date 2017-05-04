#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=..\bin\SlateDocGenerator2.exe
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs
This is the main script

The script goal is to read .lua file, extract the documentation in comment blocks, and write .md files to be converted to html by Slate : https://github.com/lord/slate
It works in 5 steps :

First, it reads the .lua files one bt one, indentifying the comment blocks. for each comment block, it determines the kind of content the comment block describes (module, class/type or function),
find some usefull stuff (for exemple in the declaration...) and writes all of this info in the creatively named TreeHierarchy.csv, with this format :
@K=kind, @M=ParentModule, @N=Name, @P=Parent, @F=FileWhereTheCommentBlockIsLocated, @C=CarretPositionOfTheCommentBlock
The functions used to do this step are mostly found in Parser.au3

Then the second step is the longest : we sort the TreeHiearchy.csv, and put the result into TreeHierarchySorted.csv
The idea is to have the data in this order :
Module A
Class A (belongs to Module A)
Function A (belongs to Class A)
Function B (belongs to Class A)
Class B Class A (belongs to Module A)
Function C (belongs to Class B)
Function D (belongs to Class B)
Module B ...
The functions used to do this step are found in DataStorer.au3

Then, step 3 : We read each line of TreeHierarchySorted.csv, read the appropriate comment block in the .lua source files,
and write the appropriate Markdown documentation for it in a temporary folder
This is where the markdown documentation is actually written for the first time.
The functions used to do this step are found in Writer.au3

Step 4 ! We read the newly created Markdown files, trying to find hyperlinks/picture paths... and we replace them with the new ones.
We copy each processed file into it's final destination.
The functions used to do this step are mostly found in Parser.au3

And finally Step 5 : We add the new markdown files to Slate's index and delete temporary files and folder
#ce

#include <FileConstants.au3>
#include <StringConstants.au3>
#include <Array.au3>
#include <File.au3>

; Those are the arguments that need to be passed at the start
Global $SourceFolder = $CmdLine[1] ;"./Results"
Global $OutputFolder = $CmdLine[2] ;"@ScriptDir&"/source/index.html.md"

Global $Log = FileOpen(@ScriptDir & "\SlateGenerator2.log", 2)
Global $DataFile = FileOpen(@ScriptDir & "\TreeHierarchy.csv", 2)
Global $FunctionList = FileOpen(@ScriptDir & "\FuctionList.txt", 2)

#include "Parser.au3"
#include "DataStorer.au3"
#include "Writer.au3"


Func ExitCleanly()
	FileClose($DataFile)
	FileClose($FunctionList)
	FileWrite($Log, "SlateGenerator2 exited cleanly")
	FileClose($Log)
EndFunc


; Small function to determine if a comment block is describing a module, a type or a function
Func IdentifyBlock($Block, $Declaration)
	Local $Kind
	Local $KindFunction

	$Kind = ParseForOneTag($Block, "@module")
	If $Kind Then
		Return "module"
	EndIf

	$Kind = ParseForOneTag($Block, "@type")
	If $Kind Then
		Return "type"
	EndIf


	$KindFunction = ParseFunctionName($Block, $Declaration)
	If $KindFunction[0] Then
		Return "function"
	EndIf

	Return ""
EndFunc




; -----------------------------------------------------------------
; Main
; -----------------------------------------------------------------

; Step 1 !
; -----------------------------------------------------------------

Local $SourceList = _FileListToArrayRec($SourceFolder, "*", $FLTAR_FILES, $FLTAR_RECUR, $FLTAR_NOSORT, $FLTAR_FULLPATH)
Local $CurrentFile
Local $CarretPos = 0
Local $CommentBlock
Local $CommentKind
Local $CommentInfo[2]
Local $CurrentModule

ConsoleWrite("1. Parsing Source Files... ")
FileWrite($Log, @CRLF&@CRLF&@TAB&"INFO : Building Hierarchy" & @CRLF)
For $i=1 To $SourceList[0] ; for each .lua source file


	FileWrite($Log, "DEBUG : "&$SourceList[$i])

	; let's read the next .lua source file
	$CurrentFile = FileOpen($SourceList[$i], $FO_READ)
	FileWrite($Log, @CRLF&"INFO : Reading File "&$SourceList[$i] & @CRLF)
	While True ; for each comment block in the current .lua source file

		; We read the next comment block. If we could not, it's probably eof, time to open the next .lua file
		$CommentBlock = ReadNextBlock($CurrentFile, $CarretPos)
		If Not $CommentBlock[1] Then
			ExitLoop
		EndIf

		$CarretPos = $CommentBlock[0]
		$CommentKind = IdentifyBlock($CommentBlock[1], $CommentBlock[2])
		; Depending on the kind of comment block it is, we write the appropriate line in TreeHierarchy.csv
		Switch $CommentKind
			Case "function"
				$CommentInfo = ParseFunctionName($CommentBlock[1], $CommentBlock[2])
				AddNode("function", $CurrentModule, $CommentInfo[0], $CommentInfo[1], $SourceList[$i], $CommentBlock[3])
				FileWrite($Log, "INFO : Added function "&$CommentInfo[0]&" to hierarchy" & @CRLF)
			Case "type"
				$CommentInfo[0] = ParseForOneTag($CommentBlock[1], "@type")
				$CommentInfo[1] = ParseForOneTag($CommentBlock[1], "@extends")
				$CommentInfo[1] = StringRegExpReplace($CommentInfo[1], "(.*#)", "")
				AddNode("type", $CurrentModule, $CommentInfo[0], $CommentInfo[1], $SourceList[$i], $CommentBlock[3])
			FileWrite($Log, "INFO : Added type "&$CommentInfo[0]&" to hierarchy" & @CRLF)
			Case "module"
				$CurrentModule = ParseForOneTag($CommentBlock[1], "@module")
				AddNode("module", "", $CurrentModule, "", $SourceList[$i], $CommentBlock[3])
				FileWrite($Log, "INFO : Added module "&$CurrentModule&" to hierarchy" & @CRLF)
		EndSwitch

	WEnd
	$CarretPos = 0
	FileClose($CurrentFile)

Next
ConsoleWrite("Done"&@CRLF)


; Step 2 !
; -----------------------------------------------------------------
ConsoleWrite("2. Sorting Hierarchy")
FileWrite($Log, @CRLF&@CRLF&@TAB&"INFO : Sorting Hierarchy" & @CRLF)
; The magic happens in DataStorer.au3
DataSort()
ConsoleWrite("Done"&@CRLF)



; Step 3 !
; -----------------------------------------------------------------
ConsoleWrite("3. Writing Markdown Documentation")
FileWrite($Log, @CRLF&@CRLF&@TAB&"INFO : Writing Markdown Documentation" & @CRLF)

Local $CurrentOutput
Local $CurrentFolder
Local $RegexResult
Local $Line
Local $CarretPos = 0
Local $Results
Local $Output
Local $Declaration

FileSetPos($DataFile, 0, $FILE_BEGIN)
While True ; For each line in TreeHierarchySorted.csv

	; read the next line until eof
	FileSetPos($DataFile, $CarretPos, $FILE_BEGIN)
	$Line = FileReadLine($DataFile)
	If @error Then ; eof
		ExitLoop
	Endif

	$CarretPos = FileGetPos($DataFile)

	; find the file/position of the next comment block referenced in the line
	$RegexResult = StringRegExp($Line, "\@F=(.+?),", $STR_REGEXPARRAYMATCH)
	$CurrentFile = FileOpen($RegexResult[0], $FO_READ)

	$RegexResult = StringRegExp($Line, "\@C=(.+?),", $STR_REGEXPARRAYMATCH)
	$DataPos = $RegexResult[0]

	; get the comment block itself
	$Results = ReadNextBlock($CurrentFile, $DataPos)
	$Block = $Results[1]
	$Declaration = $Results[2]


	; choose the right function to write mardown depending on the type of comment block
	$RegexResult = StringRegExp($Line, "\@K=(.+?),", $STR_REGEXPARRAYMATCH)

	If $RegexResult[0] == "module" Then
		ConsoleWrite(".")
		; We need the name of the folder containing this particular source file
		$RegexResult = StringRegExp($Line, "\@F=(.+?),", $STR_REGEXPARRAYMATCH)
		$RegexResult = StringRegExp($RegexResult[0], "\\(.*)\\.*\.lua", $STR_REGEXPARRAYMATCH)
		If @error Then
			$CurrentFolder = ""
		Else
			$CurrentFolder = $RegexResult[0]
		Endif

		; Now we can write the markdown for this module
		$CurrentOutput = WriteModule($Block, $CurrentFolder)
	EndIf

	If $RegexResult[0] == "type" Then
		; We need the name of the Module containing the type
		$RegexResult = StringRegExp($Line, "\@M=(.+?),", $STR_REGEXPARRAYMATCH)

		; Now we can write the markdown for this type
		WriteType($Block, $RegexResult[0], $CurrentOutput)
	EndIf

	If $RegexResult[0] == "function" Then
		; We can write the markdown for this function
		WriteFunction($Block, $Declaration, $CurrentOutput)
	EndIf

	FileClose($CurrentFile)
Wend
ConsoleWrite("Done"&@CRLF)


; Step 4 !
; -----------------------------------------------------------------
ConsoleWrite("4. Processing Hyperlinks...")
FileWrite($Log, @CRLF&@CRLF&@TAB&"INFO : Processing Hyperlinks" & @CRLF)
Local $i=1
Local $TempFilesArray = _FileListToArray(@ScriptDir & "/TEMP")
Local $CurrentFile
Local $FinalFile
While $i <= $TempFilesArray[0] ; For each markdown file in the temporary folder

	;read the file
	$CurrentFile = FileOpen(@ScriptDir & "/TEMP/" & $TempFilesArray[$i], 0)
	; The magic happens in Parser.au3
	$FinalString = ReplaceHyperlinks($CurrentFile)

	; copy the result to the final file location
	$FinalFile = FileOpen($OutputFolder & "/includes/" & $TempFilesArray[$i], 2)
	FileWrite($FinalFile, $FinalString)

	FileClose($FinalFile)
	FileClose($CurrentFile)
	$i += 1
WEnd
ConsoleWrite("Done"&@CRLF)


; Step 5 !
; -----------------------------------------------------------------
ConsoleWrite("5. Adding new documentation to index...")
FileWrite($Log, @CRLF&@CRLF&@TAB&"INFO : Adding new documentation to index" & @CRLF)

; Now this is a bit annoying : there is no way to insert a line in a document.
; So we need to read the first half of it, read the second half, and the wipe the whole document
; This way, in the new doc, we can write the first half, what we wanted to insert, and then the second half !

; Let's store the index file in $IndexString
Local $IndexFile = $OutputFolder&"/index.html.md"
Local $IndexFileHandle = FileOpen($IndexFile, 0)
Local $IndexString = FileRead($IndexFileHandle)
$IndexString = StringRegExpReplace($IndexString, "-\h[A-Z][a-z]+\.[A-Z][a-z]+\s", "")

; Now we slpit it into and store the results in $BeforeString and $AfterString
Local $SearchPos = StringInStr($IndexString, "search:")
local $BeforeString = StringTrimRight($IndexString, StringLen($IndexString) - $SearchPos + 5)
local $AfterString = StringTrimLeft($IndexString, $SearchPos - 1)

; reopening the index file wiping everything
FileClose($IndexFileHandle)
$IndexFileHandle = FileOpen($IndexFile, 2)

; write the first half
FileWrite($IndexFileHandle, $BeforeString)
Local $IncludePos = StringInStr($IndexString, "includes:")
FileSetPos($IndexFileHandle, $IncludePos + 10, $FILE_BEGIN)

; add the new markdown files to the index
$i = 1
While $i <= $TempFilesArray[0]
	FileWrite($Log, StringTrimRight($TempFilesArray[$i], 3)&@CRLF)

	FileWrite($IndexFileHandle, "  - "&StringTrimRight($TempFilesArray[$i], 3)&@CRLF)
	$i+=1
WEnd
FileWrite($IndexFileHandle, @CRLF)

; append the second half of the file
FileWrite($IndexFileHandle, $AfterString)
FileClose($IndexFileHandle)
ConsoleWrite("Done"&@CRLF)

; WE ARE DONE !
ExitCleanly()
