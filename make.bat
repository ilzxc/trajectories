coffee -c -b -o build\front src\front\ui.coffee
coffee -c -b -o build\front src\front\main.coffee
coffee -c -b -o build\back src\back\main.coffee
cp build\back\main.js index.js
cp build\front\main.js app.js
