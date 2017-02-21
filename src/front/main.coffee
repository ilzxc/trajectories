"use strict"

ipc = require('electron').ipcRenderer
ui = require './js/front/ui'
compute = require './js/front/compute'
pathNodes = require './js/front/pathNodes'
fs = require 'fs'

paper.install window
window.onload = () ->
    window.onresize()
    paper.setup 'traj'

    model = {
        # numeric data
        totalTime: 5000
        minDistance: 0.8
        distanceRadius: 25
        # graphic objects data
        path: null        
        headPosition: view.center
        distance: null
        # playback data:
        startTime: null
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
        compute.generate model, filename
        return

    ipc.on 'saved-file', (event, filename) ->
        if filename is null then return
        saveModel = {
            totalTime: model.totalTime
            minDistance: model.minDistance
            distanceRadius: model.distanceRadius
            variants: []
            pathSegments: []
        }
        for v in model.pathData.variants
            saveModel.variants.push {
                offset: v.nodeModel.offset
                start: v.nodeModel.start
                end: v.nodeModel.end
                velocity: v.nodeModel.velocity
                pause: v.nodeModel.pause
                easeIn: v.nodeModel.easeIn
                easeOut: v.nodeModel.easeOut
                behavior: v.nodeModel.behavior
            }
        for s in model.path.segments
            saveModel.pathSegments.push {
                point: [s.point.x, s.point.y]
                handles: [[s.handleIn.x, s.handleIn.y], [s.handleOut.x, s.handleOut.y]]
            }
        fs.writeFileSync filename, JSON.stringify saveModel
        return
    return

window.onresize = () ->
    trajRef = document.getElementById('traj').style
    trajRef.width = window.innerWidth + 'px'
    trajRef.height = window.innerHeight + 'px'
    return
