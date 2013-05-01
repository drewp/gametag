fs = require('fs')
path = require('path')
async = require("../3rdparty/async-0.2.7.js")
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
    self.events.find().sort({t: -1}).toArray (err, results) ->
      throw err if err
      prevDay = null
      cb(results.map((ev) ->
        thisDay = ev.t.toDateString()
        augmented = _.extend(ev, {
                uri: eventUriFromId(ev._id),
                cancelled: !!ev.cancelled,
                isNewDay: thisDay != prevDay,
                })
        prevDay = thisDay
        augmented
      ))

  @syncPicEvents = (done) =>
    ###
       the pic/ dir is the authority; mongo events with type:"pic" are a
       mirror of the names and timestamps of the files. type:"pic" event
       _id fields are not considered stable.
    ###
    fs.readdir("pic/", (err, files) =>
      throw err if err?

      eventFromFile = (f, cb) =>
        picPath = path.join("pic/", f)
        picUri = "/" + picPath
        fs.stat(picPath, (err, stats) ->
          cb(err, {type: "pic", t: stats.mtime, pic: picUri}))
          
      replaceEvents = (err, newPicEvents) =>
        @events.remove({type: "pic"}, {safe: true}, (err) =>
          throw err if err?
          @events.insert(newPicEvents, {safe: true}, (err) =>
            throw err if err?
            console.log("updated pic events, error: "+err)
            self.sockets.sendToAll({'type':'reload'})
            done() if done?
          )
        )
        
      async.map(files, eventFromFile, replaceEvents)
    )

  @addRequestHandlers = () ->
    events = @events
    newEvent = @newEvent

    # the registration lines should be moved to server.coffee
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