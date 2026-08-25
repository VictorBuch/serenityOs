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
    ../common/davinci-convert.nix
    ../common/wlogout
    ../common/hyprlock
    ../common/fuzzel.nix
    ../common/noctalia.nix
  ];

  home.desktop = {
    compositor.niri = {
      enable = lib.mkDefault true;
      focus-or-run.enable = lib.mkDefault true;
    };
    shell.noctalia.enable = lib.mkDefault true;
    common = {
      davinci-convert.enable = lib.mkDefault davinciEnabled;
      fuzzel.enable = lib.mkDefault true;
      wlogout.enable = lib.mkDefault true;
      hyprlock.enable = lib.mkDefault true;
    };
  };
}
