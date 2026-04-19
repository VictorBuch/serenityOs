args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "mangohud";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.mangohud ];
  description = "MangoHud performance overlay";
} args
