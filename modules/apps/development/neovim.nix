args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "neovim";
  category = "development";
  packages = { pkgs, ... }: [ pkgs.neovim ];
  description = "Neovim text editor";
} args
