playButton = () ->
    @gfx = Path.Circle {
        center: [30, 30]
        radius: 25
        fillColor: 'blue'
    }
    return this

paper.install window
window.onload = () ->
    window.onresize()
    paper.setup 'traj'

    test = new playButton()
    console.log test

window.onresize = () ->
    trajRef = document.getElementById('traj').style
    trajRef.width = window.innerWidth + 'px'
    trajRef.height = window.innerHeight + 'px'
    return