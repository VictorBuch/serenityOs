args@{ config, pkgs, lib, mkModule, inputs, ... }:

mkModule {
  name = "zen";
  category = "browsers";
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
