module.exports = (env) ->

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take 
  # a look at the dependencies section in pimatics package.json

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  path = env.require 'path'

  OnkyoControl = env.require(path.join(__dirname, 'lib/onkyo-control')) env

  # Include you own depencies with nodes global require function:
  #  
  #     someThing = require 'someThing'
  #  

  # ###OnkyoPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
  class OnkyoPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      if @config.debug
        env.logger.debug("OnkyoPlugin starting, with config:", @config)

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("OnkyoReceiver", {
        configDef: deviceConfigDef.OnkyoReceiver,
        createCallback: (config) => new OnkyoReceiver(this, config)
      })

      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', 'pimatic-onkyo/app/onkyo-js.coffee'
          #mobileFrontend.registerAssetFile 'css', 'pimatic-onkyo/app/css/onkyo-css.css'
          mobileFrontend.registerAssetFile 'html', 'pimatic-onkyo/app/onkyo-html.jade'
        else
          env.logger.warn "Mobile-frontend not found. No GUI available."

      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage('pimatic-onkyo', 'Contacting Onkyo devices')

        onkyoController = new OnkyoControl()
        onkyoController.on('discovery', (result) =>
          for device in result
            config = {
              class: 'OnkyoReceiver'
              id: 'onkyo_' + device.mac
              host: device.host
            }
            if 1*device.port != 60128
              config.port = device.port
            @framework.deviceManager.discoveredDevice(
              'pimatic-onkyo', device.model, config
            )
        )
        onkyoController.discover()
      )

  class OnkyoReceiver extends env.devices.Device
    template: "onkyodevice"

    powerState: false
    activeSource: ""
    isMuted: false

    constructor: (@plugin, @config) ->
      @id = @config.id
      @name = @config.name

      @onkyoControl = new OnkyoControl()

      @onkyoControl.on('power', (state) =>
        @powerState = state == 'on'
        @emit 'power', if @powerState then 'on' else 'off'
      )

      @onkyoControl.on('mute', (muted) =>
        @isMuted = muted
        @emit 'muted', muted
      )

      @onkyoControl.on('source', (name) =>
        env.logger.debug('source: ', name)
        @activeSource = name
        @emit 'source', name
      )

      @onkyoControl.connect(@config.host, @config.port)

      if @plugin.config.debug
        env.logger.info("OnkyoReceiver created, with config:", @config)

      super(@config)

    destroy: () ->
      super()

    attributes:
      power:
        description: "Is the system turned on"
        type: "string"
      muted:
        description: "Indicates if audio is muted"
        type: "boolean"
      source:
        description: "The active source"
        type: "string"

    getPower: -> Promise.resolve(if @powerState then 'on' else 'off')

    getSource: -> Promise.resolve(@activeSource)

    getMuted: -> Promise.resolve(@isMuted)

    actions:
      setPower:
        description: "Turn the device on or off"
        params:
          power:
            type: "string"
      switchSource:
        description: "Changes the active source"
        params:
          name:
            type: "string"
      volumeUp:
        description: "Increase the volume"
      volumeDown:
        description: "Decrease the volume"
      volumeMute:
        description: "Toggle muting"

    setPower: (power) ->
      if power == 'on' then @onkyoControl.powerOn()
      else if power == 'off' then @onkyoControl.powerOff()
      else env.logger.error("Invalid power value (expected: on/off): ", power)
      return Promise.resolve()

    switchSource: (name) ->
      @onkyoControl.setSource(name)
      return Promise.resolve()
    
    volumeUp: () ->
      @onkyoControl.volumeUp()
      return Promise.resolve()

    volumeDown: () ->
      @onkyoControl.volumeDown()
      return Promise.resolve()

    volumeMute: () ->
      @onkyoControl.volumeMute('toggle')
      return Promise.resolve()
    
  # ###Finally
  # Create a instance of my plugin
  onkyoPlugin = new OnkyoPlugin
  # and return it to the framework.
  return onkyoPlugin
