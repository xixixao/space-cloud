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
        _id: {type: String, unique: true} # topic._id-fileid
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
        email: "ms6611@erial.ac.uk"
        facebook: "xixixao"
        topics: [
          code: "222"
          permission: 'w'
        ]
      Q.ninvoke(user, 'save').then ->
        topic = new models.Topic
          name: "Models of Computation"
          _id: "222"
          types: ["Notes", "Tutorials", "Solutions"]
          files: [
              _id: 'intro'
              name: "Introduction and Methods"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'uninformed-search'
              name: "Uninformed Search"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'informed-search'
              name: "Informed Search"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'adversarial-search'
              name: "Adversarial Search"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'planning-and logic'
              name: "Planning and Logic"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'planning-algorithms'
              name: "Planning Algorithms"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'krr'
              name: "KRR"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'semanticweb'
              name: "SemanticWeb"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'nmr'
              name: "NMR"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'introlearning'
              name: "IntroLearning"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'reinflearning'
              name: "ReinfLearning"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'abdarg'
              name: "AbdArg"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'tutorial-1'
              name: "Tutorial 1"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'tutorial-2'
              name: "Tutorial 2"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'tutorial-3'
              name: "Tutorial 3"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'tutorial-4'
              name: "Tutorial 4"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'tutorial-5'
              name: "Tutorial 5"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'solution-1'
              name: "Solution 1"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'solution-2'
              name: "Solution 2"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'solution-3'
              name: "Solution 3"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'solution-4'
              name: "Solution 4"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
            ,
              _id: 'solution-5'
              name: "Solution 5"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
              owner: "ms6611"
          ]
        Q.ninvoke(topic, 'save')
      #          "223":
      #            name: "Architecture"
      #            permission: "r"
      #            types: [
      #              'Cool notes'
      #            ]
      #            files:
      #              'hello-ronnie':
      #                name: "Hello ronnie"
      #                type: 'Cool notes'
      #              'blabla':
      #                name: "Blabla"
      #                type: 'Cool notes'


And execute everything in correct synchronized order. Node will take care of executing this only once.

    connect()
    #wipe()
    #setTimeout ->
    #  populate()
    #, 2000

