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
        proto['elements'][0]['args'] = pitch
        proto['elements'][1]['args'] = distance
        udp.send osc.toBuffer(proto), 56765, 'localhost'
        return

    return this

module.exports = { oscudp }