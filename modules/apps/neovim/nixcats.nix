args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "nixcats";
  category = "neovim";
  description = "nix-wrapper-modules Neovim (nixCats-style) with custom Lua config from _nixcats/";
  packages = { pkgs, ... }: [ pkgs.nixcatsNeovim ];
} args
