let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.music-assistant-desktop ];
    };
in
{
  flake.modules.nixos.mass = module;
  flake.modules.darwin.mass = module;
}
