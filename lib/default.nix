{ lib }:

# Custom library functions for serenityOs configuration
# Import in flake.nix and pass to modules via specialArgs

{
  # Module helper for creating app/service modules with enable options
  # Handles cross-platform packages, stable/unstable mixing, and Home Manager injection
  mkModule = import ./mkModule.nix { inherit lib; };
}
