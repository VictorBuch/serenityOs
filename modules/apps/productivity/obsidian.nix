let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.obsidian ];
    };
in
{
  flake.modules.nixos.obsidian = module;
  flake.modules.darwin.obsidian = module;
}
