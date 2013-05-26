This is the definition of our service, via a RESTful API.

    {Course, User} = require './model'

    module.exports = (app) ->
      app.get '/users', (request, response) ->
        response.send users

      app.get '/users/:name', (request, response) ->
        User.find name: request.params.name, (err, docs) ->
          response.send docs