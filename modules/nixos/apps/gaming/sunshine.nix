{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.gaming.sunshine.enable = lib.mkEnableOption "Enables Sunshine game streaming";
  };

  config = lib.mkIf config.apps.gaming.sunshine.enable {

    # Enable sunshine
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
}
