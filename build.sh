#!/bin/bash
set -euo pipefail

# Rootless containerized build (no host mkosi/sudo needed). Usage:
#   ./build.sh            incremental comet build (mkosi -f)
#   ./build.sh --force    full rebuild (mkosi -ff) - use after skeleton edits
#   ./build.sh --profile=qemu
#   ./build.sh --version=20260813-1200
#   ./build.sh --release=44   build against another Fedora release (default: mkosi.conf)

CONTAINER_NAME=mecha-build

opts_force=0
profile="comet"
version=""
release=""

while [ $# -gt 0 ]; do
    case "$1" in
        --force) opts_force=1 ;;
        --profile=*) profile="${1#--profile=}" ;;
        --version=*) version="${1#--version=}" ;;
        --release=*) release="${1#--release=}" ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

cd "$(dirname "$0")"

if ! podman image exists "$CONTAINER_NAME"; then
    echo "==> Building build container ($CONTAINER_NAME)…"
    podman build -t "$CONTAINER_NAME" -f Containerfile .
fi

release_flag=""
[ -n "$release" ] && release_flag="--release=$release"

force_flag=""
[ "$opts_force" -eq 1 ] && force_flag="-ff"

if [ -z "$version" ]; then
    version=$(date -u +%Y%m%d-%H%M)
fi

commit_sha=$(git rev-parse --short HEAD)

echo "==> Building profile '$profile' (IMAGE_VERSION=$version, commit=$commit_sha)…"

export TIMEFORMAT='==> Build took %3lR (%R real)'
time podman run --rm --cap-add=SYS_ADMIN --network=host -v "$PWD":/build -w /build "$CONTAINER_NAME" \
    bash -euxc "git config --global --add safe.directory /build; mkosi --profile=$profile $release_flag --image-version=\"$version\" --environment=MECHA_COMMIT_SHA=\"$commit_sha\" $force_flag -f build"
