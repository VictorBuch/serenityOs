let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.gcc
        pkgs.chromium
        pkgs.lm_sensors
        pkgs.pciutils
        pkgs.gparted
        pkgs.sops
        pkgs.jq
      ];
    };
in
{
  flake.modules.nixos.system-tools = module;
  flake.modules.darwin.system-tools = module;
  flake.modules.homeManager.system-tools =
    { ... }:
    {
      programs.btop = {
        enable = true;
        settings.color_theme = "noctalia";
      };
    };
}
