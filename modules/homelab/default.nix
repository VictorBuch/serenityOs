{
  pkgs,
  lib,
  config,
  options,
  ...
}:

{

  imports = [
    ../nixos/system-configs/user.nix
    ./configs.nix
    ./services
    ./oci-containers
    ./lab.nix
  ];

  # Enable homelab categories by default (services disabled individually in host config)
  config = {
    apps.homelab = {
      services.enable = lib.mkDefault false;
      oci-containers.enable = lib.mkDefault false;
    };
  };
}
