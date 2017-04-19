" This is sheldon.vim
" Author: Nihat Engin Toklu < www.github.com/engintoklu >

if !exists('g:SheldonBufferName')
    let g:SheldonBufferName = '~/SheldonBuffer'
endif

if !exists('g:SheldonPatterns')
    let g:SheldonPatterns = []
endif

if !exists('g:SheldonHistoryLength')
    let g:SheldonHistoryLength = 100
endif

if !exists('g:SheldonPowershellSettings')
    let g:SheldonPowershellSettings = ['-NoProfile', '-NonInteractive']
endif

if !exists('g:SheldonUsePowershellOnWin')
    let g:SheldonUsePowershellOnWin = 1
endif

" to handle the outputs of gcc, g++, clang, etc.
call add(g:SheldonPatterns, ['\m^\(.*\):\([0-9][0-9]*\):\([0-9][0-9]*\): ', '\1\n\2\n\3\n'])
call add(g:SheldonPatterns, ['\m^\(.*\):\([0-9][0-9]*\): ', '\1\n\2\n1\n'])

" to handle the output of gfortran:
call add(g:SheldonPatterns, ['\m^\(.*\):\([0-9][0-9]*\).\([0-9][0-9]*\):', '\1\n\2\n\3\n'])

" to handle the output of python
call add(g:SheldonPatterns, ['\m^  File \"\(.*\)\", line \([0-9][0-9]*\), in', '\1\n\2\n1\n'])

" to handle the output of gdb
" (although gdb is most frequently used interactively and
" sheldon.vim can not handle interactive processes!)
call add(g:SheldonPatterns, ['\m^.* at \(.*\):\([0-9][0-9]*\)', '\1\n\2\n1\n'])

let g:SheldonGlobSpecialChars = ['*', '?', '[', ']']

if !exists('g:SheldonCommands')
    let g:SheldonCommands = {}
endif

let g:SheldonCommands["echo"] = "g:SheldonCommandEcho"
let g:SheldonCommands["pwd"] = "g:SheldonCommandPwd"
let g:SheldonCommands["cd"] = "g:SheldonCommandCd"
let g:SheldonCommands["vi"] = "g:SheldonCommandVi"
let g:SheldonCommands["vim"] = "g:SheldonCommandVi"
let g:SheldonCommands["win"] = "g:SheldonCommandWin"
let g:SheldonCommands["exit"] = "g:SheldonCommandExit"
let g:SheldonCommands["clear"] = "g:SheldonCommandClear"
let g:SheldonCommands["cls"] = "g:SheldonCommandClear"
let g:SheldonCommands["set"] = "g:SheldonCommandSet"
let g:SheldonCommands["eval"] = "g:SheldonCommandEval"
let g:SheldonCommands["testeval"] = "g:SheldonCommandTestEval"
let g:SheldonCommands["do"] = "g:SheldonCommandDo"
let g:SheldonCommands["not"] = "g:SheldonCommandNot"
let g:SheldonCommands["and"] = "g:SheldonCommandAnd"
let g:SheldonCommands["or"] = "g:SheldonCommandOr"
let g:SheldonCommands["if"] = "g:SheldonCommandIf"
let g:SheldonCommands["for"] = "g:SheldonCommandFor"
let g:SheldonCommands["else"] = "g:SheldonCommandElse"
let g:SheldonCommands["while"] = "g:SheldonCommandWhile"
let g:SheldonCommands["which"] = "g:SheldonCommandWhich"
if (has("win32") || has("win64")) && g:SheldonUsePowershellOnWin == 1
    let g:SheldonCommands["ls"] = "g:SheldonPowershellCommand"
    let g:SheldonCommands["cp"] = "g:SheldonPowershellCommand"
    let g:SheldonCommands["mv"] = "g:SheldonPowershellCommand"
    let g:SheldonCommands["rm"] = "g:SheldonPowershellCommand"
    let g:SheldonCommands["mkdir"] = "g:SheldonPowershellCommand"
    let g:SheldonCommands["rmdir"] = "g:SheldonPowershellCommand"
endif

function! s:dirname(s)
    return fnamemodify(a:s, ":h")
endfunction

function! s:filename(s)
    return fnamemodify(a:s, ":t")
endfunction

function! s:separateFlagsAndArgs(cmdline)
    let flags = ''
    let args = []
    let expectingFlags = 1
    let askingForHelp = 0
    for cmdcell in a:cmdline
        if expectingFlags == 1 && cmdcell == '--help'
            let askingForHelp = 1
        elseif expectingFlags == 1 && len(cmdcell) == '--'
            let expectingFlags = 0
        elseif expectingFlags == 1 && len(cmdcell) > 0 && cmdcell[0] == '-'
            for i in range(1, len(cmdcell))
                let flags = flags . cmdcell[i]
            endfor
        else
            call add(args, cmdcell)
        endif
    endfor
    return [flags, args, askingForHelp]
endfunction

