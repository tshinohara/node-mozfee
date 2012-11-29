Mozfee
======

[MozRepl](https://github.com/bard/mozrepl) + [CoffeeScript](http://coffeescript.org/) + α.

MozRepl is a Firefox addon that enables you to access inside Firefox from outside (e.g. terminal).
Though it is awesome, it lacks features like CoffeeScript support, command line eval and so on.

Mozfee aims to cover these features.

Install
-------

Mozfee is installed using [Node](http://nodejs.org/) and [npm](http://npmjs.org/).

    npm install mozfee -g

Usage
-----

`mozfee` command without any options will invoke a MozRepl REPL with CoffeeScript.

    $ mozfee
    mozfee> repl.enter content
    [object Window] - {window: {...}, document: {...}, InstallTrigger: {...}, location: {...}, sh_requests: {...}, sh_isEmailAddress: function() {...}, sh_setHref: function() {...}, ...}
    mozfee> document.title
    "mozfee"

### How to end the REPL

* repl.quit() or
* ctrl-c/ctrl-d

### Writing multiline code

Ending the line with '\' will enable continuation mode. 
Continuation mode continues untill you pass an empty line.

    mozfee> f = (x)-> \
    ......>     console.log x
    ......>     x
    ......>
    function() {...}
    mozfee>

### Options
Lookup `mozfee --help` for options you can use.

    mozfee [OPTIONS...]
    
    OPTIONS:
      -c, --content            repl.enter(content) before executing.
      --cs                     Uses CoffeeScript (default).
      --js                     Uses JavaScript.
      -e, --eval <code>        Eval code and exit.
      --host <host>            Host (default: localhost)
      --port <port>            Port (default: 4242)
      --[no-]mozrepl-greeting  Shows greeting from Mozrepl (defualt: false).
      --[no-]color             Colorize the output (default: true).
      -h, --help               Show this message.

License
-------
(The MIT License)

Copyright (c) 2012 Takenari Shinohara

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
