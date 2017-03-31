"use strict"

wav = require 'node-wav'
fs = require 'fs'
udp = require 'dgram'
osc = require 'osc-min'

# note that vs > 0 iff source is moving away from the receiver
# and vs < 0 iff souce is moving towards the receiver
doppCompute = (vs) ->
    (340.29 / (340.29 + vs)) - 1

# sound levels attenuation function for distance from the listener
distCompute = (minDistance, currentDistance) -> 
    r = minDistance / currentDistance
    r * r

# azimuth computation (normalized to 0..1 for 360 degrees)
angCompute = (pt, headPosition) -> 
    result = (pt.subtract headPosition).angle + 90
    result = (if result == 360 then 359.9 else result)
    (if result < 0 then 360 + result else result) / 360

# pan computation (left-right) for exaggerated movement
panCompute = (pt, headPosition) ->
    (Math.abs (pt.subtract headPosition).angle / 180) * 2 - 1

# helper scale function, curried version is used below
scale = (x, x1, y1) -> y1 * (x / x1)

# figure out % multiplier for the velocity of the sound
velPercent = (variants, actualOffset) ->
    for v in variants
        if v.nodeModel.start < actualOffset < v.nodeModel.end
                dp = 1 - (v.nodeModel.velocity / 100)
                if actualOffset <= v.nodeModel.offset
                    fadeIn = (actualOffset - v.nodeModel.start) / (v.nodeModel.offset - v.nodeModel.start)
                    return 1 - (fadeIn * dp)
                else 
                    fadeOut = 1 - (actualOffset - v.nodeModel.offset) / (v.nodeModel.end - v.nodeModel.offset)
                    return 1 - (fadeOut * dp)
                break
    return 1

# stand-alone function that runs the simulation at 44.1 kHz
# and records the computed output into a multichannel wav file
generate = (m, filename) ->
    dt = 1 / 44100 # delta time
    offset = 0 # normalized path offset
    baseVelocity = 1000 / m.totalTime # average velocity
    numsamples = 0 # due to velocity variance, we need to compute total num samples
    len = m.path.length # convenience function
    maxVelocity = minVelocity = baseVelocity # prepare min/max for scaling

    # console.log "layer scaling", m.canvasScale
    # console.log "head position", m.canvasGroup.head.head.position
    # console.log "distance", m.distanceRadius * m.canvasScale

    # determine the length of the file & maximum velocity
    n = m.pathData.variants   
    while offset <= 1
        velocity = baseVelocity
        actualOffset = len * offset
        velocity *= velPercent n, actualOffset
        offset += velocity * dt
        if velocity > maxVelocity then maxVelocity = velocity 
        if velocity < minVelocity then minVelocity = velocity
        ++numsamples

    # create arrays for mono tracks in our wave file:
    dopplers = new Float32Array numsamples
    distances = new Float32Array numsamples
    angles = new Float32Array numsamples
    pans = new Float32Array numsamples
    velocities = new Float32Array numsamples
    
    # curry the scaler according to the distance radius
    scaler = (x) -> scale x, m.distanceRadius * m.canvasScale, m.minDistance
    # precompute our divisors so we can multiply instead of divide (high sampling rate)
    maxVelInv = 1 / (maxVelocity - baseVelocity)
    minVelInv = 1 / (baseVelocity - minVelocity)

    # initialize initial known values (for prevDistance & everything)
    prevDistance = scaler (m.path.getPointAt 0).getDistance m.canvasGroup.head.head.position
    distances[0] = prevDistance
    angles[0] = angCompute m.path.getPointAt 0
    pans[0] = panCompute m.path.getPointAt 0

    # reset offset & proceed with the computation:
    offset = 0
    for i in [1...numsamples]
        velocity = baseVelocity
        actualOffset = len * offset
        velocity *= velPercent n, actualOffset
        offset += velocity * dt # using scaled velocity
        pt = m.path.getPointAt actualOffset
        distance = scaler pt.getDistance m.canvasGroup.head.head.position
        vel = (distance - prevDistance) * 44100 # multiply by the sampling rate
        dopplers[i] = doppCompute vel
        distances[i] = distCompute m.minDistance, distance
        angles[i] = angCompute pt, m.canvasGroup.head.head.position
        pans[i] = panCompute pt, m.canvasGroup.head.head.position
        velocities[i] = if (velocity > baseVelocity) then (velocity - maxVelocity) * maxVelInv + 1 else if velocity < baseVelocity then (velocity - minVelocity) * minVelInv - 1 else 0
        prevDistance = distance

    # set the first point == second point for doppler and velocities to avoid clicks
    dopplers[0] = dopplers[1]
    velocities[0] = velocities[1]

    # encode the wav file with five data tracks:
    buf = wav.encode [dopplers, distances, angles, pans, velocities], {sampleRate: 44100, float: true, bitDepth: 32}
    fs.writeFileSync filename, buf
    return

oscudp = () ->
    # create socket
    @sock = udp.createSocket 'udp4'
    # osc prototype bundle that will remain constant
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
        # set the JSON osc values using our prototype
        @proto['elements'][0]['args'] = pitch
        @proto['elements'][1]['args'] = distance
        @proto['elements'][2]['args'] = azimuth
        @proto['elements'][3]['args'] = pan

        # send the buffer
        @sock.send osc.toBuffer(@proto), 56765, 'localhost'
        return

    @generate = (m, n) ->
        # OSC bridge needs to correctly scale values according to time
        time = ((new Date()).getTime() - m.startTime) / 1000
        dt = time - m.prevTime # delta time
        # de-normalize offset for path & compute the velocity of frame-based motion
        actualOffset = m.offset * m.path.length
        velocity = m.velocity * velPercent n, actualOffset

        # increment normalized offset & correct for overflow
        m.offset += velocity * dt
        if m.offset > 1 then m.offset = 1

        # get the correct point & move the indicator position
        pt = m.path.getPointAt m.offset * m.path.length
        m.pathData.positionIndicator.position = pt
        
        # compute the vector distance & convert to physical distance (in meters)
        vectorDistance = m.canvasGroup.head.head.position.getDistance pt
        distance = scale vectorDistance, m.distanceRadius * m.canvasScale, m.minDistance

        # compute the physical velocity
        vel = (distance - m.prevDistance) / dt

        # compute doppler, attenuation, azimuth, and pan
        # note that attenuation (distNorm) is normalization of physical distance
        # according to user-defined distance radius
        doppler = doppCompute vel
        distNorm = distCompute m.minDistance, distance
        azimuth = angCompute pt, m.canvasGroup.head.head.position
        pan = panCompute pt, m.canvasGroup.head.head.position

        # most common use-case first: send the values & update previous state
        if m.offset != 1
            @send doppler, distNorm, azimuth, pan
            m.prevDistance = distance
            m.prevTime = time
        else
            # store the time estimate (todo: remove)
            # reset the startTime to null to turn off update
            m.timeEstimate = time
            m.startTime = null
            @send -1, 0, 0, 0 # send "reset" bundle to stop audio
        return
    this

module.exports = { generate, oscudp, doppCompute, distCompute, angCompute, panCompute }
