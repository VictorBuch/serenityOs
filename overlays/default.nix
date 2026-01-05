{
  inputs,
  ...
}: final: prev: {
  # Add unstable packages as pkgs.unstable (for stable-based hosts)
  unstable = import inputs.unstable-nixpkgs {
    inherit (final) system;
    config = {
      allowUnfree = true;
      allowBroken = true;
    };
  };

  # Add the pam package (renamed to avoid conflict with linux-pam)
  # Use unstable buildGoModule if available, otherwise use current pkgs
  pam-cli = final.callPackage ../packages/pam {
    buildGoModule = (final.unstable or final).buildGoModule;
  };

  # Wine 9.20 pinned for audio/yabridge compatibility
  # Wine 9.22+ has GUI issues with yabridge: https://github.com/robbert-vdh/yabridge/issues/382
  # Uses the nixpkgs-wine920 flake input with stagingFull for maximum Windows compatibility
  wine921 = let
    wine920Pkgs = import inputs.nixpkgs-wine920 {
      inherit (final) system;
      config = {
        allowUnfree = true;
      };
    };
  in wine920Pkgs.wineWowPackages.stagingFull;
}