function! s:isPowershellFlag(s)
    if a:s == '--'
        return 1
    else
        let ss = tolower(a:s)
        if matchstr(ss, '-[a-z]\+') == ss
            return 1
        else
            return 0
        endif
    endif
endfunction

function! s:powershellQuote(s)
    if s:isPowershellFlag(a:s) == 1
        return a:s
    else
        let result = ''
        for i in range(len(a:s))
            let c = a:s[i]
            if c == "'"
                let result = result . "''"
            else
                let result = result . c
            endif
        endfor
        return "'" . result . "'"
    endif
endfunction

function! s:runPowershellCommand(cmd, argtokens)
    let pshellcmd = a:cmd
    let first = 1
    for token in a:argtokens
        let pshellcmd = pshellcmd . ' ' . s:powershellQuote(token)
    endfor
    
    let output = system(g:SheldonMakeSystemString(['powershell'] + g:SheldonPowershellSettings + ['-Command', pshellcmd]))
    let result = v:shell_error
    let outputAsList = split(output, "\<NL>")

    return [result, outputAsList, 0]
endfunction

function! g:SheldonPowershellCommand(cmdline)
    let q = s:separateFlagsAndArgs(a:cmdline[1:])
    let flags = q[0]
    let fnames = q[1]
    let askingForHelp = q[2]
    let fdestination = ''

    if askingForHelp == 1
        if a:cmdline[0] == 'ls'
            return [0, ['ls : a wrapper in Sheldon.vim for Powershell cmdlet ls. Lists files.', 'Usage: ', 'ls [FLAGS] FILENAME(S)', 'Flags: -v Verbose  -r Recurse  -f Force'], 0]
        elseif a:cmdline[0] == 'cp'
            return [0, ['cp : a wrapper in Sheldon.vim for Powershell cmdlet cp. Copies files.', 'Usage: ', 'cp [FLAGS] SOURCEFILE(S) DESTINATION', 'Flags: -v Verbose  -r Recurse  -f Force'], 0]
        elseif a:cmdline[0] == 'mv'
            return [0, ['mv : a wrapper in Sheldon.vim for Powershell cmdlet mv. Moves files.', 'Usage: ', 'mv [FLAGS] SOURCEFILE(S) DESTINATION', 'Flags: -v Verbose  -r Recurse  -f Force'], 0]
        elseif a:cmdline[0] == 'rm'
            return [0, ['rm : a wrapper in Sheldon.vim for Powershell cmdlet rm. Removes files.', 'Usage: ', 'rm [FLAGS] FILENAME(S)', 'Flags: -v Verbose  -r Recurse  -f Force'], 0]
        elseif a:cmdline[0] == 'mkdir'
            return [0, ['mkdir : a wrapper in Sheldon.vim for Powershell cmdlet mkdir. Creates directories.', 'Usage: ', 'mkdir [FLAGS] DIRNAME(S)', 'Flags: -v Verbose  -f Force'], 0]
        elseif a:cmdline[0] == 'rmdir'
            return [0, ['rmdir : a wrapper in Sheldon.vim for Powershell cmdlet rmdir. Removes directories.', 'Usage: ', 'rmdir [FLAGS] DIRNAME(S)', 'Flags: -v Verbose  -r Recurse  -f Force'], 0]
        endif
    endif

    if a:cmdline[0] == 'ls' && len(fnames) == 0
        call add(fnames, '.')
    endif

    if a:cmdline[0] == 'cp' || a:cmdline[0] == 'mv'
        if len(fnames) < 2
            return [1, [a:cmdline[0] . ': wrong number of arguments'], 0]
        else
            let fdestination = fnames[-1]
            let fnames = fnames[:-2]
        endif
    endif

    let pshellArgs = []

    for iflag in range(len(flags))
        let flag = flags[iflag]
        if flag == 'v'
            call add(pshellArgs, '-verbose')
        elseif flag == 'r' || flag == 'R'
            if a:cmdline[0] == 'mkdir'
                return [1, [a:cmdline[0] . ': unknown option: ' . flag], 0]
            else
                call add(pshellArgs, '-recurse')
            endif
        elseif flag == 'f'
            call add(pshellArgs, '-force')
        else
            return [1, [a:cmdline[0] . ': unknown option: ' . flag], 0]
        endif
    endfor
    call add(pshellArgs, '--')

    let totalOutput = []
    let finalResult = 0
    for fname in fnames
        if fdestination == ''
            let q = s:runPowershellCommand(a:cmdline[0], pshellArgs + [fname])
        else
            let q = s:runPowershellCommand(a:cmdline[0], pshellArgs + [fname] + [fdestination])
        endif
        let thisResult = q[0]
        let totalOutput = totalOutput + q[1]
        if thisResult != 0
            let finalResult = thisResult
            break
        endif
    endfor

    return [finalResult, totalOutput, 0]
endfunction


