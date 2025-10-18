{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.minecraft.enable = lib.mkEnableOption "Enables Minecraft";
  };

  config = lib.mkIf config.apps.gaming.minecraft.enable {

    environment.systemPackages = with pkgs; [
      # minecraft
      zulu17
      prismlauncher
    ];
  };
}
