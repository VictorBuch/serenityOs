args@{ config, pkgs, lib, isLinux, mkCategory, ... }:

mkCategory {
  _file = toString ./.;
  name = "neovim";
  enableByDefault = {
    nixvim = false;
    nvf = false;
  };
} args
