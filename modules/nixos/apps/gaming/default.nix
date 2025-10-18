{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./steam.nix
    ./sunshine.nix
    ./utils/corectrl.nix
  ];

  options = {
    apps.gaming.linux.enable = lib.mkEnableOption "Enables Linux-specific gaming features";
  };

  config = lib.mkIf config.apps.gaming.linux.enable {
    apps.gaming.steam.enable = lib.mkDefault true;
    apps.gaming.sunshine.enable = lib.mkDefault true;
    apps.gaming.corectrl.enable = lib.mkDefault true;
  };
}
