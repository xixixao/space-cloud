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

      userSchema = Schema
        name: String
        _id: {type: String, unique: true, dropDups: true}
        password: String
        topics: [topicPermission]
      User = mongoose.model('User', userSchema)

      commentASchema = Schema
        _id: {type:String, unique: true} #comment id
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        text: String
      CommentA = mongoose.model('CommentA', commentASchema)    

      answerSchema = Schema
        _id: {type:String, unique: true, dropDups: true} 
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        rank : Number
        comments: [commentASchema]
        text: String
      Answer = mongoose.model('Answer', answerSchema)

      commentQSchema = Schema
        _id: {type:String, unique: true, dropDups: true} #comment id
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        text: String
      CommentQ = mongoose.model('CommentQ', commentQSchema)

      questionSchema = Schema
        _id: {type:String, unique: true} #question id
        createdTime: {type: Date, default: Date.now}
        modifiedQuestionTime: {type: Date, default: Date.now}
        modifiedTime: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        filePosition: String
        answers: [answerSchema]
        comments: [commentQSchema]
        text: String
      Question = mongoose.model('Question', questionSchema)

      eventSchema = Schema
        type: String
        link: [String]
        model: String
        timestamp: {type: Date, default: Date.now}
        topicCode: {type: String, ref: 'Topic'}
      Event = mongoose.model('Event', eventSchema)

      fileSchema = Schema
        _id: {type: String, unique: true} # topic._id-fileid
        path: String
        name: String
        owner: {type: String, ref: 'User'}
        topicCode: {type: String, ref: 'Topic'}
        questions: [questionSchema]
      File = mongoose.model('File', fileSchema)     
      
      topicSchema = Schema
        name: String
        _id: {type: String, unique: true}
        files: [fileSchema]
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
        console.error "There has been an error:\n", error

    wipe = ->
      db = mongoose.connection
      Q.map db.collections, (collection) ->
        Q.ninvoke collection, 'drop'

    module.exports.wipe = wipe

And execute everything in correct synchronized order. Node will take care of executing this only once.

    connect()
    wipe()

