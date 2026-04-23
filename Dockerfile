FROM debian:bookworm-slim

WORKDIR /covpn

# 环境变量防止交互式安装
ENV DEBIAN_FRONTEND=noninteractive

ENV VPN_PROFILE=''

ENV LOCAL_NETS='10.0.0.0/8,172.16.0.0/12,192.168.0.0/16'

# 安装必要软件
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openvpn curl iproute2 \
        iptables \
        ca-certificates \
        net-tools bash\
        xz-utils \
        gnupg \
        easy-rsa \
        dante-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
ARG S6_OVERLAY_VERSION=3.2.1.0

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) S6_ARCH="x86_64" ;; \
      arm64) S6_ARCH="aarch64" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/s6-overlay-noarch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz"; \
    curl -fsSL -o /tmp/s6-overlay-${S6_ARCH}.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz"; \
    curl -fsSL -o /tmp/s6-overlay-symlinks-noarch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz"; \
    curl -fsSL -o /tmp/s6-overlay-symlinks-arch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz"; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-${S6_ARCH}.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz; \
    rm -f /tmp/s6-overlay-*.tar.xz

COPY s6-rc.d /etc/s6-overlay/s6-rc.d/
COPY danted.conf /etc

RUN mkdir /config && chmod -R 755 /etc/s6-overlay/s6-rc.d

ENTRYPOINT ["/init"]
