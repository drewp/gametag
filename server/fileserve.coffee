
precompiledName = (requestedName) ->
  requestedName
    .replace(".css", ".styl")
    .replace(".js", ".coffee")
    .replace(".html", ".jade")

exports.respondFile = (res, prefix, requestedPath) ->
    if requestedPath == ""
      requestedPath = "index.html"
    res.contentType(requestedPath)
    if requestedPath.match(/\.(jpg|png|webm|svg|gif)$/)
      # probably res.render could be made to handle this
      res.sendfile(prefix + precompiledName(requestedPath))
    else
      res.render(prefix + precompiledName(requestedPath))
