"use strict"

ipc = require('electron').ipcRenderer
ui = require './js/front/ui'
compute = require './js/front/compute'
pathNodes = require './js/front/pathNodes'

paper.install window
window.onload = () ->
    window.onresize()
    paper.setup 'traj'

    model = {
        totalTime: 5000
        startTime: null
        path: null
        minDistance: 0.8
        distanceRadius: 25
        distance: null
        headPosition: view.center
        headDistance: null
        # playback data:
        velocity: 0 # default velocity
        offset: 0 # the offset
        timeEstimate: 0 # zero-to-one tracking
        prevDistance: null
        prevTime: null
    }

    # setup
    canvas = new ui.canvas model

    # test = new pathNodes.node model.path, 0.5
    playButton = new ui.play model
    smoothButton = new ui.smooth model
    exportButton = new ui.exporter ipc
    distanceNum = new ui.distNum model
    timeNum = new ui.timeNum model

    # animation
    view.onFrame = () ->
        canvas.update()

    # system:
    ipc.on 'exported-file', (event, filename) ->
        if filename is null then return
        compute.generate model.path, model.totalTime / 1000, model.minDistance, model.distanceRadius, view.center, filename

window.onresize = () ->
    trajRef = document.getElementById('traj').style
    trajRef.width = window.innerWidth + 'px'
    trajRef.height = window.innerHeight + 'px'
    return
