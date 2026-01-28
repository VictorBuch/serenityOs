# Centralized Nix settings for all hosts
# Includes binary caches for faster builds
{ ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Binary caches
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixvim.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixvim.cachix.org-1:8xrm/43sWNaE3sqFYil49+3wO5LqCbS4FHGhMCuPNNA="
    ];
  };
}
