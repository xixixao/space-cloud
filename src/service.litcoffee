This is the definition of our service, via a RESTful API.

    Q = require 'q'
    (require './q-each') Q
    passport = require("passport")
    {Topic, User, File, CommentA, CommentQ, Question, Answer, Event} = Model = require './model'
    {canRead, canWrite, authenticated} = require './authentication'
    path = require 'path'
    fs = require 'fs'
    os = require 'os'
    mkdirp = Q.denodeify require 'mkdirp'

    module.exports = (app) ->

-------------------------------------------------------
Finds a user with a given login and returns the details
-------------------------------------------------------

FOLLOWING IS WRONG:

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
        events = getEvents(topicCodes)
        topics = Q.ninvoke(request.user, 'populate', 'topics.code')
        .then (user) ->
          Q.map user.topics, ({code, permission}) ->
            Q.map code.files, (file) ->
              file.shallow().then (file) ->
                file.url = topicId: code._id, fileId: file._id
                file
            .then (files) ->
              code.shallow().then (topic) ->
                topic.permission = permission
                topic.files = files
                topic
        Q.all([events, topics])
        .then ([events, topics]) ->
          user = request.user.toObject()
          user.topics = topics
          user.events = events
          response.send user
        , (error) ->
          response.send error
        .done()

data is an alias for /login, when the user is already authenticated. They should return the same data, namely the user

  - user.events, list of all relevant events
  - user.topics, list of all his topics with permissions assigned to them
  - user.files, list of all accessible files, for quick search

Here we go (stupid markdown needs this line).

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

      addEvent = (type, model, topicCode, url) ->
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
          response.send 500, error
        .done()

      getEvents = (topics) ->
        topicCodes = (code for {code} in topics)
        query = Event.find({})
        .where('topicCode').in(topicCodes)
        .sort('-timestamp')
        .limit(100)
        Q.ninvoke(query, 'exec')
        .then (events) ->
          Q.map events, (event, i) ->
            event = event.toObject()
            event.url.topicId = event.topicCode
            Model.named(event.model).findShallowByURL(event.url)
            .then (target) ->
              event.target = target
              event


Retrieve questions related to current user

      app.get '/questions', authenticated, (request, response) ->
        topicCodes = (code for {code} in request.user.topics)
        query = Topic.find({})
        .where('_id').in(topicCodes)
        .select('name files._id files.name files.questions')
        .sort('-modifiedTime')
        .limit(100)
        all = []
        Q.ninvoke(query, 'exec')
        .then (topics) ->
          Q.map topics, (topic) ->
            t = topic.shallow()
            Q.map topic.files, (file) ->
              f = file.shallow()
              Q.map file.questions, (question) ->
                Q.all([question.shallow(), f, t])
                .then ([question, file, topic]) ->
                  question.file = file
                  question.topic = topic
                  question.url = topicId: topic._id, fileId: file._id, questionId: question._id
                  all.push question
        .then ->
          response.send all
        , (error) ->
          throw error
          response.send 500, error
        .done()



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
          owner: request.user._id
          type: request.body.type
          date: request.body.date
        findTopic(request.params)
        .then (topic) ->
          topic.files.addToSet file
          addEvent "Added", "File", request.params.topicId,
            fileId: file._id
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
            addEvent "Modified", "File", request.params.topicId,
              fileId: request.params.fileId
            response.send file
          , (error) ->
            response.send error
          .done()
        .done()

------------------------------------------
Creates and saves a new question to the DB
------------------------------------------

      shallowUser = (request) ->
        {_id, name} = request.user
        return {_id, name}

      app.post '/topics/:topicId/files/:fileId/questions', authenticated, (request, response) ->
        question = new Question
          owner: request.user._id
          position: request.body.position
          text: request.body.text
          createdTime: new Date()
          modifiedTime: new Date()
        Q.ninvoke(question, 'generateId')
        .then ->
          findFile(request, request.params)
        .then ([topic, file]) ->
          file.questions.addToSet question
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent "Added", "Question", request.params.topicId,
            fileId: request.params.fileId
            questionId: question._id
          question.owner = shallowUser request
          response.send question
        , (error) ->
          throw error
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
            addEvent "Modified", "Question", request.params.topicId,
              fileId: request.params.fileId
              questionId: question._id
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
          Q.map file.questions, (question) ->
            question.shallow()
        .then (questions) ->
          response.send questions
        , (error) ->
          response.send error...
        .done()

      app.get '/topics/:topicId/files/:fileId/questions/:questionId', authenticated, (request, response) ->
        findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          populateOwner(Question, 'owner comments.owner answers.owner answers.comments.owner', question)
        .then (question) ->
          response.send question
        , (error) ->
          response.send error...
        .done()


------------------------------------------
Creates and saves a new answer to the DB
------------------------------------------

      app.post '/topics/:topicId/files/:fileId/questions/:questionId/answers', authenticated, (request, response) ->
        answer = new Answer
            owner: request.user._id
            rank: request.body.rank
            text: request.body.text
        answer.priority = if canWrite request, request.params.topicId then 1 else 0
        Q.ninvoke(answer, 'generateId')
        .then ->
          findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          question.answers.addToSet answer
          question.modifiedTime = new Date()
          Q.ninvoke(topic, 'save')
          .then ->
            addEvent "Added", "Answer", request.params.topicId,
              fileId: request.params.fileId
              questionId: request.params.questionId
              answerId: answer._id
            answer.owner = shallowUser request
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
            addEvent "Modified", "Answer", request.params.topicId,
              fileId: request.params.fileId
              questionId: request.params.questionId
              answerId: answer._id
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
          populateOwner(Answer, 'owner comments.owner', answer)
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
          owner: request.user._id
          text: request.body.text
        Q.ninvoke(comment, 'generateId')
        .then ->
          findQuestion(request, request.params)
        .then ([topic, file, question]) ->
          question.comments.addToSet comment
          question.modifiedTime = new Date()
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent "Added", "CommentQ", request.params.topicId,
            fileId: request.params.fileId
            questionId: request.params.questionId
            commentId: comment._id
          comment.owner = shallowUser request
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
            addEvent "Modified", "CommentQ", request.params.topicId,
              fileId: request.params.fileId
              questionId: request.params.questionId
              commentId: comment._id
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
          populateOwner(CommentQ, 'owner', comment)
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
          owner: request.user._id
          text: request.body.text
        Q.ninvoke(comment, 'generateId')
        .then ->
          findAnswer(request, request.params)
        .then ([topic, file, question, answer]) ->
          answer.comments.addToSet comment
          question.modifiedTime = new Date()
          Q.ninvoke(topic, 'save')
        .then ->
          addEvent "Added", "CommentA", request.params.topicId,
            fileId: request.params.fileId
            questionId: request.params.questionId
            answerId: request.params.answerId
            commentId: comment._id
          comment.owner = shallowUser request
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
            addEvent "Modified", "CommentA", request.params.topicId,
              fileId: request.params.fileId
              questionId: request.params.questionId
              answerId: request.params.answerId
              commentId: comment._id
            response.send comment
          , (error) ->
            response.send error
          .done()
        .done()

------------------------------------------------------------
Retrieves a comment from an answer from the DB with id code
------------------------------------------------------------

      populateOwner = (model, path, type) ->
        Q.ninvoke(
            model
            'populate'
            type
            path: path
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
          populateOwner(CommentA, 'owner', comment)
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



