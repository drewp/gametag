gameId = window.location.pathname.split("/")[3]
thisGame = "/games/"+gameId

$(".scorecard").hide()

class Model
  constructor: ->
    @recentlyScannedUser = ko.observable(null)

    @simUsers = ('/users/'+x for x in [1..5])
    
  simUserScan: (who) =>
    $.post("../../../events", {type: "scan", user: who, game: thisGame}, (ev) ->
      console.log("test scan made event", ev)
    )
    
  bgImage: =>
    "bg/"+ gameId + ".jpg"

model = new Model()

new reconnectingWebSocket(socketRoot + "/events", (msg) ->
  if msg.type == "scan" && msg.game == thisGame
    model.recentlyScannedUser(msg.user)
    
    $(".scorecard")
      .addClass("scorecardAnim")
      .show()

)
ko.applyBindings(model)