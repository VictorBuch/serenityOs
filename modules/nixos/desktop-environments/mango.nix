{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  options = {
    desktop-environments.mango.enable = lib.mkEnableOption "Enables Mango WM (dwl-based wlroots compositor)";
  };

  config = lib.mkIf config.desktop-environments.mango.enable {

    home-manager.sharedModules = [ ./_home/mango ];

    i18n.inputMethod.enable = false;

    # nixpkgs upstreamed this module (programs/wayland/mango.nix); the login
    # session entry is wired automatically via services.displayManager.sessionPackages.
    # nixpkgs only packages 0.14.4 (~6 releases behind), so point it at the flake's
    # nightly build to match the config the mango hm module generates.
    programs.mango = {
      enable = true;
      package = inputs.mangowm.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    sddm.enable = true;

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
    programs.ssh.startAgent = true;

    security.polkit = {
      enable = true;
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

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
      config = {
        common.default = [ "gtk" ];
        mango = {
          default = lib.mkForce [
            "wlr"
            "gtk"
          ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        };
      };
    };

    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    services = {
      blueman.enable = true;
      udisks2.enable = true;
      tumbler.enable = true; # Thumbnail support for images Thunar
      gvfs.enable = true;
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };

    programs.nm-applet.enable = true;
    security.rtkit.enable = true;

    # Thunar file manager
    programs.thunar.enable = true;
    programs.xfconf.enable = true;

    environment.systemPackages =
      (with pkgs; [
        libnotify
        awww
        #hyprlock
        #dunst
        pipewire
        wireplumber
        pavucontrol
        blueman
        networkmanagerapplet
        polkit_gnome
        #waybar
        #wlogout

        qt5.qtwayland
        qt6.qtwayland

        xwayland-satellite

        cliphist
        wl-clipboard
        papirus-icon-theme

        grim
        slurp
        brightnessctl
        playerctl
        wlr-randr
      ])
      ++ [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
  };
}
