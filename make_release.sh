#!/bin/sh

npm run pack
cp -r max ./dist/mac/max-trajectories
rm ./dist/mac/max-trajectories/*.wav
cd dist/mac
releasename=trajectories-`git describe --tags --long`-`git branch | egrep '^\*' | awk '{print $2}'`.tgz
tar zcvf $releasename .
