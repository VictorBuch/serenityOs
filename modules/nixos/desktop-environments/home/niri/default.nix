{
  lib,
  osConfig ? { },
  ...
}:

let
  # Check if DaVinci Resolve is enabled at the system level
  davinciEnabled = (osConfig.apps.media.davinci-resolve.enable or false);
in

{
  imports = [
    ./niri.nix
    ./focus-or-run.nix
    ./davinci-convert.nix
    ../common/dunst.nix
    ../common/wlogout
    ../common/hyprlock
    ../common/fuzzel.nix
    ../common/noctalia.nix
  ];

  home.desktop-environments = {
    niri = {
      enable = lib.mkDefault true;
      focus-or-run.enable = lib.mkDefault true;
      davinci-convert.enable = lib.mkDefault davinciEnabled;
    };
    noctalia = {
      enable = lib.mkDefault true;
    };
    common = {
      fuzzel.enable = lib.mkDefault true;
      dunst.enable = lib.mkDefault false;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
