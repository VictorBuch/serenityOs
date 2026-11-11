let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.zoom-us ];
    };
in
{
  flake.modules.nixos.zoom = module;
  flake.modules.darwin.zoom = module;
}
