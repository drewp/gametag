async = require("../3rdparty/async-0.2.7.js")
identifiers = require("../shared/identifiers.js")

exports.getAllUsers = (events, allGames, cb) ->
    events.find({type:"enroll", cancelled: {$ne: true}}).toArray (err, enrolls) ->
      return cb(err) if err?
      async.map(enrolls,
                ((enrollEvent, cb2) ->
                  computeScore(events, allGames, enrollEvent.user, (score) ->
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

exports.findOneUser = (events, allGames, uri, cb) ->
   events.findOne({type:"enroll", user: uri, cancelled: {$ne: true}}, (err, doc) ->
      return cb(err) if err?
      return cb(null, doc) if not doc?
      computeScore(events, allGames, uri, (score) ->
        doc.score = score
        cb(null, doc)
      )
    )


computeScore = (events, allGames, user, cb) ->
  gameByUri = {}
  for g in allGames
    gameByUri[identifiers.gameUri(g._id)] = g

  events.find({
      user: user,
      type: {$in: ["scan", "achievement"]},
      cancelled: {$ne: true}
    },
    {sort: {t:1}}
    ).toArray((err, evs) ->
      score = {points: 0, games: 0}
      lastScannedGame = null
      for ev in evs
        switch ev.type
          when "scan"
            if ev.game == lastScannedGame
              # no points for repeat scan. Currently this even takes
              # effect if other users played in between or if the
              # gameop cleared your scan. Your new scan will wake up
              # the game screen but not give you points.
              continue
              
            g = gameByUri[ev.game]
            if not g?
              console.log("unknown game in scoring: "+ev.game)
              return cb(null)
            score.points += g.pointsForPlaying
            score.games += 1
            lastScannedGame = ev.game
          when "achievement"
            score.points += ev.won.points if ev.won.points?

       cb(score)
    )
