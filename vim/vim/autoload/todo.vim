" todo.vim - the functions behind todo.md's date colouring.
"
" Called from ftplugin/todo.vim; the format they assume is described at the
" top of syntax/todo.vim.

let s:due = '@due(\d\{4}-\d\d-\d\d)'

" Colour @due dates by how they compare with today.
"
" This cannot be a syntax rule: "before today" is not a fixed pattern. ISO
" dates compare correctly as plain strings, so the only work is finding them.
" Matches sit above syntax highlighting (priority 10 against syntax's 0), so
" they just win - but they belong to the window, not the buffer, which is why
" ftplugin/todo.vim re-runs this whenever the buffer is shown and clears it
" whenever the window moves on to something else.
function! todo#Refresh() abort
    if &filetype !=# 'todo'
        return
    endif
    call todo#Clear()

    let today = strftime('%Y-%m-%d')
    let lnum = 0
    for line in getline(1, '$')
        let lnum += 1
        " A finished task is never overdue.
        if line =~# '^\s*[-*+]\s\+\[[xX]\]'
            continue
        endif

        let col = match(line, s:due)
        if col < 0
            continue
        endif
        let date = matchstr(line, '@due(\zs\d\{4}-\d\d-\d\d\ze)')

        let group = ''
        if date <# today
            let group = 'todoOverdue'
        elseif date ==# today
            let group = 'todoDueToday'
        endif
        if !empty(group)
            call add(w:todo_matches,
                        \ matchaddpos(group, [[lnum, col + 1, len(matchstr(line, s:due))]]))
        endif
    endfor
endfunction

function! todo#Clear() abort
    for id in get(w:, 'todo_matches', [])
        silent! call matchdelete(id)
    endfor
    let w:todo_matches = []
endfunction
