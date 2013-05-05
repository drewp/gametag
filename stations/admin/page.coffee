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

  eventQr: (ev) ->
    if ev.user
      uri = "https://gametag.bigast.com" + ev.user
      "https://chart.googleapis.com/chart?chs=250x250&cht=qr&"+$.param({chl: uri})
    else
      null

  iconClass: (ev) ->
    {
        # see http://fortawesome.github.io/Font-Awesome/design.html
        enroll: 'icon-user'
        scan: 'icon-qrcode'
        cancel: 'icon-ban-circle'
        pic: 'icon-camera'
        achievement: 'icon-money'
        printError: 'icon-stethoscope'
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
  # append all events to the model
  $.getJSON "../../events/all", {}, (data) ->
    data.events.forEach((ev) -> model.events.push(ev))

new ReconnectingWebSocket(
  socketRoot + "/events",
  (() -> model.events.removeAll(); readEvents()),
  ((msg) ->
    console.log("new ev", msg)
    # prepend a new event to the model.
    # Note that after reconnect, readEvents may be slow to add its
    # events, and it may include some dups that we also added
    # here. 
    model.events.unshift(msg)
  )
)
        
ko.applyBindings(model)