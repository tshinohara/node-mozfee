CoffeeScript = require 'coffee-script'
readline     = require 'readline'
{Mozrepl}    = require './mozrepl'
clc          = require 'cli-color'

empty_cli_color = ->
    f = (x)-> x    
    for k in ['black', 'red', 'green',
        'yellow', 'blue', 'magenta', 'cyan', 'white'
        'xterm', 'bold', 'italic','underline','inverse','strike']
        f[k] = f
    f
        
class Mozfee
    NORMAL = 'normal'
    CONTINUATION = 'continuation'
    EVALUATING = 'evaluating'

    DefaultOptioin = {
        color: true,
        'mozrepl-greeting': false,
    }
    constructor: (@mozrepl, @stdin, @stdout, @opt={}) ->
        @opt[k] ?= v for own k, v of DefaultOptioin
        @clc = if @opt.color then clc else empty_cli_color()
        
    preprocess: (buf) ->
        buf = buf.replace /(^|[\r\n]+)(\s*)##?(?:[^#\r\n][^\r\n]*|)($|[\r\n])/, "$1$2$3"
        buf = buf.replace /[\r\n]+$/, ""
        buf
        
    process: (buf) ->
        if @mode == CONTINUATION
            if buf.trim()            
                @backlog += "#{buf}\n"
                return on
            else
                code = @backlog
        else if @mode == NORMAL
            return on if !buf.trim() # do nothing on empty line
            if buf[buf.length - 1] == '\\'
                @backlog = "#{buf[...-1]}\n"
                @mode = CONTINUATION
                return on
            code = buf

        @mode = EVALUATING
        @mozrepl.evalCS code, (err, res)=>
            if err
                @rl.output.write @clc.yellow.bold("!! CoffeeScript Compile Error !!\n")
                @rl.output.write "#{err}\n"
            else
                @rl.output.write "#{res}\n"
            @mode = NORMAL
            @prompt()
        return no
        
    
    line: (buf)->
        if @process(@preprocess(buf))
            @prompt()

    normalPrompt: ->
        ['mozfee> ', 8]
    continuationPrompt: ->
        ['......> ', 8]
            
    prompt: ->
        switch @mode
            when NORMAL then s = @normalPrompt()
            when CONTINUATION then s = @continuationPrompt()
            else 
                throw "??"
        @rl.setPrompt s...
        @rl.prompt()
        
    run: ->
        @mode = NORMAL
        @backlog = ''
        
        @rl = readline.createInterface @stdin, @stdout
        @rl.on "line", (line)=> @line line
        @rl.on "pause", => @close()
        @rl.on "close", => @close()
        # Raw mode でも return, ctrl-j, ctrl-m は区別できない？
        @rl.input.on 'keypress', (char, key) =>
            return if !(key && key.ctrl && !key.meta && !key.shift && key.name == 'v')
            @rl.write '\\\n'            
        
        @mozrepl.on "close", =>
            @close()            
        @mozrepl.on "error", (e)=>
            @rl.output.write @clc.red.bold("!! Mozrepl Connection Error !!\n")
            @rl.output.write(e.stack || e.toString())
            @close()
             
        if @opt['mozrepl-greeting']
            @rl.output.write @clc.blue("#{@mozrepl.greeting}\n")
        @prompt()

    close: ->
        return if @_closing
        @_closing = true
        @mozrepl.close()
        @rl.close()
        @rl.output.write '\n'
        @rl.input.destroy()
        @closed = true

exports.Mozfee = Mozfee
