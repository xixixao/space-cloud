This is our backend server.

    express = require 'express'
    app = express()

    port = 3333

    server = app.listen port, ->
      console.log "Express server listening on port %d in %s mode", server.address().port, app.settings.env

    app.configure ->
      app.set 'port', port
      app.use express.bodyParser()
      app.use express.methodOverride()
      app.use express.compress()

    app.configure 'development', ->
      app.use express.errorHandler()

    app.all '/server-check', (request, response) ->
      response.send "Cloud running"


Database for users:

    users = [
        id: "michal"
        name: "Michal Srb"
        year: 2011
        uri: "/users/michal"
      ,
        id: "pamela"
        name: "Cruz"
        year: 2011
        uri: "/users/pamela"
    ]

    app.get '/users', (request, response) ->
      response.send users

    app.get '/users/:name', (request, response) ->
      for user in users
        if user.id is request.params.name
          response.send user
          break

    app.put '/client/create-form', (request, response) ->
      res.writeHead 200, 'Content-Type': 'text/plain'
      res.end JSON.stringify list








