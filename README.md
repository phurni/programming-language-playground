# Programming Language Playground

This is a developer playground to gain knowledge and for experiments with computer programming language.

Initially inspired from https://www.destroyallsoftware.com/screencasts/catalog/a-compiler-from-scratch.

The first experiment is to create an **interpreter** for the language.

It is licensed under the [MIT License](http://opensource.org/licenses/MIT),
so feel free to fork it and run your own experiments.

## Project layout

* `doc`  
all the documentation describing the project.

* `example`  
code examples written in the _programming language_.

* `bin`  
binaries to run the different parts of the project.

* `src`  
source code of the implementation.

## Interpreter

The first experiment is the language interpreter, execute the `run` script to launch the interpreter,
pass the language source file as the first argument:

    bin/run example/fib.src

Under the `interpreter-v1` git tag, you'll find the first runnable version of the interpreter which consists
of the `Tokenizer`, `Parser` and `Interpreter`.

Under the `interpreter-v2` git tag, you'll find the same implementation as the `interpreter-v1` but with error
reports indicating the source filename and line number. It also includes tools to print the AbstractSyntaxTree
and to reformat the source code (reprints the source from the AST).

At this stage we have a working interpreter but we are fooling a real one. Why? Because we rely on the host
language (ruby) for handling the call stack and branching.  
In order to demonstrate this, we change the language behaviour a bit which will force a more realistic implementation.  
Here are the desired changes:
 - Add the `return` statement that will break out of the current function body.
 - Since we added the `return` statement, remove the fact that the last statement of a function is its return value.
 - In the interpreter implementation, don't rely on host's `if` and `while` to implement the guest language
   `if` and `while` (implement jumps).
