#!/bin/bash
if ! open "$1" 2>/dev/null; then
  tmux display-message "Failed to open URL: $1"
fi
