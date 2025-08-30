
# 📦 `aidyland911/cka-tools`

Containerized toolkit for **CKA / CKAD prep** and Kubernetes daily work.
It comes preloaded with the most common tools, Starship prompt, and tmux config tuned for exam efficiency.

---

## 🚀 How to Run

Pull from Docker Hub and start a container:

```bash
docker run -it --rm \
  --name cka-tools \
  --hostname cka-tools \
  -v $HOME/.kube:/home/student/.kube \
  aidyland911/cka-tools:latest
```

Windows PowerShell:

```powershell
docker run -it --rm `
  --name cka-tools `
  --hostname cka-tools `
  -v "$HOME\.kube:/home/student/.kube" `
  aidyland911/cka-tools:latest
```

---

## 🔧 Installed Tools

| Tool          | Version (at build)       | Notes                                |
| ------------- | ------------------------ | ------------------------------------ |
| **kubectl**   | v1.30.4                  | Main CLI                             |
| **kubectx**   | v0.9.5                   | Switch context quickly               |
| **kubens**    | v0.9.5                   | Switch namespaces quickly            |
| **helm**      | v3.15.4                  | Helm charts                          |
| **kustomize** | v5.4.2                   | Manifest customization               |
| **yq**        | v4.44.3                  | YAML processor                       |
| **jq**        | latest Debian pkg        | JSON processor                       |
| **stern**     | v1.30.0                  | Log tailing                          |
| **tmux**      | v3.4 (built from source) | Dual prefix enabled (Ctrl-j, Ctrl-f) |
| **starship**  | latest stable            | Custom prompt                        |

---

## ⌨️ Aliases & Shortcuts

Loaded from `/etc/bashrc.d/10-cka.sh`:

* `k` → `kubectl`
* `kgp` → `kubectl get pods -o wide`
* `kgn` → `kubectl get nodes -o wide`
* `kgs` → `kubectl get svc -o wide`
* `kga` → `kubectl get all`
* `kdesc` → `kubectl describe`
* `kl` → `kubectl logs`
* `klf` → `kubectl logs -f`
* `kx` → `kubectl exec -it`
* `kaf` → `kubectl apply -f`
* `kdf` → `kubectl delete -f`
* `ky` → `kubectl -o yaml`
* `kj` → `kubectl -o json`
* `kc` → `kubectx`
* `kn` → `kubens`

### Functions

* `ksetns <ns>` → set current namespace
* `ksecret <name>` → decode secret data
* `kpf <pod> <local:remote> [container]` → port-forward
* `kshell <pod> [container]` → exec into a pod with bash/sh
* `kdebug <pod> [container]` → ephemeral debug container (busybox)
* `krunbb <name> [ns]` → run BusyBox pod (sleep)
* `krunng <name> [ns]` → run nginx pod + expose

---

## 🖥️ Tmux Setup

* Prefix = `Ctrl-j` (primary) and `Ctrl-f` (secondary)
* Reload config = `<prefix> r`
* Split panes: `v` (vertical), `h` (horizontal)
* Alt+Arrows = move between panes
* Shift+Arrows = switch windows
* `<prefix> z` = zoom a pane

---

## 🌟 Starship Prompt

Prompt shows:

```
[context|namespace] (admin@cka-tools) ~/dir ➜
```

* Kubernetes context + namespace
* Hostname = `cka-tools`
* Current directory
* ➜ or ✖ symbol based on last command exit code

---

## 🛠 Tips

* Suppress kubeconfig permission warnings:

  ```bash
  export KUBECONFIG_WARNINGS=false
  ```

  (already auto-sanitized inside image)

* Start directly in tmux:

  ```bash
  docker run -it --rm aidyland911/cka-tools tmux
  ```

* Quick version check of all tools:

  ```bash
  verify-cka-tools
  ```

---

## 📚 Example Usage

```bash
# switch ns quickly
kn kube-system

# run a debug pod
krunbb debug
kshell debug

# view logs of all pods with label
stern -l app=nginx
```

---

Do you want me to generate this as a **`README.md` file** and drop it alongside your Dockerfile (so you can just push repo → Docker Hub description)?
