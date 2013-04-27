class Camera
  constructor: (picCopying) ->
    @picCopying = picCopying
    @canvas = document.querySelector('canvas')
    @ctx = @canvas.getContext('2d')
    @video = document.querySelector("video")

    if document.location.search != "?cam=demo"
      if !navigator.getUserMedia
        navigator.getUserMedia = navigator.webkitGetUserMedia
      navigator.getUserMedia({
        video: true
      }, ((localMediaStream) ->
        @video.src = window.URL.createObjectURL(localMediaStream)
      ), (e) ->
        console.log("cam failed", e)
      )
      $("video").css({width: 320, height: 240})
    else
      @video.src = "booth.webm"
      @video.loop = true

  grab: (onPicData, onPicUri) =>
    @video.pause()
    
    scanners = $(".scanner")
    scanners.css("top", 0).show()
    @picCopying(true)
    effectMs = 200
    for t in (x for x in [0..effectMs * 1.2] by 20)
      setTimeout(((t2) -> (() =>
        scanners.css("top", (t2 / effectMs * 100) + "%")
      ))(t), t)
    setTimeout(() =>
      scanners.hide()
      # this scheduling is to avoid the scanner line stuttering during
      # the video.play call
      setTimeout(() => 
        @ctx.drawImage(@video, 0, 0)
        @video.play()
        image = @canvas.toDataURL('image/jpeg')
        onPicData(image)
        $.ajax(
          type: "POST"
          url: "../../pic"
          contentType: "image/jpeg"
          data: atob(image.replace(/^[^,]*,/, ""))
          success: (newPic) =>
            onPicUri(newPic.pic)
            @picCopying(false)
        )
      , 10)
    , effectMs)

class Badge
  # svg badge image which can replace its images and text

  constructor: (onLoad) ->
    @waitingSvgDataUrl = null
    loadsLeft = 2
    $.ajax
      url: "badge.svg"
      dataType: "text"
      success: (data) =>
        $("#badge").html(data)
        loadsLeft--
        onLoad() if loadsLeft == 0

    $.ajax
      url: "../../shared/waiting.svg"
      dataType: "text"
      success: (data) =>
        @waitingSvgDataUrl = "data:image/svg+xml;base64,"+btoa(data)
        loadsLeft--
        onLoad() if loadsLeft == 0

  _setXlinkHref: (id, value) ->
    elem = document.getElementById(id)
    elem.setAttribute('xlink:href', value) if elem?

  setName: (name) ->
    $("#name1, #name2").text(name)

  setPic: (imageData) =>
    # pass null for the waiting dots
    console.log("Setpic", imageData?)
    if imageData?
      @_setXlinkHref('face', imageData)
    else
      if @waitingSvgDataUrl?
        @_setXlinkHref('face', @waitingSvgDataUrl)

  setUrl: (url) =>
    # pass null for the waiting dots
    console.log("set to", url)
    if url?
      @_makeQrImageUrl(url, (imageUrl) =>
        console.log("qr finished", imageUrl)
        @_setXlinkHref('qr', imageUrl)
      )
    else
      if @waitingSvgDataUrl?
        @_setXlinkHref('qr', @waitingSvgDataUrl)

  getSvgData: () ->
    new XMLSerializer().serializeToString(
      $("#badge")[0].firstElementChild)

  _makeQrImageUrl: (text, cb) ->
    i = document.createElement("div")
    q = new QRCode(i, {
      text: text,
      width: 128,
      height: 128
    })
    q.makeImage()

    # calling getAttribute right away, or even with one setTimeout,
    # was getting me null (chrome 26.0.1410.43), but this way works:
    fin = ->
      imageData = i.children[1].getAttribute("src")
      if not imageData?
        setTimeout(fin, 50)
        return
      cb(imageData)
    setTimeout(fin, 50)





class Model
  constructor: ->
    @decoded = ko.observable(false)
    @currentPicUri = ko.observable()
    @currentUserUri = ko.observable()
    @picCopying = ko.observable(false)
    @grabEnabled = ko.computed(=> !@picCopying() && !@currentUserUri())
    @resetEnabled = ko.computed(=> @currentPicUri() || @currentUserUri())
    @makeUserEnabled = ko.computed(=> !@currentUserUri())
    @printEnabled = ko.computed(=> @currentUserUri())

  setBadge: =>
    ko.computed(=>
      badge.setUrl(@currentUserUri())
    )   

  grab: =>
    camera.grab(badge.setPic, @currentPicUri)

  reset: =>
    $("#nametag").text("")
    @currentUserUri(null)
    badge.setPic(null)
    @currentPicUri(null)
    $("#print").text("Print")

  print: ->
    $("#print").text("Printing...")

    $.ajax(
      type: "POST"
      url: "../../print"
      contentType: "image/svg+xml"
      data: badge.getSvgData()
      success: (report) ->
        @reset
    )

  makeUser: =>
    n = ["Endburo", "Tasgar", "Serit", "Tonumo", "Achath", "Itutan", "Endline", "Unda", "Vesaunt", "Rodundem"][Math.floor(Math.random() * 10)]
    badge.setName(n + " #" + Math.floor(Math.random() * 99999))

    $.post("../../users", {station: "enroll", pic: @currentPicUri()}, (data) =>
      console.log("scans", data)
      @currentUserUri("https://gametag.bigast.com"+data.user)
    )

  
model = new Model()

camera = new Camera(model.picCopying)
    
badge = new Badge(-> model.reset()) 
model.setBadge(badge)

new reconnectingWebSocket(socketRoot + "/events", (msg) ->

)
ko.applyBindings(model)
