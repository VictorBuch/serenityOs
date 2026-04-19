{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.homelab.it-tools;
in
{

  options.homelab.it-tools = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the it-tools service.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add it-tools package to environment for Caddy to access
    environment.systemPackages = [ pkgs.it-tools ];
  };
}
