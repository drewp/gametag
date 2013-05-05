gameId = window.location.pathname.split("/")[3]
thisGame = "/games/"+gameId

$(".scorecard").hide()

class Model
  constructor: ->
    @latestScanEvent = ko.observable(null)
    @recentUserData = ko.observable(null)

    # events since the latest user scan (including that event),
    # augmented with 'scoreDesc' and 'scoreWon'
    @newScoreEvents = ko.observableArray([])

    @simUsers = ('/users/'+x for x in [1..5])

    ko.computed =>
      @recentUserData(null)
      if @latestScanEvent()?
        reloadUser()    
  simUserScan: (who) =>
    $.post("../../../events", {type: "scan", user: who, game: thisGame}, (ev) ->
      console.log("test scan made event", ev)
    )
    
  bgImage: =>
    "bg/"+ gameId + ".jpg"

model = new Model()

openScorecard = () ->
  $(".scorecard")
    .addClass("scorecardAnim")
    .show()

reloadUser = () ->
  $.getJSON model.latestScanEvent().user, (data) =>
    model.recentUserData(data)
    
# wrong; this should happen at startup and on reconnect
$.getJSON(".././../../events/all", (data) ->

  model.latestScanEvent(null)
  acc = []
  for ev in data.events # going backwards in time
    acc.push(ev)
    if ev.type == "scan" && ev.game == thisGame
      model.latestScanEvent(ev)
      break
  if !model.latestScanEvent()
    return

  openScorecard()
  reloadUser()
  acc.reverse()
  model.newScoreEvents([])
  for ev in acc # forwards in time
    if ev.game == thisGame && ev.user == model.latestScanEvent().user
      console.log("nse", ev)
      [ev.scoreDesc, ev.scoreWon] = switch ev.type
        when "scan"
          ["Points for playing", "??"]
        when "achievement"
          ["Got "+ev.won.label, summarizeWin(ev.won)]

      model.newScoreEvents.push(ev)
      
    
)

new reconnectingWebSocket(socketRoot + "/events", (msg) ->
  console.log("newmsg", msg)
#  if (msg.type == "scan" && msg.game == thisGame) || (msg.user == model.recentlyScannedUser())
#    onScan(msg)
)
ko.applyBindings(model)