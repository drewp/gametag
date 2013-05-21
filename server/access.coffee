# no admin check yet, so this just makes a limited 'public-only mode'

exports.mustBeAdmin = (req, res) ->
  res.send(403)

exports.isAdmin = (req) ->
  return false