let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bottles
      ];
    };
in
{
  flake.modules.nixos.bottles = module;
  flake.modules.darwin.bottles = module;
}
