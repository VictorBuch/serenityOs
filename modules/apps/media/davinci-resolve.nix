{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.media.davinci-resolve.enable = lib.mkEnableOption "Enables DaVinci Resolve";
  };

  config = lib.mkIf config.apps.media.davinci-resolve.enable {
    environment.systemPackages = with pkgs; [
      davinci-resolve
    ];
  };
}
