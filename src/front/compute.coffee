wav = require 'node-wav'
fs = require 'fs'

# note that vs > 0 iff source is moving away from the receiver
# and vs < 0 iff souce is moving towards the receiver
doppCompute = (vs) ->
    return 340.29 / (340.29 + vs)

# sound levels attenuation function for distance from the listener
distCompute = (minDistance, currentDistance) -> 
    r = minDistance / currentDistance
    return r * r

scale = (x, x1, y1) -> return y1 * (x / x1)

# generate accepts:
#   * the motion path we are interested in
#   * the time it takes to traverse the path
#   * the distance @ which the closest point to the head is from the head (this defines the overall distance for the path
#   * headPosition (which is currently hardwired to be at the center of the view)
generate = (path, time, minDistance, distanceRadius, headPosition) ->
    # each of the computation results is an audio channel to be stored in a 44100:32 wav file:
    steps = Math.round time * 44100 # number of samples we will take
    dt = path.length / steps        # increment of distance to ensure uniform motion

    dopplers = new Float32Array steps
    distances = new Float32Array steps
    dopplers[0] = 1 # first value is 0

    # distanceFromHead = headPosition.getDistance path.getPointAt (path.getNearestLocation headPosition).offset
    scaler = (x) -> return scale x, distanceRadius, minDistance

    prevDistance = scaler (path.getPointAt 0).getDistance headPosition
    distances[0] = prevDistance

    # doppler & distance
    for i in [1...steps]
        t = dt * i
        pt = path.getPointAt t
        distance = scaler pt.getDistance headPosition 
        vel = (distance - prevDistance) * 44100
        dopplers[i] = doppCompute vel
        distances[i] = distCompute minDistance, distance
        prevDistance = distance

    buf = wav.encode [dopplers, distances], {sampleRate: 44100, float: true, bitDepth: 32}

    fs.writeFileSync 'output.wav', buf
    return

udp = require 'dgram'
osc = require 'osc-min'

oscudp = () ->
    @sock = udp.createSocket 'udp4'
    @proto = {
        oscType: 'bundle'
        timetag: 0
        elements: [
            {
                oscType: 'message'
                address: '/pitch'
                args: 0
            }
            {
                oscType: 'message'
                address: '/distance'
                args: 0
            }
        ]
    }
    @send = (pitch, distance) ->
        @proto['elements'][0]['args'] = pitch
        @proto['elements'][1]['args'] = distance
        @sock.send osc.toBuffer(@proto), 56765, 'localhost'
        return

    @generate = (pb) ->
        # pb.path, pb.startTime, pb.totalTime, pb.minDistance, pb.distanceCircle, pb.headPosition,
        # pb.prevDistance, pb.prevTime
        time = ((new Date()).getTime() - pb.startTime) / pb.totalTime
        if time > 1 then time = 1
        pb.positionIndicator.position = pb.path.getPointAt time * pb.path.length
        vectorDistance = pb.headPosition.getDistance pb.path.getPointAt time * pb.path.length
        distance = scale vectorDistance, pb.distanceCircle, pb.minDistance
        vel = (distance - pb.prevDistance) / ((time - pb.prevTime) * pb.totalTime / 1000)
        doppler = doppCompute vel
        distNorm = distCompute pb.minDistance, distance
        @send doppler, distNorm
        pb.prevDistance = distance
        pb.prevTime = time
        if time == 1
            pb.startTime = null
        return
    return this

module.exports = { generate, oscudp }
