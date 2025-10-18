{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.productivity.nextcloud.enable = lib.mkEnableOption "Enables Nextcloud client";
  };

  config = lib.mkIf config.apps.productivity.nextcloud.enable {
    environment.systemPackages = with pkgs; [
      nextcloud31
      nextcloud-client
    ];
  };
}
