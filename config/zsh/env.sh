export LANG=en_US.utf-8
export EDITOR=nvim

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
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
