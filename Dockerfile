# cka-tools/Dockerfile
FROM debian:bookworm-slim

# ---- Versions (adjust as needed) ----
ARG KUBECTL_VERSION=v1.30.4
ARG KUBECTX_VERSION=v0.9.5
ARG HELM_VERSION=v3.15.4
ARG KUSTOMIZE_VERSION=v5.4.2
ARG YQ_VERSION=v4.44.3
ARG STERN_VERSION=v1.30.0

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8

# ---- Base packages ----
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg bash-completion \
      tmux vim git jq procps iputils-ping \
      coreutils tar gzip unzip less \
      figlet lolcat \
    && rm -rf /var/lib/apt/lists/*

# ---- kubectl ----
RUN curl -fsSL -o /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && chmod +x /usr/local/bin/kubectl

# ---- kubectx / kubens ----
RUN curl -fsSL -o /tmp/kubectx.tgz \
      "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_x86_64.tar.gz" \
 && curl -fsSL -o /tmp/kubens.tgz \
      "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_x86_64.tar.gz" \
 && tar -xzf /tmp/kubectx.tgz -C /usr/local/bin kubectx \
 && tar -xzf /tmp/kubens.tgz -C /usr/local/bin kubens \
 && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens \
 && rm -f /tmp/kubectx.tgz /tmp/kubens.tgz

# ---- Helm ----
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
  | tar -xz -C /tmp \
 && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
 && chmod +x /usr/local/bin/helm \
 && rm -rf /tmp/linux-amd64

# ---- Kustomize ----
# NOTE: tag is "kustomize/vX.Y.Z" → URL-encode the slash as %2F
RUN curl -fsSL -o /tmp/kustomize.tgz \
      "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
 && tar -xzf /tmp/kustomize.tgz -C /usr/local/bin kustomize \
 && chmod +x /usr/local/bin/kustomize \
 && rm -f /tmp/kustomize.tgz

# ---- yq ----
RUN curl -fsSL -o /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
 && chmod +x /usr/local/bin/yq

# ---- stern ----
# Tag has 'v' (e.g., v1.30.0) but asset filename drops it.
RUN export SVER_NOV="${STERN_VERSION#v}" \
 && curl -fsSL -o /tmp/stern.tgz \
      "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${SVER_NOV}_linux_amd64.tar.gz" \
 && tar -xzf /tmp/stern.tgz -C /usr/local/bin stern \
 && chmod +x /usr/local/bin/stern \
 && rm -f /tmp/stern.tgz

# ---- Starship ----
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# ---- Non-root user ----
RUN useradd -m -u 1000 student
ENV HOME=/home/student
WORKDIR /home/student

# ---- Entrypoint + bashrc.d ----
COPY entrypoint.sh /entrypoint.sh
COPY bashrc.d/ /etc/bashrc.d/
RUN chmod +x /entrypoint.sh

# ---- Copy dotfiles (Windows-safe ownership) ----
RUN mkdir -p /home/student
COPY --chown=student:student home/student/ /home/student/

# 🍅 helper for tmux status-right to avoid errors if you don't have your own yet
RUN printf '#!/usr/bin/env bash\necho "🍅 00:00"\n' >/usr/local/bin/pomo && chmod +x /usr/local/bin/pomo

# ---- Normalize CRLF (Windows edits) ----
RUN apt-get update && apt-get install -y --no-install-recommends dos2unix && rm -rf /var/lib/apt/lists/* \
 && find /home/student -type f -print0 | xargs -0 dos2unix || true \
 && dos2unix /entrypoint.sh /etc/bashrc.d/*.sh || true

# Permissions (belt-and-suspenders)
RUN chown -R student:student /home/student /etc/bashrc.d /entrypoint.sh

# ---- Useful env ----
ENV STARSHIP_CONFIG="/home/student/.config/starship.toml" \
    KUBECONFIG="/home/student/.kube/config"

# Prepare kube/work dirs
RUN mkdir -p /home/student/.kube /work && chown -R student:student /home/student/.kube /work

USER student

# ---- Default entry ----
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash","-l"]
