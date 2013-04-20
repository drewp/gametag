model =
  users: ko.observableArray([])
  deleteUser: (user) =>
    $.ajax(
      url: user.uri
      type: "DELETE"
      success: () ->
        console.log("del")
    )

readUsers = ->
  $.getJSON "../../users", {}, (data) ->
    model.users(data.users)
readUsers()



new reconnectingWebSocket("ws://dash:3200/events", (msg) ->
  console.log("msg", msg)
  if msg.event in ["userChange", "userScan"]
    readUsers()
)
        
ko.applyBindings(model)