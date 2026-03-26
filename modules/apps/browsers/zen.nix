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
  homeConfig =
    {
      config,
      lib,
      ...
    }:
    {
      programs.zen-browser = {
        enable = true;
        profiles.${config.home.username} = {
          # Default profile using the username
        };
      };
    };
} args
