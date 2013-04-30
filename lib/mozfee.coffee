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
        mode: 'cs'
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
        @mozrepl.eval @opt.mode, code, (err, res)=>
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
        mode = @opt.mode
        repl_name = @mozrepl.repl_name
        ["#{mode}-#{repl_name}> ", 3 + mode.length + repl_name.length]
    continuationPrompt: ->
        dotLength = 1 + @opt.mode.length + @mozrepl.repl_name.length
        [('.' for _ in [1..dotLength]).join('') + '> ', dotLength + 2]
            
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
        # Do not close on "pause" event.
        # TabCompleter (pressing TAB) emits "pause" event.
        # @rl.on "pause", => @close()
        @rl.on "close", => @close()
        # Raw mode でも return, ctrl-j, ctrl-m は区別できない？
        @rl.input.on 'keypress', (char, key) =>
            ctrl_v = (key && key.ctrl && !key.meta && !key.shift && key.name == 'v')
            return unless ctrl_v
            if @mode is NORMAL
              @rl.write '\\\n'
            else if @mode is CONTINUATION
              @rl.write '\n'        

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
