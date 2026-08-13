#!/bin/bash
# Builds (if needed) and boots the mechanix-os-qemu image in QEMU.
#
# Works in two contexts, auto-detected by whether mkosi.conf sits next to
# this script:
# - Full mkosi checkout: builds the image (if missing, or on --build) before
#   booting it.
# - Standalone (e.g. a downloaded release/CI artifact, just this script and
#   mechanix-os-qemu.raw): there's no mkosi checkout to build from, so it
#   only ever boots whatever image is already sitting next to it.
#
# mkosi's own `mkosi vm` doesn't work for this profile: the Fedora
# tools-tree qemu segfaults inside mkosi's own sandbox under Console=gui
# (upstream mkosi issue https://github.com/systemd/mkosi/issues/3941), so
# this runs the host's own qemu-system-x86_64 directly against the built
# disk image instead. See README.md "Testing in QEMU" for the background on
# every flag below.
#
# No sudo anywhere: mkosi builds unprivileged via user namespaces (needs
# unprivileged_userns_clone enabled - see mkosi's docs "FREQUENTLY ASKED
# QUESTIONS" if `mkosi build` fails with a namespace/permission error), and
# qemu's -enable-kvm only needs the invoking user in the `kvm` group for
# /dev/kvm access, which this script never runs through mkosi's own sandbox
# for anyway.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

usage() {
    cat <<'EOF'
Usage: run-qemu.sh [--build]

  --build   Force a clean rebuild (mkosi clean + build) before booting.
            Only available in a full mkosi checkout (mkosi.conf present
            next to this script). Without --build, the image is built
            only if it doesn't exist yet; if it does, this just boots it.
EOF
}

BUILD=0
case "${1:-}" in
    --build) BUILD=1 ;;
    -h|--help) usage; exit 0 ;;
    "") ;;
    *)
        echo "Unknown argument: ${1}" >&2
        usage >&2
        exit 1
        ;;
esac

IMAGE=mechanix-os-qemu.raw
OVMF_VARS=/tmp/mechanix-os-qemu-ovmf-vars.fd

# Locate OVMF firmware: Debian ships /usr/share/OVMF, Arch's edk2 ships
# /usr/share/edk2/x64. Overridable via env.
for cand in "${OVMF_CODE:-}" /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/edk2/x64/OVMF_CODE.4m.fd; do
    [[ -n "$cand" && -f "$cand" ]] && { OVMF_CODE=$cand; break; }
done
for cand in "${OVMF_VARS_TEMPLATE:-}" /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/edk2/x64/OVMF_VARS.4m.fd; do
    [[ -n "$cand" && -f "$cand" ]] && { OVMF_VARS_TEMPLATE=$cand; break; }
done

if [[ ! -f "$OVMF_CODE" || ! -f "$OVMF_VARS_TEMPLATE" ]]; then
    echo "OVMF firmware not found (tried /usr/share/OVMF and /usr/share/edk2/x64) - install ovmf/edk2-ovmf or set OVMF_CODE/OVMF_VARS_TEMPLATE." >&2
    exit 1
fi

if [[ "$BUILD" == "1" || ! -f "$IMAGE" ]]; then
    if [[ ! -f mkosi.conf ]]; then
        echo "$IMAGE not found next to this script, and there's no mkosi checkout here to build it from - download it from a release/CI artifact and decompress it here first." >&2
        exit 1
    fi
    echo "Building $IMAGE..."
    mkosi clean --profile=qemu -f
    mkosi build --profile=qemu -f
fi

# Fresh EFI vars every run so leftover boot-order/state from a previous
# image never carries over.
cp "$OVMF_VARS_TEMPLATE" "$OVMF_VARS"

qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -cpu host \
    -smp 4 \
    -m 4096 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$OVMF_VARS" \
    -drive file="$IMAGE",if=none,id=bootdisk,format=raw \
    -device virtio-blk-pci,drive=bootdisk,bootindex=1 \
    -display gtk,gl=on,zoom-to-fit=on \
    -device virtio-vga-gl,xres=1080,yres=1240 \
    -device qemu-xhci,id=xhci \
    -device usb-tablet,bus=xhci.0 \
    -device usb-kbd,bus=xhci.0
