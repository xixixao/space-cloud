This is the definition of our service, via a RESTful API.

    Q = require 'q'
    (require './q-each') Q
    passport = require("passport")
    {Topic, User, File, CommentA, CommentQ, Question, Answer, Event} = require './model'
    {canRead, canWrite, authenticated} = require './authentication'
    path = require 'path'
    fs = require 'fs'
    os = require 'os'
    mkdirp = Q.denodeify require 'mkdirp'

    module.exports = (app) ->

-------------------------------------------------------
Finds a user with a given login and returns the details
-------------------------------------------------------

      app.get '/users/:username', authenticated, (request, response) ->
        usersFiles(request.params.username)
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


Serving files

      app.get '/files/:topicId/:fileName', authenticated, (request, response) ->
        {topicId, fileName} = request.params
        response.sendFile path.join(__dirname, "files/#{topicId}/#{fileName}"), (err) ->
          response.send 404, "File not found"



----------------------
Adds a user to the DB - aka SIGN UP
----------------------

      app.post '/users', (request, response) ->
        user = new User
          name: request.body.name
          _id: request.body._id
          password: request.body.password
          email: request.body.email
          facebook: request.body.facebook
          topics: request.body.topics
        user.save (err) ->
          if err?
            response.send err
          else
            response.send user

----------------
username validation
----------------

      fromArrayToMap = (idKey, array) ->
        result = {}
        for element in array
          result[element[idKey]] = element
        return result

      objectify = (topic) ->
        for file in topic.files
          for question in file.questions
            for answer in question.answers
              answer.comments = fromArrayToMap '_id', answer.comments
            question.comments = fromArrayToMap '_id', question.comments
            question.answers = fromArrayToMap '_id', question.answers
          file.questions = fromArrayToMap '_id', file.questions
        topic.files = fromArrayToMap '_id', topic.files
        topic

      getOwners = (user) ->
        fileOwners = Q.map user.topics, ({code}) ->
              Q.all [
                Q.ninvoke(
                  File
                  'populate'
                  code.files
                  path: 'owner'
                  select: '_id name'
                )
                Q.map code.files, (file) ->
                  Q.all [
                    Q.ninvoke(
                      Question
                      'populate'
                      file.questions
                      path: 'owner'
                      select: '_id name'
                    )
                    Q.map file.questions, (question) ->
                      Q.all [
                        Q.ninvoke(
                          CommentQ
                          'populate'
                          question.comments
                          path: 'owner'
                          select: '_id name'
                        )
                        Q.ninvoke(
                          Answer
                          'populate'
                          question.answers
                          path: 'owner'
                          select: '_id name'
                        )
                        Q.map question.answers, (answer) ->
                          Q.ninvoke(
                            CommentA
                            'populate'
                            answer.comments
                            path: 'owner'
                            select: '_id name'
                          )
                      ]
                  ]
              ]

      batchUserData = (request, response) ->
        topicCodes = request.user.topics
        Q.ninvoke(request.user, 'populate', 'topics.code')
        .then (user) ->
          getOwners(user)
          .then ->
            user
        .then (user) ->
          user = user.toObject()
          topics = {}
          for {code, permission} in user.topics
            code.permission = permission
            topics[code._id] = objectify code
          user.topics = topics
          getEvents(topicCodes)
          .then (events) ->
            user.events = events
            response.send user
          , (error) ->
            response.send error
          .done()
        .done()

      app.post '/login', passport.authenticate('local'), (request, response) ->
        batchUserData request, response

      app.get '/data', authenticated, (request, response) ->
        batchUserData request, response


Updating user details
---------------------

      app.post '/users/:username', authenticated, (request, response) ->
        if request.user._id != request.params.username
          return response.send 401, "User doesn't have permissions"
        User.update request.user,
          name: request.body.name
          password: request.body.password
          email: request.body.email
          facebook:request.body.facebook
        , (err, numberAffected, res) ->
          if err?
            response.send err
          else
            response.send request.user


-----------------------
Adds a topic to the DB
-----------------------

      app.post '/topics', (request, response) ->
        topic = new Topic
          name: request.body.name
          _id: request.body._id
          files: []
          types: request.body.types
        topic.save (err) ->
          if err?
            response.send err
          else
            response.send topic


