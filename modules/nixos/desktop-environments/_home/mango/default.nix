{
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../common/apps.nix
    inputs.mangowm.hmModules.mango
    ./mango.nix
    ./focus-or-run.nix
    ./tag-toggle.nix
    ../common/davinci-convert.nix
    ../common/rofi.nix
    ../common/noctalia.nix
  ];

  home.desktop = {
    compositor.mango = {
      enable = lib.mkDefault true;
      focus-or-run.enable = lib.mkDefault true;
      tag-toggle.enable = lib.mkDefault true;
    };
    shell.noctalia.enable = lib.mkDefault true;
    common = {
      rofi.enable = lib.mkDefault true;
    };
  };
}
