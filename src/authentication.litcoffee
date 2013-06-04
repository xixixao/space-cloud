We provide a strategy to authenticate user on login. The 'usernameField' and 'passwordField' must match the client request.

    passport = require("passport")
    LocalStrategy = require("passport-local").Strategy
    {User} = require './model'

    passport.use new LocalStrategy
      usernameField: '_id'
      passwordField: 'password'
    , (username, password, done) ->
      User.findById username, (err, user) ->
        if err?
          done err
        else if !user?
          done null, false, "User doesn't exist"
        else if user.password != password
          done null, false, "The password doesn't match the username"
        else
          done null, user, scope: 'all'

Information we store between requests.

    passport.serializeUser (user, done) ->
      done null, user._id

Retreaving the complete information.

    passport.deserializeUser (id, done) ->
      User.findById id, (err, user) ->
        done null, user

Restricting the user access to our API.

    restrict = (request, topic, permission) ->
      if !request.isAuthenticated()
        false
      else
        console.log "ser", request.user

Exporting the restricting functions.

    module.exports =
      canWrite: (request, topic) ->
        restrict request, topic, 'w'
      canRead: (request, topic) ->
        restrict request, topic, 'r'




