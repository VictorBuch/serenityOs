{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
# Homelab-specific maintenance configuration
# Uses the common maintenance module but with different defaults:
# - 10-day GC retention (instead of 30 days)
# - Auto-upgrade enabled by default
# - More aggressive cleanup for server environments
{
  config = lib.mkIf config.maintenance.enable {
    # Override GC options for homelab (more aggressive cleanup)
    nix.gc.options = lib.mkForce "--delete-older-than 10d";

    # Enable auto-upgrade for homelab servers (not default in common)
    autoupgrade.enable = lib.mkDefault true;
  };
}
