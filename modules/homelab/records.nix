# Service Records and Port Reservations (see CONTEXT.md).
#
# A Service Record is one endpoint a homelab service exposes. The service's own
# module declares it inside its enable gate; Caddy, newt/Pangolin, the glance
# dashboard and the firewall all derive from it, so no port or subdomain is
# written twice.
#
# Every port a module listens on is reserved under `homelab.ports`, exposed or
# not. Records reserve their own port; a module adds internal ones by hand.
# Two owners claiming one port fails evaluation instead of crash-looping a
# unit at runtime.
{
  config,
  lib,
  ...
}:
let
  hl = config.homelab;
  inherit (lib) mkOption types;

  tileGroups = [
    "media"
    "infrastructure"
    "productivity"
  ];

  recordType = types.submodule (
    { name, config, ... }:
    {
      options = {
        subdomain = mkOption {
          type = types.str;
          default = name;
          description = "Served at <subdomain>.<domain>";
        };
        domain = mkOption {
          type = types.str;
          default = hl.domain;
        };
        kind = mkOption {
          type = types.enum [
            "proxy"
            "pocketbase"
            "static"
          ];
          default = "proxy";
          description = "proxy: reverse proxy to host:port. pocketbase: /api and /_ only. static: file_server from `root`.";
        };
        root = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Directory served when kind = static";
        };
        port = mkOption {
          type = types.nullOr types.port;
          default = null;
        };
        host = mkOption {
          type = types.str;
          default = "127.0.0.1";
        };
        scheme = mkOption {
          type = types.enum [
            "http"
            "https"
          ];
          default = "http";
          description = "How the backend is dialed. https backends are self-signed; verification is skipped.";
        };
        exposure = mkOption {
          type = types.enum [
            "public"
            "sso"
            "private"
            "lan"
          ];
          default = "sso";
          description = ''
            public:  on the internet, no auth screen (the app authenticates itself)
            sso:     on the internet behind Pangolin's SSO auth screen
            private: Pangolin private resource; only with a connected client or on the LAN
            lan:     no edge route at all; reached at http://<nixosIp>:<port>, firewall opened
            LAN-direct traffic through Caddy is never gated.
          '';
        };
        openFirewall = mkOption {
          type = types.bool;
          default = false;
          description = "Open `port` on the LAN firewall. Implied by exposure = lan.";
        };
        tile = mkOption {
          default = null;
          type = types.nullOr (
            types.submodule {
              options = {
                title = mkOption { type = types.str; };
                icon = mkOption { type = types.str; };
                group = mkOption { type = types.enum tileGroups; };
                check = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Health-check the backend. Always off without a port.";
                };
              };
            }
          );
        };
        caddy = {
          extraRoutes = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = "Raw Caddyfile placed ahead of the proxy, for claiming specific paths";
          };
          upstreamHost = mkOption {
            type = types.str;
            default = "{host}";
          };
          upstreamOrigin = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };

        url = mkOption {
          type = types.str;
          readOnly = true;
          description = "Where a person opens this endpoint";
        };
        upstream = mkOption {
          type = types.str;
          readOnly = true;
          description = "Where Caddy, Pangolin and health checks dial the backend";
        };
      };

      config = {
        url =
          if config.exposure == "lan" then
            "http://${hl.nixosIp}:${toString config.port}"
          else
            "https://${config.subdomain}.${config.domain}";
        upstream = "${config.scheme}://${config.host}:${toString config.port}";
      };
    }
  );

  records = hl.records;

  reservations = lib.concatLists (
    lib.mapAttrsToList (owner: ports: map (port: { inherit owner port; }) (lib.unique ports)) hl.ports
  );
  portClashes = lib.filterAttrs (_: owners: lib.length owners > 1) (
    lib.groupBy' (acc: r: acc ++ [ r.owner ]) [ ] (r: toString r.port) reservations
  );

  routed = lib.filterAttrs (_: r: r.exposure != "lan") records;
  hostClashes = lib.filterAttrs (_: names: lib.length names > 1) (
    lib.groupBy' (acc: n: acc ++ [ n ]) [ ] (n: "${routed.${n}.subdomain}.${routed.${n}.domain}") (
      lib.attrNames routed
    )
  );
in
{
  options.homelab = {
    records = mkOption {
      type = types.attrsOf recordType;
      default = { };
      description = "Service Records, keyed by service name";
    };
    ports = mkOption {
      type = types.attrsOf (types.listOf types.port);
      default = { };
      description = "Port Reservations, keyed by owner";
    };
  };

  config = {
    homelab.ports = lib.mapAttrs (_: r: [ r.port ]) (lib.filterAttrs (_: r: r.port != null) records);

    networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: r: r.port) (
      lib.filterAttrs (_: r: r.port != null && (r.openFirewall || r.exposure == "lan")) records
    );

    assertions =
      lib.mapAttrsToList (port: owners: {
        assertion = false;
        message = "homelab.ports: port ${port} is reserved by ${lib.concatStringsSep ", " owners}";
      }) portClashes
      ++ lib.mapAttrsToList (host: names: {
        assertion = false;
        message = "homelab.records: ${host} is claimed by ${lib.concatStringsSep ", " names}";
      }) hostClashes
      ++ lib.mapAttrsToList (name: r: {
        assertion = if r.kind == "static" then r.root != null else r.port != null;
        message = "homelab.records.${name}: kind = ${r.kind} needs ${
          if r.kind == "static" then "root" else "port"
        }";
      }) records;
  };
}
