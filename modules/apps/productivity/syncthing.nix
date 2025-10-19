args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "syncthing";
  linuxPackages = pkgs: [
    pkgs.syncthing
    pkgs.gnomeExtensions.syncthing-toggle
  ];
  description = "Syncthing file synchronization (Linux only)";
  extraConfig = {
    services.syncthing = {
      enable = true;
      dataDir = "/home/${config.user.userName}"; # default location for new folders
      configDir = "/home/${config.user.userName}/.config/syncthing";
      user = "${config.user.userName}";
      group = "users";
      openDefaultPorts = true;
    };
  };
} args
