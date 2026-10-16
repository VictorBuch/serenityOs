#!/usr/bin/env bash
# herdr-sesh — a sesh-style space picker for the herdr multiplexer.
#
# `herdr-sesh` (no args) shows an fzf list of predefined "spaces", followed by
# your top zoxide directories. Selecting an entry either focuses the matching
# workspace if it already exists, or builds it:
#   - a configured space  -> named workspace with tabs, split panes, and startup
#     commands already running (the herdr equivalent of `sesh connect`),
#   - a zoxide directory   -> a bare workspace at that path, named after the dir.
#
# Spaces are read from $HERDR_SESH_CONFIG (default: ~/.config/herdr/sesh-spaces.json),
# which is generated declaratively by the Nix module.
set -euo pipefail

CONFIG="${HERDR_SESH_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/sesh-spaces.json}"
ZOXIDE_LIMIT="${HERDR_SESH_ZOXIDE_LIMIT:-20}"
STAR="★ "  # marks configured spaces in the picker, vs. plain zoxide paths
DOT="● "   # marks running ad-hoc workspaces
LAST_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/herdr-sesh-last"
CMDS_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-sesh/cmds"  # read by the shell hook in herdr.nix
TILDE='~'  # kept in a var so shellcheck doesn't mistake it for an expansion

die() { printf 'herdr-sesh: %s\n' "$*" >&2; exit 1; }

# Strip the leading marker a picker entry carries.
strip_star() { local s="${1#"$STAR"}"; printf '%s' "${s#"$DOT"}"; }

focused_ws() {
  herdr workspace list 2>/dev/null | jq -r 'first(.result.workspaces[] | select(.focused) | .workspace_id) // empty'
}

# Remember the workspace we are leaving, for `herdr-sesh last`.
remember_current() {
  local cur
  cur=$(focused_ws)
  [ -n "$cur" ] || return 0
  mkdir -p "${LAST_FILE%/*}"
  printf '%s\n' "$cur" >"$LAST_FILE"
}

# Swap back to the previously remembered workspace (tmux switch-client -l).
last() {
  local target
  target=$(cat "$LAST_FILE" 2>/dev/null || true)
  [ -n "$target" ] || exit 0
  [ "$target" = "$(focused_ws)" ] && exit 0
  remember_current
  herdr workspace focus "$target" >/dev/null 2>&1 || true
}

expand_tilde() {
  local p="$1"
  if [ "$p" = "~" ]; then
    printf '%s' "$HOME"
  elif [ "${p#\~/}" != "$p" ]; then
    printf '%s' "$HOME/${p#\~/}"
  else
    printf '%s' "$p"
  fi
}

# Display absolute paths under $HOME as ~/... for a tidier picker.
shorten_home() {
  local p="$1"
  if [ "$p" = "$HOME" ]; then
    printf '%s' "$TILDE"
  elif [ "${p#"$HOME"/}" != "$p" ]; then
    printf '%s/%s' "$TILDE" "${p#"$HOME"/}"
  else
    printf '%s' "$p"
  fi
}

# Extract a single space object by name.
get_space() {
  jq -c --arg n "$1" '.spaces[] | select(.name == $n)' "$CONFIG"
}

# The picker list: configured spaces first, then top zoxide dirs (deduped
# against the spaces' own paths, existing dirs only, home-shortened).
list_items() {
  # Running workspaces that aren't configured spaces, like sesh's tmux sessions.
  herdr workspace list 2>/dev/null | jq -r --arg dot "$DOT" --slurpfile cfg "$CONFIG" '
    ($cfg[0].spaces | map(.name)) as $names
    | .result.workspaces[] | select(.focused | not) | .label
    | select(. as $l | $names | index($l) | not) | $dot + .' || true

  jq -r --arg star "$STAR" '.spaces[] | $star + .name' "$CONFIG"

  command -v zoxide >/dev/null 2>&1 || return 0

  # Absolute paths already covered by a configured space.
  local cfg expanded="" cp
  cfg=$(jq -r '.spaces[].path // empty' "$CONFIG")
  while IFS= read -r cp; do
    [ -n "$cp" ] && expanded+="$(expand_tilde "$cp")"$'\n'
  done <<<"$cfg"

  local dir shown=0
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    [ -d "$dir" ] || continue
    printf '%s\n' "$expanded" | grep -qxF "$dir" && continue
    shorten_home "$dir"; printf '\n'
    shown=$((shown + 1))
    [ "$shown" -ge "$ZOXIDE_LIMIT" ] && break
  done < <(zoxide query --list 2>/dev/null)
}

