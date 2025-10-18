{ pkgs, lib, ... }:
{

  imports = [
    ./fonts.nix
    ./nh.nix
    ./maintenance
  ];

  fonts.enable = lib.mkDefault true;
  nh.enable = lib.mkDefault true;
}
