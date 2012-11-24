CoffeeScript = require 'coffee-script'
readline     = require 'readline'
{Mozrepl}    = require './mozrepl'
clc          = require 'cli-color'


class Mozfee
    NORMAL = 'normal'
    CONTINUATION = 'continuation'
    MOZREPLING = 'mozrepling'
    
    constructor: (@stdin, @stdout, @enableColours=yes) ->
        @mozrepl = new Mozrepl
        @rl = readline.createInterface @stdin, @stdout
        @rl.on "line", (line)=> @line line
        @rl.on "pause", => @rl.close()
        @rl.on "close",  =>
            @close()
        # Raw mode でも return, ctrl-j, ctrl-m は区別できない？
        @rl.input.on 'keypress', (char, key) =>
            return if !(key && key.ctrl && !key.meta && !key.shift && key.name == 'v')
            @rl.write '\\\n'            
        @mode = NORMAL
        @backlog = ''

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

        try
            jscode = CoffeeScript.compile code, bare: true
        catch e
            @rl.output.write clc.yellow("Compile Error\n")
            @rl.output.write "#{e}\n"
            @mode = NORMAL
            return on
            
        @mode = MOZREPLING
        @mozrepl.eval jscode, (r)=>
            @rl.output.write "#{r}\n"
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
        @mozrepl.connect()
        @mozrepl.on "connect", =>
            # Mozrepl が接続を切ったらreplを落す
            @mozrepl.on "close", =>
                @close()
            @rl.output.write clc.blue("#{@mozrepl.greeting}\n")
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
