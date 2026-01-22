# Common modules shared across all hosts (NixOS and Darwin)
{ lib, ... }:
{
  imports = [
    ./nix-settings.nix
    ./fonts.nix
    ./nh.nix
    ./maintenance.nix
    ../apps # System-wide applications
  ];

  # Enable by default
  fonts.enable = lib.mkDefault true;
  nh.enable = lib.mkDefault true;
}