function! g:SheldonGlobForWin(s)
    " Prevent Vim from taking \*, \? and \[ as
    " * ? and [ for globbing in windows
    " This problem arises because \ is not an escape character
    " in windows: it is a path separator

    let result = ''
    let specialchar = 0
    let activateglobbing = 0
    
    for i in range(len(a:s))
        let c = a:s[i]
        if specialchar
            let specialchar = 0
            if c == '?' || c == '*'
                " We assume that a file name can not contain
                " ? or * in its name
                " So, we give an empty string as the result
                let result = ''
                break
            elseif c == '['
                " We convert [ to [[]
                " See Vim help topic: wildcards
                let result = result . '[[]'
            else
                let result = result . c
            endif
        elseif c == '\'
            let specialchar = 1
        else
            if index(g:SheldonGlobSpecialChars, c) != -1
                let activateglobbing = 1
            endif
            let result = result . c
        endif
    endfor

    if !activateglobbing
        let result = ''
    endif
    
    if result != ""
        let result = glob(result)
    endif

    return result
endfunction

function! s:SheldonEscapeBackslash(s)
    return substitute(a:s, '\\', '\\\\', 'g')
endfunction

function! s:SheldonEscapeFromGlob(s)
    let result = ""
    for i in range(len(a:s))
        let c = a:s[i]
        if c == '\'
            let result = result . '\\'
        elseif index(g:SheldonGlobSpecialChars, c) != -1
            let result = result . '\' . c
        else
            let result = result . c
        endif
    endfor
    return result
endfunction

function! g:SheldonCommandEcho(tokens)
    " Echo command: it just prints the tokens
    " This is an example command, showing how you can extend Sheldon
    " A Sheldon command function takes the list of tokens as its argument
    " The first element of tokens is the name of the command itself

    let outputstr = ""
    let firstone = 1
    for token in a:tokens[1:]
        if firstone
            let firstone = 0
        else
            let outputstr = outputstr . " "
        endif
        let outputstr = outputstr . token
    endfor

    " Now we return:
    "  - Result code (0 means success)
    "  - Output lines as a list of strings
    "  - Signal of exiting. If the echo command would close the Sheldon buffer,
    "    signal of exiting would be 1. This is necessary because if the Sheldon buffer
    "    is closed, Sheldon should not write its prompt anymore.
    return [0, [outputstr], 0]
endfunction

function! g:SheldonCommandWhich(cmdline)
    " which command: echoes the handling function or program of a command

    let q = s:separateFlagsAndArgs(a:cmdline[1:])
    let flags = q[0]
    let fnames = q[1]
    let askingForHelp = q[2]

    if askingForHelp == 1
        return [0, ['which', 'specifies the executable full path or the Vimscript function name of a command', 'Usage:  which COMMANDNAME'], 0]
    endif

    if len(flags) > 0
        return [1, ['which: unexpected arguments'], 0]
    endif

    if len(fnames) == 0
        return [1, ['which: expected file names, but got none.'], 0]
    endif

    if len(fnames) > 1
        return [1, ['which: expected a single file name, but got more.'], 0]
    endif

    let result = 0
    let cmdname = fnames[0]
    if has_key(g:SheldonCommands, cmdname)
        let outputstr = cmdname . ' is handled by the Vimscript function ' . g:SheldonCommands[cmdname]
    else
        " let outputstr = split(system(g:SheldonMakeSystemString(["which", cmdname])), "\<NL>")[0]
        " let result = v:shell_error
        let outputstr = exepath(cmdname)
    endif
    return [result, [outputstr], 0]
endfunction

function! g:SheldonCommandPwd(tokens)
    " Prints the current directory
    return [0, [getcwd()], 0]
endfunction

function! g:SheldonCommandCd(tokens)
    " Changes the current directory of Vim
    if len(a:tokens) == 1
        " Switch to home directory if no dir provided
        execute 'cd ' . '$HOME'
    else
        execute 'cd ' . fnameescape(a:tokens[1])
    endif
    return [0, [], 0]
endfunction

function! g:SheldonCommandVi(tokens)
    " Opens the specified file for editing
    call g:SheldonEditFile(fnameescape(fnamemodify(a:tokens[1], ':p')), 1)
    return [0, [], 1]
endfunction

function! g:SheldonCommandWin(tokens)
    " Opens the specified file for editing in prev window
    call g:SheldonEditFilePrevWin(fnameescape(fnamemodify(a:tokens[1], ':p')), 1)
    return [0, [], 1]
endfunction

function! g:SheldonCommandExit(tokens)
    " Deletes the Sheldon buffer
    execute 'bd!'
    return [0, [], 1]
endfunction

function! g:SheldonCommandClear(tokens)
    " Closes the Sheldon buffer
    execute 'normal! ggVG"_d'
    return [0, [], 0]
endfunction

function! g:SheldonCommandSet(tokens)
    " Sets a Sheldon-buffer-variable
    let b:SheldonVars[a:tokens[1]] = a:tokens[2]
    return [0, [], 0]
endfunction

function! g:SheldonCommandEval(tokens)
    " Evaluates its token as a Vimscript expression
    return [0, ['' . eval(join(a:tokens[1:], ' '))], 0]
