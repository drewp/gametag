video = document.querySelector("video")

canvas = document.querySelector('canvas')
ctx = canvas.getContext('2d')

if document.location.search != "?cam=demo"
  if !navigator.getUserMedia
    navigator.getUserMedia = navigator.webkitGetUserMedia
  navigator.getUserMedia({
    video: true
  }, ((localMediaStream) ->
    video.src = window.URL.createObjectURL(localMediaStream)
  ), (e) ->
    console.log("cam failed", e)
  )
  $("video").css({width: 320, height: 240})
else
  video.src = "booth.webm"
  video.loop = true

$("#grab").click(() ->
  ctx.drawImage(video, 0, 0)
  $("#face").attr("xlink:href", canvas.toDataURL('image/jpg'))
      
)
$("video").click(-> $("#grab").click())

$.ajax
  url: "badge.svg",
  dataType: "text",
  success: (data) ->
    $("#badge").html(data)

$("#assemble").click(() ->
      n = ["Endburo", "Tasgar", "Serit", "Tonumo", "Achath", "Itutan", "Endline", "Unda", "Vesaunt", "Rodundem"][Math.floor(Math.random() * 10)]
      $("#name1, #name2").text(n + " #" + Math.floor(Math.random() * 99999));

      i = document.createElement("div")
      q = new QRCode(i, {
        text: "http://what",
        width: 128,
        height: 128
      })
      q.makeImage()
      
      $("body").append(i)
      $("#qr").attr('xlink:href', i.children[1].getAttribute("src"))

      svgOut = new XMLSerializer().serializeToString($("#badge")[0])
)

$("#print").click(() ->
  origText = $("#print").text()
  $("#print").text("Printing...")
  setTimeout(() ->
    $("#nametag").text("")
    $("#qr").attr('src', '#')
    $("#face").attr('src', '#')
    $("#print").text(origText)
  , 1000)
)

class Model
  constructor: ->
    @decoded = ko.observable(false)
  makeDemoUser: =>
    $.post("../../users", {station: "enroll", pic: "pic1"}, (data) ->
      console.log("scans", data)
    )

model = new Model()

new reconnectingWebSocket(socketRoot + "/events", (msg) ->

)
ko.applyBindings(model)
