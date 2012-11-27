{Mozrepl} = require '../lib/mozrepl'
chai = require 'chai'

describe 'Mozrepl', ->
    describe '#connect()', ->
        m = null
        afterEach ->
            m.close()
            
        it 'should emit "connect" when connected to Mozprel', (done)->
            # 以下のこともテストに記述したいができていない
            #   他にイベントが置きていないこと
            #   一番最初のconnectイベントが発行されること
            #   状態がちゃんと遷移すること
            m = new Mozrepl
            m.connect()
            m.on 'connect', -> done()
            m.on 'error', -> throw "error"

        it 'should emit "error" with invalid host', (done)->
            m = new Mozrepl "don.t.exit"
            m.connect()
            m.on 'connect', -> throw "error"
            m.on 'error', -> done()
        it 'should emit "error" with invalid port', (done)->
            m = new Mozrepl "localhost", 9876
            m.connect()
            m.on 'connect', -> throw "error"
            m.on 'error', -> done()
