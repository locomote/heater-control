_          = require('lodash')
exec       = require('child_process').exec
express    = require('express')

app     = express()

RANGES =
  heat:
    min: 20, max: 24
  cool:
    min: 21, max: 24

start = ->
  host = '127.0.0.1'
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

  command = "igclient --send=./commands/#{file}"

  console.log "executing: #{command}"

  exec command, (err, stdout, stderr) ->
    return cb(err) if err

    if !stdout?.length or stdout.indexOf('send: success') is -1
      return cb("Send didn't complete successfully:\n#{stdout}")

    cb()

setupRoutes = ->
  app.post "/off", (req, res, next) ->
    sendCommand 'off', null, (err) ->
      return next(err) if err

      res.send 'ok'

  app.post "/on", (req, res, next) ->
    mode = req.param('mode')
    temp = req.param('temp')

    return res.status(400).send("Invalid mode") unless RANGES[mode]
    return res.status(400).send("Invalid temp") unless temp

    temp = parseInt(temp)
    range = RANGES[mode]

    if temp > range.max or temp < range.min
      return res.send(400, "Out of range; must be within: #{range.min} <= temp <= #{range.max}")

    sendCommand mode, temp, (err) ->
      return next(err) if err

      res.send 'ok'


setupRoutes()
start()
