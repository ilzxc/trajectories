fs = require 'fs'
wav = require 'node-wav'
{ Point } = require 'paper'
{ doppCompute, distCompute } = require '../js/front/compute'

# azimuth computation (normalized to 0..1 for 360 degrees)
angCompute = (pt) -> 
    result = (pt.subtract view.center).angle + 90
    (if result < 0 then 360 + result else result) / 360

# pan computation (left-right) for exaggerated movement
panCompute = (pt) ->
    (Math.abs (pt.subtract view.center).angle / 180) * 2 - 1

# helper scale function, curried version is used below
scale = (x, x1, y1) -> y1 * (x / x1)

# curry the scaler according to the distance radius
scaler = (x) -> scale x, 5, 0.80

numParticles = process.argv[2]
dim = [process.argv[3], process.argv[4]]
view = { center: new Point dim[0] / 2, dim[1] / 2 }
time = process.argv[5]

if numParticles is undefined or dim[0] is undefined or dim[1] is undefined
    console.log "bad args: ", process.argv
    console.log numParticles, dim, time
    process.exit()

locs = []
vels = []
accl = []
audio = []
osr = 1 / 44100 # actual delta, in seconds
factor = osr / (1 / 60)

simTime = Math.floor time * 44100

for i in [0...numParticles]
    locs.push new Point Math.random() * dim[0], Math.random() * dim[1]
    vels.push new Point 0, 0
    accl.push new Point 0, 0
    audio.push {
        dopp: new Float32Array simTime
        amp: new Float32Array simTime
        azimuth: new Float32Array simTime
        pan: new Float32Array simTime
        velocity: new Float32Array simTime
    }

prevdistances = []
for i in [0...numParticles]
    prevdistances[i] = locs[i].getDistance view.center

for t in [0...simTime]
    # reset accelerations
    for i in [0...locs.length]
        accl[i].x = accl[i].y = 0

    # compute new accelerations based on everyone's position
    # (we do not move anything until we're done computing the vectors)
    for i in [0...locs.length]
        for j in [0...locs.length]
            diff = locs[i].subtract locs[j]
            dist = diff.length
            if dist is 0 then continue
            if dist < 1 then dist = 1
            accl[i] = accl[i].subtract diff.divide dist * 100 # this is acceleration for ~60 fps

    # scale by the time factor & apply accl -> vel -> positions
    for i in [0...locs.length]
        accl[i] = accl[i].multiply factor
        vels[i] = vels[i].add accl[i]
        locs[i] = locs[i].add vels[i]
        distance = scaler locs[i].getDistance view.center
        centralvel = distance - prevdistances[i] 
        audio[i].dopp[t] = doppCompute centralvel
        audio[i].amp[t] = distCompute 3, distance
        audio[i].azimuth[t] = angCompute locs[i]
        audio[i].pan[t] = panCompute locs[i]
        audio[i].velocity[t] = vels[i].length
        prevdistances[i] = distance

for i in [0...audio.length]
    a = audio[i]
    buf = wav.encode [a.dopp, a.amp, a.azimuth, a.pan, a.velocity], {sampleRate: 44100, float: true, bitDepth: 32}
    fs.writeFileSync i + ".wav", buf


