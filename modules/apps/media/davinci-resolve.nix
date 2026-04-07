args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "davinci-resolve";
  category = "media";
  packages = { pkgs, ... }: [ pkgs.davinci-resolve ];
  description = "DaVinci Resolve video editor";
} args
