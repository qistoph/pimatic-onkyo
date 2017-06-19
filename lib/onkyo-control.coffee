module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  eiscp = require 'eiscp'

  class OnkyoControl extends require('events').EventEmitter
    constructor: () ->
      eiscp.on('error', @eiscpError)
      eiscp.on('data', @eiscpData)

    connect: (host, port) ->
      eiscp.on('connect', () ->
        env.logger.debug('eiscp connected', arguments)
        eiscp.command('system-power=query')
        eiscp.command('audio-muting=query')
        eiscp.command('input-selector=query')
      )

      eiscp.connect({host: host, port: port})

    destroy: () ->
      super()

    eiscpError: (msg) ->
      env.logger.error('eiscpError: ', msg)

    eiscpData: (data) =>
      env.logger.debug('eispData:', data)
      if data.command == 'audio-muting'
        @emit('mute', data.argument == 'on')
      if data.command == 'input-selector'
        if data.argument?
          @emit('source', if typeof(data.argument) == 'string' then data.argument else data.argument[0])
      if data.command == 'system-power'
        @emit('power', data.argument)

    discover: () ->
      env.logger.info('Starting discovery')
      eiscp.discover({address: '192.168.178.98'}, @eiscpDiscovered)

    eiscpDiscovered: (err, result) =>
      if err
        env.logger.error('Onkyo (eiscp) discovery failed')
        return

      env.logger.info('eiscpDiscovered (err, result): ', err, result)
      @emit('discovery', result)

    powerOn: ->
      eiscp.command('system-power=on')

    powerOff: ->
      eiscp.command('system-power=standby')

    volumeUp: ->
      eiscp.command('volume=level-up')

    volumeDown: ->
      eiscp.command('volume=level-down')

    volumeMute: (type) ->
      switch type
        when 'on', 'off', 'toggle'
          eiscp.command('audio-muting=' + type)
        else
          env.logger.error('Invalid volumeMute type ', type)

    setSource: (name) ->
      eiscp.command('input-selector=' + name)
      return true

  return OnkyoControl
