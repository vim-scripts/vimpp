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
function! s:list2set(list)
    return eval('{'.join(map(a:list, 'string(v:val).'':''.1'),',').'}')
endf
function! vimpp#InitClassPath()
    if !exists('g:VimPlusPlus')
        let g:VimPlusPlus = {}
    endif
    call extend(g:VimPlusPlus, {'classpath': {}}, 'keep')
    if type(g:VimPlusPlus.classpath) == type('')
        call extend(g:VimPlusPlus, {'classpath': s:list2set(split(g:VimPlusPlus.classpath, ','))})
    endif
    call extend(g:VimPlusPlus.classpath, s:list2set(split(&runtimepath, ',')))
endf
function! vimpp#Load()
    if exists('g:loaded_VimPlusPlus') && g:loaded_VimPlusPlus 
        return 1
    endif
    call vimpp#InitClassPath()
    for dir in keys(g:VimPlusPlus.classpath)
        for file in split(glob(dir.'/plugin/vim++*.vim'), '\n')
            exec 'so '.file
        endfor
    endfor
    return g:loaded_VimPlusPlus
endf
