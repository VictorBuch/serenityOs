let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.pcsx2 ];
    };
in
{
  flake.modules.nixos.ps2 = module;
  flake.modules.darwin.ps2 = module;
}
