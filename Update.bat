rem This script will pull the latest changes from the remote repository, and update the submodules accordingly.

git pull
git submodule update --init
