" gitsessions.vim - auto save/load vim sessions based on git branches
" Maintainer:       William Ting <io at williamting.com>
" Site:             https://github.com/wting/gitsessions.vim

" setup

if exists('g:loaded_gitsessions') || v:version < 700 || &cp
    finish
endif
let g:loaded_gitsessions = 1

function! s:rtrim_slashes(string)
    return substitute(a:string, '[/\\]$', '', '')
endfunction

if !exists('g:gitsessions_dir')
    let g:gitsessions_dir = 'sessions'
else
    let g:gitsessions_dir = s:rtrim_slashes(g:gitsessions_dir)

endif

if !exists('s:session_exist')
    let s:session_exist = 0
endif

if !exists('g:VIMFILESDIR')
    let g:VIMFILESDIR = has('unix') ? $HOME . '/.vim/' : $HOME . '/vimfiles/'
endif

" helper functions

function! s:replace_bad_chars(string)
    return substitute(a:string, '/', '_', 'g')
endfunction

function! s:trim(string)
    return substitute(substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', ''), '\n', '', '')
endfunction

function! s:os_sep()
    return has('unix') ? '/' : '\'
endfunction

function! s:is_abs_path(path)
    return a:path[0] == s:os_sep()
endfunction

" logic functions

function! s:os_getcwd()
    let l:cwd = getcwd()
    if has('unix')
        return cwd
    else
        return '\' . substitute(cwd, ':', '', 'g')
    endif
endfunction

function! s:session_path(sdir, pdir)
    let l:path = a:sdir . a:pdir
    return s:is_abs_path(a:sdir) ? l:path : g:VIMFILESDIR . l:path
endfunction

function! s:session_dir()
    return s:session_path(g:gitsessions_dir, s:os_getcwd())
endfunction

function! s:session_file()
    return s:session_dir() . '/session'
endfunction


" public functions

function! g:SessionSave()
    let l:dir = s:session_dir()
    let l:file = s:session_file()

    if !isdirectory(l:dir)
        call mkdir(l:dir, 'p')

        if !isdirectory(l:dir)
            echoerr "cannot create directory:" l:dir
            return
        endif
    endif

    if isdirectory(l:dir) && (filewritable(l:dir) != 2)
        echoerr "cannot write to:" l:dir
        return
    endif

    let s:session_exist = 1
    if filereadable(l:file)
        execute 'mksession!' l:file
        echom "session updated:" l:file
    else
        execute 'mksession!' l:file
        echom "session saved:" l:file
    endif
    redrawstatus!
endfunction

function! g:SessionUpdate(...)
    let l:show_msg = a:0 > 0 ? a:1 : 1
    let l:file = s:session_file()

    if s:session_exist && filereadable(l:file)
        execute 'mksession!' l:file
        if l:show_msg
            echom "session updated:" l:file
        endif
    endif
endfunction

function! g:SessionLoad(...)
    if argc() != 0
        return
    endif

    let l:show_msg = a:0 > 0 ? a:1 : 0
    let l:file = s:session_file()

    if filereadable(l:file)
        let s:session_exist = 1
        execute 'source' l:file
        echom "session loaded:" l:file
    elseif l:show_msg
        echom "session not found:" l:file
    endif
    redrawstatus!
endfunction

function! g:SessionDelete()
    let l:file = s:session_file()
    let s:session_exist = 0
    if filereadable(l:file)
        call delete(l:file)
        echom "session deleted:" l:file
    endif
endfunction

augroup gitsessions
    autocmd!
    autocmd VimEnter * :call g:SessionLoad()
    autocmd BufEnter * :call g:SessionUpdate(0)
    autocmd VimLeave * :call g:SessionUpdate()
augroup END

command SessionSave call g:SessionSave()
command SessionLoad call g:SessionLoad(1)
command SessionDelete call g:SessionDelete()
