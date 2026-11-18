#!/usr/bin/env bash
# Copies each flavor's Firebase config into the app when it exists in ~/.config/nexdesk-mobile/<flavor>/.
# The files are gitignored and never committed. Without them the app builds with push turned off.
set -euo pipefail
cd "$(dirname "$0")/.."

source_root="${NEXDESK_MOBILE_CONFIG:-$HOME/.config/nexdesk-mobile}"
for flavor in dev prod; do
  if [[ -f "$source_root/$flavor/google-services.json" ]]; then
    cp "$source_root/$flavor/google-services.json" "android/app/src/$flavor/google-services.json"
    echo "Firebase ($flavor, Android): configured"
  fi
  if [[ -f "$source_root/$flavor/GoogleService-Info.plist" ]]; then
    mkdir -p "ios/config/$flavor"
    cp "$source_root/$flavor/GoogleService-Info.plist" "ios/config/$flavor/GoogleService-Info.plist"
    echo "Firebase ($flavor, iOS): configured"
  fi
done
