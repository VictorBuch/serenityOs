{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.emacs.enable = lib.mkEnableOption "Enables Emacs";
  };

  config = lib.mkIf config.apps.emacs.enable {
    environment.systemPackages = with pkgs; [
      emacs
    ];
  };
}
