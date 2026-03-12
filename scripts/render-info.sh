#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="$ROOT_DIR/config/_info.yaml.tmpl"
OUTPUT_FILE="$ROOT_DIR/build/_info.yaml"

: "${DECK_SELECT_TAG:?DECK_SELECT_TAG is required}"

# Render from template while keeping dependencies minimal.
awk -v tag="$DECK_SELECT_TAG" '{ gsub(/\$\{DECK_SELECT_TAG\}/, tag); print }' "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Rendered $OUTPUT_FILE with DECK_SELECT_TAG=$DECK_SELECT_TAG"
