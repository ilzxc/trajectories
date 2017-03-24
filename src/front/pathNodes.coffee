"use strict"

draggableText = (model, keyword, units, size, factor, min, max, justify='center', color='black', decimals=2, helper=(a)->a) ->
    numbox = new PointText {
        point: [0, 4.5]
        justification: justify
        fontSize: size
        fillColor: color
        m: model
        keyword: keyword
        factor: factor
        min: min
        max: max
        units: units
        helper: helper
        decimals: decimals
        set: (value) ->
            @m[@keyword] = value
            if @min != null
                if @m[@keyword] < @min then @m[@keyword] = @min
            if @max != null
                if @m[@keyword] > @max then @m[@keyword] = @max
            @content = @helper(@m[@keyword]).toFixed(@decimals) + ' ' + @units
            return
        onMouseDown: (event) ->
            if event.event.button is 2 # right mouse button
                if @keyword == 'velocity'
                    @m.velocity = 0
                    @units = 's'
                    @keyword = 'pause'
                    @factor = 0.02
                    @decimals = 2
                else if @keyword == 'pause'
                    @m.pause = 0
                    @m.velocity = 100
                    @units = '%'
                    @keyword = 'velocity'
                    @factor = 1
                    @decimals = 0
                @content = @helper(@m[@keyword]).toFixed(@decimals) + ' ' + @units
                return
        onMouseDrag: (event) ->
            @m[@keyword] += event.delta.x * @factor
            if @min != null
                if @m[@keyword] < @min then @m[@keyword] = @min 
            if @max != null
                if @m[@keyword] > @max then @m[@keyword] = @max
            @content = @helper(@m[@keyword]).toFixed(@decimals) + ' ' + @units
            return
    }
    numbox.content = numbox.helper(numbox.m[numbox.keyword]).toFixed(numbox.decimals) + ' ' + numbox.units
    return numbox

fromMarker = (model, node) ->
    result = new Path.Arc (new Point 0, -7), (new Point -7, 0), (new Point 0, 7)
    result.closed = true
    result.fillColor = 'grey'
    result.strokeColor = 'black'
    result.m = model
    result.node = node
    result.angle = 0
    result.onMouseDrag = (event) ->
        loc = (@m.path.getNearestLocation event.point)
        if loc != null then @m.start = loc.offset
        @node.update()
        return
    return result

toMarker = (model, node) ->
    result = new Path.Arc (new Point 0, -7), (new Point 7, 0), (new Point 0, 7)
    result.closed = true
    result.fillColor = 'white'
    result.strokeColor = 'black'
    result.m = model
    result.node = node
    result.angle = 0
    result.onMouseDrag = (event) ->
        loc = (@m.path.getNearestLocation event.point)
        if loc != null then @m.end = loc.offset
        @node.update()
        return
    return result

node = (path, offset) ->
    @handle = new Group()
    @handle.hack = this
    @nodeModel = {
        path: path
        offset: offset
        start: offset - 25
        end: offset + 25
        velocity: 100 # %
        pause: 0 # seconds
        easeIn: 1
        easeOut: 1
        behavior: null
    }
    base = new Path.Circle {
        center: [0, 0]
        radius: 20
        fillColor: 'black'
        m: @nodeModel
        onMouseDrag: (event) ->
            @m.offset = (@m.path.getNearestLocation event.point).offset
            if @m.offset > @m.path.length then @m.offset = @m.path.length
            if @m.offset < 0 then @m.offset = 0
            @parent.hack.update()
            return
    }
    @num = draggableText @nodeModel, 'velocity', '%', 10, 1, 0.01, 600, 'center', 'white', 0 
    @from = fromMarker @nodeModel, this
    @to = toMarker @nodeModel, this
    @handle.addChildren([base, @num])
    
    @update = () ->
        # fix any potential errors
        if @nodeModel.offset > @nodeModel.path.length then @nodeModel.offset = nodeModel.path.length
        if @nodeModel.offset < 0 then @nodeModel.offset = 0
        if @nodeModel.start < 0 then @nodeModel.start = 0
        if @nodeModel.start > @nodeModel.offset then @nodeModel.start = @nodeModel.offset
        if @nodeModel.end > @nodeModel.path.length then @nodeModel.end = @nodeModel.path.length
        if @nodeModel.end < @nodeModel.offset then @nodeModel.end = @nodeModel.offset
        # update the position of the node
        @handle.position = @nodeModel.path.getPointAt @nodeModel.offset
        # update the positions & rotations of the enpoints
        @from.position = @nodeModel.path.getPointAt @nodeModel.start
        angle = (@nodeModel.path.getNormalAt @nodeModel.start).angle + 90
        @from.rotate -@from.angle
        @from.rotate angle
        @from.angle = angle
        @to.position = @nodeModel.path.getPointAt @nodeModel.end
        angle = (@nodeModel.path.getNormalAt @nodeModel.end).angle + 90
        @to.rotate -@to.angle
        @to.rotate angle
        @to.angle = angle
        return
    @update()
    return this

module.exports = { node }
