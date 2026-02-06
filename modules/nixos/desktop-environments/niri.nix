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
      package = pkgs.unstable.niri;
    };

    sddm.enable = true;
    services.displayManager.defaultSession = "niri";

    security.polkit = {

      # Enable polkit
      enable = true;

      # Allow wheel group users to mount drives without password
      extraConfig = ''
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
    };

    # Enable portals with proper configuration for niri
    # Use xdg-desktop-portal-gtk only (gnome portal causes conflicts)
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = [ "gtk" ];
        niri.default = [ "gtk" ];
      };
    };

    # Enable bluetooth
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    services = {
      blueman.enable = true;

      # Enable services for Nautilus to work with external drives
      udisks2.enable = true; # Auto-mount removable drives
      gvfs.enable = true;
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    }; # GNOME Virtual File System (needed by Nautilus)

    # Enable network manager applet
    programs.nm-applet.enable = true;

    # Enable sound with pipewire
    security.rtkit.enable = true;

    environment.systemPackages =
      (with pkgs.unstable; [
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

        # Xwayland support
        xwayland-satellite # X11 compatibility layer for niri

        cliphist
        wl-clipboard
        papirus-icon-theme

        # Screenshot tools
        grim # Screenshot tool
        slurp # Screen area selector
      ])
      ++ [
        # noctalia from flake input (uses its own pkgs)
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
  };
}
