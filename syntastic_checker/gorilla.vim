"============================================================================
"File:        gorilla.vim
"Description: Syntax checking plugin for syntastic.vim
"Maintainer:  "UnCO" Lin
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================
if exists("g:loaded_syntastic_gorilla_gorilla_checker")
    finish
endif
let g:loaded_syntastic_gorilla_gorilla_checker=1

let s:save_cpo = &cpo
set cpo&vim

function! SyntaxCheckers_gorilla_gorilla_IsAvailable() dict
    return executable(self.getExec())
endfunction

function! SyntaxCheckers_gorilla_gorilla_GetLocList() dict
    let makeprg = self.makeprgBuild({
                \ 'exe': 'gorilla',
                \ 'args_after': '-p'})
    let errorformat =
        \ '%\\w%\\+%trror:\ %m\ at\ %f:%l:%c,%-G%.%#'

    return SyntasticMake({
          \ 'makeprg': makeprg,
          \ 'errorformat': errorformat})
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
    \ 'filetype': 'gorilla',
    \ 'name': 'gorilla'})

let &cpo = s:save_cpo
unlet s:save_cpo

