{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    home.desktop.common.rofi.enable =
      lib.mkEnableOption "Rofi as a dmenu backend for the few menus the Shell does not own";
  };

  config = lib.mkIf config.home.desktop.common.rofi.enable {
    home.packages = with pkgs; [
      # NetworkManager VPN toggle. The Shell's control center covers wifi,
      # bluetooth, volume and the session menu, but not VPN connections.
      rofi-vpn
    ];

    programs.rofi = {
      enable = true;
      package = pkgs.rofi;
      terminal = "${pkgs.ghostty}/bin/ghostty";

      # Demoted to a dmenu backend. The Shell owns drun, calc, window
      # switching, emoji and the session menu (its providers live in
      # src/launcher/), so rofi is kept only for rofi-vpn and as the
      # xdg-desktop-portal-wlr screencast source chooser, which names
      # ${pkgs.rofi}/bin/rofi by absolute path.
      #
      # No bespoke theme: with the 115-line .rasi gone, stylix's rofi target
      # owns these colors, which is one writer rather than two.
      extraConfig = {
        modi = "run";
        show-icons = true;
        icon-theme = config.stylix.icons.dark;
        display-run = "  Run";
        drun-display-format = "{name}";
        kb-cancel = "Escape";
      };
    };
  };
}
