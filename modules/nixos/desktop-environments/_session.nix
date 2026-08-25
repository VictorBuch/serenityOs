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

    homeModule = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Home Manager module carrying the Compositor's own config.";
    };
  };

  config = lib.mkIf cfg.enable {

    desktop.loginManager.sddm.enable = true;

    services.displayManager.defaultSession = lib.mkIf cfg.makeDefault cfg.name;

    home-manager.sharedModules = lib.optional (cfg.homeModule != null) cfg.homeModule;

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
