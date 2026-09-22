{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.newt;
  hl = config.homelab;

  # One Pangolin resource per Service Record (records.nix — shared with
  # caddy.nix so the tunnel path and the LAN path can never drift).
  # Every public resource targets Caddy on this host, which fans out by Host
  # header; exposure = sso becomes Pangolin's SSO auth screen.
  mkResource = name: r: {
    inherit name;
    protocol = "http";
    full-domain = "${name}.${r.domain}";
    # Caddy routes by Host and needs a matching SNI to complete the TLS
    # handshake — traefik would otherwise dial SNI-less (tunnel IP target)
    # and Caddy rejects that.
    tls-server-name = "${name}.${r.domain}";
    targets = [
      {
        hostname = "localhost";
        method = "https";
        port = 443;
      }
    ];
    auth.sso-enabled = r.exposure == "sso";
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
  mkPrivateResource = name: r: {
    inherit name;
    mode = "http";
    enabled = true;
    destination = "localhost";
    destination-port = r.port;
    inherit (r) scheme;
    ssl = true;
    full-domain = "${name}.${r.domain}";
  };

  # Keyed by subdomain: that is the resource's name in Pangolin.
  withExposure =
    exposures:
    lib.mapAttrs' (_: r: lib.nameValuePair r.subdomain r) (
      lib.filterAttrs (_: r: lib.elem r.exposure exposures) hl.records
    );
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
        proxy-resources = lib.mapAttrs mkResource (withExposure [
          "public"
          "sso"
        ]);
        private-resources = lib.mapAttrs mkPrivateResource (withExposure [ "private" ]);
      };
    };
  };
}
