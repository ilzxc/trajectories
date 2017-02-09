osc = require './compute'

###
    the current sketches seem to be dedicated to the following data model for
    paths -> doppler / envelope effects:
    model = {
        totalTime: 5000
        startTime: null
        path: null
        minDistance: 3
        distanceCircle: 1
        headPosition: view.center
        prevDistance: null
        prevTime: null
    }

    however, the refactor requires variance of speeds on paths, and requires
    annotations for "idle" behaviors at particular destinations.

    two things on the todo:
    1. make the model a part of the path, since we're already passing the path
       everywhere, so that the buttons need to store just one reference
    2. organize the types of path-nodes into subclasses through prototypes,
       which should make it easy to extend additional behaviors

    the harder part is trying to figure out how the tools ought to behave,
    given the requirement to constantly cut up a path into a number of varied
    segments.
###

play = (path) ->
    # button graphics, position indicator & osc
    # due to the Paper.js scoping issues, we need the interactive
    # button to store references to other objects so we can access
    # them from onMouseDown callback scope:
    @button = new Path.Circle {
        center: [25, 25]
        radius: 20
        fillColor: 'blue'
    }
    @button.positionIndicator = new Path.Circle {
        center: [-100, -100]
        radius: 10
        strokeColor: 'blue'
        strokeWidth: 2
    }
    @button.osc = new osc.oscudp()
   
    # button properties for playing & exporting, just as above
    @button.totalTime = 5000
    @button.startTime = null
    @button.path = path
    @button.paused = false 
    @button.minDistance = 3
    @button.distanceCircle = 1
    @button.headPosition = view.center
    # @button.headDistance = null
    @button.prevDistance = null
    @button.prevTime = null

    @button.onMouseDown = (event) ->
        console.log "play initiated"
        console.log @totalTime, @minDistance, @distanceCircle
        if @startTime is not null
            console.log "@paused, before", @paused
            @paused = !(@paused)
            console.log "@paused, after", @paused
            return
        @startTime = (new Date()).getTime()
        @positionIndicator.position = @path.getPointAt 0
        # @headDistance = @headPosition.getDistance @path.getPointAt (@path.getNearestLocation @headPosition).offset
        return

    @update = () ->
        if @button.startTime is null or @button.paused then return
        @button.osc.generate @button
        return
    return this

smooth = (pathRef) ->
    @button = new Path.Circle {
        center: [65, 25]
        radius: 20
        fillColor: 'green'
    }
    @button.pathRef = pathRef
    @updatePath = (newPath) -> @button.pathRef = newPath
    @button.onMouseDown = (event) ->
        console.log "smooth activated"
        console.log @pathRef
        @pathRef.smooth()
        return
    return this

exporter = (pathRef, playButton) ->
    @button = new Path.Circle {
        center: [105, 25]
        radius: 20
        fillColor: 'red'
    }
    @button.pathRef = pathRef
    @button.pb = playButton
    @button.onMouseDown = (event) ->
        compute = require './compute'
        compute.generate @pathRef, @pb.totalTime / 1000, @pb.minDistance, @pb.distanceCircle, view.center 
        return
    @setTime = (time) -> @button.time = time
    @setMinDistance = (minDistance) -> @button.minDistance = minDistance
    @setHeadPosition = (headPosition) -> @button.headPosition = headPosition
    return this

distNum = (playButton) ->
    @numbox = new PointText {
        point: [690, 30]
        justification: 'right'
        fontSize: 15
        fillColor: 'black'
    }
    @numbox.playButton = playButton
    @numbox.content = '' + @numbox.playButton.minDistance.toFixed(2) + ' m'
    @numbox.onMouseDrag = (event) ->
        @playButton.minDistance += event.delta.x * 0.01
        if @playButton.minDistance < 0.01 then @playButton.minDistance = 0.01
        @content = '' + @playButton.minDistance.toFixed(2) + ' m'
        return
    return this

timeNum = (playButton) ->
    @numbox = new PointText {
        point: [600, 30]
        justification: 'right'
        fontSize: 15
        fillColor: 'black'
    }
    @numbox.playButton = playButton
    @numbox.content = '' + (@numbox.playButton.totalTime / 1000).toFixed(2) + ' s'
    @numbox.onMouseDrag = (event) ->
        @playButton.totalTime += event.delta.x * 4
        if @playButton.totalTime < 100 then @playButton.totalTime = 100
        @content = '' + (@playButton.totalTime / 1000).toFixed(2) + ' s'
        return
    return this

head = (radius) ->
    @head = ((new Path.Circle {
            center: [0, 0]
            radius: radius
        }).unite new Path.Circle {
            center: [radius, 0]
            radius: radius / 2
        }).unite new Path.Circle {
            center: [-radius, 0]
            radius: radius / 2
        }
    @head.position = view.center
    @head.strokeWidth = 2
    @head.fillColor = 'white'
    @head.strokeColor = 'black'
    return this

grid = () ->
    @grid = []
    for i in [0...(window.innerWidth / 25)]
        @grid.push new Path.Line {
            from: [i * 25, 0]
            to: [i * 25, 700]
            strokeColor: 'grey'
            strokeWidth: 0.2
        }
    for i in [0...(window.innerHeight / 25)]
        @grid.push new Path.Line {
            from: [0, i * 25]
            to: [700, i * 25]
            strokeColor: 'grey'
            strokeWidth: 0.2
        }
    return this

module.exports = { play, smooth, exporter, distNum, timeNum, head, grid }
