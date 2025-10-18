{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.emacs.linux.enable = lib.mkEnableOption "Enables Linux-specific Emacs service";
  };

  config = lib.mkIf config.apps.emacs.linux.enable {
    # Enable the Emacs daemon service (Linux-only)
    services.emacs = {
      enable = true;
    };
  };
}
