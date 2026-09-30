# The Session: one selectable entry at the login manager, naming a Compositor
# and a Shell. Every standalone Wayland Compositor in this repo enables it and
# fills in what varies; everything a Session needs regardless of which
# Compositor it names lives here.
#
# The `_` prefix keeps import-tree from auto-discovering this; each Compositor
# module imports it explicitly.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.desktop.session;
  argv = lib.types.listOf lib.types.str;
  number = lib.types.either lib.types.int lib.types.float;
in
{
  options.desktop.session = {
    enable = lib.mkEnableOption "a standalone Wayland Compositor + Shell session";

    name = lib.mkOption {
      type = lib.types.str;
      description = "The session's name at the login manager.";
    };

    makeDefault = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Preselect this session at the login manager.";
    };

    keyring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Unlock gnome-keyring from PAM at login, for secrets and passwords only.
        SSH keys stay with the real OpenSSH agent, because GNOME's gcr agent
        cannot sign with FIDO2/SK keys.
      '';
    };

    inputMethod = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        IBus and friends. Off by default: XKB already handles the Latin layouts
        in use here, and IBus only arrives as a GNOME dependency.
      '';
    };

    outputs = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Connector name, e.g. DP-2.";
            };
            width = lib.mkOption { type = lib.types.int; };
            height = lib.mkOption { type = lib.types.int; };
            refresh = lib.mkOption {
              type = number;
              description = "Refresh rate in Hz, as the output reports it.";
            };
            scale = lib.mkOption {
              type = number;
              default = 1;
            };
            x = lib.mkOption {
              type = lib.types.int;
              default = 0;
            };
            y = lib.mkOption {
              type = lib.types.int;
              default = 0;
            };
          };
        }
      );
      default = [ ];
      description = "The host's monitors. Outputs not listed are left to the Compositor.";
    };

    input = {
      layouts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "us"
          "dk"
          "cz"
        ];
        description = "XKB layouts, cycled in this order.";
      };
      repeatDelay = lib.mkOption {
        type = lib.types.int;
        default = 200;
      };
      repeatRate = lib.mkOption {
        type = lib.types.int;
        default = 35;
      };
      touchpad = {
        tap = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        naturalScroll = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        accelSpeed = lib.mkOption {
          type = number;
          default = 0.2;
        };
      };
    };

    autostart = lib.mkOption {
      type = lib.types.listOf argv;
      default = [ ];
      description = "Commands started with the Session, after the Shell.";
    };

    autostartApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "App Slots (home.desktop.apps names) started with the Session, after `autostart`.";
    };

    fileManager = lib.mkOption {
      type = lib.types.enum [
        "dolphin"
        "nautilus"
      ];
      default = "dolphin";
      description = "The app that owns inode/directory and answers org.freedesktop.FileManager1.";
    };

    homeModules = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Home Manager modules carrying each enabled Compositor's own config.";
    };
  };

  config = lib.mkIf cfg.enable {

    desktop.loginManager.sddm.enable = true;

    services.displayManager.defaultSession = lib.mkIf cfg.makeDefault cfg.name;

    home-manager.sharedModules = [ ./_home/common/session.nix ] ++ cfg.homeModules;

    desktop.session.autostart = [
      [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]
      [
        "easyeffects"
        "--gapplication-service"
      ]
      [
        "wl-paste"
        "--watch"
        "cliphist"
        "store"
      ]
    ];

    i18n.inputMethod.enable = cfg.inputMethod;

    # Enable on `login` because /etc/pam.d/sddm is `substack login` -- setting
    # this on `sddm` directly is a no-op.
    services.gnome.gnome-keyring.enable = lib.mkIf cfg.keyring true;
    security.pam.services.login.enableGnomeKeyring = lib.mkIf cfg.keyring true;
    services.gnome.gcr-ssh-agent.enable = lib.mkIf cfg.keyring (lib.mkForce false);
    programs.ssh.startAgent = lib.mkIf cfg.keyring true;

    security.polkit = {
      enable = true;

      # Let wheel mount removable drives without a password prompt.
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

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services = {
      blueman.enable = true;
      udisks2.enable = true; # auto-mount removable drives
      gvfs.enable = true; # virtual filesystems for GUI file managers
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };

    security.rtkit.enable = true;
    programs.nm-applet.enable = true;

    environment.systemPackages = with pkgs; [
      libnotify
      awww # wallpaper daemon (swww renamed)
      pipewire
      wireplumber
      pavucontrol
      blueman
      networkmanagerapplet

      qt5.qtwayland
      qt6.qtwayland

      cliphist
      wl-clipboard

      grim
      slurp

      # Fallback for icon themes that declare Inherits=breeze, which the
      # Colloid theme stylix installs does.
      kdePackages.breeze-icons
    ];
  };
}
