{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.it-tools;
in
{

  options.it-tools = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the it-tools service.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add it-tools package to environment for Caddy to access
    environment.systemPackages = [ pkgs.unstable.it-tools ];
  };
}
