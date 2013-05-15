model =
  users: ko.observableArray([])
  numColumns: 5
  maxTopUsers: 25

readEvents = ->
  $.getJSON "../../users", {}, (data) ->
    users = data.users

    users.sort (a,b) ->
      if a.score.points == b.score.points
        return (if a.label < b.label then -1 else 1)
      return (if a.score.points > b.score.points then -1 else 1)

    for i in [0...users.length]
      users[i].classes = c = {}
      c['two' + (i % 2)] = true
      c['three' + (i % 3)] = true

    model.users(_.first(users, model.maxTopUsers))
    
new ReconnectingWebSocket(socketRoot + "/events", readEvents, (msg) ->
  readEvents()
)
        
ko.applyBindings(model)