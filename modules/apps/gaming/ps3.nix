{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.ps3.enable = lib.mkEnableOption "Enables RPCS3 PS3 emulator";
  };

  config = lib.mkIf config.apps.gaming.ps3.enable {

    environment.systemPackages = with pkgs; [
      rpcs3
    ];

  };
}
