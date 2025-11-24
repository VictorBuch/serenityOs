# modules/homelab/oci-containers/pocket-id.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.pocket-id-oci;
  hl = config.homelab;
  domain = hl.domain;
in

{
  options.pocket-id-oci = {
    enable = lib.mkEnableOption "Enables Pocket ID authentication service";

    appUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://id.${domain}";
      description = "The URL where Pocket ID will be accessible (must be HTTPS)";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 1411;
      description = "Port for Pocket ID service";
    };

    trustProxy = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Trust proxy headers (enable when behind reverse proxy)";
    };

    puid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "Process user ID";
    };

    pgid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "Process group ID";
    };
  };

  config = lib.mkIf cfg.enable {

    # Firewall rules - allow access to Pocket ID service
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Create data directory for Pocket ID
    systemd.tmpfiles.rules = [
      "d /var/lib/pocket-id 755 root root"
    ];

    # Pocket ID container
    virtualisation.oci-containers.containers.pocket-id = {
      image = "ghcr.io/pocket-id/pocket-id:v1.15.0";
      autoStart = true;

      ports = [
        "${toString cfg.port}:1411"
      ];

      volumes = [
        "/var/lib/pocket-id:/app/data"
      ];

      environmentFiles = [
        config.sops.templates."pocket-id-env".path
      ];

      environment = {
        "APP_URL" = cfg.appUrl;
        "TRUST_PROXY" = lib.boolToString cfg.trustProxy;
        "PUID" = toString cfg.puid;
        "PGID" = toString cfg.pgid;
        "TZ" = "Europe/Copenhagen";
      };

      # Optional healthcheck
      extraOptions = [
        "--health-cmd=/app/pocket-id healthcheck"
        "--health-interval=1m30s"
        "--health-timeout=5s"
        "--health-retries=2"
        "--health-start-period=10s"
      ];
    };

    # Create environment file template for Pocket ID with encryption key
    sops.templates."pocket-id-env" = {
      content = ''
        ENCRYPTION_KEY=${config.sops.placeholder."pocket-id/encryption_key"}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # SOPS secrets configuration
    sops.secrets = {
      "pocket-id/encryption_key" = {
        owner = "root";
        group = "root";
      };
    };
  };
}
