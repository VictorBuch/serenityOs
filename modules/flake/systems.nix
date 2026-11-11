{ inputs, ... }:
let
  overlay = import ../../overlays { inherit inputs; };
in
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  flake.overlays.default = overlay;

  perSystem =
    { system, pkgs, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowBroken = true;
          android_sdk.accept_license = true;
        };
        overlays = [ overlay ];
      };

      _module.args.pkgs-stable = import inputs.nixpkgs-stable {
        inherit system;
        config = {
          allowUnfree = true;
          allowBroken = true;
        };
      };

      packages = import ../../packages { inherit pkgs; };
    };
}
