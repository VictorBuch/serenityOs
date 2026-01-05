{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    desktop-environments.gnome.enable = lib.mkEnableOption "Enables Gnome DE";
  };

  config = lib.mkIf config.desktop-environments.gnome.enable {
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable =
      !(config.desktop-environments.kde.enable || config.desktop-environments.hyprland.enable || config.desktop-environments.niri.enable);
    services.xserver.desktopManager.gnome.enable = true;
    environment.gnome.excludePackages =
      (with pkgs.unstable; [
        gnome-tour
        gedit
        cheese # webcam tool
        gnome-terminal
        epiphany # web browser
        geary # email reader
        gnome-music
        gnome-characters
        totem # video player
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
      ])
      ++ (with pkgs.unstable.gnome; [
        pkgs.unstable.gnome-console
        pkgs.unstable.gnome-connections
      ]);

    environment.systemPackages = [
      pkgs.unstable.sushi
      pkgs.unstable.gnome-tweaks
    ];
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 1716;
        to = 1764;
      }
    ];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 1716;
        to = 1764;
      }
    ];
  };
}
