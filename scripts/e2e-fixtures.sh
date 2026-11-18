#!/usr/bin/env bash
# Puts a 12 MP camera-sized photo (4000x3000 JPEG, about 6.6 MB) in the emulator's photo library for
# e2e/attach_photo.yaml. The photo is generated with ffmpeg on first use and kept in build/.
set -euo pipefail
cd "$(dirname "$0")/.."

photo=build/e2e-fixtures/nexdesk-e2e-photo.jpg
if [[ ! -f "$photo" ]]; then
  mkdir -p "$(dirname "$photo")"
  ffmpeg -loglevel error -y -f lavfi -i "mandelbrot=s=4000x3000:end_pts=1,noise=alls=12:allf=t" \
    -frames:v 1 -q:v 2 "$photo"
fi

target=/sdcard/Pictures/nexdesk-e2e-photo.jpg
adb push "$photo" "$target" >/dev/null
# Newer Android versions ignore the broadcast and need the scan call; older ones the other way round.
adb shell content call --method scan_volume --uri content://media --arg external_primary >/dev/null 2>&1 || true
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://$target" >/dev/null 2>&1 || true
