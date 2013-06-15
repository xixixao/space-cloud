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
        comments: [commentASchema]
        text: String
        votesFor: [{type: String, ref: 'User'}]
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
        position: String
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
        date: {type: Date}
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
              questions: [
                  owner: "ms6611"
                  text: "I am not sure what this means. Please help me I am lost I need some solutions as fast as you can! please help!!! help!!! I am not sure what this means. Please help me I am lost I need some solutions as fast as you can! please help!!! help!!! I am not sure what this means. Please help me I am lost I need some solutions as fast as you can! please help!!! help!!! I am not sure what this means. Please help me I am lost I need some solutions as fast as you can! please help!!! help!!!"
                  position: "[\"[200, 600, 1]\",\"[400, 700, 1]\"]"
                  comments: [
                      owner: "ms6611"
                      text: "Interesting question."
                    ,
                      owner: "ms6611"
                      text: "Or just a stupid one."
                    ,
                      owner: "ms6611"
                      text: "Or just a stupid one."
                  ]
                  answers: [
                      owner: "ms6611"
                      text: "I think the answer is 'awesome'."
                      comments: [
                          owner: "ms6611"
                          text: "A lion?"
                        ,
                          owner: "ms6611"
                          text: "A cat for sure."
                      ]
                    ,
                      owner: "ms6611"
                      text: "I think it is concerned with the abdominal spacial features of enlarged natural language complexities."
                  ]
                ,
                  owner: "ms6611"
                  text: "How come?"
                  position: "[\"[300, 100, 1]\",\"[500, 200, 1]\"]"
                ]
            ,
              _id: 'uninformed-search'
              name: "Uninformed Search"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'informed-search'
              name: "Informed Search"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'adversarial-search'
              name: "Adversarial Search"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'planning-and logic'
              name: "Planning and Logic"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'planning-algorithms'
              name: "Planning Algorithms"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'krr'
              name: "KRR"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'semanticweb'
              name: "SemanticWeb"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'nmr'
              name: "NMR"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'introlearning'
              name: "IntroLearning"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'reinflearning'
              name: "ReinfLearning"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'abdarg'
              name: "AbdArg"
              type: 'Notes'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'tutorial-1'
              name: "Tutorial 1"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'tutorial-2'
              name: "Tutorial 2"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'tutorial-3'
              name: "Tutorial 3"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'tutorial-4'
              name: "Tutorial 4"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'tutorial-5'
              name: "Tutorial 5"
              type: 'Tutorials'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'solution-1'
              name: "Solution 1"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'solution-2'
              name: "Solution 2"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'solution-3'
              name: "Solution 3"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'solution-4'
              name: "Solution 4"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
            ,
              _id: 'solution-5'
              name: "Solution 5"
              type: 'Solutions'
              date: new Date Date.UTC(2013, 6, 5)
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
    wipe()
    #setTimeout ->
    #  populate()
    #, 2000

