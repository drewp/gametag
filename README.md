Contained here
--------------

A system for making badges with faces and QR codes on them, and then
various stations that scan badges to award points to users or to
display/withdraw those points.



Other name ideas
----------------
*  gametag
*  qrnival
*  partybadge
*  badger

Schema 2
--------

events (all have time t, source station uri, and cancelled=false):

  {type: savePic, uri: pic}
  {type: enroll, pic: uri, user: uri, label: l}
  {type: scan, user: uri}
  {type: gameOutcome, user: uri, ...} # optional

games

  {id: shortname, background: pic, pointsPerScan: n}

