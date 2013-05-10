domainCreate = require('domain').create
fs = require('fs')
exec = require('child_process').exec
_ = require("../3rdparty/underscore-1.4.4-min.js")

lpr = (filename, destinationPrinter, jobName, cb) ->
  cmdline = "lp " +
       filename +
       " -d " + destinationPrinter +
       " -t " + jobName
  console.log("run: "+cmdline)
  exec(cmdline,
       (err, stdout, stderr) ->
         if err?
           return cb(_.extend(err, {stdout: stdout, stderr: stderr, jobName: jobName}))

         cb(null, jobName)
  )

exports.printSvgBody = (inputStream, destinationPrinter, cb) ->
  domain = domainCreate()
  domain.on('error', (err) ->
    console.log("domain error: " + err)
    cb(err, null)
  )

  console.log("run in domain")
  domain.run =>
    base = "pdf/" + (+new Date())
    out = fs.createWriteStream(base + ".svg")
    console.log("pipe to svg file")
    inputStream.pipe(out)

    cmdline = ("inkscape " +
               "--export-pdf=" + base + ".pdf "+
               "--export-dpi=300 " + base + ".svg")
    onExec = ((err, stdout, stderr) ->
      console.log("inkscape done: ", err)
      if err?
        return cb(_.extend(err, {stdout: stdout, stderr: stderr, jobName: base}))

      # also see https://npmjs.org/package/lp-client
      jobName = base
      lpr(base + ".pdf", destinationPrinter, jobName, cb)
    )
    inputStream.on('end', () ->
      console.log("run inkscape to make pdf")
      exec(cmdline, onExec)
    )

