args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "nextcloud";
  packages = { pkgs, ... }: [
    pkgs.nextcloud31
    pkgs.nextcloud-client
  ];
  description = "Nextcloud client";
} args
