{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.wannashare;
  dataDir = "/var/lib/wannashare";
  staticDir = "/var/lib/wannashare/static";
  user = "wannashare";
  group = "wannashare";
  port = 8099;

  # Domain configuration
  hasDomain = cfg.domain != null;

  # Check if Caddy is already enabled by another module
  caddyAlreadyEnabled = config.caddy.enable or false;

  # Subdomains
  pocketDomain = "pocket.${cfg.domain}";
  appDomain = "app.${cfg.domain}";
  wildcardDomain = "*.${cfg.domain}";
in
{
  options.wannashare = {
    enable = lib.mkEnableOption "Enables WannaShare PocketBase backend";

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "xyz.online";
      description = ''
        Base domain for WannaShare (e.g., xyz.online).
        This will configure:
        - pocket.<domain> -> PocketBase backend (port ${toString port})
        - app.<domain> -> Static frontend files
        When set, this module will configure its own Caddy reverse proxy
        and Cloudflare tunnel.
      '';
    };

    staticPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/var/lib/wannashare/static";
      description = ''
        Path to the static frontend files for app.<domain>.
        If null, defaults to ${staticDir}.
      '';
    };

    cloudflare = {
      tunnelId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
        description = "Cloudflare tunnel UUID for WannaShare. Required when domain is set.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base WannaShare service configuration (always applied when enabled)
    {
      environment.systemPackages = with pkgs; [
        go
      ];

      users.users.wanna-share-releaser = {
        isNormalUser = true;
        group = "wanna-share-releaser";
        description = "WannaShare Deployment User";
        shell = pkgs.bashInteractive;
        extraGroups = [ "wannashare" ];
      };
      users.groups.wanna-share-releaser = { };

      security.sudo.extraRules = [
        {
          users = [ "wanna-share-releaser" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/systemctl stop wannashare";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/systemctl start wannashare";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      users.groups.${group} = { };
      users.users.${user} = {
        isSystemUser = true;
        group = group;
        home = dataDir;
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0770 ${user} ${group}"
        "d ${dataDir}/pb_data 0750 ${user} ${group}"
        "d ${staticDir} 0755 ${user} ${group}"
      ];

      systemd.services.wannashare = {
        description = "WannaShare PocketBase Backend";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = user;
          Group = group;
          WorkingDirectory = dataDir;
          ExecStart = "${dataDir}/wannashare-backend serve --http=127.0.0.1:${toString port}";
          Restart = "always";
          RestartSec = "5s";

          # Hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ dataDir ];
        };
      };
    }

    # Custom domain configuration (Caddy + Cloudflare tunnel)
    (lib.mkIf hasDomain {
      # Validate that tunnelId is provided when domain is set
      assertions = [
        {
          assertion = cfg.cloudflare.tunnelId != "";
          message = "wannashare.cloudflare.tunnelId must be set when wannashare.domain is configured";
        }
      ];

      # Sops secrets for TLS certificates (wildcard cert for *.domain)
      sops.secrets = {
        "cloudflare/ssl/wannashare_origin_certificate" = {
          owner = "caddy";
          group = "caddy";
        };
        "cloudflare/ssl/wannashare_origin_private_key" = {
          owner = "caddy";
          group = "caddy";
        };
        "cloudflare/wannashare/tunnel_credentials" = {
          owner = "cloudflared";
          group = "cloudflared";
        };
      };

      sops.templates."wannashare-cert.pem" = {
        content = config.sops.placeholder."cloudflare/ssl/wannashare_origin_certificate";
        owner = "caddy";
        group = "caddy";
      };

      sops.templates."wannashare-key.pem" = {
        content = config.sops.placeholder."cloudflare/ssl/wannashare_origin_private_key";
        owner = "caddy";
        group = "caddy";
      };

      # Enable Caddy (mkDefault allows other modules to override)
      services.caddy.enable = lib.mkDefault true;

      # Open firewall ports for Caddy (only if not already managed elsewhere)
      networking.firewall.allowedTCPPorts = lib.mkIf (!caddyAlreadyEnabled) [ 80 443 ];

      # Caddy virtual host for PocketBase backend (pocket.xyz.online)
      services.caddy.virtualHosts.${pocketDomain} = {
        extraConfig = ''
          tls ${config.sops.templates."wannashare-cert.pem".path} ${config.sops.templates."wannashare-key.pem".path}

          request_body {
            max_size 10M
          }
          reverse_proxy http://127.0.0.1:${toString port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
            transport http {
              read_timeout 360s
            }
          }
        '';
      };

      # Caddy virtual host for Flutter web frontend (app.xyz.online)
      services.caddy.virtualHosts.${appDomain} = {
        extraConfig =
          let
            staticFilesPath = if cfg.staticPath != null then cfg.staticPath else staticDir;
          in
          ''
            tls ${config.sops.templates."wannashare-cert.pem".path} ${config.sops.templates."wannashare-key.pem".path}

            root * ${staticFilesPath}

            # Flutter web app specific headers
            header {
              # Security headers
              X-Content-Type-Options "nosniff"
              X-Frame-Options "SAMEORIGIN"
              Referrer-Policy "strict-origin-when-cross-origin"

              # CORS headers for Flutter web
              Access-Control-Allow-Origin "*"
              Access-Control-Allow-Methods "GET, POST, OPTIONS"
              Access-Control-Allow-Headers "Content-Type, Authorization"

              # Cache control for Flutter web assets
              # Main files (index.html, flutter_bootstrap.js) - no cache
              # Versioned assets (.js, .wasm with hashes) - long cache
            }

            # No cache for main entry points (they reference versioned assets)
            @noCache {
              path /index.html /flutter_bootstrap.js /flutter_service_worker.js /manifest.json /version.json
            }
            header @noCache Cache-Control "no-cache, no-store, must-revalidate"

            # Long cache for versioned/hashed assets
            @versionedAssets {
              path *.js *.wasm *.map
              not path /flutter_bootstrap.js /flutter_service_worker.js
            }
            header @versionedAssets Cache-Control "public, max-age=31536000, immutable"

            # Cache for fonts and images
            @staticAssets {
              path *.ttf *.otf *.woff *.woff2 *.png *.jpg *.jpeg *.gif *.svg *.ico *.webp
            }
            header @staticAssets Cache-Control "public, max-age=31536000, immutable"

            # Handle canvaskit and skwasm files
            @canvaskit {
              path /canvaskit/*
            }
            header @canvaskit Cache-Control "public, max-age=31536000, immutable"

            # Proper MIME types for Flutter web
            @wasm path *.wasm
            header @wasm Content-Type "application/wasm"

            # Enable compression
            encode gzip zstd

            file_server

            # SPA fallback - serve index.html for non-file routes (Flutter Router)
            try_files {path} /index.html
          '';
      };

      # Cloudflare tunnel for WannaShare (separate tunnel for this domain)
      # Uses wildcard to route all subdomains through the tunnel
      services.cloudflared = {
        enable = true;
        tunnels.${cfg.cloudflare.tunnelId} = {
          credentialsFile = config.sops.secrets."cloudflare/wannashare/tunnel_credentials".path;
          default = "http_status:404";
          ingress = {
            ${wildcardDomain} = {
              service = "https://127.0.0.1:443";
              originRequest = {
                originServerName = wildcardDomain;
              };
            };
          };
        };
      };
    })
  ]);
}
