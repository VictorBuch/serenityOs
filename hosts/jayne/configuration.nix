# Jayne - Primary desktop workstation (AMD GPU)
# Full workstation with audio production, video editing, gaming, etc.
{
  inputs,
  isLinux,
  mkHomeModule,
  mkHomeCategory,
  ...
}:
let
  username = "jayne";
in
{
  imports = [
    ./hardware-configuration.nix
    ../profiles/desktop.nix
    ../profiles/desktop-home.nix
    inputs.home-manager.nixosModules.default
  ];

  networking.hostName = "jayne";
  networking.wireless.enable = false;

  user.userName = username;

  # Home Manager setup
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        username
        inputs
        isLinux
        mkHomeModule
        mkHomeCategory
        ;
    };
    users.${username} = import ../../home/default.nix;

    # Jayne-specific Home Manager additions (extends desktop-home.nix sharedModules)
    sharedModules = [
      {
        home.audio.yabridge.enable = true;
      }
    ];
  };

  # Jayne-specific boot configuration
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = true;
      };
    };
    # Enable NTFS support for mounting Windows drives
    supportedFilesystems = [ "ntfs" ];
    # Kernel performance optimizations
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
    };
  };

  # AMD GPU
  amd-gpu.enable = true;

  # Desktop environments
  desktop-environments = {
    gnome.enable = true;
    hyprland.enable = false;
    kde.enable = false;
    niri.enable = true;
  };

  # Apps - full workstation
  apps = {
    audio.enable = true;
    browsers = {
      enable = true;
      floorp.enable = false;
    };
    communication.enable = true;
    development.enable = true;
    emacs.enable = false;
    emulation.enable = false;
    gaming.enable = true;
    media = {
      enable = true;
      davinci-resolve.enable = true;
    };
    productivity.enable = true;
    utilities.enable = true;
    work.enable = true;
  };

  nix.settings.trusted-users = [
    "root"
    "jayne"
  ];

  system.stateVersion = "25.05";
}
