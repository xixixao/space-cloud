Database setup
==============

We use this script to populate the database with some initial data.

    Q = require 'q'
    (require './q-each') Q
    mongoose = require 'mongoose'
    (require './mongoose-promise-save') mongoose
    {Topic, User, File, CommentA, CommentQ, Question, Answer, Event} = require './model'

Model connects to our database.

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
          permission: 'r'
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
              date: new Date("2013/06/05")
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
                    ]
                  answers: [
                      owner: "ms6611"
                      text: """<p>\"a brief summary of the user interactions in your program\"
                        <p>What we want top see here is a high-level discussion of what interactions take place between the users and the app.
                        You don't need to go into too much detail, just make the purpose and use of the app clear.
                        <br>
                        <p>So, for example, if your app were the exam communications system example from the spec then the user interactions would include:<br>
                        > Invigilators can communicate silently during an exam<br>
                        > Invigilators can request assistance in their room<br>
                        > Invigilators can check the status of all currently running exams<br>
                        ...etc...
                        <p>If your app is a game, then we want a brief summary of the rules and how the user plays the game."""
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
              date: new Date("2013/06/05")
            ,
              _id: 'informed-search'
              name: "Informed Search"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'adversarial-search'
              name: "Adversarial Search"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'planning-and logic'
              name: "Planning and Logic"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'planning-algorithms'
              name: "Planning Algorithms"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'krr'
              name: "KRR"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'semanticweb'
              name: "SemanticWeb"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'nmr'
              name: "NMR"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'introlearning'
              name: "IntroLearning"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'reinflearning'
              name: "ReinfLearning"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'abdarg'
              name: "AbdArg"
              type: 'Notes'
              date: new Date("2013/06/05")
            ,
              _id: 'tutorial-1'
              name: "Tutorial 1"
              type: 'Tutorials'
              date: new Date("2013/06/05")
            ,
              _id: 'tutorial-2'
              name: "Tutorial 2"
              type: 'Tutorials'
              date: new Date("2013/06/05")
            ,
              _id: 'tutorial-3'
              name: "Tutorial 3"
              type: 'Tutorials'
              date: new Date("2013/06/05")
            ,
              _id: 'tutorial-4'
              name: "Tutorial 4"
              type: 'Tutorials'
              date: new Date("2013/06/05")
            ,
              _id: 'tutorial-5'
              name: "Tutorial 5"
              type: 'Tutorials'
              date: new Date("2013/06/05")
            ,
              _id: 'solution-1'
              name: "Solution 1"
              type: 'Solutions'
              date: new Date("2013/06/05")
            ,
              _id: 'solution-2'
              name: "Solution 2"
              type: 'Solutions'
              date: new Date("2013/06/05")
            ,
              _id: 'solution-3'
              name: "Solution 3"
              type: 'Solutions'
              date: new Date("2013/06/05")
            ,
              _id: 'solution-4'
              name: "Solution 4"
              type: 'Solutions'
              date: new Date("2013/06/05")
            ,
              _id: 'solution-5'
              name: "Solution 5"
              type: 'Solutions'
              date: new Date("2013/06/05")
          ]
        Q.ninvoke(topic, 'save')
      #.then ->
      #  event = new models.Event
      #    model: "Added"
      #    type: "File"
      #    topicCode: "topics/222/files/#{file._id}"
      #    url: request.params.topicId
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


We need to wait for wipout to finish because the synchronization doesn't work for some reason.

    wipe()
    setTimeout ->
      populate()
    , 2000

