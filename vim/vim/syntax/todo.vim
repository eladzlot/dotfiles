" Highlighting for todo.md outlines. Selected by after/ftdetect/todo.vim.
"
" The format is a plain indented outline:
"
"   * Measurement                     a section: a bullet with no checkbox
"     * lectures @due(2026-09-06)     ...which nest
"       * [ ] Finish lit review       an open task
"       * [x] Book the room           a done task
"       * [ ] Get grant #p1 @waiting for Katie
"
" Tags are matched generically - @name, @name(arg) and #name all highlight -
" with @due and @waiting only being specially coloured cases, so a new kind
" of tag gets a colour without touching this file.

if exists('b:current_syntax')
  finish
endif

" Tags come first because of how vim breaks ties: among items that could
" match at the same position, the one defined LAST wins. The generic tag rule
" therefore has to be defined before the two specific ones it overlaps.
syn match todoTag      /@\w\+\%((.\{-})\)\=/
syn match todoPriority /#\w\+/
syn match todoDue      /@due(\d\{4}-\d\d-\d\d)/
" @waiting swallows what follows it: that is a note about who or what is being
" waited on, not part of the task. It stops at the next @ or # so that a tag
" written after the note still gets its own colour.
syn match todoWaiting  /@waiting\>[^@#]*/

syn cluster todoTags contains=todoTag,todoPriority,todoDue,todoWaiting

" Whole-line rules. These start at column 1, and an item starting earlier
" beats one starting later, so anything that should still show through has to
" be listed in contains=. Nothing is, for a done task: it is finished, and
" recedes as a whole - tags, checkbox, due date and all.
syn match todoDone    /^\s*[-*+]\s\+\[[xX]\].*$/
syn match todoProject /^\s*[-*+]\s\+\%(\[[ xX]\]\)\@!.*$/           contains=@todoTags
syn match todoSection /^[-*+]\s\+\%(\[[ xX]\]\)\@!.*$/              contains=@todoTags
syn match todoBox     /\[[ xX]\]/

hi def link todoSection  Title
hi def link todoProject  Type
hi def link todoBox      Statement
hi def link todoDone     Comment
hi def link todoDue      Identifier
hi def link todoWaiting  Special
hi def link todoPriority Constant
hi def link todoTag      PreProc

" Not syntax groups: todo#Refresh() paints these over @due dates with
" matchaddpos(). Defined here so the colours all live in one place.
"
" The three states of a due date are meant to read as a ramp - orange for a
" date ahead, yellow for today, red for late - so these two are linked for
" their colour rather than their name. WarningMsg is the obvious name for
" "today" and the wrong choice: molokai draws it, and Todo, as white on a grey
" block, which inline looks like no highlighting at all.
hi def link todoOverdue  ErrorMsg
hi def link todoDueToday MoreMsg

let b:current_syntax = 'todo'
