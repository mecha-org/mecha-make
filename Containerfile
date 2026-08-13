FROM fedora:44

RUN dnf -y update && dnf -y install \
    mkosi \
    systemd \
    systemd-repart \
    git \
    python3 \
    wget \
    util-linux \
    e2fsprogs \
    dosfstools \
    squashfs-tools \
    xz \
    tar
