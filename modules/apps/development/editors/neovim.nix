{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.development.editors.neovim.enable = lib.mkEnableOption "Enables Neovim";
  };

  config = lib.mkIf config.apps.development.editors.neovim.enable {
    environment.systemPackages = with pkgs; [
      neovim
    ];
  };
}
