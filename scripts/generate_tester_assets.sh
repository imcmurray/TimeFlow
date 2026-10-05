#!/bin/bash
# Regenerates the beta-tester badges in marketing/testers/ with Chromium
# (Playwright in Docker), the app's Nunito font and the logo SVG.
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
