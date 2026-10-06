#!/bin/bash
# Regenerates the beta-tester badges in marketing/testers/ (PNGs, plus vector
# SVGs in marketing/testers/svg/) with Chromium (Playwright in Docker), the
# app's Nunito font and the logo SVG.
#
#   SINCE_VERSION=1.0.0 SINCE_BUILD=183 ./scripts/generate_tester_assets.sh
#
# SINCE_VERSION/SINCE_BUILD set the "Since vX (N)" text: the first build the
# testers received.
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
IMAGE=mcr.microsoft.com/playwright:v1.57.0-noble
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp scripts/tester-assets/generate.mjs "$WORK/"
docker run --rm \
  -e SINCE_VERSION="${SINCE_VERSION:-1.0.0}" -e SINCE_BUILD="${SINCE_BUILD:-183}" \
  -v "$WORK:/work" -v "$PWD:/repo" -w /work -u "$(id -u):$(id -g)" -e HOME=/work \
  "$IMAGE" bash -c 'npm init -y >/dev/null && npm i --silent playwright@1.57.0 >/dev/null && node generate.mjs'

# SVG copies via Inkscape: text becomes outlines, so they print correctly
# without Nunito installed. (pdftocairo crashes on some of these PDFs.)
mkdir -p marketing/testers/svg
for pdf in "$WORK"/pdf/*.pdf; do
  name=$(basename "$pdf" .pdf)
  inkscape "$pdf" --pdf-poppler --export-type=svg --export-plain-svg \
    --export-filename="marketing/testers/svg/$name.svg" 2>/dev/null
  echo "marketing/testers/svg/$name.svg"
done