endfunction

function! g:SheldonCommandTestEval(tokens)
    " Evaluates its token as a Vimscript expression
    " Returns success code (0) if the evaluation result is true
    " Otherwise, returns failure code (1)

    let result = 0
    let evalresult = eval(join(a:tokens[1:], ' '))

    if evalresult
        let result = 0
    else
        let result = 1
    endif

    return [result, [], 0]
endfunction

function! g:SheldonCommandDo(tokens)
    " Evaluates all its tokens
    let output = []
    let exiting = 0
    for token in a:tokens[1:]
        let evaluation = g:SheldonExecuteLine(token)
        let output = output + evaluation[1]
        if evaluation[2]
            let exiting = evaluation[2]
            break
        endif
    endfor
    return [0, output, exiting]
endfunction

function! g:SheldonCommandNot(tokens)
    " Evaluates all its token and returns its logical opposite
    let output = []
    let exiting = 0
    let result = 0

    let evaluation = g:SheldonExecuteLine(a:tokens[1])
    let result = evaluation[0]
    let output = output + evaluation[1]
    if evaluation[2]
        let exiting = evaluation[2]
        break
    endif

    if result == 0
        let result = 1
    else
        let result = 0
    endif

    return [result, output, exiting]
endfunction

function! g:SheldonCommandAnd(tokens)
    " Evaluates all its tokens until one of them returns false
    let output = []
    let result = 0
    let exiting = 0
    for token in a:tokens[1:]
        let evaluation = g:SheldonExecuteLine(token)
        let output = output + evaluation[1]
        if evaluation[0] != 0
            let result = 1
            break
        endif
        if evaluation[2]
            let exiting = evaluation[2]
            break
        endif
    endfor
    return [result, output, exiting]
endfunction

function! g:SheldonCommandOr(tokens)
    " Evaluates all its tokens until one of them returns false
    let output = []
    let result = 1
    let exiting = 0
    for token in a:tokens[1:]
        let evaluation = g:SheldonExecuteLine(token)
        let output = output + evaluation[1]
        if evaluation[0] == 0
            let result = 0
            break
        endif
        if evaluation[2]
            let exiting = evaluation[2]
            break
        endif
    endfor
    return [result, output, exiting]
endfunction

function! g:SheldonCommandIf(tokens)
    " if condition1 action1 condition2 action2 ...
    let exiting = 0
    let result = 0
    let output = []
    let i = 1
    while i < len(a:tokens)
        let condition = a:tokens[i]

        let evaluation = g:SheldonExecuteLine(condition)
        let output = output + evaluation[1]
        if evaluation[2]
            let exiting = evaluation[2]
            break
        endif

        if i + 1 >= len(a:tokens)
            break
        endif
        let action = a:tokens[i + 1]

        if evaluation[0] == 0
            let evaluation = g:SheldonExecuteLine(action)
            let result = evaluation[0]
            let output = output + evaluation[1]
            if evaluation[2]
                let exiting = evaluation[2]
                break
            endif
            break
        endif

        let i = i + 2
    endwhile

    return [result, output, exiting]
endfunction

function! g:SheldonCommandElse(tokens)
    " Dummy command. Always returns success (0)
    return [0, [], 0]
endfunction

function! g:SheldonCommandWhile(tokens)
    " while condition action
    let exiting = 0
    let result = 0
    let output = []

    let condition = a:tokens[1]
    let action = a:tokens[2]
    let repeating = 1

    while repeating
        let evaluation = g:SheldonExecuteLine(condition)
        let result = evaluation[0]
        let output = output + evaluation[1]
        if evaluation[2]
            let exiting = evaluation[2]
            break
        endif
        if evaluation[0] == 0
            let evaluation = g:SheldonExecuteLine(action)
            let result = evaluation[0]
            let output = output + evaluation[1]
            if evaluation[2]
                let exiting = evaluation[2]
                break
            endif
        else
            break
        endif
    endwhile

    return [result, output, exiting]
endfunction

function! g:SheldonCommandFor(tokens)
    " for varname in item1 item2 .. itemN action
    let exiting = 0
    let result = 0
    let output = []

    let varname = a:tokens[1]
    let items = a:tokens[3:len(a:tokens)-2]
    let action = a:tokens[len(a:tokens)-1]

    for item in items
        let b:SheldonVars[varname] = item
        let evaluation = g:SheldonExecuteLine(action)
        let result = evaluation[0]
        let output = output + evaluation[1]
        if evaluation[2]
            let exiting = evaluation[2]
            break
        endif
    endfor

    return [result, output, exiting]
endfunction

function! g:SheldonEscape(token)
    " Encloses a file name within quotation marks so that Sheldon will take the name literally
    let result = ""
    for i in range(len(a:token))
        let c = a:token[i]
        if c == "'"
            let result = result . "'" . '"' . "'" . '"' . "'"
        else
            let result = result . c
        endif
    endfor
    return "'" . result . "'"
endfunction

