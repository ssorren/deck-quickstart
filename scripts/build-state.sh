#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_FILE="${1:-$ROOT_DIR/openapi/spec.yaml}"
BUILD_DIR="$ROOT_DIR/build"

: "${DECK_SELECT_TAG:?DECK_SELECT_TAG is required}"

mkdir -p "$BUILD_DIR"

BASE_FILE="$BUILD_DIR/01-openapi.yaml"
PLUGINS_FILE="$BUILD_DIR/02-with-plugins.yaml"
FINAL_FILE="$BUILD_DIR/kong.yaml"

# 1) Convert OpenAPI -> Kong state and apply tag on generated entities.
deck file openapi2kong \
  --spec "$SPEC_FILE" \
  --output-file "$BASE_FILE"

# 2) Add plugins from overlays in ./plugins.
deck file add-plugins \
  --state "$BASE_FILE" \
  --output-file "$PLUGINS_FILE" \
  "$ROOT_DIR/plugins/rate-limiting.yaml" \
  "$ROOT_DIR/plugins/oidc.yaml"

# 3) Render _info.select_tags from env var and merge into final file.
"$ROOT_DIR/scripts/render-info.sh"

deck file merge \
  --output-file "$FINAL_FILE" \
  "$PLUGINS_FILE" \
  "$BUILD_DIR/_info.yaml"

echo "Built state file: $FINAL_FILE"
