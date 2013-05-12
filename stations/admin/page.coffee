model =
  events: ko.observableArray([])
  rowFilter: ko.observable("")

  deleteUser: (user) =>
    $.ajax(
      url: identifiers.localSite(user.uri)
      type: "DELETE"
      success: () ->
        console.log("del")
    )

  rowVisible: (ev) ->
    return true if @rowFilter() == ""
    filters = @rowFilter().toLowerCase().split(/\s+/)
    _.every(filters, (filt) => (@prettyTime(ev) + " " + JSON.stringify(ev).toLowerCase()).indexOf(filt) != -1)

  prettyTime: (ev) ->
    window.t = ev.t
    new Date(ev.t).toLocaleTimeString()

  eventSpecificHtml: (ev) ->
    data = _.omit(ev, ['_id', 'type', 't', 'uri', 'cancelled', 'isNewDay'])
    json = JSON.stringify(data)
    html = json.replace(/&/g, '&amp;').replace(/\"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

    html.replace(/// https://gametag.bigast.com(/[a-zA-Z0-9_\./]*) ///g, (match, path) ->
      '<a href="'+match+'">'+path+'</a>'
    )

  eventQr: (ev) ->
    if ev.user
      "https://chart.googleapis.com/chart?chs=250x250&cht=qr&"+$.param({chl: ev.user})
    else
      null

  iconClass: (ev) ->
    {
        # see http://fortawesome.github.io/Font-Awesome/design.html
        enroll: 'icon-user'
        scan: 'icon-qrcode'
        cancel: 'icon-ban-circle'
        pic: 'icon-camera'
        achievement: 'icon-trophy'
        printError: 'icon-stethoscope'
        print: 'icon-print'
        buy: 'icon-money'
    }[ev.type]

  eventRowClasses: (ev) ->
    ret = {cancelled: ev.cancelled, isNewDay: ev.isNewDay}
    ret[ev.type] = true
    ret

  toggleCancelEvent: (ev) ->
    if !ev.cancelled # note: works off our copy, not the real event state
      $.ajax(
        url: identifiers.localSite(ev.uri)
        type: "DELETE"
      )
    else
      $.ajax(
        url: identifiers.localSite(ev.uri)
        type: "PATCH"
        data: JSON.stringify({cancelled: false}),
        contentType: 'application/json',
      )

readEvents = ->
  # append all events to the model
  $.getJSON "../../events/all", {}, (data) ->
    model.events.removeAll()
    data.events.forEach((ev) -> model.events.push(ev))

ko.computed ->
  model.events()
  $("img").lazyload({threshold: 200})
  
new ReconnectingWebSocket(
  socketRoot + "/events",
  (() -> readEvents()),
  ((ev) ->
    # prepend a new event to the model.
    # Note that after reconnect, readEvents may be slow to add its
    # events, and it may include some dups that we also added
    # here.
    if ev.type == 'cancel'
      readEvents()
    else
      model.events.unshift(ev)
  )
)
        
ko.applyBindings(model)
