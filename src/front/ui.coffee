"use strict"

osc = require './compute'
pn = require './pathNodes'
{ icons } = require './icons'

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

pathEditNode = (segment, pathData) ->
    result = new Path.Circle {
        point: [0, 0]
        radius: 5
        strokeColor: '#989898'
        fillColor: '#989898'
        opacity: .5
    }
    result.position = segment.point
    result.segment = segment
    result.pd = pathData
    result.onMouseDown = (event) ->
        if event.event.button is 0
            @offset = event.point.subtract @position
        else
            counter = 0
            for seg in @pd.path.segments
                if seg is segment then break
                ++counter
            @pd.path.removeSegment counter
            @remove()
            @pd.editNodes.splice counter
            @pd.update()
        return
    result.onMouseDrag = (event) ->
        @segment.point = event.point.subtract @offset
        @position = event.point.subtract @offset
        @pd.pathEnd.position = @pd.path.lastSegment.point
        @pd.pathStart.position = @pd.path.firstSegment.point
        @pd.update()
        return
    result.update = () -> result.position = result.segment.point
    return result

pathData = (model) ->
    @path = new Path()
    @path.strokeColor = 'black'
    @path.strokeWidth = 2
    @paths = [@path]
    @index = 0
    @editNodes = []
    @variants = []
    @hack = this

    @positionIndicator = new Path.Circle {
        center: [-100, -100]
        radius: 10
        strokeColor: 'blue'
        strokeWidth: 2
    }
    @splitIndicator = new Path.Circle {
        center: [-100, -100]
        radius: 5
        strokeColor: 'blue'
        strokeWidth: 1
        fillColor: 'orange'
    }
    @splitIndicator.path = @path
    @splitIndicator.variants = @variants
    @splitIndicator.hack = @hack
    @splitIndicator.onMouseMove = (event) ->
        loc = @path.getNearestLocation event.point
        if loc is null then return
        @position = loc
        return
    @splitIndicator.onMouseDown = (event) ->
        if event.event.button is 2 # right mouse button
            loc = @path.getNearestLocation @position
            @variants.push new pn.node @path, loc.offset, @hack
            @variants.sort (a, b) -> a.offset - b.offset
            return
    @path.onMouseMove = (event) ->
        if event.event.button is 2
            loc = @getNearestLocation event.point
            if loc is null then return @hack.splitIndicator.position = [-10, -10]
            @hack.splitIndicator.position = loc
        return

    @pathStart = new Path.Circle {
        center: [-10, -10]
        radius: 5
        strokeColor: 'black'
        strokeWidth: 1
        fillColor: 'black'
    }
    @pathEnd = new Path.Circle {
        center: [-10, -10]
        radius: 5
        strokeColor: 'black'
        strokeWidth: 1
        fillColor: 'white'
    }
    @add = (event) ->
        @path.add event.point
        @editNodes.push pathEditNode @path.segments[@path.segments.length - 1], this
        @pathEnd.position = event.point
        @pathStart.position = @path.firstSegment.point
        return
    @addVariant = (obj) ->
        variant = new pn.node @path, obj.offset, this
        variant.nodeModel.start = obj.start
        variant.nodeModel.end = obj.end
        variant.nodeModel.velocity = obj.velocity
        variant.num.set obj.velocity
        variant.update()
        @variants.push variant
        return
    @removeVariant = (variant) ->
        for v, i in @variants
            if v is variant
                eliminated = (@variants.splice i, 1)[0]
                eliminated.to.remove()
                eliminated.from.remove()
                eliminated.handle.remove()
                eliminated = null
                return
        return
    @movePath = (deltaVector) ->
        @path.translate deltaVector
        @updateAll()
        return
    @rotatePath = (delta) ->
        factor = delta / 10
        @path.rotate factor, view.center
        @updateAll()
        return
    @scalePath = (delta) ->
        factor = 1 + (delta / 20)
        @path.scale factor, view.center
        for v in @variants
            v.scale factor
        @updateAll()
    @update = () ->
        for v in @variants
            v.update()
        @pathEnd.position = @path.lastSegment.point
        @pathStart.position = @path.firstSegment.point
        return
    @updateAll = () ->
        @update()
        for en in @editNodes
            en.update()
        return
    @clear = () ->
        for en in @editNodes
            en.remove()
        @editNodes.length = 0
        @pathStart.position = [-10, -10] 
        @pathEnd.position = [-10, -10]
        for variant in @variants
            variant.from.remove()
            variant.to.remove()
            variant.handle.remove()
        @variants.length = 0
        @splitIndicator.position = [-10, -10]
        @positionIndicator.position = [-10, -10]
        @path.removeSegments()
        return
    @loadFromSVG = (segments) ->
        @clear()
        @path.set { segments: segments }
        for seg in @path.segments
            @editNodes.push pathEditNode seg, this
        return
    return this

