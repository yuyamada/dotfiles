# git
alias g='git'
compdef g=git
alias gst='git status'
compdef _git gst=git-status
alias ga='git add'
compdef _git ga=git-add
alias gcm='git commit -m'
compdef _git gcm=git-commit
# 安全なforce pushを含むgp関数
gp() {
    if [[ "$1" == "-f" ]]; then
        echo "🛡️  Using --force-with-lease instead of -f"
        shift
        git push --force-with-lease "$@"
    else
        git push "$@"
    fi
}
compdef _git gp=git-push
alias gpl='git pull'
compdef _git gpl=git-pull
alias gd='git diff'
compdef _git gd=git-diff
alias gl='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative --decorate=full'
compdef _git gl=git-log
alias gla='git log --graph --all --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative --decorate=full'
compdef _git gla=git-log
function git-switch-default() {
  if [[ "$#" -eq 0 ]]; then
    git switch $(git symbolic-ref refs/remotes/origin/HEAD | cut -f4 -d'/')
    return
  fi
  git switch $@
}
compdef _git git-switch-default=git-switch
alias gsw='git-switch-default'
compdef _git gsw=git-switch

alias grs='git restore'
compdef _git grs=git-restore
alias gf='git fetch'
compdef _git gf=git-fetch

which git-cz > /dev/null && alias gcz='git-cz --disable-emoji'

# less
alias less='less -R'

# ls
alias l='ls -1A'
alias ll='ls -lh'
alias la='ll -A'
alias lt='ll -tr'
alias lk='ll -Sr'
alias lr='ll -R'

# directory
alias -- -='cd -'
alias o='open'

# safety
alias mkdir='mkdir -p'

# utility
alias http-serve='python3 -m http.server'
alias sa='alias | grep -i'

# tmux
alias t='tmux'
alias ta='tmux a'
alias tat='tmux a -t'
alias tls='tmux ls'
alias tcc='tmux -CC'
alias trn='tmux rename -t'
alias tn='tmux new-session -A -s "$(basename "$PWD")"'


# vim
alias vim='nvim'

# gpu
alias ns='nvidia-smi'

alias proxy='sh ~/.zsh/proxy.sh'

alias time='gtime'


# my commands
alias tokenize='sed -e "s/ /_/g" | sed -E "s/(.)/\1 /g" | sed -e "s/ $//g"'
alias tk='tokenize'
alias detokenize='sed -e "s/ //g" | sed -e "s/_/ /g"'
alias dtk='detokenize'
alias relogin='exec $SHELL -l'
alias pc='pbcopy'
alias pp='pbpaste'
alias gpp='g++'
alias gr='go run'

# atcoder
alias gojt='gollect >! gollect/main.go && oj t --gnu-time gtime -c "go run gollect/main.go"'
alias accs='echo "abca" | acc s -s -- -w 0'

# docker
alias d='docker'
alias dc='docker-compose'

# kubernetes
alias k='kubectl'

# terraform
alias tf='terraform'

# image
alias imc='impbcopy -'
alias imp='pngpaste -'
function lgtm-convert() {
  magick - \
    -resize 400x400 \
    -gravity center \
    -fill white \
    -stroke none \
    -strokewidth 20 \
    -font ~/Library/Fonts/Aileron-Black.otf \
    -pointsize 72 \
    -kerning 12 \
    -annotate +0+0 'LGTM' \
    -font ~/Library/Fonts/Aileron-Regular.otf \
    -pointsize 11 \
    -fill white \
    -kerning 6 \
    -annotate +0+52 'Looks Good To Me' \
    -
}
function lgtm() {
  imp \
  | lgtm-convert \
  | imc \
  && echo Looks Good To Me!
}

alias bazel='bazelisk'

# onelogin
alias onelogin-aws-login='~/.pyenv/versions/3.6.15/bin/onelogin-aws-login'

# watch
alias w='watch -n1 '

# sql formatter
alias sqlf='sql-formatter-cli'

alias date='gdate'

alias rr=gh-revreq

# tmux session switcher
function s() {
  if [[ -n "$1" ]]; then
    sesh connect "$1"
    return
  fi
  sesh connect $(sesh list -t | fzf)
}

# s関数のディレクトリ補完を設定
_s_completion() {
    # 1. sesh のセッションリストを候補に出す
    local -a sessions
    sessions=(${(f)"$(sesh list -t)"})
    _describe 'session' sessions

    # 2. ディレクトリのみを候補に出す (-/ オプション)
    _path_files -/
}

compdef _s_completion s

# bat
alias bat='bat -p'
