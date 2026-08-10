{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.newt;
  hl = config.homelab;

  # One Pangolin resource per edge service (see edge-services.nix — shared
  # with caddy.nix so the tunnel path and the LAN path can never drift).
  # Every resource targets Caddy on this host, which fans out by Host header;
  # `protected` becomes Pangolin's SSO auth screen on the public path.
  mkResource = domain: name: service: {
    inherit name;
    protocol = "http";
    full-domain = "${name}.${domain}";
    # Caddy routes by Host and needs a matching SNI to complete the TLS
    # handshake — traefik would otherwise dial SNI-less (tunnel IP target)
    # and Caddy rejects that.
    tls-server-name = "${name}.${domain}";
    targets = [
      {
        hostname = "localhost";
        method = "https";
        port = 443;
      }
    ];
    auth.sso-enabled = service.protected or false;
  };

  # Private resources bypass Caddy and hit the service port directly —
  # the WG tunnel already encrypts, and skipping Caddy avoids the SNI dance.
  # full-domain reuses the public name so the same URL works with the
  # client connected (tunnel) and at home (AdGuard rewrite -> Caddy).
  #
  # `ssl` and `scheme` are INDEPENDENT legs, not one passthrough:
  #   ssl    -> client-side TLS. Pangolin terminates it and serves the
  #             *.<domain> wildcard cert (prefer_wildcard_cert on wash).
  #             Must be true: the browser opens https://<name>.<domain>
  #             either way, and a plaintext upstream answering a ClientHello
  #             is exactly SSL_ERROR_RX_RECORD_TOO_LONG.
  #   scheme -> how Pangolin dials the upstream on mal.
  urlPort = url: lib.toInt (builtins.head (builtins.match ".*:([0-9]+)" url));
  mkPrivateResource = domain: name: service: {
    inherit name;
    mode = "http";
    enabled = true;
    destination = "localhost";
    destination-port = urlPort service.url;
    scheme = if service.https or false then "https" else "http";
    ssl = true;
    full-domain = "${name}.${domain}";
  };

  isPrivate = _: s: s.private or false;
  publicOf = svcs: lib.filterAttrs (n: s: !(isPrivate n s)) svcs;
  privateOf = svcs: lib.filterAttrs isPrivate svcs;
in
{
  options.homelab.newt = {
    enable = lib.mkEnableOption "Newt tunnel client (Pangolin site connector on wash)";

    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "https://pangolin.${hl.domain}";
      description = "Pangolin server endpoint the tunnel connects to";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "pangolin/newt_id" = { };
      "pangolin/newt_secret" = { };
    };

    sops.templates."newt.env" = {
      content = ''
        NEWT_ID=${config.sops.placeholder."pangolin/newt_id"}
        NEWT_SECRET=${config.sops.placeholder."pangolin/newt_secret"}
      '';
      mode = "0400";
      # EnvironmentFile content changes don't restart units on their own
      restartUnits = [ "newt.service" ];
    };

    # Outbound-only: wss to pangolin + WireGuard to gerbil, no firewall ports needed
    services.newt = {
      enable = true;
      settings.endpoint = cfg.endpoint;
      environmentFile = config.sops.templates."newt.env".path;

      blueprint = {
        proxy-resources =
          lib.mapAttrs (mkResource hl.domain) (publicOf config.homelab.edge.services)
          // lib.mapAttrs (mkResource hl.smoothlessDomain) (
            publicOf config.homelab.edge.wannashareServices
          );

        private-resources = lib.mapAttrs (mkPrivateResource hl.domain) (
          privateOf config.homelab.edge.services
        );
      };
    };
  };
}