# Start commands are never typed into a pane. Each pane is created with
# HERDR_SESH_CMD in its env, and the shell hook in herdr.nix runs it at the
# first prompt (after direnv). The command is also saved under the pane id:
# herdr's restore keeps pane ids but drops env, so the hook falls back to the
# saved file and restored panes start their commands again.
# ponytail: a workspace id reused after a manual close + server restart could
# inherit stale files; gc_cmds and clear_ws_cmds narrow that to rare.
ENV_ARGS=()
with_cmd() {
  ENV_ARGS=()
  [ -n "$1" ] && ENV_ARGS=(--env "HERDR_SESH_CMD=$1")
  return 0
}

save_cmd() {
  [ -n "$2" ] || return 0
  mkdir -p "$CMDS_DIR"
  printf '%s' "$2" >"$CMDS_DIR/$1"
}

clear_ws_cmds() { rm -f "$CMDS_DIR/$1:"*; }

# Drop saved commands for panes that no longer exist.
gc_cmds() {
  local live f
  live=$(herdr pane list 2>/dev/null | jq -r '.result.panes[].pane_id') || return 0
  [ -n "$live" ] || return 0
  for f in "$CMDS_DIR"/*; do
    [ -e "$f" ] || continue
    grep -qxF "${f##*/}" <<<"$live" || rm -f "$f"
  done
}

# Build a configured space from scratch: workspace -> tabs -> panes -> commands.
build_space() {
  local name="$1" space
  space=$(get_space "$name")
  [ -n "$space" ] || die "unknown space: $name"

  local path
  path=$(expand_tilde "$(jq -r '.path // "~"' <<<"$space")")

  # A space is a list of tabs. If none given, synthesize one from a top-level
  # `command` (single-shot spaces like an ssh session), else a bare shell.
  local tabs ntabs
  tabs=$(jq -c '.tabs // (if .command then [{panes:[{command:.command}]}] else [{}] end)' <<<"$space")
  ntabs=$(jq 'length' <<<"$tabs")

  # Creating a workspace also creates its first tab and root pane.
  local created ws first_tab first_pane
  with_cmd "$(jq -r '.[0].panes[0].command // empty' <<<"$tabs")"
  created=$(herdr workspace create --cwd "$path" --label "$name" --focus "${ENV_ARGS[@]}")
  ws=$(jq -r '.result.workspace.workspace_id' <<<"$created")
  first_tab=$(jq -r '.result.tab.tab_id' <<<"$created")
  first_pane=$(jq -r '.result.root_pane.pane_id' <<<"$created")
  clear_ws_cmds "$ws"

  local ti
  for (( ti = 0; ti < ntabs; ti++ )); do
    local tab tabname tabcwd root_pane
    tab=$(jq -c ".[$ti]" <<<"$tabs")
    tabname=$(jq -r '.name // empty' <<<"$tab")
    tabcwd=$(jq -r '.path // empty' <<<"$tab")
    if [ -n "$tabcwd" ]; then tabcwd=$(expand_tilde "$tabcwd"); else tabcwd="$path"; fi

    if [ "$ti" -eq 0 ]; then
      # Reuse the workspace's first tab/pane.
      root_pane="$first_pane"
      [ -n "$tabname" ] && herdr tab rename "$first_tab" "$tabname" >/dev/null
    else
      local label=()
      [ -n "$tabname" ] && label=(--label "$tabname")
      with_cmd "$(jq -r '.panes[0].command // empty' <<<"$tab")"
      root_pane=$(herdr tab create --workspace "$ws" --cwd "$tabcwd" "${label[@]}" --no-focus "${ENV_ARGS[@]}" \
        | jq -r '.result.root_pane.pane_id')
    fi

    # Lay out panes within the tab. The first pane is the tab's root; each
    # subsequent pane splits off the previous one.
    local panes npanes pj prev
    panes=$(jq -c '.panes // []' <<<"$tab")
    npanes=$(jq 'length' <<<"$panes")
    prev="$root_pane"
    for (( pj = 0; pj < npanes; pj++ )); do
      local pane target cmd
      pane=$(jq -c ".[$pj]" <<<"$panes")
      cmd=$(jq -r '.command // empty' <<<"$pane")
      if [ "$pj" -eq 0 ]; then
        target="$root_pane"
      else
        local ratio=()
        [ "$(jq -r '.ratio // empty' <<<"$pane")" ] && ratio=(--ratio "$(jq -r '.ratio' <<<"$pane")")
        with_cmd "$cmd"
        target=$(herdr pane split "$prev" --direction "$(jq -r '.direction // "right"' <<<"$pane")" \
          --cwd "$tabcwd" "${ratio[@]}" --no-focus "${ENV_ARGS[@]}" | jq -r '.result.pane.pane_id')
      fi
      save_cmd "$target" "$cmd"
      prev="$target"
    done
  done

  herdr workspace focus "$ws" >/dev/null 2>&1 || true
}

