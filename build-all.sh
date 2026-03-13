#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "  trex - Tree Explorer :: Build Script"
echo "  Author: Windneiro"
echo "============================================================"
echo

# Check zig
if ! command -v zig &>/dev/null; then
    echo "[ERROR] zig not found in PATH."
    echo "        Install Zig 0.13.0 from https://ziglang.org/download/"
    exit 1
fi

ZIG_VER=$(zig version)
echo "[INFO] Using Zig ${ZIG_VER}"
echo

mkdir -p dist

build_target() {
    local label="$1"
    local target="$2"
    local out_bin="$3"
    local dest="$4"

    echo -n "[BUILD] ${label} ... "
    if zig build -Dtarget="${target}" -Doptimize=ReleaseSafe 2>/dev/null; then
        cp -f "zig-out/bin/${out_bin}" "dist/${dest}"
        echo "OK  →  dist/${dest}"
    else
        echo "SKIP (cross-compilation not available)"
    fi
}

# Windows
build_target "Windows x86_64"       "x86_64-windows"  "trex.exe"  "trex-windows-x86_64.exe"
build_target "Windows arm64"        "aarch64-windows" "trex.exe"  "trex-windows-arm64.exe"

# Linux
build_target "Linux x86_64"         "x86_64-linux"    "trex"      "trex-linux-x86_64"
build_target "Linux arm64"          "aarch64-linux"   "trex"      "trex-linux-arm64"

# macOS
build_target "macOS x86_64"         "x86_64-macos"    "trex"      "trex-macos-x86_64"
build_target "macOS arm64 (Apple Silicon)" "aarch64-macos" "trex"  "trex-macos-arm64"

echo
echo "============================================================"
echo "  Done! Binaries are in ./dist/"
echo "============================================================"
ls -lh dist/
