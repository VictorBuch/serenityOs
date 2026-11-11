let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.gamemode ];
    };
in
{
  flake.modules.nixos.gamemode = module;
  flake.modules.darwin.gamemode = module;
}
