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
  $("#face")[0].src = canvas.toDataURL('image/webp')
      
)
$("video").click(-> $("#grab").click())

$("#assemble").click(() ->
  n = ["Endburo", "Tasgar", "Serit", "Tonumo", "Achath", "Itutan", "Endline", "Unda", "Vesaunt", "Rodundem"][Math.floor(Math.random() * 10)]
  $("#nametag").text(n + " #" + Math.floor(Math.random() * 99999));
  $("#qr").attr('src', 'qr-demo.png')
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