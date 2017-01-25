#!/bin/sh
./make.sh
fswatch ./src/*.coffee | xargs -n1 ./make.sh
