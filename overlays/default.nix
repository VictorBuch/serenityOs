{
  inputs,
  ...
}: final: prev: {
  # Add unstable packages as pkgs.unstable
  unstable = import inputs.unstable-nixpkgs {
    inherit (final) system;
    config = {
      allowUnfree = true;
      allowBroken = true;
    };
  };

  # Add the pam package
  pam = final.callPackage ../packages/pam {
    buildGoModule = final.unstable.buildGoModule;
  };
}