let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.neovim ];
    };
in
{
  flake.modules.nixos.neovim = module;
  flake.modules.darwin.neovim = module;
}
