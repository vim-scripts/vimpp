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
" For version 5.x, clear all syntax items.
" For version 6.x, quit when a syntax file was already loaded.
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif
so $VIMRUNTIME/syntax/vim.vim
syn cluster vimppEval contains=vimppParen,vimppBrackets,vimppBraces,vimppString,vimppVersion,vimppFuncName,vimppInt,vimppComment
syn match vimppPreproc #^\s*\(Import\|Package\|Library\)\s\+\([^|]\|'[^']*'\|"\([^"]\|\\"\)*"\)\+\(|\|$\)# contains=vimppImport,vimppPackage,@vimppEval
syn match vimppImport '^\s*Import\>' contained nextgroup=vimppPackName skipwhite
syn match vimppPackName '\S\+' contained 
syn match vimppPackName ',\s*\w\+\s\+\<'ms=s+1 contained containedin=vimppPreproc
syn match vimppPackage '^\s*\(Package\|Library\)\>' contained
syn region vimppParen start='(' end=')' skip=/'[^']*'\|"\([^"]\|\\"\)*"/ contained contains=@vimppEval
syn region vimppBrackets start='\[' end=']' skip=/'[^']*'\|"\([^"]\|\\"\)*"/ contained contains=@vimppEval
syn region vimppBraces start='{' end='}' skip=/'[^']*'\|"\([^"]\|\\"\)*"/ contained contains=@vimppEval
exec 'syn keyword vimppFuncName contained  '.join(split(CommandOutput('syn list vimFuncName'), '\n\(\(\s\+\|vimFuncName\s\+xxx\)\s\+contained\s\+\)\?')[1:-2], ' ')
syn match vimppString  /'[^']*'\|"\([^"]\|\\"\)*"/ contained contains=vimppVersion
syn match vimppComment '"[^"]*$' contained 
syn match vimppInt /[.]\@<!\<\d\+\>[.]\@!/ contained
syn match vimppEvalWrapper '.*' contained contains=@vimppEval
syn match vimppVersion  /[.[:alnum:]]\@<!\(\d\{1,8\}\.\)\+\d\{1,8\}[.[:alnum:]]\@!/ contained
syn match vimppKeyw '\<\(Var\|EndC\%[lass]\|EndCo\%[nstr]\|Su\%[per]\|Me\%[thod]\|Abstr\%[act]\)\>' 
syn match vimppClassDef '^\s*\<Cla\%[ss]\s\+.*' contains=vimppClass 
syn match vimppClass '\<Cla\%[ss]\>' contained nextgroup=vimppEvalWrapper skipwhite
syn match vimppConstrDef '^\s*\<Con\%[str]\s\+.*' contains=vimppConstr
syn match vimppConstr '\<Con\%[str]\>' contained nextgroup=vimppEvalWrapper skipwhite
"syn match vimppOp '[\[\]]' contained containedin=vimppBrackets
"syn match vimppOp '[{}]' contained containedin=vimppBraces
"syn match vimppOp '[()]' contained containedin=vimppParen
syn match vimppOp '+-=<>!/\*' contained containedin=@vimppEval

" For version 5.x and earlier, only when not done already.
" For version 5.8 and later, only when an item doesn't have highlighting yet.
if version >= 508 || !exists("did_command_cmd_syn_inits")
  if version < 508
    let did_command_cmd_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink vimppKeyw Type
  HiLink vimppClass Type
  HiLink vimppConstr Type
  HiLink vimppPackage PreProc
  HiLink vimppPackName Type
  HiLink vimppString String
  HiLink vimppVersion PreProc
  HiLink vimppImport PreProc
  HiLink vimppFuncName Identifier
  HiLink vimppInt Number
  HiLink vimppOp Statement
  HiLink vimppComment Comment
  delcommand HiLink
endif
let b:current_syntax = "vim++"
