{Mozrepl} = require '../lib/mozrepl'
chai = require 'chai'
chai.should()

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

    describe '#eval()', ->
        mozrepl = null
        before (done)->
            mozrepl = new Mozrepl
            mozrepl.connect()
            mozrepl.on 'connect', -> done()
            mozrepl.on 'error', -> done(true)
        after ->
            mozrepl.close()

        tests = [
            ['1','1']
            ['1+1', '2']
            ['1 \n + 1', '2']
        ]
        # 汚ない。。。
        # CoffeeScript の for 式に問題があるがいする。。
        for [code, expected_result] in tests
            ((code, expected_result)->
                it "should eval JS code '#{code}' to '#{expected_result}'", (done)->
                    mozrepl.eval code, (err, result)->
                        result.should.be.string expected_result
                        done()
            )(code, expected_result)

    describe '#evalCS()', ->
        mozrepl = null
        before (done)->
            mozrepl = new Mozrepl
            mozrepl.connect()
            mozrepl.on 'connect', -> done()
            mozrepl.on 'error', -> done(true)
        after ->
            mozrepl.close()

        tests = [
            ['1','1']
            ['1+1', '2']
            ['"hoge".charAt 0', '"h"']
        ]
        # 汚ない。。。
        # CoffeeScript の for 式に問題があるがいする。。
        for [code, expected_result] in tests
            ((code, expected_result)->
                it "should eval CS code '#{code}' to '#{expected_result}'", (done)->
                    mozrepl.evalCS code, (err, result)->
                        result.should.be.string expected_result
                        done()
            )(code, expected_result)
