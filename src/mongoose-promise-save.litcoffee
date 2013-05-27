Uses Q to fix mongoose's save to return a promise, implements https://github.com/LearnBoost/mongoose/issues/1431.

    Q = require 'q'

    module.exports = (mongoose) ->

      save = mongoose.Model::save
      mongoose.Model::save = (cb) ->
        if cb?
          save.bind(this) cb
        else
          Q.nfcall save.bind(this)