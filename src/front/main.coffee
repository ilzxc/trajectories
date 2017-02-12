ipc = require('electron').ipcRenderer
ui = require './build/front/ui'
compute = require './build/front/compute'

pathData = () ->
    @path = new Path()
    @path.strokeColor = 'black'
    @path.strokeWidth = 2
    @path.fullySelected = true

    @pathStart = new Path.Circle {
        center: [-100, 0]
        radius: 5
        strokeColor: 'black'
        strokeWidth: 1
        fillColor: 'black'
    }

    @pathEnd = new Path.Circle {
        center: [-100, 0]
        radius: 5
        strokeColor: 'black'
        strokeWidth: 1
        fillColor: 'white'
    }

    @add = (event) ->
        @path.add event.point
        @pathEnd.position = event.point
        @pathStart.position = @path.firstSegment.point
        return
    return this

distanceCircle = (playButton) ->
    @path = new Path.Circle {
        center: view.center
        radius: 1
        strokeColor: '#ff0000'
        strokeCap: 'round'
        dashArray: [1, 4]
        strokeWidth: 1
    }
    @radius = 1
    @path.pb = playButton

    @setScale = (amount) ->
        inv = 1 / @radius
        @radius = amount
        @path.pb.distanceCircle = @radius
        @path.scale [inv, inv]
        @path.scale [@radius]
        return

    return this


paper.install window
window.onload = () ->
    window.onresize()
    paper.setup 'traj'

    # setup
    currentPath = new pathData()

    grid = new ui.grid()
    playButton = new ui.play currentPath.path
    smoothButton = new ui.smooth currentPath.path
    exportButton = new ui.exporter ipc

    distanceNum = new ui.distNum playButton.button
    timeNum = new ui.timeNum playButton.button

    distance = new distanceCircle playButton.button

    head = new ui.head 10

    test = new Path.Circle {
        center: [-100, -100]
        radius: 5
        strokeColor: 'blue'
        strokeWidth: 1
        fillColor: 'orange'
    }

    # interaction
    tool = new Tool()
    tool.onMouseMove = (event) ->
        loc = currentPath.path.getNearestLocation event.point
        if loc is null then return
        test.position = currentPath.path.getPointAt loc.offset
        return


    tool.onMouseDown = (event) ->
        if event.point.y < 50 then return
        if event.event.button is 0 # left mouse button
            currentPath.add event
            return
        else
            distance.setScale (view.center).getDistance event.point
            return

    tool.onMouseDrag = (event) ->
        if event.event.button is 2 # right moust button
            distance.setScale (view.center).getDistance event.point
            return

    # animation
    view.onFrame = () ->
        playButton.update()

    # system:
    ipc.on 'exported-file', (event, filename) ->
        if filename is null then return
        pb = playButton.button
        compute.generate currentPath.path, pb.totalTime / 1000, pb.minDistance, pb.distanceCircle, view.center, filename

window.onresize = () ->
    trajRef = document.getElementById('traj').style
    trajRef.width = window.innerWidth + 'px'
    trajRef.height = window.innerHeight + 'px'
    return
