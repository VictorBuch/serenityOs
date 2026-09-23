# Kaylee - Laptop (NVIDIA GPU)
# Lighter setup - no audio production, video editing, or gaming
{
  inputs,
  pkgs-stable,
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
  ];

  networking.hostName = "kaylee";

  user.userName = username;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # NVIDIA GPU
  nvidia.enable = true;

  # Desktop environments
  desktop = {
    compositor.niri.enable = true;
    session = {
      fileManager = "nautilus";
      outputs = [
        {
          name = "DP-1";
          width = 2560;
          height = 1440;
          refresh = 119.998;
        }
      ];
      autostartApps = [
        "zen"
        "ghostty"
        "slack"
        "discord"
      ];
    };
    environment.gnome.enable = true;
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
