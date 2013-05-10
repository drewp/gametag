
class Model
  constructor: ->
    @users = ko.observableArray([])
   
  fillBadge: (user) =>
    badge.setName(user.label)
    badge.setPicFromSrc(user.pic)
    badge.setUrl(user.user)

  print: ->
    $("#print").text("Printing...")
    badge.postSvg("../../print", (report) -> 0)

  
model = new Model()
badge = new Badge($("#badge"), (-> 0)) 

$.getJSON "../../users", (data) =>
  data.users.reverse()
  model.users(data.users)

new ReconnectingWebSocket(socketRoot + "/events", (() ->), ((msg) ->))
ko.applyBindings(model)
