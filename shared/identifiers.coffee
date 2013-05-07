methods = {
  localSite: (uri) ->
    # a version of this URI that talks to the local server, for use in
    # ajax requests
    uri.replace(/// ^https://gametag.bigast.com ///, "")

  absolute: (url) ->
    if url[0] != "/"
      throw new Error("tried to absolute this url: "+url)
    "https://gametag.bigast.com" + url

  gameUri: (gameId) ->
    # the game PAGE has a trailing slash, but the game URI doesn't
    "https://gametag.bigast.com/games/" + gameId

  picUri: (picPath) ->
    if !picPath.match(/^pic\//)
      throw new Error("unexpected picPath "+picPath)

    "https://gametag.bigast.com/" + picPath

  newDocId: () ->
    @absolute("/events/" + require('mongodb').ObjectID().toHexString())

  newUserUri: (userCount) ->
    # user uris are trying to stay short for better QR codes
    "https://gametag.bigast.com/users/" + userCount
}

if exports?
  exports[k] = v for k, v of methods
else
  window.identifiers = methods

 