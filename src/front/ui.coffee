osc = require './compute'

play = (path) ->
    @button = new Path.Circle {
        center: [20, 20]
        radius: 20
        fillColor: 'blue'
    }
    @button.positionIndicator = new Path.Circle {
        center: [0, 0]
        radius: 10
        strokeColor: 'blue'
        strokeWidth: 2
    }
    @button.totalTime = 5000 # will be controlled
    @button.startTime = null
    @button.path = path
    @button.paused = false
    @button.osc = new osc.oscudp()
    # button properties for playing:
    @button.minDistance = 3
    @button.distanceCircle = 1
    @button.headPosition = view.center
    @button.headDistance = null
    @button.prevDistance = null
    @button.prevTime = null
    @button.onMouseDown = (event) ->
        if @startTime is not null 
            @paused = !(@paused)
            return
        @startTime = (new Date()).getTime()
        @positionIndicator.position = @path.getPointAt 0
        @headDistance = @headPosition.getDistance @path.getPointAt (@path.getNearestLocation @headPosition).offset
        return
    @update = () ->
        if @button.startTime is null or @button.paused then return
        @button.osc.generate @button
        # @button.t = ((new Date()).getTime() - @button.startTime) / @button.totalTime
        # if @button.t > 1 then @button.t = 1
        # @button.positionIndicator.position = @button.path.getPointAt @button.t * @button.path.length
        # if @button.t == 1
        #     @button.startTime = null
        return
    return this

smooth = (pathRef) ->
    @button = new Path.Circle {
        center: [60, 20]
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

exporter = (pathRef) ->
    @button = new Path.Circle {
        center: [100, 20]
        radius: 20
        fillColor: 'red'
    }
    @button.pathRef = pathRef
    @button.time = 5
    @button.minDistance = 3
    @button.headPosition = view.center
    @button.onMouseDown = (event) ->
        compute = require './compute'
        compute.generate @pathRef, @time, @minDistance, @headPosition 
        return
    @setTime = (time) -> @button.time = time
    @setMinDistance = (minDistance) -> @button.minDistance = minDistance
    @setHeadPosition = (headPosition) -> @button.headPosition = headPosition
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

module.exports = { play, smooth, exporter, head, grid }