function! g:SheldonGetVarValue(token)
    " Returns the value of a variable
    " If there is such a variable defined in b:SheldonVars, its value is returned
    " Otherwise, an environment variable with that name is sought

    if exists('b:SheldonVars') && has_key(b:SheldonVars, a:token)
        return b:SheldonVars[a:token]
    else
        let envar = '$' . a:token
        if exists(envar)
            return expand('$' . a:token)
        else
            return ''
        endif
    endif
endfunction

function! g:SheldonExpandVars(token)
    " Expands the variables in a string
    " The variables to be expanded are expected in this form:
    "   %VARNAME%
    " like:
    "   %PATH%
    let result = ""
    let varname = ""
    let winstyle = 0
    let dontprocessnext = 0
    for i in range(len(a:token))
        let c = a:token[i]

        if dontprocessnext
            let dontprocessnext = 0
            let result = result . c
        elseif winstyle
            if c == "%"
                let result = result . s:SheldonEscapeFromGlob(g:SheldonGetVarValue(varname))
                let winstyle = 0
                let varname = ""
            else
                let varname = varname . c
            endif
        elseif c == "%"
            let winstyle = 1
        elseif c == "~"
            let result = result . s:SheldonEscapeFromGlob(expand("~"))
        elseif c == '\'
            let result = result . '\'
            let dontprocessnext = 1
        else
            let result = result . c
        endif
    endfor
    return result
endfunction

" function! g:SheldonExpand(token)
"     " Expands the variables and globs in a string
"     " Returns a list of string
"
"     " return split(expand(a:token), "\<NL>")
"     return split(glob(g:SheldonExpandVars(a:token)), "\<NL>")
" endfunction

" function! g:SheldonExpand(token)
"     " Expands the variables and globs in a string
"     " Returns a list of string
"
"     return split(expand(a:token), "\<NL>")
" endfunction


function! g:SheldonRemoveBackslashes(s)
    let result = ""
    let backslash = 0

    for i in range(len(a:s))
        let c = a:s[i]

        if backslash
            let backslash = 0
            if c == 'n'
                let result = result . "\n"
            elseif c == 'r'
                let result = result . "\r"
            elseif c == 't'
                let result = result . "\t"
            else
                let result = result . c
            endif
        elseif c == '\'
            let backslash = 1
        else
            let result = result . c
        endif
    endfor

    return result
endfunction


function! g:SheldonExpand(token)
    " Expands the variables and globs in a string
    " Returns a list of string

    " echom "SheldonExpand received " . a:token

    let result = g:SheldonExpandVars(a:token)

    if has("win32") || has("win64")
        let globbed = g:SheldonGlobForWin(result)
    else
        let globbed = glob(result)
    endif

    if globbed != ""
        let result = globbed
    else
        let result = g:SheldonRemoveBackslashes(result)
    endif

    return split(result, "\<NL>")
endfunction

