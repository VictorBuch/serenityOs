{ pkgs, lib, ... }:
{

  imports = [
    ./stylix.nix
    # ./catppuccin.nix
    ./desktop-environments
    ./audio
  ];

  config = {
    home.stylix.enable = lib.mkDefault true;
    # home.catppuccin.enable = lib.mkDefault true;
  };
}
