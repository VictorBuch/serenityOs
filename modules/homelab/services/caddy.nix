{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.homelab.caddy;
  hl = config.homelab;
  domain = hl.domain;
  smoothlessDomain = hl.smoothlessDomain;

  # Service definitions live in edge-services.nix — shared with newt.nix so
  # the LAN path (Caddy) and tunnel path (Pangolin resources) never drift.
  edge = config.homelab.edge;

  # --- HELPER FUNCTIONS ---
  # Request-handling body for one service, independent of domain/TLS.
  serviceBody =
    service:
    if service.isStaticFiles or false then
      ''
        # Serve static files
        root * ${service.staticPath}
        file_server
      ''
    else if service.isPocketBase or false then
      ''
        request_body {
          max_size 10M
        }

        # Route /api/* directly to backend
        handle /api/* {
          reverse_proxy ${service.url} {
            header_up Host ${service.upstreamHost or "{host}"}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            transport http {
              read_timeout 360s
            }
          }
        }

        # Route /_/* directly to backend (PocketBase admin UI)
        handle /_/* {
          reverse_proxy ${service.url} {
            header_up Host ${service.upstreamHost or "{host}"}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            transport http {
              read_timeout 360s
            }
          }
        }

        # Redirect root to /_/
        redir / /_/ permanent
      ''
    else if service.https then
      ''
        reverse_proxy ${service.url} {
          header_up Host ${service.upstreamHost or "{host}"}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
          transport http {
            tls_insecure_skip_verify
          }
        }
      ''
    else
      ''
        reverse_proxy ${service.url} {
          header_up Host ${service.upstreamHost or "{host}"}
          ${lib.optionalString (service ? upstreamOrigin) "header_up Origin ${service.upstreamOrigin}"}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }
      '';

  # One named matcher + handle block per service inside a wildcard vhost.
  mkHandle = hostDomain: name: service: ''
    @${name} host ${name}.${hostDomain}
    handle @${name} {
      ${serviceBody service}
    }
  '';

  mkWildcardHost = hostDomain: svcs: {
    useACMEHost = hostDomain;
    extraConfig =
      lib.concatStrings (lib.mapAttrsToList (mkHandle hostDomain) svcs)
      + ''
        # Unknown subdomain: close the connection
        handle {
          abort
        }
      '';
  };
in
{
  options.homelab.caddy = {
    enable = lib.mkEnableOption "Enables Caddy reverse proxy";
  };

  config = lib.mkIf cfg.enable {

    sops.secrets."cloudflare/api_token" = { };
    sops.templates."acme-cf.env" = {
      content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/api_token"}
      '';
      mode = "0400";
    };

    # Wildcard certs via Let's Encrypt DNS-01 (lego + Cloudflare API).
    # Replaces the old Cloudflare origin certificates, which are only
    # trusted behind Cloudflare's proxy.
    security.acme = {
      acceptTerms = true;
      defaults.email = "victorbuch@protonmail.com";
      certs."${domain}" = {
        domain = "*.${domain}";
        extraDomainNames = [ domain ];
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."acme-cf.env".path;
        group = config.services.caddy.group;
        reloadServices = [ "caddy" ];
      };
      certs."${smoothlessDomain}" = {
        domain = "*.${smoothlessDomain}";
        extraDomainNames = [ smoothlessDomain ];
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."acme-cf.env".path;
        group = config.services.caddy.group;
        reloadServices = [ "caddy" ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.caddy = {
      enable = true;
      email = "victorbuch@protonmail.com";
      # Traefik on wash dials mal without SNI (tunnel target is an IP);
      # serve the main wildcard vhost for SNI-less TLS handshakes.
      globalConfig = ''
        default_sni fallback.${domain}
      '';
      virtualHosts = {
        "*.${domain}" = mkWildcardHost domain edge.services;
        "*.${smoothlessDomain}" = mkWildcardHost smoothlessDomain edge.wannashareServices;
      };
    };
  };
}
