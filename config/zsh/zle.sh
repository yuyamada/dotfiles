bindkey -v
bindkey -M viins '\er' history-incremental-pattern-search-forward
bindkey -M viins '^?'  backward-delete-char
bindkey -M viins '^A'  beginning-of-line
bindkey -M viins '^B'  backward-char
bindkey -M viins '^D'  delete-char-or-list
bindkey -M viins '^E'  end-of-line
#bindkey -M viins '^F'  forward-char
bindkey -M viins '^G'  send-break
#bindkey -M viins '^H'  backward-delete-char
#bindkey -M viins '^K'  kill-line
bindkey -M viins '^N'  down-line-or-history
bindkey -M viins '^P'  up-line-or-history
bindkey -M viins '^R'  history-incremental-pattern-search-backward
bindkey -M viins '^U'  backward-kill-line
bindkey -M viins '^W'  backward-kill-word
bindkey -M viins '^Y'  yank
# 補完時にhjklで選択
zmodload -i zsh/complist
autoload -Uz compinit && compinit
zstyle ':completion:*:default' menu select= 2
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# わがままキーバインド
bindkey jj vi-cmd-mode
bindkey -M viins '^h'  backward-char
bindkey -M viins '^j'  down-line-or-history
bindkey -M viins '^k'  up-line-or-history
bindkey -M viins '^l'  forward-char
bindkey -M viins '^d'  backward-delete-char
bindkey -M viins '^m'  accept-line
bindkey -M viins '^f'  accept-line

function fuzzy-history-selection() {
    # BUFFER=`history -n 1 | awk '!a[$0]++' | fzf-tmux --reverse -p --height 100%`
    BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N fuzzy-history-selection
bindkey '^R' fuzzy-history-selection
