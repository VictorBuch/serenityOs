# Shared NixOS configuration for Linux desktop machines (jayne, kaylee)
# Contains common settings for locale, audio, bluetooth, etc.
{ lib, pkgs, ... }:
{
  # Danish locale settings
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

  # Force Electron apps to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Better memory management
  zramSwap.enable = true;

  # Audio (Pipewire)
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Common services
  services.printing.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Networking
  networking.networkmanager.enable = true;

  # Shell
  programs.zsh.enable = true;

  # Binary compatibility for unpackaged programs
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libz
  ];

  # Maintenance
  maintenance = {
    enable = true;
    linux.enable = true;
  };

  # Theming
  catppuccin.enable = true;
}
