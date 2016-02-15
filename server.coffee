path       = require('path')
exec       = require('child_process').exec
express    = require('express')
glob       = require('glob')


root         = path.normalize(__dirname)
commandsPath = "#{root}/commands"
app          = express()


getTemps = (mode) ->
  glob.sync("on_*_#{mode}.txt", cwd: commandsPath).map((f) -> f.match(/_(\d+)_/)[1])

commands =
  heat: getTemps('heat')
  cool: getTemps('cool')


start = ->
  #host = '127.0.0.1'
  host = '0.0.0.0'
  port = 2990
  server = app.listen port, host

  console.log "App listening at http://#{host}:#{port}"

  server.on 'error', (err) ->
    switch err.code
      when 'EADDRINUSE'
        console.error "Port #{port} already taken"
    throw err

sendCommand = (mode, temp, cb) ->
  file = if mode is 'off'
    "off.txt"
  else
    "on_#{temp}_#{mode}.txt"

  command = "igclient --send=#{commandsPath}/#{file}"

  console.log "executing: #{command}"

  exec command, (err, stdout, stderr) ->
    return cb(err) if err

    if !stdout?.length or stdout.indexOf('send: success') is -1
      return cb("Send didn't complete successfully:\n#{stdout}")

    cb()

setupRoutes = ->
  app.post "/", (req, res, next) ->
    mode = req.param('mode')
    temp = req.param('temp')

    if mode is 'off'
      sendCommand 'off', null, (err) ->
        return next(err) if err

        res.send 'ok'
    else
      return res.status(400).send("Invalid mode") unless commands[mode]
      return res.status(400).send("Invalid temp") unless temp

      if temp not in commands[mode]
        return res.status(400).send("temp must be in #{commands[mode]}")

      sendCommand mode, temp, (err) ->
        return next(err) if err

        res.send 'ok'


setupRoutes()
start()
