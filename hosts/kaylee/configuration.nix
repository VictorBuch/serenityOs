# Kaylee - Laptop (NVIDIA GPU)
# Lighter setup - no audio production, video editing, or gaming
{
  inputs,
  isLinux,
  pkgs-stable,
  mkHomeModule,
  mkHomeCategory,
  ...
}:
let
  username = "kaylee";
in
{
  imports = [
    ./hardware-configuration.nix
    ../profiles/desktop.nix
    ../profiles/desktop-home.nix
    inputs.home-manager.nixosModules.default
  ];

  networking.hostName = "kaylee";

  user.userName = username;

  # Home Manager setup
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        username
        inputs
        isLinux
        pkgs-stable
        mkHomeModule
        mkHomeCategory
        ;
    };
    users.${username} = import ../../home/default.nix;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # NVIDIA GPU
  nvidia.enable = true;

  # Desktop environments
  desktop-environments = {
    gnome.enable = true;
    hyprland.enable = false;
    kde.enable = false;
    niri.enable = true;
  };

  # Apps - lighter setup for laptop
  apps = {
    audio.enable = true;
    browsers.zen.enable = true;
    communication.enable = true;
    development.enable = true;
    utilities.enable = true;
  };

  system.stateVersion = "24.05";
}
