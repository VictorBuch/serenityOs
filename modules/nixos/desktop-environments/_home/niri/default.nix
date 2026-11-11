{ lib, ... }:

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
  };
}
