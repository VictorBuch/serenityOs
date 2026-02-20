{
  pkgs,
  lib,
  config,
  ...
}:

let
  # Focus-or-run script for Raycast-style app launching
  focus-or-run = pkgs.writeShellApplication {
    name = "focus-or-run";
    runtimeInputs = with pkgs; [ jq ];
    text = ''
      if [ $# -lt 2 ]; then
          echo "Usage: focus-or-run <app-id> <command> [args...]" >&2
          exit 1
      fi

      app_id="$1"
      shift

      # Find window info using niri IPC
      window_info=$(niri msg --json windows | jq -r ".[] | select(.app_id == \"$app_id\") | {id: .id, workspace_id: .workspace_id} | @json" | head -n1)

      if [ -n "$window_info" ]; then
          workspace_id=$(echo "$window_info" | jq -r '.workspace_id')
          window_id=$(echo "$window_info" | jq -r '.id')
          
          # Switch to workspace then focus window
          niri msg action focus-workspace "$workspace_id"
          niri msg action focus-window --id "$window_id"
      else
          # Launch app if not running
          exec "$@" &
      fi
    '';
  };
in
{
  options = {
    home.desktop-environments.niri.focus-or-run.enable =
      lib.mkEnableOption "Enable focus-or-run script for Raycast-style app launching";
  };

  config = lib.mkIf config.home.desktop-environments.niri.focus-or-run.enable {
    home.packages = [ focus-or-run ];
  };
}
