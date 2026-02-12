args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "spotify";
  packages = { pkgs, ... }: [ pkgs.spotify ];
  description = "Spotify music streaming";
  linuxExtraConfig = {
    networking.firewall.allowedUDPPorts = [ 5353 ];
  };
} args
