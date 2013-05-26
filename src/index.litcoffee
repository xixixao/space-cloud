This is our backend server.

    mongoose = require 'mongoose'
    express = require 'express'
    Q = require 'q'
    (require './q-each') Q


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

    mongoose.connect "mongodb://localhost/test"
    Schema = mongoose.Schema

    db = mongoose.connection

    db.on "error", ->
      console.error "of"
    db.once "open", ->
      console.log "success"



    courseSchema = Schema(name: String, courseCode: Number)
    userSchema = Schema(name: String, courses: [{type: Schema.Types.ObjectId, ref: 'Course'}])

    Course = mongoose.model('Course', courseSchema)
    User = mongoose.model('User', userSchema)

    wiped = Q.map db.collections, (collection) ->
      Q.invoke collection, 'drop'

    wiped.then ->
      User.find (err, users) ->
        console.log "Number of users #{users.length}"

      Course.find (err, courses) ->
        console.log "Number of users #{courses.length}"

#    modules = Q.map [0..3], (i) ->
#      course = new Course name: "course #{i}", courseCode: i
#      Q.ninvoke course, 'save'
#
#    users = for i in [0..10]
#      user = new User name: "user#{i}"
#      modules.thenEach (module) ->
#        console.log module
#        user.courses.addToSet module._id
#      user.save (err, users) ->
#        if err
#          console.error err

    


    app.get '/users', (request, response) ->
      response.send users

    app.get '/users/:name', (request, response) ->
      User.find name: request.params.name, (err, docs) ->
        response.send docs

    app.put '/client/create-form', (request, response) ->
      res.writeHead 200, 'Content-Type': 'text/plain'
      res.end JSON.stringify list









