{ pkgs, lib, ... }:
{

  imports = [
    ./stylix.nix
    ./catppuccin.nix
    ./desktop-environments
  ];

  config = {
    home.stylix.enable = lib.mkDefault false;
    home.catppuccin.enable = lib.mkDefault true;
  };
}
