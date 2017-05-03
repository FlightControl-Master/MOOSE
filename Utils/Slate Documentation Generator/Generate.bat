:: Generate the Markdown doc
"./bin/SlateDocGenerator2.exe" "../../../MOOSE/Moose Development/Moose" ../../../slate/source

:: Do some cleanup
del /s /q "TreeHierarchySorted.csv"
del /s /q "FuctionList.txt"
rmdir /s /q "./bin/TEMP"

:: Copy the Images that go with the documentation
robocopy ../../docs/Presentations ../../../slate/source/includes/Pictures /MIR /NJH /NJS
