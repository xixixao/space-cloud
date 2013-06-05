This is the definition of our service, via a RESTful API.

    Q = require 'q'
    (require './q-each') Q
    passport = require("passport")
    {Topic, User, File, CommentA, CommentQ, Question, Answer, Event} = require './model'
    {canRead, canWrite, authenticated} = require './authentication'

    module.exports = (app) ->

-------------------------------------------------------
Finds a user with a given login and returns the details
-------------------------------------------------------

      app.get '/users/:login', (request, response) ->
        usersFiles(request.params.login)
        .then (user) ->
          response.send user
        , (error) ->
          response.send error

      usersFiles = (userId) ->
        Q.ninvoke(User, 'findById', userId)
        .then (user) ->
          Q.ninvoke(user, 'populate', 'topics.code')
        .then (user) ->
          user = user.toObject()

          topicPermissions = user.topics
          fileLists = Q.map topicPermissions, ({code}) ->
            topicId = code._id
            Q.ninvoke File, 'find', topicCode: topicId

          fileLists.thenEach (files, i) ->
            user.topics[i].code.files = files
          .then ->
            user

----------------------
Adds a user to the DB - aka SIGN UP
----------------------

      app.post '/users', (request, response) ->
        user = new User
          name: request.body.name
          _id: request.body._id
          password: request.body.password
          topics: request.body.topics
        user.save (err) ->
          if err?
            response.send err
          else
            response.send user

----------------
Login validation
----------------

      app.post '/login', passport.authenticate('local'), (request, response) ->
        response.send "logged in"


-----------------------
Adds a topic to the DB
-----------------------

      app.post '/topics', (request, response) ->
        topic = new Topic
          name: request.body.name
          _id: request.body._id
          files: []
        topic.save (err) ->
          if err?
            response.send err
          else
            response.send topic

-------------------------------------------
Retrieves a topic from the DB with id code
-------------------------------------------

      app.get '/topics/:code', (request, response) ->
        topicCode = request.params.code
        Topic.findById topicCode, (err, docs) ->
          if err?
            response.send "not found"
          else
            response.send docs


---------------------------------------------------
Adds a list of topics to the user with login given
---------------------------------------------------

      app.post '/users/:login', (request, response) ->
        User.findById request.params.login, (err, user) ->
          if err?
            response.send err
          else
            topics = request.body.topics
            for topic in topics
              user.topics.addToSet topic
            response.send user

------------------------
Adds an event to the DB
------------------------

      addEvent = (type, model, link) ->
        event = new Event
          model: model
          type: type
        for item in link 
          event.link.addToSet item
        event.save (err) ->
          if err?
            return err
          else
            return event

------------------------------------
Retrieve all the events from the DB
------------------------------------

      app.get '/events', (request, response) ->
        Event.find({}).sort('-timestamp').exec (err, events) ->
          if err?
            response.send err
          else
            # Q.map events, (event) ->
            #   Q.ninvoke event, 'populate',
            #     model: event.model
            #     path: 'link'
            # .then (events) ->
            response.send events


--------------------------------------
Creates and saves a new file to the topics list of files
--------------------------------------

      findTopic = ({topicId}) ->
        Q.ninvoke(Topic, 'findById', topicId)
        .then (topic) ->
          if !topic?
            throw [404, "topic not found"]
          topic

      app.post '/topics/:topicId/files', authenticated, (request, response) ->
        if !canWrite request, request.params.topicId
          return response.send 401, 'User doesnt have write permission'

        file = new File
          _id: request.body._id
          path: request.body.path
          name: request.body.name
          owner: request.body.owner
        findTopic(request.params)
        .then (topic) ->
          topic.files.addToSet file  
          addEvent "Added", "File", [request.params.topicId, request.body._id]
          topic.save()
        .then ->
          response.send file
        , (error) ->
          response.send 500, error
        .done()

-------------------------------------------
Retrieves a file from the DB with id code
-------------------------------------------

      findFile = (request, {topicId, fileId}) ->
   
        findTopic({topicId})
        .then (topic) ->
          if !canRead request, topicId
            throw [401, "cant read"]
          [topic, topic.files.id fileId]

      app.get '/topics/:topicId/files/:fileId', authenticated, (request, response) ->
        findFile(request, request.params)
        .then ([topic, file]) ->
          response.send file
        , (error) ->
          response.send error...
        .done()  

        
------------------------------------------
Creates and saves a new question to the DB
------------------------------------------


      app.post '/topics/:topicId/files/:fileId/questions', authenticated, (request, response) ->
        question = new Question
          _id: request.body._id
          owner: request.body.owner
          filePosition: request.body.filePosition
          text: request.body.text
        findFile(request, request.params)
        .then ([topic, file]) ->
          file.questions.addToSet question
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent "Added", "Question", [request.params.topicId, request.params.fileId, request.body._id]
          response.send question
        , (error) ->
          response.send error...
        .done() 


