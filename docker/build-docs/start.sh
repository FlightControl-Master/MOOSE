#!/bin/sh

# Prepare environment
cd /moose/
mkdir -p build/tools
mkdir -p build/doc

# Checkout luadocumentor
cd /moose/build/tools
if [ ! -f /moose/build/tools/luadocumentor/luadocumentor.lua ]
then
    git clone --branch patch-1 --single-branch https://github.com/Applevangelist/luadocumentor.git
fi

# Run luadocumentor
cd /moose/build/tools/luadocumentor
lua luadocumentor.lua -d /moose/build/doc '/moose/Moose Development/Moose'

# Copy generated files in the MOOSE_DOCS repo if it is already there
if [ -d /moose/build/MOOSE_DOCS/Documentation ]; then
  rm -rf /moose/build/MOOSE_DOCS/Documentation
  mkdir -p /moose/build/MOOSE_DOCS/Documentation
  cp /moose/build/doc/* /moose/build/MOOSE_DOCS/Documentation/
fi
