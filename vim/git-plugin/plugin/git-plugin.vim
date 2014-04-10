" ============================================================================
" File: git-plugin.vim
" Description: some extra git functionality
" Maintainer: Benjamen R. Meyer <bmeyer_mail-github@yahoo.com>
" License: Apache License, Version 2.0
" ============================================================================

" Init {{{

fun! s:GitCachedDiff()
	:below new
	:setlocal buftype=nofile
	:setlocal bufhidden=hide
	:setlocal noswapfile
	:set syntax=diff
	:read !git diff --cached
	:set readonly
endfun

fun! s:GitUncachedDiff()
	:below new
	:setlocal buftype=nofile
	:setlocal bufhidden=hide
	:setlocal noswapfile
	:set syntax=diff
	:read !git diff
	:set readonly
endfun

" }}}

" Commands {{{

command! -nargs=0 GitCachedDiff call s:GitCachedDiff() 
command! -nargs=0 GitStagedDiff call s:GitCachedDiff() 
command! -nargs=0 GitDiff call s:GitUncachedDiff()

" }}}
