thisGame = "http://game1" # to get from url

$(".scorecard").hide()

class Model
  constructor: ->
    @decoded = ko.observable(false)
  simUser1: =>
    $.post("../../../scans", {qr: "/users/1", game: thisGame}, (data) ->
      console.log("scans", data)
    )

model = new Model()

new reconnectingWebSocket("ws://dash:3200/events", (msg) ->
  if msg.event == "userScan" && msg.game == thisGame
    model.decoded(true)
    $(".scorecard")
      .addClass("scorecardAnim")
      .show()

)
ko.applyBindings(model)