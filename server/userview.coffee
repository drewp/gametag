findOneUser = require("./users.js").findOneUser
points      = require("../shared/points.js")
moment      = require("../3rdparty/moment-2.0.0.min.js")

exports.userView = (events, gameByUri, uri, res) ->
  findOneUser(events, gameByUri, uri, ((err, userDoc) ->
    if err?
      res.send(500)
    else if not userDoc?
      res.send(404)
    else
      pointScale = if (userDoc.ageCategory || '?') == "adult" then 0 else 1
      eventDesc = (ev) ->
        desc = (switch ev.type
          when "scan"
            g = gameByUri[ev.game]
            if not g?
              "Played an unknown game"
            else
              "Played "+g.label+" and got "+((g.pointsForPlaying * pointScale) || 0)+" points"
          when "achievement"
            ev.won.label+ " and won "+points.summarizeWin(ev.won)
        )
        
        ""+moment(ev.t).format('h:mm:ss a')+": "+desc
      userDoc.score.events = ({t: ev.t, desc: eventDesc(ev)} for ev in userDoc.score.events)

      res.render("stations/userview/index.jade", {
          user: userDoc
          userJson: JSON.stringify(userDoc)
      })
  ), {allEvents: true})
