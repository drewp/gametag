thisGame = "https://gametag.bigast.com/stations/prize"

class Model
  constructor: ->
    @allGames = ko.observable(null)
    @recentUserData = ko.observable(null)
    @userDataChanged = ko.observable(null) # just an event trigger
    @currentUserScore = ko.observable(null) # only assigned when we have a user
    @gameReport = ko.observable(null)
    
    ko.computed =>
      if not @allGames()? or not @recentUserData()?
        return @gameReport(null)
        
      @gameReport(_.extend({
          played: @recentUserData().score.perGame[g.uri]
        },  g) for g in @allGames())

    if false#ko.computed =>
      @userDataChanged()
      if @recentUserData()?
        setTimeout((() => 
          $.getJSON @recentUserData().user, (data) =>
            @recentUserData(data)
            
          ), 0)

    if false#noticeChangedUser = ko.computed =>
      return unless @recentUserData?
      score = new UserScore(@recentUserData())
      @currentUserScore(score)
      setTimeout((() ->
        # currently we have to see these all again to rebuild the user score
        #$.getJSON(".././../../events/all", (data) ->
        #  data.events.forEach((ev) => score.onEvent(ev))
        #)
        ), 0)


class UserScore
  # computes the full score and can incrementally update it with new events
  constructor: (userDoc) ->
    # pass me the enrollment doc for the user
    @user = userDoc.user
    @numEvents = 0

    #track points won, spent, ranks
    
  onEvent: (ev) =>
    # pass me all the type:scan and type:achievement events
    return if ev.user != @user
    return if ev.cancelled

    @numEvents = @numEvents + 1
  get: () =>
    {demo: @numEvents} 
    
onScan = (scanEvent) ->
  $.getJSON identifiers.localSite(scanEvent.user), (data) =>
    model.recentUserData(data)

model = new Model()



reloadEvents = () ->
  # this is to notice prize table scans 
  $.getJSON("../../events/all", (data) ->
    latestScan = _.find(data.events, (ev) -> (ev.type == "scan" && ev.game == thisGame))
    if latestScan?
      onScan(latestScan)
  )


$.getJSON "../../games", (data) ->
  model.allGames(_.sortBy(data.games, ((k,v) -> k)))
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