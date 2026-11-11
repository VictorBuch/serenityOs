let
  module =
    { pkgs, pkgs-stable, ... }:
    {
      # Use pkgs-stable for Wine gaming to avoid breaking changes
      environment.systemPackages = [
        pkgs-stable.wineWowPackages.stable
        pkgs-stable.wineWowPackages.waylandFull
        pkgs-stable.winetricks
        pkgs.protontricks # protontricks can stay on unstable
      ];
    };
in
{
  flake.modules.nixos.wine = module;
  flake.modules.darwin.wine = module;
}
