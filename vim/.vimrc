" ~/.vimrc - vim configuration for coding
" Organized by category

" ── Plugin manager (vim-plug) ─────────────────────────────────────────────────
" Install vim-plug automatically if not present
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
  " File explorer
  Plug 'preservim/nerdtree'
  " Fuzzy file finder
  Plug 'ctrlpvim/ctrlp.vim'
  " Status line
  Plug 'itchyny/lightline.vim'
  " Git signs in the gutter
  Plug 'airblade/vim-gitgutter'
  " Auto-close brackets/quotes
  Plug 'jiangmiao/auto-pairs'
  " Comment/uncomment with gc
  Plug 'tpope/vim-commentary'
  " Git integration (:Git, :Gblame, etc.)
  Plug 'tpope/vim-fugitive'
  " Surround text objects (cs"' to change " to ')
  Plug 'tpope/vim-surround'
  " Color scheme
  Plug 'morhetz/gruvbox'
call plug#end()

" ── Basics ────────────────────────────────────────────────────────────────────
set nocompatible                " disable Vi compatibility mode
filetype plugin indent on       " enable filetype detection + plugins + indent
syntax enable                   " syntax highlighting

set encoding=utf-8              " always use UTF-8
set fileformats=unix,dos,mac    " prefer Unix line endings

" ── Appearance ───────────────────────────────────────────────────────────────
set background=dark
silent! colorscheme gruvbox     " use gruvbox if installed, silently ignore if not

set number                      " show absolute line numbers
set relativenumber              " show relative numbers for easy jumping (j/k counts)
set cursorline                  " highlight the current line
set colorcolumn=88              " vertical guide at column 88 (PEP8/Black default)
set signcolumn=yes              " always show sign column (avoid layout shift)
set laststatus=2                " always show status line
set showmode                    " show current mode (INSERT, VISUAL, etc.)
set showcmd                     " show partial command in status line
set ruler                       " show cursor position in status line
set list                        " show invisible characters
set listchars=tab:»·,trail:·,extends:›,precedes:‹  " what invisible chars look like

" ── Indentation ───────────────────────────────────────────────────────────────
set expandtab                   " use spaces instead of tabs
set tabstop=4                   " tab width = 4 spaces
set shiftwidth=4                " indent width = 4 spaces
set softtabstop=4               " backspace deletes 4 spaces at a time
set autoindent                  " copy indent from previous line
set smartindent                 " auto-indent for C-like code

" Overrides per filetype
autocmd FileType javascript,typescript,html,css,json,yaml,toml
    \ setlocal tabstop=2 shiftwidth=2 softtabstop=2

" ── Searching ─────────────────────────────────────────────────────────────────
set hlsearch                    " highlight all search matches
set incsearch                   " highlight as you type
set ignorecase                  " case-insensitive search by default
set smartcase                   " case-sensitive if pattern has uppercase
" Clear search highlight with <Esc>
nnoremap <Esc> :nohlsearch<CR>

" ── Navigation & editing ─────────────────────────────────────────────────────
set backspace=indent,eol,start  " backspace works over indents, line ends, start of insert
set scrolloff=8                 " keep 8 lines visible above/below cursor
set sidescrolloff=8             " keep 8 columns visible left/right
set wrap                        " soft-wrap long lines (display only)
set linebreak                   " wrap at word boundaries
set mouse=a                     " enable mouse in all modes
set clipboard=unnamedplus       " use system clipboard (requires +clipboard build)

" ── Splits ────────────────────────────────────────────────────────────────────
set splitright                  " new vertical splits open to the right
set splitbelow                  " new horizontal splits open below

" Navigate splits with Ctrl+hjkl
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ── Files & buffers ───────────────────────────────────────────────────────────
set hidden                      " allow switching buffers without saving
set autoread                    " reload file if changed outside vim
set nobackup                    " don't create ~ backup files
set noswapfile                  " don't create .swp files (use git instead)
set nowritebackup

" Persistent undo across sessions
if has('persistent_undo')
    let &undodir = expand('~/.vim/undo')
    silent! call mkdir(&undodir, 'p')
    set undofile
endif

" ── Completion ────────────────────────────────────────────────────────────────
set wildmenu                    " enhanced command-line completion
set wildmode=longest:full,full  " complete longest common, then cycle
set completeopt=menuone,longest " popup menu even for single match

" ── Performance ───────────────────────────────────────────────────────────────
set lazyredraw                  " don't redraw while executing macros
set ttyfast                     " fast terminal connection (smoother redraws)
set updatetime=300              " faster CursorHold event (for gitgutter, etc.)

" ── Leader key ────────────────────────────────────────────────────────────────
let mapleader = " "             " space as leader key

" ── Keymaps ───────────────────────────────────────────────────────────────────
" Save with <leader>w
nnoremap <leader>w :w<CR>
" Quit with <leader>q
nnoremap <leader>q :q<CR>
" Toggle NERDTree
nnoremap <leader>e :NERDTreeToggle<CR>
" CtrlP fuzzy finder
nnoremap <leader>f :CtrlP<CR>
nnoremap <leader>b :CtrlPBuffer<CR>
" Move between buffers
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprev<CR>
" Git status via fugitive
nnoremap <leader>gs :Git<CR>
nnoremap <leader>gb :Git blame<CR>

" ── Plugin config ─────────────────────────────────────────────────────────────
" NERDTree: hide irrelevant files
let NERDTreeIgnore = ['\~$', '\.pyc$', '__pycache__', '\.git$', 'node_modules', '.DS_Store']
let NERDTreeShowHidden = 1      " show dotfiles

" CtrlP: ignore version-controlled ignored files
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let g:ctrlp_show_hidden = 1

" lightline: minimal status line
let g:lightline = { 'colorscheme': 'gruvbox' }
set noshowmode                  " lightline shows mode, no need to duplicate

" gitgutter: update faster
let g:gitgutter_update_interval = 300

" ── Trailing whitespace ───────────────────────────────────────────────────────
" Highlight trailing whitespace in red
highlight TrailingWhitespace ctermbg=red guibg=red
match TrailingWhitespace /\s\+$/
" Strip trailing whitespace on save (except for markdown where it's meaningful)
autocmd BufWritePre * if &ft !=# 'markdown' | :%s/\s\+$//e | endif
