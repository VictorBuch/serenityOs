args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "handbrake";
  category = "media";
  packages = { pkgs, ... }: [ pkgs.handbrake ];
  description = "HandBrake video transcoder";
} args
