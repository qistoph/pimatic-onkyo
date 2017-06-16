$(document).on("templateinit", (event) ->
  console.log('templateinit, window.pimatic.Device: ', window.pimatic.Device);

  class OnkyoDeviceItem extends pimatic.DeviceItem
    #getItemTemplate: -> 'onkyodevice'
    constructor: (data, @device) ->
      super(data, @device)
      console.log("Creating OnkyoDeviceItem: ", this, data, @device)

      powerAttribute = @getAttribute('power')
      unless powerAttribute?
        throw new Error("OnkyoDeviceItem needs a power attribute!")
      @powerState = ko.observable(powerAttribute.value())
      powerAttribute.value.subscribe( (newValue) =>
        @_restoringState = true
        @powerState(newValue)
        pimatic.try => @updatePower()
        @_restoringState = false
      )

      sourceAttribute = @getAttribute('source')
      unless sourceAttribute?
        throw new Error("OnkyoDeviceItem needs a source attribute!")
      @sourceState = ko.observable(sourceAttribute.value())
      sourceAttribute.value.subscribe( (newValue) =>
        @_restoringState = true
        @sourceState(newValue)
        pimatic.try => @updateButtons()
        @_restoringState = false
      )

      mutedAttribute = @getAttribute('muted')
      unless mutedAttribute?
        throw new Error("OnkyoDeviceItem needs a muted attribute!")
      @mutedState = ko.observable(mutedAttribute.value())
      mutedAttribute.value.subscribe( (newValue) =>
        @_restoringState = true
        @mutedState(newValue)
        pimatic.try => @updateMuted()
        @_restoringState = false
      )

    afterRender: (elements) ->
      super(elements)
      @powerButton = $(elements).find('[name=powerButton]')
      @muteButton = $(elements).find('[name=volMuteButton]')
      @sourceButtons = $(elements).find('.source-btn')
      @updatePower()
      @updateMuted()
      @updateButtons()

    updatePower: ->
      power = @powerState()
      if power == "on"
        @powerButton.addClass('ui-btn-active')
      else
        @powerButton.removeClass('ui-btn-active')

    updateMuted: ->
      muted = @mutedState()
      console.log("Muted: ", muted)

      if muted
        @muteButton.addClass('ui-btn-active')
      else
        @muteButton.removeClass('ui-btn-active')

    updateButtons: ->
      source = @sourceState()
      console.log("Source: ", source)

      @sourceButtons.removeClass('ui-btn-active')
      console.log('@sourceButtons: ', @sourceButtons)
      if source? and source != ""
        active = @sourceButtons.filter('[name='+source+']')
        console.log('Active: ', active)
        active.addClass('ui-btn-active')

    switchPower: (btn) ->
      newPower = if !@powerButton.hasClass('ui-btn-active') then 'on' else 'off'
      if @_restoringState then return
      @device.rest.setPower({power: newPower})
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)

    sourceBtnPress: (btn) ->
      if @_restoringState then return
      @device.rest.switchSource({name: btn.key}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)

    volUp: ->
      if @_restoringState then return
      @device.rest.volumeUp({}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
      return

    volMute: ->
      if @_restoringState then return
      @device.rest.volumeMute({}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
      return

    volDown: ->
      if @_restoringState then return
      @device.rest.volumeDown({}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)
      return

  pimatic.OnkyoDeviceItem = OnkyoDeviceItem
  pimatic.templateClasses['onkyodevice'] = OnkyoDeviceItem
)