-------------------------------------------
Retrieves a topic from the DB with id code
-------------------------------------------

      app.get '/topics/:code', authenticated, (request, response) ->
        getTopic(request.params.code)
        .then (topic) ->
          topic = topic.toObject()
          topic.permission = do ->
            for {code, permission} in request.user.topics when code is topic._id
              return permission
          response.send topic
        , (error) ->
          response.send error

      getTopic = (topicId) ->
        Q.ninvoke(Topic, 'findById', topicId)
        .then (topic) ->
          topic


---------------------------------------------------
Adds a list of topics to the user with login given
---------------------------------------------------

      # app.post '/users/:login', (request, response) ->
      #   User.findById request.params.login, (err, user) ->
      #     if err?
      #       response.send err
      #     else
      #       topics = request.body.topics
      #       for topic in topics
      #         user.topics.addToSet topic
      #       response.send user

------------------------
Adds an event to the DB
------------------------

      addEvent = (type, model, url, topicCode) ->
        event = new Event
          model: model
          type: type
          topicCode: topicCode
          url: url
        event.save (err) ->
          if err?
            return err
          else
            return event

------------------------------------
Retrieve all the events from the DB
------------------------------------

      app.get '/events', authenticated, (request, response) ->
        getEvents(request.user.topics)
        .then (events) ->
          response.send events
        , (error) ->
          response.send error

      getEvents = (topics) ->
        topicCodes = (code for {code} in topics)
        Q.ninvoke(
            Event.find({})
            .where('topicCode').in(topicCodes)
            .select('timestamp')
            .select('url')
            .select('type')
            .sort('-timestamp')
          , 'exec')


--------------------------------------
Creates and saves a new file to the topics list of files
--------------------------------------

      findTopic = ({topicId}) ->
        Q.ninvoke(Topic, 'findById', topicId)
        .then (topic) ->
          if !topic?
            throw [404, "topic not found #{topicId}"]
          topic

      app.get '/topics/:topicId/files', authenticated, (request, response) ->
        findTopic(request.params)
        .then (topic) ->
          response.send topic.files
        , (error) ->
          response.send error
        .done()

      app.post '/topics/:topicId/upload', authenticated, (request, response) ->
        response.send do ->
          files = if Array.isArray request.files.form.files[0]
            request.files.form.files[0]
          else
            request.files.form.files
          for file in files
            tmpName: path.basename file.path

      app.post '/topics/:topicId/files', authenticated, (request, response) ->
        if !canWrite request, request.params.topicId
          return response.send 401, 'User doesnt have write permission'

        topicDir = path.join __dirname, "files/#{request.params.topicId}"
        filePath = path.join(topicDir, request.body.name)
        fileSaved = mkdirp(topicDir)
        .then ->
          console.log path.join(app.get('uploadDir'), request.body.tmpName)
          console.log fs.statSync path.join app.get('uploadDir'), request.body.tmpName
          console.log fs.renameSync path.join(app.get('uploadDir'), request.body.tmpName),
            filePath

        file = new File
          _id: request.body._id
          path: filePath
          name: request.body.name
          owner: request.body.owner
          type: request.body.type
          date: request.body.date
        findTopic(request.params)
        .then (topic) ->
          topic.files.addToSet file
          addEvent(
            "Added"
            "File"
            "topics/#{request.params.topicId}/files/#{file._id}"
            request.params.topicId
          )
          Q.ninvoke(topic, 'save')
          .then ->
            response.send file
          , (error) ->
            throw error
            response.send 500, error
          .done()
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

--------------
Delete a file
--------------

      app.delete '/topics/:topicId/files/:fileId', authenticated, (request, response) ->
        findFile(request, request.params)
        .then ([topic, file]) ->
          topic.files.pull file
          response.send topic
        , (error) ->
          response.send error...
        .done()

---------------
Updates a file
---------------

      app.post '/topics/:topicId/files/:fileId', authenticated, (request, response) ->
        findFile(request, request.params)
        .then ([topic, file]) ->
          file.name = request.body.name
          file.path = request.body.path
          file.date = request.body.date
          Q.ninvoke(topic, 'save')
          .then ->
            addEvent(
              "Modified"
              "File"
              "topics/#{request.params.topicId}/files/#{request.params.fileId}"
              request.params.topicId
            )
            response.send file
          , (error) ->
            response.send error
          .done()
        .done()

