args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "corectrl";
  platforms = [ "linux" ];
  category = "gaming";
  packages = { pkgs, ... }: [ ]; # CoreCtrl is enabled via programs.corectrl
  description = "CoreCtrl AMD GPU control (Linux only)";
  extraConfig = {
    programs.corectrl.enable = true;
  };
} args
