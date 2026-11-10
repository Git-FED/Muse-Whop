#!/usr/bin/env bash
# Mint a fresh Whop access token from the saved refresh token.
# Requires: WHOP_CLIENT_SECRET in the environment (never hardcode it).
# The refresh token rotates on every refresh; this re-saves it.
# Prints only the access token to stdout.
set -euo pipefail

CFG="${WHOP_OAUTH_CONFIG:-$HOME/.config/connections/whop-oauth.json}"
CLIENT_ID="${WHOP_CLIENT_ID:-app_as4wNcNUMX4FlM}"
: "${WHOP_CLIENT_SECRET:?set WHOP_CLIENT_SECRET first}"

if [[ ! -f "$CFG" ]]; then
  echo "missing OAuth config: $CFG" >&2
  exit 1
fi

REFRESH=$(python3 - "$CFG" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    print(json.load(f)['refresh_token'])
PY
)

RESP=$(curl -sS -m 30 -X POST "https://api.whop.com/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=refresh_token" \
  --data-urlencode "refresh_token=$REFRESH" \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "client_secret=$WHOP_CLIENT_SECRET")

TOKEN=$(printf '%s' "$RESP" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("access_token") or "")')
NEW_REFRESH=$(printf '%s' "$RESP" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("refresh_token") or "")')

if [[ -z "$TOKEN" ]]; then
  echo "mint failed: $RESP" >&2
  exit 1
fi

if [[ -n "$NEW_REFRESH" ]]; then
  NEW_REFRESH="$NEW_REFRESH" CFG="$CFG" python3 - <<'PY'
import json, os, tempfile
path = os.environ['CFG']
with open(path) as f:
    data = json.load(f)
data['refresh_token'] = os.environ['NEW_REFRESH']
fd, temp = tempfile.mkstemp(dir=os.path.dirname(path), prefix='.oauth-', text=True)
try:
    with os.fdopen(fd, 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
    os.chmod(temp, 0o600)
    os.replace(temp, path)
finally:
    if os.path.exists(temp):
        os.unlink(temp)
PY
fi

printf '%s\n' "$TOKEN"
