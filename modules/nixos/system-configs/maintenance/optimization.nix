{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{

  options = {
    optimization.enable = lib.mkEnableOption "Enable Nix store optimization";
  };

  config = lib.mkIf config.optimization.enable {

    # Automatic Nix store optimization (deduplication via hardlinking)
    nix.optimise = {
      automatic = true;
      dates = [ "weekly" ];
      randomizedDelaySec = "45min";
      persistent = true;
    };

  };
}
