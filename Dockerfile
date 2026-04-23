FROM debian:bookworm-slim

WORKDIR /covpn

# 环境变量防止交互式安装
ENV DEBIAN_FRONTEND=noninteractive

ENV VPN_PROFILE=''

ENV LOCAL_NETS='10.88.0.0/16,192.168.0.0/16,10.0.0.0/8'

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

COPY s6-overlay-noarch.tar.xz /tmp
COPY s6-overlay-x86_64.tar.xz /tmp
COPY s6-overlay-symlinks-noarch.tar.xz /tmp
COPY s6-overlay-symlinks-arch.tar.xz /tmp

RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

COPY s6-rc.d /etc/s6-overlay/s6-rc.d/
COPY danted.conf /etc

RUN mkdir /config && chmod -R 755 /etc/s6-overlay/s6-rc.d

COPY auth.txt /auth.txt

ENTRYPOINT ["/init"]