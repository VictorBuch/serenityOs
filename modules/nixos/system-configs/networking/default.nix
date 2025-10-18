{ pkgs, lib, ... }:
{
  imports = [
    ./wake-on-lan.nix
  ];

  networking.wake-on-lan.enable = lib.mkDefault false;
}
