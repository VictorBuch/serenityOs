{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.utilities.system-tools.enable = lib.mkEnableOption "Enables system utility tools";
  };

  config = lib.mkIf config.apps.utilities.system-tools.enable {
    environment.systemPackages = with pkgs; [
      gcc
      btop
      filezilla
      chromium
      bottles
    ];
  };
}
