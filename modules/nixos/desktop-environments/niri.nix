{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [ ./_wayland-session.nix ];

  options = {
    desktop-environments.niri.enable = lib.mkEnableOption "Enables Niri WM";
  };

  config = lib.mkIf config.desktop-environments.niri.enable {

    desktop-environments.wayland-session.enable = true;

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

    environment.systemPackages =
      (with pkgs; [
        hyprlock # Lock screen (compatible with niri)
        dunst # Notification manager
        nautilus
        waybar # Status bar with niri support
        wlogout

        # Xwayland support
        xwayland-satellite # X11 compatibility layer for niri

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
