{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    fonts.enable = lib.mkEnableOption "Enable custom fonts";
  };

  config = lib.mkIf config.fonts.enable {

    environment.systemPackages = with pkgs; [
      jetbrains-mono
    ];

    fonts.packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];
  };
}
