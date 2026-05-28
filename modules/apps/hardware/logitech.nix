args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "logitech";
  category = "hardware";
  description = "Logitech wireless devices (Unifying/Bolt receivers) with Solaar";
  linuxPackages =
    { pkgs, ... }:
    [
      pkgs.solaar
    ];
  linuxExtraConfig = {
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
} args
