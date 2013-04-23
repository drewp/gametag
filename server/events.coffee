_ = require("../3rdparty/underscore-1.4.4-min.js")
mongo = require("mongodb")

exports.Events = (app, events, sockets) ->
  self = this
  @app = app
  @events = events
  @sockets = sockets

  eventUriFromId = (_id) ->
    '/events/' + _id # wrong abs uri

  @newEvent = (type, opts, cb) =>
    # callback gets the complete event, with type and t included
    ev = _.clone(opts)
    ev.type = type
    ev.t = new Date()
    self.events.insert(ev, {safe: true}, (err) ->
      throw err if err
      self.sockets.sendToAll(ev)
      cb(null, ev)
    )

  @getAllEvents = (cb) =>
    self.events.find().sort({t: 1}).toArray (err, results) ->
      throw err if err
      cb(results.map((ev) ->
        _.extend(ev, {uri: eventUriFromId(ev._id), cancelled: !!ev.cancelled})
      ))

  @addRequestHandlers = () ->
    events = @events
    newEvent = @newEvent

    self.app.delete "/events/:id", (req, res) ->
      events.update({_id: mongo.ObjectID(req.params.id)}, {$set: {cancelled: true}}, (err) ->
        newEvent("cancel",
                 {target: eventUriFromId(req.params.id), setTo: true}, 
                 (err) ->
                   res.send(204)
        )
      )

    self.app.post "/events", (req, res) ->
      newEvent(req.body.type, _.omit(req.body, "type"), (err, ev) ->
        res.send(204)
      )

    self.app.patch "/events/:id", (req, res) ->
      # so far this just supports replacing the 'cancelled' field
      events.update({_id: mongo.ObjectID(req.params.id)},
                    {$set: {cancelled: req.body.cancelled}}, (err) ->
                      newEvent("cancel",
                               {target: eventUriFromId(req.params.id), now: req.body.cancelled}, 
                               (err) ->
                                 res.send(204)
                      )
      )
  self