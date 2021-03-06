fs = require('fs')
path = require('path')
async = require("../3rdparty/async-0.2.7.js")
_ = require("../3rdparty/underscore-1.4.4-min.js")
mongo = require("mongodb")
identifiers = require("../shared/identifiers.js")

exports.Events = (app, events, sockets) ->
  # operations on the events collection, including sending new events
  # to all websocket listeners
  self = this
  @app = app
  @events = events
  @sockets = sockets

  @newEvent = (type, opts, cb) =>
    # callback gets the complete event, with type and t included
    ev = _.clone(opts)
    ev.type = type
    ev.t = new Date()
    ev._id = identifiers.newDocId()
    self.events.insert(ev, {safe: true}, (err) ->
      throw err if err
      augmented = _.extend({}, ev, {
        uri: ev._id,
        cancelled: !!ev.cancelled,
        isNewDay: false, # don't care about incremental display of the date line
      })
      self.sockets.sendToAll(augmented)
      cb(null, ev)
    )

  @getAllEvents = (cb) =>
    self.events.find().sort({t: -1}).toArray (err, results) ->
      throw err if err
      prevDay = null
      cb(results.map((ev) ->
        thisDay = ev.t.toDateString()
        augmented = _.extend(ev, {
          uri: ev._id,
          cancelled: !!ev.cancelled,
          isNewDay: prevDay? && thisDay != prevDay,
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
        picUri = identifiers.picUri(picPath)
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
      # todo: this blows up if there are no pics yet
      async.map(files, eventFromFile, replaceEvents)
    )

  @postEvent = (body, cb) =>
    @newEvent(body.type, _.omit(body, "type"), (err, ev) ->
      throw err if err?
      cb(ev)
    )

  @cancelEvent = (eventUri, cb) =>
    @events.update({_id: eventUri}, {$set: {cancelled: true}}, (err) =>
      @newEvent("cancel", {target: eventUri, setTo: true}, cb)
    )

  @patchEvent = (eventUri, body, cb) =>
    # so far this just supports replacing the 'cancelled' field
    spec = {_id: eventUri}
    action = {$set: {cancelled: body.cancelled}}
    done = (err) =>
      @newEvent("cancel",
                {target: eventUri, now: body.cancelled},
                cb)
    @events.update(spec, action, done)
    
  self