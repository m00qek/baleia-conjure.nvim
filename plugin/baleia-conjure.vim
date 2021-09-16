let g:conjure#log#strip_ansi_escape_sequences_line_limit = 0

let s:highlighter = luaeval("require('baleia').setup(require('baleia.options').conjure())")

let s:options = { 'max_attempts': 3, 'buffer_size': 200 }

function! s:strip_ansi_color_codes(attempts, buffer, tid)
  let l:save = winsaveview()


  let l:is_colorizing = get(b:, 'baleia_colorizing', v:false)
  if l:is_colorizing
    if a:attempts >= s:options.max_attempts
      echoerr 'Could not strip ANSI color codes, tried ' . a:attempts . ' times without success.'
    else
      call timer_start(100, funcref('s:strip_ansi_color_codes', [ a:attempts + 1, a:buffer ]))
    end

    return
  end

  let l:start = line(a:buffer) - s:options.buffer_size
  if l:start < 1
    let l:start = 1
  endif


  silent execute l:start . ',$' . 's/\%x1b[[:;0-9]*m//ge'
  call winrestview(l:save)
endfunction

function! s:enable_colorizer(buffer)
  syntax match ConjureLogColorCode /\%x1b\[[:;0-9]*m/ conceal

  setlocal conceallevel=2
  setlocal concealcursor=nvic

  if exists('b:baleia') && b:baleia == v:true
    return
  endif

  call s:highlighter.automatically(a:buffer)

  let b:baleia = v:true
endfunction

function! s:colorize(buffer)
  syntax match ConjureLogColorCode /\%x1b\[[:;0-9]*m/ conceal

  setlocal conceallevel=2
  setlocal concealcursor=nvic

  call s:highlighter.once(a:buffer)
  call s:strip_ansi_color_codes(0, a:buffer, 0)
endfunction

function! s:schedule_strip_ansi_codes(buffer)
  call timer_start(500, funcref('s:strip_ansi_color_codes', [ 0, bufnr('%') ]))
endfunction


command! BaleiaColorize call s:colorize(bufnr('%'))

augroup ConjureLogColors
  autocmd!
  autocmd BufNew,BufWinEnter conjure-log-* call s:enable_colorizer(bufnr('%'))
  autocmd BufEnter conjure-log-* call s:schedule_strip_ansi_codes(bufnr('%'))
augroup END
