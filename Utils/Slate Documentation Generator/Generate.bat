:: Generate the Markdown doc
"./bin/SlateDocGenerator2.exe" "../../../MOOSE/Moose Development/Moose" ../../../slate/source

:: Do some cleanup
del /s /q "TreeHierarchySorted.csv"
del /s /q "FuctionList.txt"
rmdir /s /q "./bin/TEMP"

:: Copy the Images that go with the documentation
robocopy ../../docs/Presentations ../../../slate/source/includes/Pictures /MIR /NJH /NJS

:: Deploy the Slate documentation
"C:\Program Files\Git\bin\bash.exe" --login -i -c "cd slate | git commit -a -m "Doc Update" | ./deploy.sh"

