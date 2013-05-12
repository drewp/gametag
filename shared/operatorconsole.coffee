
watchEventForNewScan = (model, thisGame, ev) ->
  # act on this new event if is a scan or clear for our screen
  if _.findWhere([ev], {type: "scan", game: thisGame}) != null
    if ev.user?
      model.currentScan(ev)
    else
      model.currentScan(null)

        
_userXhr = null
reloadUser = (model) ->
  # refresh model.currentUserData from model.currentScan().user
  _userXhr.abort() if _userXhr?
  if !model.currentScan()? || !model.currentScan().user?
    model.currentUserData(null)
    return
  _userXhr = $.getJSON(identifiers.localSite(model.currentScan().user), (data) =>
    model.currentUserData(data)
  )

window.operatorconsole =

  lastScanData: () ->
    # put these at the root of your model on an operator
    # page. scanopwidget.jade uses them.
    toAdd = {
      currentScan:  ko.observable(null)
      currentUserData:  ko.observable(null)
      now: (() ->
              now = ko.observable()
              setInterval((() => now(new Date())), 1000)
              now)()
    }
    toAdd.lastScanTime = ko.computed => toAdd.currentScan()?.t
    toAdd.scanAgo = ko.computed(() =>
        toAdd.now()
        moment(toAdd.lastScanTime()).fromNow()
      )
    toAdd

  reloadUser: reloadUser   

  bye: (toRoot, game) ->
    # clearUser is not used; it's just to make the event more readable
    $.post(toRoot + "/events", {type: "scan", game: game, clearUser: true}, (ev) ->)

  postButton: (uiEvent, url, jsData) ->
    uiEvent.currentTarget.disabled = true
    $.ajax({
      url: url,
      type: "POST",
      data: JSON.stringify(jsData),
      contentType: "application/json",
      success: (ev) ->
        uiEvent.currentTarget.disabled = false
    })

  getLatestScan: (model, toRoot, thisGame) ->
    # find latest scan for this game, call onNewestScan with the event
    $.getJSON(toRoot + "/events/all", (data) ->
      newestScan = _.findWhere(data.events, {type: "scan", game: thisGame})
      watchEventForNewScan(model, thisGame, newestScan)
    )

  watchEventForNewScan: watchEventForNewScan
