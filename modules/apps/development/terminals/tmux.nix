{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.development.terminals.tmux.enable = lib.mkEnableOption "Enables tmux";
  };

  config = lib.mkIf config.apps.development.terminals.tmux.enable {
    environment.systemPackages = with pkgs; [
      tmux
    ];
  };
}
