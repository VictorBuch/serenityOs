{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./kitty.nix
    ./ghostty.nix
    ./tmux.nix
  ];

  options = {
    apps.development.terminals.enable = lib.mkEnableOption "Enables all terminals";
  };

  config = lib.mkIf config.apps.development.terminals.enable {
    apps.development.terminals.kitty.enable = lib.mkDefault true;
    apps.development.terminals.ghostty.enable = lib.mkDefault true;
    apps.development.terminals.tmux.enable = lib.mkDefault true;
  };
}