------------------------------------------
Creates and saves a new question to the DB
------------------------------------------

      app.post '/topics/:topicId/files/:fileId/questions', authenticated, (request, response) ->
        question = new Question
          owner: request.body.owner
          filePosition: request.body.filePosition
          text: request.body.text
          createdTime: new Date()
        findFile(request, request.params)
        .then ([topic, file]) ->
          file.questions.addToSet question
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent(
            "Added"
            "Question"
            "topics/#{request.params.topicId}/files/#{request.params.fileId}/questions/#{question._id}"
            request.params.topicId
          )
          response.send question
        , (error) ->
          response.send error...
        .done()

------------------
Delete a question
------------------

      app.delete '/topics/:topicId/files/:fileId/questions/:questionId', authenticated, (request, response) ->
        findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          file.questions.pull question
          response.send file
        , (error) ->
          response.send error...
        .done()

-------------------
Updates a question
-------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId', authenticated, (request, response) ->
        findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          question.text = request.body.text
          question.modifiedQuestionTime = new Date() 
          Q.ninvoke(topic, 'save')
          .then ->
            addEvent(
              "Modified"
              "Question"
              "topics/#{request.params.topicId}/files/#{request.params.fileId}/questions/#{question._id}"
              request.params.topicId
            )
            response.send question
          , (error) ->
            response.send error
          .done()
        .done()

-------------------------------------------
Retrieves a question from the DB with id code
-------------------------------------------

      findQuestion = (request, {topicId, fileId, questionId}) ->
        findFile(request, {topicId, fileId})
        .then ([topic, file]) ->
          question = file.questions.id questionId
          [topic, file, question]

      app.get '/topics/:topicId/files/:fileId/questions', authenticated, (request, response) ->
        findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          response.send file.questions
        , (error) ->
          response.send error...
        .done()

      app.get '/topics/:topicId/files/:fileId/questions/:questionId', authenticated, (request, response) ->
        findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          populateOwner(Question, question)
          .then (question) ->
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
              owner: request.body.owner
              rank: request.body.rank
              text: request.body.text
          question.answers.addToSet answer
          Q.ninvoke(topic, 'save')
          .then ->
            addEvent(
              "Added"
              "Answer"
              "topics/#{topic._id}/files/#{file._id}/questions/#{question._id}/answers/#{answer._id}"
              request.params.topicId
            )
            response.send answer
        , (error) ->
          response.send error...
        .done()

------------------
Delete an answer
------------------

      # app.delete '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId', authenticated, (request, response) ->
      #   findAnswer(request, request.params)
      #   .then ([topic, file, question, answer]) ->
      #     file.questions.answers.pull question
      #     response.send file
      #   , (error) ->
      #     response.send error...
      #   .done()

-------------------
Updates an answer
-------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId', authenticated, (request, response) ->
        findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          answer.text = request.body.text
          question.modifiedTime = new Date() 
          Q.ninvoke(topic, 'save')
          .then ->
            addEvent(
              "Modified"
              "Answer"
              "topics/#{topic._id}/files/#{file._id}/questions/#{question._id}/answers/#{answer._id}"
              request.params.topicId
            )
            response.send answer
          , (error) ->
            response.send error
          .done()
        .done()

-------------------------------------------
Retrieves an answer from the DB with id code
-------------------------------------------

      findAnswer = (request, {topicId, fileId, questionId, answerId}) ->
        findQuestion(request, {topicId, fileId, questionId})
        .then ([topic, file, question]) ->
          answer = question.answers.id answerId
          [topic, file, question, answer]

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/answers', authenticated, (request, response) ->
        findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          response.send question.answers
        , (error) ->
          response.send error...
        .done()

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId', authenticated, (request, response) ->
        findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          populateOwner(Answer, answer)
          .then (answer) ->
            response.send answer
        , (error) ->
          response.send error...
        .done()


-------------------------------------------------------
Creates and saves a new comment to a question to the DB
-------------------------------------------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/comments', authenticated, (request, response) ->
        comment = new CommentQ
          owner: request.body.owner
          text: request.body.text
        findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          question.comments.addToSet comment
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent(
            "Added"
            "CommentQ"
            "topics/#{request.params.topicId}/files/#{request.params.fileId}/questions/#{request.params.questionId}/comments/#{comment._id}"
            request.params.topicId
          )
          response.send comment
        , (error) ->
          response.send error
        .done()

