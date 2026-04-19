args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "vscode";
  category = "development";
  packages = { pkgs, ... }: [ pkgs.vscode ];
  description = "Visual Studio Code editor";
} args
