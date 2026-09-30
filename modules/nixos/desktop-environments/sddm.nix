{
  config,
  lib,
  inputs,
  ...
}:
let
  silent = config.programs.silentSDDM;
  wallpaper = "bg8.jpg";
in
{
  imports = [ inputs.silentSDDM.nixosModules.default ];

  options = {
    desktop.loginManager.sddm.enable = lib.mkEnableOption "SDDM as the login manager";
  };

  config = lib.mkIf config.desktop.loginManager.sddm.enable {
    programs.silentSDDM = {
      enable = true;
      theme = "default";
      wayland = {
        enable = true;
        compositor = "kwin";
      };
      backgrounds.night = "${inputs.wallpapers-nord}/${wallpaper}";
      settings = {
        LockScreen = {
          background = wallpaper;
          blur = 48;
          brightness = -0.1;
        };
        "LockScreen.Clock".font-family = config.fonts.mono.familyMono;
        "LockScreen.Date".font-family = config.fonts.mono.familyMono;
        "LockScreen.Message".font-family = config.fonts.mono.familyMono;
        LoginScreen = {
          background = wallpaper;
          blur = 64;
          brightness = -0.15;
        };
      };
    };

    services.displayManager.sddm.settings.General.GreeterEnvironment = lib.mkForce (
      lib.concatStringsSep "," [
        "QML2_IMPORT_PATH=${silent.package'}/share/sddm/themes/silent/components/"
        "QT_IM_MODULE=qtvirtualkeyboard"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION=1"
      ]
    );
  };
}
