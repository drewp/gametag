fs = require('fs')
express = require("express")
build = require("consolidate-build")
mongo = require("mongodb")
mime = require('connect').mime
app = express()
server = require("http").createServer(app)
Sockets = require("./sockets.js").Sockets
_ = require("../3rdparty/underscore-1.4.4-min.js")
Events = require("./events.js").Events
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
      for g in results
        g.uri = "/stations/game/"+g._id+"/"
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
               {pic: req.body.pic, user: "/users/" + newId, label: req.body.label},
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
    d = require('domain').create()
    d.on('error', (err) ->
          e.newEvent("printError",
            {error: err},
            (err, ev) -> res.json(500, ev)))
    d.run =>
      base = "pdf/" + (+new Date())
      out = fs.createWriteStream(base + ".svg")
      req.pipe(out)

      req.on('end', () ->
          exec("inkscape "+
               "--export-pdf="+base+".pdf "+
               "--export-dpi=300 "+base+".svg",
               (err, stdout, stderr) ->
                 if err?
                   [err.stdout, err.stderr] = [stdout, stderr]
                   throw err

                 exec("lpr "+base+".pdf", (err, stdout, stderr) ->
                   if err?
                     [err.stdout, err.stderr] = [stdout, stderr]
                     throw err

                   e.newEvent("print", {}, (err, ev) -> res.json(200, ev))
                 )
          )
      )


  app.get "/shared/:f", (req, res) ->
    respondFile(res, "./shared/", req.params.f)

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
