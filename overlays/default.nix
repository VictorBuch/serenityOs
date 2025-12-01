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
}