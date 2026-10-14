#!/bin/bash
# Prints the flags every TimeFlow build should pass to `flutter build`:
# a monotonically increasing build number (commits on the current history,
# which Play requires to grow with each upload) and build metadata defines.
#
#   flutter build appbundle $(./scripts/build_flags.sh)
#
# CI needs a full clone (fetch-depth: 0) for the commit count to be right.
#
# TIMEFLOW_BETA=1 makes a tester build: it adds the Feedback button that opens
# the tester portal (lib/build_info.dart). Never use it for store builds.
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
BETA=""
[ "${TIMEFLOW_BETA:-}" = 1 ] && BETA="--dart-define=BETA_FEEDBACK=true"
echo "--build-number=$(git rev-list --count HEAD)" \
  "--dart-define=GIT_COMMIT=$(git rev-parse --short HEAD)" \
  "--dart-define=BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  $BETA
