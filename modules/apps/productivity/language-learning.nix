let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.anki
      ];
    };
in
{
  flake.modules.nixos.language-learning = module;
  flake.modules.darwin.language-learning = module;
}
