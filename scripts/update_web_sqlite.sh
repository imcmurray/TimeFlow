#!/bin/bash
# Downloads the web runtime files drift needs (sqlite3.wasm, drift_worker.js)
# into web/, matching the drift and sqlite3 versions in pubspec.lock.
# Re-run after upgrading drift or sqlite3.
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.."
version() { awk -v p="  $1:" '$0==p{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock; }
DRIFT=$(version drift)
SQLITE=$(version sqlite3)
gh release download "drift-$DRIFT" -R simolus3/drift -p drift_worker.js -D web --clobber
gh release download "sqlite3-$SQLITE" -R simolus3/sqlite3.dart -p sqlite3.wasm -D web --clobber
echo "web/ now has drift_worker.js for drift $DRIFT and sqlite3.wasm for sqlite3 $SQLITE"
