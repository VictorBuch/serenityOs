let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.retroarch-full ];
    };
in
{
  flake.modules.nixos.retroarch = module;
  flake.modules.darwin.retroarch = module;
}
