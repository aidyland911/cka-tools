#!/usr/bin/env bash
# k8s_boiler.sh -- bootstrap kubectl shell helpers on a fresh system
# Supports: Debian/Ubuntu, RHEL 9 based (RHEL, Rocky, Alma, CentOS Stream 9),
#           and VMware Photon OS
# Installs: git, curl, bash-completion, kubectl (if missing), kubectx/kubens
# Appends to ~/.bashrc: k / kctx / kns aliases + completion
set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
BASHRC="$TARGET_HOME/.bashrc"
KUBECTX_DIR="/opt/kubectx"
MARKER_BEGIN="# >>> k8s_boiler >>>"
MARKER_END="# <<< k8s_boiler <<<"

# Photon OS often runs as root with no sudo installed
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# ---------------------------------------------------------------- detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "ERROR: cannot detect OS (/etc/os-release missing)" >&2
  exit 1
fi

install_pkgs() {
  case "$ID" in
    debian|ubuntu)
      $SUDO apt-get update -y
      $SUDO apt-get install -y git curl bash-completion
      ;;
    rhel|rocky|almalinux|centos|ol)
      $SUDO dnf install -y git curl bash-completion
      ;;
    photon)
      $SUDO tdnf install -y git curl bash-completion
      ;;
    *)
      echo "ERROR: unsupported distro: $ID" >&2
      exit 1
      ;;
  esac
}

install_kubectl() {
  if command -v kubectl &>/dev/null; then
    echo "kubectl already present ($(command -v kubectl)), skipping"
    return
  fi
  local arch ver
  case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) echo "ERROR: unsupported arch: $(uname -m)" >&2; exit 1 ;;
  esac
  ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/${ver}/bin/linux/${arch}/kubectl"
  $SUDO install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
}

install_kubectx() {
  if [ ! -d "$KUBECTX_DIR" ]; then
    $SUDO git clone --depth 1 https://github.com/ahmetb/kubectx "$KUBECTX_DIR"
  else
    echo "kubectx already present at $KUBECTX_DIR, skipping clone"
  fi
  $SUDO ln -sf "$KUBECTX_DIR/kubectx" /usr/local/bin/kubectx
  $SUDO ln -sf "$KUBECTX_DIR/kubens"  /usr/local/bin/kubens
}

append_bashrc() {
  touch "$BASHRC"
  if grep -qF "$MARKER_BEGIN" "$BASHRC"; then
    echo "k8s_boiler block already in $BASHRC, skipping"
    return
  fi
  cp "$BASHRC" "$BASHRC.bak.$(date +%Y%m%d%H%M%S)"
  cat >> "$BASHRC" << BASHRC_BLOCK

$MARKER_BEGIN
alias k=kubectl
alias kctx=kubectx
alias kns=kubens
if command -v kubectl &>/dev/null; then
  source <(kubectl completion bash)
  complete -o default -F __start_kubectl k
fi
[ -f $KUBECTX_DIR/completion/kubectx.bash ] && source $KUBECTX_DIR/completion/kubectx.bash
[ -f $KUBECTX_DIR/completion/kubens.bash ]  && source $KUBECTX_DIR/completion/kubens.bash
$MARKER_END
BASHRC_BLOCK
}

fix_ownership() {
  if [ "$TARGET_USER" != "root" ]; then
    $SUDO chown "$TARGET_USER":"$TARGET_USER" "$BASHRC" 2>/dev/null || true
  fi
}

echo "== Installing packages ($ID) =="
install_pkgs
echo "== Installing kubectl =="
install_kubectl
echo "== Installing kubectx / kubens =="
install_kubectx
echo "== Updating $BASHRC =="
append_bashrc
fix_ownership
echo "== Done. Run: source ~/.bashrc  then try: k get pods, kctx, kns =="
