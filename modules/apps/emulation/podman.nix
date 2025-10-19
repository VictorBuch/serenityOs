args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "podman";
  linuxPackages = pkgs: [ ]; # Podman enabled via virtualisation.podman
  description = "Podman container engine (Linux only)";
  extraConfig = {
    virtualisation.containers.enable = true;
    virtualisation.podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
} args
