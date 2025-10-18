{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.development.terminals.kitty.enable = lib.mkEnableOption "Enables Kitty terminal";
  };

  config = lib.mkIf config.apps.development.terminals.kitty.enable {
    environment.systemPackages = with pkgs; [
      kitty
    ];
  };
}
