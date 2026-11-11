let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.zulu17
        pkgs.prismlauncher
      ];
    };
in
{
  flake.modules.nixos.minecraft = module;
  flake.modules.darwin.minecraft = module;
}
