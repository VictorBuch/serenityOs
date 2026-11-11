let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.spotify ];
    };
in
{
  flake.modules.nixos.spotify = {
    imports = [ module ];
    # Spotify Connect discovery.
    networking.firewall.allowedUDPPorts = [ 5353 ];
  };
  flake.modules.darwin.spotify = module;
}
