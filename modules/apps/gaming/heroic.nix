let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.heroic ];
    };
in
{
  flake.modules.nixos.heroic = module;
  flake.modules.darwin.heroic = module;
}
