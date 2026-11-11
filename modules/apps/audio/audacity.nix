let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.audacity ];
    };
in
{
  flake.modules.nixos.audacity = module;
  flake.modules.darwin.audacity = module;
}
