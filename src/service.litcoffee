This is the definition of our service, via a RESTful API.

    {Course, User, File, Comment, Question} = require './model'

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
        file.save (err) ->
          if err?
            response.send err 
          else
            response.send file

------------------------------------------
Creates and saves a new question to the DB
------------------------------------------

      app.post '/questions', (request, response) ->
        question = new Question
          _id: request.body._id
          owner: request.body.owner
          filePosition: request.body.filePosition
        question.save (err) ->
          if err?
            response.send err 
          else
            response.send question

-----------------------------------------
Creates and saves a new comment to the DB
-----------------------------------------

      app.post '/comments', (request, response) ->
        comment = new Comment
          _id: request.body._id
          owner: request.body.owner      
        comment.save (err) ->
          if err?
            response.send err 
          else
            response.send comment



