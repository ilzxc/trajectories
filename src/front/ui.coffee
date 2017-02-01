play = (path) ->
    @button = new Path.Circle {
        center: [20, 20]
        radius: 20
        fillColor: 'blue'
    }
    @button.t = 0
    @button.totalTime = 5000 # will be controlled
    @button.startTime = null
    @button.positionIndicator = new Path.Circle {
        center: [0, 0]
        radius: 10
        strokeColor: 'blue'
        strokeWidth: 2
    }
    @button.currentPath = path
    @button.paused = false
    @button.onMouseDown = (event) ->
        if @startTime is not null 
            @paused = !(@paused)
            return
        d = new Date()
        @startTime = d.getTime()
        @t = 0
        @positionIndicator.position = @currentPath.getPointAt 0
        return
    @update = () ->
        if @button.startTime is null or @button.paused then return
        @button.t = ((new Date()).getTime() - @button.startTime) / @button.totalTime
        if @button.t > 1 then @button.t = 1
        @button.positionIndicator.position = @button.currentPath.getPointAt @button.t * @button.currentPath.length
        if @button.t == 1
            @button.startTime = null
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

module.exports = { play, smooth, head, grid }
