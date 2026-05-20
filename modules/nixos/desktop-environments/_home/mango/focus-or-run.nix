{
  pkgs,
  lib,
  config,
  ...
}:

let
  focus-or-run = pkgs.writeShellApplication {
    name = "mango-focus-or-run";
    runtimeInputs = with pkgs; [ jq ];
    text = ''
      if [ $# -lt 2 ]; then
          echo "Usage: mango-focus-or-run <app-id-regex> <command> [args...]" >&2
          exit 1
      fi

      app_id="$1"
      shift

      # mango exposes tag state via mmsg -g -t; window-by-appid lookup needs the
      # focused-client query repeated per monitor/tag — easier: just dispatch
      # `view` to scan tags. As a pragmatic implementation: ask `mmsg -g -c` on
      # each tag for current monitor. If no IPC match, launch the app.
      found=0
      for tag in 1 2 3 4 5 6 7 8 9; do
        client_info=$(mmsg -t "$tag" -g -c 2>/dev/null || true)
        if echo "$client_info" | grep -qiE "$app_id"; then
          mmsg -s -t "$tag"
          found=1
          break
        fi
      done

      if [ "$found" -eq 0 ]; then
          setsid "$@" >/dev/null 2>&1 &
      fi
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
