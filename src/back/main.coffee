{ app, Menu, BrowserWindow, ipcMain, dialog } = require 'electron'

mainWindow = null;

exporter = () ->
    options = {
        title: 'Export motion as a multichannel wav file'
        filters: [
            { name: 'Audio', extensions: ['wav'] }
        ]
    }
    dialog.showSaveDialog options, (filename) ->
        mainWindow.webContents.send 'exported-file', filename

saver = () ->
    options = {
        title: 'Save path(s)'
        filters: [
            { name: 'Audio', extensions: ['trajectories'] }
        ]
    }
    dialog.showSaveDialog options, (filename) ->
        mainWindow.webContents.send 'saved-file', filename


template = [
    {
        label: 'File'
        submenu: [
            { label: 'New...', accelerator: 'CmdOrCtrl+N', click: () -> return }
            { type: 'separator' }
            { label: 'Open...', accelerator: 'CmdOrCtrl+O', click: () -> return  }
            { label: 'Save', accelerator: 'CmdOrCtrl+S', click: () -> saver()  }
            { label: 'Save As...', accelerator: 'Shift+CmdOrCtrl+S', click: () -> saver() }
            { type: 'separator' }
            { label: 'Export', accelerator: 'CmdOrCtrl+E', click: () -> exporter() }
            { label: 'Quit', accelerator: 'CmdOrCtrl+Q', role: 'quit'  }
        ]
    }
]

if process.platform == 'darwin'
    template.unshift {
        label: app.getName(),
        submenu: [
            { role: 'about' }
            { type: 'separator' }
            { role: 'services', submenu: [] }
            { type: 'separator' }
            { role: 'hide' }
            { role: 'hideothers' }
            { role: 'unhide' }
            { type: 'separator' }
            { role: 'quit' }
        ]
    }

app.on 'ready', () ->
    mainWindow = new BrowserWindow { width: 700, height: 700 }
    mainWindow.loadURL 'file:///' + __dirname + '/index.html'
    menu = Menu.buildFromTemplate template
    Menu.setApplicationMenu menu
    return 

ipcMain.on 'export-dialog', (event) -> exporter()
