Model
=====

Model, as in MVC, is a set of mongoose models for each entity in our database.

    Q = require 'q'
    (require './q-each') Q
    mongoose = require 'mongoose'
    (require './mongoose-promise-save') mongoose
    mongooseIncr = require './mongoose-auto-incr'

Models
------

We define our models, with appropriate schemas,

    defineModels = ->
      Schema = mongoose.Schema
      mongooseIncr.loadAutoIncr mongoose.connection

      topicPermission = Schema
        code: {type: String, ref: 'Topic'}
        permission: String

      eventSchema = Schema
        type: String
        url: {}
        model: String
        timestamp: {type: Date, default: Date.now}
        topicCode: {type: String, ref: 'Topic'}
      Event = mongoose.model('Event', eventSchema)

      userSchema = Schema
        name: String
        _id: {type: String, unique: true}
        password: String
        email: String
        facebook: String
        topics: [topicPermission]
      User = mongoose.model('User', userSchema)

      commentASchema = Schema
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        text: String
      commentASchema.methods.shallow = ->
        shallowify this, CommentA
      commentASchema.statics.findByURL = (url) ->
        Answer.findByURL(url)
        .then ([answer, parents]) ->
          comment = answer.comments.id url.commentId
          parents.answer = answer
          [comment, parents]
      commentASchema.statics.findShallowByURL = (url) ->
        compile CommentA.findByURL(url)
      CommentA = mongooseIncr.model('CommentA', commentASchema)

      answerSchema = Schema
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        comments: [commentASchema]
        text: String
        votesFor: [{type: String, ref: 'User'}]
        priority: Number
      answerSchema.methods.shallow = ->
        shallowify(this, Answer, ['comments'])
      answerSchema.statics.findByURL = (url) ->
        Question.findByURL(url)
        .then ([question, parents]) ->
          answer = question.answers.id url.answerId
          parents.question = question
          [answer, parents]
      answerSchema.statics.findShallowByURL = (url) ->
        compile Answer.findByURL(url)
      Answer = mongooseIncr.model('Answer', answerSchema)

      commentQSchema = Schema
        timestamp: {type: Date, default: Date.now}
        owner: {type: String, ref: 'User'}
        text: String
      commentQSchema.methods.shallow = ->
        shallowify this, CommentQ
      commentQSchema.statics.findByURL = (url) ->
        Question.findByURL(url)
        .then ([question, parents]) ->
          comment = question.comments.id url.commentId
          parents.question = question
          [comment, parents]
      commentQSchema.statics.findShallowByURL = (url) ->
        compile CommentQ.findByURL(url)
      CommentQ = mongooseIncr.model('CommentQ', commentQSchema)

      questionSchema = Schema
        createdTime: {type: Date}
        modifiedQuestionTime: {type: Date}
        modifiedTime: {type: Date}
        owner: {type: String, ref: 'User'}
        position: String
        answers: [answerSchema]
        comments: [commentQSchema]
        text: String
      questionSchema.methods.shallow = ->
        shallowify this, Question, ['answers', 'comments']
      questionSchema.statics.findByURL = (url) ->
        File.findByURL(url)
        .then ([file, parents]) ->
          question = file.questions.id url.questionId
          parents.file = file
          [question, parents]
      questionSchema.statics.findShallowByURL = (url) ->
        compile Question.findByURL(url)
      Question = mongooseIncr.model('Question', questionSchema)

      fileSchema = Schema
        _id: {type: String, unique: true, sparse: true} # topic._id-fileid
        path: String
        name: String
        owner: {type: String, ref: 'User'}
        questions: [questionSchema]
        type: String
        date: {type: Date}
      fileSchema.methods.shallow = ->
        shallowify this, File, ['questions']
      fileSchema.statics.findByURL = ({topicId, fileId}) ->
        Topic.findByURL({topicId})
        .then ([topic]) ->
          [topic.files.id(fileId), {topic}]
      fileSchema.statics.findShallowByURL = (url) ->
        compile File.findByURL(url)
      File = mongoose.model('File', fileSchema)

      topicSchema = Schema
        name: String
        _id: {type: String, unique: true}
        files: [fileSchema]
        types: [String]
      topicSchema.methods.shallow = ->
        Q.when this.toObject
          transform: (doc, ret) ->
            delete ret.files
            delete ret.types
            ret
      topicSchema.statics.findByURL = ({topicId}) ->
        Q.ninvoke(Topic, 'findById', topicId)
        .then (topic) ->
          if !topic?
            throw [404, "topic not found #{topicId}"]
          [topic]
      Topic = mongoose.model('Topic', topicSchema)

      {Topic, User, File, Question, CommentA, CommentQ, Answer, Event}

and export them.

    module.exports = models = defineModels()

Let service dynamicly choose a model.

    module.exports.named = (name) ->
      mongoose.model name

Utility to remove tree structure from data and populate owners

    shallowify = (doc, model, dontShow) ->
      Q.ninvoke(model, 'populate', doc, path: 'owner', select: 'name _id')
      .then (doc) ->
        doc.toObject
          transform: (doc, ret) ->
            if dontShow?
              for key in dontShow
                delete ret[key]
            ret

Utility which adds shallow copies of parents to the objects

    compile = (promise) ->
      promise.then ([doc, map]) ->
        doc.shallow().then (ret) ->
          Q.map map, (parent, label) ->
            parent.shallow().then (plain) ->
              ret[label] = plain
          .then ->
            ret

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

    populate = ->
      user = new models.User
        name: "Michal Srb"
        _id: "ms6611"
        password: "admin"
        email: "ms6611@imperial.ac.uk"
        facebook: "xixixao"
        topics: [
          code: "240"
          permission: 'r'
        ,
          code: "120.1"
          permission: 'r'
        ,
          code: "261"
          permission: 'r'
        ]
      Q.ninvoke(user, 'save').then ->
        user = new models.User
          name: "Mark Wheelhouse"
          _id: "mjw03"
          password: "admin"
          email: "mjw03@imperial.ac.uk"
          facebook: "mark"
          topics: [
            code: "240"
            permission: 'w'
          ,
            code: "120.1"
            permission: 'r'
          ,
            code: "261"
            permission: 'w'
          ]
        Q.ninvoke(user, 'save')
      .then ->
        user = new models.User
          name: "Tony Field"
          _id: "ajf"
          password: "admin"
          email: "ajf@imperial.ac.uk"
          facebook: "mark"
          topics: [
            code: "120.1"
            permission: 'w'
          ]
        Q.ninvoke(user, 'save')
      .then ->
        topic = new models.Topic
          name: "Models of Computation"
          _id: "240"
          types: ["Notes", "Tutorials", "Solutions"]
          files: []
        Q.ninvoke(topic, 'save')
      .then ->
        topic = new models.Topic
          name: "Programming I"
          _id: "120.1"
          types: ["Notes", "Exercises", "Tests"]
          files: []
        Q.ninvoke(topic, 'save')
      .then ->
        topic = new models.Topic
          name: "Laboratory 2"
          _id: "261"
          types: ["Webapps", "Pintos", "Life", "MAlice"]
          files: []
        Q.ninvoke(topic, 'save')
      .done()
      console.log "Populated"


And execute everything in correct synchronized order. Node will take care of executing this only once.

    connect()
    #wipe()
    #setTimeout ->
    #  #populate()
    #, 5000
