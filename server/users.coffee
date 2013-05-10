async = require("../3rdparty/async-0.2.7.js")
identifiers = require("../shared/identifiers.js")

exports.getAllUsers = (events, gameByUri, cb) ->
    events.find({type:"enroll", cancelled: {$ne: true}}).sort({t:1}).toArray (err, enrolls) ->
      return cb(err) if err?
      async.map(enrolls,
                ((enrollEvent, cb2) ->
                  computeScore(events, gameByUri, enrollEvent.user, {}, (score) ->
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
      computeScore(events, gameByUri, uri, opts, (score) ->
        doc.score = score
        cb(null, doc)
      )
    )


computeScore = (events, gameByUri, user, opts, cb) ->
  events.find({
      user: user,
      type: {$in: ["scan", "achievement"]},
      cancelled: {$ne: true}
    },
    {sort: {t:1}}
    ).toArray((err, evs) ->
      score = {points: 0, games: 0}
      if opts.allEvents
        score.events = []
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
            if opts.allEvents
              score.events.push(ev)
          when "achievement"
            score.points += ev.won.points if ev.won.points?
            if opts.allEvents
              score.events.push(ev)           

       cb(score)
    )
