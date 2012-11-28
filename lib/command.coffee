{Mozrepl} = require './mozrepl'
{Mozfee} = require './mozfee'
clc      = require 'cli-color'
argv     = require('optimist')
    .boolean(['help', 'mozrepl-greeting', 'color', 'cs', 'js'])
    .string(['eval', 'host', 'port'])
    .alias(e: 'eval', h: 'help')
    .default('color', true)
    .default('mozrepl-greeting', false)
    .default('cs', false)
    .default('js', false)
    .argv

ableOptions = [
    'help', 'mozrepl-greeting', 'color', 'cs', 'js',
    'eval', 'host', 'port',
    'e', 'h'
]

unkownOptions = (argv)->
    k for own k of argv when !(k =='_' || k =='$0' || k in ableOptions)

usage = """
mozfee [OPTIONS...]

OPTIONS:
  --cs                     Uses CoffeeScript (default).
  --js                     Uses JavaScript.
  -e, --eval <code>        Eval code and exit.
  --host <host>            Host (default: localhost)
  --port <port>            Port (default: 4242)
  --[no-]mozrepl-greeting  Shows greeting from Mozrepl (defualt: false).
  --[no-]color             Colorize the output (default: true).
  -h, --help               Show this message.
"""

_error = if argv.color then clc.red.bold else (x)->x

run = ->
    unkowns = unkownOptions argv
    if unkowns.length > 0
        unkowns = unkowns.map (i)-> if i.length == 1 then "-#{i}" else "--#{i}"
        unkowns = unkowns.join ', '
        console.log _error("Unkown options : #{unkowns}\n")
        console.log usage
        process.exit 1
    if argv.help
        console.log usage
        return
    stdin  = process.stdin
    stdout = process.stdout
    mode = if argv.js then 'js' else 'cs'
    mozrepl = new Mozrepl argv.host, argv.port
    mozrepl.connect (err)->
        if err
            console.error _error("An error occured while connecting Mozrepl")
            console.error (err.stack || err.toString())
            process.exit 1
        if argv.eval
            code = argv.eval.toString()
            mozrepl.eval mode, code, (err, res)->
                if err
                    console.error (err.stack || err.toString())
                    process.exit 1
                console.log res
                process.exit 0    
        else
            options = {
                'mozrepl-greeting': argv['mozrepl-greeting']
                color: argv.color
                mode: mode
            }
            mozfee = new Mozfee mozrepl, stdin, stdout, options
            mozfee.run()

exports.run = run
