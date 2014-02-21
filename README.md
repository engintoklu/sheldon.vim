## Sheldon.vim

Sheldon.vim is a shell-like command interpreter written in Vimscript.
It is intended to allow the user to do simple shell operations without having to leave Vim.
This project was inspired by eshell of GNU Emacs, but note that Sheldon.vim has its own syntax.

## Vim commands to activate Sheldon.vim

To create and switch to a Sheldon buffer:

    :Sheldon

To create a Sheldon buffer and show it in a new window:

    :SheldonSplit

## How to use Sheldon.vim
When you are in a Sheldon buffer, switch to INSERT mode, and write your command.
When you hit ENTER, your command will be executed.
You don't have to be at the last line to execute a command.
You can go to previous lines, edit them, and hit ENTER in INSERT mode to execute that line.
This feature makes the entire Sheldon buffer your editable command history.
The classical command line history interface is also available:
in INSERT mode, you can use Ctrl+Up and Ctrl+Down to browse your command history.

To quit Sheldon, you can simply destroy the buffer by switching to NORMAL mode
or in INSERT mode, hit Ctrl+d.

Sheldon can understand the outputs of gcc and python.
For example, when you execute the following line in Sheldon:

    gcc -o myprogram myprogram.c

Let us now assume that you receive an error message from gcc like this:

    myprogram.c:12:4: some error message here

You can go over that error message line, switch to NORMAL mode, and press ENTER.
When you do that, Sheldon will open a buffer for myprogram.c, and bring you to the erroneous line.
Also, if you have multiple windows open, and you want to see that erroneous line of myprogram.c in the previous window,
you can go over the error message line, and press TAB in NORMAL mode.

## Syntax

The simple syntax is:

    command argument1 argument2 ... argumentN

For giving an argument which includes space, there are three types of quotations:

    command "one argument"
    command 'one argument'
    command {one argument}

As an alternative to quotation, you can use the backslash escape character:

    command one\ argument

The variable expansion is as follows:

    echo %PATH%

Note that the quotation by using the double quote character (") is a weak quotation. This means that the backslash escape character and the variable expansion work also within this weak quotation. For example, assuming that `MYVAR` is a variable which stores the string `HELLO`, the following command writes `I SAY \HELLO\` to the screen:

    echo "I SAY \\%MYVAR%\\"

The following code, however, will write `I SAY \\%MYVAR%\\` to the screen:

    echo 'I SAY \\%MYVAR%\\'

Comments are given by # character:

    echo hi # this is a comment

The output of another command can be captured:

    echo The command pwd gives us: (pwd)

You can also use wildcard expansion:

    echo Here are the text files: *.txt

## Built-in commands

`echo <argument>` -- write argument

`pwd` -- write the current directory

`cd <argdir>` -- change the current directory to argdir (default: $HOME)

`vi <argfile>` -- open a Vim buffer for argfile and switch to it

`vim <argfile>` -- open a Vim buffer for argfile and switch to it

`win <argfile>` -- open a Vim buffer for argfile, in the previous Vim window

`exit` -- destroy the Sheldon buffer

`clear` -- clear the Sheldon buffer

`cls` -- clear the Sheldon buffer

`set x y` -- set the local variable x to y

`eval <vimexp>` -- evaluate the vim expression vimexp and write the result

`testeval <vimexp>` -- evaluate the vim expression vimexp and return success(0) if the expression returns true, otherwise, return failure(1)

`do <arg1> <arg2> ... <argN>` -- evaluate all the Sheldon command strings given as arguments

`not <arg>` -- evaluate the Sheldon command string given as arg, and return success(0) if the evaluation returns failure(non-zero), otherwise, return failure(1)

`and <arg1> <arg2> ... <argN>` -- evaluate all the Sheldon command strings, until the evaluation of one of them returns failure(non-zero)

`or <arg1> <arg2> ... <argN>` -- evaluate all the Sheldon command strings, until the evaluation of one of them returns success(0)

`if <condition1> <action1> <condition2> <action2> ...` -- evaluate action1 if condition1 returns success, otherwise, evaluate action2 if condition2 returns success, and it goes on like this.

`for x in <xvalue1> <xvalue2> ... <xvalueN> <action>` -- evaluate the Sheldon command string action for each value of x

`else` -- always return success(0)

`while <condition> <action>` -- evaluate the Sheldon command string action, as long as condition returns success

`which <cmdname>` -- write which executable or Vim function is associated with the Sheldon command cmdname

## Notes for Windows Users

Currently, Sheldon.vim is not very well tested in Windows systems. For now, the following comments are applicable.

In Windows, the path separator is the backslash character (`\`), not the forward slash (`/`) as in Linux, BSD, Mac OSX, etc. However, the backslash character is used as the escape character in Sheldon.vim. Therefore, a Windows user is suggested to write the paths within single quotes (`'`):

    cd 'C:\Program Files'
    
Another approach is to use the rules of the backslash escape character:

    cd C:\\Program\ Files

In Windows, there are no external executables like cp, ls, rm to do basic file operations (such commands are built into cmd.exe). You might want to check GNUWin32 project, find cp.exe, ls.exe, mv.exe, rm.exe, etc. from there, and then put those executables into path.

## Examples for some advanced commands

### set

    set x 3

### eval

    eval 1+1

    eval %x%+3

### if

    if {testeval %x%==3} {echo x is 3} else {echo x is not 3}

### and

    and {SomeRandomCommand} {echo SomeRandomCommand worked!}

### or

    or {SomeRandomCommand} {echo SomeRandomCommand did not work}

### do

    do {echo this will work} {echo this will also work}

### for

    for f in *.txt {echo here is a text file: %f%}

## Author
Created by Nihat Engin Toklu ( https://github.com/engintoklu )

Syntax Highlighting added by Rupesh Kumar Srivastava ( https://github.com/flukeskywalker )

Please feel free to open an issue or send a PR.

## License
See the file: 
[LICENSE](https://github.com/engintoklu/sheldon.vim/blob/master/LICENSE)

