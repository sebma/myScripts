set listchars=tab:»»
if has("patch-7.4.710") | set listchars+=space:· else | set listchars+=trail:· | endif
set listchars+=eol:¶
set listchars+=nbsp:☠
set title
"set ruler
set paste nohls autoindent
set noexpandtab ts=4
syntax on
" Shortcut to rapidly toggle `set list` with CTRL+L
nmap <c-l> :set list!<CR>
nmap <c-t> :sort u<CR>
nmap <c-n> :set nu! \| :set ruler<CR>
nmap <F5> :e<CR>
"autocmd StdinReadPost * set buftype=nofile
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif "Remember last cursor position
autocmd FileType xml setlocal equalprg=xmllint\ --format\ --recover\ -\ 2>/dev/null "Pretty print XML when '=G' is pressed
"au FileType xml exe ":silent %!xmllint --format --recover - 2>/dev/null"
au BufNewFile,BufRead *.octave set filetype=matlab
call plug#begin('~/.vim/plugged')
" Specify a directory for plugins
" - Avoid using standard Vim directory names like 'plugin'
let g:plug_window = 'enew' "Open vim-plug without a split
" Initialize plugin system
Plug 'vim-scripts/AdvancedSorters'
Plug 'vim-scripts/ingo-library'
Plug 'vim-scripts/matchit.zip' "use % to travel Shell's if, else, elif, fi.
Plug 'vim-scripts/python_match.vim' " use % to travel Python's if, elif, etc.
call plug#end()
