args@{
  config,
  pkgs,
  lib,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "nixvim";
  description = "Nixvim-based neovim";
  # Inject the nixvim HM config via sharedModules
  extraConfig = {
    home-manager.sharedModules = [ ./nixvim/config.nix ];
  };
} args
