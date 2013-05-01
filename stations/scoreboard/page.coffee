model =
  users: ko.observableArray([])
  numColumns: 5
  maxTopUsers: 25

readEvents = ->
  $.getJSON "../../users", {}, (data) ->
    users = _.sortBy(data.users, (u) -> [-u.score.points, -u.score.games])
    model.users(_.first(users, model.maxTopUsers))
    
readEvents()

new reconnectingWebSocket(socketRoot + "/events", (msg) ->
  readEvents()
)
        
ko.applyBindings(model)