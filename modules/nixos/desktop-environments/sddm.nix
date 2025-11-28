{
  config,
  pkgs,
  lib,
  options,
  ...
}:
{

  options = {
    sddm.enable = lib.mkEnableOption "Enables SDDM";
  };

  config = lib.mkIf config.sddm.enable {
    # catppuccin.sddm = {
    #   enable = true;
    #   accent = "mauve";
    #   flavor = "mocha";
    #   assertQt6Sddm = false;
    # };
    #
    services.xserver.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
      # theme = "catppuccin-mocha";
      settings = {
        General = {
          # Ensure proper session detection
          GreeterEnvironment = "QT_WAYLAND_DISABLE_WINDOWDECORATION=1";
        };
      };
    };
  };
}
