#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-release}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
BUILD_TYPE="${BUILD_TYPE:-Release}"

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
cmake --build "$BUILD_DIR"
cmake --install "$BUILD_DIR" --prefix "$DIST_DIR"

printf 'Package created in %s\n' "$DIST_DIR"
