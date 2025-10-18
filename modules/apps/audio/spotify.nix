{
  config,
  pkgs,
  lib,
  isLinux,
  ...
}:
{

  options = {
    apps.audio.spotify.enable = lib.mkEnableOption "Enables Spotify";
  };

  config = lib.mkIf config.apps.audio.spotify.enable (
    lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          spotify
        ];
      }

      # Firewall configuration only on Linux
      (lib.optionalAttrs isLinux {
        networking.firewall.allowedUDPPorts = [ 5353 ];
      })
    ]
  );
}
