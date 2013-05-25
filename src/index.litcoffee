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

    # users = [
    #     id: "michal"
    #     name: "Michal Srb"
    #     year: 2011
    #     uri: "/users/michal"
    #   ,
    #     id: "pamela"
    #     name: "Cruz"
    #     year: 2011
    #     uri: "/users/pamela"
    # ] 

    mongoose = require 'mongoose'
    mongoose.connect "mongodb://localhost/test"
    
    db = mongoose.connection

    db.on "error", ->
      console.error "of"
    db.once "open", ->
      console.log "success"



    courseSchema = mongoose.Schema(name: String, courseCode: Number)
    userSchema = mongoose.Schema(name: String, courses: [courseSchema])

    Course = mongoose.model('Course', courseSchema)
    User = mongoose.model('User', userSchema)


    courses = for i in [0..3]
      course = new Course name: "course #{i}", courseCode: i
      course.save (err, course) -> 
        if err 
          console.error err


    users = for i in [0..10]
      user = new User name: "user #{i}"
      user.save (err, users) ->
        if err 
          console.error err

    User.find (err, users) -> 
      console.log users.length

    Course.find (err, courses) -> 
      console.log courses.length



 








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








