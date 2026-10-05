{
  lib,
  config,
  ...
}:

let
  cfg = config.homelab.music-assistant;
in

{
  options.homelab.music-assistant.enable = lib.mkEnableOption "Enables the Music Assistant server";

  # Runs the upstream image rather than nixpkgs' services.music-assistant.
  # Upstream bakes shared API credentials (app_secrets.json) into its image at
  # build time; the nixpkgs build has none, and Tidal's device-flow login only
  # accepts Tidal-registered "Limited Input Device" clients, so there is no
  # self-supplied client_id that works there.
  config = lib.mkIf cfg.enable {
    homelab.records.music-assistant = {
      subdomain = "ma";
      port = 8095;
      # Host networking: LAN clients (desktop/mobile app) hit 8095 directly.
      openFirewall = true;
      tile = {
        title = "Music Assistant";
        icon = "sh:music-assistant";
        group = "media";
      };
    };

    virtualisation.oci-containers.containers.music-assistant = {
      image = "ghcr.io/music-assistant/server:latest";
      pull = "always";
      autoStart = true;

      # Host networking is required: player discovery (mDNS/Chromecast/AirPlay)
      # and the stream server both need to sit on the LAN directly. That also
      # means docker installs no NAT rules, so the NixOS firewall applies.
      extraOptions = [ "--network=host" ];

      environment = {
        LOG_LEVEL = "info";
      };

      volumes = [
        "/var/lib/music-assistant:/data"
      ];
    };

    networking.firewall.allowedTCPPorts = [
      8097 # stream server (players pull audio from here)
      8927 # sendspin
    ];
  };
}
