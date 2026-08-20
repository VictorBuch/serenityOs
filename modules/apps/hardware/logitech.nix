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
  linuxExtraConfig = {
    programs.solaar.enable = true;
  };
} args
