{ lib, osConfig ? { }, ... }:

{
  imports = [
    ../common/apps.nix
    ./niri.nix
    ../common/noctalia.nix
    ../common/davinci-convert.nix
  ];

  home.desktop = {
    compositor.niri.enable = lib.mkDefault true;
    shell.noctalia.enable = lib.mkDefault true;
    common.davinci-convert.enable = lib.mkDefault (osConfig.apps.media.davinci-resolve.enable or false);
  };
}