function! g:SheldonSplit(cmdline)
    " This is the command line parser function of Sheldon.
    " It tokenizes a string by splitting it by spaces.
    "   a b c -> ['a', 'b', 'c']
    " Tokens which include spaces can be written within single- or double-quotation marks
    "   a 'b c' d -> ['a', 'b c', 'd']
    "   a "b c" d -> ['a', 'b c', 'd']
    " You can do nested quotation with { }
    "   a {b {c d} e} -> ['a', 'c {c d} e']
    " Subcommands can be used with ( )
    "   a (echo OutputOfEcho) -> ['a', 'OutputOfEcho']
    " Backslash means escape character: it can be used inside or outside quotation marks
    " Globs and environment variables are expanded, unless they are in single-quotation marks
    "   cd %HOME% -> ['cd', '/home/myusername']
    "   cd "%HOME%" -> ['cd', '/home/myusername']
    "   cd '%HOME%' -> ['cd', '%HOME%']
    "   ls *.txt -> ['ls', 'a.txt', 'b.txt']
    "   ls "*.txt" -> ['ls', 'a.txt', 'b.txt']
    "   ls '*.txt' -> ['ls', '*.txt']
    " Backslash is used as the escape character
    "   echo \t -> ['echo', '    ']
    " Escape characters are processed within double-quotation marks too
    "   echo "\t" -> ['echo', '    ']
    " In single-quotation marks, escape characters are not processed
    "   echo '\t' -> ['echo', '\t']
    " In single-quotation marks, insert the single quote twice to literaly add a single quote
    "   echo 'a''b' -> ['echo', "a'b"]
    " If outside quotations, the symbol '#' can be used for writing comments
    "   a b c #d e -> ['a', 'b', 'c']
    " A string enclosed with { } or ( ) always becomes a separate token.
    "     a{b c} -> ['a', 'b c']
    "   This does not apply to quotations:
    "     a"b c" -> ['ab c']
    "     a'b c' -> ['ab c']

    let prevc = ""
    let nextc = ""
    let ignorenext = 0
    let dontprocessnext = 0

    let result = []
    let singlequote = 0
    let doublequote = 0

    let paren = 0
    let parencell = ''

    let curly = 0
    let curlycell = ''

    let singlequotenested = 0
    let doublequotenested = 0

    let cell = ""
    let s = a:cmdline
    for i in range(len(s))
        let c = s[i]
        if i < (len(s) - 1)
            let nextc = s[i + 1]
        else
            let nextc = ""
        endif

        if ignorenext
            let ignorenext = 0
        elseif dontprocessnext
            let dontprocessnext = 0
            let cell = cell . c
        elseif singlequote || doublequote
            if c == '\'
                if singlequote
                    let cell = cell . '\\'
                else
                    let cell = cell . '\'
                    let dontprocessnext = 1
                endif
            elseif c == '%' && singlequote
                let cell = cell . '\%'
            elseif c == '~'
                let cell = cell . '\~'
            elseif index(g:SheldonGlobSpecialChars, c) != -1
                let cell = cell . '\' . c
            elseif doublequote && c == '"'
                let doublequote = 0
            elseif singlequote && c == "'"
                let singlequote = 0
            " elseif singlequote && c == "'"
            "     if nextc == "'"
            "         let cell = cell . "'"
            "         let ignorenext = 1
            "     else
            "         let singlequote = 0
            "         if cell != ""
            "             let result = result + [cell]
            "             " call add(result, cell)
            "             let cell = ""
            "         endif
            "     endif
            else
                let cell = cell . c
            endif
        elseif paren > 0
            if c == "'"
                let singlequotenested = !singlequotenested
                let parencell = parencell . "'"
            elseif c == '"'
                let doublequotenested = !doublequotenested
                let parencell = parencell . '"'
            elseif c == '\' && (!singlequotenested)
                let parencell = parencell . '\' . nextc
                let ignorenext = 1
            elseif singlequotenested || doublequotenested
                let parencell = parencell . c
            elseif c == "("
                let paren = paren + 1
                let parencell = parencell . "("
            elseif c == ")"
                let paren = paren - 1
                if paren > 0
                    let parencell = parencell . ")"
                else
                    let result = result + g:SheldonExecuteLine(parencell)[1]
                    let parencell = ''
                endif
            else
                let parencell = parencell . c
            endif
        elseif curly > 0
            if c == "'"
                let singlequotenested = !singlequotenested
                let curlycell = curlycell . "'"
            elseif c == '"'
                let doublequotenested = !doublequotenested
                let curlycell = curlycell . '"'
            elseif c == '\'
                if singlequotenested
                    let curlycell = curlycell . '\'
                else
                    let curlycell = curlycell . '\' . nextc
                    let ignorenext = 1
                endif
            elseif singlequotenested || doublequotenested
                let curlycell = curlycell . c
            elseif c == "{"
                let curly = curly + 1
                let curlycell = curlycell . "{"
            elseif c == "}"
                let curly = curly - 1
                if curly > 0
                    let curlycell = curlycell . "}"
                else
                    let result = result + [curlycell]
                    let curlycell = ''
                endif
            else
                let curlycell = curlycell . c
            endif
        elseif c == '\'
            let cell = cell . c
            let dontprocessnext = 1
        elseif c == "#"
            break
        elseif c == "("
            if cell != ""
                let result = result + g:SheldonExpand(cell)
                let cell = ""
            endif
            let paren = 1
        elseif c == "{"
            if cell != ""
                let result = result + g:SheldonExpand(cell)
                let cell = ""
            endif
            let curly = 1
        elseif c == " " || c == "\t"
            if cell != ""
                " call add(result, cell)
                let result = result + g:SheldonExpand(cell)
                let cell = ""
            endif
        elseif c == "'"
            let singlequote = 1
            "if cell != ""
            "    " call add(result, cell)
            "    let result = result + g:SheldonExpand(cell)
            "    let cell = ""
            "endif
        elseif c == '"'
            let doublequote = 1
        else
            let cell = cell . c
        endif

        let prevc = c
    endfor
    if cell != ""
        " call add(result, cell)
        let result = result + g:SheldonExpand(cell)
    endif
    return result
endfunction

function! s:SheldonSpecialCharForWinCmd(c)
    " Returns 1 if c is a special character in the environment of cmd.exe
    " Otherwise, returns 0

    let specials = [" ", "'", '"', "&", "(", ")", "[", "]", "{", "}", "^", "=", ";", "!", "+", ",", "`", "~", "|", ">", "<"]
    if index(specials, a:c) != -1
        return 1
    else
        return 0
    endif
endfunction

function! g:SheldonFixForWindowsCmd(str)
    " Surrounds the str with ( ) and escapes the special characters by inserting ^
    " See:
    " http://vim.wikia.com/wiki/Execute_external_programs_asynchronously_under_Windows
    let result = ""
    for i in range(len(a:str))
        let c = a:str[i]
        if s:SheldonSpecialCharForWinCmd(c)
            let result = result . "^"
        endif
        let result = result . c
    endfor
    return '(' . result . ')'
endfunction

