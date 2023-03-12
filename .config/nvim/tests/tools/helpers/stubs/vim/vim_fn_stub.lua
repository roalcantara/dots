-- https://neovim.io/doc/user/builtin.html
--luacheck: no unused args
local fn = {}

local case = function(value, when)
  return when[value]
end

---Get A Character String From A List Of Numbers
function fn.list2str(...)
  return ...
end

---Convert A String To A Number
---@return number
function fn.str2nr(...)
  return ...
end

---Absolute Value (Also Works For Number)
---Absolute Value Of {ExAlso Works For Number
---@return number
function fn.abs(expr)
  return expr
end

---Arc Cosine Of {Expr}
---@return number
function fn.acos(expr)
  return expr
end

---Append {Item} To {Object}
---@return table
function fn.add(object, item)
  return object, item
end

---Bitwise And
---@return number
function fn.And(expr, expr2)
  return expr, expr2
end

---Api Metadata
---@return table
function fn.api_info()
  return nil
end

---Append {String} Below Line {Lnum}
---Append Lines {List} Below Line {Lnum}
---@return number
function fn.append(lnum, list)
  return lnum, list
end

---Number Of Files In The Argument List
---@return number
function fn.argc(winid)
  return winid
end

---Current Index In The Argument List
---@return number
function fn.argidx()
  return nil
end

---Argument List Id
---@return number
function fn.arglistid(winnr, tabnr)
  return winnr, tabnr
end

---{Nr} Entry Of The Argument List
---@return string | table
function fn.argv(nr, winid)
  return nr, winid
end

---Arc Sine Of {Expr}
---@return number
function fn.asin(expr)
  return expr
end

---Assert {Cmd} Causes A Beep
---@return number
function fn.assert_beeps(cmd)
  return cmd
end

---Assert {Exp} Is Equal To {Act}
---@return number
function fn.assert_equal(exp, act, msg)
  return exp, act, msg
end

---Assert File Contents Are Equal
---@return number
function fn.assert_equalfile(fname_one, fname_two, msg)
  return fname_one, fname_two, msg
end

---Assert {Error} Is In V:Exception
---@return number
function fn.assert_exception(error, msg)
  return error, msg
end

---Assert {Cmd} Fails
---@return number
function fn.assert_fails(cmd, error)
  return cmd, error
end

---Assert {Actual} Is False
---@return number
function fn.assert_false(actual, msg)
  return actual, msg
end

---Assert {Actual} Is Inside The Range
---@return number
function fn.assert_inrange(lower, upper, actual, msg)
  return lower, upper, actual, msg
end

---Assert {Pat} Matches {Text}
---@return number
function fn.assert_match(pat, text, msg)
  return pat, text, msg
end

---Assert {Cmd} Does Not Cause A Beep
---@return number
function fn.assert_nobeep(cmd)
  return cmd
end

---Assert {Exp} Is Not Equal {Act}
---@return number
function fn.assert_notequal(exp, act, msg)
  return exp, act, msg
end

---Assert {Pat} Not Matches {Text}
---@return number
function fn.assert_notmatch(pat, text, msg)
  return pat, text, msg
end

---Report A Test Failure
---@return number
function fn.assert_report(msg)
  return msg
end

---Assert {Actual} Is True
---@return number
function fn.assert_true(actual, msg)
  return actual, msg
end

---Arc Tangent Of {Expr}
---@return number
function fn.atan(expr)
  return expr
end

---Arc Tangent Of {Expr1}/{Expr2}
---@return number
function fn.atan2(expr, expr2)
  return expr, expr2
end

---Put Up A File Requester
---@return string
function fn.browse(save, title, initdir, default)
  return save, title, initdir, default
end

---Put Up A Directory Requester
---@return string
function fn.browsedir(title, initdir)
  return title, initdir
end

---Add A Buffer To The Buffer List
---@return number
function fn.bufadd(name)
  return name
end

---True If Buffer {Expr} Exists
---@return number
function fn.bufexists(expr)
  return expr
end

---True If Buffer {Expr} Is Listed
---@return number
function fn.buflisted(expr)
  return expr
end

---Load Buffer {Expr} If Not Loaded Yet
---@return number
function fn.bufload(expr)
  return expr
end

---True If Buffer {Expr} Is Loaded
---@return number
function fn.bufloaded(expr)
  return expr
end

---Name Of The Buffer {Expr}
---@return string
function fn.bufname(expr)
  return expr
end

---Number Of The Buffer {Expr}
---@return number
function fn.bufnr(exp, create)
  return exp, create
end

---Window-id Of Buffer {Expr}
---@return number
function fn.bufwinid(expr)
  return expr
end

---Window Number Of Buffer {Expr}
---@return number
function fn.bufwinnr(expr)
  return expr
end

---Line Number At Byte Count {Byte}
---@return number
function fn.byte2line(byte)
  return byte
end

---Byte Index Of {Nr}'Th Char In {Expr}
---@return number
function fn.byteidx(expr, nr)
  return expr, nr
end

---Byte Index Of {Nr}'Th Char In {Expr}
---@return number
function fn.byteidxcomp(expr, nr)
  return expr, nr
end

---Call {Func} With Arguments {Arglist}
---@return table
function fn.call(func, arglist, dict)
  return func, arglist, dict
end

---Round {Expr} Up
---@return number
function fn.ceil(expr)
  return expr
end

---Closes A Channel Or One Of Its Streams
---@return number
function fn.chanclose(i, stream)
  return i, stream
end

---Current Change Number
---@return number
function fn.changenr()
  return nil
end

---Writes {Data} To Channel
---@return number
function fn.chansend(id, data)
  return id, data
end

---Ascii/Utf-8 Value Of First Char In {Expr}
---@return number
function fn.char2nr(exp, utf8)
  return exp, utf8
end

---Char Index Of Byte {Idx} In {String}
---@return number
function fn.charidx(string, idx, countcc)
  return string, idx, countcc
end

---Change Current Working Directory
---@return string
function fn.chdir(dir)
  return dir
end

---C Indent For Line {Lnum}
---@return number
function fn.cindent(lnum)
  return lnum
end

---Clear All Matches
function fn.clearmatches(win)
  return win
end

---Column Nr Of Cursor Or Mark
---@return number
function fn.col(expr)
  return expr
end

---Set Insert Mode Completion
function fn.complete(startcol, matches)
  return startcol, matches
end

---Add Completion Match
---@return number
function fn.complete_add(expr)
  return expr
end

---Check For Key Typed During Completion
---@return number
function fn.complete_check()
  return nil
end

---Get Current Completion Information
---@return table
function fn.complete_info(what)
  return what
end

---Number Of Choice Picked By User
---@return number
function fn.confirm(msg, choices, default, type)
  return msg, choices, default, type
end

---Make A Shallow Copy Of {Expr}
---@return table
function fn.copy(expr)
  return expr
end

---Cosine Of {Expr}
---@return number
function fn.cos(expr)
  return expr
end

---Hyperbolic Cosine Of {Expr}
---@return number
function fn.cosh(expr)
  return expr
end

---Count How Many {Expr} Are In {List}
---@return number
function fn.count(list, expr, ic, start)
  return list, expr, ic, start
end

---Checks Existence Of Cscope Connection
---@return number
function fn.cscope_connection(num, dbpath, prepend)
  return num, dbpath, prepend
end

---Return The Context Dict At {Index}
---@return table
function fn.ctxget(index)
  return index
end

---Pop And Restore Context Rom The Context-stack
function fn.ctxpop()
  return nil
end

---Push The Current Context To The   Context-stack
function fn.ctxpush(types)
  return types
end

---Set Context At {Index}
function fn.ctxset(contex, index)
  return contex, index
end

---Return Context-stack Size
---@return number
function fn.ctxsize()
  return nil
end

---Move Cursor To Position In {List}
---Move Cursor To {Lnum}, Col, Off
---@return number
function fn.cursor(lnum, col, off)
  return lnum, col, off
end

---Interrupt Process Being Debugged
---@return number
function fn.debugbreak(pid)
  return pid
end

---Make A Full Copy Of {Expr}
---@return table
function fn.deepcopy(expr, noref)
  return expr, noref
end

---Delete The File Or Directory {Fname}
---@return number
function fn.delete(fname, flags)
  return fname, flags
end

---Delete Lines From Buffer {Buf}
---@return number
function fn.deletebufline(buf, firs, last)
  return buf, firs, last
end

---Watching A Dictionary
function fn.dictwatcheradd(dict, pattern, callback)
  return dict, pattern, callback
end

---Watching A Dictionary
function fn.dictwatcherdel(dict, pattern, callback)
  return dict, pattern, callback
end

---True If Filetype Autocommand Event Used
---@return number
function fn.did_filetype()
  return nil
end

---Diff Filler Lines About {Lnum}
---@return number
function fn.diff_filler(lnum)
  return lnum
end

---Diff Highlighting At {Lnum}/{Col}
---@return number
function fn.diff_hlID(lnum, col)
  return lnum, col
end

---True If {Expr} Is Empty
---@return number
function fn.empty(expr)
  return expr
end

---Return Environment Variables
---@return table
function fn.environ()
  return nil
end

---Escape Characters In A String With A '\'
---@return string
function fn.escape(string, chars)
  return string, chars
end

---Evaluate {String} Into Its Value
---@return table
function fn.eval(string)
  return string
end

---True If Inside An Event Handler
---@return number
function fn.eventhandler()
  return nil
end

---1 If Executable {Expr} Exists
---@return number
function fn.executable(expr)
  return expr
end

---Execute And Capture Output Of {Command}
---@return string
function fn.execute(command)
  return command
end

---Full Path Of The Command {Expr}
---@return string
function fn.exepath(expr)
  return expr
end

---True If {Expr} Exists
---@return number
function fn.exists(expr)
  return expr
end

---Exponential Of {Expr}
---@return number
function fn.exp(expr)
  return expr
end

---Expand Special Keywords In {Expr}
---@return table
function fn.expand(expr, nosuf, list)
  return expr, nosuf, list
end

---Expand {Expr} Like With `:Edit`
---@return string
function fn.expandcmd(expr)
  return expr
end

---Insert Items Of {Expr2} Into {Expr1}
---@return table
function fn.extend(expr1, expr2, expr3)
  return expr1, expr2, expr3
end

---Add Key Sequence To Typeahead Buffer
---@return number
function fn.feedkeys(string, mode)
  return string, mode
end

---True If {File} Is A Readable File
---@return number
function fn.filereadable(file)
  return file
end

---True If {File} Is A Writable File
---@return number
function fn.filewritable(file)
  return file
end

---Remove Items From {Expr1} Where {Expr2} Is 0
---@return table
function fn.filter(expr1, expr2)
  return expr1, expr2
end

---Find Directory {Name} In {Path}
---@return string
function fn.finddir(name, path, count)
  return name, path, count
end

---Find File {Name} In {Path}
---@return string
function fn.findfile(name, path, count)
  return name, path, count
end

---Flatten {List} Up To {Maxdepth} Levels
---@return table
function fn.flatten(list, maxdepth)
  return list, maxdepth
end

---Convert Float {Expr} To A Number
---@return number
function fn.float2nr(expr)
  return expr
end

---Round {Expr} Down
---@return number
function fn.floor(expr)
  return expr
end

---Remainder Of {Expr1}/ {Expr2}
---@return number
function fn.fmod(expr1, expr2)
  return expr1, expr2
end

---Escape Special Characters In {Fname}
---@return string
function fn.fnameescape(fname)
  return fname
end

---Modify File Name
---@return string
function fn.fnamemodify(fname, mods)
  return fname, mods
end

---First Line Of Fold At {Lnum} If Closed
---@return number
function fn.foldclosed(lnum)
  return lnum
end

---Last Line Of Fold At {Lnum} If Closed
---@return number
function fn.foldclosedend(lnum)
  return lnum
end

---Fold Level At {Lnum}
---@return number
function fn.foldlevel(lnum)
  return lnum
end

---Line Displayed For Closed Fold
---@return string
function fn.foldtext()
  return nil
end

---Text For Closed Fold At {Lnum}
---@return string
function fn.foldtextresult(lnum)
  return lnum
end

---Bring The Vim Window To The Foreground
---@return number
function fn.foreground()
  return nil
end

---Named Reference To Function Fn.{Name}
---@return nil
function fn.Function(name, arglist, dict)
  return name, arglist, dict
end

---Free Memory, Breaking Cyclic References
function fn.garbagecollect(atexit)
  return atexit
end

---Get Item {Idx} From {List} Or {Def}
---@return table
function fn.get(list, idx, def)
  return list, idx, def
end

---Information About Buffers
---@return table
function fn.getbufinfo(buf)
  return buf
end

---Lines {Lnum} To {End} Of Buffer {Buf}
---@return table
function fn.getbufline(buf, lnum, lend)
  return buf, lnum, lend
end

---Variable {Varname} In Buffer {Buf}
---@return table
function fn.getbufvar(buf, varname, def)
  return buf, varname, def
end

---List Of Change List Items
---@return table
function fn.getchangelist(buf)
  return buf
end

---Get One Character From The User
---@return number or String
function fn.getchar(expr)
  return expr
end

---Modifiers For The Last Typed Character
---@return number
function fn.getcharmod()
  return nil
end

---Last Character Search
---@return table
function fn.getcharsearch()
  return nil
end

---Get One Character From The User
---@return string
function fn.getcharstr(expr)
  return expr
end

---Return The Current Command-line
---@return string
function fn.getcmdline()
  return nil
end

---Return Cursor Position In Command-line
---@return number
function fn.getcmdpos()
  return nil
end

---Return Current Command-line Type
---@return string
function fn.getcmdtype()
  return nil
end

---Return Current Command-line Window Type
---@return string
function fn.getcmdwintype()
  return nil
end

---List Of Cmdline Completion Matches
---@return table
function fn.getcompletion(pat, type, filtered)
  return pat, type, filtered
end

---Position Of The Cursor
---@return table
function fn.getcurpos()
  return nil
end

---Get The Current Working Directory
---@return string
function fn.getcwd(winn, tabnr)
  return winn, tabnr
end

---Return Environment Variable
---@return string
function fn.getenv(name)
  return case(name, {
    XDG_CONFIG_HOME = "~/.config",
  })
end

---Name Of Font Being Used
---@return string
function fn.getfontname(name)
  return name
end

---File Permissions Of File {Fname}
---@return string
function fn.getfperm(fname)
  return fname
end

---Size In Bytes Of File {Fname}
---@return number
function fn.getfsize(fname)
  return fname
end

---Last Modification Time Of File
---@return number
function fn.getftime(fname)
  return fname
end

---Description Of Type Of File {Fname}
---@return string
function fn.getftype(fname)
  return fname
end

---List Of Jump List Items
---@return table
function fn.getjumplist(winn, tabnr)
  return winn, tabnr
end

---Lines {Lnum} To {End} Of Current Buffer
---@return table
function fn.getline(lnum, lend)
  return lnum, lend
end

---Get Specific Location List Properties
---@return table
function fn.getloclist(nr, what)
  return nr, what
end

---List Of Global/Local Marks
---@return table
function fn.getmarklist(buf)
  return buf
end

---List Of Current Matches
---@return table
function fn.getmatches(win)
  return win
end

---Last Known Mouse Position
---@return table
function fn.getmousepos()
  return nil
end

---Process Id Of Vim
---@return number
function fn.getpid()
  return nil
end

---Position Of Cursor, Mark, Etc.
---@return table
function fn.getpos(expr)
  return expr
end

---Get Specific Quickfix List Properties
---@return table
function fn.getqflist(what)
  return what
end

---Contents Of A Register
---@return string or List
function fn.getreg(regnam, num, list)
  return regnam, num, list
end

---Information About A Register
---@return table
function fn.getreginfo(regname)
  return regname
end

---Type Of A Register
---@return string
function fn.getregtype(regname)
  return regname
end

---List Of Tab Pages
---@return table
function fn.gettabinfo(expr)
  return expr
end

---Variable {Varname} In Tab {Nr} Or {Def}
---@return table
function fn.gettabvar(nr, varname, def)
  return nr, varname, def
end

---{Name} In {Winnr} In Tab Page {Tabnr}
---@return table
function fn.gettabwinvar(tabnr, winnr, name, def)
  return tabnr, winnr, name, def
end

---Get The Tag Stack Of Window {Nr}
---@return table
function fn.gettagstack(nr)
  return nr
end

---List Of Windows
---@return table
function fn.getwininfo(winid)
  return winid
end

---X And Y Coord In Pixels Of The Vim Window
---@return table
function fn.getwinpos(timeout)
  return timeout
end

---X Coord In Pixels Of Vim Window
---@return number
function fn.getwinposx()
  return nil
end

---Y Coord In Pixels Of Vim Window
---@return number
function fn.getwinposy()
  return nil
end

---Variable {Varname} In Window {Nr}
---@return table
function fn.getwinvar(nr, varname, def)
  return nr, varname, def
end

---Expand File Wildcards In {Expr}
---@return table
function fn.glob(expr, nosuf, list, alllinks)
  return expr, nosuf, list, alllinks
end

---Convert A Glob Pat Into A Search Pat
---@return string
function fn.glob2regpat(expr)
  return expr
end

---Do Glob(Expr) For All Dirs In {Path}
function fn.globpath(path, expr, nosuf, list, alllinks)
  return path, expr, nosuf, list, alllinks
end

---True If Feature {Feature} Supported
---@return number
function fn.has(feature)
  return feature
end

---Check Whether A Key Appears In A Dictionary
---True If {Dict} Has Entry {Key}
---@return number
function fn.has_key(...)
  return nil
end

---If The Window Executed :Lcd Or The Tab Executed :Tcd
---@return number | true
function fn.haslocaldir(winn, tabnr)
  return winn, tabnr
end

---If Mapping To {What} Exists
---@return number | true
function fn.hasmapto(what, mode, abbr)
  return what, mode, abbr
end

---Add An Item To A History
---@return string
function fn.histadd(history, item)
  return history, item
end

---Remove An Item From A History
---@return string
function fn.histdel(history, item)
  return history, item
end

---Get The Item {Index} From A History
---@return string
function fn.histget(history, index)
  return history, index
end

---Highest Index Of A History
---@return number
function fn.histnr(history)
  return history
end

---Syntax Id Of Highlight Group {Name}
---@return number
function fn.hlID(name)
  return name
end

---True If Highlight Group {Name} Exists
---@return number
function fn.hlexists(name)
  return name
end

---Name Of The Machine Vim Is Running On
---@return string
function fn.hostname()
  return nil
end

---Convert Text From One Encoding To Another
---Convert Encoding Of {Expr}
---@return string
function fn.iconv(expr, from, to)
  return expr, from, to
end

---Identifier Of The Container
---@return string
function fn.id(expr)
  return expr
end

---Indent Of Line {Lnum}
---@return number
function fn.indent(lnum)
  return lnum
end

---Index In {Object} Where {Expr} Appears
---@return number
function fn.index(object, expr, start, ic)
  return object, expr, start, ic
end

---Get Input From The User
---@return string
function fn.input(prompt, text, completion)
  return prompt, text, completion
end

---Let The User Pick From A Choice List
---@return number
function fn.inputlist(textlist)
  return textlist
end

---Restore Typeahead
---@return number
function fn.inputrestore()
  return nil
end

---Save And Clear Typeahead
---@return number
function fn.inputsave()
  return nil
end

---Like Input() But Hiding The Text
function fn.inputsecret(prompt, text)
  return prompt, text
end

---Insert {Item} In {Object} [Before {Idx}]
---@return table
function fn.insert(object, item, idx)
  return object, item, idx
end

---Interrupt Script Execution
function fn.interrupt()
  return nil
end

---Bitwise Invert
---@return number
function fn.invert(expr)
  return expr
end

---True If {Directory} Is A Directory
---@return number
function fn.isdirectory(directory)
  return directory
end

---Determine If {Expr} Is Infinity Value (Positive Or Negative)
---Number
function fn.isinf(...)
  return ...
end

---True If {Expr} Is Locked
---@return number
function fn.islocked(expr)
  return expr
end

---True If {Expr} Is Nan
---@return number
function fn.isnan(expr)
  return expr
end

---Key-value Pairs In {Dict}
---@return table
function fn.items(dict)
  return dict
end

---Returns Pid Of A Job.
---@return number
function fn.jobpid(id)
  return id
end

---Resize Pseudo Terminal Window Of A Job
---@return number
function fn.jobresize(id, width, height)
  return id, width, height
end

---Spawns {Cmd} As A Job
---@return number
function fn.jobstart(cm, opts)
  return cm, opts
end

---Stops A Job
---@return number
function fn.jobstop(id)
  return id
end

---Wait For A Set Of Jobs
---@return number
function fn.jobwait(id, timeout)
  return id, timeout
end

---Join {List} Items Into One String
---@return string
function fn.join(list, sep)
  return list, sep
end

---Convert {Expr} From Json
---@return table
function fn.json_decode(expr)
  return expr
end

---Convert {Expr} To Json
---@return string
function fn.json_encode(expr)
  return expr
end

---Keys In {Dict}
---@return table
function fn.keys(dict)
  return dict
end

---The Length Of {Expr}
---@return number
function fn.len(expr)
  return expr
end

---Call {Func} In Library {Lib} With {Arg}
---@return string
function fn.libcall(lib, func, arg)
  return lib, func, arg
end

---Idem, But Return A Number
---@return number
function fn.libcallnr(lib, func, arg)
  return lib, func, arg
end

---Line Nr Of Cursor, Last Line Or Mark
---@return number
function fn.line(expr, winid)
  return expr, winid
end

---Byte Count Of Line {Lnum}
---@return number
function fn.line2byte(lnum)
  return lnum
end

---Lisp Indent For Line {Lnum}
---@return number
function fn.lispindent(lnum)
  return lnum
end

---Current Time
---@return number
function fn.localtime()
  return nil
end

---Natural Logarithm (Base E) Of {Expr}
function fn.log(expr)
  return expr
end

---Logarithm Of Float {Expr} To Base 10
---@return number
function fn.log10(expr)
  return expr
end

---Evaluate Lua Expression
---@return table
function fn.luaeval(exp, expr)
  return exp, expr
end

---Change Each Item In {Expr1} To {Expr}
---@return table
function fn.map(expr1, expr2)
  return expr1, expr2
end

---Rhs Of Mapping {Name} In Mode {Mode}
---@return string or Dict
function fn.maparg(nam, mode, abbr, dict)
  return nam, mode, abbr, dict
end

---Check For Mappings Matching {Name}
---@return string
function fn.mapcheck(nam, mode, abbr)
  return nam, mode, abbr
end

---Position Where {Pat} Matches In {Expr}
---@return number
function fn.match(expr, pa, star, count)
  return expr, pa, star, count
end

---Highlight {Pattern} With {Group}
---@return number
function fn.matchadd(group, patter, priorit, id)
  return group, patter, priorit, id
end

---Highlight Positions With {Group}
---@return number
function fn.matchaddpos(group, lis, priorit, id)
  return group, lis, priorit, id
end

---Arguments Of :Match
---@return table
function fn.matcharg(nr)
  return nr
end

---Delete Match Identified By {Id}
---@return number
function fn.matchdelete(id, win)
  return id, win
end

---Position Where {Pat} Ends In {Expr}
---@return number
function fn.matchend(expr, pa, star, count)
  return expr, pa, star, count
end

---Match And Submatches Of {Pat} In {Expr}
---@return table
function fn.matchlist(expr, pa, star, count)
  return expr, pa, star, count
end

---Match Of A Pattern In A String
---{Count}'Th Match Of {Pat} In {Expr}
---@return string
function fn.matchstr(expr, pa, star, count)
  return expr, pa, star, count
end

---Match And Positions Of A Pattern In A String
---{Count}'Th Match Of {Pat} In {Expr}
---@return table
function fn.matchstrpos(expr, pa, star, count)
  return expr, pa, star, count
end

---Maximum Value Of Items In {Expr}
---@return number
function fn.max(expr)
  return expr
end

---Description Of Menus Matched By {Path}
---@return table
function fn.menu_get(path, modes)
  return path, modes
end

---Minimum Value Of Items In {Expr}
---@return number
function fn.min(expr)
  return expr
end

---Create Directory {Name}
---@return number
function fn.mkdir(name, path, prot)
  return name, path, prot
end

---Current Editing Mode
---@return string
function fn.mode(expr)
  return expr
end

---Dump Objects To Msgpack
---@return table
function fn.msgpackdump(list, type)
  return list, type
end

---Parse Msgpack To A List Of Objects
---@return table
function fn.msgpackparse(data)
  return data
end

---Single Char With Ascii/Utf-8 Value {Expr}
---@return string
function fn.nr2char(exp, utf8)
  return exp, utf8
end

---Bitwise Or
---@return number
function fn.Or(expr, expr2)
  return expr, expr2
end

---Shorten Directory Names In A Path
---@return string
function fn.pathshorten(expr)
  return expr
end

---Evaluate Perl Expression
---@return table
function fn.perleval(expr)
  return expr
end

---{X} To The Power Of {Y}
---@return number
function fn.pow(x, y)
  return x, y
end

---
---Find Previous Non-blank Line
---Line Nr Of Non-blank Line <= {Lnum}
---@return number
function fn.prevnonblank(lnum)
  return lnum
end

---Format Text
---@return string
function fn.printf(fmt, ...)
  return fmt, ...
end

---Get The Effective Prompt Text For A Buffer
---@return string
function fn.prompt_getprompt(buf)
  return buf
end

---Set Prompt Callback Function Fn.
function fn.prompt_setcallback(buf, expr)
  return buf, expr
end

---Set Prompt Interrupt Function Fn.
function fn.prompt_setinterrupt(buf, text)
  return buf, text
end

---Set Prompt Text
function fn.prompt_setprompt(buf, text)
  return buf, text
end

---Position And Size Of Pum If Visible
---@return table
function fn.pum_getpos()
  return nil
end

---Whether Popup Menu Is Visible
---@return number
function fn.pumvisible()
  return nil
end

---Evaluate Python3 Expression
---@return table
function fn.py3eval(expr)
  return expr
end

---Evaluate Python Expression
---@return table
function fn.pyeval(expr)
  return expr
end

---Evaluate Python_x Expression
---@return table
function fn.pyxeval(expr)
  return expr
end

---Items From {Expr} To {Max}
---@return table
function fn.range(expr, max, stride)
  return expr, max, stride
end

---File Names In {Dir} Selected By {Expr}
---@return table
function fn.readdir(dir, expr)
  return dir, expr
end

---Get List Of Lines From File {Fname}
---@return table
function fn.readfile(fname, type, max)
  return fname, type, max
end

---Get The Executing Register Name
---@return string
function fn.reg_executing()
  return nil
end

---Get The Recording Register Name
---@return string
function fn.reg_recording()
  return nil
end

---Get Time Value
---@return table
function fn.reltime(star, lend)
  return star, lend
end

---Turn The Time Value Into A Float
---@return number
function fn.reltimefloat(time)
  return time
end

---Turn Time Value Into A String
---@return string
function fn.reltimestr(time)
  return time
end

---Send Expression
---@return string
function fn.remote_expr(server, string, idvar, timeout)
  return server, string, idvar, timeout
end

---Bring Vim Server To The Foreground
---@return number
function fn.remote_foreground(server)
  return server
end

---Check For Reply String
---@return number
function fn.remote_peek(serverid, retvar)
  return serverid, retvar
end

---Read Reply String
---@return string
function fn.remote_read(serverid, timeout)
  return serverid, timeout
end

---Send Key Sequence
---@return string
function fn.remote_send(server, string, idvar)
  return server, string, idvar
end

---Become Server {Name}
function fn.remote_startserver(name)
  return name
end

---Remove Bytes {Idx}-{End} From {Blob}
---@return number | table
function fn.remove(blob, idx, lend)
  return blob, idx, lend
end

---Rename (Move) File From {From} To {To}
function fn.rename(from, to)
  return from, to
end

---Repeat {Expr} {Count} Times
---@return string
function fn.Repeat(expr, count)
  return expr, count
end

---Get Filename A Shortcut Points To
---@return string
function fn.resolve(filename)
  return filename
end

---Reverse {List} In-place
---@return table
function fn.reverse(...)
  return ...
end

---Round Off {Expr}
---@return number
function fn.round(expr)
  return expr
end

---Notification To {Channel}
function fn.rpcnotify(channel, even, ...)
  return channel, even, ...
end

---Request To {Channel}
function fn.rpcrequest(channel, metho, ...)
  return channel, metho, ...
end

---Evaluate Ruby Expression
---@return table
function fn.rubyeval(expr)
  return expr
end

---Attribute At Screen Position
---@return number
function fn.screenattr(row, col)
  return row, col
end

---Character At Screen Position
---@return number
function fn.screenchar(row, col)
  return row, col
end

---List Of Characters At Screen Position
---@return table
function fn.screenchars(row, col)
  return row, col
end

---Current Cursor Column
---@return number
function fn.screencol()
  return nil
end

---Screen Row And Col Of A Text Character
---@return table
function fn.screenpos(winid, lnum, col)
  return winid, lnum, col
end

---Current Cursor Row
---@return number
function fn.screenrow()
  return nil
end

---Characters At Screen Position
---@return string
function fn.screenstring(row, col)
  return row, col
end

---Search For {Pattern}
---@return number
function fn.search(pattern, flags, stopline, timeout)
  return pattern, flags, stopline, timeout
end

---Get Or Update The Last Search Count
---@return table
function fn.searchcount(options)
  return options
end

---Search For Variable Declaration
---@return number
function fn.searchdecl(name, global, thisblock)
  return name, global, thisblock
end

---Search For Other End Of Start/End Pair
---@return number
function fn.searchpair(start, middle, lend, flags, skip, ...)
  return start, middle, lend, flags, skip, ...
end

---Search For Other End Of Start/End Pair
---@return table
function fn.searchpairpos(start, middle, lend, flags, skip, ...)
  return start, middle, lend, flags, skip, ...
end

---Search For {Pattern}
---@return table
function fn.searchpos(pattern, flags, stopline, timeout)
  return pattern, flags, stopline, timeout
end

---Send Reply String
---@return number
function fn.server2client(clientid, string)
  return clientid, string
end

---Get A List Of Available Servers
---@return string
function fn.serverlist()
  return nil
end

---Set Line {Lnum} To {Line} In Buffer {Expr}
---@return number
function fn.setbufline(expr, lnum, line)
  return expr, lnum, line
end

---{Varname} In Buffer {Buf} To {Val}
function fn.setbufvar(buf, varname, val)
  return buf, varname, val
end

---Set Character Search From {Dict}
---@return table
function fn.setcharsearch(dict)
  return dict
end

---Set Cursor Position In Command-line
---@return number
function fn.setcmdpos(pos)
  return pos
end

---Set Environment Variable
function fn.setenv(name, val)
  return name, val
end

---Set {Fname} File Permissions To {Mode}
---@return number
function fn.setfperm(fname, mode)
  return fname, mode
end

---Set Line {Lnum} To {Line}
---@return number
function fn.setline(lnum, line)
  return lnum, line
end

---Modify Specific Location List Props
---@return number
function fn.setloclist(nr, list, action, what)
  return nr, list, action, what
end

---Restore A List Of Matches
---@return number
function fn.setmatches(list, win)
  return list, win
end

---Set The {Expr} Position To {List}
---@return number
function fn.setpos(expr, list)
  return expr, list
end

---Modify Specific Quickfix List Props
---@return number
function fn.setqflist(list, action, what)
  return list, action, what
end

---Set Register To Value And Type
---@return number
function fn.setreg(n, opt)
  return n, opt
end

---{Varname} In Tab Page {Nr} To {Val}
---@return table
function fn.settabvar(nr, varname, val)
  return nr, varname, val
end

---{Winnr} In Tab Page {Tabnr} To {Val}
---{varname} in window {winnr} to {val} in tab page {tabnr}
---@return table
function fn.settabwinvar(tabnr, winnr, varname, val)
  return tabnr, winnr, varname, val
end

---Modify Tag Stack Using {Dict}
---@return number
function fn.settagstack(nr, dict, action)
  return nr, dict, action
end

---{Varname} In Window {Nr} To {Val}
---@return table
function fn.setwinvar(nr, varname, val)
  return nr, varname, val
end

---Sha256 Checksum Of {String}
---@return string
function fn.sha256(string)
  return string
end

---Escape {String} For Use As Shell Command Argument
---@return string
function fn.shellescape(string, special)
  return string, special
end

---Effective Value Of 'Shiftwidth'
---@return number
function fn.shiftwidth(col)
  return col
end

---Define Or Update A Sign
---@return number | table
function fn.sign_define(name, dict)
  return name, dict
end

---Get A List Of Defined Signs
---@return table
function fn.sign_getdefined(...)
  return ...
end

---Get A List Of Placed Signs
---@return table
function fn.sign_getplaced(bu, dict)
  return bu, dict
end

---Jump To A Sign
---@return number
function fn.sign_jump(id, group, buf)
  return id, group, buf
end

---Place A Sign
---@return number
function fn.sign_place(id, group, name, buf, dict)
  return id, group, name, buf, dict
end

---Place A List Of Signs
---@return table
function fn.sign_placelist(...)
  return ...
end

---Undefine A Sign
---Undefine A List Of Signs
---@return table | number
function fn.sign_undefine(...)
  return ...
end

---Unplace A Sign
---@return number
function fn.sign_unplace(group, dict)
  return group, dict
end

---Unplace A List Of Signs
---@return table
function fn.sign_unplacelist(...)
  return ...
end

---Simplify Filename As Much As Possible
---@return string
function fn.simplify(filename)
  return filename
end

---Sine Of {Expr}
---@return number
function fn.sin(expr)
  return expr
end

---Hyperbolic Sine Of {Expr}
---@return number
function fn.sinh(expr)
  return expr
end

---Connects To Socket
---@return number
function fn.sockconnect(mode, address, opts)
  return mode, address, opts
end

---Sort {List}, Using {Func} To Compare
---@return table
function fn.sort(list, func, dict)
  return list, func, dict
end

---Sound-fold {Word}
---@return string
function fn.soundfold(word)
  return word
end

---Badly Spelled Word At Cursor
---@return string
function fn.spellbadword()
  return nil
end

---Spelling Suggestions
---@return table
function fn.spellsuggest(word, max, capital)
  return word, max, capital
end

---Make List From {Pat} Separated {Expr}
---@return table
function fn.split(expr, pat, keepempty)
  return expr, pat, keepempty
end

---Square Root Of {Expr}
---@return number
function fn.sqrt(expr)
  return expr
end

---Open Stdio In A Headless Instance.
---@return number
function fn.stdioopen(dict)
  return dict
end

---Returns The Standard Path(S) For {What}
---@param stdpath 'cache' | 'config' | 'config_dirs' | 'data' | 'data_dirs' | 'log' | 'run'
---@return string
function fn.stdpath(stdpath)
  return case(stdpath, {
    cache = "~/.cache/nvim",
    config = "~/.config/nvim",
    config_dirs = "~/.config/nvim",
    data = "~/.local/share/nvim",
    data_dirs = "~/.local/share/nvim",
    log = "~/.local/share/nvim/logs",
    run = "~/.local/share/nvim/run"
  })
end

---Convert String To Float
---@return number
function fn.str2float(expr, quoted)
  return expr, quoted
end

---Convert Each Character Of {Expr} To Ascii Utf-8 Value
---@return table
function fn.str2list(expr, utf8)
  return expr, utf8
end

---Get Part Of A String Using Char Index
---{Len} Characters Of {Str} At Character {Start}
---@return string
function fn.strcharpart(str, start, len)
  return str, start, len
end

---Character Length Of The String {Expr}
---@return number
function fn.strchars(expr, skipcc)
  return expr, skipcc
end

---Size Of String When Displayed, Deals With Tabs
---Display Length Of The String {Expr}
---@return number
function fn.strdisplaywidth(expr, col)
  return expr, col
end

---Format Time With A Specified Format
---@return string
function fn.strftime(format, time)
  return format, time
end

---Get Character From A String Using Char Index
---Get Char {Index} From {Str}
---@return number
function fn.strgetchar(str, index)
  return str, index
end

---First Index Of A Short String In A Long String
---Index Of {Needle} In {Haystack}
---@return number
function fn.stridx(haystack, needle, start)
  return haystack, needle, start
end

---String Representation Of {Expr} Value
---@return string
function fn.string(expr)
  return expr
end

---Length Of The String {Expr}
---@return number
function fn.strlen(expr)
  return expr
end

---Get Part Of A String Using Byte Index
---{Len} Bytes/Chars Of {Str} Atbyte {Start}
---@return string
function fn.strpart(str, start, len, chars)
  return str, start, len, chars
end

---Convert {Timestring} To Unix Timestamp
---@return number
function fn.strptime(format, timestring)
  return format, timestring
end

---Last Index Of {Needle} In {Haystack}
---@return number
function fn.strridx(haystack, needle, start)
  return haystack, needle, start
end

---Translate String To Make It Printable
---@return string
function fn.strtrans(expr)
  return expr
end

---Size Of String When Displayed
---Display Cell Length Of The String {Expr}
---@return number
function fn.strwidth(expr)
  return expr
end

---Or List Specific Match In ":S" Or Substitute()
function fn.submatch(nr, list)
  return nr, list
end

---Substitute A Pattern Match With A String
---All {Pat} In {Expr} Replaced With {Sub}
---@return string
function fn.substitute(expr, pat, sub, flags)
  return expr, pat, sub, flags
end

---Information About Swap File {Fname}
---@return table
function fn.swapinfo(fname)
  return fname
end

---Swap File Of Buffer {Buf}
---@return string
function fn.swapname(buf)
  return buf
end

---Syntax Id At {Lnum} And {Col}
---@return number
function fn.synID(lnum, col, trans)
  return lnum, col, trans
end

---Attribute {What} Of Syntax Id {Synid}
---@return string
function fn.synIDattr(synID, what, mode)
  return synID, what, mode
end

---Translated Syntax Id Of {Synid}
---@return number
function fn.synIDtrans(synID)
  return synID
end

---Info About Concealing
---@return table
function fn.synconcealed(lnum, col)
  return lnum, col
end

---Stack Of Syntax Ids At {Lnum} And {Col}
---@return table
function fn.synstack(lnum, col)
  return lnum, col
end

---Output Of Shell Command/Filter {Cmd}
---@return string
function fn.system(cmd, input)
  return cmd, input
end

---Output Of Shell Command/Filter {Cmd}
---@return table
function fn.systemlist(cmd, input)
  return cmd, input
end

---List Of Buffer Numbers In Tab Page
---@return table
function fn.tabpagebuflist(arg)
  return arg
end

---Number Of Current Or Last Tab Page
---@return number
function fn.tabpagenr(arg)
  return arg
end

---Number Of Current Window In Tab Page
---@return number
function fn.tabpagewinnr(tabar, arg)
  return tabar, arg
end

---Tags Files Used
---@return table
function fn.tagfiles()
  return nil
end

---List Of Tags Matching {Expr}
---@return table
function fn.taglist(exp, filename)
  return exp, filename
end

---Tangent Of {Expr}
---@return number
function fn.tan(expr)
  return expr
end

---Hyperbolic Tangent Of {Expr}
---@return number
function fn.tanh(expr)
  return expr
end

---Name For A Temporary File
---@return string
function fn.tempname()
  return nil
end

---Free Memory Right Now For Testing
function fn.test_garbagecollect_now()
  return nil
end

---Information About Timers
---@return table
function fn.timer_info(id)
  return id
end

---Pause Or Unpause A Timer
function fn.timer_pause(id, pause)
  return id, pause
end

---Create A Timer
---@return number
function fn.timer_start(time, callback, options)
  return time, callback, options
end

---Stop A Timer
function fn.timer_stop(timer)
  return timer
end

---Stop All Timers
function fn.timer_stopall()
  return nil
end

---The String {Expr} Switched To Lowercase
---@return string
function fn.tolower(expr)
  return expr
end

---The String {Expr} Switched To Uppercase
---@return string
function fn.toupper(expr)
  return expr
end

---Translate Chars Of {Src} In {Fromstr} To Chars In {Tostr}
---@return string
function fn.tr(src, fromstr, tostr)
  return src, fromstr, tostr
end

---Trim Characters In {Mask} From {Text}
---@return string
function fn.trim(text, mask, dir)
  return text, mask, dir
end

---Truncate Float {Expr}
---@return number
function fn.trunc(expr)
  return expr
end

---Type Of Variable {Name}
---@return number
function fn.type(name)
  return name
end

---Undo File Name For {Name}
---@return string
function fn.undofile(name)
  return name
end

---Undo File Tree
---@return table
function fn.undotree()
  return nil
end

---Remove Adjacent Duplicates From A List
---@return table
function fn.uniq(list, func, dict)
  return list, func, dict
end

---Values In {Dict}
---@return table
function fn.values(dict)
  return dict
end

---Screen Column Of Cursor Or Mark
---@return number
function fn.virtcol(expr)
  return expr
end

---Last Visual Mode Used
---@return string
function fn.visualmode(expr)
  return expr
end

---Wait Until {Condition} Is Satisfied
---@return number
function fn.wait(timeout, conditio, interval)
  return timeout, conditio, interval
end

---Whether 'Wildmenu' Mode Is Active
---@return number
function fn.wildmenumode()
  return nil
end

---Execute {Command} In Window {Id}
---@return string
function fn.win_execute(id, command, silent)
  return id, command, silent
end

---Find Windows Containing {Bufnr}
---@return table
function fn.win_findbuf(bufnr)
  return bufnr
end

---Get Window-id For {Win} In {Tab}
---@return number
function fn.win_getid(wi, tab)
  return wi, tab
end

---Type Of Window {Nr}
---@return string
function fn.win_gettype(nr)
  return nr
end

---Go To {Expr}
---@return number
function fn.win_gotoid(expr)
  return expr
end

---Get Tab And Window Nr From Window-id
---@return table
function fn.win_id2tabwin(expr)
  return expr
end

---Get Window Nr From Window-id
---@return number
function fn.win_id2win(expr)
  return expr
end

---Get Screen Position Of Window {Nr}
---@return table
function fn.win_screenpos(nr)
  return nr
end

---Move Window {Nr} To Split Of {Target}
---@return number
function fn.win_splitmove(nr, target, options)
  return nr, target, options
end

---Buffer Number Of Window {Nr}
---@return number
function fn.winbufnr(nr)
  return nr
end

---Window Column Of The Cursor
---@return number
function fn.wincol()
  return nil
end

---Ms-windows Os Version
---@return string
function fn.windowsversion()
  return nil
end

---Height Of Window {Nr}
---@return number
function fn.winheight(nr)
  return nr
end

---Layout Of Windows In Tab {Tabnr}
---@return table
function fn.winlayout(tabnr)
  return tabnr
end

---Window Line Of The Cursor
---@return number
function fn.winline()
  return nil
end

---Number Of Current Window
---@return number
function fn.winnr(expr)
  return expr
end

---Returns Command To Restore Window Sizes
---@return string
function fn.winrestcmd()
  return nil
end

---Restore View Of Current Window
function fn.winrestview(dict)
  return dict
end

---Save View Of Current Window
---@return table
function fn.winsaveview()
  return nil
end

---Width Of Window {Nr}
---@return number
function fn.winwidth(nr)
  return nr
end

---Get Byte/Char/Word Statistics
---@return table
function fn.wordcount()
  return nil
end

---Write Blob Or List Of Lines To File
---@return number
function fn.writefile(object, fname, flags)
  return object, fname, flags
end

---Bitwise Xor
---@return number
function fn.xor(expr, expr2)
  return expr, expr2
end

return fn
