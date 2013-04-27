model =
  users: ko.observableArray([])
  numColumns: 3
  maxTopUsers: 12

readEvents = ->
  $.getJSON "../../events/all", {}, (data) ->

    users = []
    byUri = {}
    for ev in data.events by -1
      if ev.cancelled
        continue
      switch ev.type
        when 'enroll'
          row = _.extend({"points": 0, "games": 0}, ev)
          users.push(row)
          byUri[ev.user] = row
        when 'scan'
          byUri[ev.user].games++
    
    model.users(_.first(_.sortBy(users, (u) -> [-u.points, -u.games]), model.maxTopUsers))
    
readEvents()

new reconnectingWebSocket(socketRoot + "/events", (msg) ->
  readEvents()
)
        
ko.applyBindings(model)