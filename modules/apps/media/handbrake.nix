let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.handbrake ];
    };
in
{
  flake.modules.nixos.handbrake = module;
  flake.modules.darwin.handbrake = module;
}
