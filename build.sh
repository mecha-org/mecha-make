#!/bin/bash
set -euo pipefail

# Rootless containerized build (no host mkosi/sudo needed). Usage:
#   ./build.sh            incremental comet build (mkosi -f)
#   ./build.sh --force    full rebuild (mkosi -ff) - use after skeleton edits
#   ./build.sh --profile=qemu
#   ./build.sh --version=20260813-1200

IMAGE_NAME=mecha-build

opts_force=0
profile="comet"
version=""

while [ $# -gt 0 ]; do
    case "$1" in
        --force) opts_force=1 ;;
        --profile=*) profile="${1#--profile=}" ;;
        --version=*) version="${1#--version=}" ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

cd "$(dirname "$0")"

if ! podman image exists "$IMAGE_NAME"; then
    echo "==> Building build container ($IMAGE_NAME)…"
    podman build -t "$IMAGE_NAME" -f Containerfile .
fi

force_flag=""
[ "$opts_force" -eq 1 ] && force_flag="-ff"

if [ -z "$version" ]; then
    version=$(date -u +%Y%m%d-%H%M)
fi

commit_sha=$(git rev-parse --short HEAD)

echo "==> Building profile '$profile' (IMAGE_VERSION=$version, commit=$commit_sha)…"

export TIMEFORMAT='==> Build took %3lR (%R real)'
time podman run --rm --cap-add=SYS_ADMIN --network=host -v "$PWD":/build -w /build "$IMAGE_NAME" \
    bash -euxc "git config --global --add safe.directory /build; mkosi --profile=$profile --image-version=\"$version\" --environment=MECHA_COMMIT_SHA=\"$commit_sha\" $force_flag -f build"
