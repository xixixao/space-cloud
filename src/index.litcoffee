This is our backend server.

    mongoose = require 'mongoose'
    (require './mongoose-promise-save') mongoose
    express = require 'express'
    Q = require 'q'
    (require './q-each') Q

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

We connect to our test database and erase it.

    dbConnect = ->
      mongoose.connect "mongodb://localhost/test"

      db = mongoose.connection

      db.on "error", ->
        console.error "Unable to connect to the database"

    dbWipe = ->
      db = mongoose.connection
      Q.map db.collections, (collection) ->
        Q.invoke collection, 'drop'

We define our models, with appropriate schemas.

    dbModel = ->
      Schema = mongoose.Schema

      courseSchema = Schema
        name: String
        courseCode: Number
      Course = mongoose.model('Course', courseSchema)

      userSchema = Schema
        name: String
        courses: [type: Schema.Types.ObjectId, ref: 'Course']
      User = mongoose.model('User', userSchema)

      {Course, User}

For testing purposes, we fill in the database. We create couple courses,

    dbPopulate = ->

      courses = Q.map [0..3], (i) ->
        course = new Course
          name: "course #{i}"
          courseCode: i
        course.save()

and couple users and assign each course to every user.

      users = Q.map [0..10], (i) ->
        user = new User
          name: "user#{i}"
        courses.thenEach (course) ->
          user.courses.addToSet course._id
        user.save()

      Q.all [courses, users]

Check contents of the database.

    dbLog = ->

      users = User.find().exec().then (users) ->
        console.log "  Number of users #{users.length}"

      courses = Course.find().exec().then (courses) ->
        console.log "  Number of courses #{courses.length}"

      Q.all [users, courses]

    dbConnect()
    {Course, User} = dbModel()
    dbWipe()
    .then ->
      console.log "After wiping out"
      dbLog()
    .then(dbPopulate)
    .then ->
      console.log "After populating"
      dbLog()



    app.get '/users', (request, response) ->
      response.send users

    app.get '/users/:name', (request, response) ->
      User.find name: request.params.name, (err, docs) ->
        response.send docs









