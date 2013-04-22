_ = require("../3rdparty/underscore-1.4.4-min.js")
mongo = require("mongodb")

exports.Events = class Events
  constructor: (app, events, sockets) ->
    @app = app
    @events = events
    @sockets = sockets

  newEvent: (type, opts, cb) =>
    # callback gets the complete event, with type and t included
    ev = _.clone(opts)
    ev.type = type
    ev.t = new Date()
    @events.insert(ev, {safe: true}, (err) ->
      throw err if err
      @sockets.sendToAll(ev)
      cb(null, ev)
    )

  addRequestHandlers: () ->
    events = @events
    newEvent = @newEvent
    @app.get "/events/all", (req, res) ->
      events.find().sort({t:1}).toArray (err, results) ->
        res.json(200, {"events": results.map((ev) ->
          _.extend(ev, {uri: '/events/' + ev._id, cancelled: !!ev.cancelled})
        )})

    @app.delete "/events/:id", (req, res) ->
      events.update({_id: mongo.ObjectID(req.params.id)}, {$set: {cancelled: true}}, (err) ->
        newEvent("cancel",
                 {target: '/events/'+req.params.id, now: true}, 
                 (err) ->
                   res.send(204)
        )
      )

    @app.patch "/events/:id", (req, res) ->
      # so far this just supports replacing the 'cancelled' field
      events.update({_id: mongo.ObjectID(req.params.id)},
                    {$set: {cancelled: req.body.cancelled}}, (err) ->
                      newEvent("cancel",
                               {target: '/events/'+req.params.id, now: req.body.cancelled}, 
                               (err) ->
                                 res.send(204)
                      )
      )
