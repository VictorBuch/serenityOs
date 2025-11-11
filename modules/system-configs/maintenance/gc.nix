{
  config,
  pkgs,
  lib,
  inputs,
  isLinux ? pkgs.stdenv.isLinux,
  ...
}:
{

  options = {
    gc.enable = lib.mkEnableOption "Enable gc";
  };

  config = lib.mkIf config.gc.enable {
    # Automatic Garbage collection cleanup
    nix.gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    } // (lib.optionalAttrs isLinux {
      # NixOS-specific options
      dates = "weekly";
      randomizedDelaySec = "30min";
      persistent = true;
    }) // (lib.optionalAttrs (!isLinux) {
      # nix-darwin-specific options
      interval = { Weekday = 0; Hour = 3; Minute = 15; };  # Weekly on Sunday at 3:15 AM
    });
  };
}
