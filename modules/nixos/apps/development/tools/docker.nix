{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.development.tools.docker.enable = lib.mkEnableOption "Enables Docker";
  };

  config = lib.mkIf config.apps.development.tools.docker.enable {
    virtualisation.docker.enable = true;

    environment.systemPackages = with pkgs; [
      docker
      docker-compose
    ];
  };
}
