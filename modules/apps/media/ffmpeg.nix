let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.ffmpeg ];
    };
in
{
  flake.modules.nixos.ffmpeg = module;
  flake.modules.darwin.ffmpeg = module;
}
