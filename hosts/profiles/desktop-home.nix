# Shared Home Manager sharedModules for Linux desktop machines (jayne, kaylee)
# Sets up catppuccin theming, niri, nixvim, and common CLI tools
#
# Usage: Import this profile and it will add common sharedModules.
# Each host must still define home-manager.users and extraSpecialArgs.
#
# Note: nixvim module is imported by home/cli/neovim/nixvim/default.nix,
# so we just enable it here rather than importing the module again.
{ inputs, ... }:
{
  home-manager.sharedModules = [
    inputs.noctalia.homeModules.default
    inputs.zen-browser.homeModules.default
    {
      home = {
        # catppuccin.enable = true;
        desktop-environments = {
          niri.enable = true;
          noctalia.enable = true;
        };
        cli = {
          enable = true;
          neovim.nixvim.enable = true;
        };
        terminals.enable = true;
      };
    }
  ];
}
