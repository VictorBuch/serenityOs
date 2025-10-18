{ pkgs, lib, ... }:
{

  # Import cross-platform modules from parent
  imports = [
    ../common.nix
    ./apps
    ./system-configs
    ./desktop-environments
  ];
}
