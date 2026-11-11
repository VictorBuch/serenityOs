let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.handy
        pkgs.wtype
      ];
    };
in
{
  flake.modules.nixos.handy = module;
  flake.modules.darwin.handy = module;
}
