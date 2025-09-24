FROM debian:bookworm-slim AS tmuxbuilder
ARG TMUX_VERSION=3.4
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl build-essential libevent-dev libncurses-dev bison pkg-config \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL -o /tmp/tmux.tar.gz "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz" \
 && tar -xzf /tmp/tmux.tar.gz -C /tmp \
 && cd /tmp/tmux-${TMUX_VERSION} && ./configure && make -j"$(nproc)" && make install DESTDIR=/tmp/tmux-out \
 && strip /tmp/tmux-out/usr/local/bin/tmux

# ------------ Final Image ------------
FROM debian:bookworm-slim

# OCI labels
LABEL org.opencontainers.image.title="cka-tools" \
      org.opencontainers.image.description="CKA prep toolbox: kubectl, helm, kustomize, tmux 3.4, starship, aliases" \
      org.opencontainers.image.url="https://hub.docker.com/r/aidyland911/cka-tools" \
      org.opencontainers.image.source="https://github.com/aidyland911/cka-tools" \
      org.opencontainers.image.licenses="MIT"

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

# ---- Base runtime packages (single block, cleaned) ----
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget openssh-client gnupg bash-completion \
      libevent-2.1-7 libevent-core-2.1-7 libtinfo6 \
      vim git jq procps iputils-ping dnsutils traceroute mtr-tiny net-tools \
      figlet lolcat sudo dos2unix \
    && rm -rf /var/lib/apt/lists/*

# ---- tmux 3.4 from builder ----
COPY --from=tmuxbuilder /tmp/tmux-out/usr/local/bin/tmux /usr/local/bin/tmux

# ensure non-interactive contexts can see it
ENV PATH="/home/student/.local/bin:${PATH}"

RUN ln -sf /home/student/.local/bin/pomo /usr/local/bin/pomo \
 && /usr/bin/env bash -lc '/home/student/.local/bin/pomo --help >/dev/null 2>&1 || true'

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
RUN export SVER_NOV="${STERN_VERSION#v}" \
 && curl -fsSL -o /tmp/stern.tgz \
      "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${SVER_NOV}_linux_amd64.tar.gz" \
 && tar -xzf /tmp/stern.tgz -C /usr/local/bin stern \
 && chmod +x /usr/local/bin/stern \
 && rm -f /tmp/stern.tgz

# ---- Starship ----
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# ---- Non-root user ----
RUN useradd -m -u 1000 -s /bin/bash student \
 && usermod -aG sudo student \
 && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-student-nopasswd \
 && chmod 0440 /etc/sudoers.d/90-student-nopasswd

ENV HOME=/home/student SHELL=/bin/bash
WORKDIR /home/student

# ---- Entrypoint + bashrc.d ----
COPY entrypoint.sh /entrypoint.sh
COPY bashrc.d/ /etc/bashrc.d/
RUN chmod +x /entrypoint.sh

COPY --chown=student:student home/student/ /home/student/

RUN find /home/student -type f -print0 | xargs -0 dos2unix || true \
 && dos2unix /entrypoint.sh /etc/bashrc.d/*.sh || true \
 && chown -R student:student /home/student /etc/bashrc.d /entrypoint.sh

ENV STARSHIP_CONFIG="/home/student/.config/starship.toml" \
    KUBECONFIG="/home/student/.kube/config"

RUN mkdir -p /home/student/.kube /work && chown -R student:student /home/student/.kube /work

USER student
RUN install -d -m 0755 -o student -g student /home/student/.local/bin \
    && install -d -m 0700 -o student -g student /home/student/.cache/pomo

COPY --chown=student:student pomo/pomo /home/student/.local/bin/pomo
COPY --chown=student:student pomo/vars /home/student/.cache/pomo/vars

RUN chmod 0755 /home/student/.local/bin/pomo \
    && chmod 0600 /home/student/.cache/pomo/vars \
    && command -v dos2unix >/dev/null 2>&1 && dos2unix /home/student/.cache/pomo/vars || true

# ---- tmux logging plugin ----
RUN git clone https://github.com/tmux-plugins/tmux-logging /home/student/tmux-logging \ 
&& chown -R student:student /home/student/.tmux.conf /home/student/tmux-logging

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash","-l"]
