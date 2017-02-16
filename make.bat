coffee -c -b -o js\front src\front\ui.coffee
coffee -c -b -o js\front src\front\main.coffee
coffee -c -b -o js\back src\back\main.coffee
cp js\back\main.js index.js
cp js\front\main.js app.js
