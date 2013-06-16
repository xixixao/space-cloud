Uses Q to fix mongoose's save to return a promise, implements https://github.com/LearnBoost/mongoose/issues/1431.

Doesn't work, no idea why.

    Q = require 'q'

    module.exports = (mongoose) ->

      #save = mongoose.Model::save
      #mongoose.Model::save = (cb) ->
      #  if cb?
      #    save.bind(this) cb
      #  else
      #    promise = Q.nfcall save.bind(this)
      #    promise
