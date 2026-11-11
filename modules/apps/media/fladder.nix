let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.fladder ];
    };
in
{
  flake.modules.nixos.fladder = module;
  flake.modules.darwin.fladder = module;
}