canvas = (model) ->
    @rect = new Path.Rectangle {
        point: [0, 0]
        size: view.size
        fillColor: 'white'
    }
    @grid = new grid()
    @head = new head 10
    @canvasGroup = new Group @rect, @grid.group, @head.head
    @canvasGroup.sendToBack()

    @canvasGroup.m = model
    @canvasGroup.m.pathData = new pathData model
    @canvasGroup.m.path = @canvasGroup.m.pathData.path
    @canvasGroup.m.distance = new distanceCircle model
    @osc = new osc.oscudp()

    @canvasGroup.onMouseMove = (event) ->
        loc = @m.path.getNearestLocation event.point
        if loc is null then return
        @m.pathData.splitIndicator.position = @m.path.getPointAt loc.offset
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
        else console.log event
        return

    @clear = () ->
        @canvasGroup.m.distance.setScale 25
        @canvasGroup.m.pathData.clear()
        @canvasGroup.m.minDistance = 0.8
        return

    @update = () ->
        if @canvasGroup.m.startTime is null then return
        @osc.generate @canvasGroup.m, @canvasGroup.m.pathData.variants
        return
    return this

play = (model) ->
    @button = project.importSVG icons.play
    @button.position = new Point 25, 25
    @button.m = model
    @button.onMouseDown = (event) ->
        console.log "play triggered", @m
        @m.pathData.positionIndicator.position = @m.path.getPointAt 0
        @m.velocity = 1000 / @m.totalTime
        @m.offset = 0
        @m.prevDistance = 0
        @m.startTime = (new Date()).getTime()
        @m.prevTime = 0
        return
    return this

smooth = (model) ->
    @button = project.importSVG icons.smooth
    @button.position = new Point 65, 25
    @button.m = model
    @updatePath = (model) -> @button.m = model
    @button.onMouseDown = (event) ->
        @m.path.smooth()
        @m.pathData.update()
        return
    return this

exporter = (ipc) ->
    @button = project.importSVG icons.export
    @button.position = new Point 105, 25
    @button.ipc = ipc
    @button.onMouseDown = (event) ->
        @ipc.send 'export-dialog'
        return
    return this

move = (model) ->
    @button = project.importSVG icons.move
    @button.position = new Point 185, 25
    @button.model = model
    @button.onMouseDrag = (event) ->
        @model.pathData.movePath event.delta
        return
    return this

rotate = (model) ->
    @button = project.importSVG icons.rotate
    @button.position = new Point 185 + 40, 25
    @button.model = model
    @button.onMouseDrag = (event) ->
        @model.pathData.rotatePath event.delta.x
        return
    return this

scale = (model) ->
    @button = project.importSVG icons.scale
    @button.position = new Point 185 + 80, 25
    @button.model = model
    @button.onMouseDrag = (event) ->
        @model.pathData.scalePath event.delta.y
        return
    return this

distNum = (model) ->
    @units = new PointText {
        point: [669, 20]
        justification: 'left'
        fontSize: 15
        fillColor: 'black'
        content: 'm'
    }
    @numbox = new PointText {
        point: [665, 20]
        justification: 'right'
        fontSize: 15
        fillColor: 'black'
    }
    @numbox.m = model
    @numbox.content = '' + @numbox.m.minDistance.toFixed(2) #+ ' m'
    @numbox.onMouseDrag = (event) ->
        @m.minDistance += event.delta.x * 0.01
        if @m.minDistance < 0.01 then @m.minDistance = 0.01
        @content = '' + @m.minDistance.toFixed(2) #+ ' m'
        return
    @refresh = (value) -> @numbox.content = '' + @numbox.m.minDistance.toFixed(2) #+ ' m'
    return this

timeNum = (model) ->
    @units = new PointText {
        point: [669, 45]
        justification: 'left'
        fontSize: 15
        fillColor: 'black'
        content: 's'
    }
    @numbox = new PointText {
        point: [665, 45]
        justification: 'right'
        fontSize: 15
        fillColor: 'black'
    }
    @numbox.m = model
    @numbox.content = '' + (@numbox.m.totalTime / 1000).toFixed(2) #+ ' s'
    @numbox.onMouseDrag = (event) ->
        @m.totalTime += event.delta.x * 4
        if @m.totalTime < 100 then @m.totalTime = 100
        @content = '' + (@m.totalTime / 1000).toFixed(2) #+ ' s'
        return
    @refresh = () -> @numbox.content = '' + (@numbox.m.totalTime / 1000).toFixed(2) #+ ' s'
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

module.exports = { canvas, play, smooth, exporter, move, rotate, scale, distNum, timeNum }
