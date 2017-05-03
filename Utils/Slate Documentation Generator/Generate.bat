@echo off
:: Generate the Markdown doc
"./bin/SlateDocGenerator2.exe" "../../../MOOSE/Moose Development/Moose" ../../../slate/source

:: Do some cleanup
del /s /q "TreeHierarchySorted.csv"
del /s /q "FuctionList.txt"
rmdir /s /q "./bin/TEMP"

:: Copy the Images that go with the documentation
robocopy ../../docs/Presentations ../../../slate/source/includes/Pictures /MIR /NJH /NJS

:: Deploy the Slate documentation
echo A shell will open. To deploy the Slate website, please run the following command. Otherwise, simply close the shell.
echo $ Moose/Utils/Deploy.sh
%localappdata%\GitHub\GitHub.appref-ms --open-shell