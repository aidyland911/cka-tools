#!/usr/bin/env bash

# Source global bash_completion if available
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
elif [ -f /etc/profile.d/bash_completion.sh ]; then
  . /etc/profile.d/bash_completion.sh
fi


# Exec the given command (default is "bash -l" from CMD in Dockerfile)
exec "$@"
