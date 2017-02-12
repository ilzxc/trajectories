{ app, BrowserWindow, ipcMain, dialog } = require 'electron'

mainWindow = null;

app.on 'ready', () ->
    mainWindow = new BrowserWindow { width: 700, height: 700 }
    mainWindow.loadURL 'file:///' + __dirname + '/index.html'
    return 

ipcMain.on 'export-dialog', (event) ->
    options = {
        title: 'Export motion as a multichannel wav file'
        filters: [
            { name: 'Audio', extensions: ['wav'] }
        ]
    }
    dialog.showSaveDialog options, (filename) ->
        event.sender.send 'exported-file', filename
