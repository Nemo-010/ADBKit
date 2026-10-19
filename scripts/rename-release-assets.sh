#!/usr/bin/env bash
set -euo pipefail

# Rename raw build outputs in bin/ to canonical versioned release names.
# VERSION is read from the Makefile (single source of truth).
#
# Usage: rename-release-assets.sh [windows|linux|all]  (default: all)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$ROOT_DIR/bin"

TARGET="${1:-all}"

VERSION="$(grep -E '^VERSION :=' "$ROOT_DIR/Makefile" | awk '{print $3}')"
if [ -z "$VERSION" ]; then
  echo "Error: could not read VERSION from Makefile" >&2
  exit 1
fi

rename() {
  local src="$1"
  local dst="$2"
  if [ ! -f "$BIN_DIR/$src" ]; then
    echo "Skipped bin/$src (not found)"
    return 0
  fi
  mv "$BIN_DIR/$src" "$BIN_DIR/$dst"
  echo "Renamed bin/$src -> bin/$dst"
}

rename_windows() {
  rename "ADBKit.exe" "ADBKit-$VERSION-windows-amd64.exe"
}

rename_linux() {
  # The AppImage is no longer produced here: quick-sharun names it
  # ADBKit-<version>-anylinux-<arch>.AppImage in the Anylinux workflow.
  rename "ADBKit.deb" "ADBKit-${VERSION}_amd64.deb"
  rename "ADBKit.rpm" "ADBKit-${VERSION}-1.x86_64.rpm"
  rename "ADBKit.pkg.tar.zst" "ADBKit-${VERSION}-1-x86_64.pkg.tar.zst"
}

case "$TARGET" in
  windows)
    rename_windows
    ;;
  linux)
    rename_linux
    ;;
  all)
    rename_windows
    rename_linux
    ;;
  *)
    echo "Error: unknown target '$TARGET' (want windows|linux|all)" >&2
    exit 1
    ;;
esac
