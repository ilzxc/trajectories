"use strict"

fs = require 'fs'
ipc = require('electron').ipcRenderer
ui = require './js/front/ui'
compute = require './js/front/compute'
pathNodes = require './js/front/pathNodes'

paper.install window
window.onload = () ->
    dragDrop = require 'drag-drop'
    dragDrop '#traj', (files, pos) ->
        if files.length > 1 then return
        if files[0].name.slice(-13) == '.trajectories'
            ipc.send 'drag-open', files[0].path
        else if files[0].name.slice(-4) == '.svg'
            item = project.importSVG fs.readFileSync files[0].path, 'utf8'
            model.pathData.loadFromSVG item.children[1].segments
            item.remove()
            item = null
        return

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
        velocity: 0 # default
        offset: 0   
        timeEstimate: 0 
        prevDistance: null
        prevTime: null
    }

    # setup
    canvas = new ui.canvas model

    playButton = new ui.play model
    smoothButton = new ui.smooth model
    exportButton = new ui.exporter ipc
    moveButton = new ui.move model
    rotateButton = new ui.rotate model
    scaleButton = new ui.scale model
    distanceNum = new ui.distNum model
    timeNum = new ui.timeNum model

    # animation
    view.onFrame = () ->
        canvas.update()
        return

    # scroll wheel
    window.addEventListener 'mousewheel', (event) -> 
        # model.pathData.scalePath event.deltaY
        return false
    , false

    # system:
    ipc.on 'clear-canvas', (event) ->
        canvas.clear()
        return

    ipc.on 'load-file', (event, data) ->
        canvas.clear()
        # load path
        segments = []
        for p in data.pathSegments
            model.pathData.add { point: p.point }
            model.pathData.path.segments[model.pathData.path.segments.length - 1].handleIn = new Point p.handles[0]
            model.pathData.path.segments[model.pathData.path.segments.length - 1].handleOut = new Point p.handles[1]
        # load path velocity-altering dots:
        for v in data.variants
            model.pathData.addVariant v
        # take care of global settings scalar values
        model.totalTime = data.totalTime
        model.minDistance = data.minDistance
        model.distance.setScale data.distanceRadius
        timeNum.refresh()
        distanceNum.refresh()
        return

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

