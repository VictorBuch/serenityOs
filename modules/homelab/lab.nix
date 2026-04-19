{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

{

  options.homelab.lab = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.homelab.lab.enable {

  };

}
