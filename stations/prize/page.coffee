thisGame = "https://gametag.bigast.com/stations/prize"

class Model
  constructor: ->
    @maxPoints = 50000 # for pointsBar
    @allGames = ko.observable(null)

    @displayedUser = ko.observable(null)
    @recentUserData = ko.observable(null)
    @userDataChanged = ko.observable(null) # just an event trigger



    updateUserScore = ko.computed =>
      @userDataChanged()
      if @displayedUser()?
        $.getJSON identifiers.localSite(@displayedUser()), (data) =>
          @recentUserData(data)
      else
        @recentUserData(null)

    @pointsToSpend = ko.computed =>
      if not @allGames()? or not @recentUserData()?
        return 0
      
      score = @recentUserData().score
      Math.max(0, score.points - score.absSpentPoints)
    
    @gameReport = ko.computed =>
      if not @allGames()? or not @recentUserData()?
        return null
        
      _.extend({
          played: @recentUserData().score.perGame[g.uri]
        },  g) for g in @allGames()

    @catalog = ko.computed =>
      if not @allGames()? or not @recentUserData()?
        return null
      toSpend = @pointsToSpend()

      _.extend({
          cantAfford: p.points > toSpend,
          avail: p.points <= toSpend
        }, p) for p in window.prizes
      

onScan = (scanEvent) ->
  return if scanEvent.game != thisGame
  if not scanEvent.user?
    return model.recentUserData(null) 
    
  model.displayedUser(scanEvent.user)

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

    if ev.user == model.displayedUser()
      model.userDataChanged(new Date())
  )
  ko.applyBindings(model)