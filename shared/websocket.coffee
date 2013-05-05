window.ReconnectingWebSocket = (url, onReconnect, onMessage) ->
  connect = ->
    ws = new WebSocket(url)
    ws.onopen = ->
      onReconnect()
      $("#status").text(" connected").prepend($("<i>").addClass("icon-bolt"))

    ws.onerror = (e) ->
      $("#status").text("error: " + e)

    ws.onclose = ->
      $("#status").text(" disconnected").prepend($("<i>").addClass("icon-refresh icon-spin"))
      
      # this should be under a requestAnimationFrame to
      # save resources
      setTimeout(connect, 2000)

    ws.onmessage = (evt) ->
      onMessage(JSON.parse(evt.data))
  connect()
