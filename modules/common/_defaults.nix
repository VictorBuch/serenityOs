# Default enable values for common modules
# The _ prefix means import-tree ignores this file (imported explicitly in flake.nix)
{ lib, ... }:
{
  fonts.enable = lib.mkDefault true;
  nh.enable = lib.mkDefault true;
  yubikey.enable = lib.mkDefault true;
}
