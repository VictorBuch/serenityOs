{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./minecraft.nix
    ./wine.nix
    ./heroic.nix
    ./ps3.nix
    ./utils/gamemode.nix
    ./utils/mangohud.nix
  ];

  options = {
    apps.gaming.enable = lib.mkEnableOption "Enables all cross-platform gaming apps";
  };

  config = lib.mkIf config.apps.gaming.enable {
    apps.gaming.minecraft.enable = lib.mkDefault true;
    apps.gaming.wine.enable = lib.mkDefault true;
    apps.gaming.gamemode.enable = lib.mkDefault true;
    apps.gaming.mangohud.enable = lib.mkDefault true;
    apps.gaming.heroic.enable = lib.mkDefault true;
    apps.gaming.ps3.enable = lib.mkDefault false;
  };
}
