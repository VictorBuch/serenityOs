args@{
  config,
  pkgs,
  lib,
  mkHomeCategory,
  ...
}:

mkHomeCategory {
  _file = toString ./.;
  name = "neovim";
  enableByDefault = {
    nixvim = false;
    nvf = false;
  };
} args
