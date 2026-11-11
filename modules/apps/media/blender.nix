let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.blender ];
    };
in
{
  flake.modules.nixos.blender = module;
  flake.modules.darwin.blender = module;
}
