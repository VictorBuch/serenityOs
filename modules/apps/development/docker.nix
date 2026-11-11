{
  flake.modules.nixos.docker =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.docker
        pkgs.docker-compose
      ];
      virtualisation.docker.enable = true;
      users.users.${config.user.userName}.extraGroups = [ "docker" ];
    };
}
