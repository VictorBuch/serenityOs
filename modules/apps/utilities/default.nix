{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./system-tools.nix
    ./web-apps.nix
    ./ffmpeg.nix
  ];

  options = {
    apps.utilities.enable = lib.mkEnableOption "Enables all utility apps";
  };

  config = lib.mkIf config.apps.utilities.enable {
    apps.utilities.system-tools.enable = lib.mkDefault true;
    apps.utilities.web-apps.enable = lib.mkDefault true;
    apps.utilities.ffmpeg.enable = lib.mkDefault true;
  };
}
