args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "nixvim";
  category = "neovim";
  description = "Nixvim-based neovim";
  # Inject the nixvim HM config via sharedModules
  extraConfig = {
    home-manager.sharedModules = [ ./_nixvim/config.nix ];
  };
} args
