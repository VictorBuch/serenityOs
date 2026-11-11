let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.vscode ];
    };
in
{
  flake.modules.nixos.vscode = module;
  flake.modules.darwin.vscode = module;
}
