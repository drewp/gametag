fs = require('fs')
express = require("express")
build = require("consolidate-build")
mongo = require("mongodb")
mime = require('connect').mime
app = express()
server = require("http").createServer(app)
Sockets = require("./sockets.js").Sockets
_ = require("../3rdparty/underscore-1.4.4-min.js")
async = require("../3rdparty/async-0.2.7.js")
Events = require("./events.js").Events
printSvgBody = require("./print.js").printSvgBody
exec = require('child_process').exec

app.engine("jade", build.jade)
app.engine("styl", build.stylus)
app.engine("coffee", build.coffee)

app.set('views', __dirname + "/..")

app.use("/static", express.static(__dirname));
app.use(express.logger())
app.use(express.bodyParser())

openMongo = (cb) ->
  client = new mongo.Db('gametag',
                        new mongo.Server('bang', 27017),
                        {w: 1, journal: true, fsync: true})
  client.open (err, _) ->
    throw err if err
    client.collection 'games', (err, games) ->
      throw err if err
      games.find({}).toArray (err, allGames) ->
        client.collection 'events', (err, events) ->
          throw err if err
          cb(games, allGames, events)

precompiledName = (requestedName) ->
  requestedName
    .replace(".css", ".styl")
    .replace(".js", ".coffee")
    .replace(".html", ".jade")

respondFile = (res, prefix, requestedPath) ->
    if requestedPath == ""
      requestedPath = "index.html"
    res.contentType(requestedPath)
    if requestedPath.match(/\.(jpg|png|webm|svg|gif)$/)
      # probably res.render could be made to handle this
      res.sendfile(prefix + precompiledName(requestedPath))
    else
      res.render(prefix + precompiledName(requestedPath))

openMongo (games, allGames, events) ->
  sockets = new Sockets(server, "/events")

  e = new Events(app, events, sockets)
  e.syncPicEvents()

  e.addRequestHandlers()

  app.get "/events/all", (req, res) ->
    # newest first
    e.getAllEvents((events) -> res.json(200, {events: events}))
    
  app.post "/events", (req, res) ->
    body = req.body
    e.postEvent(body, (ev) -> res.json(200, ev))

  nextUserId = (cb) ->
    # this doesn't care about whether events were cancelled
    events.find({type: "enroll"}).count(cb)

  app.get "/", (req, res) ->
    games.find().toArray (err, results) ->
      throw err if err
      for g in results
        g.uri = "/stations/game/"+g._id+"/"
        g.gameOp = "/stations/gameop/"+g._id+"/"
      res.render("stations/proto/index.jade", {
        title: "Consolidate.js",
        games: results
      })
  app.get "/page.js", (req, res) -> respondFile(res, 'stations/proto/', 'page.js')

  computeScore = (events, allGames, user, cb) ->
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

  app.get "/users", (req, res) ->
    events.find({type:"enroll", cancelled: {$ne: true}}).toArray (err, enrolls) ->
      throw err if err?
      async.map(enrolls,
                ((enrollEvent, cb) ->
                  computeScore(events, allGames, enrollEvent.user, (score) ->
                    enrollEvent.score = score
                    cb(null, enrollEvent)
                  )
                 ),
                ((err, users) ->
                  throw err if err?
                  res.json(200, {users: users})
                  )
      )

  app.get "/users/:u", (req, res) ->
    uri = "/users/"+req.params.u
    events.findOne({type:"enroll", user: uri, cancelled: {$ne: true}}, (err, doc) ->
      if err?
        res.send(500)
        return
      if not doc?
        res.send(404)
        return
      computeScore(events, allGames, uri, (score) ->
        doc.score = score
        res.json(200, doc)
      )
    )

  app.get "/games/:g", (req, res) ->
    res.json(200, _.find(allGames, (g) -> g._id == req.params.g))

  app.post "/users", (req, res) ->
    nextUserId((err, newId) ->
      e.newEvent("enroll",
               {pic: req.body.pic, user: "/users/" + newId, label: req.body.label},
               (err, ev) ->
                 throw err if err
                 sockets.sendToAll({"event":"enroll"})
                 res.json(200, ev)
      )
    )

  # GET /users/:id is what guests will revisit from their own badges later

  app.post "/picRescan", (req, res) ->
    e.syncPicEvents(() -> res.json(200, {}))
  
  app.post "/scans", (req, res) ->
    e.newEvent("scan", {user: req.body.qr, game: req.body.game}, (err, doc) ->
                   throw err if err
                   res.json(200, doc)
    )

  app.post "/pic", (req, res) ->
    # POST a jpeg image and get back a copy of the event that
    # announces your new pic.
    outBasename = (+new Date())+".jpg"

    out = fs.createWriteStream("pic/"+outBasename)
    req.pipe(out)
    req.on('end', () ->
        e.newEvent("pic", {"pic": "/pic/"+outBasename}, (err, ev) ->
          res.json(200, ev)
        )
    )

  app.get "/pic/:f", (req, res) ->
    respondFile(res, "./pic/", req.params.f)

  app.post "/print", (req, res) ->
    printSvgBody(req, "printername1", (err, jobName) ->
      if err?
        e.newEvent("printError", {error: err}, (err, ev) -> res.json(500, ev))
      else
        e.newEvent("print", {jobName: jobName}, (err, ev) -> res.json(200, ev))
    )

  app.get "/shared/:f", (req, res) ->
    respondFile(res, "./shared/", req.params.f)

  app.get /// /3rdparty/(.*) ///, (req, res) ->
    res.sendfile('./3rdparty/' + req.params[0], {maxAge: 100000000})

  # the next segment after /stations/game/ or /stations/gameop/ is
  # ignored by this server, but the browser can use it to
  # differentiate
  app.get(/// /(stations/game/[^/]+/)(.*) ///,
          (req, res) -> respondFile(res, "stations/game/", req.params[1]))
  app.get(/// /(stations/gameop/[^/]+/)(.*) ///,
          (req, res) -> respondFile(res, "stations/gameop/", req.params[1]))
  app.get(/// /(stations/[^/]+/)(.*) ///,
          (req, res) -> respondFile(res, req.params[0], req.params[1]))


# this one would be nice on port 80
server.listen(3200)
console.log("serving on port 3200")
