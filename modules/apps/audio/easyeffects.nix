let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.easyeffects ];
    };
in
{
  flake.modules.nixos.easyeffects = module;
  flake.modules.darwin.easyeffects = module;
}
