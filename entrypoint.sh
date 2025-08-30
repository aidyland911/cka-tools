#!/usr/bin/env bash

# Source global bash_completion if available
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
elif [ -f /etc/profile.d/bash_completion.sh ]; then
  . /etc/profile.d/bash_completion.sh
fi

# Source any custom snippets in /etc/bashrc.d
if [ -d /etc/bashrc.d ]; then
  for f in /etc/bashrc.d/*.sh; do
    [ -r "$f" ] && . "$f"
  done
fi

# Exec the given command (default is "bash -l" from CMD in Dockerfile)
exec "$@"
