{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{

  imports = [
    ./sddm.nix
  ];

  options = {
    desktop-environments.niri.enable = lib.mkEnableOption "Enables Niri WM";
  };

  config = lib.mkIf config.desktop-environments.niri.enable {

    # Enable the Niri Window Manager
    programs.niri = {
      enable = true;
    };

    sddm.enable = true;

    # Enable polkit
    security.polkit.enable = true;

    # Allow wheel group users to mount drives without password
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (
          subject.isInGroup("wheel")
          && (action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
              action.id == "org.freedesktop.udisks2.filesystem-mount")
        ) {
          return polkit.Result.YES;
        }
      });
    '';

    # Enable portals with proper configuration for niri
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = "*";
        niri.default = [
          "gnome"
          "gtk"
        ];
      };
    };

    # Enable bluetooth
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    services.blueman.enable = true;

    # Enable services for Nautilus to work with external drives
    services.udisks2.enable = true; # Auto-mount removable drives
    services.gvfs.enable = true; # GNOME Virtual File System (needed by Nautilus)

    # Enable network manager applet
    programs.nm-applet.enable = true;

    # Enable sound with pipewire
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = with pkgs; [
      libnotify
      swww # Wallpaper daemon
      hyprlock # Lock screen (compatible with niri)
      dunst # Notification manager
      pipewire
      wireplumber
      nautilus
      pavucontrol
      blueberry # Bluetooth manager
      networkmanagerapplet
      waybar # Status bar with niri support
      wlogout

      qt5.qtwayland
      qt6.qtwayland

      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Xwayland support
      xwayland-satellite # X11 compatibility layer for niri

      cliphist
      wl-clipboard
      papirus-icon-theme

      # Screenshot tools
      grim # Screenshot tool
      slurp # Screen area selector
    ];
  };
}
