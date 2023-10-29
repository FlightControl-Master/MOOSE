#!/bin/bash

# Prepare environment
cd /moose/
mkdir -p build/result/Moose_Include_Dynamic
mkdir -p build/result/Moose_Include_Static

GIT_SHA=$(git rev-parse HEAD)
GIT_SHA=$(echo $GIT_SHA|tr -d '\n')
COMMIT_TIME=$(date +%Y-%m-%dT%H:%M:%S)

# Create Includes
lua "./Moose Setup/Moose_Create.lua" S "$COMMIT_TIME-$GIT_SHA" "./Moose Development/Moose" "./Moose Setup" "./build/result/Moose_Include_Static"
lua "./Moose Setup/Moose_Create.lua" D "$COMMIT_TIME-$GIT_SHA" "./Moose Development/Moose" "./Moose Setup" "./build/result/Moose_Include_Dynamic"

# Create Moose_.lua
luasrcdiet --basic --opt-emptylines ./build/result/Moose_Include_Static/Moose.lua -o ./build/result/Moose_Include_Static/Moose_.lua

# Run luacheck
luacheck --std=lua51c --config=.luacheckrc -gurasqq "Moose Development/Moose"
