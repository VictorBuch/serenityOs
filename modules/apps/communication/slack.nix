let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.slack ];
    };
in
{
  flake.modules.nixos.slack = module;
  flake.modules.darwin.slack = module;
}
