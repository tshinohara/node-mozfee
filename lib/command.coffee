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

run = ->
    if argv.help
        console.log usage
        return
    stdin  = process.stdin
    stdout = process.stdout
    mozrepl = new Mozrepl argv.host, argv.port
    errCb = (e)->
        console.error clc.red.bold("Error occured while connecting Mozrepl")
        console.error(e.stack || e.toString())
    mozrepl.connect()        
    mozrepl.on 'connect', ->
        mozrepl.removeListener 'error', errCb
        mozfee = new Mozfee mozrepl, stdin, stdout, {
            'mozrepl-greeting': argv['mozrepl-greeting']
            color: argv.color
        }
        mozfee.run()
    mozrepl.on 'error', errCb

# Log an error.
#process.on 'uncaughtException', (err)->
#    console.error (err.stack or err.toString())

exports.run = run
