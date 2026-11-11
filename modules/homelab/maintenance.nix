{
  flake.modules.nixos.homelab =
    { lib, ... }:
    # Homelab-specific maintenance configuration
    # Uses the common maintenance module but with different defaults:
    # - 10-day GC retention (instead of 30 days)
    # - Auto-upgrade enabled by default
    # - More aggressive cleanup for server environments
    {
      nix.gc.options = lib.mkForce "--delete-older-than 10d";
      autoupgrade.enable = lib.mkDefault true;
    };
}
