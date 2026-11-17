#!/usr/bin/env bash
# Refreshes the OpenAPI snapshot from a running API and regenerates the client. Commit both.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

API="${1:-http://localhost:8080}"
curl -fsS "$API/openapi/v1.json" -o openapi/nexdesk-v1.json
rm -rf lib/core/api/generated
dart run swagger_parser
echo "Snapshot and client updated from $API. Review the diff, then commit openapi/ and lib/core/api/generated/."
