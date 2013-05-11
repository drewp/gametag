async = require("../3rdparty/async-0.2.7.js")

exports.computeScore = (events, allGames, user, cb) ->
  gameByUri = {}
  for g in allGames
    gameByUri["/games/"+g._id] = g

  events.find({
      user: user,
      type: {$in: ["scan", "achievement"]},
      cancelled: {$ne: true}
    },
    {sort: {t:1}}
    ).toArray((err, evs) ->
      score = {points: 0, games: 0}
      async.each(evs, ((ev, cb) ->
        # this should be using UserScore now
          console.log("consider", ev)
          switch ev.type
            when "scan"
              score.points += gameByUri[ev.game].pointsForPlaying
              score.games += 1
            when "achievement"
              score.points += ev.won.points if ev.won.points?
          cb(null)
        ),
        ((err) ->
          throw err if err?
          cb(score)
        )) 
          
    )