" function! g:SheldonFixForWindowsCmd(str)
"     return '"' . a:str . '"'
" endfunction


function! s:SheldonNeedFixForWindowsCmd()
    if exists("g:SheldonApplyFixForWindowsCmd")
        return g:SheldonApplyFixForWindowsCmd
    else
        return has("win32") || has("win64")
    endif
endfunction

function! g:SheldonMakeSystemString(tokens)
    " Creates a string out of a tokens list. The result string is ready to be sent to the shell.
    let result = ""
    let first = 1
    for token in a:tokens
        if first
            let first = 0
        else
            let result = result . " "
        endif
        let result = result . shellescape(token)
    endfor

    if s:SheldonNeedFixForWindowsCmd()
        return g:SheldonFixForWindowsCmd(result)
    else
        return result
    endif
endfunction

function! g:SheldonPrompt()
    " Generates and returns the prompt string of Sheldon
    return '# Current directory: ' . getcwd()
endfunction

function! g:SheldonEditFile(eargs, makeNewLine)
    " Executes the ex-command e!, with the specified argument string
    if a:makeNewLine
        execute 'normal! Go'
    endif
    execute 'e! ' . a:eargs
endfunction

function! g:SheldonEditFilePrevWin(eargs, makeNewLine)
    " Switches window & executes the ex-command e!, with the specified argument string
    if a:makeNewLine
        execute 'normal! Go'
    endif
    wincmd W
    execute 'e ' . a:eargs
endfunction

function! g:SheldonGotoSpecifiedLine(inPrevWin)
    " Jumps to the file and line number written in the current line
    " The regular expressions for parsing the line are defined in g:SheldonPatterns

    let s = getline('.')
    for [pat, sub] in g:SheldonPatterns
        let ss = substitute(s, pat, sub, '')
        if ss != s
            let parts = split(ss, "\<NL>")
            if a:inPrevWin
                call g:SheldonEditFilePrevWin('+' . parts[1] . ' ' . fnameescape(fnamemodify(parts[0], ':p')), 0)
            else
                call g:SheldonEditFile('+' . parts[1] . ' ' . fnameescape(fnamemodify(parts[0], ':p')), 0)
            endif
            " execute 'enew +' . parts[1] . ' ' . parts[0]
            break
        endif
    endfor
endfunction

" function! g:SheldonHandleNormalEnterKey()
"     let s = getline('.')
"     if s:Strip(s) == ''
"         let cmdline = input(getcwd() . '$ ')
"         call append(line('.'), cmdline)
"         call g:SheldonExecuteLine(cmdline)
"     else
"         call g:SheldonExecuteThisLine()
"     endif
" endfunction

function! s:Strip(input_string)
    " Strips (or trims) leading and trailing whitespace
    " www.stackoverflow.com/a/4479072
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! g:SheldonHistoryIndexUp()
    let b:SheldonHistoryIndex = (b:SheldonHistoryIndex + 1)
    if b:SheldonHistoryIndex >= len(b:SheldonHistory)
        let b:SheldonHistoryIndex = -1
    endif
endfunction

function! g:SheldonHistoryIndexDown()
    let b:SheldonHistoryIndex = (b:SheldonHistoryIndex - 1)
    if b:SheldonHistoryIndex < -1
        let b:SheldonHistoryIndex = len(b:SheldonHistory) - 1
    endif
endfunction

function! g:SheldonWriteHistoryLine()
    let s = ''
    if b:SheldonHistoryIndex >= 0
        let s = b:SheldonHistory[-(b:SheldonHistoryIndex + 1)]
    endif
    execute 'normal! 0"_d$i' . s
endfunction

function! g:SheldonHistoryUp()
    call g:SheldonHistoryIndexUp()
    call g:SheldonWriteHistoryLine()
endfunction

function! g:SheldonHistoryDown()
    call g:SheldonHistoryIndexDown()
    call g:SheldonWriteHistoryLine()
endfunction

function! g:SheldonUpdateHistory(currentline)
    let updateHistory = 0
    if len(b:SheldonHistory) == 0
        let updateHistory = 1
    else
        if a:currentline != b:SheldonHistory[-1]
            let updateHistory = 1
        endif
    endif
    if updateHistory
        call add(b:SheldonHistory, a:currentline)
        if len(b:SheldonHistory) > g:SheldonHistoryLength
            let b:SheldonHistory = b:SheldonHistory[1:]
        endif
    endif
    let b:SheldonHistoryIndex = -1
endfunction

function! g:SheldonExecuteThisLine()
    " Executes the command in the current line
    call g:SheldonUpdateHistory(getline('.'))
    let [result, outputAsList, exiting] = g:SheldonExecuteLine(getline('.'))
    if !exiting
        let outputAsList = outputAsList + [g:SheldonPrompt()]
        call append(line('$'), outputAsList)
        execute 'normal! Go'
    endif
endfunction

