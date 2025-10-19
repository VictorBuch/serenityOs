{ pkgs, lib, ... }:
{

  # Import cross-platform modules from parent
  imports = [
    ../common.nix
    ./system-configs
    ./desktop-environments
  ];
}
