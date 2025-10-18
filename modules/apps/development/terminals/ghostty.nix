{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.development.terminals.ghostty.enable = lib.mkEnableOption "Enables Ghostty terminal";
  };

  config = lib.mkIf config.apps.development.terminals.ghostty.enable {
    environment.systemPackages = with pkgs; [
      ghostty
    ];
  };
}
