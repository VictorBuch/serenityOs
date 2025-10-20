args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "linux";
  linuxPackages = pkgs: [ ]; # Emacs daemon enabled via services.emacs
  description = "Emacs daemon service (Linux only)";
  linuxExtraConfig = {
    services.emacs.enable = true;
  };
} args
