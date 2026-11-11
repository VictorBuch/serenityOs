let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.eden ];
    };
in
{
  flake.modules.nixos.eden = module;
  flake.modules.darwin.eden = module;
}