-------------------------------------------
Retrieves a question from the DB with id code
-------------------------------------------

      findQuestion = (request, {topicId, fileId, questionId}) ->
        findFile(request, {topicId, fileId})
        .then ([topic, file]) ->
          question = file.questions.id questionId
          [topic, file, question]

      app.get '/topics/:topicId/files/:fileId/questions/:questionId', authenticated, (request, response) ->
        findQuestion(request, request.params) 
        .then ([topic, file, question]) ->
          response.send question
        , (error) ->
          response.send error...
        .done()


------------------------------------------
Creates and saves a new answer to the DB
------------------------------------------



      app.post '/topics/:topicId/files/:fileId/questions/:questionId/answers', authenticated, (request, response) ->
        findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          answer = new Answer
              _id: request.body._id
              owner: request.body.owner
              rank: request.body.rank
              text: request.body.text
          question.answers.addToSet answer
          Q.ninvoke(topic, 'save')
          .then ->
            addEvent "Added", "Answer", [request.params.topicId, request.params.fileId, request.params.questionId, request.body._id]
            response.send question
        , (error) ->
          response.send error...
        .done() 

-------------------------------------------
Retrieves an answer from the DB with id code
-------------------------------------------

      findAnswer = (request, {topicId, fileId, questionId, answerId}) ->
        findQuestion(request, {topicId, fileId, questionId})
        .then ([topic, file, question]) ->
          answer = question.answers.id answerId
          [topic, file, question, answer]

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId', authenticated, (request, response) ->
        findAnswer(request, request.params) 
        .then ([topic, file, question, answer]) ->
          response.send answer
        , (error) ->
          response.send error...
        .done()
            

-------------------------------------------------------
Creates and saves a new comment to a question to the DB
-------------------------------------------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/comments', authenticated, (request, response) ->
        comment = new CommentQ
          _id: request.body._id
          owner: request.body.owner
          text: request.body.text
        findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          question.comments.addToSet comment
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent "Added", "CommentQ", [request.params.topicId, request.params.fileId, request.params.questionId, request.body._id]
          response.send comment
        , (error) ->
          response.send error
        .done() 
        

------------------------------------------------------------
Retrieves a comment from a question from the DB with id code
------------------------------------------------------------

      findCommentQ = (request, {topicId, fileId, questionId, commentId}) ->
        findQuestion(request, {topicId, fileId, questionId})
        .then ([topic, file, question]) ->
          comment = question.comments.id commentId
          [topic, file, question, comment]

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/comments/:commentId', authenticated, (request, response) ->
        findCommentQ(request, request.params) 
        .then ([topic, file, question, comment]) ->
          response.send comment
        , (error) ->
          response.send error...
        .done()


-------------------------------------------------------
Creates and saves a new comment to an answer to the DB
-------------------------------------------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/comments', authenticated, (request, response) ->
        comment = new CommentA
          _id: request.body._id
          owner: request.body.owner
          text: request.body.text
        findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          answer.comments.addToSet comment
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent "Added", "CommentA", [request.params.topicId, request.params.fileId, request.params.questionId, request.params.answerId, request.body._id]
          response.send comment
        , (error) ->
          response.send error...
        .done() 
        
        

------------------------------------------------------------
Retrieves a comment from an answer from the DB with id code
------------------------------------------------------------
      
      findCommentA = (request, {topicId, fileId, questionId, answerId, commentId}) ->
        findAnswer(request, {topicId, fileId, questionId, answerId})
        .then ([topic, file, question, answer]) ->
          comment = answer.comments.id commentId
          [topic, file, question, answer, comment]

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/comments/:commentId', authenticated, (request, response) ->
        findCommentA(request, request.params) 
        .then ([topic, file, question, answer, comment]) ->
          response.send comment
        , (error) ->
          response.send error...
        .done()

Retrieve feeds for a particular user

      app.get '/feeds/:user', authenticated, (request, response) ->
        Q.ninvoke(
          User.findById(request.params.user)
          .select('topics.code')
        , 'exec')
        .then ({topics}) ->
          topicCodes = (code for {code} in topics)
          Q.ninvoke(
            Question.find({})
            .populate(
              path: 'file'
              match: topicCode: $in: topicCodes
            )
            .sort('-modifiedTime')
          , 'exec')
          .then (questions) ->
            q for q in questions when q.file?
        .then (questions) ->
          response.send questions
        .done()

        # find questions
        # populate file {topic_id}

        # find user (list of topics inside it)

        # on the questions, do topic_id "in" the list of courses

