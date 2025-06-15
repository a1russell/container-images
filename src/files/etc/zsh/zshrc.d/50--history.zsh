setopt \
  HIST_EXPIRE_DUPS_FIRST \
  HIST_FIND_NO_DUPS \
  HIST_IGNORE_ALL_DUPS \
  HIST_IGNORE_DUPS \
  HIST_IGNORE_SPACE \
  HIST_SAVE_NO_DUPS \
  SHARE_HISTORY

# Set number of lines of history to keep within the shell,
#  and save it to ~/.zsh_history:
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTFILE=$HOME/.zsh_history
