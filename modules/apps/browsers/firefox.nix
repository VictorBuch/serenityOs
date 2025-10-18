{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{

  options = {
    apps.browsers.firefox.enable = lib.mkEnableOption "Enables Firefox browser";
  };

  config = lib.mkIf config.apps.browsers.firefox.enable {
    environment.systemPackages = with pkgs; [
      firefox
    ];
  };
}
