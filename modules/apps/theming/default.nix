args@{ config, pkgs, lib, isLinux, mkCategory, ... }:

mkCategory {
  _file = toString ./.;
  name = "theming";
  enableByDefault = {
    stylix = false;
    catppuccin = false;
  };
} args
