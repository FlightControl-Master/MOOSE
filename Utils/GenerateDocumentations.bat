@echo off

:: Generate Luadocumentor documentation
echo Generating LuaDocumentor Documentation
echo --------------------------------------
call luadocumentor.bat

rem :: Generate Slate documentation
rem echo Generating Slate Documentation
rem echo ------------------------------
rem cd "Slate Documentation Generator"
rem call Generate.bat
rem cd ..