testPathCurves = () ->
    @myPath = new Path();
    @myPath.strokeColor = 'black'
    @myPath.add(new Point 100, 100)
    @myPath.add(new Point 200, 200)
    @myPath.add(new Point 300, 100)
    myPath.smooth()
    myPath.fullySelected = true
    return this

paper.install window
window.onload = () ->
    window.onresize()
    paper.setup 'traj'

    ui = require('./build/front/ui')
    testGrid = new ui.grid()
    head = new ui.head 10
    test = testPathCurves()

    t = 0
    littleCircle = new Path.Circle {
        center: [0, 0]
        radius: 10
        strokeColor: 'blue'
        strokeWidth: 2
    }

    view.onFrame = () ->
        if t <= 1
            littleCircle.position = test.myPath.getPointAt t * test.myPath.length
            t += 0.01
            return
        else console.log "done"

window.onresize = () ->
    trajRef = document.getElementById('traj').style
    trajRef.width = window.innerWidth + 'px'
    trajRef.height = window.innerHeight + 'px'
    return
