{
  config,
  pkgs,
  lib,
  ...
}:
let
  run-or-raise = pkgs.writeShellApplication {
    name = "run-or-raise";
    runtimeInputs = with pkgs; [
      kdotool
      util-linux
    ];
    text = ''
      if [ $# -lt 2 ]; then
          echo "Usage: run-or-raise <class-regex> <command> [args...]" >&2
          exit 1
      fi

      class="$1"
      shift

      mapfile -t ids < <(kdotool search --class --classname "$class")

      if [ -z "''${ids[0]:-}" ]; then
          setsid "$@" >/dev/null 2>&1 &
          exit 0
      fi

      active=$(kdotool getactivewindow 2>/dev/null || true)
      next="''${ids[0]}"
      for i in "''${!ids[@]}"; do
          if [ "''${ids[$i]}" = "$active" ]; then
              next="''${ids[$(( (i + 1) % ''${#ids[@]} ))]}"
              break
          fi
      done

      kdotool windowactivate "$next"
    '';
  };
in
{

  options = {
    desktop.environment.kde.enable = lib.mkEnableOption "the KDE Plasma Desktop Environment";
  };

  config = lib.mkIf config.desktop.environment.kde.enable {
    desktop.loginManager.sddm.enable = true;

    services = { 
      xserver.enable = true; # optional
      displayManager.sddm.enable = true;
      displayManager.sddm.wayland.enable = true;
      desktopManager.plasma6.enable = true;
      displayManager.sddm.settings.General.DisplayServer = "wayland";
      displayManager.defaultSession = lib.mkForce "plasma";
    };

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      konsole
      oxygen
    ];

    environment.systemPackages = [
      run-or-raise
      pkgs.kdotool
    ];
  };
}
