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

      topicSchema = Schema
        name: String
        _id: {type: String, unique: true}
      Topic = mongoose.model('Topic', topicSchema)

      topicPermission = Schema
        code: {type: String, ref: 'Topic'}
        permission: String

      userSchema = Schema
        name: String
        _id: {type: String, unique: true, dropDups: true}
        password: String
        topics: [topicPermission]
      User = mongoose.model('User', userSchema)

      fileSchema = Schema
        _id: {type: String, unique: true} # topic._id-fileid
        path: String
        name: String
        owner: {type: String, ref: 'User'}
        topicCode: {type: String, ref: 'Topic'}
      File = mongoose.model('File', fileSchema)     
                 
      questionSchema = Schema
        _id: {type:String, unique: true} #question id
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        filePosition: String
        file: {type: String, ref: 'File'}
        answers: [answerSchema]
        comments: [commentQSchema]
        text: String
      Question = mongoose.model('Question', questionSchema)

      answerSchema = Schema
        _id: {type:String, unique: true} 
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        question: {type: String, ref: 'Question'}
        rank : Number
        comments: [commentASchema]
        text: String
      Answer = mongoose.model('Answer', answerSchema)

      commentQSchema = Schema
        _id: {type:String, unique: true} #comment id
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        question: {type: String, ref: 'Question'}
        text: String
      CommentQ = mongoose.model('CommentQ', commentQSchema)       

      commentASchema = Schema
        _id: {type:String, unique: true} #comment id
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        answer: {type: String, ref: 'Answer'}
        text: String
      CommentA = mongoose.model('CommentA', commentASchema)    

      {Topic, User, File, Question, CommentA, CommentQ, Answer}

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


For testing purposes, we fill in the database. We create couple topics,

    populate = ({Topic, User})->
      topics = Q.map [0..3], (i) ->
        topic = new Topic
          name: "topic #{i}"
          _id: i
        topic.save()

and couple users and assign each topic to every user.

      users = Q.map [0..10], (i) ->
        user = new User
          name: "user#{i}"
        topics.thenEach (topic) ->
          user.topics.addToSet topic._id
        user.save()

      Q.all [topics, users]

Check contents of the database.

    printStats = ({User, Topic})->

      users = User.find().exec().then (users) ->
        console.log "  Number of users #{users.length}"

      topics = Topic.find().exec().then (topics) ->
        console.log "  Number of topics #{topics.length}"

      Q.all [users, topics]

And execute everything in correct synchronized order. Node will take care of executing this only once.

    connect()
    wipe()

