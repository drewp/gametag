fs = require('fs')
express = require("express")
build = require("consolidate-build")
exec = require('child_process').exec
mongo = require("mongodb")
mime = require('connect').mime
app = express()
server = require("http").createServer(app)
decToGeneric = require("base-converter").decToGeneric
_            = require("../3rdparty/underscore-1.4.4-min.js")
async        = require("../3rdparty/async-0.2.7.js")
identifiers  = require("../shared/identifiers.js")
points       = require("../shared/points.js")
Sockets      = require("./sockets.js").Sockets
Events       = require("./events.js").Events
printSvgBody = require("./print.js").printSvgBody
usersMod     = require("./users.js")
[getAllUsers, findOneUser] = [usersMod.getAllUsers, usersMod.findOneUser]
respondFile  = require("./fileserve.js").respondFile
userView     = require("./userview.js").userView
mustBeAdmin  = require("./access.js").mustBeAdmin

app.engine("jade", build.jade)
app.engine("styl", build.stylus)
app.engine("coffee", build.coffee)

app.set('views', __dirname + "/..")

app.use("/static", express.static(__dirname));
app.use(express.logger())
app.use(express.bodyParser())

randomId = (nChars) ->
    alpha = "0123456789abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"
    max = Math.pow(alpha.length, nChars)
    x = Math.floor(Math.random() * max)
    decToGeneric(x, alpha)

openMongo = (cb) ->
  client = new mongo.Db('gametag',
                        new mongo.Server(process.env.GAMETAG_MONGODB || 'localhost', 27017),
                        {w: 1, journal: true, fsync: true})
  client.open (err, _) ->
    throw err if err
    client.collection 'games', (err, games) ->
      throw err if err
      games.find({}).toArray (err, allGames) ->
        gameByUri = {}
        for g in allGames
          uri = identifiers.gameUri(g._id)
          g.uri = uri
          gameByUri[uri] = g

        client.collection 'events', (err, events) ->
          throw err if err
          cb(games, gameByUri, events)

openMongo (games, gameByUri, events) ->
  sockets = new Sockets(server, "/events")

  e = new Events(app, events, sockets)
  e.syncPicEvents()

  app.delete "/events/:id", (req, res) ->
    mustBeAdmin(req, res)
    e.cancelEvent(identifiers.absolute(req.url), (err) ->
      return res.send(500) if err?
      res.send(204)
    )
    
  app.patch "/events/:id", (req, res) ->
    mustBeAdmin(req, res)
    e.patchEvent(identifiers.absolute(req.url), req.body, (err) ->
      return res.send(500) if err?
      res.send(204)
    )

  app.get "/events/all", (req, res) ->
    mustBeAdmin(req, res)
    # newest first
    e.getAllEvents((events) -> res.json(200, {events: events}))
    
  app.post "/events", (req, res) ->
    mustBeAdmin(req, res)
    body = req.body
    e.postEvent(body, (ev) -> res.json(200, ev))

  app.get "/", (req, res) ->
    results = _.sortBy(_.values(gameByUri), (g) -> g.label)
    for g in results
      g.uri = "/stations/game/"+g._id+"/"
      g.gameOp = "/stations/gameop/"+g._id+"/"
    res.render("stations/proto/index.jade", {
      title: "gametag proto page",
      games: results
    })
  app.get "/page.js", (req, res) -> respondFile(res, 'stations/proto/', 'page.js')

  app.get "/users", (req, res) ->
    mustBeAdmin(req, res)
    getAllUsers(events, gameByUri, (err, users) ->
      throw err if err?
      res.json(200, {users: users})
    )
    
  app.get "/userview.js", (req, res) -> respondFile(res, 'stations/userview/', 'page.js')

  userJson = (uri, res) ->
        findOneUser(events, gameByUri, uri, (err, userDoc) ->
          return res.send(500) if err?
          return res.send(404) if not userDoc?
          res.json(200, userDoc)
        )

  app.get "/users/:u.json", (req, res) ->
    uri = identifiers.absolute(req.url.replace(/\.json$/, ""))
    res.set("Content-Location", uri+".json")
    userJson(uri, res)
    
  app.get "/users/:u.html", (req, res) ->
    uri = identifiers.absolute(req.url.replace(/\.html$/, ""))
    res.set("Content-Location", uri+".json")
    userView(events, gameByUri, uri, res)

  app.get "/users/:u", (req, res) ->
    uri = identifiers.absolute(req.url)
    res.format({
      json: ->
        res.set("Content-Location", uri+".json")
        userJson(uri, res)
      html: ->
        res.set("Content-Location", uri+".json")
        userView(events, gameByUri, uri, res)
    })

  app.get "/games", (req, res) ->
    mustBeAdmin(req, res)
    res.json(200, {games: gameByUri})

  app.get "/games/qr", (req, res) ->
    mustBeAdmin(req, res)
    res.render("stations/proto/gamesqr.jade",
               {games: _.extend(
                {"prize":{uri: "https://gametag.bigast.com/stations/prize"}},
                gameByUri)})
    
  app.get "/games/:g", (req, res) ->
    mustBeAdmin(req, res)
    r = identifiers.absolute(req.url)
    res.json(200, gameByUri[r])

  nextUserId = (cb) ->
    # this doesn't care about whether events were cancelled
    events.find({type: "enroll"}).count(cb)

  app.post "/users", (req, res) ->
    mustBeAdmin(req, res)
    newId = randomId(6)
    e.newEvent("enroll",
             {
               pic: req.body.pic
               user: identifiers.newUserUri(newId)
               label: req.body.label
               ageCategory: req.body.ageCategory
              }, (err, ev) ->
               throw err if err
               sockets.sendToAll({"event":"enroll"})
               res.json(200, ev)
    )


  # GET /users/:id is what guests will revisit from their own badges later

  app.post "/picRescan", (req, res) ->
    mustBeAdmin(req, res)
    e.syncPicEvents(() -> res.json(200, {}))
  
  app.post "/scans", (req, res) ->
    mustBeAdmin(req, res)
    e.newEvent("scan", {user: req.body.qr, game: req.body.game}, (err, doc) ->
      throw err if err
      res.json(200, doc)
    )

  app.post "/pic", (req, res) ->
    # POST a jpeg image and get back a copy of the event that
    # announces your new pic.
    mustBeAdmin(req, res)
    writeFilename = "pic/" + randomId(12) + ".jpg"
    out = fs.createWriteStream(writeFilename)
    req.pipe(out)
    req.on('end', () ->
        e.newEvent("pic", {"pic": identifiers.picUri(writeFilename)},
          (err, ev) ->
            res.json(200, ev)
        )
    )

  app.get "/pic/:f", (req, res) ->
    respondFile(res, "./pic/", req.params.f)

  app.post "/print", (req, res) ->
    mustBeAdmin(req, res)
    printSvgBody(req, "photopaper", (err, jobName) ->
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
