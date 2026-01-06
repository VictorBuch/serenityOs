args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "docker";
  linuxPackages = pkgs: [
    pkgs.docker
    pkgs.docker-compose
  ];
  description = "Docker containerization platform (Linux only)";
  linuxExtraConfig = {
    virtualisation.docker.enable = true;
    users.users.${config.user.userName}.extraGroups = [ "docker" ];
  };
} args
