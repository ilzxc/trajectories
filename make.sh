#!/bin/sh
coffee -c -b -o build/front src/front/*
coffee -c -b -o build/back src/back/*
cp build/back/main.js index.js
browserify build/front/main.js -o app.js
# cp build/front/main.js app.js
# uglifyjs build/back/main.js > index.js
# uglifyjs build/front/main.js > app.js
