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

      topicPermission = Schema
        code: {type: String, ref: 'Topic'}
        permission: String

      eventSchema = Schema
        type: String
        url: String
        model: String
        timestamp: {type: Date, default: Date.now}
        topicCode: {type: String, ref: 'Topic'}
      Event = mongoose.model('Event', eventSchema)

      userSchema = Schema
        name: String
        _id: {type: String, unique: true, dropDups: true}
        password: String
        email: String
        facebook: String
        topics: [topicPermission]
      User = mongoose.model('User', userSchema)

      commentASchema = Schema
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        text: String
      CommentA = mongoose.model('CommentA', commentASchema)    

      answerSchema = Schema
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        rank : Number
        comments: [commentASchema]
        text: String
      Answer = mongoose.model('Answer', answerSchema)

      commentQSchema = Schema
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        text: String
      CommentQ = mongoose.model('CommentQ', commentQSchema)

      questionSchema = Schema
        createdTime: {type: Date, default: Date.now}
        modifiedQuestionTime: {type: Date, default: Date.now}
        modifiedTime: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        filePosition: String
        answers: [answerSchema]
        comments: [commentQSchema]
        text: String
      Question = mongoose.model('Question', questionSchema)


      fileSchema = Schema
        _id: {type: String, unique: true} # topic._id-fileid
        path: String
        name: String
        owner: {type: String, ref: 'User'}
        topicCode: {type: String, ref: 'Topic'}
        questions: [questionSchema]
        type: String
      File = mongoose.model('File', fileSchema)     
      
      topicSchema = Schema
        name: String
        _id: {type: String, unique: true}
        files: [fileSchema]
        types: [String]
      Topic = mongoose.model('Topic', topicSchema)
      
      {Topic, User, File, Question, CommentA, CommentQ, Answer, Event}

and export them.

    module.exports = models = defineModels()

Database setup
--------------

We connect to our test database and erase it.

    connect = ->
      mongoose.connect "mongodb://localhost/test"

      db = mongoose.connection

      db.on "error", (error) ->
        console.error "DB error:(are you running the database?)\n", error

    wipe = ->
      db = mongoose.connection
      Q.map db.collections, (collection) ->
        Q.ninvoke collection, 'drop'

    module.exports.wipe = wipe

And execute everything in correct synchronized order. Node will take care of executing this only once.

    connect()
    wipe()

