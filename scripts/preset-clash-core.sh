#!/bin/bash
set -euo pipefail

ARCH="${1:-}"
CORE_TYPE="${2:-Meta}"
RELEASE_BRANCH="${3:-master}"

if [ -z "$ARCH" ]; then
  echo "missing clash core architecture" >&2
  echo "usage: $0 <arch> [Meta|Smart] [release_branch]" >&2
  exit 1
fi

case "${CORE_TYPE}" in
  Meta|meta)
    CORE_DIR="meta"
    ;;
  Smart|smart)
    CORE_DIR="smart"
    ;;
  *)
    echo "invalid core type: ${CORE_TYPE}, expected Meta or Smart" >&2
    exit 1
    ;;
esac

mkdir -p files/etc/openclash/core files/etc/openclash
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CORE_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/${RELEASE_BRANCH}/${CORE_DIR}/clash-${ARCH}.tar.gz"

echo "Downloading ${CORE_TYPE} core for ${ARCH} from branch ${RELEASE_BRANCH} ..."
if ! wget --spider -q "$CORE_URL"; then
  echo "core url not found: $CORE_URL" >&2
  exit 1
fi

wget -qO "$TMPDIR/clash_meta.tar.gz" "$CORE_URL"
tar -xzf "$TMPDIR/clash_meta.tar.gz" -C "$TMPDIR"

if [ ! -f "$TMPDIR/clash" ]; then
  echo "archive extracted, but clash binary not found" >&2
  exit 1
fi

install -m 0755 "$TMPDIR/clash" files/etc/openclash/core/clash_meta

wget -qO files/etc/openclash/GeoIP.dat   "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
wget -qO files/etc/openclash/GeoSite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"

echo "Done."
echo "Core saved to files/etc/openclash/core/clash_meta"