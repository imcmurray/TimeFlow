#!/bin/bash
# Renders the beta-tester PNGs in marketing/testers/ from the SVGs in
# marketing/testers/svg/, which are the source (and may be hand-edited in
# Inkscape). For each svg/NAME.svg, every existing NAME-WxH.png is redrawn at
# W×H with a transparent background.
#
#   ./scripts/render_tester_pngs.sh
#
# Needs Inkscape.
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/../marketing/testers"
for svg in svg/*.svg; do
  name=$(basename "$svg" .svg)
  for png in *.png; do
    # Exact match, so "timeflow-tester" doesn't pick up "timeflow-tester-stacked-…".
    [[ $png =~ ^${name}-([0-9]+)x([0-9]+)\.png$ ]] || continue
    inkscape "$svg" --export-type=png --export-filename="$png" \
      --export-width="${BASH_REMATCH[1]}" --export-height="${BASH_REMATCH[2]}" \
      --export-background-opacity=0 2>/dev/null
    echo "marketing/testers/$png"
  done
done
