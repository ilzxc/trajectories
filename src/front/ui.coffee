"use strict"

icons = {
    play: """
<?xml version="1.0" encoding="utf-8"?>
<!-- Generator: Adobe Illustrator 21.0.2, SVG Export Plug-In . SVG Version: 6.00 Build 0)  -->
<svg version="1.1" baseProfile="tiny" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
x="0px" y="0px" viewBox="0 0 40 40" overflow="scroll" xml:space="preserve">
<g>
<circle fill="#51C5F2" cx="20" cy="20" r="19.4"/>
<polygon fill="#2D2D2D" points="16.2,11.8 16.2,28.2 30.3,20     "/>
</g>
</svg>"""
    smooth: """
<?xml version="1.0" encoding="utf-8"?>
<!-- Generator: Adobe Illustrator 21.0.2, SVG Export Plug-In . SVG Version: 6.00 Build 0)  -->
<svg version="1.1" baseProfile="tiny" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
x="0px" y="0px" viewBox="0 0 40 40" overflow="scroll" xml:space="preserve">
<g>
<circle fill="#54C0A2" cx="20" cy="20" r="19.4"/>
<path fill="#2D2D2D" d="M28.6,16L28,16.7c-1.4-1.2-3.1-1.9-5-1.9c-1.2,0-2.4,0.3-3.5,0.9l2.7-2.7c0.2,0.1,0.5,0.2,0.7,0.2
        c0.4,0,0.7-0.1,1-0.4c0.6-0.6,0.6-1.4,0-2c-0.3-0.3-0.6-0.4-1-0.4c-0.4,0-0.7,0.1-1,0.4c-0.5,0.5-0.5,1.2-0.2,1.7l-3.4,3.4
        l-0.6-0.6L15.9,17l0.6,0.6l-3.4,3.4c-0.2-0.1-0.5-0.2-0.7-0.2c-0.4,0-0.7,0.1-1,0.4c-0.6,0.6-0.6,1.4,0,2c0.3,0.3,0.6,0.4,1,0.4
        c0.4,0,0.7-0.1,1-0.4c0.5-0.5,0.5-1.2,0.2-1.7l2.7-2.7c-1.4,2.7-1.1,6.1,1,8.5L16.6,28l1.7,1.7l1.7-1.7l-1.7-1.7l-0.6,0.6
        c-2-2.4-2.2-5.8-0.4-8.4l0.3,0.3l1.7-1.7l-0.3-0.3c1.1-0.8,2.5-1.2,3.9-1.2c1.7,0,3.2,0.6,4.5,1.6l-0.6,0.6l1.7,1.7l1.7-1.7
        L28.6,16z"/>
</g>
</svg>"""
    export: """
<?xml version="1.0" encoding="utf-8"?>
<!-- Generator: Adobe Illustrator 21.0.2, SVG Export Plug-In . SVG Version: 6.00 Build 0)  -->
<svg version="1.1" baseProfile="tiny" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
x="0px" y="0px" viewBox="0 0 40 40" xml:space="preserve">
<g>
<circle fill="#F5949B" cx="20" cy="20" r="19.4"/>
<g>
<path fill="#2D2D2D" d="M25.4,11.9h-0.7v6.7h-8.1v-5.4v-1.3h0h-4v16.1h16.1V15.3L25.4,11.9z M24,25.4h-6.7v-0.7H24V25.4z M24,23.4
h-6.7v-0.7H24V23.4z"/>
<path fill="#2D2D2D" d="M24.1,11.9h-6.7v1.3V18h6.7V11.9z M22.7,16H22v-2h0.7V16z"/>
</g>
</g>
</svg>"""
}

osc = require './compute'
pn = require './pathNodes'

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
        @variants.push variant
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
    @update = () ->
        for v in @variants
            v.update()
        @pathEnd.position = event.point
        @pathStart.position = @path.firstSegment.point
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

module.exports = { canvas, play, smooth, exporter, distNum, timeNum }
