#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm --needed \
	bun              \
	go               \
	gtk4             \
	webkitgtk-6.0

echo "Fetching ADBKit source..."
echo "---------------------------------------------------------------"
# on tag builds the runner checks out the tag, so use it as the version
VERSION=""
if [ "${GITHUB_REF_TYPE-}" = tag ]; then
	VERSION=${GITHUB_REF_NAME#v}
fi
if [ -z "$VERSION" ]; then
	# fall back to the Makefile, which is the source of truth for local builds
	VERSION=$(awk -F' := *' '/^VERSION/{print $2; exit}' Makefile)
fi
echo "$VERSION" > ~/version
echo "Building ADBKit $VERSION..."

echo "Building the frontend..."
echo "---------------------------------------------------------------"
cd frontend
bun install --frozen-lockfile
bun run build
cd ..

echo "Building ADBKit from source..."
echo "---------------------------------------------------------------"
mkdir -p ./bin
CGO_ENABLED=1 go build \
	-tags production     \
	-trimpath           \
	-buildvcs=false     \
	-ldflags="-w -s"    \
	-o ./bin/ADBKit

install -Dm755 ./bin/ADBKit /usr/bin/ADBKit
install -Dm644 ./appimage/ADBKit.desktop /usr/share/applications/ADBKit.desktop
install -Dm644 ./build/linux/appicon.png /usr/share/icons/hicolor/512x512/apps/ADBKit.png

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
# installed after the build: these replace gtk4 and friends with debloated
# builds that have the same sonames, but no headers for webkitgtk-6.0
if ! get-debloated-pkgs --add-common --prefer-nano; then
	echo "Debloated packages unavailable, continuing with the full ones"
fi
