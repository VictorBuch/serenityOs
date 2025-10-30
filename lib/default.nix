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

  # Home Manager module helper
  # Wraps Home Manager modules with automatic enable options and minimal boilerplate
  mkHomeModule = import ./mkHomeModule.nix { inherit lib; };

  # Home Manager category helper for auto-discovering modules
  # Auto-imports all .nix files in directory and creates category-level enable options
  mkHomeCategory = import ./mkHomeCategory.nix { inherit lib; };

  # Additional helpers can be added here as needed
  # mkService = import ./mkService.nix { inherit lib; };
  # mkHost = import ./mkHost.nix { inherit lib; };
}
