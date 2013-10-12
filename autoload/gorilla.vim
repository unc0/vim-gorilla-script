" Language:    GorillaScript
" Maintainer:  "UnCO" Lin
" URL:         http://github.com/unc0/vim-gorilla-script
" License:     WTFPL

" Set up some common global/buffer variables.
function! gorilla#GorillaSetUpVariables()
  " Path to gorilla executable
  if !exists('g:gorilla_compiler')
    let g:gorilla_compiler = 'gorilla'
  endif

  " Options passed to gorilla with make
  if !exists('g:gorilla_make_options')
    let g:gorilla_make_options = ''
  endif
endfunction

function! gorilla#GorillaSetUpErrorFormat()
  CompilerSet errorformat=Compiling\ %.%#.gs\ ...\ %\\w%\\+%trror:\ %m\ at\ %f:%l:%c,%-G%.%#
endfunction
