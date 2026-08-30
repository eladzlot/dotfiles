" todo.vim - the functions behind the todo.md mappings and date colouring.
"
" Mapped in ftplugin/todo.vim; the format they assume is described at the top
" of syntax/todo.vim.

" A bullet line, with the checkbox optional: indent, marker, box.
let s:bullet = '^\(\s*\)\([-*+]\)\s\+\(\[[ xX]\]\)\='

" A task line: a bullet line that does have a checkbox.
let s:task = '^\s*[-*+]\s\+\[[ xX]\]'

let s:due = '@due(\d\{4}-\d\d-\d\d)'
let s:done = '@done(\d\{4}-\d\d-\d\d)'

" What a new task under this line starts with: indent, marker, empty checkbox.
"
" Next to another task the new one is a sibling; under a section heading it
" belongs one level in, which is where you want it after typing the heading.
function! s:prefix(line) abort
    let parts = matchlist(a:line, s:bullet)
    if empty(parts)
        return matchstr(a:line, '^\s*') . '* [ ] '
    endif

    let indent = parts[1]
    if parts[3] ==# ''
        let indent .= repeat(' ', &shiftwidth)
    endif
    return indent . parts[2] . ' [ ] '
endfunction

" Open a new task below the cursor and start typing it.
function! todo#NewTask() abort
    call append(line('.'), s:prefix(getline('.')))
    call cursor(line('.') + 1, 1)
    startinsert!
endfunction

" <CR> while typing: finish this task and open the next one.
"
" Returned as keys rather than done here, because an <expr> mapping is not
" allowed to change the buffer itself. They are also keys that never leave
" insert mode, which matters more than it looks: the obvious version returned
" <Esc>:call todo#NewTask()<CR>, and that reads correctly at typing speed but
" loses text when you type fast or paste. startinsert! only takes effect once
" vim runs out of keys to process, so anything already typed behind the <CR>
" is executed as normal-mode commands first.
"
" On a task still empty the line is cleared instead: a second <CR> on a blank
" task means "no more of these", and this is the way back out of a list.
" Anywhere off a bullet, <CR> is left alone.
"
" The clear deletes into the black hole register. cc and S would do the same
" job, and with 'clipboard' set to unnamedplus they would put the line on the
" system clipboard for the sake of pressing return.
"
" One deliberate difference from an ordinary <CR>: the line is not split at
" the cursor. Whatever follows the cursor stays on the task being finished -
" cutting a task in half mid-word is not what asking for a new one means.
"
" The 0 CTRL-D clears whatever 'autoindent' has just copied onto the new line,
" so the prefix is written from column one and is exactly the one <leader>n
" would have used, rather than that indent plus this one. Both of the more
" obvious spellings are wrong: <C-u> carries on past an indent it has finished
" deleting and eats the line break itself, which left a task at column zero
" with no new line at all, and <C-o>"_d0 steps out of insert for one command
" and loses the prefix to the same race as startinsert!.
function! todo#Return() abort
    let line = getline('.')
    if line !~# s:bullet
        return "\<CR>"
    endif
    if s:text(line) =~# '^\s*$'
        return "\<Esc>0\"_Da"
    endif
    return "\<End>\<CR>0\<C-d>" . s:prefix(line)
endfunction

" Flip [ ] and [x] on the current line, stamping @done with today's date.
"
" The stamp is what makes a finished task worth keeping rather than deleting:
" without a date, an archive of done tasks answers no question. Any stamp
" already on the line goes first, so ticking rewrites it rather than
" accumulating stamps, and unticking leaves nothing to mislead.
function! todo#ToggleDone() abort
    let line = getline('.')
    if line !~# s:task
        return
    endif

    let line = substitute(line, '\s*' . s:done, '', 'g')
    if line =~# '^\s*[-*+]\s\+\[ \]'
        let line = substitute(line, '\[ \]', '[x]', '')
        let line = substitute(line, '\s*$', '', '') . ' @done(' . strftime('%Y-%m-%d') . ')'
    else
        let line = substitute(line, '\[[xX]\]', '[ ]', '')
    endif

    call setline('.', line)
    call todo#Refresh()
    call todo#SummarySoon()
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
    call todo#SummarySoon()
endfunction

