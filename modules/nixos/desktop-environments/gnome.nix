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
    services.displayManager.gdm.enable =
      !(
        config.desktop-environments.kde.enable
        || config.desktop-environments.hyprland.enable
        || config.desktop-environments.niri.enable
      );
    services.desktopManager.gnome.enable = true;
    environment.gnome.excludePackages =
      (with pkgs; [
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
      ++ (with pkgs.gnome; [
        pkgs.gnome-console
        pkgs.gnome-connections
      ]);

    environment.systemPackages = [
      pkgs.sushi
      pkgs.gnome-tweaks
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
