express = require("express")
build = require("consolidate-build")
mongo = require("mongodb")
mime = require('connect').mime
app = express()
server = require("http").createServer(app)
Sockets = require("./sockets.js").Sockets

app.engine("jade", build.jade)
app.engine("styl", build.stylus)
app.engine("coffee", build.coffee)
app.set('views', __dirname + "/..")

app.use("/static", express.static(__dirname));
app.use(express.logger())

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
        cb(games, users)

openMongo (games, users) ->
  sockets = new Sockets(server, "/events")

  app.get "/", (req, res) ->
    games.find().toArray (err, results) ->
      throw err if err
      res.render("stations/proto/index.jade", {
        title: "Consolidate.js",
        games: results
      })

  app.get "/users", (req, res) ->
    users.find().toArray (err, results) ->
      res.json(200, {"users":results})

  app.post "/users", (req, res) ->
    users.insert({label: "u"+new Date()}, {safe: true}, (err, objs) ->
      sockets.sendToAll({"event":"userChange"})
      res.json(200, objs)
    )

  app.get "/shared/:f", (req, res) ->
    requested = req.params.f
    res.contentType(requested)
    res.render("./shared/" + requested
        .replace(".css", ".styl")
        .replace(".js", ".coffee")
    )

  app.get "/3rdparty/:f", (req, res) ->
    res.sendfile('./3rdparty/' + req.params.f, {maxAge: 100000000})

  app.get /\/stations\/([^\/]+)\/(.*)/, (req, res) ->
    sockets.sendToAll({"requested": req.params[0]})
    if !req.params[1]
      res.render("./stations/" + req.params[0] + "/index.jade", {})
    else
      res.contentType(req.params[1])
      res.render("./stations/" + req.params[0] + "/" +
                 req.params[1].replace('.js', '.coffee'), {})

# this one would be nice on port 80
server.listen(3200)
console.log("serving on port 3200")
