#!/bin/bash
# Regenerates the Google Play phone screenshots in docs/store/screenshots/
# (1080×1920 PNG, no transparency) from a release web build, with Chromium
# (Playwright) in Docker. The designs and seeded tasks are in
# scripts/play-screenshots/generate.mjs.
#
#   ./scripts/generate_play_screenshots.sh
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
IMAGE=mcr.microsoft.com/playwright:v1.57.0-noble
flutter build web --release --no-web-resources-cdn --base-href=/
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/out"
cp scripts/play-screenshots/generate.mjs "$WORK/"
docker run --rm \
  -v "$WORK:/work" -v "$PWD/build/web:/web:ro" -w /work \
  -u "$(id -u):$(id -g)" -e HOME=/work \
  "$IMAGE" bash -c 'npm init -y >/dev/null && npm i --silent playwright@1.57.0 >/dev/null && node generate.mjs'
# Play wants 24-bit PNGs (no alpha channel).
rm -f docs/store/screenshots/*.png
for f in "$WORK"/out/*.png; do
  magick "$f" -background white -alpha remove -alpha off \
    "docs/store/screenshots/$(basename "$f")"
  echo "docs/store/screenshots/$(basename "$f")"
done
