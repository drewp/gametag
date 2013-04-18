WebSocketServer = require('websocket').server

exports.Sockets = class Sockets
  # one-way websocket for sending events back out to the
  # browsers. Clients just use straight HTTP for incoming communications.

  constructor: (server, path) ->
    # connection tracker is based on
    # https://github.com/Worlize/WebSocket-Node/wiki/How-to:-List-all-connected-sessions-&-Communicating-with-a-specific-session-only
    maxId = 0
    @connectedSockets = {} # id : connection
        
    @wsServer = new WebSocketServer({
      httpServer: server,
      autoAcceptConnections: false
    })

    @wsServer.on('request', (request) =>
      if request.resource != path
        return request.reject("unknown WS path")
      
      console.log("websocket: accepting connection from", request.origin)
      connection = request.accept(null, request.origin)
      connection.id = maxId++
      @connectedSockets[connection.id] = connection

      connection.on("close", (reasonCode, description) =>
        delete @connectedSockets[connection.id]
        console.log("websocket: close from", connection.remoteAddress)
      )
    )

  sendToAll: (msg) ->
    s = JSON.stringify(msg)
    for _, conn of @connectedSockets
        console.log("sending to", conn.remoteAddress)
        conn.sendUTF(s)
