# modules/homelab/services/pocket-id.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.homelab.pocket-id;
  hl = config.homelab;
in

{
  options.homelab.pocket-id = {
    enable = lib.mkEnableOption "Enables Pocket ID authentication service";

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

    # The OIDC IdP itself: must never sit behind an auth screen or
    # Pangolin/qui/fileflows logins deadlock.
    homelab.records.pocket-id = {
      subdomain = "id";
      port = 1411;
      exposure = "public";
      openFirewall = true;
    };

    # Create data directory for Pocket ID
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 pocket-id pocket-id"
    ];

    # Native NixOS service for Pocket ID
    services.pocket-id = {
      enable = true;
      package = pkgs.pocket-id;

      dataDir = cfg.dataDir;

      # Environment file with secrets
      environmentFile = config.sops.templates."pocket-id-env".path;

      settings = {
        APP_URL = hl.records.pocket-id.url;
        TRUST_PROXY = true;
        PORT = toString hl.records.pocket-id.port;
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
