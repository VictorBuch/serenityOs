let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.qemu
        pkgs.quickemu
        pkgs.quickgui
      ];
    };
in
{
  flake.modules.nixos.qemu = module;
  flake.modules.darwin.qemu = module;
}
