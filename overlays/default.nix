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

  # Add the pam package (renamed to avoid conflict with linux-pam)
  pam-cli = final.callPackage ../packages/pam {
    buildGoModule = final.unstable.buildGoModule;
  };
}