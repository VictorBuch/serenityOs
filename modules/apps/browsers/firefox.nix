let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.firefox ];
    };
in
{
  flake.modules.nixos.firefox = module;
  flake.modules.darwin.firefox = module;
}
