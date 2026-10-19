APP_NAME := ADBKit
VERSION := 2.0.0

.PHONY: help deps frontend-install doctor dev build build-upx windows run lint typecheck test test-coverage check check-all package deb rpm arch appimage release-assets all

.DEFAULT_GOAL := help

help:
	@echo "$(APP_NAME) $(VERSION)"
	@echo "  make deps       Install Go and frontend dependencies"
	@echo "  make frontend-install  Install frontend dependencies"
	@echo "  make doctor     Check required local tools"
	@echo "  make dev        Run Wails v3 development mode"
	@echo "  make build      Build the current platform"
	@echo "  make build-upx  Build then compress with UPX"
	@echo "  make windows    Build the Windows target task"
	@echo "  make run        Run the current platform build"
	@echo "  make check      Run frontend and Go checks"
	@echo "  make package    Package the current platform"
	@echo "  make deb rpm arch  Build Linux package targets"
	@echo "  make appimage   Build the Anylinux AppImage (needs an Arch container)"

deps:
	go mod download
	$(MAKE) frontend-install

frontend-install:
	cd frontend && bun install

doctor:
	@command -v go >/dev/null 2>&1 && echo "ok: go" || echo "missing: go"
	@command -v wails3 >/dev/null 2>&1 && echo "ok: wails3" || echo "missing: wails3"
	@command -v bun >/dev/null 2>&1 && echo "ok: bun" || echo "missing: bun"
	@command -v adb >/dev/null 2>&1 && echo "ok: adb" || echo "missing: adb"
	@command -v fastboot >/dev/null 2>&1 && echo "ok: fastboot" || echo "missing: fastboot"
	@command -v scrcpy >/dev/null 2>&1 && echo "ok: scrcpy" || echo "missing: scrcpy"
	@command -v makensis >/dev/null 2>&1 && echo "ok: makensis" || echo "optional: makensis"

dev:
	wails3 dev

build:
	wails3 build

build-upx: build
	upx bin/ADBKit$(if $(filter Windows_NT,$(OS)),.exe,)

windows:
	wails3 task windows:build

run:
	wails3 task run

lint:
	cd frontend && bun run lint

typecheck:
	cd frontend && bun run typecheck

test:
	cd frontend && bun run test
	go test ./...

test-coverage:
	go test -coverprofile=coverage.out -covermode=atomic ./...
	@total=$$(go tool cover -func=coverage.out | awk '/^total:/ {gsub("%","",$$3); print $$3}'); \
	echo "Go line coverage: $${total}% (informational, no gate)"

check: lint typecheck test

check-all: check test-coverage

package:
	wails3 package

deb:
	wails3 task linux:create:deb

rpm:
	wails3 task linux:create:rpm

arch:
	wails3 task linux:create:aur

# The AppImage is built by quick-sharun inside the Arch Linux container used by
# .github/workflows/appimage.yml, so there is no local AppImage target here.
appimage:
	@echo "The AppImage is built by .github/workflows/appimage.yml"
	@echo "Run: podman run --rm -v \"$$PWD\":/src -w /src ghcr.io/pkgforge-dev/archlinux:latest"
	@echo "       /bin/sh -c '/bin/sh ./appimage/get-dependencies.sh && /bin/sh ./appimage/make-appimage.sh'"

release-assets:
	bash scripts/rename-release-assets.sh all

all:
	wails3 task linux:package