{ app, BrowserWindow } = require 'electron'
mainWindow = null;

app.on 'ready', () ->
    mainWindow = new BrowserWindow { width: 1400, height: 800 }
    mainWindow.loadURL 'file:///' + __dirname + '/index.html'
    return 
