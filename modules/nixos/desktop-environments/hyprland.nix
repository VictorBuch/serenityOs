{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./_wayland-session.nix ];

  options = {
    desktop-environments.hyprland.enable = lib.mkEnableOption "Enables Hyprland WM";
  };

  config = lib.mkIf config.desktop-environments.hyprland.enable {

    desktop-environments.wayland-session.enable = true;

    # Inject Home Manager config for hyprland (keybinds, animations, etc.)
    home-manager.sharedModules = [ ./_home/hyprland ];

    # Enable the Hyprland Window Manager
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Enable portals with proper configuration
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = lib.mkDefault "*";
        hyprland.default = [
          "hyprland"
          "gtk"
        ];
      };
    };

    # Configure keymap in X11
    # services.xserver = {
    #   xkb = {
    #     layout = "us, dk";
    #     variant = "";
    #     options = "grp:alt_space_toggle";
    #   };
    # };

    environment.systemPackages = with pkgs; [
      hypridle # Idle
      hyprlock # Lock screen
      # Bar provided by noctalia via home-manager (../_home/common/noctalia.nix)
      hyprpolkitagent
      dunst # Notification manager
      nautilus
      hyprshot # Screenshot tool
      wlogout

    ];
  };
}
