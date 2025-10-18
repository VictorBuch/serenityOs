{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.productivity.obsidian.enable = lib.mkEnableOption "Enables Obsidian";
  };

  config = lib.mkIf config.apps.productivity.obsidian.enable {
    environment.systemPackages = with pkgs; [
      obsidian
    ];
  };
}
