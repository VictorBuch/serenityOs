# Reusable base profile for shepherd-derived NixOS hosts.
#
# Provides: bootloader, networking, locale/timezone, base apps (cli,
# neovim, zen, niri), home-manager scaffolding, maintenance.
#
# Hosts importing this profile must set:
#   - networking.hostName
#   - user.userName
#   - home-manager.users.<name>
#   - hardware-configuration.nix import
#   - disko layout import (hosts/profiles/disko-btrfs.nix { device = ...; })
#   - system.stateVersion
{
  config,
  pkgs,
  inputs,
  pkgs-stable,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_DK.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };
  console.keyMap = "dk-latin1";

  programs.zsh.enable = true;
  maintenance.enable = true;

  apps = {
    cli.enable = true;
    neovim.nixvim.enable = true;
    theming.stylix.enable = true;
    browsers = {
      enable = true;
      zen.enable = true;
    };
  };

  desktop-environments = {
    gnome.enable = false;
    hyprland.enable = false;
    kde.enable = false;
    niri.enable = true;
  };

  hardware.graphics.enable = true;
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
  };

  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit inputs pkgs-stable;
    };
    sharedModules = [
      inputs.noctalia.homeModules.default
      inputs.zen-browser.homeModules.default
    ];
  };
}
