{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.caddy;
  hl = config.homelab;
  domain = hl.domain;

  services = {
    auth = {
      url = "http://127.0.0.1:3002";
      https = false;
      protected = false;
    };
    id = {
      # Pocket ID
      url = "http://127.0.0.1:1411";
      https = false;
      protected = false;
    };
    dashboard = {
      url = "http://127.0.0.1:8080";
      https = false;
      protected = true;
    };
    ma = {
      # Music Assistant
      url = "http://127.0.0.1:8095";
      https = false;
      protected = true;
    };
    files = {
      url = "http://127.0.0.1:3030";
      https = false;
      protected = true;
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
    };
    ad = {
      url = "http://127.0.0.1:3000";
      https = false;
      protected = true;
    };
    shows = {
      # Sonarr
      url = "http://127.0.0.1:8989";
      https = false;
      protected = true;
    };
    movies = {
      # Radarr
      url = "http://127.0.0.1:7878";
      https = false;
      protected = true;
    };
    music = {
      # Lidarr
      url = "http://127.0.0.1:8686";
      https = false;
      protected = true;
    };
    books = {
      # Readarr
      url = "http://127.0.0.1:8787";
      https = false;
      protected = true;
    };
    prowlarr = {
      url = "http://127.0.0.1:9696";
      https = false;
      protected = true;
    };
    subtitles = {
      # Bazarr
      url = "http://127.0.0.1:6767";
      https = false;
      protected = true;
    };
    downloads = {
      # Deluge
      url = "http://127.0.0.1:8112";
      https = false;
      protected = true;
    };
    subscriptions = {
      # Wallos
      url = "http://127.0.0.1:8282";
      https = false;
      protected = true;
    };
    photos = {
      # Immich
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
    nextcloud = {
      url = "unix//run/phpfpm/nextcloud.sock";
      https = false;
      protected = false;
      isPhpFpm = true;
    };
    git = {
      url = "http://127.0.0.1:3004";
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
    wannashare = {
      # WannaShare PocketBase backend
      url = "http://127.0.0.1:8099";
      https = false;
      protected = false; # PocketBase handles its own auth
      isPocketBase = true;
    };
    app = {
      # WannaShare Flutter Web App
      url = "";
      https = false;
      protected = false;
      isStaticFiles = true;
      staticPath = "/var/lib/wannashare/web";
    };
  };

  # --- HELPER FUNCTIONS ---
  mkHost = subdomain: service: {
    name = "${subdomain}.${domain}";
    value.extraConfig = ''

      tls ${config.sops.templates."cf-cert.pem".path} ${config.sops.templates."cf-key.pem".path}

      ${
        if service.protected then
          ''
            forward_auth http://127.0.0.1:3002 {
              uri /api/auth/caddy
              copy_headers Remote-User Remote-Email Remote-Name Remote-Groups
            }
          ''
        else
          ""
      }

      ${
        if service.isPhpFpm or false then
          let
            nextcloudPackage =
              if config.nextcloud.enable then config.services.nextcloud.package else pkgs.nextcloud31;
          in
          ''
            # Nextcloud-specific configuration
            root * ${nextcloudPackage}

            # Security headers
            header {
              Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
              Referrer-Policy "no-referrer"
              X-Content-Type-Options "nosniff"
              X-Download-Options "noopen"
              X-Frame-Options "SAMEORIGIN"
              X-Permitted-Cross-Domain-Policies "none"
              X-Robots-Tag "noindex, nofollow"
              -X-Powered-By
            }

            # WebDAV redirects for CardDAV and CalDAV
            redir /.well-known/carddav /remote.php/dav 301
            redir /.well-known/caldav /remote.php/dav 301
            redir /.well-known/webfinger /index.php/.well-known/webfinger 301
            redir /.well-known/nodeinfo /index.php/.well-known/nodeinfo 301

            # Enable large file uploads
            request_body {
              max_size 16G
            }

            # PHP-FPM configuration for Nextcloud
            php_fastcgi ${service.url} {
              root ${nextcloudPackage}
              env front_controller_active true
              env modHeadersAvailable true
            }

            # Serve static files
            file_server
          ''
        else if service.isStaticFiles or false then
          ''
            # Serve static files
            root * ${service.staticPath}
            file_server
          ''
        else if service.https then
          ''
            reverse_proxy ${service.url} {
              header_up Host {host}
              header_up X-Real-IP {remote}
              header_up X-Forwarded-For {remote}
              header_up X-Forwarded-Proto {scheme}
              transport http {
                tls_insecure_skip_verify
              }
            }
          ''
        else if service.isPocketBase or false then
          ''
            request_body {
              max_size 10M
            }

            # Route /api/* directly to backend
            handle /api/* {
              reverse_proxy ${service.url} {
                header_up Host {host}
                header_up X-Real-IP {remote}
                header_up X-Forwarded-For {remote}
                header_up X-Forwarded-Proto {scheme}
                transport http {
                  read_timeout 360s
                }
              }
            }

            # Route /_/* directly to backend (PocketBase admin UI)
            handle /_/* {
              reverse_proxy ${service.url} {
                header_up Host {host}
                header_up X-Real-IP {remote}
                header_up X-Forwarded-For {remote}
                header_up X-Forwarded-Proto {scheme}
                transport http {
                  read_timeout 360s
                }
              }
            }

            # Redirect root to /_/
            redir / /_/ permanent
          ''
        else
          ''
            reverse_proxy ${service.url} {
              header_up Host {host}
              header_up X-Real-IP {remote}
              header_up X-Forwarded-For {remote}
              header_up X-Forwarded-Proto {scheme}
            }
          ''

      }
    '';
  };
in
{
  options.caddy = {
    enable = lib.mkEnableOption "Enables Caddy reverse proxy";
  };

  config = lib.mkIf cfg.enable {

    sops.templates."cf-cert.pem" = {
      content = config.sops.placeholder."cloudflare/ssl/origin_certificate";
      owner = config.services.caddy.user;
      group = config.services.caddy.group;
    };
    sops.templates."cf-key.pem" = {
      content = config.sops.placeholder."cloudflare/ssl/origin_private_key";
      owner = config.services.caddy.user;
      group = config.services.caddy.group;
    };

    sops.secrets = {
      "cloudflare/ssl/origin_certificate" = {
        owner = config.services.caddy.user;
        group = config.services.caddy.group;
      };
      "cloudflare/ssl/origin_private_key" = {
        owner = config.services.caddy.user;
        group = config.services.caddy.group;
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];



    services.caddy = {
      enable = true;
      email = "victorbuch@protonmail.com";
      virtualHosts = (lib.mapAttrs' mkHost services);
    };
  };
}
