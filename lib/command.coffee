{Mozfee}    = require './mozfee'

run = ->
    stdin  = process.stdin
    stdout = process.stdout
    mozfee = new Mozfee stdin, stdout
    mozfee.run()

# Log an error.
process.on 'uncaughtException', (err)->
    console.error (err.stack or err.toString())

exports.run = run
