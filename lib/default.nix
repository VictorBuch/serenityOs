{ lib }:

# Custom library functions for serenityOs configuration
# Import in flake.nix and pass to modules via specialArgs

{
  # Wrappers that make an override warn once its reason to exist is gone
  expiring = import ./expiring.nix { inherit lib; };
}
