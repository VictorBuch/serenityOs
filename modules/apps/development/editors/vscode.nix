args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "vscode";
  packages = { pkgs, unstable-pkgs }: [ unstable-pkgs.vscode ];
  description = "Visual Studio Code editor";
} args
