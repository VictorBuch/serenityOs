{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{

  options = {
    apps.browsers.zen.enable = lib.mkEnableOption "Enables Zen browser";
  };

  config = lib.mkIf config.apps.browsers.zen.enable {
    environment.systemPackages = with pkgs; [
      inputs.zen-browser.packages."${system}".default
    ];
  };
}
