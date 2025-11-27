args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "neovim";
  packages = { pkgs, unstable-pkgs }: [ unstable-pkgs.neovim ];
  description = "Neovim text editor";
} args
