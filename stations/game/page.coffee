gameId = window.location.pathname.split("/")[3]
thisGame = identifiers.gameUri(gameId)

thisGameData = null

class NewScoreEvents
  # tracks the events that affect the current player on this play of the game
  # 
  constructor: () ->
    # these are scan and achievement events in increasing time order,
    # augmented with 'scoreDesc' and 'scoreWon' display strings. If
    # there's no current scan, this array will be empty.
    @eventList = ko.observableArray([])
    @currentUser = ko.observable(null)
    
  rebuild: (allEvents) ->
    @eventList.removeAll()
    for ev in @_eventsSinceLastScan(allEvents) # forwards in time
      @onNewEvent(ev)
    console.log("rebuilt", @eventList())
    
  onNewEvent: (ev) =>
    # add new event to @eventList if appropriate, and clear/restart eventList
    if ev.cancelled
      return
    if ev.type == "scan"
      if ev.game == thisGame
        if !ev.user?
          @_onClearEvent(ev)
          return
        else
          @_onNewUserScanEvent(ev)
    else
      if ev.game == thisGame && ev.user == @currentUser()
        @_onNewEventForCurrentUser(ev)

  _onClearEvent: (ev) =>
    @eventList.removeAll()
    @currentUser(null)

  _onNewUserScanEvent: (ev) =>
    @eventList([@_augment(ev)])
    @currentUser(ev.user)

  _onNewEventForCurrentUser: (ev) =>
    @eventList.push(@_augment(ev))

  _augment: (ev) =>
    [ev.scoreDesc, ev.scoreWon] = switch ev.type
      when "scan"
        ["Points for playing", thisGameData?.pointsForPlaying]
      when "achievement"
        ["Got "+ev.won.label, summarizeWin(ev.won)]
    ev

  _eventsSinceLastScan: (allEvents) =>
    # result may still include irrelevant events, but it always starts
    # at the most recent scan for this game
    ret = []
    for ev in allEvents # going backwards in time
      if ev.cancelled
        continue
      ret.push(ev)
      if ev.type == "scan" && ev.game == thisGame
        break
    ret.reverse() # now forwards in time
    ret

class Model
  constructor: ->
    @newScoreEvents = new NewScoreEvents()
    @recentUserData = ko.observable(null)
    @userDataChanged = ko.observable(null) # just an event trigger

    ko.computed =>
      @userDataChanged()
      cur = @newScoreEvents.currentUser()
      if cur?
        $.getJSON cur, (data) =>
          @recentUserData(data)
      else
        @recentUserData(null)

    ko.computed =>
      if @newScoreEvents.currentUser()
        $(".scorecard")
          .addClass("scorecardAnim")
          .show()
      else
        $(".scorecard")
          .hide()
          .removeClass("scorecardAnim")
                        
  bgImage: =>
    "bg/" + gameId + ".jpg"

model = new Model()

$(".scorecard").hide()

reloadEvents = () ->     
  $.getJSON(".././../../events/all", (data) ->
    model.newScoreEvents.rebuild(data.events)
  )

$.getJSON identifiers.localSite(thisGame), (data) =>
  thisGameData = data
  # slightly easier (but slower) to get the game data before anything else

  new ReconnectingWebSocket(socketRoot + "/events", reloadEvents, (ev) ->
    if ev.type == 'cancel'
      reloadEvents()
      model.userDataChanged(new Date()) 
      return
      
    model.newScoreEvents.onNewEvent(ev)
    if ev.user?
      model.userDataChanged(new Date())
  )
  ko.applyBindings(model)
