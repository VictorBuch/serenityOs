let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.calibre ];
    };
in
{
  flake.modules.nixos.calibre = module;
  flake.modules.darwin.calibre = module;
}
