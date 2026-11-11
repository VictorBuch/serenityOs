let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.mangohud ];
    };
in
{
  flake.modules.nixos.mangohud = module;
  flake.modules.darwin.mangohud = module;
}
