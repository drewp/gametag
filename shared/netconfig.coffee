if window.location.origin == "https://gametag.bigast.com"
  window.socketRoot = "wss://gametag.bigast.com"
else
  window.socketRoot = {'https:':'wss:', 'http:':'ws:'}[window.location.protocol] + '//' + window.location.host
  
