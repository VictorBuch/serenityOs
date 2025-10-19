args@{ config, pkgs, lib, isLinux, mkCategory, ... }:

mkCategory {
  _file = toString ./.;
  name = "productivity";
  enableByDefault = {
    language-learning = false;
  };
} args
