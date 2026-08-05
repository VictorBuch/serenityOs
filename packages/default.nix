{ pkgs }:
{
  pam = pkgs.callPackage ./pam { };
  lute-v3 = pkgs.callPackage ./lute-v3 { };

  # Exposed so the risky wine-11 yabridge can be iterated on standalone:
  #   nix build .#yabridge-wine10
  # It reaches NixOS configs through overlays/default.nix, not through here.
  yabridge-wine10 = pkgs.yabridge-wine10;
  yabridgectl-wine10 = pkgs.yabridgectl-wine10;
}
