{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    desktop.environment.gnome.enable = lib.mkEnableOption "the GNOME Desktop Environment";
  };

  config = lib.mkIf config.desktop.environment.gnome.enable {
    services.xserver.enable = true;
    # GDM only when nothing else has claimed the login manager.
    services.displayManager.gdm.enable = !(
      config.desktop.environment.kde.enable || config.desktop.session.enable
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
