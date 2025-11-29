set shiftwidth=2
set softtabstop=2
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
if has("clipboard")
  set clipboard+=unnamed
  if has("unnamedplus")
    set clipboard+=unnamedplus
  endif
endif
