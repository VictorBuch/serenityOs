{
  pkgs,
  lib,
  config,
  ...
}:

let
  focus-or-run = pkgs.writeShellApplication {
    name = "mango-focus-or-run";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      # Usage: mango-focus-or-run <appid-regex> <pinned-tag> <command> [args...]
      #
      # New mango IPC (post-2026 rewrite) exposes `mmsg get all-clients` as JSON
      # and `mmsg dispatch client,<id>,focusid` to focus a specific window.
      # Strategy: pull client list, find first matching appid, view its tag and
      # focus by id. If no match, view pinned tag and launch the command.
      if [ $# -lt 3 ]; then
          echo "Usage: mango-focus-or-run <appid-regex> <pinned-tag> <command> [args...]" >&2
          exit 1
      fi

      app_re="$1"
      tag="$2"
      shift 2

      match=$(mmsg get all-clients 2>/dev/null \
          | jq -r --arg re "$app_re" \
              '.clients[]
               | select(.is_minimized == false and .is_scratchpad == false and .is_namedscratchpad == false)
               | select(.appid | test($re; "i"))
               | "\(.id) \(.tags[0])"' \
          | head -n1)

      if [ -n "$match" ]; then
          id=''${match%% *}
          client_tag=''${match##* }
          mmsg dispatch view,"$client_tag" >/dev/null 2>&1 || true
          mmsg dispatch client,"$id",focusid >/dev/null 2>&1 || true
          exit 0
      fi

      # Not running — view pinned tag and launch.
      mmsg dispatch view,"$tag" >/dev/null 2>&1 || true
      setsid "$@" >/dev/null 2>&1 &
    '';
  };
in
{
  options = {
    home.desktop-environments.mango.focus-or-run.enable =
      lib.mkEnableOption "Enable focus-or-run helper for mango";
  };

  config = lib.mkIf config.home.desktop-environments.mango.focus-or-run.enable {
    home.packages = [ focus-or-run ];
  };
}
