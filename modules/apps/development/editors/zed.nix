let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.zed-editor ];
    };
in
{
  flake.modules.nixos.zed = module;
  flake.modules.darwin.zed = module;
}
