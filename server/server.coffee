express = require("express")
build = require("consolidate-build")
mongo = require("mongodb")
mime = require('connect').mime
app = express()
server = require("http").createServer(app)
Sockets = require("./sockets.js").Sockets
_ = require("../3rdparty/underscore-1.4.4-min.js")
Events = require("./events.js").Events


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
      client.collection 'users', (err, users) ->
        throw err if err
        client.collection 'events', (err, events) ->
          throw err if err
          cb(games, users, events)

precompiledName = (requestedName) ->
  requestedName
    .replace(".css", ".styl")
    .replace(".js", ".coffee")
    .replace(".html", ".jade")

respondFile = (res, prefix, requestedPath) ->
    if requestedPath == ""
      requestedPath = "index.html"
    res.contentType(requestedPath)
    if requestedPath.match(/\.(jpg|png|webm|svg)$/)
      # probably res.render could be made to handle this
      res.sendfile(prefix + precompiledName(requestedPath))
    else
      res.render(prefix + precompiledName(requestedPath))

openMongo (games, users, events) ->
  sockets = new Sockets(server, "/events")

  e = new Events(app, events, sockets)

  e.addRequestHandlers()

  app.get "/events/all", (req, res) ->
    e.getAllEvents((events) -> res.json(200, {events: events}))

  nextUserId = (cb) ->
    # this doesn't care about whether events were cancelled
    events.find({type: "enroll"}).count(cb)

  app.get "/", (req, res) ->
    games.find().toArray (err, results) ->
      throw err if err
      res.render("stations/proto/index.jade", {
        title: "Consolidate.js",
        games: results
      })
  app.get "/page.js", (req, res) -> respondFile(res, 'stations/proto/', 'page.js')

  app.get "/users", (req, res) ->
    #todo
    users.find().toArray (err, results) ->
      res.json(200, {"users":results})

  app.post "/users", (req, res) ->
    nextUserId((err, newId) ->
      e.newEvent("enroll",
               {pic: "pic1", user: "/users/" + newId, label: "u"+newId},
               (err, ev) ->
                 throw err if err
                 sockets.sendToAll({"event":"enroll"})
                 res.json(200, ev)
      )
    )

  # GET /users/:id is what guests will revisit from their own badges later
  
  app.post "/scans", (req, res) ->
    users.update({uri: req.body.qr},
                 {$push: {"scans": {game: req.body.game, t: new Date()}}},
                 {safe: true},
                 (err, doc) ->
                   throw err if err
                   sockets.sendToAll({event: "userScan", game: req.body.game})
                   res.json(200, doc)
    )

  app.get "/shared/:f", (req, res) ->
    requested = req.params.f
    respondFile(res, "./shared/", requested)

  app.get /// /3rdparty/(.*) ///, (req, res) ->
    res.sendfile('./3rdparty/' + req.params[0], {maxAge: 100000000})

  # the next segment after /stations/game/ is ignored by this
  # server, but the browser can use it to differentiate
  app.get(/// /(stations/game/[^/]+/)(.*) ///,
          (req, res) -> respondFile(res, "stations/game/", req.params[1]))
  app.get(/// /(stations/[^/]+/)(.*) ///,
          (req, res) -> respondFile(res, req.params[0], req.params[1]))


# this one would be nice on port 80
server.listen(3200)
console.log("serving on port 3200")
