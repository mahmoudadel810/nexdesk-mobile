#!/usr/bin/env bash
# Captures the store screenshots (English and Arabic) on the running emulator into build/store/.
# Needs the dev app installed and the local API seeded, as for `verify.sh --e2e`.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

output=build/maestro-store
rm -rf "$output" build/store
maestro test --test-output-dir "$output" e2e/suites/store_screenshots.yaml
mkdir -p build/store
find "$output" -path '*build/store/*.png' -exec cp {} build/store/ \;
ls build/store
