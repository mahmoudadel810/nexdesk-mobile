#!/usr/bin/env bash
# Arabic flips the layout, so spacing and alignment must say start/end, never left/right.
set -euo pipefail
cd "$(dirname "$0")/.."
pattern='EdgeInsets\.only\([^)]*(left|right):|EdgeInsets\.fromLTRB|Alignment\.(center|top|bottom)(Left|Right)|Positioned\([^)]*(left|right):|TextAlign\.(left|right)'
if grep -rnE "$pattern" lib --include='*.dart' --exclude-dir=generated; then
  echo "Use EdgeInsetsDirectional, AlignmentDirectional, PositionedDirectional and TextAlign.start/end instead." >&2
  exit 1
fi
