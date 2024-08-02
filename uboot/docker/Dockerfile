# Use the Ubuntu 22.04 base image
FROM ubuntu:22.04

# Copy all files from the bootloader directory except those in .dockerignore
COPY ../bootloader /bootloader/
COPY ../machine /machine/

# Set the working directory inside the container
WORKDIR /bootloader

# Install dependencies and update the package list
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    build-essential \
    gcc-aarch64-linux-gnu \
    bison \
    flex \
    libssl-dev \
    libncurses-dev \
    uuid-dev \
    libgnutls28-dev \
    git \
    zlib1g-dev \
    device-tree-compiler

# Install Nushell
RUN curl -L https://github.com/nushell/nushell/releases/download/0.95.0/nu-0.95.0-x86_64-unknown-linux-gnu.tar.gz | tar xz \
    && mv nu-0.95.0-x86_64-unknown-linux-gnu/nu /usr/local/bin/ \
    && rm -rf nu-0.95.0-x86_64-unknown-linux-gnu 

#make build directory
RUN mkdir ../build

# Specify the command to run when the container starts
CMD ["nu", "build.nu", "mecha-comet-m-gen1", "../build"] 