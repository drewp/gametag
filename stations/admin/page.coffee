model =
  users: ko.observableArray([])

readUsers = ->
  $.getJSON "../../users", {}, (data) ->
    model.users(data.users)
readUsers()
new reconnectingWebSocket("ws://dash:3200/events", (msg) ->
  console.log("msg", msg)
  if msg.event == "userChange"
    readUsers()
)
        
ko.applyBindings(model)