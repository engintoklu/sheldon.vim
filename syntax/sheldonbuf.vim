" Sheldon.vim Syntax Highlighting
" Author: Rupesh Kumar Srivastava < github.com/flukeskywalker >

if exists("b:current_syntax")
  finish
  endif

setlocal iskeyword+=#
syn case ignore 

" Rules
syn keyword sheldonKeyword ls echo pwd cd vi vim win exit clear cls set eval testeval do not and or if for else while which
syn match sheldonOutput "^#\(.*\)$"

" Highlights
highlight link sheldonOutput PreProc
highlight link sheldonKeyword Keyword

let b:current_syntax = "sheldonbuf"
