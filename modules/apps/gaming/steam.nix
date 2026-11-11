{
  flake.modules.nixos.steam =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server
        localNetworkGameTransfers.openFirewall = true; # Open ports for Steam Local Network Game Transfers
        extraCompatPackages = [
          pkgs.proton-ge-bin
        ];
      };
    };
}
