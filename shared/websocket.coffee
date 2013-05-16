window.ReconnectingWebSocket = (onReconnect, onMessage) ->
  connect = ->

    socket = io.connect('//', {
      # https://github.com/LearnBoost/Socket.IO/wiki/Configuring-Socket.IO#client
      'max reconnection attempts': 500
    })

    setStatus = (quality, msg) ->
      $("#status").text(" " + msg).prepend($("<i>").addClass(
        switch quality
          when "good" then "icon-bolt"
          when "bad" then "icon-refresh icon-spin"
        ))

    socket.on "reconnect_failed", (r) ->
      setStatus("bad", "reconnect failed")

    socket.on "error", (r) ->
      setStatus("bad", "error " + r)

    socket.on "connecting", (how) ->
      setStatus("bad", "connecting via " + how)

    socket.on "connect", () ->
      setStatus("good", "connected")
      onReconnect()

    socket.on "disconnect", ->
      setStatus("bad", "disconnected")

    socket.on "connect_failed", (r) ->
      setStatus("bad", "connect failed: " + r)

    socket.of("").on "event", (r) ->
      onMessage(r)
    
  connect()
