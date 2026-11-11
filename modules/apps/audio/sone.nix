let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.sone ];
    };
in
{
  flake.modules.nixos.sone = module;
  flake.modules.darwin.sone = module;
}
