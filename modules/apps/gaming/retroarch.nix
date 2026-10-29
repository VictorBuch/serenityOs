args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "retroarch";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.retroarch-full ];
  description = "Emulator";
} args
