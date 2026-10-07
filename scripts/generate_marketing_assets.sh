#!/bin/bash
# Regenerates the marketing and press kit PNGs in marketing/ from the logo
# SVGs (assets/branding/timeflow-logo*.svg) and the app's Nunito font.
#
#   ./scripts/generate_marketing_assets.sh
#
# Chromium (Playwright in Docker) lays each design out and prints it to a
# vector PDF; Inkscape turns that into an SVG and rsvg-convert rasterises it to
# every size, so the large print files stay sharp. Needs Docker, Inkscape,
# rsvg-convert (librsvg) and ImageMagick; works on Linux and macOS.
#
# Every PNG carries DPI metadata: 300/800/1000/1500 for print folders, 72 for
# screen ones. The 800/1000/1500 DPI folders are gitignored (see
# marketing/README.md for the release download).
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
IMAGE=mcr.microsoft.com/playwright:v1.57.0-noble
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp scripts/marketing-assets/generate.mjs "$WORK/"
docker run --rm \
  -v "$WORK:/work" -v "$PWD:/repo:ro" -w /work -u "$(id -u):$(id -g)" -e HOME=/work \
  "$IMAGE" bash -c 'npm init -y >/dev/null && npm i --silent playwright@1.57.0 >/dev/null && node generate.mjs' >/dev/null

python3 -c '
import json, sys
for d in json.load(open(sys.argv[1])):
    for o in d["outputs"]:
        print(d["id"], o["path"], o["w"], o["h"], o["dpi"])
' "$WORK/manifest.json" | while read -r id path w h dpi; do
  svg="$WORK/$id.svg"
  if [[ ! -f $svg ]]; then
    inkscape "$WORK/pdf/$id.pdf" --pdf-poppler --export-type=svg --export-plain-svg \
      --export-filename="$svg" 2>/dev/null
  fi
  out="marketing/$path"
  mkdir -p "$(dirname "$out")"
  rsvg-convert -w "$w" -h "$h" "$svg" -o "$out"
  magick "$out" -units PixelsPerInch -density "$dpi" "$out"
  echo "$out"
done
