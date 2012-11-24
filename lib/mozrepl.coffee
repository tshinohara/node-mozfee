net = require 'net'
util = require 'util'
EventEmitter = require('events').EventEmitter

#
class Mozrepl extends EventEmitter
    HOST = 'localhost'
    PORT = 4242

    INITAIAL = 0
    CONNECTING = 1
    CONNECTED = 2
    CLOSING = 3
    CLOSED = 4

    constructor: (@host = HOST, @port = PORT)->
        @state = INITAIAL
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
                    @request.cb result if @request.cb
                    @request = null
                    @serve()    # リクエストがあれば引続き
                else
                    # error?
                    @emit "error", str
            else
                @greeting = str
                @setReplName @buffer
                # initalize
                @state = CONNECTED
                # multiline mode
                @bare_eval "#{@repl_name}.setenv('inputMode', 'multiline')", =>
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
        
    eval: (code, cb) ->
        # ! Needs {(#{code})} . Just {#{code}} doesn't work with object literal.
        # 逆に 3; みたいなコードが来ると {(3;)}ではエラーになる
        # オブジェクトリテラルの時のみに(..)で囲む
        code = "try {#{code}} catch(e) {e}\n--end-remote-input\n"
        @pending_requests.push code: code, cb: cb
        @serve()

    repl: (command, cb) ->
        @eval "#{@repl_name}.#{command}", cb
        
    connect: ->
        @state = CONNECTING
        @con = net.createConnection(PORT, HOST)
        @con.setEncoding 'utf8'
        @con.on "connect",  =>
            @con.on "data", (s) =>
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
            @con.on "error", (e) => @close()
            @con.on "end", (e) => @close()
            @con.on "close", (e) => @close()

    close: ->
        return if @state == CLOSING
        @state = CLOSING
        @con.end()
        # or @con.destroy() ???
        @emit "close"
        @state = CLOSED
        
#
if require.main == module
  m = new Mozrepl
  m.connect()
  m.on "connect", ->
      console.log "connected"
      tests = [
          "1"
          "1+2"
          "{ a: 2 }",
          "ffff",
      ]
      for code in tests
          m.eval code, (r)-> console.log "result '#{code}' = #{r}"
      m.repl "enter(content)"
      m.eval "document.title", (r) -> console.log r
      m.close()

  # m.on "_sended", (s)-> console.log "_sended : #{s}"
  # m.on "_received", (s)-> console.log "_received : #{s}"

exports.Mozrepl = Mozrepl
