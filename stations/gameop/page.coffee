gameId = window.location.pathname.split("/")[3]
thisGame = identifiers.gameUri(gameId)

class Model
  constructor: ->
    @game = ko.observable(null)
    @lastUser = ko.observable(null)
    @lastUserData = ko.observable(null)
    @lastScanTime = ko.observable(0)

    @now = ko.observable()
    setInterval((() => @now(new Date())), 1000)
    @scanAgo = ko.computed(() =>
      @now()
      moment(@lastScanTime()).fromNow()
    )
    $.getJSON(identifiers.localSite(thisGame), (data) =>
      @game(data)
    )
    
  award: (ach, uiEvent) =>
    postButton(uiEvent, "../../../events", {
      type: "achievement",
      user: @lastUser(),
      game: thisGame,
      won: ach})
    
  summarizeWin: window.summarizeWin
  bye: () -> operatorconsole.bye(thisGame)
    
model = new Model()

isScanEvent = (ev) ->
  ev.type == "scan" && ev.game == thisGame

userXhr = null
reloadUser = () ->
    userXhr.abort() if userXhr?
    if !model.lastUser()
      model.lastUserData(null)
      return
    userXhr = $.getJSON(identifiers.localSite(model.lastUser()), (data) =>
      model.lastUserData(data)
    )

onEvent = (ev) ->
  if isScanEvent(ev)
    model.lastUser(ev.user)
    model.lastScanTime(ev.t)
    reloadUser()


readAll = () ->
  $.getJSON("../../../events/all", (data) ->
    newestScan = _.find(data.events, isScanEvent)
    if newestScan?
      onEvent(newestScan)
  )

new ReconnectingWebSocket(socketRoot + "/events", readAll, (msg) ->
  onEvent(msg)
  if msg.type in ["scan", "achievement", "cancel"]
    reloadUser()
)
ko.applyBindings(model)