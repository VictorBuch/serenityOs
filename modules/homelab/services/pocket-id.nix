# modules/homelab/services/pocket-id.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.pocket-id;
  hl = config.homelab;
  domain = hl.domain;
in

{
  options.pocket-id = {
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

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/pocket-id";
      description = "Data directory for Pocket ID";
    };
  };

  config = lib.mkIf cfg.enable {

    # Firewall rules - allow access to Pocket ID service
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Create data directory for Pocket ID
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 pocket-id pocket-id"
    ];

    # Native NixOS service for Pocket ID
    services.pocket-id = {
      enable = true;
      package = pkgs.unstable.pocket-id;

      dataDir = cfg.dataDir;

      # Environment file with secrets
      environmentFile = config.sops.templates."pocket-id-env".path;

      settings = {
        APP_URL = cfg.appUrl;
        TRUST_PROXY = true;
        PORT = 1411;
        TZ = "Europe/Copenhagen";
        # Analytics disabled by default for privacy
        ANALYTICS_DISABLED = true;
      };
    };

    # Create environment file template for Pocket ID with encryption key
    sops.templates."pocket-id-env" = {
      content = ''
        ENCRYPTION_KEY=${config.sops.placeholder."pocket-id/encryption_key"}
      '';
      owner = "pocket-id";
      group = "pocket-id";
      mode = "0400";
    };

    # SOPS secrets configuration
    sops.secrets = {
      "pocket-id/encryption_key" = {
        owner = "pocket-id";
        group = "pocket-id";
      };
    };
  };
}
