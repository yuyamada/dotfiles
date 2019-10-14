# git
alias g='git'
alias gst='git status'
alias ga='git add'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
# tmux
alias ta='tmux a'

# gpu
alias ns='nvidia-smi'

# fujiso-san configuration↲
alias gpu='watch -n1 "hostname; nvidia-smi pmon -s um -c 1"'↲
alias imux='tmux attach || tmux new-session \; source-file ~/.tmux/imux'
