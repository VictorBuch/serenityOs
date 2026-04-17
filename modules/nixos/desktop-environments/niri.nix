{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{

  options = {
    desktop-environments.niri.enable = lib.mkEnableOption "Enables Niri WM";
  };

  config = lib.mkIf config.desktop-environments.niri.enable {

    # Inject Home Manager config for niri (keybinds, window rules, noctalia, etc.)
    home-manager.sharedModules = [ ./_home/niri ];

    # Disable IBus input method framework (pulled in by GNOME)
    # IBus is not needed for Latin-based layouts (US, Danish, Czech) - XKB handles those
    i18n.inputMethod.enable = false;

    # Enable the Niri Window Manager
    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };

    sddm.enable = true;
    services.displayManager.defaultSession = "niri";

    # GNOME Keyring: auto-unlock on login via PAM (secrets/passwords only)
    # Enable on `login` because /etc/pam.d/sddm is `substack login` — setting
    # this on `sddm` directly is a no-op.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;

    # Disable GNOME's gcr SSH agent — it can't handle FIDO2/SK key signing
    # Use real OpenSSH agent instead
    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
    programs.ssh.startAgent = true;

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
    # Use xdg-desktop-portal-gtk (nixpkgs niri module sets niri.default)
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = [ "gtk" ];
        # niri.default managed by nixpkgs niri module
        # niri.default = [ "gtk" ];
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
      (with pkgs; [
        libnotify
        awww # Wallpaper daemon (swww renamed)
        hyprlock # Lock screen (compatible with niri)
        dunst # Notification manager
        pipewire
        wireplumber
        nautilus
        pavucontrol
        blueman # Bluetooth manager
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
