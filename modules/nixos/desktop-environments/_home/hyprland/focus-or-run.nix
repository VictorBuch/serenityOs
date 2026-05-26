{
  pkgs,
  lib,
  config,
  ...
}:

let
  focus-or-run = pkgs.writeShellApplication {
    name = "focus-or-run-hypr";
    runtimeInputs = with pkgs; [
      hyprland
      jq
    ];
    text = ''
      if [ $# -lt 2 ]; then
          echo "Usage: focus-or-run <class> <command> [args...]" >&2
          exit 1
      fi

      class="$1"
      shift

      # Match against both class and initialClass (xwayland apps sometimes differ)
      if hyprctl clients -j \
          | jq -e --arg c "$class" 'any(.[]; (.class // "") == $c or (.initialClass // "") == $c)' >/dev/null; then
          hyprctl dispatch focuswindow "class:^($class)$"
      else
          setsid "$@" >/dev/null 2>&1 &
      fi
    '';
  };
in
{
  options = {
    home.desktop-environments.hyprland.focus-or-run.enable =
      lib.mkEnableOption "Enable focus-or-run script for Raycast-style app launching";
  };

  config = lib.mkIf config.home.desktop-environments.hyprland.focus-or-run.enable {
    home.packages = [ focus-or-run ];
  };
}
