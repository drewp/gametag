
new Badge($("#badge"), ((badge) ->
  user = window.user  
  badge.setName(user.label)
  badge.setUrl(user.user)
  badge.setPicFromSrc(identifiers.localSite(user.pic))
))