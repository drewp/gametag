class Model
  constructor: ->
    @qrCodes = ko.observableArray([])
    @stations = ko.observableArray([])
    $.getJSON "../../users", (data) =>
      data.users.forEach((u) =>
        @qrCodes.push({uri: u.user, desc: identifiers.localSite(u.user) + " " + u.label})
      )
      $(".qrUrl").draggable({opacity: .7, helper: 'clone'})

    $.getJSON "../../games", (data) =>
      @stations.push({uri: "https://gametag.bigast.com/stations/prize", desc: "/stations/prize"})
      for _, g of data.games
        @stations.push({uri: g.uri, desc: identifiers.localSite(g.uri)})
      $(".station").droppable({
        accept: ".qrUrl"
        hoverClass: "hover"
        activeClass: "active"
        drop: (ev, ui) ->
          qr = ui.draggable.context.href
          station = $(this).attr("href")
          $.post("../../events", {type: "scan", user: qr, game: station}, (ev)->)
      })
        
  noClicks: =>
    $("h2").css({fontSize: "120%"})

model = new Model()


ko.applyBindings(model)