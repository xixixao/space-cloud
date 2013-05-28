This is the definition of our service, via a RESTful API.

    {Course, User, File, CommentA, CommentQ, Question, Answer} = require './model'

    module.exports = (app) ->

-------------------------------------------------------
Finds a user with a given login and returns the details
-------------------------------------------------------

      app.get '/users/:login', (request, response) ->
        User.find _id: request.params.login, (err, docs) ->
          if err?
            response.send err 
          else
            response.send docs

----------------------
Adds a user to the DB
----------------------

      app.post '/users', (request, response) ->
        user = new User
          name: request.body.name
          _id: request.body._id 
          password: request.body.password
        user.save (err) ->
          if err?
            response.send err 
          else
            response.send user

----------------
Login validation
----------------

      app.post '/login', (request, response) ->
        User.findOne _id: request.body._id, (err, user) ->
          if err?
            response.send err 
          else
            if user.password != request.body.password
              response.send "error"
            else
              response.send "ok" 

-----------------------
Adds a course to the DB
-----------------------

      app.post '/courses', (request, response) ->
        course = new Course
          name: request.body.name
          _id: request.body._id
        course.save (err) ->
          if err?
            response.send err 
          else
            response.send course

-------------------------------------------
Retrieves a course from the DB with id code
-------------------------------------------

      app.get '/courses/:code', (request, response) ->
        Course.find _id: request.params.code, (err, docs) ->
          if err?
            response.send "not found"
          else
          	response.send docs


---------------------------------------------------
Adds a list of courses to the user with login given
---------------------------------------------------

      app.post '/users/:login', (request, response) ->
        User.findOne _id: request.params.login, (err, user) ->
          if err?
            response.send err 
          else
            courses = request.body.courses
            #console.log courses
            for course in courses
              user.courses.addToSet course
            response.send user


--------------------------------------
Creates and saves a new file to the DB
--------------------------------------

      app.post '/files', (request, response) ->
        file = new File
          _id: request.body._id
          path: request.body.path
          name: request.body.name
          owner: request.body.owner
          course: request.body.course
        file.save (err) ->
          if err?
            response.send err 
          else
            response.send file

-------------------------------------------
Retrieves a file from the DB with id code
-------------------------------------------

      app.get '/files/:code', (request, response) ->
        File.find _id: request.params.code, (err, docs) ->
          if err?
            response.send "not found"
          else
            response.send docs   

------------------------------------------
Creates and saves a new question to the DB
------------------------------------------

      app.post '/questions', (request, response) ->
        question = new Question
          _id: request.body._id
          owner: request.body.owner
          filePosition: request.body.filePosition
          file: request.body.file
        question.save (err) ->
          if err?
            response.send err 
          else
            response.send question

-------------------------------------------
Retrieves a question from the DB with id code
-------------------------------------------

      app.get '/questions/:code', (request, response) ->
        Question.find _id: request.params.code, (err, docs) ->
          if err?
            response.send "not found"
          else
            response.send docs



------------------------------------------
Creates and saves a new answer to the DB
------------------------------------------

      app.post '/answers', (request, response) ->
        answer = new Answer
          _id: request.body._id
          owner: request.body.owner
          question: request.body.question
          rank: request.body.rank
        answer.save (err) ->
          if err?
            response.send err 
          else
            response.send answer

-------------------------------------------
Retrieves an answer from the DB with id code
-------------------------------------------

      app.get '/answers/:code', (request, response) ->
        Answer.find _id: request.params.code, (err, docs) ->
          if err?
            response.send "not found"
          else
            response.send docs


-------------------------------------------------------
Creates and saves a new comment to a question to the DB
-------------------------------------------------------

      app.post '/commentsQ', (request, response) ->
        comment = new CommentQ
          _id: request.body._id
          owner: request.body.owner   
          question: request.body.question   
        comment.save (err) ->
          if err?
            response.send err 
          else
            response.send comment

------------------------------------------------------------
Retrieves a comment from a question from the DB with id code
------------------------------------------------------------

      app.get '/commentsQ/:code', (request, response) ->
        CommentQ.find _id: request.params.code, (err, docs) ->
          if err?
            response.send "not found"
          else
            response.send docs


-------------------------------------------------------
Creates and saves a new comment to an answer to the DB
-------------------------------------------------------

      app.post '/commentsA', (request, response) ->
        comment = new CommentA
          _id: request.body._id
          owner: request.body.owner   
          answer: request.body.answer   
        comment.save (err) ->
          if err?
            response.send err 
          else
            response.send comment

------------------------------------------------------------
Retrieves a comment from an answer from the DB with id code
------------------------------------------------------------

      app.get '/commentsA/:code', (request, response) ->
        CommentA.find _id: request.params.code, (err, docs) ->
          if err?
            response.send "not found"
          else
            response.send docs            



