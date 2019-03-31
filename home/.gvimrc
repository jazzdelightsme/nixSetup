set autoindent
set autowrite					"not in Hans'
set ignorecase 				"not in Hans'
set magic						"not in Hans'
set nolisp						"not in Hans'
set nolist						"not in Hans'
set nowarn						"not in Hans'
set redraw						"not in Hans'
set report=1					"not in Hans'
" set shiftwidth=4 already in _vimrc
" set tabstop=4	already in _vimrc "not in Hans' 
set showmatch				"not in Hans'
set showmode				"not in Hans'
set noterse				"not in Hans'
set wrapscan				"not in Hans'
" set expandtab	already in _vimrc			"not in Hans'
set ruler				"not in Hans'
set number				"not in Hans'
"set cindent				"Hans' has an auto plugin thingy
" set smarttab   already in _vimrc
syntax on
map #1 :set autoindent
map #2 :set noautoindent
map #3 :set ignorecase
map #4 :set noignorecase
map #5 :e!<CR>G
map #6 :set shiftwidth=3
"map #7 :buffers
map #7 /{<CR>vaBzf
"map #8 :r ! datestamp
"map #9 :r ! pwd
"
" Map Y to be analogous to C and D
map Y y$



set mousefocus
"set guifont=ProFontWindows:h11:cANSI
"set guifont=Consolas:h10:cANSI
"set guifont=Consolas:h12:cANSI
"set guifont=Bitstream_Vera_Sans_Mono:h10:cANSI
" Don't know why this doesn't work; it works if I set it from the GUI. :/
"set guifont=Hack:h10:cANSI

"set guifont=Hack:h9:cANSI
" Trying out ligatures...
"set guifont=Fira_Code:h9:cANSI:qDRAFT
"set renderoptions:type:directx

" These are the defaults, plus my own preferences beginning with "winpos":
set sessionoptions=blank,buffers,curdir,folds,help,options,tabpages,winsize,winpos,localoptions

" Get rid of the GUI toolbar with goofy icons (just takes out the 'T')
let &guioptions = substitute(&guioptions, "T", "", "g")

