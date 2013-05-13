thisGame = "https://gametag.bigast.com/stations/prize"

class Model
  constructor: ->
    @maxPoints = 50000 # for pointsBar
    @allGames = ko.observable(null)

    @displayedUser = ko.observable(null)
    @recentUserData = ko.observable(null)
    @userDataChanged = ko.observable(null) # just an event trigger
    @gameReport = ko.observable(null)

    updateUserScore = ko.computed =>
      @userDataChanged()
      if @displayedUser()?
        $.getJSON identifiers.localSite(@displayedUser()), (data) =>
          @recentUserData(data)
      else
        @recentUserData(null)
    
    updateGameReport = ko.computed =>
      if not @allGames()? or not @recentUserData()?
        return @gameReport(null)
        
      @gameReport(_.extend({
          played: @recentUserData().score.perGame[g.uri]
        },  g) for g in @allGames())

onScan = (scanEvent) ->
  return if scanEvent.game != thisGame
  if not scanEvent.user?
    return model.recentUserData(null) 
    
  model.displayedUser(scanEvent.user)

model = new Model()

reloadEvents = () ->
  # this is to notice prize table scans 
  $.getJSON("../../events/all", (data) ->
    latestScan = _.find(data.events, (ev) -> (ev.type == "scan" && ev.game == thisGame && ev.cancelled != true))
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

    console.log("new ev", ev.user, model.displayedUser())
    if ev.user == model.displayedUser()
      model.userDataChanged(new Date())
    if ev.type == "scan"
      if not ev.user?
        model.displayedUser(null)
      model.displayedUser(ev.user)
  )
  ko.applyBindings(model)
