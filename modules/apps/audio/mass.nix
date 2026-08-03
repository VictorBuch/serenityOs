args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "mass";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.music-assistant-desktop ];
  description = "Music assistant desktop app";
} args
