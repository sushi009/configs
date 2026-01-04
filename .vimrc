set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab
set autoindent
set ignorecase
set smartcase
set number
set ruler
set incsearch
set hlsearch
set backspace=indent,eol,start
set ttimeoutlen=50
set laststatus=2
set background=dark
set t_RV=
set t_md=
set t_Co=16
syntax enable
set mouse=a " disable this to atleast use tmux copy on select
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>
hi LineNr ctermfg=8
hi Comment ctermfg=8
hi StatusLine ctermfg=235 ctermbg=15
hi StatusLineNC ctermfg=235 ctermbg=8

" Clipboard Configuration
if !empty($SSH_TTY)
    " Remote: Use OSC52 for clipboard
    function! Osc52Yank()
        let buffer = @"
        let buffer = substitute(buffer, '\n$', '', '')
        let b64 = system('echo -n ' . shellescape(buffer) . ' | base64 | tr -d "\n"')
        if $TMUX != ''
            let osc52 = "\033Ptmux;\033\033]52;c;" . b64 . "\007\033\\"
        else
            let osc52 = "\033]52;c;" . b64 . "\007"
        endif
        call writefile([osc52], '/dev/tty', 'b')
    endfunction

    augroup Osc52Yank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call Osc52Yank() | endif
    augroup END
else
    " Local: Use system clipboard
    set clipboard+=unnamed
    if has("unnamedplus")
        set clipboard+=unnamedplus
    endif
endif
