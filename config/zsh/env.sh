export LANG=en_US.utf-8

# fzf theme (Iceberg)
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#1e2132,bg:#161821,spinner:#89b8c2,hl:#84a0c6 \
  --color=fg:#c6c8d1,header:#84a0c6,info:#6b7089,pointer:#e27878 \
  --color=marker:#b4be82,fg+:#c6c8d1,prompt:#84a0c6,hl+:#84a0c6"
export EDITOR=nvim
export LESS=FRX

typeset -U path PATH

# completion
setopt AUTO_MENU
setopt AUTO_LIST
setopt ALWAYS_TO_END
setopt COMPLETE_IN_WORD

# history
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
