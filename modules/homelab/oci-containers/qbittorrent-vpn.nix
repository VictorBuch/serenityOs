{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.homelab.qbittorrent-vpn;
  user = config.user;
in

{
  options.homelab.qbittorrent-vpn = {
    enable = lib.mkEnableOption "qBittorrent behind PIA WireGuard via pia-tun";

    qui.enable = lib.mkEnableOption "Enable qui modern web UI for qBittorrent";

    pia.locations = lib.mkOption {
      type = lib.types.str;
      default = "de_berlin";
      description = "PIA locations (comma-separated, port-forward capable regions only)";
    };

    ports = {
      webui = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Host port for qBittorrent WebUI (mapped from pia-tun container:8080)";
      };
      qui = lib.mkOption {
        type = lib.types.port;
        default = 7476;
        description = "Host port for qui WebUI";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      networking.firewall.allowedTCPPorts =
        [ cfg.ports.webui ]
        ++ lib.optional cfg.qui.enable cfg.ports.qui;

      sops.templates."pia-tun-env" = {
        content = ''
          PIA_USER=${config.sops.placeholder."vpn/pia/username"}
          PIA_PASS=${config.sops.placeholder."vpn/pia/password"}
          PS_USER=${config.sops.placeholder."qbittorrent/username"}
          PS_PASS=${config.sops.placeholder."qbittorrent/password"}
        '';
        owner = "root";
        group = "root";
        mode = "0400";
      };

      virtualisation.oci-containers.containers.pia-tun = {
        image = "x0lie/pia-tun:1.1.0";
        autoStart = true;

        # Internal port stays 8080 (matches pia-tun's PS_URL default).
        # Host port is configurable via cfg.ports.webui.
        ports = [
          "${toString cfg.ports.webui}:8080"
        ];

        environment = {
          PIA_LOCATIONS = cfg.pia.locations;
          PS_CLIENT = "qbittorrent";
          PS_URL = "http://localhost:8080";
          LOCAL_NETWORKS = "192.168.0.0/24,10.0.0.0/24";
          PF_ENABLED = "true";
          DNS = "pia";
          LOG_LEVEL = "info";
          TZ = "Europe/Copenhagen";
        };

        environmentFiles = [
          config.sops.templates."pia-tun-env".path
        ];

        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--cap-drop=ALL"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
      };

      virtualisation.oci-containers.containers.qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:5.2.0";
        autoStart = true;
        dependsOn = [ "pia-tun" ];

        volumes = [
          "/var/lib/qbittorrent/config:/config"
          "${config.homelab.mediaDir}/downloads:/downloads"
        ];

        environment = {
          PUID = "1000";
          PGID = "994";
          TZ = "Europe/Copenhagen";
          # Must match pia-tun's published container port (see ports above).
          WEBUI_PORT = "8080";
        };

        extraOptions = [
          "--network=container:pia-tun"
        ];
      };

      systemd.services.docker-qbittorrent = {
        after = [ "mnt-pool.mount" ];
        requires = [ "mnt-pool.mount" ];
      };
    }

    (lib.mkIf cfg.qui.enable {
      virtualisation.oci-containers.containers.qui = {
        # No semver tags published yet, only `latest`. Pin to digest once stable.
        image = "ghcr.io/autobrr/qui:latest";
        autoStart = true;
        dependsOn = [ "qbittorrent" ];

        ports = [
          "${toString cfg.ports.qui}:7476"
        ];

        volumes = [
          "/var/lib/qui:/config"
          "${config.homelab.mediaDir}/downloads:/downloads:ro"
        ];

        environment = {
          TZ = "Europe/Copenhagen";
          QUI__LOG_LEVEL = "info";
        };

        # qui reaches qBittorrent via host bridge -> host:cfg.ports.webui -> pia-tun -> qbittorrent
        extraOptions = [
          "--add-host=host.docker.internal:host-gateway"
        ];
      };

      systemd.services.docker-qui = {
        after = [ "docker-qbittorrent.service" "mnt-pool.mount" ];
        wants = [ "docker-qbittorrent.service" ];
        requires = [ "mnt-pool.mount" ];
      };
    })
  ]);
}
