" Language:    GorillaScript
" Maintainer:  "UnCO" Lin
" URL:         http://github.com/unc0/vim-gorilla-script
" License:     WTFPL

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

let b:undo_ftplugin = "setl isk< fo< com< cms< ofu< sua<"

setlocal isident+=$
setlocal iskeyword+=-,!
setlocal formatoptions-=t formatoptions+=crql
setlocal comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,://
setlocal commentstring=//\ %s
setlocal omnifunc=javascriptcomplete#CompleteJS
setlocal suffixesadd=.gs,.js

" Create custom augroups.
augroup GorillaBufUpdate | augroup END
augroup GorillaBufNew | augroup END

" Enable GorillaMake if it won't overwrite any settings.
if !len(&l:makeprg)
  compiler gorilla
endif

" Switch to the window for buf.
function! s:SwitchWindow(buf)
  exec bufwinnr(a:buf) 'wincmd w'
endfunction

" Create a new scratch buffer and return the bufnr of it. After the function
" returns, vim remains in the scratch buffer so more set up can be done.
function! s:ScratchBufBuild(src, vert, size)
  if a:size <= 0
    if a:vert
      let size = winwidth(bufwinnr(a:src)) / 2
    else
      let size = winheight(bufwinnr(a:src)) / 2
    endif
  endif

  if a:vert
    vertical belowright new
    exec 'vertical resize' size
  else
    belowright new
    exec 'resize' size
  endif

  setlocal bufhidden=wipe buftype=nofile nobuflisted noswapfile nomodifiable
  nnoremap <buffer> <silent> q :hide<CR>

  return bufnr('%')
endfunction

" Replace buffer contents with text and delete the last empty line.
function! s:ScratchBufUpdate(buf, text)
  " Move to the scratch buffer.
  call s:SwitchWindow(a:buf)

  " Double check we're in the scratch buffer before overwriting.
  if bufnr('%') != a:buf
    throw 'unable to change to scratch buffer'
  endif

  setlocal modifiable
    silent exec '% delete _'
    silent put! =a:text
    silent exec '$ delete _'
  setlocal nomodifiable
endfunction

" Parse the output of gorilla into a qflist entry for src buffer.
function! s:ParseGorillaError(output, src, startline)
  " Gorilla error is always on first line?
  let match = matchlist(a:output,
  \                     '^\w\+Error: \(.\{-}\) at \(\d\+\):\(\d\+\)' . "\n")

  if !len(match)
    return
  endif

  " Consider the line number from gorilla as relative and add it to the beginning
  " line number of the range the command was called on, then subtract one for
  " zero-based relativity.
  call setqflist([{'bufnr': a:src, 'lnum': a:startline + str2nr(match[2]) - 1,
  \                'type': 'E', 'col': str2nr(match[3]), 'text': match[1]}], 'r')
endfunction

" Reset source buffer variables.
function! s:GorillaCompileResetVars()
  " Variables defined in source buffer:
  "   b:gorilla_compile_buf: bufnr of output buffer
  " Variables defined in output buffer:
  "   b:gorilla_src_buf: bufnr of source buffer
  "   b:gorilla_compile_pos: previous cursor position in output buffer

  let b:gorilla_compile_buf = -1
endfunction

function! s:GorillaWatchResetVars()
  " Variables defined in source buffer:
  "   b:gorilla_watch_buf: bufnr of output buffer
  " Variables defined in output buffer:
  "   b:gorilla_src_buf: bufnr of source buffer
  "   b:gorilla_watch_pos: previous cursor position in output buffer

  let b:gorilla_watch_buf = -1
endfunction

function! s:GorillaRunResetVars()
  " Variables defined in gorillaRun source buffer:
  "   b:gorilla_run_buf: bufnr of output buffer
  " Variables defined in gorillaRun output buffer:
  "   b:gorilla_src_buf: bufnr of source buffer
  "   b:gorilla_run_pos: previous cursor position in output buffer

  let b:gorilla_run_buf = -1
endfunction

