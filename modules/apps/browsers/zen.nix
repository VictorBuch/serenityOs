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
  name = "zen";
  packages =
    { pkgs, ... }: [ inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  description = "Zen browser";
} args
