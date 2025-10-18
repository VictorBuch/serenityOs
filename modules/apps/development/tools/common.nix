{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.development.tools.common.enable = lib.mkEnableOption "Enables common development tools";
  };

  config = lib.mkIf config.apps.development.tools.common.enable {
    environment.systemPackages = with pkgs; [
      fastfetch
      starship
      zoxide
      fzf
      lazygit
      ripgrep
      fd
      nodePackages.nodejs
      claude-code
      mcp-nixos
    ];
  };
}
