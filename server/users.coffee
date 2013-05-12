async = require("../3rdparty/async-0.2.7.js")
identifiers = require("../shared/identifiers.js")
_ = require("../3rdparty/underscore-1.4.4-min.js")


exports.getAllUsers = (events, gameByUri, cb) ->
    events.find({type:"enroll", cancelled: {$ne: true}}).sort({t:1}).toArray (err, enrolls) ->
      return cb(err) if err?
      async.map(enrolls,
                ((enrollEvent, cb2) ->
                  computeScore(events, gameByUri, enrollEvent.user, enrollEvent.ageCategory || "high", {}, (err, score) ->
                    cb2(err) if err?
                    enrollEvent.score = score
                    cb2(null, enrollEvent)
                  )
                 ),
                ((err, users) ->
                  if err?
                    cb(err)
                  else
                    cb(null, users)
                  )
      )

exports.findOneUser = (events, gameByUri, uri, cb, opts) ->
   opts = {} if not opts?
   events.findOne({type:"enroll", user: uri, cancelled: {$ne: true}}, (err, doc) ->
      return cb(err) if err?
      return cb(null, doc) if not doc?
      computeScore(events, gameByUri, uri, doc.ageCategory || "high", opts, (err, score) ->
        cb(err) if err?
        doc.score = score
        cb(null, doc)
      )
    )


computeScore = (events, gameByUri, user, ageCategory, opts, cb) ->
  events.find({
      user: user,
      type: {$in: ["scan", "achievement", "buy"]},
      cancelled: {$ne: true}
    },
    {sort: {t:1}}
    ).toArray((err, evs) ->
      score = {points: 0, games: 0, spentPoints: 0, perGame: {}, rank: []}
      if opts.allEvents
        score.events = []
      lastScannedGame = null
      boughtRankPrizes = []
      for ev in evs
        switch ev.type
          when "scan"
            if ev.game == lastScannedGame
              # no points for repeat scan. Currently this even takes
              # effect if other users played in between or if the
              # gameop cleared your scan. Your new scan will wake up
              # the game screen but not give you points.
              continue

            if ev.game == 'https://gametag.bigast.com/stations/prize'
              continue
            g = gameByUri[ev.game]
            if not g?
              console.log("unknown game in scoring: "+ev.game)
            else
              score.points += g.pointsForPlaying
              score.games += 1
              score.perGame[ev.game] = (score.perGame[ev.game] || 0) + 1
              lastScannedGame = ev.game
            if opts.allEvents
              score.events.push(ev)
          when "achievement"
            score.points += ev.won.points if ev.won.points?
            if opts.allEvents
              score.events.push(ev)
          when "buy"
            if ev.rankPrize?
              boughtRankPrizes.push(ev.rankPrize)
            else
              score.spentPoints += ev.points
       try
         currentRank = computeRank(score.points, score.perGame, ageCategory)
       catch e
         console.log("computeRank failed on "+user+", "+e)
         cb(e)
       score.rank = rankResult(boughtRankPrizes, currentRank)

       cb(null, score)
    )

rankResult = (boughtRankPrizes, currentRank) ->
  ranks = ["cadet", "captain", "colonel", "commander", "commodore"]
  {
    rank: r
    label: r[0].toUpperCase() + r.substr(1)
    havePrize: r in boughtRankPrizes
    isCurrent: r == currentRank
    alreadyAchieved: ranks.indexOf(r) < ranks.indexOf(currentRank)
    notAchieved: ranks.indexOf(r) > ranks.indexOf(currentRank)
  } for r in ranks
    
computeRank = (points, perGame, ageCategory) ->
  distinctGames = gameCount(perGame, 1)
  totalGames = gameCount(perGame, 999)
  switch ageCategory
    when "elementary"
      return "commodore" if gameCount(perGame, 5) >= 50 or points >= 40000
      return "commander" if gameCount(perGame, 4) >= 30 or points >= 25000
      return "colonel"   if totalGames >= 20 or points >= 15000
      return "captain"   if distinctGames >= 14
      return "cadet"
    when "middle"
      return "commodore" if gameCount(perGame, 5) >= 55 or points >= 45000
      return "commander" if gameCount(perGame, 4) >= 35 or points >= 30000
      return "colonel"   if totalGames >= 25 or points >= 20000
      return "captain"   if distinctGames >= 15
      return "cadet"
    when "high"
      return "commodore" if gameCount(perGame, 5) >= 60 or points >= 50000
      return "commander" if gameCount(perGame, 4) >= 40 or points >= 35000
      return "colonel"   if totalGames >= 30 or points >= 25000
      return "captain"   if distinctGames >= 15 and points >= 15000
      return "cadet"
  throw new Error("unknown ageCategory "+ageCategory)
    

gameCount = (perGame, maxAllowedPerGame) ->
  qualifyingGameCount = 0
  for game, count of perGame
    qualifyingGameCount += Math.min(count, maxAllowedPerGame)
  qualifyingGameCount
  