" Clean things up in the source buffers.
function! s:GorillaCompileClose()
  " Switch to the source buffer if not already in it.
  silent! call s:SwitchWindow(b:gorilla_src_buf)
  call s:GorillaCompileResetVars()
endfunction

function! s:GorillaWatchClose()
  silent! call s:SwitchWindow(b:gorilla_src_buf)
  silent! autocmd! GorillaAuWatch * <buffer>
  call s:GorillaWatchResetVars()
endfunction

function! s:GorillaRunClose()
  silent! call s:SwitchWindow(b:gorilla_src_buf)
  call s:GorillaRunResetVars()
endfunction

" Compile the lines between startline and endline and put the result into buf.
function! s:GorillaCompileToBuf(buf, startline, endline)
  let src = bufnr('%')
  let input = join(getline(a:startline, a:endline), "\n")

  " Gorilla doesn't like empty input.
  if !len(input)
    " Function should still return within output buffer.
    call s:SwitchWindow(a:buf)
    return
  endif

  " Pipe lines into gorilla.
  let output = system(g:gorilla_compiler . ' -spb 2>&1', input)

  " Paste output into output buffer.
  call s:ScratchBufUpdate(a:buf, output)

  " Highlight as JavaScript if there were no compile errors.
  if v:shell_error
    call s:ParseGorillaError(output, src, a:startline)
    setlocal filetype=
  else
    " Clear the quickfix list.
    call setqflist([], 'r')
    setlocal filetype=javascript
  endif
endfunction

" Peek at compiled GorillaScript in a scratch buffer. We handle ranges like this
" to prevent the cursor from being moved (and its position saved) before the
" function is called.
function! s:GorillaCompile(startline, endline, args)
  if a:args =~ '\<watch\>'
    echoerr 'GorillaCompile watch is deprecated! Please use GorillaWatch instead'
    sleep 5
    call s:GorillaWatch(a:args)
    return
  endif

  " Switch to the source buffer if not already in it.
  silent! call s:SwitchWindow(b:gorilla_src_buf)

  " Bail if not in source buffer.
  if !exists('b:gorilla_compile_buf')
    return
  endif
  " Build the output buffer if it doesn't exist.
  if bufwinnr(b:gorilla_compile_buf) == -1
    let src = bufnr('%')

    let vert = exists('g:gorilla_compile_vert') || a:args =~ '\<vert\%[ical]\>'
    let size = str2nr(matchstr(a:args, '\<\d\+\>'))

    " Build the output buffer and save the source bufnr.
    let buf = s:ScratchBufBuild(src, vert, size)
    let b:gorilla_src_buf = src

    " Set the buffer name.
    exec 'silent! file [GorillaCompile ' . src . ']'

    " Clean up the source buffer when the output buffer is closed.
    autocmd BufWipeout <buffer> call s:GorillaCompileClose()
    " Save the cursor when leaving the output buffer.
    autocmd BufLeave <buffer> let b:gorilla_compile_pos = getpos('.')

    " Run user-defined commands on new buffer.
    silent doautocmd GorillaBufNew User GorillaCompile

    " Switch back to the source buffer and save the output bufnr. This also
    " triggers BufLeave above.
    call s:SwitchWindow(src)
    let b:gorilla_compile_buf = buf
  endif

  " Fill the scratch buffer.
  call s:GorillaCompileToBuf(b:gorilla_compile_buf, a:startline, a:endline)
  " Reset cursor to previous position.
  call setpos('.', b:gorilla_compile_pos)

  " Run any user-defined commands on the scratch buffer.
  silent doautocmd GorillaBufUpdate User GorillaCompile
endfunction

" Update the scratch buffer and switch back to the source buffer.
function! s:GorillaWatchUpdate()
  call s:GorillaCompileToBuf(b:gorilla_watch_buf, 1, '$')
  call setpos('.', b:gorilla_watch_pos)
  silent doautocmd GorillaBufUpdate User GorillaWatch
  call s:SwitchWindow(b:gorilla_src_buf)
