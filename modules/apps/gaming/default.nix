args@{ config, pkgs, lib, isLinux, mkCategory, ... }:

mkCategory {
  _file = toString ./.;
  name = "gaming";
  enableByDefault = {
    ps3 = false;
  };
} args
