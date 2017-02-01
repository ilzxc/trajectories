ui = require('./build/front/ui')

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

paper.install window
window.onload = () ->
    window.onresize()
    paper.setup 'traj'

    # setup
    currentPath = new pathData()
    

    testGrid = new ui.grid()
    playButton = new ui.play currentPath.path
    smoothButton = new ui.smooth currentPath.path
    head = new ui.head 10

    t = 0
    littleCircle = 

    totalTime = 5 # seconds
    currentTime = null
    t = 0

    # interaction
    tool = new Tool()
    tool.onMouseDown = (event) ->
        if event.point.y < 50 then return
        currentPath.add event
        return

    view.onFrame = () ->
        playButton.update()

window.onresize = () ->
    trajRef = document.getElementById('traj').style
    trajRef.width = window.innerWidth + 'px'
    trajRef.height = window.innerHeight + 'px'
    return
