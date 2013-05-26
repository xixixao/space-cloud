This is our backend server.

    express = require 'express'
    service = require './service'

We use express to reply to different requests in a fully RESTful matter.

    app = express()

    port = 3333

    server = app.listen port, ->
      console.log "Express server listening on port %d in '%s' mode", server.address().port, app.settings.env

    app.configure ->
      app.set 'port', port
      app.use express.bodyParser()
      app.use express.methodOverride()
      app.use express.compress()

During development, we want to see errors in our responses.

    app.configure 'development', ->
      app.use express.errorHandler()

Replies to any request to URI 'server-check', for testing purposes.

    app.all '/server-check', (request, response) ->
      response.send "Cloud running"

We now attach our service to the server.

    service app
