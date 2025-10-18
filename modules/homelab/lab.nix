{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{

  options.lab = {
    enable = mkOption {
      type = types bool;
      default = false;
    };
  };

  config = mkIf config.lab.enable {

  };

}
