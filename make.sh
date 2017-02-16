#!/bin/sh
coffee -c -b -o js/front src/front/*
coffee -c -b -o js/back src/back/*
cp js/back/main.js index.js
cp js/front/main.js app.js
# browserify build/front/main.js -o app.js
# uglifyjs build/back/main.js > index.js
# uglifyjs build/front/main.js > app.js
