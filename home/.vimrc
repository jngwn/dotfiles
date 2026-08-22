" Minimal Vim fallback for the editing defaults shared with Neovim.
" Neovim owns its complete workflow in config/nvim/init.lua; keep this file
" dependency-free so plain Vim remains useful without duplicating that setup.

if has('nvim')
  finish
endif

set nocompatible
set encoding=utf-8
set fileencodings=utf-8,euckr,cp949,latin1
set nomodeline

filetype plugin indent on
syntax enable

" Editing and navigation defaults
set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set autoindent
set smartindent
set cindent
set smarttab
set textwidth=0
set ignorecase
set smartcase
set nojoinspaces
set wrapscan
set number
set nowrap
set scrolloff=8
set sidescrolloff=8
set splitbelow
set splitright
set autoread
set mouse=a

if has('clipboard')
  set clipboard=unnamedplus
endif

" Core editing mappings shared with the Neovim workflow.
let mapleader = "\\"
inoremap jk <Esc>
nnoremap , :
vnoremap , :
nnoremap <S-u> <C-r>
nnoremap Q <Nop>

nnoremap j gj
nnoremap k gk
nnoremap 0 g0
nnoremap ^ g^
nnoremap $ g$
vnoremap < <gv
vnoremap > >gv
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap <silent> <Esc> :nohlsearch<CR>
nnoremap <leader>v <C-v>
inoremap {<CR> {<CR>}<Esc>O

nnoremap c "_c
nnoremap C "_C
nnoremap x "_x
nnoremap X "_X
nnoremap s "_s
nnoremap S "_S
vnoremap c "_c
vnoremap C "_C
vnoremap x "_x
vnoremap X "_X
vnoremap s "_s
vnoremap S "_S
vnoremap p P

nnoremap <leader>bb <C-o>
nnoremap <leader>gg <C-i>
nnoremap <leader>ss <C-^>
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR>
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [Q :cfirst<CR>
nnoremap <silent> ]Q :clast<CR>
nnoremap <silent> [t :tabprevious<CR>
nnoremap <silent> ]t :tabnext<CR>

nnoremap <leader>w <C-w>
nnoremap <leader>1 <C-w>h
nnoremap <leader>2 <C-w>j
nnoremap <leader>3 <C-w>k
nnoremap <leader>4 <C-w>l
nnoremap <silent> <leader>5 :vertical resize -10<CR>
nnoremap <silent> <leader>6 :resize -10<CR>
nnoremap <silent> <leader>7 :resize +10<CR>
nnoremap <silent> <leader>8 :vertical resize +10<CR>
nnoremap <silent> <leader>qq :qa<CR>
nnoremap <leader>a ggVG

" Keep cleanup commands reversible at the buffer level and preserve the view.
function! s:TrimCarriageReturn() abort
  let l:view = winsaveview()
  silent! keeppatterns %s/\r//e
  call winrestview(l:view)
endfunction

function! s:TrimTrailingWhitespace() abort
  let l:view = winsaveview()
  silent! keeppatterns %s/\s\+$//e
  call winrestview(l:view)
endfunction

command! TrimCarriageReturn call <SID>TrimCarriageReturn()
command! TrimWhitespace call <SID>TrimTrailingWhitespace()

augroup dotfiles_vim_cleanup
  autocmd!
  autocmd BufWritePre * call <SID>TrimTrailingWhitespace()
  if exists('$WSL_DISTRO_NAME')
    autocmd BufWritePre * call <SID>TrimCarriageReturn()
  endif
augroup END
