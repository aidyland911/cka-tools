" -------------------------
" Custom Vim Keybindings
" -------------------------

" F2 toggle line numbers
nnoremap <F2> :set number!<CR>

" F3 delete empty or whitespace-only lines
nnoremap <F3> :g/^\s*$/d<CR>

" F4 toggle paste mode
nnoremap <F4> :set paste!<CR>

" Recommended for YAML
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent

" Enable syntax highlighting
syntax on