" The last date that still counts as soon.
"
" One notion of soon, shared by the colouring and by the summary, so that what
" the file shows as approaching is exactly what the picker gathers. Walking
" today's date forward is the whole reason any of this needs code: "within
" three days" cannot be written as a pattern, but the comparison afterwards
" is an ordinary string compare, because ISO dates sort as text.
function! s:soon() abort
    return strftime('%Y-%m-%d', localtime() + get(g:, 'todo_soon_days', 3) * 86400)
endfunction

" The task text alone: no indent, no bullet, no checkbox.
function! s:text(line) abort
    return substitute(a:line, '^\s*[-*+]\s\+\%(\[[ xX]\]\s*\)\=', '', '')
endfunction

" A heading as it reads in a list: its text without its own tags. A heading's
" @due says something about the project, not about the task underneath it.
function! s:heading(line) abort
    let text = substitute(s:text(a:line), '\s*\%(@\w\+\%((.\{-})\)\=\|#\w\+\)', '', 'g')
    return substitute(text, '^\s*\|\s*$', '', 'g')
endfunction

" The headings a task sits under, as "Measurement > research". A flat list of
" task text loses exactly what the outline was written for.
function! s:path(trail, indent) abort
    let keys = filter(keys(a:trail), 'str2nr(v:val) < a:indent')
    call sort(keys, {a, b -> str2nr(a) - str2nr(b)})
    return join(filter(map(keys, 'a:trail[v:val]'), '!empty(v:val)'), ' > ')
endfunction

