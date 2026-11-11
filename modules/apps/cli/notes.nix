let
  scripts = pkgs: rec {
    # All scripts honour $NOTES_VAULT so the location is overridable per host.
    vaultPreamble = ''
      set -euo pipefail
      VAULT="''${NOTES_VAULT:-$HOME/notes}"
      DAILY_DIR="$VAULT/daily"

      ensure_daily() {
        mkdir -p "$DAILY_DIR"
        local today file
        today="$(date +%F)"
        file="$DAILY_DIR/$today.md"
        [ -f "$file" ] || printf '# %s\n\n' "$today" > "$file"
        printf '%s\n' "$file"
      }
    '';

    # notes-capture — the ADHD-critical path. rofi is called from PATH so it uses
    # the same (wayland) rofi as every other mango bind. Escape = capture nothing.
    notes-capture = pkgs.writeShellScriptBin "notes-capture" ''
      ${vaultPreamble}

      file="$(ensure_daily)"

      if ! text="$(rofi -dmenu -l 0 -p 'capture' \
          -theme-str 'entry { placeholder: "what'"'"'s on your mind?"; }' </dev/null)"; then
        exit 0
      fi

      # Trim surrounding whitespace; bail on an empty capture.
      text="$(printf '%s' "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      [ -z "$text" ] && exit 0

      printf -- '- %s %s\n' "$(date +%H:%M)" "$text" >> "$file"
      notify-send -a notes -t 1500 'captured' "$text" 2>/dev/null || true
    '';

    # nf — content search. rg feeds fzf; selection opens at file:line.
    nf = pkgs.writeShellScriptBin "nf" ''
      ${vaultPreamble}
      cd "$VAULT"

      query="''${*:-}"
      sel="$(rg --line-number --no-heading --color=always --smart-case -- "''${query:-.}" . \
        | fzf --ansi --delimiter : --nth '3..' \
              --preview 'rg --pretty --context 3 --color=always "" {1} | head -300' \
              --preview-window 'right,55%,border-left')" || exit 0
      [ -z "$sel" ] && exit 0

      f="''${sel%%:*}"
      rest="''${sel#*:}"
      ln="''${rest%%:*}"
      # cwd is already $VAULT, so open the rg-relative path directly.
      exec "''${EDITOR:-nvim}" "+$ln" "$f"
    '';

    # nn — new (or existing) note. Title is the filename and the search key;
    # spaces are kept as-is. No other metadata required.
    nn = pkgs.writeShellScriptBin "nn" ''
      ${vaultPreamble}

      title="''${*:-}"
      if [ -z "$title" ]; then
        echo "usage: nn <title>" >&2
        exit 1
      fi

      file="$VAULT/$title.md"
      mkdir -p "$(dirname "$file")"
      [ -f "$file" ] || printf '# %s\n\n' "$title" > "$file"
      exec "''${EDITOR:-nvim}" "$file"
    '';

    # nd — jump straight to today's daily note.
    nd = pkgs.writeShellScriptBin "nd" ''
      ${vaultPreamble}
      file="$(ensure_daily)"
      exec "''${EDITOR:-nvim}" "$file"
    '';

    # notes-init — one-time, idempotent scaffold. Never overwrites existing files.
    notes-init = pkgs.writeShellScriptBin "notes-init" ''
          ${vaultPreamble}

          mkdir -p "$DAILY_DIR"

          if [ ! -f "$VAULT/homelab.md" ]; then
            cat > "$VAULT/homelab.md" <<'EOF'
      # homelab

      Hub note — one heading per service, links out to detail notes.
      This is a big-file-with-headings note on purpose; do not atomise it.

      ## mal
      ## caddy
      ## syncthing
      EOF
          fi

          # Never sync editor scratch / syncthing internals / the mal git history.
          if [ ! -f "$VAULT/.stignore" ]; then
            cat > "$VAULT/.stignore" <<'EOF'
      .obsidian/workspace*
      .stversions
      .git
      EOF
          fi

          if [ ! -f "$VAULT/.gitignore" ]; then
            cat > "$VAULT/.gitignore" <<'EOF'
      .obsidian/workspace*
      .stversions/
      .stfolder/
      EOF
          fi

          ensure_daily > /dev/null
          printf 'vault ready at %s\n' "$VAULT"
    '';
  };
  common =
    pkgs: with scripts pkgs; [
      nf
      nn
      nd
      notes-init
      pkgs.ripgrep
      pkgs.fzf
    ];
in
{
  flake.modules.nixos.notes =
    { pkgs, ... }:
    {
      environment.systemPackages = common pkgs ++ [
        (scripts pkgs).notes-capture
        pkgs.libnotify
      ];
    };
  flake.modules.darwin.notes =
    { pkgs, ... }:
    {
      environment.systemPackages = common pkgs;
    };
}
