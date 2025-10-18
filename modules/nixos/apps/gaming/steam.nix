{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.steam.enable = lib.mkEnableOption "Enables Steam";
  };

  config = lib.mkIf config.apps.gaming.steam.enable {

    # Enable steam
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
  };
}
