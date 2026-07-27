args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "system-tools";
  category = "utilities";
  packages =
    { pkgs, ... }:
    [
      pkgs.gcc
      pkgs.filezilla
      pkgs.chromium
      pkgs.lm_sensors
      pkgs.pciutils
      pkgs.gparted
      pkgs.sops
      pkgs.jq
    ];
  description = "System utility tools";
  # btop is managed via programs.btop so its config carries
  # `color_theme = "noctalia"`. noctalia's btop template writes
  # ~/.config/btop/themes/noctalia.theme from the wallpaper palette and reloads
  # btop live (SIGUSR2); the config edit is a no-op because the key is set here.
  homeConfig =
    { ... }:
    {
      programs.btop = {
        enable = true;
        settings.color_theme = "noctalia";
      };
    };
} args
