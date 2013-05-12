thisGame = "https://gametag.bigast.com/stations/prize"

class Model
  constructor: ->
    @allGames = ko.observable(null)

    _.extend(this, operatorconsole.lastScanData())

    ko.computed =>
      @currentScan()
      operatorconsole.reloadUser(this)

    @availablePrizes = ko.computed =>
      score = @currentUserData()?.score
      if not score?
        return []
      pointsToSpend = score.points - score.spentPoints
      console.log("tospend", pointsToSpend)

      ret = []
      for size in [500, 1000, 2000]
        ret.push({
          label: "Give "+size+" point prize"
          points: -size
          enable: pointsToSpend >= size
          whyNot: "not enough points"
        })


      availRankPrizes = []
      for r in score.rank
        if r.rank == "cadet"
          continue
        row = {
          label: "Give "+r.rank+" prize"
          rankPrize: r.rank
          enable: true
        }
        if r.notAchieved
          _.extend(row, {enable: false, whyNot: "haven't reached this rank"})
        if r.havePrize
          _.extend(row, {enable: false, whyNot: "already have prize"})
        ret.push(row)
      ret
            
  buy: (ach, uiEvent) =>
    ev = {
      type: "buy"
      user: @currentScan().user
    }
    if ach.rankPrize?
      ev.rankPrize = ach.rankPrize
    if ach.points?
      ev.points = ach.points
    
    operatorconsole.postButton(uiEvent, "../../events", ev)

  bye: () -> operatorconsole.bye("../..", thisGame)   
    
model = new Model()

new ReconnectingWebSocket(
  socketRoot + "/events",
  () -> operatorconsole.getLatestScan(model, "../..", thisGame),
  (ev) ->
    operatorconsole.watchEventForNewScan(model, thisGame, ev)
    if ev.type == "cancel"
      return operatorconsole.getLatestScan(model, "../..", thisGame)
    if ev.type in ["scan", "achievement"]
      operatorconsole.reloadUser(model)
)
ko.applyBindings(model)