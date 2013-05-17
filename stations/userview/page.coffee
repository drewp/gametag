
new Badge($("#badge"), ((badge) ->
  user = window.user  
  badge.setName(user.label) if user.label?
  badge.setUrl(user.user) if user.user?
  badge.setPicFromSrc(identifiers.localSite(user.pic)) if user.pic?
))