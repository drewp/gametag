domainCreate = require('domain').create
fs = require('fs')
exec = require('child_process').exec

lpr = (filename, destinationPrinter, jobName) ->
  exec("lpr " +
       filename +
       " -P " + destinationPrinter +
       " -T " + jobName,
       (err, stdout, stderr) ->
         if err?
           [err.stdout, err.stderr] = [stdout, stderr]
           throw err

         cb(null, jobName)
  )

exports.printSvgBody = (inputStream, destinationPrinter, cb) ->
  domain = domainCreate()
  domain.on('error', (err) -> cb(err, null))

  domain.run =>
    base = "pdf/" + (+new Date())
    out = fs.createWriteStream(base + ".svg")
    req.pipe(out)

    cmdline = ("inkscape "+
           "--export-pdf="+base+".pdf "+
           "--export-dpi=300 "+base+".svg")
    onExec = ((err, stdout, stderr) ->
      if err?
        [err.stdout, err.stderr] = [stdout, stderr]
        throw err

        # also see https://npmjs.org/package/lp-client
        jobName = "gametag" + (+new Date())
        lpr(base + ".pdf", destinationPrinter, jobName, cb)
    )
    req.on('end', () -> exec(cmdline, onExec))

