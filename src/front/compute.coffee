"use strict"

wav = require 'node-wav'
fs = require 'fs'

# note that vs > 0 iff source is moving away from the receiver
# and vs < 0 iff souce is moving towards the receiver
doppCompute = (vs) ->
    1 - (340.29 / (340.29 + vs))

# sound levels attenuation function for distance from the listener
distCompute = (minDistance, currentDistance) -> 
    r = minDistance / currentDistance
    r * r

angCompute = (pt) -> 
    result = (pt.subtract view.center).angle + 90
    (if result < 0 then 360 + result else result) / 360

panCompute = (pt) ->
    Math.abs (pt.subtract view.center).angle / 180

scale = (x, x1, y1) -> y1 * (x / x1)

# generate accepts:
#   * the motion path we are interested in
#   * the time it takes to traverse the path
#   * the distance @ which the closest point to the head is from the head (this defines the overall distance for the path
#   * headPosition (which is currently hardwired to be at the center of the view)
generate = (path, time, minDistance, distanceRadius, headPosition, filename) ->
    # each of the computation results is an audio channel to be stored in a 44100:32 wav file:
    steps = Math.round time * 44100 # number of samples we will take
    dt = path.length / steps        # increment of distance to ensure uniform motion

    dopplers = new Float32Array steps
    distances = new Float32Array steps
    angles = new Float32Array steps
    pans = new Float32Array steps
    dopplers[0] = 1 # first value is 0

    # distanceFromHead = headPosition.getDistance path.getPointAt (path.getNearestLocation headPosition).offset
    scaler = (x) -> scale x, distanceRadius, minDistance

    prevDistance = scaler (path.getPointAt 0).getDistance headPosition
    distances[0] = prevDistance
    angles[0] = angCompute path.getPointAt 0
    pans[0] = panCompute path.getPointAt 0

    # doppler & distance
    for i in [1...steps] # sampled @ the sampling rate
        t = dt * i
        pt = path.getPointAt t
        distance = scaler pt.getDistance headPosition 
        vel = (distance - prevDistance) * 44100
        dopplers[i] = doppCompute vel
        distances[i] = distCompute minDistance, distance
        angles[i] = angCompute pt
        pans[i] = panCompute pt
        prevDistance = distance

    buf = wav.encode [dopplers, distances, angles, pans], {sampleRate: 44100, float: true, bitDepth: 32}

    fs.writeFileSync filename, buf
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
            {
                oscType: 'message'
                address: '/azimuth'
                args: 0
            }
            {
                oscType: 'message'
                address: '/pan'
                args: 0
            }
        ]
    }
    @send = (pitch, distance, azimuth, pan) ->
        @proto['elements'][0]['args'] = pitch
        @proto['elements'][1]['args'] = distance
        @proto['elements'][2]['args'] = azimuth
        @proto['elements'][3]['args'] = pan
        @sock.send osc.toBuffer(@proto), 56765, 'localhost'
        return

    @generate = (m) ->
        # m.path, m.startTime, m.totalTime, m.minDistance, m.distanceCircle, m.headPosition,
        # m.prevDistance, m.prevTime
        time = ((new Date()).getTime() - m.startTime) / m.totalTime
        if time > 1 then time = 1
        pt = m.path.getPointAt time * m.path.length
        m.positionIndicator.position = pt

        vectorDistance = m.headPosition.getDistance pt
        distance = scale vectorDistance, m.distanceCircle, m.minDistance
        vel = (distance - m.prevDistance) / ((time - m.prevTime) * m.totalTime / 1000)
        doppler = doppCompute vel
        distNorm = distCompute m.minDistance, distance
        azimuth = angCompute pt
        pan = panCompute pt
        if time >= 1
            m.startTime = null
            @send -1, 0, 0, 0
        else
            @send doppler, distNorm, azimuth, pan
        m.prevDistance = distance
        m.prevTime = time
        return
    return this

module.exports = { generate, oscudp }
