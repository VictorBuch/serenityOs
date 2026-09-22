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

  # Every routed Service Record (records.nix), keyed by subdomain per domain.
  recordsOn =
    hostDomain:
    lib.mapAttrs' (_: r: lib.nameValuePair r.subdomain r) (
      lib.filterAttrs (_: r: r.exposure != "lan" && r.domain == hostDomain) hl.records
    );

  # --- HELPER FUNCTIONS ---
  # Client IP: use {client_ip}, never {remote_host}. newt targets Caddy at
  # localhost:443, so {remote_host} is 127.0.0.1 for every tunnelled request —
  # it would stamp the loopback address onto all internet traffic and defeat
  # any backend check that keys on the client address (Home Assistant's
  # `local_only` webhooks, for one). {client_ip} resolves through the global
  # `trusted_proxies` allowlist below, so it yields the real client from the
  # tunnel and the peer address for LAN-direct requests, and a LAN client
  # cannot forge it because its own address is not in the allowlist.
  proxy = r: transport: ''
    reverse_proxy ${r.upstream} {
      header_up Host ${r.caddy.upstreamHost}
      ${lib.optionalString (r.caddy.upstreamOrigin != null) "header_up Origin ${r.caddy.upstreamOrigin}"}
      header_up X-Real-IP {client_ip}
      header_up X-Forwarded-For {client_ip}
      header_up X-Forwarded-Proto {scheme}
      ${lib.optionalString (transport != "") "transport http {\n    ${transport}\n  }"}
    }
  '';

  # Request-handling body for one record, independent of domain/TLS.
  serviceBody =
    r:
    if r.kind == "static" then
      ''
        # Serve static files
        root * ${r.root}
        file_server
      ''
    else if r.kind == "pocketbase" then
      ''
        request_body {
          max_size 10M
        }

        # Route /api/* directly to backend
        handle /api/* {
          ${proxy r "read_timeout 360s"}
        }

        # Route /_/* directly to backend (PocketBase admin UI)
        handle /_/* {
          ${proxy r "read_timeout 360s"}
        }

        # Redirect root to /_/
        redir / /_/ permanent
      ''
    else
      proxy r (lib.optionalString (r.scheme == "https") "tls_insecure_skip_verify");

  # One named matcher + handle block per record inside a wildcard vhost.
  # `caddy.extraRoutes` is raw Caddyfile placed ahead of the record's own body,
  # so a service can claim specific paths before the catch-all proxy. The body
  # then moves into a nested `handle` so a request can only ever take one of
  # the two.
  mkHandle =
    hostDomain: subdomain: r:
    let
      body =
        if r.caddy.extraRoutes != null then
          ''
            ${r.caddy.extraRoutes}
            handle {
              ${serviceBody r}
            }
          ''
        else
          serviceBody r;
    in
    ''
      @${subdomain} host ${subdomain}.${hostDomain}
      handle @${subdomain} {
        ${body}
      }
    '';

  mkWildcardHost = hostDomain: {
    useACMEHost = hostDomain;
    extraConfig =
      lib.concatStrings (lib.mapAttrsToList (mkHandle hostDomain) (recordsOn hostDomain))
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

    # Sonarr/Radarr keys for the dashboard cover-proxy routes (see the
    # `glance` record in dashboard.nix). Caddy reads them as
    # {env.SONARR_API_KEY} / {env.RADARR_API_KEY} so they stay out of the Nix
    # store and out of the dashboard HTML.
    sops.templates."caddy.env" = {
      content = ''
        SONARR_API_KEY=${config.sops.placeholder."sonarr_api_key"}
        RADARR_API_KEY=${config.sops.placeholder."radarr_api_key"}
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
      environmentFile = config.sops.templates."caddy.env".path;
      # Traefik on wash dials mal without SNI (tunnel target is an IP);
      # serve the main wildcard vhost for SNI-less TLS handshakes.
      globalConfig = ''
        default_sni fallback.${domain}
        servers {
          trusted_proxies static ::1/128 127.0.0.1/32
        }
      '';
      virtualHosts = {
        "*.${domain}" = mkWildcardHost domain;
        "*.${smoothlessDomain}" = mkWildcardHost smoothlessDomain;
      };
    };
  };
}
