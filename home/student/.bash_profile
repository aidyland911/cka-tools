# ~/.bash_profile
[ -r /etc/profile ] && . /etc/profile

# Starship once (login shells)
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
  eval "$(starship init bash)"
fi

# Always load interactive settings
[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
