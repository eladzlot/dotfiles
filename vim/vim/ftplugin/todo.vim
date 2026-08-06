" Buffer settings for todo.md files.
" Highlighting is in syntax/todo.vim, the functions in autoload/todo.vim.

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" conceallevel is set explicitly because vim-pandoc may already have raised it
" for this buffer - see after/ftdetect/todo.vim. Folding by indent is what an
" outline wants, but start with everything open.
setlocal conceallevel=0
setlocal foldmethod=indent
setlocal foldlevel=99

" todo#Refresh() paints with window-local matches, so it has to run again
" every time the buffer is shown in a window, and be cleared when the window
" moves on - otherwise the matches stay behind and colour whatever is at
" those line and column numbers in the next file.
augroup todo_refresh
  autocmd! * <buffer>
  autocmd BufWinEnter,BufEnter,BufWritePost,TextChanged,InsertLeave <buffer>
        \ call todo#Refresh()
  autocmd BufLeave,BufWinLeave <buffer> call todo#Clear()
augroup END

call todo#Refresh()

let b:undo_ftplugin = 'setlocal conceallevel< foldmethod< foldlevel<'
      \ . ' | silent! autocmd! todo_refresh * <buffer>'
      \ . ' | call todo#Clear()'
