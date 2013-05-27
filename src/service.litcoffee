This is the definition of our service, via a RESTful API.

    {Course, User} = require './model'

    module.exports = (app) ->

-----

      app.get '/users/:login', (request, response) ->
        User.find login: request.params.login, (err, docs) ->
          response.send docs

-----

      app.post '/users', (request, response) ->
        user = new User
          name: request.body.name
          login: request.body.login 
          password: request.body.password
        user.save (err) ->
          if err?
            response.send err 
          else
            response.send user

-----

      app.post '/login', (request, response) ->
        User.findOne login: request.body.login, (err, user) ->
          if err?
            response.send err 
          else
            console.log user
            console.log request.body.password
            if user.password != request.body.password
              response.send "error"
            else
              response.send "ok" 
