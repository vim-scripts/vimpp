" vim++: Object-oriented programming for Vim
" Author: Michael Shvarts
" Copyright: (c) 2007 by Michael Shvarts(shvarts@akmosoft.com)
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               vim++.vim(i.e. plugin/vim++.vim, syntax/vim++.vim, ftdetect/vim++.vim 
"               and indent/vim++),  vimReflection.vim++ and vimpp.vim are provided
"               *as is* and comes with no warranty of any kind, either
"               expressed or implied. By using this plugin, you agree that
"               in no event will the copyright holder be liable for any damages
"               resulting from the use of this software.
"{{{--------Init global variables----------
call vimpp#InitClassPath()
let g:VimPlusPlus.version = '0.1.0'
let g:VimPlusPlus[g:VimPlusPlus.version] = {'loaded': {'vim++': g:VimPlusPlus.version}}
let g:loaded_VimPlusPlus = 1
"}}}
"{{{--------Auxillary functions-----------------------
let s:open = {'{': {'close': '}', 'name': 'brace'}, '[': {'close': ']', 'name': 'bracket'}, '(': {'close': ')', 'name': 'parenthesis'}}
let s:s = {}
for s:c in keys(s:open)
    call extend(s:open[s:c],{'count': 0, 'open': s:c})
endfor
function! s:findLValue(expr,char)
    let i = 0
    let quoted = 0
    let len = len(a:expr)
    let open = deepcopy(s:open)
    let close = {}
    for c in keys(open)
        let close[open[c]['close']] = open[c]
    endfor
    while i < len
        let char = a:expr[i]
        if quoted == 0
            if char == "'"
                let quoted = 1
            elseif char == '"'
                let quoted = 2
            elseif has_key(open, char)
                let open[char].count += 1
            elseif has_key(close, char)
                let close[char].count -= 1
                if close[char].count < 0
                    throw "Unmatched ".close[char].name." near ".strpart(a:expr, i + 1)
                endif
            elseif char == a:char && !len(filter(values(open), 'v:val.count')) && strpart(a:expr, 0, i + 1) !~ '\<[abglstvw]:$'
                return i
            endif
        elseif quoted == 1
            if char == "'"
                let quoted = 0
            endif
        elseif quoted == 2
            if char == '"'
                let quoted = 0
            elseif char == '\'
                let quoted = 3
            endif
        elseif quoted == 3
            let quoted = 2
        endif
        let i += 1
    endw
    return -1
endf
function! s:Init(filename)
    let s:file = readfile(a:filename)
endf
function! s:Class(qArgs)
    for key in keys(g:)
        exec 'let '.key.' = g:["'.escape(key, '"').'"]'
    endfor
    let colonIdx = s:findLValue(a:qArgs, ':')
    let s:type += 1
    let s:class = {'$base': [], '$type': s:type}
    let s:class['$class'] = s:class
    if colonIdx == -1
        let lValue = a:qArgs
        let s:class['$base'] = exists('g:Object')?[g:Object] : []
    else
        let lValue = strpart(a:qArgs, 0, colonIdx)
        let s:class['$base'] = eval('['.strpart(a:qArgs, colonIdx + 1).']')
    endif
    if lValue !~ '^[abglstvw]:' 
        let lValue = 'g:'.lValue
    endif
    exec 'let '.lValue.'=s:class'
endf
function! s:ParseConstr(qArgs)
    let [all, func, funcname, args, dots, supers; rest] = matchlist(a:qArgs, '\s*\(\(\%([abglstvw]:\)\?\w\+\)\s*(\s*\%(\(\%(\w\+\s*,\s*\)*\%(\w\+\|\(\.\.\.\)\)\)\s*\)\?)\)\s*\%(:\(.*\)\)\?')
    let arglist = split(args, '\s*,\s*')
    if dots != ''
        call remove(arglist, -1)
    endif
    return [func, funcname, '['.join(map(arglist, "'a:'.v:val"), ',').']'.(dots!=''? ' + a:000': ''), supers] 
endf
function! AddGlobals(locals, supers)
    let vars = split(a:supers, '\([^[:alnum:]]\|[abglstvw]:\w\+\)\+')
    for var in vars
        if exists('g:'.var)
            call extend(a:locals[0], {var : g:[var]})
        endif
    endfor
endf
function! s:ExecSuper(self, supers)
    let val = {}
    for super in a:supers "eval('['.a:supers.']')
        call extend(val, super, 'keep')
    endfor
    let copy = copy(a:self) 
    let obj = extend(deepcopy(filter(copy(copy),'v:key[0] != "$"')), filter(copy, 'v:key[0] == "$"'))   
    call extend(obj, val, 'keep')
    for base in obj['$base']
        call extend(obj, base, 'keep')
    endfor
    return obj
endf
function! s:Construct(qArgs, throwpoint)
    let [all,filename,lnum;rest] = matchlist(a:throwpoint, '\(.*\S\)\s*,\s*line\s\+\(\d\+\)')
    if !exists('s:file')
        call s:Init(filename)
    endif
    let func = matchstr(a:qArgs, '\w\+')
    let body = 'function! s:class.'.a:qArgs." \n if self == self['$class'] \n let obj = extend(deepcopy(filter(self,'v:key[0] != \"$\"')), filter(self, 'v:key[0] == \"$\"')) \n return call(obj[matchstr(<q-args>, '\w\+')], filter(a:,\"!has_key({0:1,000:1,'firstline':1,'lastline':1},v:key)\"),'dict') \n endif\n" 
    do
    for line in s:file[(lnum):]
        if line !~ '^\s*EndCo\%[nstr\]'
            let body .= line."\n"
        else
            let body .= "return self \n endf"
            echo body
            exec body
            return
        endif
    endfor
endf
function! s:EndClass()
    for parent in s:class['$base']
        call extend(s:class, filter(copy(parent), 'type(v:val) == 2'), 'keep')
    endfor 
endf
function! VersionSubst(ver)
    return substitute(substitute(a:ver, '[.]\@<!\<\(\d\{1,8\}\.\)\+\d\{1,8\}\>[.]\@!', '\="''".join(map(split(submatch(0), ''\.''),''printf("%.8i", v:val)''), ''.'')."''"', 'g'), '\(\.0\+\)\+[[:digit:].]\@!', '', 'g')
endf
function! VersionCompare(v1, v2)
    if a:v2 == '' 
        return 0
    endif
    try
        let ver = eval(VersionSubst(a:v1))
    catch /.*/
        throw 'Invalid expression: '.a:v1
        return 0
    finally
    endt
    try
        let required = eval(VersionSubst(a:v2))
    catch /.*/
        throw 'Invalid expression: '.a:v2
        return 0
    finally
    endt
    if type(required) == type(1)
        return required
    elseif type(required) == type('')
        let min = min([strlen(ver), strlen(required)]) - 1
        return ver[:min] == required[:min]
    else
        throw 'Import syntax error: version requirement must evaluate to string or bool'
    endif 
endf
function! s:ImportGlob(glob)
    let c = 0
    for dir in keys(g:VimPlusPlus.classpath)
        for file in split(glob(dir.'/'.a:glob), '\n')
            "try
                exec 'so '.file
            "catch /.*/
            "    echo "Exception caught: ".v:exception
            "endt
            let root = fnamemodify(file, ':t:r')
            if has_key(g:VimPlusPlus[g:VimPlusPlus.version].loaded, root) 
                let c += 1
                if type(g:VimPlusPlus[g:VimPlusPlus.version].loaded[root]) == type(1)
                    let g:VimPlusPlus[g:VimPlusPlus.version].loaded[root] = '1.0'
                endif
            endif
        endfor
    endfor
    return c
endf
function! s:Import(qArgs)
    let libs = {}
    let qArgs = a:qArgs
    while strlen(qArgs)
        let index = s:findLValue(qArgs, ',')
        if index == -1
            let import = qArgs
            let qArgs = ''
        else
            let import = strpart(qArgs, 0, index)
            let qArgs = strpart(qArgs, index + 1)
        endif
        let pair = matchlist(import, '^\s*\(\S\+\)\%(\s\+\(.*\)\)\?')
        if !len(pair)
             throw '"Import" command syntax error: package name expected'
             return 0
         endif
         let libs[pair[1]] = pair[2]
     endw
     for lib in items(libs)
         if !VersionCompare(get(g:VimPlusPlus[g:VimPlusPlus.version].loaded, lib[0], '0.0'), lib[1])
             if lib[0] == 'vim++'
                 return 2
             endif
             let g:VimPlusPlus[g:VimPlusPlus.version].loaded[lib[0]] = lib[1]
             if !s:ImportGlob('plugin/'.tr(lib[0], '.', '/').'.vim++')
                 if has_key(g:VimPlusPlus[g:VimPlusPlus.version].loaded, lib[0])
                     call remove(g:VimPlusPlus[g:VimPlusPlus.version].loaded, lib[0])
                 endif
                 return 0
             endif
         endif
     endfor
     return 1
 endf
function! s:Package(filename, ver, isLib)
    let lib = fnamemodify(a:filename, ':t:r')
    let ver = a:ver != ''? a:ver : '1.0'
    if !has_key(g:VimPlusPlus[g:VimPlusPlus.version].loaded, lib) 
        if a:isLib
            return 0
        endif
    else
        if g:VimPlusPlus[g:VimPlusPlus.version].loaded[lib] != ''
            if !VersionCompare(ver, g:VimPlusPlus[g:VimPlusPlus.version].loaded[lib])
                call remove(g:VimPlusPlus[g:VimPlusPlus.version].loaded, lib)
                return 0
            endif
        endif
    endif
    let g:VimPlusPlus[g:VimPlusPlus.version].loaded[lib] = ver
    return 1
endf
function! VimPP_ExportNamespace(s)
    let s:s = a:s
endf
let s:type = 4
"}}}
"{{{--------Command Definitions---------------------
command! -nargs=+ EchoErr  echohl Error | echomsg <args> | echohl Normal
command! -nargs=+ EchoErrWithPoint try | throw '' | catch /.*/ | exec "EchoErr 'In file '.v:throwpoint.': '".<q-args>  | endt
command! -nargs=+ Class  try | call s:Class(<q-args>) | catch /.*/ | let s:e = v:exception| exec 'EchoErrWithPoint "Class syntax error: ".s:e' | endt
command! -nargs=0 EndClass try | call s:EndClass() | catch /.*/ | let s:e = v:exception| exec 'EchoErrWithPoint "Class syntax error: ".s:e' | endt
command! -nargs=+ Var exec 'let s:class.'.<q-args>
command! -nargs=+ Method function! s:class.<args>
command! -nargs=+ Abstract exec 'function! s:class.'.<q-args>." \n throw 'Cannot invoke abstract method!' \n  endf"
command! -nargs=+ Constr let [s:func, s:funcname, s:arglist, s:supers] = s:ParseConstr(<q-args>) | exec 'function! s:class.'.s:func." \n if !has_key(self, '$constr') \n  \" call AddGlobals([l:], ".string(s:supers).") \n let obj = s:ExecSuper(self, [".s:supers."]) \n let obj['$constr'] = 1 \n let obj = call(obj.".s:funcname.", ".s:arglist.", obj) \n if has_key(obj, '$constr') \n call remove(obj, '$constr')\n endif \n return obj\n endif" 
command! -nargs=0 EndConstr exec "return self \n endf"
command! -nargs=+ Import  try | let s:success = s:Import(<q-args>) | if !s:success | exec 'EchoErrWithPoint "Cannot find one or more libraries in ".'.string(string(<q-args>)) | finish | elseif s:success == 2 | finish | endif | catch /.*/ | let s:e = v:exception | exec 'EchoErrWithPoint "Error importing: ".s:e'| finish | endt
command! -nargs=? Package if !s:Package(expand('<sfile>'), <q-args>, 0) | finish | endif
command! -nargs=? Library if !s:Package(expand('<sfile>'), <q-args>, 1) | finish | endif
"}}}
"{{{--------Class Object-----------------------------
Class Object
    Method is(class)
        return Type(self) == Type(a:class)
        "return filter(copy(self),'type(v:val) == 2') == filter(copy(a:class),'type(v:val) == 2')
    endf
    Method HasParent(class)
        for base in self['$base']
            if base.is(a:class)
                return 1
            endif
        endfor
        return 0
    endf
    Method HasAncestor(class)
        for base in self['$base']
            if base.is(a:class) || base.HasAncestor(a:class)
                return 1
            endif
        endfor
        return 0
    endf
EndClass
function! Type(obj)
    if type(a:obj) != type({}) || !has_key(a:obj, '$type')
        return type(a:obj)
    else 
        return a:obj['$type']
    endif
endf
"}}}
"{{{--------Load Plugins
call s:ImportGlob('plugin/*.vim++')
"}}} vim:ft=vim++ foldmethod=marker