find_ws() {
  herdr workspace list 2>/dev/null \
    | jq -r --arg n "$1" 'first(.result.workspaces[] | select(.label == $n) | .workspace_id) // empty'
}

# Focus the workspace with this label if one exists. 0 = focused, 1 = none.
focus_existing() {
  local existing
  existing=$(find_ws "$1")
  [ -n "$existing" ] || return 1
  herdr workspace focus "$existing" >/dev/null 2>&1 || true
  return 0
}

# Open a bare workspace at a directory, named after its basename (zoxide entry).
open_dir() {
  local dir name
  dir=$(expand_tilde "$1")
  [ -d "$dir" ] || die "not a directory: $dir"
  name=$(basename "$dir")
  if command -v zoxide >/dev/null 2>&1; then zoxide add "$dir" 2>/dev/null || true; fi
  focus_existing "$name" && return 0
  clear_ws_cmds "$(herdr workspace create --cwd "$dir" --label "$name" --focus | jq -r '.result.workspace.workspace_id')"
}

# Route a picked item: a configured space, otherwise a directory path.
dispatch() {
  local item="$1" space ws
  remember_current
  gc_cmds
  space=$(get_space "$item")
  if [ -n "$space" ]; then
    ws=$(find_ws "$item")
    if [ -n "$ws" ]; then
      herdr workspace focus "$ws" >/dev/null 2>&1 || true
    else
      build_space "$item"
    fi
  elif [ -n "$(find_ws "$item")" ]; then
    focus_existing "$item"
  else
    open_dir "$item"
  fi
}

# fzf preview: space layout summary, or a directory listing for zoxide entries.
preview() {
  local item space
  item=$(strip_star "$1")
  space=$(get_space "$item")
  if [ -n "$space" ]; then
    local pcmd
    pcmd=$(jq -r '.preview // empty' <<<"$space")
    if [ -n "$pcmd" ]; then
      bash -c "$pcmd" 2>/dev/null || true
      echo
    fi
    jq -r '
      "path: \(.path // "~")",
      "",
      ( .tabs // (if .command then [{panes:[{command:.command}]}] else [{}] end)
        | to_entries[]
        | " \(.value.name // "tab \(.key + 1)")"
          + ( (.value.panes // [])
              | map(.command // "shell")
              | if length > 0 then "  →  " + join("  |  ") else "" end )
      )' <<<"$space"
    return 0
  fi

  # Not a configured space: treat as a directory path.
  local dir
  dir=$(expand_tilde "$item")
  if [ -d "$dir" ]; then
    printf ' %s\n\n' "$item"
    # shellcheck disable=SC2012  # a simple listing for preview; filenames are trusted
    ls -A --group-directories-first "$dir" 2>/dev/null | head -n 60
  fi
}

main() {
  [ -f "$CONFIG" ] || die "no config at $CONFIG"
  case "${1:-}" in
    --list)    list_items; exit 0 ;;
    --preview) preview "${2:-}"; exit 0 ;;
    connect)   dispatch "${2:?usage: herdr-sesh connect <name|dir>}"; exit 0 ;;
    last)      last; exit 0 ;;
  esac

  # Outside herdr (the `s` alias in a plain terminal) start the server if
  # needed, then attach after picking, like `sesh connect` outside tmux.
  if [ -z "${HERDR_ENV:-}" ] && ! herdr workspace list >/dev/null 2>&1; then
    setsid -f herdr server >/dev/null 2>&1
    local i
    for (( i = 0; i < 50; i++ )); do
      herdr workspace list >/dev/null 2>&1 && break
      sleep 0.1
    done
  fi

  local sel
  sel=$(list_items | fzf \
    --prompt="herdr ⚡ " \
    --height=100% \
    --border=rounded \
    --preview="$0 --preview {}" \
    --preview-window=right:55%) || exit 0
  [ -n "$sel" ] || exit 0
  dispatch "$(strip_star "$sel")"
  [ -n "${HERDR_ENV:-}" ] || exec herdr
}

main "$@"
