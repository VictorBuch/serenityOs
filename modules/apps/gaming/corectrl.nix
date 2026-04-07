args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "corectrl";
  category = "gaming";
  linuxPackages = { pkgs, ... }: [ ]; # CoreCtrl is enabled via programs.corectrl
  description = "CoreCtrl AMD GPU control (Linux only)";
  linuxExtraConfig = {
    programs.corectrl.enable = true;
  };
} args
