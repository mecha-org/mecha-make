# Use Debian trixie as the base image
FROM debian:trixie

# Non-interactive apt
ENV DEBIAN_FRONTEND=noninteractive

# Update base image and install dependencies including CA certs
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    ca-certificates \
    wget \
    sudo \
    apt \
    debootstrap \
    qemu-user-static \
    whois \
    u-boot-tools \
    curl \
    gnupg \
    unzip \
    patchelf \
 && update-ca-certificates

# Install Nushell
RUN curl -fsSL https://apt.fury.io/nushell/gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/fury-nushell.gpg
RUN echo "deb https://apt.fury.io/nushell/ /" | tee /etc/apt/sources.list.d/fury.list
RUN apt-get update && apt-get install -y nushell

# Set up working directory
WORKDIR /build
RUN mkdir -p /build/assets

# Copy project files
COPY debian/distro /build/debian/distro
COPY uboot /build/uboot

# Log build directory
RUN echo "Logging /build directory" && ls -la /build

# Build packages
RUN echo "Building packages" && \
    cd /build/debian/distro && \
    ls -la && \
    nu build-debian.nu mecha-comet-m-gen1 /build/assets

# Default command
CMD ["/bin/bash"]
