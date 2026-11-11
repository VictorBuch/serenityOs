#!/usr/bin/env bash
# OnSuccess=/OnFailure= hook: report a failed job, or one that logged warnings, to ntfy.
# A clean run stays silent. systemd passes the $MONITOR_* vars; to test against a past run:
#   DRY_RUN=1 MONITOR_UNIT=snapraid-sync.service MONITOR_INVOCATION_ID=<id> [MONITOR_SERVICE_RESULT=exit-code] ntfy-job.sh
set -uo pipefail
NTFY_URL="${NTFY_URL:-http://localhost:8033/mal-jobs}"
id=${MONITOR_INVOCATION_ID:?}
name=${MONITOR_UNIT%.service}
result=${MONITOR_SERVICE_RESULT:-success}

# The run's log without snapraid's \r progress meter, wait-time chart and content-file bookkeeping.
log=$(journalctl "_SYSTEMD_INVOCATION_ID=$id" -o cat | tr '\r' '\n' | grep -vE \
  '^[0-9]+%, |ETA$|^ *[a-z0-9]+ +[0-9]+% \||^ +\|_|wait time \(|^(Saving|Saved) state|^Verif(ying|ied)')
# For snapraid only what follows "Syncing..."/"Scrubbing..." matters, if it got that far.
if grep -qxE '(Syncing|Scrubbing)\.\.\.' <<<"$log"; then
  log=$(sed -n '/^\(Syncing\|Scrubbing\)\.\.\.$/,$p' <<<"$log" | tail -n +2)
fi
warnings=$(grep -iE 'warning|danger|error' <<<"$log" | sort -u)

if [[ $result == success ]]; then
  if [[ -z $warnings ]]; then
    [[ -n ${DRY_RUN:-} ]] && echo "$name: clean run, nothing sent"
    exit 0
  fi
  title="$name finished with warnings"
  tags=warning
  body=$(head -n 15 <<<"$warnings")
else
  title="$name failed ($result${MONITOR_EXIT_STATUS:+, status $MONITOR_EXIT_STATUS})"
  tags=x
  body=$(tail -n 15 <<<"$log")
fi
secs=$(journalctl "_SYSTEMD_INVOCATION_ID=$id" -o json | jq -s \
  'if length > 0 then (.[-1].__REALTIME_TIMESTAMP | tonumber) - (.[0].__REALTIME_TIMESTAMP | tonumber) else 0 end / 1e6 | floor')
body="Ran $((secs / 60))m $((secs % 60))s."$'\n\n'"$body"

if [[ -n ${DRY_RUN:-} ]]; then
  printf '%s\n\n%s\n' "$title" "$body"
  exit 0
fi
curl -fsS -o /dev/null -H "Title: $title" -H "Priority: high" -H "Tags: $tags" -d "$body" "$NTFY_URL"
