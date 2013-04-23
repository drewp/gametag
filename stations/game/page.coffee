thisGame = "http://game1" # to get from url

$(".scorecard").hide()

class Model
  constructor: ->
    @decoded = ko.observable(false)
  simUser1: =>
    $.post("../../../events", {type: "scan", user: "/users/1", game: thisGame}, (data) ->
      console.log("scans", data)
    )

model = new Model()

new reconnectingWebSocket(socketRoot + "/events", (msg) ->
  if msg.type == "scan" && msg.game == thisGame
    model.decoded(true)
    $(".scorecard")
      .addClass("scorecardAnim")
      .show()

)
ko.applyBindings(model)