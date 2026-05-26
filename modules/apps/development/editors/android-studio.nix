args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "android-studio";
  category = "development";
  linuxPackages = {pkgs, ...}: [pkgs.android-studio];
  description = "android studio";
} args
