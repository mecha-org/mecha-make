# Use Debian Bookworm as the base image
FROM debian:bookworm

# Set non-interactive frontend for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# # Add the Debian Bookworm repository
# RUN echo "deb http://deb.debian.org/debian/ bookworm main" > /etc/apt/sources.list

# # Add deb-src URIs to sources.list
# RUN echo "deb-src http://deb.debian.org/debian bookworm main" >> /etc/apt/sources.list && \
#     echo "deb-src http://deb.debian.org/debian-security bookworm-security main" >> /etc/apt/sources.list && \
#     echo "deb-src http://deb.debian.org/debian bookworm-updates main" >> /etc/apt/sources.list

# Install basic dependencies including cmake
RUN apt-get update && apt-get install -y \
    wget \
    sudo \
    apt \
    debootstrap \
    qemu-user-static \
    whois \
    u-boot-tools 
    # build-essential meson git wget unzip nano fakeroot devscripts ninja-build \
    # quilt libexpat1-dev libxml2-dev doxygen graphviz xmlto xsltproc docbook-xsl \
    # libcairo2-dev libpango1.0-dev glslang-tools hwdata xwayland libseat-dev \
    # libvulkan-dev libxcb-dri3-dev libxcb-ewmh-dev libxcb-present-dev libxcb-res0-dev \
    # libmd-dev libbz2-dev liblzma-dev libzstd-dev po4a libncurses-dev scdoc librsvg2-dev \
    # libudev-dev libsystemd-dev libdrm-dev libcap-dev libegl1-mesa-dev libgbm-dev \
    # libgles2-mesa-dev libinput-dev libx11-xcb-dev libxcb-composite0-dev \
    # libxcb-icccm4-dev libxcb-image0-dev libxcb-render-util0-dev libxcb-xinput-dev libxkbcommon-dev \
    # cmake


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

# setup assets directory
RUN mkdir -p /build/assets

# Create necessary directories
# RUN mkdir -p deps/wayland deps/wayland-protocols deps/dpkg-dev deps/libliftoff deps/libdisplay-info deps/wlroots deps/labwc

# Copy the compositor directory
COPY debian/distro /build/debian/distro

# Copy uboot directory
COPY uboot /build/uboot

# Log the files in the /build directory
RUN echo "Logging the files in the /build directory" && ls -la /build

# Build and install Wayland and other packages using Nushell script
RUN echo "Building packages" && \
    cd /build/debian/distro && \
    ls -la && \
    nu build-debian.nu mecha-comet-m-gen1 /build/assets

# Set the default command to bash
CMD ["/bin/bash"]