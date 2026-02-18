# git
alias g='git'
alias gst='git status'
alias ga='git add'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gl='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative --decorate=full'
alias gla='git log --graph --all --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative --decorate=full'
function git-switch-default() {
  if [[ "$#" -eq 0 ]]; then
    git switch $(git symbolic-ref refs/remotes/origin/HEAD | cut -f4 -d'/')
    return
  fi
  git switch $@
}
alias gsw='git-switch-default'

alias grs='git restore'
alias gf='git fetch'

which git-cz > /dev/null && alias gcz='git-cz --disable-emoji'

# less
alias less='less -R'

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

# fujiso-san configuration↲
alias gpu='watch -n1 "hostname; nvidia-smi pmon -s um -c 1"'↲
alias imux='tmux attach || tmux new-session \; source-file ~/.tmux/imux'

# my commands
alias tokenize='sed -e "s/ /_/g" | sed -E "s/(.)/\1 /g" | sed -e "s/ $//g"'
alias tk='tokenize'
alias detokenize='sed -e "s/ //g" | sed -e "s/_/ /g"'
alias dtk='detokenize'
alias ws='cd ~/Workspace/yahoo/Text-Summarizer-Pytorch'
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

# docker
alias dc='docker-compose'

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
function ss() {
  if [[ -n "$1" ]]; then
    sesh connect "$1"
    return
  fi
  sesh connect $(sesh list -t | fzf)
}
