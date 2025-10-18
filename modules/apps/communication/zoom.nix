{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.communication.zoom.enable = lib.mkEnableOption "Enables Zoom";
  };

  config = lib.mkIf config.apps.communication.zoom.enable {
    environment.systemPackages = with pkgs; [
      zoom-us
    ];
  };
}
