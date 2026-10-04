#!/bin/bash
# Regenerates the Android adaptive-icon foreground from the logo SVG: the
# mark at 58% of the 108dp canvas, inside the 66% safe zone.
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
R=android/app/src/main/res
TMP=$(mktemp -d)
for d in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
  n=${d%%:*}; px=${d##*:}; inner=$((px * 58 / 100))
  rsvg-convert -w $inner -h $inner assets/branding/timeflow-logo.svg -o "$TMP/fg.png"
  magick -size ${px}x${px} xc:none "$TMP/fg.png" -gravity center -composite \
    "$R/mipmap-$n/ic_launcher_foreground.png"
done
rm -rf "$TMP"
