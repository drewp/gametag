window.reconnectingWebSocket = (url, onMessage) ->
         # also needs onConnect that pages can use to backfill the events
         # they care about
  pong = 0
  connect = ->
    ws = new WebSocket(url)
    ws.onopen = ->
      $("#status").text(" connected").prepend($("<i>").addClass("icon-bolt"))

    ws.onerror = (e) ->
      $("#status").text "error: " + e

    ws.onclose = ->
      pong = 1 - pong
      $("#status").text(" disconnected").prepend($("<i>").addClass("icon-refresh icon-spin"))
      
      # this should be under a requestAnimationFrame to
      # save resources
      setTimeout connect, 2000

    ws.onmessage = (evt) ->
      onMessage JSON.parse(evt.data)
  connect()
