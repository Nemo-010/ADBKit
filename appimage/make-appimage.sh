#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(cat ~/version)
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/512x512/apps/ADBKit.png
export DESKTOP=/usr/share/applications/ADBKit.desktop
export DEPLOY_GTK=1
export GTK_DIR=gtk-4.0
export DEPLOY_WEBKIT2GTK=1

# Deploy dependencies
quick-sharun /usr/bin/ADBKit

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage
