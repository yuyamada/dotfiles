set encoding=utf-8
scriptencoding utf-8
set fileencoding=utf-8 " 保存時の文字コード
set fileencodings=ucs-boms,utf-8,euc-jp,cp932 " 読み込み時の文字コードの自動判別. 左側が優先される
set fileformats=unix,dos,mac " 改行コードの自動判別. 左側が優先される
set ambiwidth=double " □や○文字が崩れる問題を解決

" タブ・インデント
set expandtab " タブ入力を複数の空白入力に置き換える
set tabstop=8 " 画面上でタブ文字が占める幅
set softtabstop=2 " 連続した空白に対してタブキーやバックスペースキーでカーソルが動く幅
set autoindent " 改行時に前の行のインデントを継続する
set smartindent " 改行時に前の行の構文をチェックし次の行のインデントを増減する
set shiftwidth=2 " smartindentで増減する幅
" tab/空白/改行を可視化
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
" Makefileだけはタブを空白に置き換えない
let _curfile=expand("%:r")
if _curfile == 'Makefile'
  set noexpandtab
endif

" 文字列検索
set incsearch " インクリメンタルサーチ. １文字入力毎に検索を行う
set ignorecase " 検索パターンに大文字小文字を区別しない
set smartcase " 検索パターンに大文字を含んでいたら大文字小文字を区別する
set hlsearch " 検索結果をハイライト
nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>  " ESCキー2度押しでハイライトの切り替え

" カーソル
set whichwrap=b,s,h,l,<,>,[,],~ " カーソルの左右移動で行末から次の行の行頭への移動が可能になる
set number " 行番号を表示
set cursorline " カーソルラインをハイライト
" 行が折り返し表示されていた場合、行単位ではなく表示行単位でカーソルを移動する
nnoremap j gj
nnoremap k gk
nnoremap <down> gj
nnoremap <up> gk
set backspace=indent,eol,start " バックスペースキーの有効化
set virtualedit=onemore " 行末にカーソルを移動可能にする
" カッコ・タグジャンプ
set showmatch " 括弧の対応関係を一瞬表示する
source $VIMRUNTIME/macros/matchit.vim " Vimの「%」を拡張する

" コマンド補完
set wildmenu " コマンドモードの補完
set history=5000 " 保存するコマンド履歴の数

" マウスの有効化
if has('mouse')
    set mouse=a
    if has('mouse_sgr')
        set ttymouse=sgr
    elseif v:version > 703 || v:version is 703 && has('patch632')
        set ttymouse=sgr
    else
        set ttymouse=xterm2
    endif
endif

" ペースト時の自動インデントを無効化
if &term =~ "xterm"
    let &t_SI .= "\e[?2004h"
    let &t_EI .= "\e[?2004l"
    let &pastetoggle = "\e[201~"

    function XTermPasteBegin(ret)
        set paste
        return a:ret
    endfunction

    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
endif

" テーマ
colorscheme iceberg " color scheme
syntax on  "syntax highlight

" Pluginの読み込み
if filereadable(expand('~/.vim/vimrc.neobundle'))
  source ~/.vim/vimrc.neobundle
endif

" わがままキーバインド
"jjで<esc>
inoremap <silent> jj <esc>

"ノーマルモードでもctrl+hjklで移動
noremap <C-h> h
noremap <C-j> gj
noremap <C-k> gk
noremap <C-l> l
"行頭・行末移動
noremap <C-e> $<RIGHT>a
noremap <C-a> ^i
noremap <S-l> $<RIGHT>a
noremap <S-h> ^i
"コマンドモードに
inoremap <silent> jj <ESC>
"Ctrlで挿入モードでカーソル移動
inoremap <C-k> <ESC>gka
inoremap <C-j> <ESC>gja
inoremap <C-h> <ESC>ha
inoremap <C-l> <ESC>la
inoremap <C-d> <BS>
inoremap <C-a> <C-o>^
inoremap <C-e> <C-o>$
inoremap <C-u> <ESC>ui
inoremap <C-r> <ESC><C-r>i
inoremap <C-s> <ESC>
"save
noremap <C-s> <ESC>:w<CR>
