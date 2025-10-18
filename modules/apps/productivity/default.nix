{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./obsidian.nix
    ./nextcloud.nix
    ./language-learning.nix
  ];

  options = {
    apps.productivity.enable = lib.mkEnableOption "Enables all productivity apps";
  };

  config = lib.mkIf config.apps.productivity.enable {
    apps.productivity.obsidian.enable = lib.mkDefault true;
    apps.productivity.nextcloud.enable = lib.mkDefault true;
    apps.productivity.language-learning.enable = lib.mkDefault false;
  };
}
