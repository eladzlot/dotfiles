" Citation completion (see autoload/cite.vim).
" Note: deliberately shadows omni-completion in these buffers.
inoremap <buffer> <expr> <c-x><c-o> cite#Complete()
