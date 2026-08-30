" Buffer settings and mappings for todo.md files.
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

nnoremap <buffer> <silent> <leader>n :call todo#NewTask()<CR>
nnoremap <buffer> <silent> <leader>d :call todo#ToggleDone()<CR>
nnoremap <buffer>          <leader>u :call todo#SetDue()<CR>

" Insert mode, so a list can be typed straight through: <CR> finishes the task
" and opens the next one - see todo#Return() - and <Tab>/<S-Tab> shift the
" line in and out. <C-t> and <C-d> are what does the shifting because they
" work on the whole line however far along it the cursor is, which is the
" point: nothing here should require going back to the indent first.
"
" The cost is that <Tab> no longer inserts whitespace in these buffers.
" <C-v><Tab> still does, and with 'expandtab' the indent is spaces anyway.
inoremap <buffer> <expr> <CR> todo#Return()
inoremap <buffer> <Tab>   <C-t>
inoremap <buffer> <S-Tab> <C-d>

" ,g for "go to the list" rather than ,a: ,a is the ALE prefix, and a bare ,a
" would leave ,an and ,ap waiting on the timeout.
command! -buffer TodoSummary call todo#SummaryToggle()
nnoremap <buffer> <silent> <leader>g :call todo#SummaryFocus()<CR>
nnoremap <buffer> <silent> <leader>G :TodoSummary<CR>

" todo#Refresh() paints with window-local matches, so it has to run again
" every time the buffer is shown in a window, and be cleared when the window
" moves on - otherwise the matches stay behind and colour whatever is at
" those line and column numbers in the next file.
" The summary panel follows the same events, minus BufEnter: returning to this
" window from the panel fires BufEnter, and rebuilding the panel from there
" would fight with the cursor. It goes when the file does, rather than being
" left behind describing a buffer that is no longer on screen.
augroup todo_refresh
  autocmd! * <buffer>
  autocmd BufWinEnter,BufEnter,BufWritePost,TextChanged,InsertLeave <buffer>
        \ call todo#Refresh()
  autocmd BufWinEnter,BufWritePost,TextChanged,InsertLeave <buffer>
        \ if get(g:, 'todo_summary', 1) | call todo#SummarySoon() | endif
  autocmd BufLeave,BufWinLeave <buffer> call todo#Clear()
  autocmd BufWinLeave <buffer> call todo#SummaryPruneSoon()
  " Take the panel down before the quit rather than after: with it gone, :q
  " sees the same window layout it would have seen had there never been a
  " panel, and does exactly what it does for any other file.
  autocmd QuitPre <buffer> call todo#SummaryClose()
augroup END

" Refresh runs now as well as on the events above, because a buffer that is
" already on screen when the filetype is set gets no BufWinEnter. The panel
" deliberately does not: opening a window from inside FileType leaves the
" cursor in the new one, so it waits for BufWinEnter, which fires late enough
" for the split to behave.
call todo#Refresh()

let b:undo_ftplugin = 'setlocal conceallevel< foldmethod< foldlevel<'
      \ . ' | silent! nunmap <buffer> <leader>n'
      \ . ' | silent! nunmap <buffer> <leader>d'
      \ . ' | silent! nunmap <buffer> <leader>u'
      \ . ' | silent! iunmap <buffer> <CR>'
      \ . ' | silent! iunmap <buffer> <Tab>'
      \ . ' | silent! iunmap <buffer> <S-Tab>'
      \ . ' | silent! nunmap <buffer> <leader>g'
      \ . ' | silent! nunmap <buffer> <leader>G'
      \ . ' | silent! delcommand TodoSummary'
      \ . ' | call todo#SummaryClose()'
      \ . ' | silent! autocmd! todo_refresh * <buffer>'
      \ . ' | call todo#Clear()'
