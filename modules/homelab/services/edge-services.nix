# Single source of truth for every service exposed at the edge.
#
# Consumed by BOTH proxies so the home path and the away path can never
# drift apart:
#   - caddy.nix     -> one handle block per service (LAN-direct path)
#   - newt.nix      -> one Pangolin resource per service via the newt
#                      blueprint (tunnel path), with `protected` mapped to
#                      Pangolin's SSO auth screen
#
# Adding a service here is all that's needed to expose it on both paths.
#
# Per-service attributes:
#   url            backend URL for Caddy (empty for static sites)
#   protected      true -> Pangolin SSO auth screen on the tunnel path
#                  (LAN-direct traffic is never gated)
#   private        true -> NOT published on the internet; becomes a Pangolin
#                  private resource, reachable only with a connected Pangolin
#                  client (olm) or on the LAN. Same URL both ways.
#   https          backend speaks TLS (self-signed; Caddy skips verify)
#   isStaticFiles / isPocketBase / staticPath / upstreamHost /
#   upstreamOrigin  special-case routing handled by caddy.nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.homelab.edge = {
    services = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Edge services on <name>.<homelab.domain>";
    };
    wannashareServices = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Edge services on <name>.<homelab.smoothlessDomain>";
    };
  };

  config.homelab.edge = {
    services = {
      id = {
        # Pocket ID — the OIDC IdP itself; must never sit behind an auth
        # screen or Pangolin/qui/fileflows/hermes logins deadlock
        url = "http://127.0.0.1:1411";
        https = false;
        protected = false;
      };
      dashboard = {
        url = "http://127.0.0.1:8080";
        https = false;
        protected = true;
        # Glance's Sonarr/Radarr widgets emit poster <img> tags that the
        # *browser* loads, so they cannot point at the arrs' loopback ports.
        # These same-origin paths proxy the covers and inject the API key
        # server-side, which also keeps the keys out of the dashboard HTML.
        # Paired with `cover-proxy` in dashboard.nix.
        extraRoutes = ''
          handle_path /covers/sonarr/* {
            rewrite * /api/v3/mediacover{path}
            reverse_proxy http://127.0.0.1:8989 {
              header_up X-Api-Key {env.SONARR_API_KEY}
            }
          }
          handle_path /covers/radarr/* {
            rewrite * /api/v3/mediacover{path}
            reverse_proxy http://127.0.0.1:7878 {
              header_up X-Api-Key {env.RADARR_API_KEY}
            }
          }
        '';
      };
      ma = {
        # Music Assistant
        url = "http://127.0.0.1:8095";
        https = false;
        protected = true;
      };
      files = {
        # copyparty. Public on purpose: it authenticates users itself, and its
        # /share links must be reachable by people who have no SSO account —
        # a Pangolin auth screen would stop the recipient before copyparty
        # ever sees the request.
        url = "http://127.0.0.1:3923";
        https = false;
        protected = false;
      };
      status = {
        url = "http://127.0.0.1:3001";
        https = false;
        protected = true;
      };
      crafty = {
        url = "https://127.0.0.1:8443";
        https = true;
        protected = true;
        private = true;
      };
      ad = {
        url = "http://127.0.0.1:3000";
        https = false;
        protected = true;
        private = true;
      };
      shows = {
        # Sonarr
        url = "http://127.0.0.1:8989";
        https = false;
        protected = true;
        private = true;
      };
      movies = {
        # Radarr
        url = "http://127.0.0.1:7878";
        https = false;
        protected = true;
        private = true;
      };
      music = {
        # Lidarr
        url = "http://127.0.0.1:8686";
        https = false;
        protected = true;
        private = true;
      };
      books = {
        # Readarr
        url = "http://127.0.0.1:8787";
        https = false;
        protected = true;
        private = true;
      };
      prowlarr = {
        url = "http://127.0.0.1:9696";
        https = false;
        protected = true;
        private = true;
      };
      subtitles = {
        # Bazarr
        url = "http://127.0.0.1:6767";
        https = false;
        protected = true;
        private = true;
      };
      qbittorrent = {
        # qBittorrent WebUI (host port 8081 -> pia-tun -> qbittorrent:8080)
        url = "http://127.0.0.1:8081";
        https = false;
        protected = true;
        private = true;
      };
      qui = {
        # qui modern web UI for qBittorrent
        url = "http://127.0.0.1:7476";
        https = false;
        protected = false; # OIDC handled by qui itself via pocket-id
        private = true;
      };
      mousehole = {
        # MAM dynamic seedbox IP updater (published via pia-tun on host:5010)
        url = "http://127.0.0.1:5010";
        https = false;
        protected = true;
        private = true;
      };
      subscriptions = {
        # Wallos
        url = "http://127.0.0.1:8282";
        https = false;
        protected = true;
      };
      photos = {
        # Immich — mobile app talks to the API directly; own auth
        url = "http://127.0.0.1:2283";
        https = false;
        protected = false;
      };
      cooking = {
        # Mealie
        url = "http://127.0.0.1:9000";
        https = false;
        protected = false;
      };
      jellyfin = {
        url = "http://127.0.0.1:8096";
        https = false;
        protected = false;
      };
      plex = {
        url = "http://127.0.0.1:32400";
        https = false;
        protected = false;
      };
      request = {
        url = "http://127.0.0.1:5055";
        https = false;
        protected = false;
      };
      audiobooks = {
        url = "http://127.0.0.1:8004";
        https = false;
        protected = false;
      };
      git = {
        url = "http://127.0.0.1:3004";
        https = false;
        protected = false;
      };
      cv = {
        # Reactive Resume
        url = "http://127.0.0.1:3200";
        https = false;
        protected = false;
      };
      tools = {
        # IT Tools - static site
        url = "";
        https = false;
        protected = true;
        isStaticFiles = true;
        staticPath = "${pkgs.it-tools}/lib";
      };
      paperless = {
        # Paperless-ngx document management
        url = "http://127.0.0.1:28981";
        https = false;
        protected = true;
      };
      invoice = {
        # InvoicePlane
        url = "http://127.0.0.1:8380";
        https = false;
        protected = false;
      };
      fileflows = {
        # FileFlows media processing
        url = "http://127.0.0.1:19200";
        https = false;
        protected = false; # OIDC handled by FileFlows itself
        private = true;
      };
      ntfy = {
        # ntfy-sh push notifications
        url = "http://127.0.0.1:8033";
        https = false;
        protected = false; # Needs to be accessible for push clients
      };
      lute = {
        # Lute v3 language learning
        url = "http://127.0.0.1:5001";
        https = false;
        protected = true;
      };
      learn = {
        # tv-learn immersion language-learning app
        url = "http://127.0.0.1:3006";
        https = false;
        protected = true;
      };
      home = {
        # Home Assistant (port 8124; 8123 is taken by crafty)
        url = "http://127.0.0.1:8124";
        https = false;
        protected = false; # HA has its own auth; companion app/API need direct access
      };
    }
    # Quartz wiki (homelab.notes) — static files built to /var/www/notes.
    // lib.optionalAttrs (config.homelab.notes.enable && config.homelab.notes.publishWiki) {
      notes = {
        url = "";
        https = false;
        protected = false;
        isStaticFiles = true;
        staticPath = "/var/www/notes";
      };
    }
    # Hermes web dashboard (agent.<domain>). Binds loopback with its own auth
    # off, so its auth screen lives on the Pangolin resource. Its DNS-rebind
    # guard rejects any non-loopback Host header, hence upstreamHost/Origin.
    // lib.optionalAttrs (config.homelab.hermes.enable && config.homelab.hermes.web.enable) {
      agent = {
        url = "http://127.0.0.1:${toString config.homelab.hermes.web.port}";
        https = false;
        protected = true;
        upstreamHost = "localhost";
        upstreamOrigin = "https://localhost";
      };
    };

    wannashareServices = {
      db-wannashare = {
        # WannaShare PocketBase backend (database)
        url = "http://127.0.0.1:8099";
        https = false;
        protected = false;
        isPocketBase = true;
      };
      wannashare = {
        # WannaShare Nuxt SSR Web App (node-server on port 3005)
        url = "http://127.0.0.1:3005";
        https = false;
        protected = false;
      };
      suboptimal = {
        url = "http://127.0.0.1:3232";
        https = false;
        protected = false;
      };
    };
  };
}
