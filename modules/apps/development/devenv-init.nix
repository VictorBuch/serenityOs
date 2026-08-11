args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

let
  devenv-init = pkgs.writeShellApplication {
    name = "devenv-init";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = builtins.readFile ./devenv-init.sh;
  };
in
mkModule {
  name = "devenv-init";
  category = "development";
  description = "Scaffold a project devenv that imports serenityOs's shared devenv modules";
  packages =
    { pkgs, ... }:
    [
      pkgs.devenv
      pkgs.direnv
      devenv-init
    ];
} args