" function! g:SheldonHandleSpecialCmd()
"     let currentline = s:Strip(getline('.'))
"     let tokens = split(currentline)
"     let special = 0
"
"     if len(tokens) != 1
"         " ignore
"     elseif tokens[0] == 'cd'
"         let mynewdir = input('cd ', '', 'dir')
"         execute 'cd ' . fnameescape(mynewdir)
"         execute 'normal! a' . mynewdir
"         execute 'normal! o' . g:SheldonPrompt()
"         execute 'normal! Go'
"     elseif tokens[0] == 'vi' || tokens[0] == 'vim'
"         call g:SheldonEditFile(fnameescape(input(tokens[0] . ' ', '', 'file')))
"     endif
" endfunction

function! g:SheldonQuoteFileName(fname)
    if s:SheldonNeedFixForWindowsCmd()
      return "'" . substitute(a:fname, '\\ ', ' ', 'g') . "'"
    else
        return a:fname
    endif
endfunction

function! g:SheldonTriggerCompletion()
    " Uses the input() command of Vim to provide an entry field with completion
    let currentline = s:Strip(getline('.'))
    let tokens = split(currentline)
    let compltype = 'file'
    let defaultvalue = expand('<cword>')

    if defaultvalue != ''
        execute 'normal! "_ciw'
    endif

    if len(tokens) > 0 && tokens[0] == 'cd'
        let compltype = 'dir'
    endif

    let result = input('Completion: ', defaultvalue, compltype)
    " execute 'normal! a' . g:SheldonEscape(result)
    execute 'normal! a' . g:SheldonQuoteFileName(result)
endfunction

function! g:SheldonExecuteLine(cmdline)
    " Executes the command specified by CMDLINE
    " If the command is a special command (like cd), it performs the necessary actions
    " Otherwise, it redirects the command line to the system shell

    let currentline = s:Strip(a:cmdline)
    let outputAsList = []

    let result = 0
    let tokens = g:SheldonSplit(currentline)
    let exiting = 0

    if len(tokens) == 0
        " ignore
    elseif has_key(g:SheldonCommands, tokens[0])
        let funcname = g:SheldonCommands[tokens[0]]
        let [result, outputAsList, exiting] = eval(funcname . "(tokens)")
    elseif tokens[0] == 'clear' || tokens[0] == 'cls'
        execute 'normal! ggVG"_d'
    else
        let output = system(g:SheldonMakeSystemString(tokens))
        let result = v:shell_error
        let outputAsList = split(output, "\<NL>")
    endif

    return [result, outputAsList, exiting]
endfunction

function! g:SheldonPrepareBuffer()
    " Adds the current buffer the keybindings of Sheldon.vim

    let b:SheldonVars = {}
    let b:SheldonHistory = []
    let b:SheldonHistoryIndex = -1

    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal filetype=sheldonbuf

    " === from Rupesh Kumar Srivastava < www.github.com/flukeskywalker > ===
    " <C-d> closes the Sheldon buffer
    inoremap <buffer> <C-d> <C-o>:bd<CR>
    " ======================================================================
    nnoremap <buffer> <Tab> :call g:SheldonGotoSpecifiedLine(1)<CR>
    nnoremap <buffer> <CR> :call g:SheldonGotoSpecifiedLine(0)<CR>
    inoremap <buffer> <C-Up> <C-o>:call g:SheldonHistoryUp()<CR><Right>
    inoremap <buffer> <C-Down> <C-o>:call g:SheldonHistoryDown()<CR><Right>
    inoremap <buffer> <CR> <C-o>:call g:SheldonExecuteThisLine()<CR>
    " inoremap <buffer> <space> <space><C-o>:call g:SheldonHandleSpecialCmd()<CR>
    inoremap <buffer> <Tab> <C-o>:call g:SheldonTriggerCompletion()<CR>
    call append(line('$'), ['# This is sheldon.vim', '# Write your shell commands to empty lines in INSERT mode','# and then press ENTER to execute them', g:SheldonPrompt(), ''])
    execute 'normal! G'
endfunction

function! g:SheldonCreateSplit()
    " Creates/opens a Sheldon buffer in a new window
    execute 'new'
    call g:SheldonCreateNew()
endfunction

function! g:SheldonCreateNew()
    " Creates/opens a Sheldon buffer

    let successful = 0
    try
        execute 'e ' . g:SheldonBufferName
        let successful = 1
    finally
        if successful
            if !exists('b:SheldonVars')
                call g:SheldonPrepareBuffer()
            endif
        endif
    endtry
endfunction

function! g:SheldonRunCommand(sheldoncmd)
    " Creates/opens a Sheldon buffer, and executes the argument
    let successful = 0
    try
        execute 'Sheldon'
        let successful = 1
    finally
        if successful
            execute 'normal! Go'
            call append(line("."), a:sheldoncmd)
            execute 'normal! j'
            call g:SheldonExecuteThisLine()
        endif
    endtry
endfunction

command! Sheldon :call g:SheldonCreateNew()
command! SheldonSplit :call g:SheldonCreateSplit()
command! -nargs=+ SheldonRun :call g:SheldonRunCommand("<args>")

