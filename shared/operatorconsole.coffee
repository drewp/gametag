window.operatorconsole =
  bye: (game) ->
  # clearUser is not used; it's just to make the event more readable
    $.post("../../../events", {type: "scan", game: game, clearUser: true}, (ev) ->)

  postButton: (uiEvent, url, jsData) ->
    uiEvent.currentTarget.disabled = true
    $.ajax({
      url: url,
      type: "POST",
      data: JSON.stringify(jsData),
      contentType: "application/json",
      success: (ev) ->
        uiEvent.currentTarget.disabled = false
    })