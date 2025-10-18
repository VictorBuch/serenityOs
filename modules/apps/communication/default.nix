{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./discord.nix
    ./slack.nix
    ./zoom.nix
  ];

  options = {
    apps.communication.enable = lib.mkEnableOption "Enables all communication apps";
  };

  config = lib.mkIf config.apps.communication.enable {
    apps.communication.discord.enable = lib.mkDefault true;
    apps.communication.slack.enable = lib.mkDefault true;
    apps.communication.zoom.enable = lib.mkDefault true;
  };
}
