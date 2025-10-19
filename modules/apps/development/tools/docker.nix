args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "docker";
  linuxPackages = pkgs: [
    pkgs.docker
    pkgs.docker-compose
  ];
  description = "Docker containerization platform (Linux only)";
  extraConfig = {
    virtualisation.docker.enable = true;
  };
} args