endfunction

" Continually compile a source buffer.
function! s:GorillaWatch(args)
  silent! call s:SwitchWindow(b:gorilla_src_buf)

  if !exists('b:gorilla_watch_buf')
    return
  endif

  if bufwinnr(b:gorilla_watch_buf) == -1
    let src = bufnr('%')

    let vert = exists('g:gorilla_watch_vert') || a:args =~ '\<vert\%[ical]\>'
    let size = str2nr(matchstr(a:args, '\<\d\+\>'))

    let buf = s:ScratchBufBuild(src, vert, size)
    let b:gorilla_src_buf = src

    exec 'silent! file [GorillaWatch ' . src . ']'

    autocmd BufWipeout <buffer> call s:GorillaWatchClose()
    autocmd BufLeave <buffer> let b:gorilla_watch_pos = getpos('.')

    silent doautocmd GorillaBufNew User GorillaWatch

    call s:SwitchWindow(src)
    let b:gorilla_watch_buf = buf
  endif

  " Make sure only one watch autocmd is defined on this buffer.
  silent! autocmd! GorillaAuWatch * <buffer>

  augroup GorillaAuWatch
    autocmd InsertLeave <buffer> call s:GorillaWatchUpdate()
    autocmd BufWritePost <buffer> call s:GorillaWatchUpdate()
  augroup END

  call s:GorillaWatchUpdate()
endfunction

" Run a snippet of GorillaScript between startline and endline.
function! s:GorillaRun(startline, endline, args)
  silent! call s:SwitchWindow(b:gorilla_src_buf)

  if !exists('b:gorilla_run_buf')
    return
  endif

  if bufwinnr(b:gorilla_run_buf) == -1
    let src = bufnr('%')

    let buf = s:ScratchBufBuild(src, exists('g:gorilla_run_vert'), 0)
    let b:gorilla_src_buf = src

    exec 'silent! file [GorillaRun ' . src . ']'

    autocmd BufWipeout <buffer> call s:GorillaRunClose()
    autocmd BufLeave <buffer> let b:gorilla_run_pos = getpos('.')

    silent doautocmd GorillaBufNew User GorillaRun

    call s:SwitchWindow(src)
    let b:gorilla_run_buf = buf
  endif

  if a:startline == 1 && a:endline == line('$')
    let output = system(g:gorilla_compiler .
    \                   ' ' . fnameescape(expand('%')) .
    \                   ' ' . a:args)
  else
    let input = join(getline(a:startline, a:endline), "\n")

    if !len(input)
      return
    endif

    let output = system(g:gorilla_compiler .
    \                   ' -s' .
    \                   ' ' . a:args, input)
  endif

  call s:ScratchBufUpdate(b:gorilla_run_buf, output)
  call setpos('.', b:gorilla_run_pos)

  silent doautocmd GorillaBufUpdate User GorillaRun
endfunction

" Complete arguments for Gorilla* commands.
function! s:GorillaComplete(cmd, cmdline, cursor)
  let args = ['vertical']

  " If no partial command, return all possibilities.
  if !len(a:cmd)
    return args
  endif

  let pat = '^' . a:cmd

  for arg in args
    if arg =~ pat
      return [arg]
    endif
  endfor
endfunction

" Set initial state variables if they don't exist
if !exists('b:gorilla_compile_buf')
  call s:GorillaCompileResetVars()
endif

if !exists('b:gorilla_watch_buf')
  call s:GorillaWatchResetVars()
endif

if !exists('b:gorilla_run_buf')
  call s:GorillaRunResetVars()
endif

command! -range=% -bar -nargs=* -complete=customlist,s:GorillaComplete
\        GorillaCompile call s:GorillaCompile(<line1>, <line2>, <q-args>)
command! -bar -nargs=* -complete=customlist,s:GorillaComplete
\        GorillaWatch call s:GorillaWatch(<q-args>)
command! -range=% -bar -nargs=* GorillaRun
\        call s:GorillaRun(<line1>, <line2>, <q-args>)
