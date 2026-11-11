let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.vlc ];
    };
in
{
  flake.modules.nixos.vlc = module;
  flake.modules.darwin.vlc = module;
}
