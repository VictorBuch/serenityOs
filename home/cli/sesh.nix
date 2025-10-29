{
  config,
  options,
  pkgs,
  lib,
  ...
}:

{

  options = {
    home.cli.sesh.enable = lib.mkEnableOption "Enables sesh session manager";
  };

  config = lib.mkIf config.home.cli.sesh.enable {

    programs.sesh = {
      enable = true;
      enableTmuxIntegration = true;
      enableAlias = false;
      tmuxKey = "s";
    };
  };
}
