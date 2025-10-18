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
    catppuccin.sddm = {
      enable = true;
      accent = "mauve";
      flavor = "mocha";
    };

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      # theme = "catppuccin-mocha";
      settings = {
        General = {
          # Ensure proper session detection
          GreeterEnvironment = "QT_WAYLAND_DISABLE_WINDOWDECORATION=1";
        };
        # Wayland = {
        #   # Specify compositor for SDDM
        #   CompositorCommand = "kwin_wayland --no-lockscreen --no-global-shortcuts --locale1";
        # };
      };
    };
    # environment.systemPackages = with pkgs; [
    #   (catppuccin-sddm.override {
    #     flavor = "mocha";
    #     font  = "JetBrainsMono Nerd Font";
    #     fontSize = "12";
    #     background = ../../home/wallpapers/cloudsnight.jpg;
    #     loginBackground = true;
    #     }
    #   )
    # ];
  };
}