--------------------------------
Updates a comment to a question
--------------------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/comments/:commentId', authenticated, (request, response) ->
        findCommentQ(request, request.params)
        .then ([topic, file, question, comment]) ->
          comment.text = request.body.text
          question.modifiedTime = new Date() 
          Q.ninvoke(topic, 'save')
          .then ->
            addEvent(
              "Modified"
              "CommentQ"
              "topics/#{request.params.topicId}/files/#{request.params.fileId}/questions/#{request.params.questionId}/comments/#{comment._id}"
              request.params.topicId
            )
            response.send comment
          , (error) ->
            response.send error
          .done()
        .done()

------------------------------------------------------------
Retrieves a comment from a question from the DB with id code
------------------------------------------------------------

      findCommentQ = (request, {topicId, fileId, questionId, commentId}) ->
        findQuestion(request, {topicId, fileId, questionId})
        .then ([topic, file, question]) ->
          comment = question.comments.id commentId
          [topic, file, question, comment]

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/comments', authenticated, (request, response) ->
        findCommentQ(request, request.params)
        .then ([topic, file, question, comment]) ->
          response.send question.comments
        , (error) ->
          response.send error...
        .done()

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/comments/:commentId', authenticated, (request, response) ->
        findCommentQ(request, request.params)
        .then ([topic, file, question, comment]) ->
          populateOwner(CommentQ, comment)
          .then (comment) ->
            response.send comment
        , (error) ->
          response.send error...
        .done()


-------------------------------------------------------
Creates and saves a new comment to an answer to the DB
-------------------------------------------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/comments', authenticated, (request, response) ->
        comment = new CommentA
          owner: request.body.owner
          text: request.body.text
        findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          answer.comments.addToSet comment
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent(
            "Added"
            "CommentA"
            "topics/#{request.params.topicId}/files/#{request.params.fileId}/questions/#{request.params.questionId}/answers/#{request.params.answerId}/comments/#{comment._id}"
            request.params.topicId
          )
          response.send comment
        , (error) ->
          response.send error...
        .done()

--------------------------------
Updates a comment to an answer
--------------------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/comments/:commentId', authenticated, (request, response) ->
        findCommentA(request, request.params)
        .then ([topic, file, question, answer, comment]) ->
          comment.text = request.body.text
          question.modifiedTime = new Date() 
          Q.ninvoke(topic, 'save')
          .then ->
            addEvent(
              "Modified"
              "CommentA"
              "topics/#{request.params.topicId}/files/#{request.params.fileId}/questions/#{request.params.questionId}/answers/#{request.params.answerId}/comments/#{comment._id}"
              request.params.topicId
            )
            response.send comment
          , (error) ->
            response.send error
          .done()
        .done()

------------------------------------------------------------
Retrieves a comment from an answer from the DB with id code
------------------------------------------------------------

      populateOwner = (model, type) ->
        Q.ninvoke(
            model
            'populate'
            type
            path: 'owner'
            select: '_id name'
          )

      findCommentA = (request, {topicId, fileId, questionId, answerId, commentId}) ->
        findAnswer(request, {topicId, fileId, questionId, answerId})
        .then ([topic, file, question, answer]) ->
          comment = answer.comments.id commentId
          [topic, file, question, answer, comment]

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/comments', authenticated, (request, response) ->
        findCommentA(request, request.params)
        .then ([topic, file, question, answer, comment]) ->
          response.send answer.comments
        , (error) ->
          response.send error...
        .done()

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/comments/:commentId', authenticated, (request, response) ->
        findCommentA(request, request.params)
        .then ([topic, file, question, answer, comment]) ->
          populateOwner(CommentA, comment)
          .then (comment) ->
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

Ranking

      getAnswer = (request, requestParams) ->
        findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          answer

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/voteUp/:username', authenticated, (request, response) ->
        findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          answer.votesFor.addToSet request.params.username
          Q.ninvoke(topic, 'save')
        .then ->
          response.send "voted for"
        , (error) ->
          response.send error...
        .done()

      app.get '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/voteUp', authenticated, (request, response) ->
        getAnswer(request, request.params)
        .then (answer) ->
          response.send answer.votesFor

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/voteDown/:username', authenticated, (request, response) ->
        findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          answer.votesFor.pull request.params.username
          Q.ninvoke(topic, 'save')
        .then ->
          response.send "voted against"
        , (error) ->
          response.send error...
        .done()

      # app.get '/topics/:topicId/files/:fileId/questions/:questionId/answers/:answerId/voteDown', authenticated, (request, response) ->
      #   getAnswer(request, request.params)
      #   .then (answer) ->
      #     response.send answer.votesFor



