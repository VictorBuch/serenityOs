args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "minecraft";
  packages = pkgs: [
    pkgs.zulu17
    pkgs.prismlauncher
  ];
  description = "Minecraft with PrismLauncher";
} args
