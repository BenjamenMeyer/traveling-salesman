" ============================================================================
" File: mouse-plugin.vim
" Description: Make using a mouse easy for when you want it
" Maintainer: Benjamen R. Meyer <bmeyer_mail-github@yahoo.com>
" License: Apache License, Version 2.0
" ============================================================================

" Init {{{

function! s:MouseEnabled()
  :set mouse=a
endfunction

function! s:MouseDisabled()
  :set mouse=
endfunction

" }}}

" Commands {{{

command! -nargs=0 MouseEnabled call s:MouseEnabled() 
command! -nargs=0 MouseDisabled call s:MouseDisabled() 

" }}}
