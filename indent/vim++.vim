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
" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
so $VIMRUNTIME/indent/vim.vim            
setlocal indentexpr=GetVimPlusPlusIndent()
setlocal indentkeys+==EndClass
function! GetVimPlusPlusIndent()
    let indent = GetVimIndent()
    if getline(line('.') - 1) =~ '^\s*\(Class\|Constr\|Method\)\>'
        let indent += &sw
    endif
    if getline('.') =~ '^\s*End\(Class\|Constr\)\>'
        let indent -= &sw
    endif
    return indent
endf
let b:did_indent = 1


