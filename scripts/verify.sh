#!/usr/bin/env bash
# Everything a change must pass before it is merged. `--e2e` also builds the dev app and runs the Maestro flows
# on a running emulator against the local API (docker compose in nexdesk-api, seeded with --seed).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

echo "== Dependencies"
flutter pub get >/dev/null

echo "== Generated code is current"
dart run swagger_parser >/dev/null
flutter gen-l10n >/dev/null
dart run build_runner build --delete-conflicting-outputs >/dev/null
git diff --exit-code --stat -- lib/core/api/generated lib/core/l10n/generated ':(glob)lib/**/*.g.dart'
untracked=$(git ls-files --others --exclude-standard -- lib/core/api/generated lib/core/l10n/generated)
if [[ -n "$untracked" ]]; then
  echo "Generated files are not committed:" >&2
  echo "$untracked" >&2
  exit 1
fi

echo "== Format"
mapfile -t sources < <(find lib test scripts -name '*.dart' -not -name '*.g.dart' -not -path '*/generated/*')
dart format --output=none --set-exit-if-changed "${sources[@]}"

echo "== Localizations and layout direction"
dart run scripts/check_l10n.dart
scripts/check-directional.sh

echo "== Analyze"
flutter analyze --fatal-infos

echo "== Tests"
flutter test

if [[ "${1:-}" == "--e2e" ]]; then
  echo "== End to end (Maestro)"
  scripts/firebase-config.sh
  flutter build apk --flavor dev -t lib/main_dev.dart --debug
  # The Gradle daemon keeps about 1.5 GB after the build; with the emulator running that exhausts a 16 GB machine.
  (cd android && ./gradlew --stop -q) || true
  adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk >/dev/null
  scripts/e2e-fixtures.sh
  # One flow at a time, retried once: Maestro's Android driver sometimes drops between flows and fails the next
  # one within milliseconds, which says nothing about the app.
  for flow in e2e/*.yaml; do
    maestro test "$flow" >/dev/null 2>&1 || maestro test "$flow"
    echo "  passed: $flow"
  done
fi

echo "All checks passed."
