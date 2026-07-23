#!/usr/bin/env bash
# herdr-sesh — a sesh-style space picker for the herdr multiplexer.
#
# `herdr-sesh` (no args) shows an fzf list of predefined "spaces". Selecting one
# either focuses the matching workspace if it already exists, or builds it from
# scratch: a named workspace with named tabs, split panes, and startup commands
# already running — the herdr equivalent of `sesh connect`.
#
# Spaces are read from $HERDR_SESH_CONFIG (default: ~/.config/herdr/sesh-spaces.json),
# which is generated declaratively by the Nix module.
set -euo pipefail

CONFIG="${HERDR_SESH_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/sesh-spaces.json}"

die() { printf 'herdr-sesh: %s\n' "$*" >&2; exit 1; }

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

# Extract a single space object by name.
get_space() {
  jq -c --arg n "$1" '.spaces[] | select(.name == $n)' "$CONFIG"
}

# Build a space from scratch: workspace -> tabs -> panes -> startup commands.
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

# Focus an existing workspace with this label, else build it.
connect() {
  local name="$1" existing
  existing=$(herdr workspace list 2>/dev/null \
    | jq -r --arg n "$name" 'first(.result.workspaces[] | select(.label == $n) | .workspace_id) // empty')
  if [ -n "$existing" ]; then
    herdr workspace focus "$existing" >/dev/null 2>&1 || true
    return 0
  fi
  build_space "$name"
}

# fzf preview: run the space's optional preview command, then a layout summary.
preview() {
  local space pcmd
  space=$(get_space "$1")
  [ -n "$space" ] || return 0
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
}

main() {
  [ -f "$CONFIG" ] || die "no config at $CONFIG"
  case "${1:-}" in
    --preview) preview "${2:-}"; exit 0 ;;
    connect)   connect "${2:?usage: herdr-sesh connect <name>}"; exit 0 ;;
  esac

  local sel
  sel=$(jq -r '.spaces[].name' "$CONFIG" | fzf \
    --prompt="herdr ⚡ " \
    --height=100% \
    --border=rounded \
    --preview="$0 --preview {}" \
    --preview-window=right:55%) || exit 0
  [ -n "$sel" ] || exit 0
  connect "$sel"
}

main "$@"
