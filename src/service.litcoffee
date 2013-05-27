This is the definition of our service, via a RESTful API.

    {Course, User} = require './model'

    module.exports = (app) ->

-----

      app.get '/users/:login', (request, response) ->
        User.find username: request.params.login, (err, docs) ->
          response.send docs

-----

      app.post '/users', (request, response) ->
        user = new User
          name: request.body.name
          username: request.body.username 
          password: request.body.password
        user.save (err) ->
          if err?
            response.send err 
          else
            response.send user

-----

      app.post '/login', (request, response) ->
        User.findOne username: request.body.username, (err, user) ->
          if err?
            response.send err 
          else
            if user.password != request.body.password
              response.send "error"
            else
              response.send "ok" 

-----

      app.post '/courses', (request, response) ->
        course = new Course
          name: request.body.name
          code: request.body.code
        course.save (err) ->
          if err?
            response.send err 
          else
            response.send course

-----

      app.get '/courses/:code', (request, response) ->
        Course.find code: request.params.code, (err, docs) ->
          response.send docs

-----

      app.post '/users/:login', (request, response) ->
        User.findOne username: request.params.login, (err, user) ->
          if err?
            response.send err 
          else
            course = request.body.courses
            #console.log courses
            #for course in courses
            user.courses.addToSet course
            response.send "ok"




