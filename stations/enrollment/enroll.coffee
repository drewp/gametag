class Camera
  # camera view, including the ability to save pics to the server and
  # prepare them for use in the SVG

  constructor: (demoMode, picCopying) ->
    @picCopying = picCopying
    @canvas = document.querySelector('canvas')
    @ctx = @canvas.getContext('2d')
    @video = document.querySelector("video")

    if not demoMode
      if !navigator.getUserMedia
        navigator.getUserMedia = navigator.webkitGetUserMedia
      navigator.getUserMedia({
        video: true
      }, ((localMediaStream) =>
        @video.src = window.URL.createObjectURL(localMediaStream)
        @video.addEventListener("loadeddata", () =>
            @canvas.width = @video.videoWidth
            @canvas.height = @video.videoHeight
          , false)
      ), (e) =>
        console.log("cam failed", e)
        @video.src = "booth.webm"
        @video.loop = true
      )
      $(@video).css({width: 320, height: 240})
    else
      @video.src = "booth.webm"
      @video.loop = true

  grab: (onPicData, onPicUri) =>
    @video.pause()
    
    scanners = $(".scanner")
    scanners.css("top", 0).show()
    @picCopying(true)
    effectMs = 200
    for t in (x for x in [0..effectMs * 1.2] by 10)
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

        imageDataUrl = @canvas.toDataURL('image/jpeg')
        onPicData(imageDataUrl)

        onBlob = (blob) =>
          $.ajax(
            type: "POST"
            url: "../../pic"
            contentType: "image/jpeg"
            processData: false
            data: blob,
            success: (newPic) =>
              onPicUri(newPic.pic)
              @picCopying(false)
          )
        @canvas.toBlob(onBlob, "image/jpeg")
      , 10)
    , effectMs)

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
    @enteredName = ko.observable("")
    @ageCategory = ko.observable(null)
    @ageCategories = [
      {label: "elementary", accesskey: "l"}
      {label: "middle", accesskey: "m"}
      {label: "high", accesskey: "h"}
      ]

  setBadge: =>
    ko.computed =>
      badge.setUrl(@currentUserUri())

    ko.computed =>
      badge.setName(@enteredName())

  grab: =>
    camera.grab(badge.setPic, @currentPicUri)
    $("#enterName").focus()
    return false

  reset: =>
    @enteredName("")
    @currentUserUri(null)
    @ageCategory(null)
    badge.setName("")
    badge.setPic(null)
    @currentPicUri(null)
    $("#print").text("Print")

  print: ->
    $("#print").text("Printing...")

    badge.postSvg("../../print", ((report) => @reset()))

  makeUser: =>
    $.post(
      "../../users",
      {
        station: "enroll",
        label: @enteredName(),
        pic: @currentPicUri(),
        ageCategory: @ageCategory()
      },
      ((data) => @currentUserUri(data.user))
    )

  
model = new Model()
camera = new Camera(document.location.search == "?cam=demo", model.picCopying)  
badge = new Badge($("#badge"), (-> model.reset())) 
model.setBadge(badge)

new ReconnectingWebSocket((() ->), ((msg) ->))
ko.applyBindings(model)
