let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.signal-desktop ];
    };
in
{
  flake.modules.nixos.signal = module;
  flake.modules.darwin.signal = module;
}
