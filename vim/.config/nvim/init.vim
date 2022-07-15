syntax on

set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set relativenumber
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set undofile
set incsearch
set scrolloff=8
set signcolumn=yes
set guicursor=i:block
set splitbelow
set splitright
set clipboard=unnamed

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Vertical columns
set colorcolumn=80,120
hi ColorColumn ctermbg=DarkGrey

# Install plugin manager
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugin management
call plug#begin('~/.vim/plugged')

" Themes
Plug 'navarasu/onedark.nvim'
" Auto pair Completion
Plug 'jiangmiao/auto-pairs'
" Comment code shortcuts
Plug 'preservim/nerdcommenter'
" Fuzzy file finder
Plug 'ctrlpvim/ctrlp.vim'
" Tree-like side bar
Plug 'scrooloose/nerdtree'

call plug#end()

" Theme
let g:onedark_config = {
    \ 'style': 'darker',
\}
colorscheme onedark

let mapleader = " "

" Mapping for ctrlp
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'

" NERDCommenter
nmap <C-_> <Plug>NERDCommenterToggle
vmap <C-_> <Plug>NERDCommenterToggle<CR>gv

" NERDTree
let NERDTreeQuitOnOpen=1
nmap <F2> :NERDTreeToggle<CR>


augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=150}
augroup END

set completeopt=menu,menuone,noselect

