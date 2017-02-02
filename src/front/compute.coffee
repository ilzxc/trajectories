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
generate = (path, time, minDistance, headPosition) ->
    # each of the computation results is an audio channel to be stored in a 44100:32 wav file:
    steps = Math.round time * 44100 # number of samples we will take
    dt = path.length / steps        # increment of distance to ensure uniform motion

    dopplers = new Float32Array steps
    distances = new Float32Array steps
    dopplers[0] = 1 # first value is 0

    distanceFromHead = headPosition.getDistance path.getPointAt (path.getNearestLocation headPosition).offset
    scaler = (x) -> return scale x, distanceFromHead, minDistance

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

module.exports = { generate }
