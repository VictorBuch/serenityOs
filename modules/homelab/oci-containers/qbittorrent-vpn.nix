{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.homelab.qbittorrent-vpn;
  user = config.user;
  records = config.homelab.records;
in

{
  options.homelab.qbittorrent-vpn = {
    enable = lib.mkEnableOption "qBittorrent behind PIA WireGuard via pia-tun";

    qui.enable = lib.mkEnableOption "Enable qui modern web UI for qBittorrent";

    mousehole.enable = lib.mkEnableOption "Enable mousehole MAM dynamic seedbox IP updater (shares pia-tun netns)";

    pia.locations = lib.mkOption {
      type = lib.types.str;
      # Two regions so one briefly vanishing from PIA's server list (as
      # de_berlin did on 2026-09-27) doesn't leave nothing to connect to.
      default = "de_berlin,de-frankfurt";
      description = "PIA locations (comma-separated, port-forward capable regions only)";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Host port 8081 is mapped to pia-tun's container:8080.
      homelab.records.qbittorrent = {
        port = 8081;
        exposure = "private";
        openFirewall = true;
        tile = {
          title = "qBittorrent";
          icon = "sh:qbittorrent";
          group = "media";
        };
      };

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
        # Host port comes from the qbittorrent Service Record.
        # mousehole shares this netns, so its port is published here too.
        ports =
          [ "${toString records.qbittorrent.port}:8080" ]
          ++ lib.optional cfg.mousehole.enable "${toString records.mousehole.port}:5010";

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

      # pia-tun exits fatally on transient PIA-side failures (region missing
      # from the server list, auth API down). The default start limit gave
      # up after ~1h and left the whole torrent stack down for days. Retry
      # forever instead, backing off from 10s to 5min between attempts.
      systemd.services.docker-pia-tun = {
        startLimitIntervalSec = 0;
        serviceConfig = {
          RestartSec = "10s";
          RestartSteps = 10;
          RestartMaxDelaySec = "5min";
        };
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
      homelab.records.qui = {
        port = 7476;
        # OIDC handled by qui itself via pocket-id
        exposure = "private";
        openFirewall = true;
        tile = {
          title = "qui";
          icon = "sh:qbittorrent";
          group = "media";
        };
      };

      sops.secrets = {
        "qui/oidc_client_id" = {
          owner = "root";
          group = "root";
        };
        "qui/oidc_client_secret" = {
          owner = "root";
          group = "root";
        };
      };

      sops.templates."qui-oidc-env" = {
        content = ''
          QUI__OIDC_CLIENT_ID=${config.sops.placeholder."qui/oidc_client_id"}
          QUI__OIDC_CLIENT_SECRET=${config.sops.placeholder."qui/oidc_client_secret"}
        '';
        owner = "root";
        group = "root";
        mode = "0400";
      };

      virtualisation.oci-containers.containers.qui = {
        # No semver tags published yet, only `latest`. Pin to digest once stable.
        image = "ghcr.io/autobrr/qui:latest";
        autoStart = true;
        dependsOn = [ "qbittorrent" ];

        ports = [
          "${toString records.qui.port}:7476"
        ];

        volumes = [
          "/var/lib/qui:/config"
          "${config.homelab.mediaDir}/downloads:/downloads:ro"
        ];

        environment = {
          TZ = "Europe/Copenhagen";
          QUI__LOG_LEVEL = "info";

          # OIDC via pocket-id. Client ID/secret come from sops via environmentFiles.
          QUI__OIDC_ENABLED = "true";
          QUI__OIDC_ISSUER = records.pocket-id.url;
          QUI__OIDC_REDIRECT_URL = "${records.qui.url}/api/auth/oidc/callback";
          QUI__OIDC_DISABLE_BUILT_IN_LOGIN = "true";
        };

        environmentFiles = [
          config.sops.templates."qui-oidc-env".path
        ];

        # qui reaches qBittorrent via host bridge -> host:records.qbittorrent.port -> pia-tun -> qbittorrent
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

    (lib.mkIf cfg.mousehole.enable {
      # Published via pia-tun, since mousehole shares its netns.
      homelab.records.mousehole = {
        port = 5010;
        exposure = "private";
        openFirewall = true;
        tile = {
          title = "Mousehole";
          icon = "sh:mousehole";
          group = "media";
        };
      };

      # mousehole runs inside pia-tun's netns so it sees the PIA exit IP/ASN.
      # Cookie is set via mousehole's own web UI on first boot (not via sops);
      # state persists in /var/lib/mousehole across restarts.
      virtualisation.oci-containers.containers.mousehole = {
        image = "tmmrtn/mousehole:latest";
        autoStart = true;
        dependsOn = [ "pia-tun" ];

        volumes = [
          "/var/lib/mousehole:/srv/mousehole"
        ];

        environment = {
          TZ = "Europe/Copenhagen";
        };

        extraOptions = [
          "--network=container:pia-tun"
        ];
      };

      systemd.services.docker-mousehole = {
        after = [ "docker-pia-tun.service" ];
        # Cascade with pia-tun like qbittorrent does — mousehole's network
        # disappears whenever pia-tun restarts.
        bindsTo = [ "docker-pia-tun.service" ];
        partOf = [ "docker-pia-tun.service" ];
      };
    })
  ]);
}
