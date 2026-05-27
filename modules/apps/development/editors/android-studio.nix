args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "android-studio";
  category = "development";
  description = "android studio";
  linuxPackages = { pkgs, ... }: [ pkgs.androidStudioPackages.canary ];
  casks = [ "android-studio" ];
} args
