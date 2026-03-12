#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_FILE="$ROOT_DIR/build/kong.yaml"

: "${DECK_KONNECT_CONTROL_PLANE_NAME:?DECK_KONNECT_CONTROL_PLANE_NAME is required}"
: "${DECK_KONNECT_TOKEN:?DECK_KONNECT_TOKEN is required}"
: "${DECK_SELECT_TAG:?DECK_SELECT_TAG is required}"

# Default Konnect region endpoint if not supplied.
export DECK_KONNECT_ADDR="${DECK_KONNECT_ADDR:-https://us.api.konghq.com}"

"$ROOT_DIR/scripts/build-state.sh"

deck gateway diff "$BUILD_FILE"
deck gateway sync "$BUILD_FILE"