" Everything worth doing now, in the order it is worth doing, as a list of
" {lnum, bucket, text}.
"
" Five ways to qualify, strongest first: overdue, due today, tagged @now,
" tagged #p1, or due inside the next g:todo_soon_days.
"
" A @waiting task is left out unless it is already late. It is blocked on
" somebody else, so listing it among things to do teaches you to skip lines;
" but once it is late, chasing it is the thing to do.
"
" Only the date rules need code at all - :lvimgrep would cover @now and #p1.
" "Due soon" cannot be a pattern, so today's date walks forward by however
" many days and the comparison stays an ordinary string compare.
function! s:gather() abort
    let today = strftime('%Y-%m-%d')
    let soon = s:soon()
    let order = {'now': 0, 'late': 1, 'today': 2, 'p1': 3, 'soon': 4}

    let found = []
    let trail = {}
    let lnum = 0
    for line in getline(1, '$')
        let lnum += 1
        if line !~# s:bullet
            continue
        endif
        let indent = strdisplaywidth(matchstr(line, '^\s*'))

        " A heading: it is the context for whatever nests under it, and it
        " replaces any heading remembered at the same depth or deeper.
        if line !~# s:task
            call filter(trail, {k, v -> str2nr(k) < indent})
            let trail[indent] = s:heading(line)
            continue
        endif

        if line =~# '^\s*[-*+]\s\+\[[xX]\]'
            continue
        endif

        let date = matchstr(line, '@due(\zs\d\{4}-\d\d-\d\d\ze)')
        let now = line =~# '@now\>'
        let late = !empty(date) && date <# today

        " Blocked work stays out of a list of things to do - unless it is
        " already late, when chasing it is the thing to do, or you have said
        " you are doing it now, which settles it.
        if !now && !late && line =~# '@waiting\>'
            continue
        endif

        " @now wins outright: it is a decision, where every other rule here
        " is an inference from a date. It is tested first as well as sorted
        " first, or a @now task that were also late would be filed as late.
        let bucket = ''
        if now
            let bucket = 'now'
        elseif late
            let bucket = 'late'
        elseif date ==# today
            let bucket = 'today'
        elseif line =~# '#p1\>'
            let bucket = 'p1'
        elseif !empty(date) && date <=# soon
            let bucket = 'soon'
        endif
        if empty(bucket)
            continue
        endif

        let path = s:path(trail, indent)
        call add(found, {
                    \ 'key':    printf('%d %s %05d', order[bucket],
                    \                  empty(date) ? '9999-99-99' : date, lnum),
                    \ 'lnum':   lnum,
                    \ 'bucket': bucket,
                    \ 'text':   empty(path) ? s:text(line)
                    \           : path . ' | ' . s:text(line)})
    endfor

    call sort(found, {a, b -> a.key ==# b.key ? 0 : a.key ># b.key ? 1 : -1})
    return found
endfunction

" One display line: "late  Measurement > research | Get grant @due(...)".
function! s:display(item) abort
    return printf('%-5s %s', a:item.bucket, a:item.text)
endfunction

" The one summary buffer, tracked by number rather than looked up by name:
" two panels would be two answers to the same question, and a name is a poor
" handle - bufnr() takes a pattern, and anything resembling a scheme (todo://)
" is claimed by netrw before it can become a scratch buffer.
let s:panel_buf = -1

function! s:panel_win() abort
    return (s:panel_buf > 0 && bufexists(s:panel_buf)) ? bufwinnr(s:panel_buf) : -1
endfunction

" Set up the panel window: a scratch buffer, its own labels coloured with the
" groups the file itself uses, and enough of a keymap to get out of it.
function! s:panel_open() abort
    silent botright new
    " Name it before locking it: :file counts as changing the buffer, so on a
    " 'nomodifiable' one it fails with E21 and the panel ends up nameless.
    silent file [todo-now]
    " wipe, not hide: a hidden panel buffer outlives its window and then
    " collides with the next one by name (E95). Nothing in it is worth
    " keeping - it is rebuilt from the file every time anyway.
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
    setlocal nonumber norelativenumber nowrap cursorline winfixheight
    setlocal nomodifiable
    let s:panel_buf = bufnr('%')

    " The file's editing keys, in the statusline this window already draws:
    " the one place that costs neither a row of the panel nor a column of a
    " task. They are the ones worth naming - <CR> and q explain themselves
    " once you are in here, but nothing announces that ,u exists.
    "
    " Airline would otherwise paint this statusline like every other window,
    " reporting a file position and a branch that a scratch buffer has not
    " got. b:airline_disable_statusline is airline's current hook for that;
    " w:airline_disabled still works but its own source marks it deprecated.
    let b:airline_disable_statusline = 1
    let &l:statusline = '%#todoSumStatus# todo: now%=,n new  ,d done  ,u due  ,g in/out '

    syntax match todoSumLate  /^late\>/
    syntax match todoSumSoon  /^\%(today\|soon\)\>/
    syntax match todoSumNow   /^now\>/
    syntax match todoSumP1    /^p1\>/
    " The heading path, up to the pipe: context, so it recedes.
    syntax match todoSumPath  /^\S\+\s\+\zs[^|]*|/

    hi def link todoSumLate todoOverdue
    hi def link todoSumSoon todoDueSoon
    hi def link todoSumNow  todoTag
    hi def link todoSumP1   todoPriority
    hi def link todoSumPath Comment
    " The statusline draws its whole width in one group, StatusLineNC by
    " default, which puts a grey slab along the bottom of the screen for the
    " sake of a few words. Comment carries no background, so the legend sits
    " quietly on the ordinary one.
    hi def link todoSumStatus Comment

    nnoremap <buffer> <silent> <CR> :call todo#SummaryJump()<CR>
    nnoremap <buffer> <silent> q    :close<CR>
    " ,g is "go to the list" in the file; in here it is the way back, so the
    " one key moves the cursor in and out rather than being half a pair.
    nnoremap <buffer> <silent> <leader>g :wincmd p<CR>

    augroup todo_panel
        autocmd! * <buffer>
        autocmd WinEnter <buffer> call todo#SummaryAlone()
    augroup END
endfunction

" The panel has been left as the only window - by :bdelete on the file, or
" :close, or anything else that takes the file off screen without going
" through QuitPre.
"
" Whether vim should still be running is not a question a summary window gets
" to answer. So hand the window to a real buffer if there is one, and quit
" only when there is genuinely nothing else open.
function! todo#SummaryAlone() abort
    if winnr('$') != 1
        return
    endif

    let alt = s:fallback()
    if alt <= 0
        quit
        return
    endif

    execute 'buffer ' . alt
    " The panel's window settings must not be inherited by whatever lands
    " here: they belong to the window, not to the buffer that has just gone.
    setlocal number< relativenumber< wrap< cursorline< winfixheight<
endfunction

" A buffer to fall back to: the alternate file if it is a real one, else any
" other listed buffer. The file that was just taken off screen is the last
" resort - showing it again is not what closing it meant.
function! s:fallback() abort
    let left = get(s:, 'left', 0)
    let here = bufnr('%')
    let cands = filter(range(1, bufnr('$')),
                \ {_, b -> buflisted(b) && b != here})
    if empty(cands)
        return 0
    endif

    let others = filter(copy(cands), {_, b -> b != left})
    if empty(others)
        return cands[0]
    endif
    return index(others, bufnr('#')) >= 0 ? bufnr('#') : others[0]
endfunction

" Show everything gathered in a window under the file, and leave the cursor
" where it was.
"
" An fzf picker over the same list came first and was removed. fzf is modal:
" while it is up it owns the keyboard, so it can answer "which one of these"
" and then it is gone - it cannot sit there saying what is on today. Hence a
" panel that holds still and never takes focus; todo#SummaryFocus() is the
" way in when you do want it.
function! todo#Summary() abort
    if &filetype !=# 'todo'
        return
    endif

    let src = bufnr('%')
    let found = s:gather()
    let winnr = s:panel_win()

    " Nothing to show: take the panel away rather than leave an empty box.
    if empty(found)
        if winnr > 0
            execute winnr . 'wincmd c'
        endif
        return
    endif

    if winnr > 0
        execute winnr . 'wincmd w'
    else
        call s:panel_open()
    endif

    setlocal modifiable
    silent %delete _
    call setline(1, map(copy(found), {_, v -> s:display(v)}))
    setlocal nomodifiable nomodified
    execute 'resize ' . min([len(found), get(g:, 'todo_summary_height', 8)])
    let b:todo_src = src
    let b:todo_lnums = map(copy(found), {_, v -> v.lnum})
    call cursor(1, 1)

    " Back to the file by its window, not by whichever window we came from:
    " the panel must never end up holding the cursor.
    let back = bufwinnr(src)
    if back > 0
        execute back . 'wincmd w'
    endif
endfunction

" Rebuild the panel once the current event has finished.
"
" Building it means creating a window and stepping back out of one, which is
" not reliable from inside the event that asked for it: during startup vim
" re-enters the first window afterwards, and the first window would be the
" panel - so the file would open with the cursor in the summary. A zero-delay
" timer runs the work after things settle, and stopping the previous one
" coalesces a burst of edits into a single rebuild.
function! todo#SummarySoon() abort
    if get(s:, 'timer', 0)
        call timer_stop(s:timer)
    endif
    let s:timer = timer_start(0, {-> todo#Summary()})
endfunction

" Close the panel if no todo file is on screen any more - after :e something
" else, say. Deferred, like the rebuild: closing a window from inside
" BufWinLeave rearranges the layout in the middle of whatever is closing it,
" and vim responds by abandoning the operation, so :q would close the panel
" and leave the file open instead of quitting.
function! todo#SummaryPruneSoon() abort
    " Remember what is going off screen, so a fallback does not re-show it.
    let s:left = bufnr('%')
    call timer_start(0, {-> todo#SummaryPrune()})
endfunction

function! todo#SummaryPrune() abort
    for w in range(1, winnr('$'))
        if getbufvar(winbufnr(w), '&filetype') ==# 'todo'
            return
        endif
    endfor
    call todo#SummaryClose()
endfunction

" Close the panel, wherever the cursor happens to be. Never as the last
" window: closing that one would take vim down with it.
function! todo#SummaryClose() abort
    let winnr = s:panel_win()
    if winnr > 0 && winnr('$') > 1
        execute winnr . 'wincmd c'
    endif
endfunction

" Put the cursor in the panel, opening it first if it is not up. The panel
" itself never takes focus, so this is the way in; <C-w> commands work from
" there like any other window, and q closes it.
function! todo#SummaryFocus() abort
    call todo#Summary()
    let winnr = s:panel_win()
    if winnr > 0
        execute winnr . 'wincmd w'
    else
        echo 'todo: nothing late, due soon, @now or #p1'
    endif
endfunction

function! todo#SummaryToggle() abort
    if s:panel_win() > 0
        call todo#SummaryClose()
    else
        call todo#Summary()
    endif
endfunction

" <CR> in the panel: go to that task in the file it came from.
function! todo#SummaryJump() abort
    let lnum = get(get(b:, 'todo_lnums', []), line('.') - 1, 0)
    let src = get(b:, 'todo_src', 0)
    if !lnum || !bufexists(src)
        return
    endif

    let winnr = bufwinnr(src)
    if winnr > 0
        execute winnr . 'wincmd w'
    else
        execute 'buffer ' . src
    endif
    execute lnum
    normal! zvzz
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
