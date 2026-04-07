args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "easyeffects";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.easyeffects ];
  description = "EasyEffects audio effects";
} args
