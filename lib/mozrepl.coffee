EventEmitter = require('events').EventEmitter
CoffeeScript = require 'coffee-script'
net = require 'net'

#
class Mozrepl extends EventEmitter
    HOST = 'localhost'
    PORT = 4242

    CONNECTING = 1
    INITIALIZING = 2
    CONNECTED = 3
    CLOSING = 4
    CLOSED = 5
    ERROR = 6

    constructor: (@host = HOST, @port = PORT)->
        @evalMode = 'js'
        @state = null
        @lines = []
        @buffer = ''
        @repl_name = null
        @request = null
        @pending_requests = []

    #Mozreplからの返った値をパーズ
    parseResult: (str) ->
        str

    check: ->
        if /^repl\d*>\s*$/.test @buffer
            str = @lines.join '\n'
            if @repl_name
                if @request
                    result = @parseResult str
                    @request.cb null, result if @request.cb
                    @request = null
                    @serve()    # リクエストがあれば引続き
                else
                    # error?
                    @emit "error", str
            else
                @greeting = str
                @setReplName @buffer
                @state = CONNECTED
                @bare_eval "#{@repl_name}.setenv('inputMode', 'multiline')", =>
                    @connectCb() if @connectCb
                    @emit "connect"
                    @serve()
                @serve()
            @lines = []
            @buffer = ''
            
    setReplName: (prompt) ->
        @repl_name = /^(repl\d*)>\s*$/.exec(prompt)[1]

    serve: ->
        if @state == CONNECTED && !@request && @pending_requests.length > 0
            @request = @pending_requests.shift()
            @con.write @request.code, =>
                @emit "_sended", @request.code # for debug

    # Only use for initializing repl
    bare_eval: (code, cb) ->
        code = code + "\n"
        @pending_requests.push code: code, cb: cb
        @serve()            
        
    evalJS: (code, cb) ->
        # ! Needs {(#{code})} . Just {#{code}} doesn't work with object literal.
        # 逆に 3; みたいなコードが来ると {(3;)}ではエラーになる
        # オブジェクトリテラルの時のみに(..)で囲む
        code = "try {#{code}} catch(e) {e}\n--end-remote-input\n"
        @pending_requests.push code: code, cb: cb
        @serve()

    evalCS: (csCode, cb) ->
        try
            jsCode = CoffeeScript.compile csCode, bare: true
        catch e
            # Async callbacks must be always async
            process.nextTick -> cb(e)
            return
        @eval jsCode, cb

    eval: (mode, code, cb) ->
        if arguments.length == 2
            cb = code
            code = mode
            mode = @evalMode
        switch mode
            when 'cs' then @evalCS code, cb
            when 'js' then @evalJS code, cb

    replJS: (command, cb) ->
        @evalJS "#{@repl_name}.#{command}", cb

    onData: (s)->
        @emit "_received", s # for debug
        frags = s.split "\n"
        if frags.length == 0
            return
        if frags.length == 1
            @buffer += frags[0]
        else
            last  = frags.pop()
            first = frags.shift()
            @lines.push(@buffer + first)
            @lines = @lines.concat frags
            @buffer = last
        @check()
        
    connect: (cb)->
        @state = CONNECTING
        @connectCb = cb
        @con = net.createConnection(@port, @host)
        @con.setEncoding 'utf8'
        @con.on "connect",  =>
            @state = INITIALIZING
            @con.on "data",  (s) => @onData s
            @con.on "end",   (e) => @close()
            @con.on "close", (e) => @close()
        @con.on "error", (e) =>
            if @connectCb && @state in [CONNECTING, INITIALIZING]
                cb(e)
            @emit "error", e
            @state = ERROR

    close: ->
        return if @state == CLOSING
        @state = CLOSING
        @con.end()
        # or @con.destroy() ???
        @emit "close"
        @state = CLOSED
        
exports.Mozrepl = Mozrepl
