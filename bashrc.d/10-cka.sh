# /etc/bashrc.d/10-cka.sh
# CKA helpers: aliases, completions, and quick functions.
# Safe if tools are missing; safe to source multiple times.

# ----- Completions (guarded) -----
if command -v kubectl >/dev/null 2>&1; then
  # 'k' alias + completion if not already defined
  if ! alias k >/dev/null 2>&1; then
    alias k=kubectl
  fi
  # attach completion to k only once
  type __start_kubectl >/dev/null 2>&1 && complete -o default -F __start_kubectl k 2>/dev/null || true
fi

command -v helm   >/dev/null 2>&1 && source <(helm completion bash)   2>/dev/null || true
command -v kubectx>/dev/null 2>&1 && complete -o default -F _kubectx  kubectx     2>/dev/null || true
command -v kubens >/dev/null 2>&1 && complete -o default -F _kubens   kubens      2>/dev/null || true

# ----- Quality-of-life aliases -----
if command -v kubectl >/dev/null 2>&1; then
  # Get shortcuts
  alias kg='kubectl get'
  alias kgp='kubectl get pods -o wide'
  alias kgn='kubectl get nodes -o wide'
  alias kgsvc='kubectl get svc -o wide'
  alias kging='kubectl get ingress'
  alias kgcm='kubectl get configmaps'
  alias kgsec='kubectl get secrets'
  alias kgns='kubectl get ns'
  alias kga='kubectl get all'

  # Describe / Logs / Exec
  alias kdesc='kubectl describe'
  alias kl='kubectl logs'
  alias klf='kubectl logs -f'
  alias kx='kubectl exec -it'

  # Apply/Delete from file
  alias kaf='kubectl apply -f'
  alias kdf='kubectl delete -f'

  # Output modes
  alias ky='kubectl -o yaml'
  alias kj='kubectl -o json'

  # Context/Namespace via kubectx/kubens if present
  command -v kubectx >/dev/null 2>&1 && alias kc='kubectx'
  command -v kubens  >/dev/null 2>&1 && alias kn='kubens'
fi

# ----- Quick functions -----
# ksetns <namespace> : set current context's namespace
ksetns() {
  command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; return 1; }
  local ns="$1"
  [ -z "$ns" ] && { echo "Usage: ksetns <namespace>"; return 2; }
  kubectl config set-context --current --namespace="$ns"
}

# kctxns : show [context|namespace]
kctxns() {
  command -v kubectl >/dev/null 2>&1 || return 0
  local ctx ns
  ctx=$(kubectl config current-context 2>/dev/null) || return 0
  ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
  [ -z "$ns" ] && ns=default
  printf "[%s|%s]\n" "$ctx" "$ns"
}

# kpods <label-selector> : list pods by label (e.g., kpods app=nginx)
kpods() {
  command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; return 1; }
  local sel="$1"
  [ -z "$sel" ] && { echo "Usage: kpods <label-selector>"; return 2; }
  kubectl get pods -l "$sel" -o wide
}

# ksecret <name> : decode all keys in a secret
ksecret() {
  command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; return 1; }
  local name="$1"
  [ -z "$name" ] && { echo "Usage: ksecret <secret-name>"; return 2; }
  kubectl get secret "$name" -o json \
    | jq -r '.data | to_entries[] | "\(.key)=\(.value|@base64d)"'
}

# kpf <pod> <localPort:remotePort> [container]
# ex: kpf web-7df 8080:80 or kpf web-7df 8080:80 app
kpf() {
  command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; return 1; }
  local pod="$1" map="$2" c="$3"
  [ -z "$pod" ] || [ -z "$map" ] && { echo "Usage: kpf <pod> <local:remote> [container]"; return 2; }
  if [ -n "$c" ]; then
    kubectl port-forward "pod/$pod" "$map" -c "$c"
  else
    kubectl port-forward "pod/$pod" "$map"
  fi
}

# kshell <pod> [container] : open a shell in a pod (bash>sh)
kshell() {
  command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; return 1; }
  local pod="$1" c="$2"
  [ -z "$pod" ] && { echo "Usage: kshell <pod> [container]"; return 2; }
  local shcmd="bash"; kubectl exec "$pod" ${c:+-c "$c"} -- bash -lc 'exit' >/dev/null 2>&1 || shcmd="sh"
  kubectl exec -it "$pod" ${c:+-c "$c"} -- $shcmd
}

# kdebug <pod> [container] : ephemeral debug (busybox)
kdebug() {
  command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; return 1; }
  local pod="$1" tgt="$2"
  [ -z "$pod" ] && { echo "Usage: kdebug <pod> [target-container]"; return 2; }
  if kubectl api-resources | grep -q '^ephemeralcontainers'; then
    kubectl debug -it "$pod" ${tgt:+--target="$tgt"} --image=busybox:1.36 -- sh
  else
    echo "Ephemeral containers not available on this cluster."
    return 3
  fi
}

# kexplain <resource[.fieldPath]> : wrap explain with --recursive
kexplain() {
  command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; return 1; }
  [ -z "$1" ] && { echo "Usage: kexplain <type[.fieldPath]>"; return 2; }
  kubectl explain "$1" --recursive
}

# dry-run helpers
alias kapplyd='kubectl apply --dry-run=client -f'
alias kcreated='kubectl create --dry-run=client -o yaml'

# quick generators
krunbb() { # krunbb <name> [ns]
  local name="${1:-bb}"; local ns="${2:-default}"
  kubectl run "$name" --image=busybox:1.36 -n "$ns" --restart=Never --command -- sh -c 'sleep 36000'
}

krunng() { # krunng <name> [ns]
  local name="${1:-nginx}"; local ns="${2:-default}"
  kubectl run "$name" --image=nginx:1.27-alpine -n "$ns" --port=80 --expose
}

# JSON/YAML helpers (requires jq/yq if used)
alias jp='jq -r'                # jp ".items[].metadata.name"
alias yget='yq -r'              # yget ".spec.template.spec.containers[].image"

# End of 10-cka.sh
