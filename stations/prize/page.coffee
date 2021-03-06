thisGame = "https://gametag.bigast.com/stations/prize"

class Model
  constructor: ->
    @maxPoints = 50000 # for pointsBar
    @allGames = ko.observable(null)

    @displayedUser = ko.observable(null)
    @recentUserData = ko.observable(null)
    @userDataChanged = ko.observable(null) # just an event trigger
    @prevUser = null


    updateUserScore = ko.computed =>
      @userDataChanged()
      if @displayedUser()?
        $.getJSON identifiers.localSite(@displayedUser()), (data) =>

          if @displayedUser != @prevUser
            @prevUser = @displayedUser
            realPoints = data.score.points
            data.score.points = 0
            for p in [0 .. realPoints] by 700
              offset = 1500 * p / realPoints
              setTimeout(((p2) => ( () => 
                data.score.points = p2
                @recentUserData(data) ) )(p),offset)
            setTimeout((() => 
              data.score.points = realPoints
              @recentUserData(data)),1501)


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
    latestScan = _.findWhere(data.events, {type: "scan", game: thisGame, cancelled: false})
    if latestScan?
      onScan(latestScan)
  )

$.getJSON "../../games", (data) ->
  model.allGames(_.sortBy(data.games, ((k,v) -> k)))
  new ReconnectingWebSocket(reloadEvents, (ev) ->
    if ev.type == 'cancel'
      reloadEvents()
      model.userDataChanged(new Date()) 
      return

    console.log("new ev", ev.user, model.displayedUser())
    if ev.user == model.displayedUser()
      model.userDataChanged(new Date())
    if ev.type == "scan" && ev.game == thisGame
      if not ev.user?
        model.displayedUser(null)
      model.displayedUser(ev.user)
  )
  ko.applyBindings(model)
