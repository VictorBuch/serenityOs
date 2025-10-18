{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.development.editors.vscode.enable = lib.mkEnableOption "Enables VS Code";
  };

  config = lib.mkIf config.apps.development.editors.vscode.enable {
    environment.systemPackages = with pkgs; [
      vscode
    ];
  };
}
