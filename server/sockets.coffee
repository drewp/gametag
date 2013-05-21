io = require('socket.io')
isAdmin = require("./access.js").isAdmin

exports.Sockets = class Sockets
  # one-way websocket for sending events back out to the
  # browsers. Clients just use straight HTTP for incoming communications.

  constructor: (server, path) ->
    

    @connectedSockets = {} # id : connection

    @io = io.listen(server)
    @io.set('log level', 1)
    @io.set('authorization', (handshakeData, callback) =>
      if not isAdmin()
        callback(new Error("forbidden"));
    )

    @io.sockets.on('connection', (socket) =>
      console.log("new sock connection " + socket.id)
      @connectedSockets[socket.id] = socket
    )

  sendToAll: (msg) =>
    for _, conn of @connectedSockets
        console.log("sending to", conn.remoteAddress)
        conn.emit('event', msg)
