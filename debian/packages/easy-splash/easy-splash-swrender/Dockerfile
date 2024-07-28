FROM debian:bookworm

# Non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive 

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    git \
    nano \
    wget \
    apt \
    unzip  \
    ninja-build \
    meson \
    cmake \
    build-essential \
    devscripts \
    dpkg-dev \
    pkg-config \
    systemd \
    libsystemd-dev \
    zlib1g-dev \
    libpng-dev \
    quilt \
    libexpat1-dev \
    libxml2-dev \
    doxygen \
    graphviz \
    xmlto \
    xsltproc \
    docbook-xsl \
    libcairo2-dev \
    libpango1.0-dev \
    glslang-tools \
    hwdata \
    xwayland \
    libseat-dev \
    libvulkan-dev \
    libxcb-dri3-dev \
    libxcb-ewmh-dev \
    libxcb-present-dev \
    libxcb-res0-dev \
    libmd-dev \
    libbz2-dev \
    liblzma-dev \
    libzstd-dev \
    po4a \
    libncurses-dev \
    scdoc \
    librsvg2-dev \
    libudev-dev \
    libdrm-dev \
    libssl-dev \
    libpixman-1-0 

# Download and install Nushell
# Download and install Nushell based on the system architecture
RUN ARCH=$(uname -m) && \
    case ${ARCH} in \
        x86_64) NUSHELL_ARCH="x86_64-unknown-linux-gnu" ;; \
        aarch64) NUSHELL_ARCH="aarch64-unknown-linux-gnu" ;; \
        armv7l) NUSHELL_ARCH="armv7-unknown-linux-gnueabihf" ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac && \
    wget https://github.com/nushell/nushell/releases/download/0.96.0/nu-0.96.0-${NUSHELL_ARCH}.tar.gz && \
    tar -xzvf nu-0.96.0-${NUSHELL_ARCH}.tar.gz && \
    mv nu-0.96.0-${NUSHELL_ARCH}/nu /usr/local/bin/ && \
    rm -rf nu-0.96.0-${NUSHELL_ARCH}.tar.gz nu-0.96.0-${NUSHELL_ARCH}

# Set up working directory
WORKDIR /build 

RUN mkdir /artifacts

ENV DEBEMAIL="dhruveshb@mechasystems.com"

COPY debian/packages/easy-splash/easy-splash-swrender/  /build

RUN ls -la /build

RUN nu easy-splash-debian-build.nu

RUN ls -la /build


RUN mv /build/*.deb /artifacts    

CMD [ "/bin/bash" ]