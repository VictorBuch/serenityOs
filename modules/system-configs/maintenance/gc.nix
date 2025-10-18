{
  config,
  pkgs,
  lib,
  inputs,
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
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

  };
}
