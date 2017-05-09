@echo off

:: Generate Luadocumentor documentation
echo Generating LuaDocumentor Documentation
echo --------------------------------------
call luadocumentor.bat

:: Generate Slate documentation
echo Generating Slate Documentation
echo ------------------------------
cd "Slate Documentation Generator"
call Generate.bat
cd ..