" cite.vim - fzf-driven citation completion for pandoc/rmd buffers
"
" Pulls suggestions from vim-pandoc's bibliography (see g:pandoc#biblio#bibs
" in vimrc) and inserts the picked keys as @key1; @key2.
"
" Mapped in ftplugin/pandoc.vim and ftplugin/rmd.vim.

" The separator between the citation key and its title in the fzf list. Only
" the part before it is inserted, so it must not occur in a citation key.
let s:sep = ' : '

" vim-pandoc only initialises its bibliography machinery for filetype=pandoc
" (see its ftplugin/pandoc.vim), so in rmd buffers we have to do it ourselves
" or GetSuggestions() dies on a missing python import / missing global.
" Both Init()s guard their own defaults, so this is a no-op in pandoc buffers.
function! s:ensure_pandoc_init() abort
    if !exists('b:pandoc_biblio_bibs')
        call pandoc#bibliographies#Init()
    endif
    if !exists('g:pandoc#completion#bib#mode')
        call pandoc#completion#Init()
    endif
endfunction

" Source: every bib entry as "key : title".
" fzf#vim#complete calls this with the matched prefix; we always offer the
" full bibliography and let fzf do the filtering, so the argument is ignored.
" (Declared as varargs so a change in how fzf calls us can't break it.)
function! s:source(...) abort
    try
        call s:ensure_pandoc_init()
        let entries = pandoc#bibliographies#GetSuggestions('')
    catch /^Vim\%((\a\+)\)\=:E117/
        " autoload function missing - vim-pandoc isn't installed
        echohl ErrorMsg
        echomsg 'cite: vim-pandoc is not available, no bibliography to complete from'
        echohl None
        return []
    endtry
    return map(copy(entries), {_, v -> v.word . s:sep . v.menu})
endfunction

" Whether the pending completion should wrap itself in [ ]. Decided at trigger
" time by cite#Complete(); see there for why it can't be done in the reducer.
let s:wrap = 1

" True if the cursor sits inside an unclosed [ ... ] on the current line, i.e.
" the last '[' before it is more recent than the last ']'. Only looks at this
" line, so a citation bracket split across lines is not detected.
function! s:inside_brackets() abort
    let before = getline('.')[0 : col('.') - 2]
    return strridx(before, '[') > strridx(before, ']')
endfunction

" Reducer: turn the picked lines back into a pandoc citation list, bracketing
" it unless we are already inside brackets. Multi-select gives [@a; @b].
function! s:reducer(lines) abort
    let keys = map(copy(a:lines), {_, v -> '@' . split(v, s:sep)[0]})
    let out = join(keys, '; ')
    return s:wrap ? '[' . out . ']' : out
endfunction

" 'prefix' is what fzf.vim treats as the text being completed: it seeds the fzf
" query with it AND deletes that many characters before inserting the result.
" The default '\k*$' grabs the word before the cursor, so triggering after a
" word would pre-fill the prompt with it and then silently eat it on accept.
" '$' always matches empty, so nothing is pre-filled and nothing is deleted.
" (Setting --query="" instead only hides the symptom - the deletion remains.)
"
" The bracket check happens here rather than in the reducer because this runs
" inside the <expr> mapping, where the cursor is exactly at the insertion point
" - the same position fzf#vim#complete itself reads the prefix from. By reducer
" time fzf has been and gone, and the insertion point depends on fzf.vim's own
" s:eol flag, which is script-local to that plugin and unreadable from here.
function! cite#Complete() abort
    let s:wrap = !s:inside_brackets()
    return fzf#vim#complete({
                \ 'prefix':  '$',
                \ 'source':  function('s:source'),
                \ 'reducer': function('s:reducer'),
                \ 'options': '--layout="reverse-list" --border --multi --margin 15%'})
endfunction
