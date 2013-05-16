io = require('socket.io')

exports.Sockets = class Sockets
  # one-way websocket for sending events back out to the
  # browsers. Clients just use straight HTTP for incoming communications.

  constructor: (server, path) ->
    

    @connectedSockets = {} # id : connection

    @io = io.listen(server)

    @io.sockets.on('connection', (socket) =>
      console.log("new sock connection " + socket.id)
      @connectedSockets[socket.id] = socket
    )

    return 
        
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

  sendToAll: (msg) =>
    for _, conn of @connectedSockets
        console.log("sending to", conn.remoteAddress)
        conn.emit('event', msg)
