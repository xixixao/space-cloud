This adds useful methods to the Q promises framework.

We get an instance of q, Q, to append methods to.

    module.exports = (Q) ->

thenEach is an instance method on promises returned by Q.all. It provides a shortcut for mapping over all the returned values.

      Q.makePromise::thenEach = (callback) ->
        Q.all @then (values) ->
          for value, i in values
            callback value, i

      Q.map = (values, callback) ->
        if Array.isArray values
          Q.all values.map callback
        else
          Q.all (callback v, k for k, v of values)

