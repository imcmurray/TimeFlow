#!/bin/bash
# Regenerate PNG icons from SVG source files
# Usage: ./regenerate-icons.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_ICONS_DIR="$SCRIPT_DIR/../../web/icons"
WEB_DIR="$SCRIPT_DIR/../../web"

echo "Regenerating TimeFlow icons from SVG..."

# Check for required tools
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick (magick) is required but not installed."
    exit 1
fi

# Generate standard icons from timeflow-logo.svg
echo "  Creating Icon-512.png..."
magick "$SCRIPT_DIR/timeflow-logo.svg" -resize 512x512 "$WEB_ICONS_DIR/Icon-512.png"

echo "  Creating Icon-192.png..."
magick "$SCRIPT_DIR/timeflow-logo.svg" -resize 192x192 "$WEB_ICONS_DIR/Icon-192.png"

# Generate maskable icons from timeflow-logo-maskable.svg
echo "  Creating Icon-maskable-512.png..."
magick "$SCRIPT_DIR/timeflow-logo-maskable.svg" -resize 512x512 "$WEB_ICONS_DIR/Icon-maskable-512.png"

echo "  Creating Icon-maskable-192.png..."
magick "$SCRIPT_DIR/timeflow-logo-maskable.svg" -resize 192x192 "$WEB_ICONS_DIR/Icon-maskable-192.png"

# Generate favicon (use maskable version for solid background)
echo "  Creating favicon.png..."
magick "$SCRIPT_DIR/timeflow-logo-maskable.svg" -resize 32x32 "$WEB_DIR/favicon.png"

echo "Done! Icons regenerated successfully."
