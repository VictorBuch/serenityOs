{
  pkgs,
  lib,
  config,
  options,
  ...
}:
{

  imports = [
    ./autoupgrade.nix
  ];

  options = {
    maintenance.linux.enable = lib.mkEnableOption "Enables Linux-specific maintenance";
  };

  config = lib.mkIf config.maintenance.linux.enable {
    autoupgrade.enable = lib.mkDefault true;
  };
}
