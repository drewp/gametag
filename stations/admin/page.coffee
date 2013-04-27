model =
  events: ko.observableArray([])

  deleteUser: (user) =>
    $.ajax(
      url: user.uri
      type: "DELETE"
      success: () ->
        console.log("del")
    )

  prettyTime: (ev) ->
    window.t = ev.t
    new Date(ev.t).toLocaleTimeString()

  eventSpecific: (ev) ->
    _.omit(ev, ['_id', 'type', 't', 'uri', 'cancelled', 'isNewDay'])

  iconClass: (ev) ->
    {
        # see http://fortawesome.github.io/Font-Awesome/design.html
        enroll: 'icon-user'
        scan: 'icon-play-circle'
        cancel: 'icon-ban-circle'
        pic: 'icon-camera'
    }[ev.type]

  eventRowClasses: (ev) ->
    ret = {cancelled: ev.cancelled, isNewDay: ev.isNewDay}
    ret[ev.type] = true
    ret

  toggleCancelEvent: (ev) ->
    if !ev.cancelled # note: works off our copy, not the real event state
      $.ajax(
        url: ev.uri
        type: "DELETE"
      )
    else
      $.ajax(
        url: ev.uri
        type: "PATCH"
        data: JSON.stringify({cancelled: false}),
        contentType: 'application/json',
      )

readEvents = ->
  $.getJSON "../../events/all", {}, (data) ->
    model.events(data.events)
readEvents()

new reconnectingWebSocket(socketRoot + "/events", (msg) ->
  console.log("msg", msg)
  # this wants to be incremental and insert the new event on the top
  readEvents()
)
        
ko.applyBindings(model)