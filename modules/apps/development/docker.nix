args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "docker";
  category = "development";
  linuxPackages =
    { pkgs, ... }:
    [
      pkgs.docker
      pkgs.docker-compose
    ];
  description = "Docker containerization platform (Linux only)";
  linuxExtraConfig = {
    virtualisation.docker.enable = true;
    users.users.${config.user.userName}.extraGroups = [ "docker" ];
  };
} args
