"use strict"

osc = require './compute'

###
    two things on the todo:
    1. make the model a part of the path, since we're already passing the path
       everywhere, so that the buttons need to store just one reference
    2. organize the types of path-nodes into subclasses through prototypes,
       which should make it easy to extend additional behaviors

    the harder part is trying to figure out how the tools ought to behave,
    given the requirement to constantly cut up a path into a number of varied
    segments.
###

distanceCircle = (model) ->
    @path = new Path.Circle {
        center: view.center
        radius: model.distanceRadius
        strokeColor: '#ff0000'
        strokeCap: 'round'
        dashArray: [1, 4]
        strokeWidth: 1
    }
    @path.m = model
    @setScale = (amount) ->
        inv = 1 / @path.m.distanceRadius
        @path.m.distanceRadius = amount
        @path.scale [inv, inv]
        @path.scale [@path.m.distanceRadius]
        return
    return this

pathEditNode = (segment, model) ->
    result = new Path.Circle {
        point: [0, 0]
        radius: 5
        strokeColor: 'yellow'
        fillColor: 'yellow'
        opacity: .5
    }
    result.position = segment.point
    result.segment = segment
    result.onMouseDown = (event) ->
        @offset = event.point.subtract @position
        return
    result.onMouseDrag = (event) ->
        @segment.point = event.point.subtract @offset
        @position = event.point.subtract @offset
        @pathEnd.position = @path.lastSegment.point
        @pathStart.position = @path.firstSegment.point
        return
    return result

pathData = (model) ->
    @path = new Path()
    @path.strokeColor = 'black'
    @path.strokeWidth = 2
    @path.fullySelected = true
    @paths = [@path]
    @index = 0
    editNodes = []

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
        editNodes.push pathEditNode @path.segments[@path.segments.length - 1], @path.model
        @pathEnd.position = event.point
        @pathStart.position = @path.firstSegment.point
        return

    @split = (position) ->
        paths.push @path.split @path.getNearestLocation position
        return
    return this

canvas = (model) ->
    @rect = new Path.Rectangle {
        point: [0, 0]
        size: view.size
        fillColor: 'white'
    }
    @grid = new grid()
    @canvasGroup = new Group @rect, @grid.group
    @canvasGroup.sendToBack()

    @canvasGroup.m = model
    @canvasGroup.m.pathData = new pathData model
    @canvasGroup.m.path = @canvasGroup.m.pathData.path
    @canvasGroup.m.distance = new distanceCircle model
    @canvasGroup.osc =  new osc.oscudp()

    @canvasGroup.m.splitIndicator.m = model
    @canvasGroup.m.splitIndicator.onMouseMove = (event) ->
        @position = @m.path.getNearestLocation event.point
        return

    @canvasGroup.m.splitIndicator.onMouseDown = (event) ->
        if event.event.button is 0 # left mouse button
            return
        else if event.event.button is 2 # right mouse button
            console.log "position of the thing", @position
            loc = @m.path.getNearestLocation @position
            newPath = @m.path.splitAt loc
            newPath.strokeColor = 'red'
            console.log newPath

    @canvasGroup.onMouseMove = (event) ->
        loc = @m.path.getNearestLocation event.point
        if loc is null then return
        @m.splitIndicator.position = @m.path.getPointAt loc.offset
        return

    @canvasGroup.onMouseDown = (event) ->
        if event.event.button is 0 # left mouse button
            @m.pathData.add event
        else
            @m.distance.setScale (view.center).getDistance event.point
        return

    @canvasGroup.onMouseDrag = (event) ->
        if event.event.button is 2 # right mouse button
            @m.distance.setScale (view.center).getDistance event.point
            return
        return

    @update = () ->
        if @canvasGroup.m.startTime is null then return
        @canvasGroup.osc.generate @canvasGroup.m
        return

    return this


play = (model) ->
    @button = new Path.Circle {
        center: [25, 25]
        radius: 20
        fillColor: 'blue'
    }
    @button.m = model
    @button.onMouseDown = (event) ->
        @m.startTime = (new Date()).getTime()
        @m.positionIndicator.position = @m.path.getPointAt 0
        @m.headDistance = @m.headPosition.getDistance @m.path.getPointAt (@m.path.getNearestLocation @m.headPosition).offset
        return
    return this

smooth = (model) ->
    @button = new Path.Circle {
        center: [65, 25]
        radius: 20
        fillColor: 'green'
    }
    @button.m = model
    @updatePath = (model) -> @button.m = model
    @button.onMouseDown = (event) ->
        @m.path.smooth()
        return
    return this

exporter = (ipc) ->
    @button = new Path.Circle {
        center: [105, 25]
        radius: 20
        fillColor: 'red'
    }
    @button.ipc = ipc
    @button.onMouseDown = (event) ->
        @ipc.send 'export-dialog'
        return
    return this

distNum = (model) ->
    @numbox = new PointText {
        point: [690, 30]
        justification: 'right'
        fontSize: 15
        fillColor: 'black'
    }
    @numbox.m = model
    @numbox.content = '' + @numbox.m.minDistance.toFixed(2) + ' m'
    @numbox.onMouseDrag = (event) ->
        @m.minDistance += event.delta.x * 0.01
        if @m.minDistance < 0.01 then @m.minDistance = 0.01
        @content = '' + @m.minDistance.toFixed(2) + ' m'
        return
    return this

timeNum = (model) ->
    @numbox = new PointText {
        point: [600, 30]
        justification: 'right'
        fontSize: 15
        fillColor: 'black'
    }
    @numbox.m = model
    @numbox.content = '' + (@numbox.m.totalTime / 1000).toFixed(2) + ' s'
    @numbox.onMouseDrag = (event) ->
        @m.totalTime += event.delta.x * 4
        if @m.totalTime < 100 then @m.totalTime = 100
        @content = '' + (@m.totalTime / 1000).toFixed(2) + ' s'
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

grid = (canvas) ->
    @grid = []
    for i in [0...(window.innerWidth / 25)]
        @grid.push new Path.Line {
            from: [i * 25, 0]
            to: [i * 25, 700]
            strokeColor: 'grey'
            strokeWidth: 0.2
        }
        @grid[@grid.length - 1].canvas = canvas
    for i in [0...(window.innerHeight / 25)]
        @grid.push new Path.Line {
            from: [0, i * 25]
            to: [700, i * 25]
            strokeColor: 'grey'
            strokeWidth: 0.2
        }
        @grid[@grid.length - 1].canvas = canvas
    @group = new Group @grid
    return this

module.exports = { canvas, play, smooth, exporter, distNum, timeNum, head }
