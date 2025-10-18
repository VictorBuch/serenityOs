{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.communication.discord.enable = lib.mkEnableOption "Enables Discord";
  };

  config = lib.mkIf config.apps.communication.discord.enable {
    environment.systemPackages = with pkgs; [
      discord
    ];
  };
}
