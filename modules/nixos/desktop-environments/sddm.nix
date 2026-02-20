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
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
      theme = "sddm-astronaut-theme";
      settings = {
        General = {
          GreeterEnvironment = "QT_WAYLAND_DISABLE_WINDOWDECORATION=1";
        };
      };
    };

    environment.systemPackages = with pkgs.kdePackages; [
      qtsvg
      qtmultimedia
      qtvirtualkeyboard
      (pkgs.sddm-astronaut.override {
        embeddedTheme = "japanese_aesthetic";
        themeConfig = {
          # Background
          Background = "${../../../home/wallpapers/dark-hole.png}";
          CropBackground = "true";
          DimBackground = "0.2";

          # General
          FormPosition = "center";
          Font = "JetBrainsMono Nerd Font Mono";
          FontSize = "13";
          RoundCorners = "16";
          HourFormat = "HH:mm";
          DateFormat = "dddd d MMMM";

          # Panel / form colors (gruvbox-dark)
          FormBackgroundColor = "#282828";
          BackgroundColor = "#282828";
          DimBackgroundColor = "#1d2021";

          # Input fields
          LoginFieldBackgroundColor = "#3c3836";
          PasswordFieldBackgroundColor = "#3c3836";
          LoginFieldTextColor = "#ebdbb2";
          PasswordFieldTextColor = "#ebdbb2";
          UserIconColor = "#ebdbb2";
          PasswordIconColor = "#ebdbb2";

          # Text colors
          HeaderTextColor = "#ebdbb2";
          DateTextColor = "#928374";
          TimeTextColor = "#ebdbb2";
          PlaceholderTextColor = "#665c54";

          # Buttons
          LoginButtonTextColor = "#ebdbb2";
          LoginButtonBackgroundColor = "#458588";
          SystemButtonsIconsColor = "#ebdbb2";
          SessionButtonTextColor = "#ebdbb2";
          VirtualKeyboardButtonTextColor = "#ebdbb2";
          WarningColor = "#cc241d";

          # Dropdowns
          DropdownTextColor = "#ebdbb2";
          DropdownSelectedBackgroundColor = "#458588";
          DropdownBackgroundColor = "#3c3836";

          # Highlights
          HighlightTextColor = "#ebdbb2";
          HighlightBackgroundColor = "#504945";
          HighlightBorderColor = "#458588";

          # Hover states (gruvbox aqua accent)
          HoverUserIconColor = "#689d6a";
          HoverPasswordIconColor = "#689d6a";
          HoverSystemButtonsIconsColor = "#689d6a";
          HoverSessionButtonTextColor = "#689d6a";
          HoverVirtualKeyboardButtonTextColor = "#689d6a";

          # Form blur
          PartialBlur = "true";
          BlurMax = "48";
          Blur = "2.0";
          HaveFormBackground = "true";

          # Behavior
          ForceLastUser = "true";
          PasswordFocus = "true";
          HideVirtualKeyboard = "true";
          HideLoginButton = "false";
        };
      })
    ];
  };
}
