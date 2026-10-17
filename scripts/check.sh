#!/usr/bin/env bash
# Everything CI's "Analyze and test" job runs, in the same order, with the same environment.
#
#   scripts/check.sh            all four gates
#   scripts/check.sh --fix      format first, then the rest (what you want while writing)
#
# It exists because passing two of the four locally and calling it green is easy, and it has
# happened: TimeFlow#67 failed on `dart format` with analyze and the tests both passing,
# which skipped all three build jobs. `flutter test` also needs TZ set the way CI sets it,
# or a timezone-sensitive test can pass here and fail there.
#
# To stop this drifting from the workflow, each command below is checked against
# .github/workflows/ci.yml before anything runs. Change the job and this fails loudly
# naming what no longer matches, which is the only way a mirror stays a mirror.
set -uo pipefail
cd "$(dirname "$0")/.."
WORKFLOW=".github/workflows/ci.yml"
FIX=false
[ "${1:-}" = "--fix" ] && FIX=true

GATES=(
  "dart run build_runner build --delete-conflicting-outputs"
  "git diff --exit-code -- lib"
  "dart format --output=none --set-exit-if-changed lib test"
  "flutter analyze"
  "flutter test"
)

missing=()
for gate in "${GATES[@]}"; do
  grep -qF -- "$gate" "$WORKFLOW" || missing+=("$gate")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "This script no longer mirrors $WORKFLOW. Not in the workflow any more:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  echo "Update both together, or the local run stops meaning anything." >&2
  exit 1
fi
grep -q "TZ: America/Denver" "$WORKFLOW" || {
  echo "$WORKFLOW no longer sets TZ: America/Denver for the tests; fix this script too." >&2
  exit 1
}

if $FIX; then
  echo "── dart format (writing) ──"
  dart format lib test || exit 1
fi

failed=()
run() {
  echo "── $* ──"
  if ! "$@"; then failed+=("$*"); fi
}

run flutter pub get

# CI's gate is `git diff --exit-code -- lib` on a clean checkout, where any diff means
# generated code wasn't committed. Run that verbatim here and it reports whatever you are
# in the middle of writing instead, which is a script that cries wolf every time it is
# useful. What CI is actually asking is whether build_runner has output nobody committed,
# so compare the diff either side of it: unchanged means your edits are your own.
before="$(git diff -- lib | sha256sum)"
run dart run build_runner build --delete-conflicting-outputs
if [ "$(git diff -- lib | sha256sum)" != "$before" ]; then
  echo "── git diff --exit-code -- lib ──"
  echo "build_runner changed files under lib that are not committed." >&2
  git --no-pager diff --stat -- lib >&2
  failed+=("git diff --exit-code -- lib")
elif git diff --quiet -- lib; then
  echo "── git diff --exit-code -- lib ──"
else
  echo "── git diff -- lib: build_runner added nothing; what's there is yours, uncommitted ──"
fi
run dart format --output=none --set-exit-if-changed lib test
run flutter analyze
# `env`, not a VAR=x prefix: that form in front of a shell function leaks the assignment
# into the calling shell in some bashes, and a timezone that outlives the command it was
# for is exactly the kind of thing that makes the next gate lie.
run env TZ=America/Denver flutter test

echo
if [ ${#failed[@]} -gt 0 ]; then
  echo "${#failed[@]} gate(s) failed — CI will fail the same way:" >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi
echo "all gates pass; CI's Analyze and test job will too"
