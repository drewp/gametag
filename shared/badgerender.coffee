class window.Badge
  # svg badge image which can replace its images and text

  constructor: (elem, onLoad) ->
    @waitingSvgDataUrl = null
    @elem = $(elem)
    loadsLeft = 2
    $.ajax
      url: "../../stations/enrollment/badge.svg"
      dataType: "text"
      success: (data) =>
        @elem.html(data)
        loadsLeft--
        onLoad(this) if loadsLeft == 0

    $.ajax
      url: "../../shared/waiting.svg"
      dataType: "text"
      success: (data) =>
        @waitingSvgDataUrl = "data:image/svg+xml;base64,"+btoa(data)
        loadsLeft--
        onLoad(this) if loadsLeft == 0

  _setXlinkHref: (id, value) ->
    # this prob needs to change to a class to support multiple badges in a page
    elem = document.getElementById(id)
    # at least sometimes, this leaves xlink:href alone and sets href,
    # and href wins. setAttributeNS worked worse.
    elem.setAttribute('xlink:href', value) if elem?

  setName: (name) ->
    @elem.find("#name1, #name2, #tspan3004").text(name)

  setPic: (imageData) =>
    # pass null for the waiting dots
    if imageData?
      @_setXlinkHref('face', imageData)
    else
      if @waitingSvgDataUrl?
        @_setXlinkHref('face', @waitingSvgDataUrl)

  setPicFromSrc: (url) =>
    # this uses XHR to get the image and make a data url, all so we
    # would be able to ship this SVG to be printed without any
    # external links. See http://stackoverflow.com/a/12665440/112864
    xhr = new XMLHttpRequest()
    xhr.open('GET', url, true);
    xhr.responseType = 'arraybuffer'

    badge = this
    xhr.onload = (e) ->
      if this.status == 200
        base64 = btoa(String.fromCharCode.apply(null, new Uint8Array(this.response)))
        badge._setXlinkHref('face', "data:image/jpg;base64,"+base64)

    xhr.send()

  setUrl: (url) =>
    # pass null for the waiting dots
    if url?
      @_makeQrImageUrl(url, (imageUrl) =>
        @_setXlinkHref('qr', imageUrl)
      )
    else
      if @waitingSvgDataUrl?
        @_setXlinkHref('qr', @waitingSvgDataUrl)

  getSvgData: () ->
    new XMLSerializer().serializeToString(
      @elem[0].firstElementChild)

  _makeQrImageUrl: (text, cb) ->
    i = document.createElement("div")
    q = new QRCode(i, {
      text: text,
      width: 256,
      height: 256
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

  postSvg: (url, cb) =>
    $.ajax(
      type: "POST"
      url: url
      contentType: "image/svg+xml"
      data: @getSvgData()
      success: cb
      error: cb
    )