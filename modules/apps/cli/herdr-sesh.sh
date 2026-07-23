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
TILDE='~'  # kept in a var so shellcheck doesn't mistake it for an expansion

die() { printf 'herdr-sesh: %s\n' "$*" >&2; exit 1; }

# Strip the leading star marker a configured space carries in the picker list.
strip_star() { printf '%s' "${1#"$STAR"}"; }

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

# Build a configured space from scratch: workspace -> tabs -> panes -> commands.
build_space() {
  local name="$1" space
  space=$(get_space "$name")
  [ -n "$space" ] || die "unknown space: $name"

  local path
  path=$(expand_tilde "$(jq -r '.path // "~"' <<<"$space")")

  # Creating a workspace also creates its first tab and root pane.
  local created ws first_tab first_pane
  created=$(herdr workspace create --cwd "$path" --label "$name" --focus)
  ws=$(jq -r '.result.workspace.workspace_id' <<<"$created")
  first_tab=$(jq -r '.result.tab.tab_id' <<<"$created")
  first_pane=$(jq -r '.result.root_pane.pane_id' <<<"$created")

  # A space is a list of tabs. If none given, synthesize one from a top-level
  # `command` (single-shot spaces like an ssh session), else a bare shell.
  local tabs ntabs
  tabs=$(jq -c '.tabs // (if .command then [{panes:[{command:.command}]}] else [{}] end)' <<<"$space")
  ntabs=$(jq 'length' <<<"$tabs")

  local ti
  for (( ti = 0; ti < ntabs; ti++ )); do
    local tab tabname tabcwd tab_id root_pane
    tab=$(jq -c ".[$ti]" <<<"$tabs")
    tabname=$(jq -r '.name // empty' <<<"$tab")
    tabcwd=$(jq -r '.path // empty' <<<"$tab")
    if [ -n "$tabcwd" ]; then tabcwd=$(expand_tilde "$tabcwd"); else tabcwd="$path"; fi

    if [ "$ti" -eq 0 ]; then
      # Reuse the workspace's first tab/pane.
      tab_id="$first_tab"
      root_pane="$first_pane"
      [ -n "$tabname" ] && herdr tab rename "$tab_id" "$tabname" >/dev/null
    else
      local tcreated
      if [ -n "$tabname" ]; then
        tcreated=$(herdr tab create --workspace "$ws" --cwd "$tabcwd" --label "$tabname" --no-focus)
      else
        tcreated=$(herdr tab create --workspace "$ws" --cwd "$tabcwd" --no-focus)
      fi
      root_pane=$(jq -r '.result.root_pane.pane_id' <<<"$tcreated")
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
      if [ "$pj" -eq 0 ]; then
        target="$root_pane"
      else
        local dir ratio scmd
        dir=$(jq -r '.direction // "right"' <<<"$pane")
        ratio=$(jq -r '.ratio // empty' <<<"$pane")
        if [ -n "$ratio" ]; then
          scmd=$(herdr pane split "$prev" --direction "$dir" --ratio "$ratio" --no-focus)
        else
          scmd=$(herdr pane split "$prev" --direction "$dir" --no-focus)
        fi
        target=$(jq -r '.result.pane.pane_id' <<<"$scmd")
      fi
      cmd=$(jq -r '.command // empty' <<<"$pane")
      if [ -n "$cmd" ]; then
        # Give the freshly spawned shell a moment before typing into it.
        sleep 0.15
        herdr pane run "$target" "$cmd" >/dev/null 2>&1 || true
      fi
      prev="$target"
    done
  done

  herdr workspace focus "$ws" >/dev/null 2>&1 || true
}

# Focus the workspace with this label if one exists. 0 = focused, 1 = none.
focus_existing() {
  local name="$1" existing
  existing=$(herdr workspace list 2>/dev/null \
    | jq -r --arg n "$name" 'first(.result.workspaces[] | select(.label == $n) | .workspace_id) // empty')
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
  herdr workspace create --cwd "$dir" --label "$name" --focus >/dev/null
}

# Route a picked item: a configured space, otherwise a directory path.
dispatch() {
  local item="$1"
  if [ -n "$(get_space "$item")" ]; then
    focus_existing "$item" && return 0
    build_space "$item"
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
  esac

  local sel
  sel=$(list_items | fzf \
    --prompt="herdr ⚡ " \
    --height=100% \
    --border=rounded \
    --preview="$0 --preview {}" \
    --preview-window=right:55%) || exit 0
  [ -n "$sel" ] || exit 0
  dispatch "$(strip_star "$sel")"
}

main "$@"
