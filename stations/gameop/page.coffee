gameId = window.location.pathname.split("/")[3]
thisGame = identifiers.gameUri(gameId)

class Model
  constructor: ->
    @game = ko.observable(null)

    _.extend(this, operatorconsole.lastScanData())

    ko.computed =>
      @currentScan()
      operatorconsole.reloadUser(this)

    $.getJSON(identifiers.localSite(thisGame), (data) =>
      @game(data)
    )
    
  award: (ach, uiEvent) =>
    operatorconsole.postButton(uiEvent, "../../../events", {
      type: "achievement"
      user: @currentScan().user
      game: thisGame
      won: ach
    })
    
  summarizeWin: window.summarizeWin
  bye: () -> operatorconsole.bye("../../..", thisGame)




model = new Model()

new ReconnectingWebSocket(
  socketRoot + "/events",
  () -> operatorconsole.getLatestScan(model, "../../..", thisGame),
  (ev) ->
    operatorconsole.watchEventForNewScan(model, thisGame, ev)

    if ev.type == "cancel"
      return operatorconsole.getLatestScan(model, "../../..", thisGame)
    if ev.type in ["scan", "achievement"]
      operatorconsole.reloadUser(model)
)
ko.applyBindings(model)