ui = require './build/front/ui'


pathData = () ->
    @path = new Path()
    @path.strokeColor = 'black'
    @path.strokeWidth = 2
    @path.fullySelected = true

    @pathStart = new Path.Circle {
        center: [0, 0]
        radius: 5
        strokeColor: 'black'
        strokeWidth: 1
        fillColor: 'black'
    }

    @pathEnd = new Path.Circle {
        center: [0, 0]
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

distanceCircle = () ->
    @path = new Path.Circle {
        center: view.center
        radius: 1
        strokeColor: '#ff0000'
        strokeCap: 'round'
        dashArray: [10, 12]
        strokeWidth: 1
    }
    @radius = 1

    @setScale = (amount) ->
        inv = 1 / @radius
        @radius = amount
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
    exportButton = new ui.exporter currentPath.path

    distance = new distanceCircle()

    head = new ui.head 10

    test = new Path.Circle {
        center: [0, 0]
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


    view.onFrame = () ->
        playButton.update()

window.onresize = () ->
    trajRef = document.getElementById('traj').style
    trajRef.width = window.innerWidth + 'px'
    trajRef.height = window.innerHeight + 'px'
    return
