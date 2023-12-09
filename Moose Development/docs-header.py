# import required module
from pathlib import Path
import os

# assign directory
directory = '.'

print( "Replacing head tag in all html files" )

# Read template file
with open( os.path.dirname(__file__) + '/docs-header.html', 'r') as file:
  newhead = file.read()

# iterate over files in
# that directory
files = Path(directory).glob('*.html')
for file in files:
  # print(file)
  with open(file, 'r') as fileread:
    filedata = fileread.read()
    # Replace the target string
    filedata = filedata.replace( '<head>', newhead )

  # Write the file out again
  with open(file, 'w') as filewrite:
    filewrite.write(filedata)
