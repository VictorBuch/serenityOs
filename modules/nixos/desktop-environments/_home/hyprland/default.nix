{
  lib,
  osConfig ? { },
  ...
}:
{
  imports = [
    ../common/apps.nix
    ./hyprland.nix
    ../common/davinci-convert.nix
    ../common/rofi.nix
    ../common/noctalia.nix
  ];

  home.desktop = {
    compositor.hyprland.enable = lib.mkDefault true;
    shell.noctalia.enable = lib.mkDefault true;
    common = {
      davinci-convert.enable = lib.mkDefault (osConfig.apps.media.davinci-resolve.enable or false);
      rofi.enable = lib.mkDefault true;
    };
  };
}
