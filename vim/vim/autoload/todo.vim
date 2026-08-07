" todo.vim - the functions behind the todo.md mappings and date colouring.
"
" Mapped in ftplugin/todo.vim; the format they assume is described at the top
" of syntax/todo.vim.

" A bullet line, with the checkbox optional: indent, marker, box.
let s:bullet = '^\(\s*\)\([-*+]\)\s\+\(\[[ xX]\]\)\='

" A task line: a bullet line that does have a checkbox.
let s:task = '^\s*[-*+]\s\+\[[ xX]\]'

let s:due = '@due(\d\{4}-\d\d-\d\d)'

" Open a new task below the cursor and start typing it.
"
" Next to another task the new one is a sibling; under a section heading it
" belongs one level in, which is where you want it after typing the heading.
function! todo#NewTask() abort
    let parts = matchlist(getline('.'), s:bullet)
    if empty(parts)
        let indent = matchstr(getline('.'), '^\s*')
        let bullet = '*'
    else
        let indent = parts[1]
        let bullet = parts[2]
        if parts[3] ==# ''
            let indent .= repeat(' ', &shiftwidth)
        endif
    endif

    call append(line('.'), indent . bullet . ' [ ] ')
    call cursor(line('.') + 1, 1)
    startinsert!
endfunction

" Flip [ ] and [x] on the current line.
function! todo#ToggleDone() abort
    let line = getline('.')
    if line !~# s:task
        return
    endif
    if line =~# '^\s*[-*+]\s\+\[ \]'
        call setline('.', substitute(line, '\[ \]', '[x]', ''))
    else
        call setline('.', substitute(line, '\[[xX]\]', '[ ]', ''))
    endif
    call todo#Refresh()
endfunction

" Set or replace the @due tag on the current line, defaulting to today (or to
" the date already there, so a nudge by a few days is a small edit).
function! todo#SetDue() abort
    let line = getline('.')
    let current = matchstr(line, '@due(\zs\d\{4}-\d\d-\d\d\ze)')
    let date = input('Due (YYYY-MM-DD): ', empty(current) ? strftime('%Y-%m-%d') : current)
    redraw

    if empty(date)
        return
    endif
    if date !~# '^\d\{4}-\d\d-\d\d$'
        echohl ErrorMsg
        echomsg 'todo: expected YYYY-MM-DD, got ' . date
        echohl None
        return
    endif

    if empty(current)
        call setline('.', substitute(line, '\s*$', '', '') . ' @due(' . date . ')')
    else
        call setline('.', substitute(line, s:due, '@due(' . date . ')', ''))
    endif
    call todo#Refresh()
endfunction

" The last date that still counts as soon.
"
" Walking today's date forward is the whole reason any of this needs code:
" "within three days" cannot be written as a pattern, but the comparison
" afterwards is an ordinary string compare, because ISO dates sort as text.
function! s:soon() abort
    return strftime('%Y-%m-%d', localtime() + get(g:, 'todo_soon_days', 3) * 86400)
endfunction

" Colour @due dates by how close they are: late, or due within the next few
" days. Everything further out keeps the plain @due colour.
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
    let soon = s:soon()
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
        elseif date <=# soon
            let group = 'todoDueSoon'
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
