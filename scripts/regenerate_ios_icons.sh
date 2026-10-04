#!/bin/bash
# Regenerates the iOS app icons from the logo SVG: the mark on white (iOS
# icons can't be transparent), at 70% of the canvas.
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
D=ios/Runner/Assets.xcassets/AppIcon.appiconset
TMP=$(mktemp -d)
rsvg-convert -w 717 -h 717 assets/branding/timeflow-logo.svg -o "$TMP/mark.png"
magick -size 1024x1024 xc:white "$TMP/mark.png" -gravity center -composite \
  -alpha off "$TMP/icon-1024.png"
python3 - "$D" "$TMP/icon-1024.png" <<'PY'
import json, subprocess, sys
d, src = sys.argv[1], sys.argv[2]
for img in json.load(open(f"{d}/Contents.json"))["images"]:
    px = round(float(img["size"].split("x")[0]) * int(img["scale"][0]))
    subprocess.run(["magick", src, "-resize", f"{px}x{px}", "-alpha", "off", "-depth", "8",
                    f"{d}/{img['filename']}"], check=True)
PY
rm -rf "$TMP"
