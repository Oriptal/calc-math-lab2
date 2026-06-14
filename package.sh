#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-release}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
BUILD_TYPE="${BUILD_TYPE:-Release}"

# EXTRA_CMAKE_ARGS lets callers (e.g. CI) pass extra -D flags, such as
# -DCMAKE_OSX_ARCHITECTURES=x86_64;arm64 for a universal macOS build.
# Left unquoted on purpose so multiple space-separated flags word-split;
# a ';' coming from the variable stays literal (no command-separator).
cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" ${EXTRA_CMAKE_ARGS:-}
cmake --build "$BUILD_DIR"
cmake --install "$BUILD_DIR" --prefix "$DIST_DIR"

printf 'Package created in %s\n' "$DIST_DIR"
