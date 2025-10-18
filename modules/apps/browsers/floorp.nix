{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.browsers.floorp.enable = lib.mkEnableOption "Enables Floorp browser";
  };

  config = lib.mkIf config.apps.browsers.floorp.enable {
    environment.systemPackages = with pkgs; [
      floorp
    ];
  };
}
