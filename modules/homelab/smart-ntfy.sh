#!/usr/bin/env bash
# SMART summary for every disk -> ntfy. DRY_RUN=1 prints instead of posting.
set -uo pipefail
NTFY_URL="${NTFY_URL:-http://localhost:8033/mal-smart}"

good=""
bad=""
total=0
nbad=0
while read -r dev; do
  block=$(smartctl -j -a "$dev" | jq -r --arg dev "${dev#/dev/}" '
    ([.ata_smart_attributes.table[]? | {(.id | tostring): .raw.value}] | add // {}) as $a
    | (.ata_smart_self_test_log.standard.table[0].status.string
       // .nvme_self_test_log.table[0].self_test_result.string // "") as $test
    | [ (if (.smart_status.passed // false) then empty else "SMART health check failed" end),
        ($a["5"] // 0 | select(. > 0) | "\(.) reallocated sectors"),
        ($a["197"] // 0 | select(. > 0) | "\(.) pending sectors"),
        ($a["198"] // 0 | select(. > 0) | "\(.) uncorrectable sectors"),
        (.nvme_smart_health_information_log.media_errors // 0 | select(. > 0) | "\(.) media errors"),
        (.temperature.current // 0 | select(. >= 50) | "running hot"),
        ($test | select(test("fail|error"; "i") and (test("without error"; "i") | not)) | "last self-test: \(.)")
      ] as $issues
    | "\(if ($issues | length) > 0 then "❌" else "✅" end) \($dev) · \(.model_name // "unknown model")"
      + " · \(.temperature.current // "?")°C"
      + " · \(if .power_on_time.hours then "\(.power_on_time.hours / 876.6 | round / 10) yrs" else "? yrs" end)"
      + ($issues | map("\n      ↳ " + .) | join(""))
  ')
  total=$((total + 1))
  if [[ $block == ❌* ]]; then
    nbad=$((nbad + 1))
    bad+="$block"$'\n'
  else
    good+="$block"$'\n'
  fi
done < <(smartctl --scan -j | jq -r '.devices[].name')

if ((nbad)); then
  title="$nbad of $total disks need attention"
  prio=urgent
  tags=warning
else
  title="All $total disks healthy"
  prio=low
  tags=white_check_mark
fi
body="$bad$good"

if [[ -n ${DRY_RUN:-} ]]; then
  printf '%s\n\n%s' "$title" "$body"
  exit 0
fi
curl -fsS -o /dev/null -H "Title: $title" -H "Priority: $prio" -H "Tags: $tags" -d "$body" "$NTFY_URL"
