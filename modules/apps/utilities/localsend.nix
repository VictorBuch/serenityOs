args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "localsend";
  category = "utilities";
  # Linux gets it from the flatpak declared below, macOS from nixpkgs.
  packages =
    { pkgs, lib, platform, ... }:
    lib.optionals (platform == "darwin") [ pkgs.localsend ];
  extraConfig =
    { lib, platform, ... }:
    lib.optionalAttrs (platform == "linux") {
      programs.localsend = {
        enable = true;
        openFirewall = true;
      };
    };
  description = "LocalSend - share files locally";
} args
