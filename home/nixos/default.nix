{ pkgs, lib, ... }:
{

  imports = [
    ./stylix.nix
    # ./catppuccin.nix
    ./desktop-environments
    ./audio
    ./zen.nix
  ];

  config = {
    home.stylix.enable = lib.mkDefault true;
    # home.catppuccin.enable = lib.mkDefault true;
    home.zen-browser.enable = lib.mkDefault true;
  };
}
