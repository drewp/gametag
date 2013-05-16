
class Model
  constructor: ->
    @users = ko.observableArray([])
    @printResult = ko.observable("")
   
  fillBadge: (user) =>
    badge.setName(user.label)
    badge.setPicFromSrc(identifiers.localSite(user.pic))
    badge.setUrl(user.user)

  print: =>
    @printResult("Printing...")
    badge.postSvg("../../print", (report) => @printResult(JSON.stringify(report)))

  
model = new Model()
badge = new Badge($("#badge"), (-> 0)) 

$.getJSON "../../users", (data) =>
  data.users.reverse()
  model.users(data.users)

new ReconnectingWebSocket((() ->), ((msg) ->))
ko.applyBindings(model)
