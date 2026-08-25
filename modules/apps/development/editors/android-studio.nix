args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "android-studio";
  category = "development";
  description = "android studio";
  packages =
    { pkgs, lib, platform, ... }:
    lib.optionals (platform == "linux") [ pkgs.androidStudioPackages.canary ];
  casks = [ "android-studio" ];
} args
