#!/bin/bash
# Prints the flags every TimeFlow build should pass to `flutter build`:
# a monotonically increasing build number (commits on the current history,
# which Play requires to grow with each upload) and build metadata defines.
#
#   flutter build appbundle $(./scripts/build_flags.sh)
#
# CI needs a full clone (fetch-depth: 0) for the commit count to be right.
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
echo "--build-number=$(git rev-list --count HEAD)" \
  "--dart-define=GIT_COMMIT=$(git rev-parse --short HEAD)" \
  "--dart-define=BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
