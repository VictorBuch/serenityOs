# Plumbing every standalone Wayland compositor in this repo needs, extracted
# from hyprland.nix / niri.nix / mango.nix where it was duplicated verbatim.
#
# The `_` prefix keeps import-tree from auto-discovering this; each compositor
# module imports it explicitly and opts in by setting the enable flag inside
# its own mkIf, so nothing here applies to a host that runs none of them.
#
# Only byte-identical config was moved. Anything that differed between the
# three -- portal backends, compositor packages, session defaults, keyring and
# input-method handling, file managers, lock screens -- stays where it was.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.desktop-environments.wayland-session;
in
{
  options = {
    desktop-environments.wayland-session.enable = lib.mkEnableOption "shared plumbing for a standalone Wayland compositor session";
  };

  config = lib.mkIf cfg.enable {

    sddm.enable = true;

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

      # Fallback for icon themes that declare Inherits=breeze, which the
      # Colloid theme stylix installs does.
      kdePackages.breeze-icons
    ];
  };
}
