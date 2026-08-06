" Give todo.md its own filetype, past vim-pandoc.
"
" vim-pandoc's ftdetect claims every *.md for filetype=pandoc. Both its
" autocmd and this one fire on todo.md, and the one registered last wins - so
" this has to be sourced after it. ftdetect files are sourced in
" 'runtimepath' order and ~/.vim/after comes last, which is the only reason
" this file lives under after/.
"
" Two details that look redundant and are not:
"
"   - `setlocal filetype=`, not `:setfiletype`. The latter is a no-op once
"     the FileType event has fired for the buffer, which pandoc has already
"     caused by then.
"   - the unlet. pandoc sets b:did_ftplugin to stop markdown's ftplugin from
"     loading; left set, it would make ftplugin/todo.vim bail out too.
autocmd BufNewFile,BufRead todo.md,*.todo.md
      \ unlet! b:did_ftplugin | setlocal filetype=todo
