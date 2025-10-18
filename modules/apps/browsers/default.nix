{ lib, config, ... }:
{

  imports = [
    ./firefox.nix
    ./zen.nix
    ./floorp.nix
  ];

  options = {
    apps.browsers.enable = lib.mkEnableOption "Enables all browsers";
  };

  config = lib.mkIf config.apps.browsers.enable {
    apps.browsers.firefox.enable = lib.mkDefault true;
    apps.browsers.floorp.enable = lib.mkDefault true;
    apps.browsers.zen.enable = lib.mkDefault true;
  };
}
