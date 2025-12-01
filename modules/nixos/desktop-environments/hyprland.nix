{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./sddm.nix
  ];

  options = {
    desktop-environments.hyprland.enable = lib.mkEnableOption "Enables Hyprland WM";
  };

  config = lib.mkIf config.desktop-environments.hyprland.enable {

    # Enable the Hyprland Window Manager
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
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

    # Enable portals with proper configuration
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs.unstable; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = "*";
        hyprland.default = [
          "hyprland"
          "gtk"
        ];
      };
    };

    #Enable bluetooth
    hardware.bluetooth.enable = true; # enables support for Bluetooth
    hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
    services.blueman.enable = true;

    # Enable services for Nautilus to work with external drives
    services.udisks2.enable = true;  # Auto-mount removable drives
    services.gvfs.enable = true;     # GNOME Virtual File System (needed by Nautilus)
 
    # Enable network manager applet
    programs.nm-applet.enable = true;

    # Configure keymap in X11
    # services.xserver = {
    #   xkb = {
    #     layout = "us, dk";
    #     variant = "";
    #     options = "grp:alt_space_toggle";
    #   };
    # };

    # Enable sound with pipewire.
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      jack.enable = true;
    };

    environment.systemPackages = with pkgs.unstable; [
      libnotify
      # hyprpaper #Wallpaper
      swww
      hypridle # Idle
      hyprlock # Lock screen
      #waybar # Bar
      hyprpanel # Bar
      hyprpolkitagent
      dunst # Notification manager
      pipewire
      wireplumber
      nautilus
      pavucontrol
      blueberry # bluetooth manager
      networkmanagerapplet # wifi manager
      hyprshot # Screenshot tool
      wlogout

      qt5.qtwayland
      qt6.qtwayland

      rofi # Application launcher
      rofi-calc
      rofi-emoji
      rofi-bluetooth
      rofi-power-menu
      rofi-vpn
      rofi-obsidian
      rofi-network-manager
      rofi-screenshot
      rofi-systemd
      rofi-pulse-select
      rofi-pass-wayland
      cliphist
      wl-clipboard
      papirus-icon-theme
    ];
  };
}
