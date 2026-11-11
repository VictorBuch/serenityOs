let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.discord ];
    };
in
{
  flake.modules.nixos.discord = module;
  flake.modules.darwin.discord = module;
}
