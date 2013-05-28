Model
=====

Model, as in MVC, is a set of mongoose models for each entity in our database.

    Q = require 'q'
    (require './q-each') Q
    mongoose = require 'mongoose'
    (require './mongoose-promise-save') mongoose

Models
------

We define our models, with appropriate schemas,

    defineModels = ->
      Schema = mongoose.Schema

      courseSchema = Schema
        name: String
        _id: {type: String, unique: true}
      Course = mongoose.model('Course', courseSchema)

      userSchema = Schema
        name: String
        _id: {type: String, unique: true}
        password: String
        courses: [type: Schema.Types.ObjectId, ref: 'Course']
      User = mongoose.model('User', userSchema)

      fileSchema = Schema
        _id: {type: String, unique: true} #file id
        path: String
        name: String
        owner: {type: Schema.Types.ObjectId, ref: 'User'}
        questions: [type: Schema.Types.ObjectId, ref: 'Question']
      File = mongoose.model('File', fileSchema)     
                 
      questionSchema = Schema
        _id: {type:String, unique: true} #question id
        timestamp: {type: Date, default: Date.now}
        owner: {type: Schema.Types.ObjectId, ref: 'User'}
        comments: [type: Schema.Types.ObjectId, ref: 'Comment']
        filePosition: String
      Question = mongoose.model('Question', questionSchema)

      commentSchema = Schema
        _id: {type:String, unique: true} #comment id
        timestamp: {type: Date, default: Date.now}
        owner: {type: Schema.Types.ObjectId, ref: 'User'}
      Comment = mongoose.model('Comment', commentSchema)        

      {Course, User, File, Question, Comment}

and export them.

    module.exports = models = defineModels()

Database setup
--------------

We connect to our test database and erase it.

    connect = ->
      mongoose.connect "mongodb://localhost/test"

      db = mongoose.connection

      db.on "error", (error) ->
        console.error "There has been an error:\n", error

    wipe = ->
      db = mongoose.connection
      Q.map db.collections, (collection) ->
        Q.ninvoke collection, 'drop'


For testing purposes, we fill in the database. We create couple courses,

    populate = ({Course, User})->
      courses = Q.map [0..3], (i) ->
        course = new Course
          name: "course #{i}"
          _id: i
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

    printStats = ({User, Course})->

      users = User.find().exec().then (users) ->
        console.log "  Number of users #{users.length}"

      courses = Course.find().exec().then (courses) ->
        console.log "  Number of courses #{courses.length}"

      Q.all [users, courses]

And execute everything in correct synchronized order. Node will take care of executing this only once.

    connect()
    wipe()

