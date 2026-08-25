args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "logitech";
  platforms = [ "linux" ];
  category = "hardware";
  description = "Logitech wireless devices (Unifying/Bolt receivers) with Solaar";
  extraConfig = {
    programs.solaar.enable = true;
  };
} args
