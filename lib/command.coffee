{Mozrepl} = require './mozrepl'
{Mozfee} = require './mozfee'
clc      = require 'cli-color'
argv     = require('optimist')
    .boolean(['help', 'mozrepl-greeting', 'color'])
    .default('color', true)
    .default('mozrepl-greeting', false)
    .argv

usage = """
mozfee [OPTIONS]

OPTIONS:
  --host <host>            Host (default: localhost)
  --port <port>            Port (default: 4242)
  --[no-]mozrepl-greeting  Shows greeting from Mozrepl (defualt: false).
  --[no-]color             Colorize the output (default: true).
  --help                   Show this message.
"""

_error = if argv.color then clc.red.bold else (x)->x

run = ->
    if argv.help
        console.log usage
        return
    stdin  = process.stdin
    stdout = process.stdout
    options = {
        'mozrepl-greeting': argv['mozrepl-greeting']
        color: argv.color
    }
    mozrepl = new Mozrepl argv.host, argv.port
    mozrepl.connect (err)->
        if err
            console.error _error("An error occured while connecting Mozrepl")
            console.error (err.stack || err.toString())
            process.exit 1            
        mozfee = new Mozfee mozrepl, stdin, stdout, options
        mozfee.run()

exports.run = run
