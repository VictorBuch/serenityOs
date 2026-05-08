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
        default = 8081;
        description = "Host port for qBittorrent WebUI (mapped from pia-tun container:8080). Default 8081 because glance owns 8080.";
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
          # 100.64.0.0/10 is Tailscale's CGNAT range — required so packets
          # from tailnet peers (e.g. Inara → mal:8081) aren't dropped by
          # pia-tun's killswitch after DNAT into the container netns.
          LOCAL_NETWORKS = "192.168.0.0/24,10.0.0.0/24,100.64.0.0/10";
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
        # NOTE: pinned to 5.1.x because v5.x is not yet whitelisted by major
        # private trackers (FileList, HDB, PTP, etc.). They review and approve
        # new client versions slowly. Bumping past this without checking each
        # tracker's allowlist breaks announces with "client not on whitelist".
        # Check tracker rules pages before raising this.
        image = "lscr.io/linuxserver/qbittorrent:5.1.4";
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
        # Bind lifecycle to pia-tun: qbittorrent shares its netns via
        # --network=container:pia-tun, so any pia-tun restart strands
        # qbittorrent's network. BindsTo stops qbittorrent when pia-tun
        # stops; PartOf restarts it whenever pia-tun is restarted.
        bindsTo = [ "docker-pia-tun.service" ];
        partOf = [ "docker-pia-tun.service" ];
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
        # Follow qbittorrent's lifecycle so a pia-tun restart cascades
        # cleanly: pia-tun -> qbittorrent (BindsTo/PartOf) -> qui (PartOf).
        partOf = [ "docker-qbittorrent.service" ];
      };
    })
  ]);
}
