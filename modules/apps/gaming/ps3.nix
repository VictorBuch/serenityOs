let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.rpcs3 ];
    };
in
{
  flake.modules.nixos.ps3 = module;
  flake.modules.darwin.ps3 = module;
}
