let
  module =
    { pkgs, ... }:
    let
      devenv-init = pkgs.writeShellApplication {
        name = "devenv-init";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
        ];
        text = builtins.readFile ./devenv-init.sh;
      };
    in
    {
      environment.systemPackages = [
        pkgs.devenv
        pkgs.direnv
        devenv-init
      ];
    };
in
{
  flake.modules.nixos.devenv-init = module;
  flake.modules.darwin.devenv-init = module;
}
