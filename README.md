# Mechanix OS Build System

Build system for creating Fedora-based images for Mecha Comet devices using `mkosi`.

## Repository Layout

- `mkosi.conf` – Base mkosi configuration.
- `mkosi.conf.d/` – Package groups and additional configuration.
- `mkosi.profiles/` – Build profiles such as `comet`, `release`, and `qemu`.
- `mkosi.skeleton/` – Files copied into the image before the package manager runs.
  Note: with incremental builds, skeleton changes need a full rebuild (`-ff`).
- `mkosi.extra.comet/` – Comet-only files copied in after the OS is installed
  (USB gadget service, dnsmasq config). Applied on every build.
- `mkosi.version` – Image version.
- `build.sh` – Rootless, containerized build wrapper (see below).

## Prerequisites

Install the required tools:

```sh
sudo apt update
sudo apt install -y mkosi qemu-system-x86 ovmf debootstrap
```

## View Configuration

Show the current mkosi configuration:

```sh
mkosi summary
```

## Development Credentials

The root account is disabled.

A regular user named `mecha` is created during the build.

To set a password for development:

```sh
echo "MECHA_USER_PASSWORD=YOUR_PASSWORD" > mkosi.env
chmod 600 mkosi.env
```

Do not commit `mkosi.env`.

## Build

A profile is always required.

### Host-installed mkosi

```sh
sudo mkosi --profile=comet -f build
```

Build a release image:

```sh
sudo mkosi --profile=comet,release -f build
```

### Containerized

`./build.sh` builds inside a podman container and stamps the image version + commit SHA:

```sh
./build.sh                     # incremental comet build (mkosi -f)
./build.sh --force             # full rebuild (mkosi -ff)
./build.sh --profile=qemu      # other profiles
./build.sh --version=20260813-1200   # override the IMAGE_VERSION stamp
```

Incremental builds cache the package-install step. After editing `mkosi.skeleton/`, rebuild with `--force` (`-ff`).

## Inspect the Image

Open a shell inside the built image:

```sh
sudo mkosi shell
```

## Test in QEMU

Build and boot the QEMU image:

```sh
./run-qemu.sh
```

Force a rebuild before booting:

```sh
./run-qemu.sh --build
```

If you only want to boot a prebuilt image from GitHub Actions, download the `mechanix-os-qemu-raw` and `run-qemu` artifacts, extract them into the same directory, and run:

```sh
chmod +x run-qemu.sh
./run-qemu.sh
```

## SSH over USB-C

The comet image exposes a USB ethernet gadget (`usb0` = `172.16.42.1/24`) on
the USB-C/PD port. Use `ssh mecha@172.16.42.1` to connect to the device. Only enabled for the comet profile.
