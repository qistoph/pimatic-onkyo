module.exports ={
  title: "pimatic-onkyo device config schemas"
  OnkyoReceiver: {
    title: "OnkyoReceiver config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      host:
        description: "IP/name of the host"
        type: "string"
      port:
        description: "Port of the EISCP service"
        type: "number"
        default: 60128
      guiShowVolumeControl:
        description: ""
        type: "boolean"
        default: true
      buttons:
        description: ""
        type: "array"
        default:
          [
            {
              key: 'tv'
              text: 'TV'
            }
            {
              key: 'dvd'
              text: 'DVD'
            }
          ]
        format: "table"
        items:
          type: "object"
          properties:
            key:
              description: "TODO"
              type: "string"
            text:
              description: "TODO"
              type: "string"
  }
}
