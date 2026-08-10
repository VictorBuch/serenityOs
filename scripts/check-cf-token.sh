#!/usr/bin/env bash
# Verifies the existing cloudflare/api_token can do DNS-01 on both zones,
# and on success copies it into secrets/vps.yaml for wash.
# One-shot helper for PANGOLIN_CUTOVER.md Phase 0 — delete after cutover.
set -euo pipefail

cd "$(dirname "$0")/.."

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/age-yubikey-identity-907e6f67.txt}"

echo "==> Decrypting token (YubiKey touch may be required)..."
TOKEN=$(sops -d --extract '["cloudflare"]["api_token"]' secrets/secrets.yaml)

api() { curl -s -H "Authorization: Bearer $TOKEN" "$@"; }

echo "==> 1/3 Token alive?"
ok=$(api https://api.cloudflare.com/client/v4/user/tokens/verify | jq -r .success)
echo "    verify: $ok"
[ "$ok" = "true" ] || { echo "FAIL: token invalid — mint a fresh one."; exit 1; }

check_zone() {
  local zone="$1"
  echo "==> Zone $zone"
  local zid
  zid=$(api "https://api.cloudflare.com/client/v4/zones?name=$zone" | jq -r '.result[0].id')
  if [ -z "$zid" ] || [ "$zid" = "null" ]; then
    echo "FAIL: token cannot see zone $zone — mint a fresh one."
    exit 1
  fi
  echo "    zone id: $zid"

  # Clean up any leftover _scope-test records from earlier manual attempts
  api "https://api.cloudflare.com/client/v4/zones/$zid/dns_records?type=TXT&name=_scope-test.$zone" \
    | jq -r '.result[].id' \
    | while read -r old; do
        api -X DELETE "https://api.cloudflare.com/client/v4/zones/$zid/dns_records/$old" >/dev/null
        echo "    removed leftover _scope-test record"
      done

  local resp rid name="_scope-test-$RANDOM"
  resp=$(api -X POST -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/$zid/dns_records" \
    -d "{\"type\":\"TXT\",\"name\":\"$name\",\"content\":\"ok\",\"ttl\":60}")
  if [ "$(echo "$resp" | jq -r .success)" != "true" ]; then
    echo "FAIL: cannot write DNS in $zone — mint a fresh token (Zone/DNS/Edit on both zones)."
    echo "$resp" | jq '.errors'
    exit 1
  fi
  rid=$(echo "$resp" | jq -r '.result.id')
  echo "    TXT write: OK"

  api -X DELETE "https://api.cloudflare.com/client/v4/zones/$zid/dns_records/$rid" >/dev/null
  echo "    cleanup: OK"
}

echo "==> 2/3 DNS write test"
check_zone victorbuch.com
check_zone smoothless.org

echo "==> 3/3 All checks passed — copying token into secrets/vps.yaml"
sops set secrets/vps.yaml '["cloudflare"]["api_token"]' "\"$TOKEN\""
echo "Done. Phase 0 complete — continue with Phase 1 (order the VPS)."
