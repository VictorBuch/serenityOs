{ lib }:

# Custom library functions for serenityOs configuration
# Import in flake.nix and pass to modules via specialArgs

{
  # Universal app module helper
  # Handles cross-platform, platform-specific, and stable/unstable packages
  mkApp = import ./mkApp.nix { inherit lib; };

  # Category helper for auto-discovering and enabling app modules
  # Auto-imports all .nix files in directory and handles platform compatibility
  mkCategory = import ./mkCategory.nix { inherit lib; };

  # Additional helpers can be added here as needed
  # mkService = import ./mkService.nix { inherit lib; };
  # mkHost = import ./mkHost.nix { inherit lib; };
}
