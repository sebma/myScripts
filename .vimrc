set lcs=tab:»»
set lcs+=trail:·
"set lcs+=precedes:·
set lcs+=eol:¶
set lcs+=nbsp:☠
set title
set ruler
" Shortcut to rapidly toggle `set list` with CTRL+L
nmap <c-l> :set list!<CR>
nmap <c-t> :sort u<CR>
nmap <c-n> :set nu!<CR>
nmap <F5> :e<CR>
set paste nohls ts=4 autoindent
syntax on
"autocmd StdinReadPost * set buftype=nofile
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif "Remember last cursor position
autocmd FileType xml setlocal equalprg=xmllint\ --format\ --recover\ -\ 2>/dev/null "Pretty print XML when '=G' is pressed
"au FileType xml exe ":silent %!xmllint --format --recover - 2>/dev/null"
au BufNewFile,BufRead *.octave set filetype=matlab
" Specify a directory for plugins
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
" Initialize plugin system
call plug#end()
