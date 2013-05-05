gameId = window.location.pathname.split("/")[3]
thisGame = "/games/"+gameId


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
    $.getJSON(thisGame, (data) =>
      @game(data)
    )
    
  award: (ach, uiEvent) =>
    uiEvent.currentTarget.disabled = true
    $.ajax({
      url: "../../../events",
      type: "POST",
      data: JSON.stringify({type: "achievement", user: @lastUser(), game: thisGame, won: ach}),
      contentType: "application/json",
      success: (ev) ->
        uiEvent.currentTarget.disabled = false
    })

  summarizeWin: window.summarizeWin
  bye: () ->
    # clearUser is not used; it's just to make the event more readable
    $.post("../../../events", {type: "scan", game: thisGame, clearUser: true}, (ev) ->)
    
model = new Model()

isScanEvent = (ev) ->
  ev.type == "scan" && ev.game in [thisGame, "https://gametag.bigast.com"+thisGame+"/"]

userXhr = null
reloadUser = () ->
    userXhr.abort() if userXhr?
    if !model.lastUser()
      model.lastUserData(null)
      return
    userXhr = $.getJSON(model.lastUser(), (data) =>
      model.lastUserData(data)
    )

onEvent = (ev) ->
  if isScanEvent(ev)
    model.lastUser(ev.user)
    model.lastScanTime(ev.t)
    reloadUser()


readAll = () ->
  $.getJSON(".././../../events/all", (data) ->
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