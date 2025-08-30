# ~/.bashrc

# Interactivity guard
case $- in *i*) ;; *) return;; esac

# History & QoL
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend checkwinsize
export EDITOR=vim
set -o vi

# Completion
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  . /etc/bash_completion
elif [ -f /etc/profile.d/bash_completion.sh ]; then
  . /etc/profile.d/bash_completion.sh
fi

# kubectl/helm completion & aliases (if installed)
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -o default -F __start_kubectl k
fi
command -v helm >/dev/null 2>&1 && source <(helm completion bash)

# Handy aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'

alias kgp='kubectl get pods -o wide 2>/dev/null'
alias kgn='kubectl get nodes -o wide 2>/dev/null'
alias ky='kubectl -o yaml 2>/dev/null'
alias kj='kubectl -o json 2>/dev/null'
alias kn='kubens 2>/dev/null'
alias kc='kubectx 2>/dev/null'

# If Starship isn't available, fall back to a similar PS1
__k_ctx_ns() {
  command -v kubectl >/dev/null 2>&1 || return 0
  local ctx ns
  ctx=$(kubectl config current-context 2>/dev/null) || return 0
  ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
  [ -z "$ns" ] && ns=default
  printf "[%s|%s] " "$ctx" "$ns"
}
if ! command -v starship >/dev/null 2>&1; then
  PS1='$(__k_ctx_ns)(admin@localhost) \W # '
fi
# Starship in interactive shells (including tmux panes)
if command -v starship >/dev/null 2>&1 && [ -n "$PS1" ]; then
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
  eval "$(starship init bash)"
fi
export PATH="$HOME/.local/bin:$PATH"
