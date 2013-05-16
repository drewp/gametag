if window.location.origin == "https://gametag.bigast.com"
  window.socketRoot = "wss://gametag.bigast.com"
else
  window.socketRoot = "wss://"+window.location.host
  
