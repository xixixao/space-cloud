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
          link: link
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
            Q.map events, (event) ->
              Q.ninvoke event, 'populate',
                model: event.model
                path: 'link'
            .then (events) ->
              response.send events

              #event.populate
              #  model: event.model
              #  path: 'link'
              #, (err, event) ->
              #  console.log event 
              #response.send events

--------------------------------------
Creates and saves a new file to the DB
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
          addEvent "Added", "File", file._id
          console.log topic
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
        findTopic(topicId)
        .then (topic) ->
          if !canRead request, topicId
            throw [401, "cant read"]
          [topic, topic.files.id fileId]

      app.get '/topics/:topicId/files/:fileId', authenticated, (request, response) ->
        findFile(request, request.params)
        .then ([topic, file]) ->
          console.log file
          response.send file
        , (error) ->
          response.send error...
        .done()  

        
------------------------------------------
Creates and saves a new question to the DB
------------------------------------------


      app.post '/topics/:topicId/files/:fileId/questions', authenticated, (request, response) ->
        findFile(request, request.params)
        .then ([topic, file]) ->
          question = new Question
            _id: request.body._id
            owner: request.body.owner
            filePosition: request.body.filePosition
            file: request.body.file
            text: request.body.text
          file.questions.addToSet question
          topic.save()
          .then ->
            addEvent "Added", "Question", question._id
            response.send question
        , (error) ->
          response.send error...
        .done() 


-------------------------------------------
Retrieves a question from the DB with id code
-------------------------------------------

      findQuestion = ({topicId, fileId, questionId}) ->
        findFile(request, {topicId, fileId})
        .then ([topic, file]) ->
          question = file.questions.id questionId
          [topic, file, question]

      app.get '/topics/:topicId/files/:fileId/questions/:questionId', authenticated, (request, response) ->
        findQuestion(request.params) 
        .then ([topic, file, question]) ->
          response.send question
        , (error) ->
          response.send error...
        .done()


------------------------------------------
Creates and saves a new answer to the DB
------------------------------------------

      app.post '/answers', authenticated, (request, response) ->
        questionPromise = Q.ninvoke Question, 'findById', request.body.question
        questionPromise.then (question) ->
          if !question?
            return response.send 404, "Question not found"
          filePromise = Q.ninvoke File, 'findById', question.file
          filePromise.then (file) ->
            if !file?
              return response.send 404, "File not found"
            if !canRead request, file.topicCode
              return response.send 401, 'User doesnt have write permission' 
            answer = new Answer
              _id: request.body._id
              owner: request.body.owner
              question: request.body.question
              rank: request.body.rank
              text: request.body.text
            addEvent "Added", "Answer", answer._id
            answer.save (err) ->
              if err?
                response.send err
              else response.send question
          , (error) ->
              response.send 500, "File could not be found"
          .done()
        , (error) ->
            response.send 500, "File could not be found"
        .done()

-------------------------------------------
Retrieves an answer from the DB with id code
-------------------------------------------

      app.get '/answers/:code', authenticated, (request, response) ->
        Q.ninvoke(Answer, 'findById', request.params.code)
        .fail (error) ->
          response.send 500, "Answer could not be found"
        .then (answer) ->
          if err? or !answer
            response.send 404, "answer not found"
          else
            Q.ninvoke(Question, 'findById', answer.question)
            .fail (error) ->
              response.send 500, "Question could not be found"
            .then (question) ->
              if !question?
                response.send 404, "Question not found"
                throw ""
              Q.ninvoke(File, 'findById', question.file)
              .fail (error) ->
                response.send 500, "File could not be found"
              .then (file) ->
                if !file?
                  return response.send 404, "File not found"
                if !canRead request, file.topicCode
                  return response.send 401, 'User doesnt have write permission'
                else
                  question.answers.addToSet answer
                  response.send question
                  question.save() 
        .done()
            

-------------------------------------------------------
Creates and saves a new comment to a question to the DB
-------------------------------------------------------

      app.post '/commentsQ', authenticated, (request, response) ->
        


        comment = new CommentQ
          _id: request.body._id
          owner: request.body.owner
          question: request.body.question
          text: request.body.text
        comment.save (err) ->
          if err?
            response.send err
          else    
            Q.ninvoke(Question, 'findById', request.body.question)
            .then (question) ->
              question.comments.addToSet comment
              question.modifiedTime = comment.timestamp
              question.save()   
            addEvent "Added", "CommentQ", comment._id      
            response.send comment

------------------------------------------------------------
Retrieves a comment from a question from the DB with id code
------------------------------------------------------------

      app.get '/commentsQ/:code', authenticated, (request, response) ->
        CommentQ.find _id: request.params.code, (err, docs) ->
          if err?
            response.send "not found"
          else
            response.send docs


-------------------------------------------------------
Creates and saves a new comment to an answer to the DB
-------------------------------------------------------

      app.post '/commentsA', authenticated, (request, response) ->
        comment = new CommentA
          _id: request.body._id
          owner: request.body.owner
          answer: request.body.answer
          text: request.body.text
        comment.save (err) ->
          if err?
            response.send err
          else
            Q.ninvoke(Answer, 'findById', request.body.answer)
            .then (answer) ->
              answer.comments.addToSet comment
              answer.save() 
            addEvent "Added", "CommentA", comment._id  
            response.send comment

------------------------------------------------------------
Retrieves a comment from an answer from the DB with id code
------------------------------------------------------------

      app.get '/commentsA/:code', authenticated, (request, response) ->
        CommentA.find _id: request.params.code, (err, docs) ->
          if err?
            response.send "not found"
          else
            response.send docs

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

