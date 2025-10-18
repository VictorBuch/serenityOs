{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.communication.slack.enable = lib.mkEnableOption "Enables Slack";
  };

  config = lib.mkIf config.apps.communication.slack.enable {
    environment.systemPackages = with pkgs; [
      slack
    ];
  };
}
