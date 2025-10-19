args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "steam";
  linuxPackages = pkgs: [ ]; # Steam is enabled via programs.steam
  description = "Steam gaming platform (Linux only)";
  linuxExtraConfig = {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports for Steam Local Network Game Transfers
    };
  };
} args
