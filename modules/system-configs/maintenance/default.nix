{
  pkgs,
  lib,
  config,
  options,
  ...
}:
{

  imports = [
    ./gc.nix
  ];

  options = {
    maintenance.enable = lib.mkEnableOption "Enables all maintenance";
  };

  config = lib.mkIf config.maintenance.enable {
    gc.enable = lib.mkDefault true;
  };
}
