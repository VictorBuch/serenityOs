args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "docker";
  platforms = [ "linux" ];
  category = "development";
  packages =
    { pkgs, ... }:
    [
      pkgs.docker
      pkgs.docker-compose
    ];
  description = "Docker containerization platform (Linux only)";
  extraConfig = {
    virtualisation.docker.enable = true;
    users.users.${config.user.userName}.extraGroups = [ "docker" ];
  };
} args
