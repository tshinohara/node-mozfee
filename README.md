Mozfee
======

Mozrepl + CoffeeScript. 

Install
-------

Mozfee is installed using [Node](http://nodejs.org/) and [npm](http://npmjs.org/).

    npm install mozfee -g

Usage
-----

Run mozfee command.

    $ mozfee
    
      ... Greetings from Mozrepl ...
      
    mozfee> 

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

You can't pass any options currently. 
