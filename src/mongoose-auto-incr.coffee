mongoose = require 'mongoose'
counter_name = null
db = null

exports.loadAutoIncr = (database, options) ->
  options = options || {}
  counter_name = options.counterName || '__Counter__'

  db = database

  schema = new mongoose.Schema
    field:
      type: String
      unique: true
    c:
      type: Number
      default: 0

  mongoose.model(counter_name, schema)

exports.model = (modelName, schema) ->
  # Check for required options
  if !modelName
    throw new Error('Missing required parameter: modelName')

  model_name = modelName.toLowerCase()
  Counter = db.model counter_name

  schema.add
    _id: Number

  schema.pre 'save', (next) ->
    Counter.collection.findAndModify
      field: model_name, [], {$inc: {c: 1}}
        new: true
        upsert: true
      , (err, doc) =>
        count = doc.c
        if err
          next(err)
        else
          this._id = count
          next()

  mongoose.model(modelName, schema)

