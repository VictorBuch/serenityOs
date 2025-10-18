{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./vscode.nix
    ./neovim.nix
  ];

  options = {
    apps.development.editors.enable = lib.mkEnableOption "Enables all editors";
  };

  config = lib.mkIf config.apps.development.editors.enable {
    apps.development.editors.vscode.enable = lib.mkDefault true;
    apps.development.editors.neovim.enable = lib.mkDefault true;
  };
}
