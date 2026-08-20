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
    services.displayManager.defaultSession = "mango";

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

      # No extraPortals here: nixpkgs' programs.mango module already contributes
      # xdg-desktop-portal-{wlr,gtk}, and xdg.portal.wlr below contributes wlr again.
      # Listing them a third time just duplicated entries in the portals env.
      #
      # xdg.portal.wlr is what we actually need over a bare extraPortals entry: it also
      # passes --config to the service. Without a config xdpw guesses a source picker at
      # runtime — it spawns wmenu, then wofi (neither is installed here), and only then
      # rofi, whichever rofi the systemd user unit happened to inherit on PATH. That
      # fallback has already failed outright once, logging "rofi: command not found"
      # followed by "wlroots: no output found", which aborts the share.
      wlr = {
        enable = true;
        settings.screencast = {
          # dmenu hands xdpw's own list (monitors *and* windows) to the chooser on
          # stdin, so window sharing stays available — "simple" + slurp would only
          # ever let you pick a monitor. Absolute store path so the picker no longer
          # depends on what the service inherited in PATH.
          chooser_type = "dmenu";
          chooser_cmd = "${pkgs.rofi}/bin/rofi -dmenu -i -p 'Select a source to share'";
        };
      };

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

    # kio-fuse is dbus-activated; without this it never starts and Dolphin's
    # remote locations stay invisible to non-KDE apps.
    services.dbus.packages = [ pkgs.kdePackages.kio-fuse ];
    security.rtkit.enable = true;

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
        kdePackages.breeze-icons

        # File manager. Colours come from noctalia's `kcolorscheme` template
        # (kdeglobals) plus the `qt` template via qt6ct; kio-extras carries the
        # protocol handlers and thumbnailers Dolphin expects.
        kdePackages.dolphin
        kdePackages.kio-extras
        kdePackages.kio-fuse
        kdePackages.ffmpegthumbs
        kdePackages.kdegraphics-thumbnailers

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
