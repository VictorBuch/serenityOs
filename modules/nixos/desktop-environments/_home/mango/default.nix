{
  lib,
  inputs,
  osConfig ? { },
  ...
}:

let
  # Check if DaVinci Resolve is enabled at the system level
  davinciEnabled = (osConfig.apps.media.davinci-resolve.enable or false);
in

{
  imports = [
    inputs.mangowm.hmModules.mango
    ./mango.nix
    ./focus-or-run.nix
    ./tag-toggle.nix
    ../common/davinci-convert.nix
    ../common/dunst.nix
    ../common/wlogout
    ../common/hyprlock
    ../common/rofi.nix
    ../common/noctalia.nix
  ];

  home.desktop-environments = {
    mango = {
      enable = lib.mkDefault true;
      focus-or-run.enable = lib.mkDefault true;
      tag-toggle.enable = lib.mkDefault true;
    };
    noctalia = {
      enable = lib.mkDefault true;
    };
    common = {
      davinci-convert.enable = lib.mkDefault davinciEnabled;
      rofi.enable = lib.mkDefault true;
      dunst.enable = lib.mkDefault false;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
