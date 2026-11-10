#!/usr/bin/env bash
# Deploy the Muse Whop site to the app that owns the domain, then verify it live.
# Run from anywhere; this script resolves its own project directory.
# Requires: WHOP_CLIENT_SECRET in the environment (never hardcode it).
set -euo pipefail

PROJECT_DIR="${MUSE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
APP_ID="${WHOP_APP_ID:-app_ucDE8WcgL4X1R1}"
LIVE_URL="${WHOP_LIVE_URL:-https://muse-ai-community.whop.site/}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PATH="/home/hatch/.local/bin:$PATH"
cd "$PROJECT_DIR"

TOKEN=$(bash "$SCRIPT_DIR/mint-token.sh")
WHOP_API_KEY="$TOKEN" whop apps deploy --app "$APP_ID" --skip_build
sleep "${WHOP_VERIFY_DELAY:-5}"

curl -sS -o /tmp/whop-live.html -w "live check: HTTP %{http_code}, %{size_download} bytes\n" \
  -A "Mozilla/5.0" "$LIVE_URL"

if grep -Eiq "sports betting|muse clips|crypto cloud mining|game modding" /tmp/whop-live.html; then
  echo "content OK: lineup items present"
else
  echo "WARNING: expected lineup items missing from live page" >&2
  exit 1
fi
