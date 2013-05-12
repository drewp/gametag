thisGame = "https://gametag.bigast.com/stations/prize"

class Model
  constructor: ->
    @allGames = ko.observable(null)
    @lastScan = ko.observable(null)
    @userData = ko.observable(null)
    @allUserPrizes = ko.observable(null)

    @now = ko.observable()
    setInterval((() => @now(new Date())), 1000)
    @scanAgo = ko.computed(() =>
      @now()
      moment(@lastScanTime()).fromNow()
    )
    $.getJSON(identifiers.localSite(thisGame), (data) =>
      @game(data)
    )

  canBuy: (ach) =>
    true
    # do we have enough points, or has this rank been earned and its prize not bought yet?
            
  award: (ach, uiEvent) =>
    postButton(uiEvent, "../../events", {
      type: "buy",
      user: @lastUser(),
      points: 33
      #rankPrize: 'cadet'
      })

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